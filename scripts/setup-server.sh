#!/usr/bin/env bash
# GESAP — Configuración inicial del servidor Ubuntu
# Ejecutar UNA SOLA VEZ en el servidor Ubuntu Server
# Uso: bash scripts/setup-server.sh
#
# Requiere: Ubuntu 22.04/24.04, acceso sudo

set -e

echo "════════════════════════════════════════════"
echo "  GESAP — Setup servidor Ubuntu"
echo "════════════════════════════════════════════"

# ── Docker ────────────────────────────────────────────────────────────────────
echo ""
echo "── Instalando Docker ────────────────────────────────────"
if ! command -v docker &>/dev/null; then
  curl -fsSL https://get.docker.com | sudo sh
  sudo usermod -aG docker "$USER"
  echo "  ✅ Docker instalado — cierra sesión y vuelve a conectar para aplicar el grupo"
else
  echo "  ✅ Docker ya instalado"
fi

# ── pnpm (para el build de frontends) ────────────────────────────────────────
echo ""
echo "── Instalando Node.js y pnpm ────────────────────────────"
if ! command -v node &>/dev/null; then
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo apt-get install -y nodejs
fi
if ! command -v pnpm &>/dev/null; then
  sudo npm install -g pnpm
  echo "  ✅ pnpm instalado"
else
  echo "  ✅ pnpm ya instalado"
fi

# ── cloudflared ───────────────────────────────────────────────────────────────
echo ""
echo "── Instalando cloudflared ───────────────────────────────"
if ! command -v cloudflared &>/dev/null; then
  curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg \
    | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
  echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] \
https://pkg.cloudflare.com/cloudflared $(lsb_release -cs) main" \
    | sudo tee /etc/apt/sources.list.d/cloudflared.list
  sudo apt update && sudo apt install -y cloudflared
  echo "  ✅ cloudflared instalado"
else
  echo "  ✅ cloudflared ya instalado"
fi

# ── Directorios www/ ──────────────────────────────────────────────────────────
echo ""
echo "── Creando directorios www/ ─────────────────────────────"
mkdir -p www/client-api www/client-auditor www/client-patient
echo "  ✅ Directorios listos"

echo ""
echo "════════════════════════════════════════════"
echo "  Setup completo."
echo ""
echo "  PRÓXIMOS PASOS:"
echo ""
echo "  1. Si es la primera vez con Docker, cierra y reconecta SSH"
echo ""
echo "  2. Configurar Cloudflare Tunnel:"
echo "       cloudflared tunnel login"
echo "       cloudflared tunnel create gesap"
echo "       (copia el TUNNEL-ID que aparece)"
echo ""
echo "  3. Editar cloudflared/config.yml con tu TUNNEL-ID y dominio"
echo ""
echo "  4. Crear registro DNS (un solo dominio gesap.lat):"
echo "       cloudflared tunnel route dns gesap gesap.lat"
echo ""
echo "  5. Instalar cloudflared como servicio:"
echo "       sudo mkdir -p /etc/cloudflared"
echo "       sudo cp cloudflared/config.yml /etc/cloudflared/config.yml"
echo "       sudo cloudflared service install"
echo "       sudo systemctl enable --now cloudflared"
echo ""
echo "  6. nginx/nginx.conf ya usa gesap.lat — no requiere edición de dominio"
echo ""
echo "  7. Copiar y editar variables de entorno:"
echo "       cp .env.prod.example .env.prod"
echo "       nano .env.prod   ← cambia contraseña DB y JWT_SECRET"
echo "       (genera JWT_SECRET con: openssl rand -hex 64)"
echo ""
echo "  8. Compilar frontends:"
echo "       bash scripts/build-frontends.sh"
echo ""
echo "  9. Levantar todo:"
echo "       docker compose --env-file .env.prod --profile production up -d --build"
echo ""
echo "  10. Seed de la base de datos (primera vez):"
echo "       docker exec gesap-api sh -c 'cd /app && npx prisma db seed 2>/dev/null || node dist/src/prisma/seed.js'"
echo "════════════════════════════════════════════"
