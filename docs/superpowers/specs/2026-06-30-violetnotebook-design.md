# Design-Spezifikation: VioletNotebook

VioletNotebook ist eine native macOS-Umsetzung der beliebten Open-Source-Tagebuchanwendung **RedNotebook** in Swift und SwiftUI. 

Ziel ist eine **100%ige Kompatibilität mit dem Dateiformat von RedNotebook**, so dass bestehende Tagebücher nahtlos eingehängt, gelesen und weitergeschrieben werden können.

---

## 1. Systemarchitektur & Datenmodell

### 1.1 Verzeichniszugriff (macOS App Sandbox)
Da die App unter macOS standardmäßig in einer Sandbox läuft, wird der Zugriff auf den Tagebuch-Ordner wie folgt gelöst:
*   Der Benutzer wählt das Tagebuch-Verzeichnis über ein `NSOpenPanel` aus.
*   Die App erstellt ein dauerhaftes Sicherheits-Bookmark (Security-Scoped Bookmark) und speichert dieses als `Data` in den `UserDefaults` ab.
*   Beim App-Start wird dieses Bookmark aufgelöst, um Lese- und Schreibzugriff ohne erneute Benutzerinteraktion zu erhalten.

### 1.2 Dateistruktur des Tagebuchs
Ein kompatibler RedNotebook-Ordner hat folgende Struktur:
*   `data/` (oder das Stammverzeichnis selbst):
    *   `YYYY-MM.txt` (z.B. `2026-06.txt`): Monatliche Logdateien im YAML-Format.
*   `configuration.cfg`: Konfigurationsdatei im Format `key=value`.
*   `templates/`: Ordner mit Vorlagendokumenten (Textdateien mit txt2tags-Markup).
*   `images/`: Ordner für im Tagebuch referenzierte Bilder.

### 1.3 Datenmodell in Swift (YAML-Kompatibilität)
Die monatlichen Dateien (`YYYY-MM.txt`) werden mithilfe der `Yams`-Bibliothek geparst.
Das Datenmodell bildet die RedNotebook-Struktur exakt ab:

```swift
import Foundation

/// Repräsentiert die Struktur eines einzelnen Tageseintrags im YAML
struct DayData: Codable, Equatable {
    var text: String
    
    // Dynamische Kategorien/Tags (z.B. "Arbeit: {Task 1: null, Task 2: null}")
    // Da Kategorien in YAML als Key-Value-Map mit optionalen Sub-Einträgen vorliegen,
    // bilden wir sie als Dictionary ab, wobei der Value meist null (nil) ist.
    var extraCategories: [String: [String: String?]]?
    
    enum CodingKeys: String, CodingKey {
        case text
    }
    
    // Custom Encoder/Decoder, um sowohl 'text' als auch dynamische Kategorien zu unterstützen
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
        self.text = try container.decode(String.self, forKey: DynamicCodingKeys(stringValue: "text")!)
        
        var extra: [String: [String: String?]] = [:]
        for key in container.allKeys {
            if key.stringValue != "text" {
                if let dict = try? container.decode([String: String?].self, forKey: key) {
                    extra[key.stringValue] = dict
                } else if let isNull = try? container.decodeNil(forKey: key), isNull {
                    extra[key.stringValue] = [:]
                }
            }
        }
        self.extraCategories = extra.isEmpty ? nil : extra
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKeys.self)
        try container.encode(text, forKey: DynamicCodingKeys(stringValue: "text")!)
        
        if let extra = extraCategories {
            for (category, subEntries) in extra {
                try container.encode(subEntries, forKey: DynamicCodingKeys(stringValue: category)!)
            }
        }
    }
}

struct DynamicCodingKeys: CodingKey {
    var stringValue: String
    init?(stringValue: String) {
        self.stringValue = stringValue
    }
    var intValue: Int?
    init?(intValue: Int) {
        return nil
    }
}
```

---

## 2. txt2tags Parser & Renderer

Das in RedNotebook verwendete Markup ist ein Subset von txt2tags. VioletNotebook übersetzt dieses Markup in HTML und rendert es über eine `WKWebView` (mit CSS für Premium-Optik).

### 2.1 Markup-Spezifikation
*   **Fett**: `**text**` $\rightarrow$ `<b>text</b>`
*   **Kursiv**: `//text//` $\rightarrow$ `<i>text</i>`
*   **Unterstrichen**: `__text__` $\rightarrow$ `<u>text</u>`
*   **Durchgestrichen**: `--text--` $\rightarrow$ `<s>text</s>`
*   **Titel**: `= H1 =` $\rightarrow$ `<h1>H1</h1>`, `== H2 ==` $\rightarrow$ `<h2>H2</h2>` (unterstützt bis Level 5)
*   **Linie**: `====================` (20 Zeichen `=` oder mehr) $\rightarrow$ `<hr />`
*   **Absätze**: Doppelte Zeilenumbrüche trennen Absätze $\rightarrow$ `<p>...</p>`
*   **Listen**: Zeilen, die mit `- ` oder `+ ` beginnen, werden als ungeordnete Listen formatiert.
*   **Farben**: `{Text|color:red}` oder `{Text|color:#HEX}` $\rightarrow$ `<span style="color:red">Text</span>`
*   **Bilder**: `[""bildname.png""]` $\rightarrow$ `<img src="file:///images/bildname.png" />`
*   **Links**: 
    *   Web-Links: `[Anzeige Text ""https://url""]` $\rightarrow$ `<a href="https://url">Anzeige Text</a>`
    *   Tagebuch-Links: `[2026-06-30]` oder `[Anzeige Text 2026-06-30]` $\rightarrow$ `<a href="violet://day/2026-06-30">Anzeige Text</a>`
*   **Hashtags**: Wörter, die mit `#` beginnen (z.B. `#projekt`), werden farblich hervorgehoben und indiziert.

---

## 3. Benutzeroberfläche & Navigation (Sidebar & Main Detail)

Das User Interface wird im macOS 13+ Look-and-Feel umgesetzt.

```
+-------------------------------------------------------------------+
|  [<] [>] [Heute]  Dienstag, 30. Juni 2026           [ Edit | Preview ] |
+-------------------------------------------------------------------+
|  [ Kalender ]      |  [ Toolbar: B / I / U / S / Link / Bild ]     |
|  <- Juni 2026 ->   |                                               |
|  Mo Di Mi Do Fr..  |  Hier steht der Tagebucheintrag.              |
|  1  2  3  4  5*    |                                               |
|  8  9  10 11 12    |  - Ein Listenpunkt                            |
|  ..                |  - Noch einer                                 |
|                    |                                               |
|  [ Sektionen ]     |  #Hashtags werden farbig hervorgehoben.       |
|  - Tags            |                                               |
|  - Suche           |                                               |
|  - Templates       |                                               |
|                    |                                               |
+-------------------------------------------------------------------+
| Status: Geladen    | Wortanzahl: 142 | Zeichen: 812                |
+-------------------------------------------------------------------+
```

### 3.1 Linke Spalte: Sidebar & Navigation
*   **Kalender-Grid**: 
    *   Ein Monatskalender, der Tage mit vorhandenen Einträgen dezent hervorhebt.
*   **Navigation-Sektionen**:
    *   **Tags**: Listet Hashtags und Kategorien alphabetisch auf.
    *   **Suche**: Volltextsuche über alle geladenen Monatsdateien.
    *   **Templates**: Liste aller Vorlagen aus dem `templates/`-Verzeichnis.

### 3.2 Rechte Spalte: Hauptbereich
*   **Top Toolbar**: Navigation, Datumstitel, Edit/Preview Segmented Control.
*   **Editor-Modus**: Textfeld mit Tastaturkürzeln (Cmd+B, etc.) und Wortstatistik.
*   **Vorschau-Modus**: WKWebView für formatiertes HTML und Link-Navigation.
