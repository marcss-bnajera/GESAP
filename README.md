# GESAP — Sistema de Gestión de Atención a Pacientes

Sistema de salud pública del Ministerio de Salud Pública y Asistencia Social (MSPAS) de Guatemala. Gestiona emergencias prehospitalarias, expedientes clínicos, sesiones de usuarios y auditoría en tiempo real para los 44 establecimientos de salud del país.

## Arquitectura

```
gesap.lat/              → Portal Pacientes  (client-patient-gesap)
gesap.lat/auditor/      → Panel Auditoría   (client-auditor-gesap)
gesap.lat/clinico/      → Portal Clínico    (client-api-gesap)
                              ↓ API
                        gesap-api        :3000  (lógica clínica principal)
                        gesap-auditor    :3001  (auditoría y sesiones)
                        gesap-patient-portal :3002  (portal pacientes)
                              ↓
                        PostgreSQL gesap_db (compartida entre los 3 backends)
```

## Submódulos

| Repo | Descripción |
|------|-------------|
| `gesap-api` | API principal — usuarios, pacientes, emergencias, WebSocket `/api-ws` |
| `gesap-auditor` | Servicio de auditoría — sesiones, bitácora, kick en tiempo real, WebSocket `/auditor-ws` |
| `gesap-patient-portal` | Portal de pacientes — autoregistro, expediente, IA con Groq |
| `client-api-gesap` | Frontend clínico — doctores y asistentes (React + Vite, base `/clinico/`) |
| `client-auditor-gesap` | Panel de auditoría — AUDITOR y SUPER_AUDITOR (React + Vite, base `/auditor/`) |
| `client-patient-gesap` | Portal de pacientes — registro y consulta (React + Vite, base `/`) |

## Levantar con Docker

```bash
# Clonar el repo con todos los submódulos
git clone --recurse-submodules git@github.com:marcss-bnajera/GESAP.git
cd GESAP

# Desarrollo (solo backends + base de datos)
docker compose up -d

# Producción (incluye nginx sirviendo los frontends compilados)
bash scripts/build-frontends.sh          # compila los 3 frontends en www/
docker compose --env-file .env.prod up -d --build
```

## Variables de entorno para producción

```bash
cp .env.prod.example .env.prod
# Editar .env.prod con los valores reales
```

Variables requeridas: `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`, `JWT_SECRET`.

## Puertos en Docker

| Servicio | Puerto (host) |
|----------|--------------|
| PostgreSQL | `5433` |
| gesap-api | `3100` |
| gesap-auditor | `3101` |
| gesap-patient-portal | `3102` |
| nginx (prod) | `80` |

## Credenciales de prueba

Correr el seed desde gesap-api para crear los usuarios de prueba:

```bash
docker exec -it gesap-api sh -c \
  "DATABASE_URL=postgresql://postgres:admin@postgres:5432/gesap_db?schema=public \
   npx ts-node prisma/seed.ts"
```

| Email | Contraseña | Rol |
|-------|-----------|-----|
| `superauditor@gesap.gt` | `GESAP2026!` | SUPER_AUDITOR |
| `auditor@gesap.gt` | `GESAP2026!` | AUDITOR (HSJD) |
| `dr.lopez@gesap.gt` | `Doctor2026!` | DOCTOR (HSJD) |
| `asistente.pre@gesap.gt` | `Asistente2026!` | ASISTENTE_PREHOSPITALARIO |
| `asistente.rec@gesap.gt` | `Asistente2026!` | ASISTENTE_RECEPCION_CLINICA (HSJD) |

## URLs de Swagger (desarrollo)

| Servicio | URL |
|----------|-----|
| gesap-api | http://localhost:3000/gesap/v1/docs |
| gesap-auditor | http://localhost:3001/gesap-auditor/v1/docs |
| gesap-patient-portal | http://localhost:3002/gesap-portal/v1/docs |

## Stack completo

| Capa | Tecnología |
|------|-----------|
| Backend | NestJS + TypeScript + Prisma ORM |
| Base de datos | PostgreSQL 15 |
| Autenticación | JWT (24h) |
| WebSocket | Socket.IO (kick en tiempo real) |
| Frontend | React 18 + Vite + Tailwind CSS v4 + Zustand |
| Proxy / Serve | nginx (producción) |
| Tunnel | Cloudflare Tunnel (gesap.lat) |
| IA | Groq API — Llama 3 (asistente de pacientes) |
