# Remedia — Guide de mise en route

## 1. Créer le projet Firebase

1. Va sur [console.firebase.google.com](https://console.firebase.google.com)
2. Crée un projet nommé `remedia`
3. Active **Authentication** → Email/Mot de passe
4. Active **Firestore Database** (mode production)
5. Active **Storage**

## 2. Configurer Firebase dans Flutter

```bash
dart pub global activate flutterfire_cli
cd remedia
flutterfire configure
```

Sélectionne le projet `remedia` — cela génère `lib/firebase_options.dart` automatiquement.

## 3. Déployer les règles Firestore

```bash
firebase init firestore   # si pas déjà fait
firebase deploy --only firestore:rules
```

## 4. Lancer l'app

```bash
flutter run
```

---

## Structure du projet

```
lib/
├── main.dart                  # Entrée, init Firebase
├── app.dart                   # MaterialApp.router
├── firebase_options.dart      # Généré par flutterfire configure
├── core/
│   ├── theme/app_theme.dart   # Thème Nunito + vert #4CAF50
│   └── widgets/
│       ├── medical_disclaimer.dart
│       └── loading_widget.dart
├── models/                    # Remedy, Comment, UserProfile, Report
├── services/                  # AuthService, RemedyService, CommentService
├── providers/providers.dart   # Riverpod (auth, remedies, comments)
├── router/app_router.dart     # GoRouter
└── screens/
    ├── auth/                  # Login, Register
    ├── home/                  # HomeScreen (liste + filtres)
    ├── search/                # SearchScreen
    ├── remedy/                # RemedyDetail, CreateRemedy, RemedyCard
    └── profile/               # ProfileScreen (mes remèdes, favoris)
```

## Stack technique

| Couche | Technologie |
|--------|-------------|
| UI | Flutter (Dart) |
| State | Riverpod 2 |
| Navigation | GoRouter |
| Backend | Firebase (Auth, Firestore, Storage) |
| Fonts | Google Fonts — Nunito |
