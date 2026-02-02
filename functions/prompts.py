from datetime import datetime


def create_enhanced_prompt(data, recent_meals=None):
    """Create a prompt that encourages variety and avoids repetition."""
    current_date = datetime.now().strftime("%B %d, %Y")
    prefs = (data.get('preferences') or {})
    proteins = (prefs.get('proteins') or {})
    cuisine = prefs.get('cuisine', 'any')
    protein_breakfast = proteins.get('breakfast', 'any')
    protein_lunch = proteins.get('lunch', 'any')
    protein_dinner = proteins.get('dinner', 'any')
    protein_snack = proteins.get('snack', 'any')
    custom_text = (prefs.get('custom') or '').strip()

    macros = data.get('macros', {}) or {}
    total_calories = macros.get('calories')
    total_protein = macros.get('proteins', macros.get('protein'))
    total_carbs = macros.get('carbs')
    total_fats = macros.get('fats')

    prompt = f"""Generate a unique daily meal plan for one person for {current_date} with EXACTLY 3 diverse options for EACH of these meals:
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

    if custom_text:
        prompt += f"""

ADDITIONAL USER PREFERENCES TO RESPECT:
{custom_text}
"""
    return prompt


def create_slot_prompt(data, recent_meals=None, slot: str = 'breakfast', slot_target: dict | None = None):
    """Prompt for a single meal slot."""
    current_date = datetime.now().strftime("%B %d, %Y")
    prefs = (data.get('preferences') or {})
    proteins = (prefs.get('proteins') or {})
    cuisine = prefs.get('cuisine', 'any')
    slot_protein = proteins.get(slot, 'any')
    custom_text = (prefs.get('custom') or '').strip()

    macros = data.get('macros', {}) or {}
    total_calories = macros.get('calories')
    total_protein = macros.get('proteins', macros.get('protein'))
    total_carbs = macros.get('carbs')
    total_fats = macros.get('fats')

    prompt = f"""For {current_date}, generate EXACTLY 3 unique {slot} options.
Return JSON matching the expected schema with 3 structured items.

CONTEXT:
- Daily Calories: {total_calories}
- Daily Macros: {total_protein}g protein, {total_carbs}g carbs, {total_fats}g fats
- Dietary Preference: {data['dietPreference']}
- Cuisine focus: {cuisine}
- Preferred protein for {slot}: {slot_protein}
"""
    if slot_target:
        prompt += f"""
TARGET FOR THIS {slot.upper()} (per option):
- Calories: {slot_target.get('calories')} kcal (within ±10%)
- Protein: {slot_target.get('protein')} g (within ±10%)
- Carbs: {slot_target.get('carbs')} g (within ±10%)
- Fats: {slot_target.get('fats')} g (within ±10%)
Each of the 3 options should individually respect these targets so that any single option combined with the other meals will approximate daily totals.
"""
    if recent_meals:
        prompt += f"""
Avoid repeating any of these meals: {', '.join(recent_meals)}.
"""

    if custom_text:
        prompt += f"""
ADDITIONAL USER PREFERENCES:
{custom_text}
"""

    prompt += """
Each option must include:
- name
- description
- calories
- macros: calories (duplicate ok), protein, carbs, fats
- ingredients (list)
- instructions (list)
Ensure portions and macros align with daily targets proportionally for this meal.
"""
    return prompt


def create_grocery_list_prompt(meals: list[dict]):
    """Prompt to generate a consolidated grocery list from selected meals."""
    lines = []
    for meal in meals:
        name = meal.get('name', 'Unknown meal')
        slot = meal.get('slot', 'meal')
        day = meal.get('day', 'day')
        lines.append(f"- {day} {slot}: {name}")

    meals_text = "\n".join(lines) if lines else "- No meals provided"
    return f"""You are a helpful meal prep assistant.
Create a consolidated grocery list for one week based on the selected meals below.
Deduplicate ingredients, combine quantities when possible, and group items by category.
If quantities are unknown, provide reasonable estimates or "as needed".

Selected meals:
{meals_text}

Return JSON that matches the expected schema.
Each grocery item must include:
- name (ingredient name)
- quantity (free text, e.g., "2", "1 lb", "1 bunch", "as needed")
- category (e.g., Produce, Protein, Dairy, Pantry, Spices, Frozen, Bakery)

If a note helps (e.g., "check pantry for staples"), add it to notes.
"""
