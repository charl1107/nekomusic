import os


class Config:
    API_BASE_URL = os.getenv("API_BASE_URL", "https://your-api-url.com/api")
    API_KEY = os.getenv("API_KEY", "")
    DEBUG = os.getenv("DEBUG", "True").lower() == "true"
    HOST = os.getenv("HOST", "0.0.0.0")
    PORT = int(os.getenv("PORT", 5000))
