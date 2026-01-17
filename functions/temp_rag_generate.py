from __future__ import annotations

import json
import os
from dataclasses import dataclass
from typing import Any, Dict, List, Optional

from dotenv import load_dotenv
from langchain_openai import ChatOpenAI, OpenAIEmbeddings
from langchain_pinecone import PineconeVectorStore
from pinecone import Pinecone
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser


# Load env from both .env and .env.local if present
load_dotenv()
load_dotenv(".env.local")


BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PINECONE_INDEX_NAME = os.environ.get("PINECONE_INDEX_NAME", "kai-recipes-index")


def _format_docs(docs) -> str:
    parts = []
    for d in docs:
        title = d.metadata.get("title") if d.metadata else None
        header = f"Title: {title}" if title else "Title: (unknown)"
        parts.append(
            f"{header}\n{d.page_content}"
        )
    return "\n\n---\n\n".join(parts)


def _build_query_from_profile(profile: Dict[str, Any]) -> str:
    # Build a simple text query from key preferences for retrieval
    pieces = []
    cuisine = profile.get("cuisine")
    if cuisine and cuisine != "any":
        pieces.append(f"cuisine {cuisine}")
    diet = profile.get("dietPreference")
    if diet and diet != "No Preference":
        pieces.append(diet)
    proteins = profile.get("proteins", {})
    # include all slot protein prefs as hints
    for slot in ("breakfast", "lunch", "dinner", "snack"):
        p = proteins.get(slot)
        if p and p != "any":
            pieces.append(f"{slot} {p}")
    custom = profile.get("custom")
    if custom:
        pieces.append(str(custom))
    return ", ".join(pieces) or "healthy balanced recipe"


def generate_recipe_with_rag(
    *,
    user_profile: Dict[str, Any],
    user_query: Optional[str] = None,
    k: int = 5,
    temperature: float = 0.4,
) -> Dict[str, Any]:
    """
    Retrieve relevant recipes from a Pinecone vector index and generate an
    adjusted recipe using LangChain + ChatOpenAI. Returns a JSON-serializable dict.
    """
    # Initialize Pinecone client and check index
    api_key = os.environ.get("PINECONE_API_KEY")
    if not api_key:
        raise RuntimeError("PINECONE_API_KEY is not set in environment.")
    pc = Pinecone(api_key=api_key)
    if not pc.has_index(PINECONE_INDEX_NAME):
        raise FileNotFoundError(
            f"Pinecone index '{PINECONE_INDEX_NAME}' not found. Run create_database.py first."
        )

    # Set up retriever
    embeddings = OpenAIEmbeddings(model="text-embedding-3-small")
    vector_store = PineconeVectorStore(
        index_name=PINECONE_INDEX_NAME,
        embedding=embeddings,
    )

    # Build a retrieval query
    retrieval_query = user_query or _build_query_from_profile(user_profile)
    docs = vector_store.similarity_search(retrieval_query, k=k)

    # Compose context
    context = _format_docs(docs)

    # Create LLM and prompt
    llm = ChatOpenAI(model="gpt-4o-mini", temperature=temperature)

    prompt = ChatPromptTemplate.from_messages(
        [
            (
                "system",
                "You are a professional chef and nutritionist. Given retrieved recipe context and a user profile, either: \n"
                "1) Select the best matching retrieved recipe and adjust it to fit the user's dietary preference, macros, and preferences, OR\n"
                "2) If none fit well, propose a new recipe inspired by the retrieved ones.\n\n"
                "Always return strict JSON with keys: name, description, calories, macros, ingredients, instructions, source.\n"
                "- macros is an object with protein, carbs, fats (grams).\n"
                "- ingredients is an array of strings.\n"
                "- instructions is an array of short steps.\n"
                "- source is 'retrieved:<title or id>' if based on a retrieved recipe, or 'new' if newly created.\n"
                "Be precise and practical; keep ingredient names consistent with the context where possible."
            ),
            (
                "user",
                "User Profile JSON:\n{profile}\n\nRetrieved Recipe Context:\n{context}\n\nTask: Generate one recipe for the user's next meal. If adjusting a retrieved recipe, adapt ingredients and steps as needed to comply with the profile.\n"
                "Return only JSON, with no extra commentary."
            ),
        ]
    )

    chain = prompt | llm | StrOutputParser()
    raw = chain.invoke({
        "profile": json.dumps(user_profile, ensure_ascii=False),
        "context": context,
    })

    # Parse JSON result leniently
    result = _safe_json_loads(raw)
    if result is None:
        # Fallback: wrap raw text
        result = {"raw": raw}
    return result


def _safe_json_loads(text: str) -> Optional[Dict[str, Any]]:
    try:
        # Try direct JSON
        return json.loads(text)
    except Exception:
        # Try to extract JSON block if any
        start = text.find("{")
        end = text.rfind("}")
        if start != -1 and end != -1 and end > start:
            try:
                return json.loads(text[start : end + 1])
            except Exception:
                return None
        return None


if __name__ == "__main__":
    # Example hard-coded profile for quick testing
    profile = {
        "dietPreference": "High Protein",
        "cuisine": "mediterranean",
        "proteins": {"breakfast": "eggs", "lunch": "chicken", "dinner": "fish", "snack": "yogurt"},
        "macros": {"calories": 2200, "protein": 160, "carbs": 180, "fats": 70},
        "custom": "Prefer low added sugar, avoid peanuts."
    }

    query = "high protein chicken dinner" 
    out = generate_recipe_with_rag(user_profile=profile, user_query=query)
    print(json.dumps(out, indent=2))
