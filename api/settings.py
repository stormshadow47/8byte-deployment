from urllib.parse import quote_plus
from starlette.config import Config
from starlette.datastructures import Secret

try:
    config = Config(".env")
except FileNotFoundError:
    config = Config()

DATABASE_URL = config("DATABASE_URL", cast=Secret, default=None)

if DATABASE_URL is None:
    db_host = config("DB_HOST", default=None)
    db_port = config("DB_PORT", default="5432")
    db_name = config("DB_NAME", default=None)
    db_username = config("DB_USERNAME", default=None)
    db_password = config("DB_PASSWORD", cast=Secret, default=None)

    if not all([db_host, db_name, db_username, db_password]):
        raise RuntimeError(
            "Set DATABASE_URL or DB_HOST, DB_NAME, DB_USERNAME, and DB_PASSWORD."
        )

    DATABASE_URL = Secret(
        "postgresql://"
        f"{quote_plus(str(db_username))}:{quote_plus(str(db_password))}"
        f"@{db_host}:{db_port}/{db_name}"
    )

CORS_ORIGINS = [
    origin.strip()
    for origin in config("CORS_ORIGINS", default="").split(",")
    if origin.strip()
]
