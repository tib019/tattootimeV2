# TattooTime V2 – Tattoo Termin App

[![React](https://img.shields.io/badge/React-18+-61DAFB?style=for-the-badge&logo=react&logoColor=black)](https://react.dev)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.x-3178C6?style=for-the-badge&logo=typescript&logoColor=white)](https://www.typescriptlang.org)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Material-UI](https://img.shields.io/badge/Material--UI-007FFF?style=for-the-badge&logo=mui&logoColor=white)](https://mui.com)

**TattooTime** ist eine moderne Webanwendung zur Verwaltung von Tattoo-Terminen. Sie bietet eine intuitive Oberfläche fuer Kunden und einen leistungsstarken Admin-Bereich fuer Studio-Betreiber.

---

## Projektueberblick

| Eigenschaft | Details |
|---|---|
| **Frontend** | React 18, TypeScript, Material-UI |
| **Backend** | Firebase (Auth, Firestore, Functions, Hosting) |
| **E-Mail** | Automatischer Versand ueber Firestore-Trigger |
| **Routing** | React Router |
| **Deployment** | Firebase Hosting |

---

## Funktionen

- **Benutzerauthentifizierung** - Registrierung, Login und Logout via Firebase Authentication
- **Dashboard** - Uebersicht ueber eigene Termine mit Kalenderansicht
- **Terminbuchung** - Kunden koennen freie Slots auswaehlen und buchen
- **Admin-Bereich** - Vollstaendige Verwaltung aller Termine, Slots und Terminarten
- **E-Mail-Benachrichtigung** - Automatische Bestaedigungsmails an Kunden und Admins
- **Rollenverwaltung** - Admin-Rolle ueber Firestore oder Cloud Function steuerbar

---

## Installation & Entwicklung


> tattootime@0.1.0 start
> react-scripts start

Die App laeuft dann unter http://localhost:3000.

---

## Deployment (Firebase Hosting)



---

## Admin-Rolle vergeben

Die Admin-Rolle kann auf zwei Wegen vergeben werden:

1. In Firestore (Collection ) das Feld  auf  setzen
2. Cloud Function  mit der E-Mail-Adresse aufrufen

---

## Cloud Functions API

| Funktion | Beschreibung | Input |
|---|---|---|
|  | Setzt Admin-Rolle fuer einen User |  |
|  | Bucht einen Slot und versendet Bestaedigungsmails |  |

---

## Firestore-Datenstruktur

| Collection | Beschreibung |
|---|---|
|  | User-Daten inkl. Rolle |
|  | Termin-Slots (Datum, Zeit, Service, isBooked) |
|  | Gebuchte Termine |
|  | E-Mail-Queue fuer Bestaedigungen |

---

## Dokumentation

- [DOKUMENTATION.md](DOKUMENTATION.md) - Vollstaendige Projektdokumentation
- [PHASE2_SUMMARY.md](PHASE2_SUMMARY.md) - Phase 2 Zusammenfassung
- [PHASE3_SUMMARY.md](PHASE3_SUMMARY.md) - Phase 3 Zusammenfassung

---

## Autor

**Tobias** - [@tib019](https://github.com/tib019)

---

## Lizenz

Dieses Projekt ist fuer private und Demonstrationszwecke erstellt.
