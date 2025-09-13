# The Cloud Functions for Firebase SDK to create Cloud Functions and set up triggers.
from typing import List
from firebase_functions import firestore_fn, https_fn

# The Firebase Admin SDK to access Cloud Firestore.
from firebase_admin import initialize_app, firestore, credentials
import google.cloud.firestore
from openai import OpenAI
from pydantic import BaseModel, validator
import os
from dotenv import load_dotenv

from datetime import datetime, timedelta
from typing import List, Optional
import logging
import random
import json

load_dotenv(".env.local")
print("Initializing Firebase Admin SDK...")

client = OpenAI(
    api_key=os.getenv("OPENAI_API_KEY"),
    )


cred = credentials.Certificate("kai-nutrition-assistant-firebase-adminsdk-fbsvc-ff82cd7006.json")

app = initialize_app(cred)
db = firestore.client()

class Macros(BaseModel):
    calories: int
    protein: int
    carbs: int
    fats: int

class Meal(BaseModel):
    name: str
    description: str
    calories: int
    macros: Macros
    ingredients: List[str]
    instructions: List[str]


class MealPlan(BaseModel):
    breakfast: List[Meal]
    lunch: List[Meal]
    dinner: List[Meal]
    snack: List[Meal]  

    @validator("breakfast", "lunch", "dinner", "snack")  
    def ensure_three_options(cls, v):
        if len(v) < 3:
            raise ValueError("Each of breakfast, lunch, dinner, and snack must have exactly 3 options.")
        return v[:3]
    
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
        model="gpt-4o",
        input=[        
            {"role": "system", "content": "You are an expert in nutrtion and fitness. Help the user with their daily macronutrient needs."},
            {"role": "user", "content": prompt}
        ],
        text_format=Macros,
    )
    try:
        macros = response.output_parsed
        return macros.dict()  # ✅ Convert to JSON-serializable format
    except Exception:
        return {"error": "Could not parse response", "raw": str(response.output_parsed)}




@https_fn.on_call()
def generate_meal_plan(req: https_fn.CallableRequest):
    """Main Firebase Function to generate meal plans with variety"""
    data = req.data
    print("Received data:", data)

    # Extract user_id ...
    user_id = req.auth.uid if hasattr(req, 'auth') and req.auth else None
    recent_meals = get_user_recent_meals(user_id, days_back=10, max_meals=20) if user_id else []
    print(f"Recent meals to avoid: {recent_meals}")

    prompt = create_enhanced_prompt(data, recent_meals)

    try:
        response = client.responses.parse(   # 👈 use `.parse` here
            model="gpt-4o-mini",               
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
        return meal_plan.dict()     # return JSON-serializable dict

    except Exception as e:
        print(f"Generation error: {e}")
        return {"error": "Could not generate meal plan", "details": str(e)}

def create_enhanced_prompt(data, recent_meals=None):
    """Create a prompt that encourages variety and avoids repetition"""

    current_date = datetime.now().strftime("%B %d, %Y")
    # Safely extract preferences; default to 'any'
    prefs = (data.get('preferences') or {})
    proteins = (prefs.get('proteins') or {})
    cuisine = prefs.get('cuisine', 'any')
    protein_breakfast = proteins.get('breakfast', 'any')
    protein_lunch = proteins.get('lunch', 'any')
    protein_dinner = proteins.get('dinner', 'any')
    protein_snack = proteins.get('snack', 'any')  # NEW

    # Be tolerant to 'protein' vs 'proteins' in user's saved macros
    macros = data.get('macros', {}) or {}
    total_calories = macros.get('calories')
    total_protein = macros.get('proteins', macros.get('protein'))
    total_carbs = macros.get('carbs')
    total_fats = macros.get('fats')

    prompt = f"""Generate a unique daily meal plan for {current_date} with EXACTLY 3 diverse options for EACH of these meals:
- breakfast
- lunch
- dinner
- snack

NUTRITIONAL REQUIREMENTS:
- Total Daily Calories: {total_calories} calories
- Total Daily Macros: {total_protein}g protein, {total_carbs}g carbs, {total_fats}g fats
- Dietary Preference: {data['dietPreference']}

VARIETY GUIDELINES for today:
- Feature cuisine: {cuisine}
- Breakfast proteins: {protein_breakfast}
- Lunch proteins: {protein_lunch}
- Dinner proteins: {protein_dinner}
- Snack proteins: {protein_snack}

CREATIVITY REQUIREMENTS:
1. Each of the 12 meal options should be completely unique
2. Vary ingredients, flavors, textures, and presentations
3. Include different spice profiles and seasonings
4. Mix cooking temperatures (hot, room temp, cold dishes)
5. Balance simple and complex preparations
6. Ensure visual variety (colors, plating styles)
"""

    if recent_meals and len(recent_meals) > 0:
        prompt += f"""
AVOID REPETITION:
Recently suggested meals to avoid repeating: {', '.join(recent_meals)}
Create completely different meal concepts from these previous suggestions.
Use different ingredients, cooking methods, and flavor profiles.
"""

    prompt += """

Each meal must include:
- Creative, descriptive name that reflects the cuisine/style
- Brief description 
- Accurate calorie count
- Precise macro breakdown (protein, carbs, fats in grams)
- Ingredients list
- Preparation instructions

Ensure nutritional accuracy and that meals are practical to prepare."""
    return prompt

def get_user_recent_meals(user_id: str, days_back: int = 7, max_meals: int = 15) -> List[str]:
    """
    Retrieve recent meal names from user's meal plan history to avoid repetition
    
    Args:
        user_id: Firebase user ID
        days_back: Number of days to look back for recent meals
        max_meals: Maximum number of recent meal names to return
        
    Returns:
        List of recent meal names to avoid in new meal plan generation
    """
    if not user_id:
        return []
    
    try:
        # Calculate date range for recent meals
        end_date = datetime.now()
        start_date = end_date - timedelta(days=days_back)
        
        recent_meal_names = []
        
        # Generate date strings for the range (matching your frontend format)
        current_date = start_date
        while current_date <= end_date:
            date_id = f"{current_date.year}-{current_date.month:02d}-{current_date.day:02d}"
            
            try:
                # Reference to the specific plan document
                plan_doc_ref = db.collection('users').document(user_id).collection('plans').document(date_id)
                plan_doc = plan_doc_ref.get()
                
                if plan_doc.exists:
                    plan_data = plan_doc.to_dict()
                    
                    # Extract meal names from breakfast, lunch, dinner
                    for meal_type in ['breakfast', 'lunch', 'dinner', 'snack']:
                        if meal_type in plan_data and isinstance(plan_data[meal_type], list):
                            for meal in plan_data[meal_type]:
                                if isinstance(meal, dict) and 'name' in meal:
                                    recent_meal_names.append(meal['name'])
                
            except Exception as e:
                logging.warning(f"Error fetching plan for date {date_id}: {e}")
                continue
            
            current_date += timedelta(days=1)
        
        # Remove duplicates while preserving order and limit results
        unique_meals = []
        seen = set()
        for meal_name in recent_meal_names:
            if meal_name not in seen:
                unique_meals.append(meal_name)
                seen.add(meal_name)
                if len(unique_meals) >= max_meals:
                    break
        
        logging.info(f"Retrieved {len(unique_meals)} recent meals for user {user_id}")
        return unique_meals
        
    except Exception as e:
        logging.error(f"Error retrieving recent meals for user {user_id}: {e}")
        return []
    
# Optional: Helper function to clean up old meal plans
def cleanup_old_meal_plans(user_id: str, days_to_keep: int = 30):
    """Clean up old meal plans to manage storage usage"""
    if not user_id:
        return
    
    try:
        cutoff_date = datetime.now() - timedelta(days=days_to_keep)
        cutoff_date_str = f"{cutoff_date.year}-{cutoff_date.month:02d}-{cutoff_date.day:02d}"
        
        plans_ref = db.collection('users').document(user_id).collection('plans')
        
        # Query old plans (this is approximate since Firestore document IDs are strings)
        old_plans = plans_ref.where('__name__', '<', cutoff_date_str).get()
        
        # Delete old plans in batches
        batch = db.batch()
        count = 0
        
        for plan_doc in old_plans:
            batch.delete(plan_doc.reference)
            count += 1
            
            # Commit batch every 500 operations (Firestore limit)
            if count % 500 == 0:
                batch.commit()
                batch = db.batch()
        
        # Commit remaining operations
        if count % 500 != 0:
            batch.commit()
            
        logging.info(f"Cleaned up {count} old meal plans for user {user_id}")
        
    except Exception as e:
        logging.error(f"Error cleaning up old meal plans for user {user_id}: {e}")
  
