# NIC Live Monitor – Echtzeit Netzwerk-Interface Überwachung (Windows, PowerShell, WinForms)

## 📌 Überblick
**NIC Live Monitor** ist ein PowerShell-Skript mit grafischer Oberfläche (WinForms), das in Echtzeit alle aktiven Netzwerk-Interfaces (NICs) überwacht.  
Es zeigt **Summenwerte** für RX/TX, Drops und Errors sowie eine **5er-History pro NIC** an – optimiert für **Live-Streaming-Umgebungen**.

## 📷 Screenshot

![NIC Live Monitor – Dark-Mode OBS Style](docs/screenshot_darkmode_obs.png)

---

## ✨ Funktionen
- **Echtzeitdarstellung** aller aktiven Netzwerk-Interfaces
- **Summenanzeige** (alle NICs kombiniert) oben im Header
- **4er-History pro NIC** mit Zeit, RX/TX (Mbit/s), Drops, Errors
- **Dark-Mode (OBS-Style)** für bessere Lesbarkeit im Studio
- **Farb-Highlighting** bei Alarmwerten
- **Keine zusätzliche Last** wie bei Tools wie *htop* oder *Task Manager*
- Optimiert für **kontinuierliche 24/7-Anzeige** auf einem Streaming-Monitor

---

## 🚀 Warum nicht einfach ein fertiges Tool?
Es gibt viele fertige Monitoring-Tools – **aber keines passte exakt zu meinem Einsatzzweck**:

| Anforderung | Problem bei Standardtools | Vorteil dieses Skripts |
|-------------|---------------------------|------------------------|
| **Geringe Systemlast** | Viele Tools erzeugen durch unnötige Visualisierungen oder ständige Hardware-Scans hohe CPU-Last. | Minimaler Overhead, optimierte Abfragen nur für benötigte Daten. |
| **Optimiert für Live-Streaming** | Standardtools zeigen CPU, RAM, GPU, Festplatten an – Netzwerkwerte gehen unter. | Fokus ausschließlich auf NIC-Performance. |
| **Dark-Mode im OBS-Stil** | Unpassende Farben oder zu grelle GUIs. | Farbpalette passend zu OBS für bessere Integration. |
| **Summenanzeige mehrerer NICs** | Meist nur Einzel-Interface-Ansicht. | Aggregierte Werte aller aktiven NICs. |
| **Einfache Portabilität** | Viele Tools müssen installiert werden. | Reines `.ps1`-Skript, direkt lauffähig. |

---

## 🛠 Technische Details
- **Sprache:** PowerShell 5.1 (Windows)
- **GUI:** Windows Forms (`System.Windows.Forms`)
- **Farbschema:** Angepasst an OBS Studio
- **Abfrageintervall:** 1 Sekunde (konfigurierbar)
- **History:** Standardmäßig 4 Einträge pro NIC (konfigurierbar)
- **Lizenz:** MIT

---

## 📂 Dateien

- `NIC_Realtime_Monitor_GUI.ps1` – Hauptskript (PowerShell 5.1, WinForms)
- `Start_NIC_Monitor_GUI.vbs` – Startet das Skript ohne sichtbares PowerShell-Fenster
- `README.md` – Diese Dokumentation

---


## 📦 Installation
### Repository klonen
```powershell
git clone https://github.com/richtertoralf/RX-TX_Monitor
cd RX-TX_Monitor
```

### ▶ Starten

1. Stelle sicher, dass **PowerShell 5.1** installiert ist (Standard bei Windows 10/11).
2. Entpacke alle Dateien in einen Ordner.
3. Starte **`Start_NIC_Monitor_GUI.vbs`** per Doppelklick.  
   → Die GUI öffnet sich im Vordergrund, ohne dass eine PowerShell-Konsole sichtbar ist.

### ⚙ Anpassungen

Im Kopfbereich des Skripts (`#region Config`) lassen sich folgende Werte anpassen:

- **Farben** (Dark-Mode, Textfarben, Akzentfarbe)
- **History-Fenster** in Sekunden (Standard: 4)
- **Polling-Intervall** für Messungen

---
## 📜 Lizenz

Dieses Projekt steht unter der MIT-Lizenz.  
Nutzen, Anpassen und Weiterverbreiten ist ausdrücklich erlaubt.
