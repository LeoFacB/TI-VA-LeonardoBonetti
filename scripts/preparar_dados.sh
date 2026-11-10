#!/usr/bin/env bash
# Descompacta o dump para initdb/, que o MySQL executa na primeira subida.
set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ZIP="$RAIZ/dados/01-leonardobonetti.zip"
DESTINO="$RAIZ/initdb"
SQL="$DESTINO/01-leonardobonetti.sql"

if ! command -v unzip >/dev/null 2>&1; then
  echo "Erro: 'unzip' nao encontrado. Instale com: sudo apt install unzip" >&2
  exit 1
fi

if [ ! -f "$ZIP" ]; then
  echo "Erro: arquivo $ZIP nao encontrado." >&2
  exit 1
fi

if [ -f "$SQL" ]; then
  echo "Dump ja existe em $SQL — nada a fazer."
  exit 0
fi

unzip -q -o -j "$ZIP" 01-leonardobonetti.sql -d "$DESTINO"
chmod 644 "$SQL"
echo "Dump extraido para $SQL ($(du -h "$SQL" | cut -f1))."
