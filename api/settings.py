import os
from starlette.config import Config
from starlette.datastructures import Secret

try:
    config = Config(".env")
except FileNotFoundError:
    config = Config()

# DATABASE_URL from AWS Secrets Manager/ECS task definition or local .env
DATABASE_URL = config("DATABASE_URL", cast=Secret, default=os.getenv("DATABASE_URL"))

# CORS origins from environment variable (required)
CORS_ORIGINS = config("CORS_ORIGINS").split(",")