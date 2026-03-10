# GESAP - Sistema de Gestion de Atencion a Pacientes
# GESAP - Sistema de Gestion de Atencion a Pacientes

Sistema hospitalario para la gestion de pacientes, desarrollado como proyecto final de Fundacion Kinal.

## Arquitectura

| Servicio | Puerto | Descripcion |
|----------|--------|-------------|
| gesap-api | 3000 | API principal (auth, roles, users, patients) |
| gesap-auditor | 3001 | Auditoria (logs, sesiones, horarios, dispositivos) |
| gesap-patient-portal | 3002 | Portal de pacientes (autoregistro, perfil, emergencias) |
| PostgreSQL | 5432 | Base de datos |

## Stack Tecnologico

- NestJS + TypeScript
- Prisma ORM + PostgreSQL
- JWT (passport-jwt) + bcrypt
- Socket.io (sesiones en tiempo real)
- Docker + Docker Compose

## Inicio Rapido con Docker

```bash
docker-compose up -d
```

## Inicio Manual (desarrollo)

1. Tener PostgreSQL corriendo en localhost:5432
2. Crear las bases de datos: `gesap_db` y `gesap_auditor_db`
3. En cada carpeta de servicio:
```bash
npm install
cp .env.example .env
npx prisma generate
npx prisma migrate dev --name init
npm run start:dev
```
4. En gesap-api, ejecutar el seed:
```bash
npx ts-node prisma/seed.ts
```

## Credenciales por Defecto

- Email: `auditor@gesap.gt`
- Password: `GESAP2024!`
