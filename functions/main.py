# The Cloud Functions for Firebase SDK to create Cloud Functions and set up triggers.
from firebase_functions import firestore_fn, https_fn

# The Firebase Admin SDK to access Cloud Firestore.
from firebase_admin import initialize_app, firestore
import google.cloud.firestore
from openai import OpenAI
from pydantic import BaseModel
import os

client = OpenAI(
    api_key = os.getenv("OPENAI_API_KEY")
    )

app = initialize_app()

class Macros(BaseModel):
    calories: int
    protein: int
    carbs: int
    fats: int

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

    content = response.output_parsed
    try:
        macros = response.output_parsed
        return macros.dict()  # ✅ Convert to JSON-serializable format
    except Exception:
        return {"error": "Could not parse response", "raw": str(response.output_parsed)}