from typing import List
from pydantic import BaseModel, validator


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


class MealOptions(BaseModel):
    items: List[Meal]

    @validator("items")
    def ensure_three(cls, v):
        if len(v) < 3:
            raise ValueError("Must include exactly 3 meal options")
        return v[:3]
