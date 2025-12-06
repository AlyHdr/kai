import os
from dotenv import load_dotenv
import firebase_admin
from firebase_admin import credentials, firestore
from openai import OpenAI


# Load env once at module import (not per request)
load_dotenv()
load_dotenv(".env.local")

print("Initializing Firebase Admin SDK...")

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
PINECONE_API_KEY = os.getenv("PINECONE_API_KEY")
PINECONE_INDEX_NAME = os.getenv("PINECONE_INDEX_NAME", "kai-recipes-index")
EMBEDDING_MODEL = os.getenv("PINECONE_EMBEDDING_MODEL", "text-embedding-3-small")

client = OpenAI(api_key=OPENAI_API_KEY)

# cred = credentials.Certificate("firebase-service-account.json")

# firebase_admin.initialize_app(cred)
# db = firestore.client()
