"""Bulk-ingest recipes from functions/data/recipes.csv into Firestore.

Usage examples:
  cd functions
  python3 ingest_recipes_csv.py \
    --csv-path data/recipes.csv \
    --collection recipes \
    --project-id kai-65604

  python3 ingest_recipes_csv.py \
    --service-account ../firebase-service-account.json \
    --limit 500
"""

import argparse
import ast
import csv
import json
import re
from pathlib import Path
from typing import Any

import firebase_admin
from firebase_admin import credentials, firestore


def _extract_number(value: Any, fallback: int = 0) -> int:
    text = str(value or '').strip()
    if not text:
        return fallback
    match = re.search(r"-?\d+(?:\.\d+)?", text)
    if not match:
        return fallback
    try:
        return int(float(match.group(0)))
    except ValueError:
        return fallback


def _meal_type(raw: str) -> str:
    val = (raw or '').strip().lower()
    if val in {'breakfast', 'lunch', 'dinner', 'snack'}:
        return val.capitalize()
    return 'Dinner'


def _build_tags(meal_type: str, protein: int, carbs: int, total_time: int) -> list[str]:
    tags: list[str] = []
    if protein >= 25:
        tags.append('High Protein')
    if 0 < carbs <= 25:
        tags.append('Low Carb')
    if 0 < total_time <= 20:
        tags.append('Quick')
    if meal_type in {'Breakfast', 'Lunch', 'Dinner', 'Snack'}:
        tags.append(meal_type)

    deduped: list[str] = []
    for tag in tags:
        if tag not in deduped:
            deduped.append(tag)
    return deduped


def _parse_list_column(raw: str, fallback_text: str = '') -> list[str]:
    text = (raw or '').strip()

    if text:
        try:
            parsed = json.loads(text)
            if isinstance(parsed, list):
                return [str(item).strip() for item in parsed if str(item).strip()]
        except json.JSONDecodeError:
            pass

        try:
            parsed = ast.literal_eval(text)
            if isinstance(parsed, list):
                return [str(item).strip() for item in parsed if str(item).strip()]
        except (ValueError, SyntaxError):
            pass

    fallback = (fallback_text or '').strip()
    if not fallback:
        return []

    lines = [line.strip(' -\t') for line in fallback.replace('\r', '\n').split('\n')]
    return [line for line in lines if line]


def _doc_from_row(row: dict[str, str]) -> dict[str, Any]:
    meal_type = _meal_type(row.get('meal_type', ''))

    calories = _extract_number(row.get('calories'))
    proteins = _extract_number(row.get('proteins'))
    fats = _extract_number(row.get('fats'))
    carbs = _extract_number(row.get('carbs'))
    total_time_mins = _extract_number(row.get('total_time_mins'))

    ingredients_items = _parse_list_column(
        row.get('ingredients_list', ''),
        fallback_text=row.get('ingredients', ''),
    )
    instruction_items = _parse_list_column(
        row.get('instructions_list', ''),
        fallback_text=row.get('instructions', ''),
    )

    return {
        'title': (row.get('title') or '').strip(),
        'image': (row.get('image') or '').strip(),
        'total_time_mins': total_time_mins,
        'calories': calories,
        'proteins': proteins,
        'fats': fats,
        'carbs': carbs,
        'meal_type': meal_type.lower(),
        'tags': _build_tags(meal_type, proteins, carbs, total_time_mins),
        'ingredients_list': ingredients_items,
        'instructions_list': instruction_items,
        'source': 'recipes.csv',
    }


def _init_app(service_account: str | None, project_id: str | None):
    if firebase_admin._apps:
        return

    if service_account:
        cred = credentials.Certificate(service_account)
        if project_id:
            firebase_admin.initialize_app(cred, {'projectId': project_id})
        else:
            firebase_admin.initialize_app(cred)
        return

    if project_id:
        firebase_admin.initialize_app(options={'projectId': project_id})
    else:
        firebase_admin.initialize_app()


def ingest(csv_path: Path, collection: str, limit: int, dry_run: bool) -> None:
    db = None if dry_run else firestore.client()

    with csv_path.open('r', encoding='utf-8', newline='') as handle:
        reader = csv.DictReader(handle)
        batch = db.batch() if db else None
        writes_in_batch = 0
        processed = 0
        committed = 0

        for row in reader:
            if 0 < limit <= processed:
                break

            recipe_id = (row.get('id') or '').strip()
            if not recipe_id:
                continue

            doc = _doc_from_row(row)
            if not doc['title']:
                continue

            processed += 1
            if dry_run:
                continue

            ref = db.collection(collection).document(recipe_id)
            batch.set(ref, doc, merge=True)
            writes_in_batch += 1

            if writes_in_batch >= 400:
                batch.commit()
                committed += writes_in_batch
                batch = db.batch()
                writes_in_batch = 0

        if not dry_run and writes_in_batch > 0:
            batch.commit()
            committed += writes_in_batch

    if dry_run:
        print(f'DRY RUN complete. Valid recipe rows: {processed}')
    else:
        print(f'Ingestion complete. Upserted {committed} recipes into {collection}.')


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument('--csv-path', default='data/recipes.csv')
    parser.add_argument('--collection', default='recipes')
    parser.add_argument('--service-account', default=None)
    parser.add_argument('--project-id', default=None)
    parser.add_argument('--limit', type=int, default=0)
    parser.add_argument('--dry-run', action='store_true')
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    csv_path = Path(args.csv_path)

    if not csv_path.exists():
        raise SystemExit(f'CSV not found: {csv_path}')

    if not args.dry_run:
        _init_app(args.service_account, args.project_id)
    ingest(csv_path, args.collection, args.limit, args.dry_run)


if __name__ == '__main__':
    main()
