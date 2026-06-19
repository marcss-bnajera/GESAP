#!/usr/bin/env bash
# GESAP — Inicio con verificación de salud
# Uso:
#   bash scripts/start.sh              (solo backends)
#   bash scripts/start.sh --production (backends + nginx)

set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
ok()   { echo -e "${GREEN}  ✓ $*${NC}"; }
fail() { echo -e "${RED}  ✗ $*${NC}"; }
info() { echo -e "${YELLOW}  → $*${NC}"; }

PRODUCTION=false
[[ "${1:-}" == "--production" ]] && PRODUCTION=true

# ── Verifica que postgres acepta conexiones reales (no solo pg_isready) ────
check_postgres_auth() {
  docker exec gesap-postgres psql -U postgres -c "SELECT 1;" > /dev/null 2>&1
}

wait_postgres() {
  local attempts=0
  info "Esperando postgres..."
  while [ $attempts -lt 30 ]; do
    if docker exec gesap-postgres pg_isready -U postgres > /dev/null 2>&1; then
      if check_postgres_auth; then
        ok "Postgres listo y autenticación OK"
        return 0
      else
        fail "Postgres responde pero la contraseña no coincide"
        echo ""
        echo "  Ejecuta esto para corregirlo:"
        echo "    docker exec -it gesap-postgres psql -U postgres -c \"ALTER USER postgres PASSWORD 'admin';\""
        echo ""
        exit 1
      fi
    fi
    attempts=$((attempts + 1))
    sleep 2
  done
  fail "Postgres no respondió después de 60s"
  exit 1
}

wait_http() {
  local name="$1" port="$2" attempts=0
  info "Esperando $name (puerto $port)..."
  while [ $attempts -lt 30 ]; do
    if curl -s --max-time 2 "http://localhost:$port" > /dev/null 2>&1; then
      ok "$name respondiendo"
      return 0
    fi
    attempts=$((attempts + 1))
    sleep 2
  done
  fail "$name no respondió después de 60s — revisa: docker logs $name --tail=30"
  exit 1
}

echo ""
echo -e "${CYAN}════════════════════════════════════${NC}"
echo -e "${CYAN}  GESAP — Iniciando sistema${NC}"
$PRODUCTION && echo -e "${CYAN}  Modo: PRODUCCIÓN (con nginx)${NC}" || echo -e "${CYAN}  Modo: backends${NC}"
echo -e "${CYAN}════════════════════════════════════${NC}"

# ── Paso 1: Postgres ────────────────────────────────────────────────────────
echo ""
echo "── Base de datos ───────────────────"
docker compose up -d postgres
wait_postgres

# ── Paso 2: Backends ────────────────────────────────────────────────────────
echo ""
echo "── Backends ────────────────────────"
docker compose up -d gesap-api gesap-auditor gesap-patient-portal

wait_http "gesap-api"            3100
wait_http "gesap-auditor"        3101
wait_http "gesap-patient-portal" 3102

# ── Paso 3: Nginx (solo en producción) ─────────────────────────────────────
if $PRODUCTION; then
  echo ""
  echo "── Nginx ───────────────────────────"
  docker compose --profile production up -d nginx
  ok "Nginx levantado en puerto 80"
fi

# ── Resumen ──────────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}════════════════════════════════════${NC}"
echo -e "${CYAN}  Estado final${NC}"
echo -e "${CYAN}════════════════════════════════════${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep gesap

echo ""
echo "  Endpoints:"
echo "    gesap-api            → http://localhost:3100"
echo "    gesap-auditor        → http://localhost:3101"
echo "    gesap-patient-portal → http://localhost:3102"
$PRODUCTION && echo "    nginx (público)      → http://localhost:80"
echo ""
echo -e "${GREEN}  Sistema listo.${NC}"
echo ""
