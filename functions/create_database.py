from typing import List, Dict, Any
import json
import os
import shutil

from dotenv import load_dotenv
from langchain_core.documents import Document
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_openai import OpenAIEmbeddings
from langchain_pinecone import PineconeVectorStore
from pinecone import Pinecone, ServerlessSpec


# Load environment variables (supports both .env and .env.local if present)
load_dotenv()
load_dotenv(".env.local")


# Resolve paths relative to this file (functions/)
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DEFAULT_DATA_FILE = os.path.join(BASE_DIR, "data", "recipes_fn.json")


def main():
    """Entry point: load recipes JSON, chunk, and persist to Pinecone."""
    data_file = os.environ.get("RECIPES_JSON", DEFAULT_DATA_FILE)
    if not os.path.exists(data_file):
        raise FileNotFoundError(
            f"Recipes JSON not found at {data_file}. Set RECIPES_JSON or place file at default path."
        )

    limit_env = os.environ.get("RECIPES_LIMIT")
    limit = int(limit_env) if limit_env and limit_env.isdigit() else None

    docs = load_recipes_as_documents(data_file, limit=limit)
    print(f"Loaded {len(docs)} recipe documents from {data_file}.")

    chunks = split_text(docs)
    print(f"Split into {len(chunks)} chunks. Persisting to Pinecone cloud index...")

    save_to_pinecone(chunks)
    print("Done.")


def load_recipes_as_documents(path: str, *, limit: int | None = None) -> List[Document]:
    """
    Load recipes from a JSON file into LangChain Document objects.

    Expected JSON structure: a list where each item has fields like
    { "title": str, "ingredients": list[str] | str, "instructions": str, "image": str | None }
    If keys differ (e.g., image hash under a different key), adapt mapping below.
    """
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)

    documents: List[Document] = []
    for i, item in data.items():
        title = safe_str(item.get("title"))

        # Ingredients may be a list or a single string
        ingredients_raw = item.get("ingredients", [])
        if isinstance(ingredients_raw, list):
            ingredients_text = "\n".join(f"- {safe_str(x)}" for x in ingredients_raw)
        else:
            ingredients_text = safe_str(ingredients_raw)

        instructions_text = safe_str(item.get("instructions", ""))

        # Picture link/hash may appear under various keys
        image = item.get("image") or item.get("image_url") or item.get("picture") or item.get("hash")
        image = safe_str(image) if image is not None else None

        page_content = (
            f"Title: {title}\n\n"
            f"Ingredients:\n{ingredients_text}\n\n"
            f"Instructions:\n{instructions_text}\n"
        )

        metadata: Dict[str, Any] = {
            "source": os.path.basename(path),
            "title": title,
        }
        if image:
            metadata["image"] = image
        # Optionally carry through an id if present
        if "id" in item:
            metadata["id"] = item["id"]

        documents.append(Document(page_content=page_content, metadata=metadata))

        if limit is not None and len(documents) >= limit:
            break

    return documents


def split_text(documents: List[Document]) -> List[Document]:
    splitter = RecursiveCharacterTextSplitter(
        chunk_size=1000,
        chunk_overlap=200,
        length_function=len,
        add_start_index=True,
    )
    chunks = splitter.split_documents(documents)
    # Preview one chunk for sanity
    if chunks:
        sample = chunks[min(1, len(chunks) - 1)]
        print("Sample chunk preview:")
        print(sample.page_content[:200].replace("\n", " ") + ("..." if len(sample.page_content) > 200 else ""))
        print(sample.metadata)
    return chunks




def save_to_pinecone(chunks: List[Document]):

    embeddings = OpenAIEmbeddings(model="text-embedding-3-small")

    # Initialize client
    api_key = os.environ.get("PINECONE_API_KEY")
    if not api_key:
        raise RuntimeError("PINECONE_API_KEY is not set in environment.")
    pc = Pinecone(api_key=api_key)
    index_name = "kai-recipes-index"
    if not pc.has_index(index_name):
        pc.create_index(
            name=index_name,
            dimension=1536,
            metric="cosine",
            spec=ServerlessSpec(cloud="aws", region="us-east-1"),
        )

    # Use LangChain's PineconeVectorStore to handle embedding + upsert
    PineconeVectorStore.from_documents(
        documents=chunks,
        embedding=embeddings,
        index_name=index_name,
    )
    print("Upsert complete.")


def safe_str(value: Any) -> str:
    return value if isinstance(value, str) else ("" if value is None else str(value))


if __name__ == "__main__":
    main()
