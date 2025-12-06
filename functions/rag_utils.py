import logging
from langchain_openai import OpenAIEmbeddings
from langchain_pinecone import PineconeVectorStore
from pinecone import Pinecone

from config import PINECONE_API_KEY, PINECONE_INDEX_NAME, EMBEDDING_MODEL


_vector_store: PineconeVectorStore | None = None


def get_vector_store() -> PineconeVectorStore:
    """Lazily initialize and cache the Pinecone vector store for recipe retrieval."""
    global _vector_store
    if _vector_store:
        return _vector_store

    api_key = PINECONE_API_KEY
    if not api_key:
        raise RuntimeError("PINECONE_API_KEY is not set in environment.")

    pc = Pinecone(api_key=api_key)
    if not pc.has_index(PINECONE_INDEX_NAME):
        raise RuntimeError(
            f"Pinecone index '{PINECONE_INDEX_NAME}' not found. "
            "Run functions/create_database.py to build it."
        )
    print("Pinecone index found.")
    embeddings = OpenAIEmbeddings(model=EMBEDDING_MODEL)
    _vector_store = PineconeVectorStore(
        index_name=PINECONE_INDEX_NAME,
        embedding=embeddings,
    )
    return _vector_store


def build_retrieval_query(data: dict, slot: str, slot_target: dict | None = None) -> str:
    """Create a text query for vector search using user preferences and slot info."""
    prefs = data.get('preferences') or {}
    proteins = prefs.get('proteins') or {}
    parts = [
        data.get('dietPreference'),
        prefs.get('cuisine'),
        prefs.get('custom'),
        f"{slot} protein {proteins.get(slot) or ''}",
    ]
    macros = data.get('macros') or {}
    if macros:
        parts.append(
            f"calories {macros.get('calories')} protein {macros.get('proteins', macros.get('protein'))} "
            f"carbs {macros.get('carbs')} fats {macros.get('fats')}"
        )
    if slot_target:
        parts.append(
            f"{slot} target {slot_target.get('calories')} kcal "
            f"{slot_target.get('protein')}g protein"
        )
    query = " ".join(str(p) for p in parts if p)
    return query or f"{slot} balanced recipe"


def format_docs_for_prompt(docs, max_docs: int = 5, max_chars: int = 750) -> str:
    """Format retrieved documents into a compact text block for grounding."""
    formatted = []
    for doc in docs[:max_docs]:
        content = doc.page_content.strip()
        if len(content) > max_chars:
            content = content[:max_chars] + "..."
        title = (doc.metadata or {}).get("title") or "Untitled"
        formatted.append(f"Title: {title}\n{content}")
    return "\n\n---\n\n".join(formatted)


def retrieve_recipe_context(query: str, k: int = 6) -> str:
    """Fetch relevant recipe chunks from Pinecone."""
    try:
        vector_store = get_vector_store()
        docs = vector_store.similarity_search(query, k=k)
        if not docs:
            return ""
        return format_docs_for_prompt(docs)
    except Exception as e:
        logging.warning(f"RAG retrieval failed for query '{query}': {e}")
        return ""
