import logging
from datetime import datetime, timedelta
from typing import List



def get_user_recent_meals(db, user_id: str, days_back: int = 7, max_meals: int = 15) -> List[str]:
    """
    Retrieve recent meal names from user's meal plan history to avoid repetition.
    """
    if not user_id:
        return []

    try:
        end_date = datetime.now()
        start_date = end_date - timedelta(days=days_back)

        recent_meal_names = []

        current_date = start_date
        while current_date <= end_date:
            date_id = f"{current_date.year}-{current_date.month:02d}-{current_date.day:02d}"

            try:
                plan_doc_ref = db.collection('users').document(user_id).collection('plans').document(date_id)
                plan_doc = plan_doc_ref.get()
                print(f"Fetched plan for date {date_id}: {plan_doc.to_dict() if plan_doc.exists else 'No plan found'}")
                if plan_doc.exists:
                    plan_data = plan_doc.to_dict()

                    for meal_type in ['breakfast', 'lunch', 'dinner', 'snack']:
                        if meal_type in plan_data and isinstance(plan_data[meal_type], list):
                            for meal in plan_data[meal_type]:
                                if isinstance(meal, dict) and 'name' in meal:
                                    recent_meal_names.append(meal['name'])

            except Exception as e:
                logging.warning(f"Error fetching plan for date {date_id}: {e}")

            current_date += timedelta(days=1)

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


# def cleanup_old_meal_plans(user_id: str, days_to_keep: int = 30):
#     """Clean up old meal plans to manage storage usage."""
#     if not user_id:
#         return

#     try:
#         cutoff_date = datetime.now() - timedelta(days=days_to_keep)
#         cutoff_date_str = f"{cutoff_date.year}-{cutoff_date.month:02d}-{cutoff_date.day:02d}"

#         plans_ref = db.collection('users').document(user_id).collection('plans')
#         old_plans = plans_ref.where('__name__', '<', cutoff_date_str).get()

#         batch = db.batch()
#         count = 0

#         for plan_doc in old_plans:
#             batch.delete(plan_doc.reference)
#             count += 1

#             if count % 500 == 0:
#                 batch.commit()
#                 batch = db.batch()

#         if count % 500 != 0:
#             batch.commit()

#         logging.info(f"Cleaned up {count} old meal plans for user {user_id}")

#     except Exception as e:
#         logging.error(f"Error cleaning up old meal plans for user {user_id}: {e}")
