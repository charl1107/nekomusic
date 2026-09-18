import os
from dotenv import load_dotenv

load_dotenv()


class Config:
    YOUTUBE_API_KEY = os.getenv("YOUTUBE_API_KEY", "")
    YOUTUBE_API_BASE = "https://www.googleapis.com/youtube/v3"
    DEBUG = os.getenv("DEBUG", "True").lower() == "true"
    HOST = os.getenv("HOST", "0.0.0.0")
    PORT = int(os.getenv("PORT", 5000))
