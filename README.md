# VioletNotebook 📓

Eine native, elegante macOS Journal- und Notizbuch-App, inspiriert vom klassischen RedNotebook, mit kalendarischer Organisation, Tag-Kategorisierung und lokaler Datenhaltung im offenen YAML/Markdown-Format.

---

## 🎯 1. Ziel der App

- **Zweck**:
  - Tägliche Tagebuch-, Journal- und Reflexionsnotizen über eine intuitive Kalendernavigation erfassen.
  - Tag-basierte Kategorisierung und Filterung von Einträgen.
  - Vorlagen-Unterstützung für strukturierte Tages- und Wochenreviews.
  - Vollständige Offline- und lokale Datenspeicherung: Einträge werden transparent im YAML-/Textformat gespeichert, wodurch Datenverlust und proprietäre Lock-ins ausgeschlossen sind.
- **Betriebssystem (OS)**: macOS 13.0 (Ventura) oder neuer (voll optimiert für macOS 14/15 und Apple Silicon).
- **Programmiersprache**: Swift (SwiftUI, Swift Package Manager, Yams YAML Parser).

---

## 🛠️ 2. Kompilierung & Ausführung

### Voraussetzungen
- macOS mit Xcode 15+ bzw. Swift Command Line Tools.

### Über Swift Package Manager bauen & testen
```bash
cd /Users/andreas/Code/VioletNotebook

# Release-Build
swift build -c release

# Tests ausführen
swift test

# Direkt ausführen
swift run
```

### Als vollständige macOS-App (.app) mit Icon paketieren
Das enthaltene Skript `build_app.sh` baut das Release-Binary und erstellt ein vollständiges macOS-App-Bundle inklusive konvertiertem `.icns`-Icon:

```bash
./build_app.sh
```

Anschließend kann die App gestartet werden:
```bash
open build/VioletNotebook.app
```

---

## 🚀 3. Umsetzungsstand & Vision

### ✅ Aktueller Umsetzungsstand
- [x] **Kalender-Navigation**: Schnelles Springen zu jedem Datum und Monatsübersicht.
- [x] **YAML-Persistenz via Yams**: Saubere Trennung von Metadaten, Tags und Textinhalt.
- [x] **Tag- & Kategoriensystem**: Vergabe und Filterung nach Schlagwörtern.
- [x] **App Packaging**: Automatisierter Build inklusive Icon-Generierung.

### 🔮 Vision & Nächste Schritte
- [ ] **Volltextsuche**: Schnelle, globale Suche über alle vergangenen Jahre und Monate.
- [ ] **Lokale Verschlüsselung**: Optionales Absichern privater Tagebucheinträge via Apple Keychain / AES-GCM.
- [ ] **Export & Backup**: Exportfunktion als formatiertes PDF, HTML oder zusammenfassende Markdown-Dokumente.
- [ ] **Statistiken & Streaks**: Visualisierung von Schreibgewohnheiten und Wortanzahlen über Zeiträume.
