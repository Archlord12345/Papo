# PAPO Backend

API REST NestJS pour le wallet PAPO/PayPoint.

## Ce que fait ce backend

- Authentification JWT avec inscription et connexion
- Gestion des utilisateurs et du statut KYC
- Gestion de wallets multi-comptes
- Catalogue de tokens
- Transactions online et offline avec signature et synchronisation
- Simulation d'ancrage blockchain

## Important sur Appwrite

Ce backend n'utilise pas Appwrite actuellement.

- Pas de SDK Appwrite
- Pas d'auth Appwrite
- Pas de Database Appwrite
- Pas de Storage Appwrite
- Pas de Functions Appwrite

La stack actuelle repose sur NestJS + Prisma + SQLite/PostgreSQL.

## Configuration

Copier le fichier d'exemple:

```bash
cp .env.example .env
```

Variables supportées:

```env
PORT=3000
DATABASE_URL=file:./dev.db
JWT_SECRET=change-me-jwt-secret
JWT_EXPIRATION=24h
ENCRYPTION_KEY=change-me-encryption-key-32-bytes
```

PostgreSQL est aussi supporté:

```env
DATABASE_URL=postgresql://papo_user:papo_password@localhost:5432/papo_db
```

## Démarrage local

Installer les dépendances:

```bash
npm install
```

Initialiser la base locale SQLite:

```bash
npx prisma db push
```

Lancer l'API:

```bash
npm run start:dev
```

URLs utiles:

- API: `http://localhost:3000/api/v1`
- Swagger: `http://localhost:3000/api/docs`

## PostgreSQL avec Docker

Pour lancer PostgreSQL:

```bash
docker compose up -d
```

Puis définir `DATABASE_URL` dans `.env` et synchroniser le schéma:

```bash
npx prisma db push
```

## Vérification

Tests unitaires:

```bash
npm test -- --runInBand
```

Vérification d'intégration locale:

```bash
npm run test:local
```

## Limites actuelles

- Le frontend Flutter n'est pas encore branché à cette API
- Le KYC et la biométrie sont partiellement simulés
- Le stockage de documents n'est pas implémenté
- Les tâches asynchrones sont mockées côté serveur
