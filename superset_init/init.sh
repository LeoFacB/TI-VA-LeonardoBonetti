#!/bin/bash
# Executado pelo servico superset-init a cada "docker compose up".
# Todos os passos sao idempotentes.
set -euo pipefail

: "${SUPERSET_ADMIN_USER:?defina SUPERSET_ADMIN_USER no .env}"
: "${SUPERSET_ADMIN_PASSWORD:?defina SUPERSET_ADMIN_PASSWORD no .env}"
: "${SUPERSET_DB_USER:?defina SUPERSET_DB_USER no .env}"
: "${SUPERSET_DB_PASSWORD:?defina SUPERSET_DB_PASSWORD no .env}"

NOME_BANCO="leonardobonetti"
URI="mysql+pymysql://${SUPERSET_DB_USER}:${SUPERSET_DB_PASSWORD}@mysql:3306/leonardobonetti"
DASHBOARD_ZIP="/app/export/dashboard.zip"

echo ">> Atualizando metadados do Superset"
superset db upgrade

echo ">> Criando usuario admin (se ja existir, aparece 'User already exists' e segue)"
superset fab create-admin \
  --username "$SUPERSET_ADMIN_USER" \
  --firstname Admin --lastname Superset \
  --email "${SUPERSET_ADMIN_EMAIL:-admin@localhost}" \
  --password "$SUPERSET_ADMIN_PASSWORD"

echo ">> Inicializando papeis e permissoes"
superset init

# O dashboard vem antes da conexao: o zip traz a conexao (sem senha) e os
# datasets com os mesmos identificadores da maquina onde foi exportado.
if [ -f "$DASHBOARD_ZIP" ]; then
  echo ">> Importando dashboard de $DASHBOARD_ZIP"
  superset import-dashboards -p "$DASHBOARD_ZIP" -u "$SUPERSET_ADMIN_USER"
fi

echo ">> Configurando conexao '$NOME_BANCO'"
superset set-database-uri -d "$NOME_BANCO" -u "$URI"

echo ">> Cadastrando datasets e consultas"
python /app/superset_init/provisionar.py

echo ">> Superset pronto."
