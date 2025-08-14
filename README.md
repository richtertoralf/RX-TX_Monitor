# NIC Live Monitor – Echtzeit Netzwerk-Interface Überwachung (Windows, PowerShell, WinForms)

## 📌 Überblick
**NIC Live Monitor** ist ein PowerShell-Skript mit grafischer Oberfläche (WinForms), das in Echtzeit alle aktiven Netzwerk-Interfaces (NICs) überwacht.  
Es zeigt **Summenwerte** für RX/TX, Drops und Errors sowie eine **4er-History pro NIC** an – optimiert für **Live-Streaming-Umgebungen**.

Entwickelt wurde das Tool speziell für **SnowgamesLive**-Events, um die Netzwerk-Performance bei NDI-, SRT- und RTMP-Streams während Sportübertragungen im Blick zu behalten.

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

## 📦 Installation
1. **Repository klonen**  
   ```powershell
   git clone https://github.com/<DEIN_USERNAME>/nic-live-monitor.git
   cd nic-live-monitor

2. **Skript starten**
```
powershell -ExecutionPolicy Bypass -File .\NIC_Realtime_Monitor_GUI.ps1 -STA

```
