# TattooTime V2

[![React](https://img.shields.io/badge/React-18+-61DAFB?style=for-the-badge&logo=react&logoColor=black)](https://react.dev)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.x-3178C6?style=for-the-badge&logo=typescript&logoColor=white)](https://www.typescriptlang.org)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Material-UI](https://img.shields.io/badge/Material--UI-007FFF?style=for-the-badge&logo=mui&logoColor=white)](https://mui.com)

Webanwendung zur Verwaltung von Tattoo-Terminen mit Echtzeit-Datenbankanbindung, Firebase Authentication und vollständigem Admin-Bereich für Studio-Betreiber. V2 der TattooTime-App mit überarbeitetem UI auf Basis von Material-UI.

---

## Projektüberblick

| Eigenschaft | Details |
|---|---|
| **Frontend** | React 18, TypeScript, Material-UI |
| **Backend** | Firebase (Auth, Firestore, Functions, Hosting) |
| **E-Mail** | Automatischer Versand über Firestore-Trigger |
| **Routing** | React Router |
| **Deployment** | Firebase Hosting |

---

## Funktionen

- **Benutzerauthentifizierung** — Registrierung, Login und Logout via Firebase Authentication
- **Dashboard** — Übersicht über eigene Termine mit Kalenderansicht
- **Terminbuchung** — Kunden können freie Slots auswählen und buchen
- **Admin-Bereich** — Vollständige Verwaltung aller Termine, Slots und Terminarten
- **E-Mail-Benachrichtigung** — Automatische Bestätigungsmails an Kunden und Admins
- **Rollenverwaltung** — Admin-Rolle über Firestore oder Cloud Function steuerbar

---

## Installation & Entwicklung

```bash
git clone https://github.com/tib019/tattootimeV2.git
cd tattootimeV2/tattootime
npm install
npm start
```

Die App läuft dann unter `http://localhost:3000`.

---

## Deployment (Firebase Hosting)

```bash
npm run build
firebase deploy
```

---

## Admin-Rolle vergeben

Die Admin-Rolle kann auf zwei Wegen vergeben werden:

1. In Firestore (Collection `users`) das Feld `isAdmin` auf `true` setzen
2. Cloud Function `setAdmin` mit der E-Mail-Adresse aufrufen

---

## Firestore-Datenstruktur

| Collection | Beschreibung |
|---|---|
| `users` | User-Daten inkl. Rolle |
| `slots` | Termin-Slots (Datum, Zeit, Service, isBooked) |
| `appointments` | Gebuchte Termine |
| `mail` | E-Mail-Queue für Bestätigungen |

---

## Tests

```bash
cd tattootime
npm test
```

35 Tests (Unit, Funktions-, Regressionstests) mit Jest und React Testing Library.

---

## Dokumentation

- [DOKUMENTATION.md](DOKUMENTATION.md) — Vollständige Projektdokumentation
- [PHASE2_SUMMARY.md](PHASE2_SUMMARY.md) — Phase 2 Zusammenfassung
- [PHASE3_SUMMARY.md](PHASE3_SUMMARY.md) — Phase 3 Zusammenfassung

---

## Autor

**Tobias Buss** — [@tib019](https://github.com/tib019)
