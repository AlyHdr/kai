# The Cloud Functions for Firebase SDK to create Cloud Functions and set up triggers.
from typing import List
from firebase_functions import firestore_fn, https_fn

# The Firebase Admin SDK to access Cloud Firestore.
from firebase_admin import initialize_app, firestore
import google.cloud.firestore
from openai import OpenAI
from pydantic import BaseModel, validator
import os
from dotenv import load_dotenv
load_dotenv(".env.local")
print("Initializing Firebase Admin SDK...")

client = OpenAI(
    api_key=os.getenv("OPENAI_API_KEY"),
    )

app = initialize_app()

print("openai key:", )
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

class MealList(BaseModel):
    meals: list[Meal]

class MealPlan(BaseModel):
    breakfast: List[Meal]
    lunch: List[Meal]
    dinner: List[Meal]
    @validator("breakfast", "lunch", "dinner")
    def ensure_three_options(cls, v):
        if len(v) < 3:
            raise ValueError("Each of breakfast, lunch, and dinner must have exactly 3 options.")
        # If model returns more than 3, trim to 3.
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
    data = req.data
    print("Received data:", data)
    prompt = (
        f"Generate a daily meal plan that provides EXACTLY 3 OPTIONS for each of the following meals: Breakfast, Lunch, and Dinner.\n"
        f"- Daily Calorie Intake: {data['macros']['calories']} calories\n"
        f"- Macronutrient Breakdown: {data['macros']['proteins']}g protein, {data['macros']['carbs']}g carbs, {data['macros']['fats']}g fats\n"
        f"- Dietary Preferences: {data['dietPreference']} (e.g., 'No Preference', 'Vegetarian', 'Vegan', 'Low Carb', 'High Protein')\n"
        f"Respond in JSON and ensure each meal option includes realistic macros that add up, and include descriptive names and brief descriptions for each meal.\n"
    )
    response = client.responses.parse(
        model="gpt-4o",
        input=[
            {"role": "system", "content": "You are an expert in meal planning and nutrition. Help the user with their daily meal plan."},
            {"role": "user", "content": prompt}
        ],
        text_format=MealPlan,
    )
    try:
        meals = response.output_parsed
        return meals.dict() 
    except Exception:
        return {"error": "Could not parse response", "raw": str(response.output_parsed)}