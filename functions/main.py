# Cloud Functions handlers; logic split into smaller modules for reuse.
from firebase_functions import https_fn
from firebase_admin import firestore

from config import client
from models import Macros, MealPlan, GroceryList
from prompts import create_enhanced_prompt, create_grocery_list_prompt
from generation import (
    compute_slot_targets,
    generate_slot_options,
    generate_slot_with_rag,
)
from services import get_user_recent_meals
from rag_utils import get_vector_store

import firebase_admin
from firebase_admin import credentials, firestore

cred = credentials.Certificate("firebase-service-account.json")

firebase_admin.initialize_app(cred)
db = firestore.client()


@https_fn.on_call()
def print_hello(req: https_fn.CallableRequest):
    print("Received request:", req.data)
    return {"message": "Hello from Firebase Functions!"}


@https_fn.on_call()
def generate_macros(req: https_fn.CallableRequest):
    data = req.data
    print("Received data:", data)
    prompt = (
        f"Generate the recommended daily calorie intake and macronutrient breakdown "
        f"(in grams) for:\n"
        f"- Date of birth: {data['dateOfBirth']}\n"
        f"- Weight in kg: {data['weightKg']}kg\n"
        f"- Height in cm: {data['heightCm']}cm\n"
        f"- gender: {data['gender']}\n"
        f"- Activity Level: {data['activityLevel']} (e.g., 'Low': 'Mostly sedentary lifestyle, little to no exercise.', 'Moderate': 'Light exercise or daily activity like walking.', 'High': 'Frequent intense workouts or physically demanding job.',\n"
        f"- Goal: {data['goal']} (e.g., 'Lose Weight': 'Focus on fat loss and calorie control.', 'Build Muscle': 'Support muscle growth with nutrition and training.', 'Maintain': 'Sustain your current physique and health.',).\n"
        f"- Dietary Preferences: {data['dietPreference']} (e.g., 'No Preference': 'No specific dietary restriction or preference.', 'Vegetarian': 'No meat, but includes dairy and eggs.', 'Vegan': 'No animal products of any kind.', 'Low Carb': 'Focus on reducing carbohydrate intake.', 'High Protein': 'Emphasizes protein-rich foods for muscle growth.',').\n"
    )

    response = client.responses.parse(
        model="gpt-4.1-mini",
        input=[
            {"role": "system", "content": "You are an expert in nutrtion and fitness. Help the user with their daily macronutrient needs."},
            {"role": "user", "content": prompt}
        ],
        text_format=Macros,
    )
    try:
        macros = response.output_parsed
        return macros.dict()
    except Exception:
        return {"error": "Could not parse response", "raw": str(response.output_parsed)}


@https_fn.on_call()
def generate_meal_plan(req: https_fn.CallableRequest):
    """Generate meal plans without external recipe grounding."""
    data = req.data
    print("Received data:", data)

    user_id = req.auth.uid if hasattr(req, 'auth') and req.auth else None
    recent_meals = get_user_recent_meals(db, user_id, days_back=10, max_meals=20) if user_id else []
    print(f"Recent meals to avoid: {recent_meals}")

    progressive = bool(data.get('progressive'))
    date_id = data.get('dateId')

    if progressive:
        if not user_id:
            return {"error": "Unauthenticated progressive generation requires user auth."}
        if not date_id:
            return {"error": "Missing dateId for progressive generation."}

        try:
            plan_ref = db.collection('users').document(user_id).collection('plans').document(date_id)
            plan_ref.set({
                'breakfast': [],
                'lunch': [],
                'dinner': [],
                'snack': [],
                'selected': {},
                'status': 'generating',
                'progress': {'stage': 'initializing', 'percent': 0},
                'date': date_id,
                'startedAt': firestore.SERVER_TIMESTAMP,
                'updatedAt': firestore.SERVER_TIMESTAMP,
            })

            stages = [('breakfast', 25), ('lunch', 50), ('dinner', 75), ('snack', 100)]
            macros = (data.get('macros') or {})
            slot_targets = compute_slot_targets(macros)

            for slot, percent in stages:
                try:
                    items = generate_slot_options(data, recent_meals, slot, slot_targets.get(slot))

                    for m in items:
                        name = m.get('name')
                        if name:
                            recent_meals.append(name)

                    plan_ref.update({
                        slot: items,
                        'progress': {'stage': slot, 'percent': percent},
                        'updatedAt': firestore.SERVER_TIMESTAMP,
                    })
                except Exception as slot_err:
                    print(f"Error generating {slot}: {slot_err}")
                    plan_ref.update({
                        'status': 'error',
                        'error': f"Failed generating {slot}: {slot_err}",
                        'updatedAt': firestore.SERVER_TIMESTAMP,
                    })
                    return {"error": f"Failed generating {slot}", "details": str(slot_err)}

            plan_ref.update({
                'status': 'ready',
                'progress': None,
                'updatedAt': firestore.SERVER_TIMESTAMP,
            })

            return {"status": "started", "mode": "progressive"}

        except Exception as e:
            print(f"Progressive generation error: {e}")
            return {"error": "Could not generate meal plan progressively", "details": str(e)}

    prompt = create_enhanced_prompt(data, recent_meals)
    try:
        response = client.responses.parse(
            model="gpt-4.1-mini",
            input=[
                {
                    "role": "system",
                    "content": (
                        "You are a creative nutritionist and chef specializing in diverse meal planning. "
                        "Always include exactly 3 diverse options for each of breakfast, lunch, dinner, and snack."
                    )
                },
                {"role": "user", "content": prompt}
            ],
            text_format=MealPlan,
        )

        meal_plan = response.output_parsed
        return meal_plan.dict()

    except Exception as e:
        print(f"Generation error: {e}")
        return {"error": "Could not generate meal plan", "details": str(e)}


@https_fn.on_call()
def generate_meal_plan_rag(req: https_fn.CallableRequest):
    """Generate meal plans grounded on recipe embeddings."""
    data = req.data
    print("Received data (RAG):", data)

    try:
        get_vector_store()
    except Exception as setup_err:
        print(f"RAG setup error: {setup_err}")
        return {"error": "RAG is not available", "details": str(setup_err)}

    user_id = req.auth.uid if hasattr(req, 'auth') and req.auth else None
    recent_meals = get_user_recent_meals(db, user_id, days_back=10, max_meals=20) if user_id else []
    print(f"Recent meals to avoid (RAG): {recent_meals}")

    progressive = bool(data.get('progressive'))
    date_id = data.get('dateId')
    macros = data.get('macros') or {}
    slot_targets = compute_slot_targets(macros)

    if progressive:
        if not user_id:
            return {"error": "Unauthenticated progressive generation requires user auth."}
        if not date_id:
            return {"error": "Missing dateId for progressive generation."}

        try:
            plan_ref = db.collection('users').document(user_id).collection('plans').document(date_id)
            plan_ref.set({
                'breakfast': [],
                'lunch': [],
                'dinner': [],
                'snack': [],
                'selected': {},
                'status': 'generating',
                'progress': {'stage': 'initializing', 'percent': 0},
                'date': date_id,
                'startedAt': firestore.SERVER_TIMESTAMP,
                'updatedAt': firestore.SERVER_TIMESTAMP,
            })

            stages = [('breakfast', 25), ('lunch', 50), ('dinner', 75), ('snack', 100)]
            for slot, percent in stages:
                try:
                    items = generate_slot_with_rag(
                        data=data,
                        recent_meals=recent_meals,
                        slot=slot,
                        slot_target=slot_targets.get(slot),
                    )

                    for m in items:
                        name = m.get('name')
                        if name:
                            recent_meals.append(name)

                    plan_ref.update({
                        slot: items,
                        'progress': {'stage': slot, 'percent': percent},
                        'updatedAt': firestore.SERVER_TIMESTAMP,
                    })
                except Exception as slot_err:
                    print(f"Error generating {slot} with RAG: {slot_err}")
                    plan_ref.update({
                        'status': 'error',
                        'error': f"Failed generating {slot}: {slot_err}",
                        'updatedAt': firestore.SERVER_TIMESTAMP,
                    })
                    return {"error": f"Failed generating {slot}", "details": str(slot_err)}

            plan_ref.update({
                'status': 'ready',
                'progress': None,
                'updatedAt': firestore.SERVER_TIMESTAMP,
            })

            return {"status": "started", "mode": "progressive_rag"}

        except Exception as e:
            print(f"Progressive RAG generation error: {e}")
            return {"error": "Could not generate meal plan progressively with RAG", "details": str(e)}

    slots = ['breakfast', 'lunch', 'dinner', 'snack']
    plan_data: dict[str, list[dict]] = {}
    try:
        for slot in slots:
            items = generate_slot_with_rag(
                data=data,
                recent_meals=recent_meals,
                slot=slot,
                slot_target=slot_targets.get(slot),
            )
            plan_data[slot] = items
            for m in items:
                name = m.get('name')
                if name:
                    recent_meals.append(name)

        try:
            validated_plan = MealPlan(**plan_data)
            return validated_plan.dict()
        except Exception:
            return plan_data

    except Exception as e:
        print(f"RAG generation error: {e}")
        return {"error": "Could not generate meal plan with RAG", "details": str(e)}


@https_fn.on_call()
def generate_grocery_list(req: https_fn.CallableRequest):
    data = req.data or {}
    user_id = req.auth.uid if hasattr(req, 'auth') and req.auth else None
    if not user_id:
        return {"error": "Authentication required."}

    week_id = data.get('weekId')
    if not week_id:
        return {"error": "Missing weekId."}

    plan_ref = db.collection('users').document(user_id).collection('weekly_plans').document(week_id)
    snap = plan_ref.get()
    if not snap.exists:
        return {"error": "Weekly plan not found."}

    plan_data = snap.to_dict() or {}
    days = plan_data.get('days', {}) or {}
    meals = []

    for date_key, day_data in days.items():
        day = day_data or {}
        day_meals = (day.get('meals') or {})
        for slot, meal in day_meals.items():
            if isinstance(meal, dict):
                meals.append({
                    'day': date_key,
                    'slot': slot,
                    'name': meal.get('name') or meal.get('title') or 'Meal',
                    'mealType': meal.get('mealType'),
                    'tags': meal.get('tags', []),
                })

    if not meals:
        return {"error": "No meals found for the selected week."}

    plan_ref.set({
        'groceryStatus': 'generating',
        'groceryUpdatedAt': firestore.SERVER_TIMESTAMP,
        'updatedAt': firestore.SERVER_TIMESTAMP,
    }, merge=True)

    prompt = create_grocery_list_prompt(meals)
    try:
        response = client.responses.parse(
            model="gpt-4.1-mini",
            input=[
                {
                    "role": "system",
                    "content": (
                        "You generate accurate, consolidated grocery lists from meal names. "
                        "Respond only with valid JSON matching the schema."
                    ),
                },
                {"role": "user", "content": prompt},
            ],
            text_format=GroceryList,
        )
        grocery_list = response.output_parsed
        result = grocery_list.dict()

        plan_ref.set({
            'groceryList': result,
            'groceryStatus': 'ready',
            'groceryGeneratedAt': firestore.SERVER_TIMESTAMP,
            'updatedAt': firestore.SERVER_TIMESTAMP,
        }, merge=True)

        return result
    except Exception as e:
        print(f"Grocery list generation error: {e}")
        plan_ref.set({
            'groceryStatus': 'error',
            'groceryError': str(e),
            'groceryUpdatedAt': firestore.SERVER_TIMESTAMP,
            'updatedAt': firestore.SERVER_TIMESTAMP,
        }, merge=True)
        return {"error": "Could not generate grocery list", "details": str(e)}
  
