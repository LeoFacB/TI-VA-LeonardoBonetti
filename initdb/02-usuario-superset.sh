#!/bin/bash
# Executado pelo entrypoint do MySQL depois do 01-leonardobonetti.sql.
# Cria o usuario so-leitura do Superset com a senha vinda do .env.
set -euo pipefail

: "${SUPERSET_DB_USER:?defina SUPERSET_DB_USER no .env}"
: "${SUPERSET_DB_PASSWORD:?defina SUPERSET_DB_PASSWORD no .env}"

mysql --protocol=socket -uroot -p"${MYSQL_ROOT_PASSWORD}" <<SQL
CREATE USER IF NOT EXISTS '${SUPERSET_DB_USER}'@'%' IDENTIFIED BY '${SUPERSET_DB_PASSWORD}';
GRANT SELECT ON leonardobonetti.* TO '${SUPERSET_DB_USER}'@'%';
FLUSH PRIVILEGES;
SQL

echo "Usuario '${SUPERSET_DB_USER}' criado com SELECT em leonardobonetti.*"
