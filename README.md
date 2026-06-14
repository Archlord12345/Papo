# PAPO

Monorepo d'une application wallet PAPO/PayPoint avec:

- une application Flutter dans la racine du dépôt
- une API NestJS dans `backend/`

## Architecture

### Frontend Flutter

Le frontend fournit l'expérience utilisateur:

- onboarding et authentification
- dashboard wallet
- transactions
- mode offline
- KYC
- sécurité
- espace marchand
- espace admin

Important: l'application Flutter est aujourd'hui principalement une démo locale pilotée par `AppState`. Elle n'appelle pas encore réellement l'API backend.

### Backend NestJS

Le backend expose la logique métier réelle:

- auth JWT
- utilisateurs
- wallets
- tokens
- transactions online/offline
- KYC
- simulation blockchain

Documentation backend: [backend/README.md](file:///workspace/backend/README.md)

## Appwrite

Le projet n'est pas connecté à Appwrite à ce jour.

- aucune dépendance Appwrite détectée
- aucune variable d'environnement Appwrite
- aucun flux Auth/DB/Storage/Functions Appwrite

La stack actuelle est `Flutter + NestJS + Prisma + SQLite/PostgreSQL`.

## Démarrage

### Backend

Voir [backend/README.md](file:///workspace/backend/README.md).

### Frontend

Le frontend nécessite un environnement Flutter local:

```bash
flutter pub get
flutter run
```

## État actuel du système

- Le backend peut être configuré et lancé localement
- Les tests unitaires backend passent
- Le frontend n'est pas encore câblé end-to-end avec le backend
- Une intégration Appwrite demanderait une conception supplémentaire
