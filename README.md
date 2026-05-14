# Debiti & Crediti

App mobile Flutter per tenere traccia dei debiti e dei crediti con gli amici.

## Funzionalità

- **Lista amici** con saldo netto per ciascuno (verde = ti devono, rosso = devi tu)
- **Riepilogo globale** con totale crediti e debiti
- **Transazioni**: aggiungi debiti o crediti con descrizione e data
- **Eliminazione** amici e transazioni con conferma
- **Tema chiaro/scuro** automatico (segue il sistema)
- **Persistenza locale** con SQLite (funziona offline, nessun account richiesto)

## Struttura

```
lib/
├── main.dart                    # Entrypoint, tema, routing
├── models/
│   ├── friend.dart              # Modello Friend
│   └── transaction.dart         # Modello Transaction (credit/debt)
├── database/
│   └── database_helper.dart     # SQLite CRUD
├── providers/
│   └── app_provider.dart        # State management con Provider
└── screens/
    ├── home_screen.dart          # Lista amici + banner saldi
    ├── friend_detail_screen.dart # Transazioni per un amico
    ├── add_transaction_screen.dart  # Form nuova transazione
    └── add_friend_screen.dart    # Form nuovo amico
```

## Come eseguire

```bash
# Installa dipendenze
flutter pub get

# Esegui su emulatore/dispositivo
flutter run

# Build per Android
flutter build apk --release

# Build per iOS (richiede macOS + Xcode)
flutter build ios --release
```

## Dipendenze principali

| Pacchetto | Versione | Uso |
|-----------|---------|-----|
| `sqflite` | ^2.3.0 | Database SQLite locale |
| `provider` | ^6.1.1 | State management |
| `intl` | ^0.19.0 | Formattazione valuta e date |
| `uuid` | ^4.3.3 | ID univoci per record |
| `google_fonts` | ^6.1.0 | Tipografia |

## Estensioni future

- Sync cloud (Firebase Firestore)
- Export CSV/PDF
- Notifiche reminder
- Widget condivisi per saldare i debiti
