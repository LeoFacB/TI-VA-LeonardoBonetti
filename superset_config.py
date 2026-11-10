import os

# Chave lida do .env (via docker-compose). Sem ela o Superset nao sobe.
SECRET_KEY = os.environ["SUPERSET_SECRET_KEY"]

# Metadados do Superset (usuarios, graficos, dashboards) em SQLite no volume.
SQLALCHEMY_DATABASE_URI = "sqlite:////app/superset_home/superset.db"

# Ambiente local de demonstracao.
TALISMAN_ENABLED = False
BABEL_DEFAULT_LOCALE = "pt_BR"
LANGUAGES = {
    "pt_BR": {"flag": "br", "name": "Português (Brasil)"},
    "en": {"flag": "us", "name": "English"},
}

FEATURE_FLAGS = {
    "DASHBOARD_RBAC": False,
}

ROW_LIMIT = 5000
SQLLAB_TIMEOUT = 300
