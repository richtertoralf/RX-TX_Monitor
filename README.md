# NIC Live Monitor – Kleiner Helfer für Netzwerk-Überwachung in Echtzeit (Windows, PowerShell, WinForms)

## 🖥 Was ist das?
**NIC Live Monitor** ist ein kleines PowerShell-Skript mit einer schlanken grafischen Oberfläche (WinForms).  
Es zeigt dir in **Echtzeit**, was deine Netzwerk-Interfaces (NICs) gerade tun – ideal für Situationen, in denen du *nur* schnell und klar die Netzwerkauslastung im Blick haben willst.  
Zum Beispiel bei **Live-Streaming** oder anderen Dauerübertragungen.

## 📷 So sieht’s aus
![So sieht’s aus](./Screenshot%202025-08-15%20010536.png) 

---

## ✨ Was kann es?
- **Summenanzeige** für RX/TX aller aktiven NICs
- **History pro NIC** (Standard: letzte 4 Messwerte)
- **Dark-Mode im OBS-Stil** – passt perfekt ins Studio-Setup
- **Farb-Highlighting** bei Fehlern/Drops
- **Sehr geringe Systemlast** – läuft nebenbei, ohne zu nerven
- **Optimiert für Dauerbetrieb** (24/7-Anzeige möglich)

---

## 🤔 Warum nicht einfach ein fertiges Tool nehmen?
Weil die meisten „fertigen“ Tools für meinen Einsatzzweck zu viel oder das Falsche machen:

| Mein Bedarf | Problem bei Standardtools | Vorteil hier |
|-------------|---------------------------|--------------|
| **Wenig Last** | Viele Tools belasten die CPU durch bunte Visualisierungen oder Hardware-Scans. | Minimaler Overhead – fragt nur die wirklich nötigen Werte ab. |
| **Streaming-Fokus** | Standardtools zeigen alles Mögliche (CPU, RAM, GPU…) – Netzwerkteil geht unter. | Fokus ausschließlich auf NIC-Performance. |
| **Passende Optik** | Farben passen nicht ins Studio, oft zu grell. | Dark-Mode im OBS-Stil. |
| **Summen über mehrere NICs** | Meist nur Einzel-Interface-Anzeige. | Kombinierte Werte im Header. |
| **Keine Installation** | Viele Tools müssen installiert oder mit Adminrechten eingerichtet werden. | Einfach `.ps1` starten – fertig. |

---

## 🛠 Technisches
- **Sprache:** PowerShell 5.1 (Windows)
- **GUI:** Windows Forms
- **Farbschema:** Angepasst an OBS Studio
- **Abfrageintervall:** 1 Sekunde (änderbar)
- **History:** Standard 4 Einträge pro NIC (änderbar)
- **Lizenz:** MIT

---

## 📂 Dateien im Paket
- `NIC_Realtime_Monitor_GUI.ps1` – das eigentliche Skript
- `Start_NIC_Monitor_GUI.vbs` – startet das Skript ohne sichtbares PowerShell-Fenster
- `README.md` – diese Beschreibung

---

## 🚀 Starten
1. Stelle sicher, dass **PowerShell 5.1** installiert ist (ist bei Windows 10/11 standardmäßig der Fall).
2. Entpacke alles in einen Ordner.
3. Starte **`Start_NIC_Monitor_GUI.vbs`** per Doppelklick.  
   → Die GUI öffnet sich im Vordergrund, keine PowerShell-Konsole sichtbar.

---

## ⚙ Anpassen
Oben im Skript (`#region Config`) kannst du u. a. ändern:
- **Farben** (Dark-Mode, Textfarbe, Akzentfarbe)
- **History-Länge**
- **Messintervall**

---

## 📜 Lizenz
MIT-Lizenz – nutzen, anpassen, weitergeben, wie du willst.
