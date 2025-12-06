from typing import List
from config import client
from models import MealOptions
from prompts import create_slot_prompt
from rag_utils import build_retrieval_query, retrieve_recipe_context


def compute_slot_targets(macros: dict | None, distribution: dict | None = None) -> dict:
    """Compute per-slot macro targets from daily totals."""
    if not macros:
        macros = {}
    if distribution is None:
        distribution = {
            'breakfast': 0.25,
            'lunch': 0.30,
            'dinner': 0.35,
            'snack': 0.10,
        }

    total_cal = float(macros.get('calories') or 0)
    total_pro = float(macros.get('proteins') or macros.get('protein') or 0)
    total_car = float(macros.get('carbs') or 0)
    total_fat = float(macros.get('fats') or 0)

    targets = {}
    for slot, pct in distribution.items():
        targets[slot] = {
            'calories': round(total_cal * pct),
            'protein': round(total_pro * pct),
            'carbs': round(total_car * pct),
            'fats': round(total_fat * pct),
        }
    return targets


def generate_slot_options(
    data: dict,
    recent_meals: List[str],
    slot: str,
    slot_target: dict | None,
) -> List[dict]:
    """Generate three options for a slot using LLM only."""
    slot_prompt = create_slot_prompt(data, recent_meals, slot, slot_target)
    resp = client.responses.parse(
        model="gpt-4.1-mini",
        input=[
            {"role": "system", "content": "You are a creative nutritionist and chef. Return exactly 3 structured options."},
            {"role": "user", "content": slot_prompt},
        ],
        text_format=MealOptions,
    )
    options: MealOptions = resp.output_parsed
    return [m.dict() for m in options.items]


def generate_slot_with_rag(
    data: dict,
    recent_meals: list[str],
    slot: str,
    slot_target: dict | None,
    retrieval_k: int = 6,
) -> list[dict]:
    """Generate three options for a slot using retrieved recipes as grounding."""
    base_prompt = create_slot_prompt(data, recent_meals, slot, slot_target)
    retrieval_query = build_retrieval_query(data, slot, slot_target)
    context = retrieve_recipe_context(retrieval_query, k=retrieval_k)
    print(f"Retrieved documents for slot {slot} with query: {retrieval_query}, context: {context}")
    prompt = base_prompt
    if context:
        prompt += f"""

REFERENCE RECIPES (use as factual inspiration; keep macros aligned for {slot}):
{context}

Prefer ingredients and preparation styles from the reference where possible, but adjust to match the user's macros and dietary preference. Keep options distinct from each other."""
    else:
        prompt += "\n\nNo reference recipes were retrieved; rely on general culinary knowledge while keeping options practical."

    resp = client.responses.parse(
        model="gpt-4.1-mini",
        input=[
            {"role": "system", "content": "You are a nutritionist-chef. Return exactly 3 grounded, realistic options."},
            {"role": "user", "content": prompt},
        ],
        text_format=MealOptions,
    )
    options: MealOptions = resp.output_parsed
    return [m.dict() for m in options.items]
