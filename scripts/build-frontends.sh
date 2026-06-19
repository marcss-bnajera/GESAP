#!/usr/bin/env bash
# GESAP — Compilar los 3 frontends y copiar a www/
# Uso: bash scripts/build-frontends.sh
# Requiere: pnpm instalado (npm install -g pnpm)

set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "── Creando directorios www/ ──────────────────────────────"
mkdir -p "$ROOT/www/client-api" "$ROOT/www/client-auditor" "$ROOT/www/client-patient"

build_frontend() {
  local name="$1"   # carpeta del frontend
  local dest="$2"   # destino en www/

  echo ""
  echo "── Build: $name ─────────────────────────────────────────"
  cd "$ROOT/$name"

  if [ ! -d node_modules ]; then
    echo "  → Instalando dependencias..."
    pnpm install --frozen-lockfile
  fi

  pnpm build

  echo "  → Copiando dist/ → $dest"
  rm -rf "$dest"/*
  cp -r dist/* "$dest/"
  echo "  ✅ $name listo"
}

build_frontend "client-api-gesap"     "$ROOT/www/client-api"
build_frontend "client-auditor-gesap" "$ROOT/www/client-auditor"
build_frontend "client-patient-gesap" "$ROOT/www/client-patient"

echo ""
echo "✅ Todos los frontends compilados."
echo "   Siguiente: docker compose --env-file .env.prod --profile production up -d --build"
