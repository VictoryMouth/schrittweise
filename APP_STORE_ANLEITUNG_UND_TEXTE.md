# 🚀 App Store Veröffentlichungs-Leitfaden für „Schrittweise“

Dieses Dokument enthält **alle fertigen Texte, Einstellungen, Links und Schritte**, die du benötigst, um die App **Schrittweise** im Apple App Store einzureichen.

---

## 📋 Übersicht der vorbereiteten Dateien

1. **Webseiten für GitHub Pages** (im Ordner `docs/`):
   - [`docs/index.html`](file:///Users/siegmundmurer/Desktop/SCORM/Xcode/Schritte-Apple%20Watch/docs/index.html) – Offizielle Landing Page & Marketing-Website
   - [`docs/privacy.html`](file:///Users/siegmundmurer/Desktop/SCORM/Xcode/Schritte-Apple%20Watch/docs/privacy.html) – Vollständige Datenschutzerklärung (Pflicht für HealthKit!)
   - [`docs/support.html`](file:///Users/siegmundmurer/Desktop/SCORM/Xcode/Schritte-Apple%20Watch/docs/support.html) – Hilfe, FAQ und Support-Kontaktseite
   - [`docs/styles.css`](file:///Users/siegmundmurer/Desktop/SCORM/Xcode/Schritte-Apple%20Watch/docs/styles.css) – Responsives Apple-Design mit Dark/Light Mode

2. **Fertige App Store Screenshots** (exakte Pixelmaße nach Apple-Vorgaben):
   - **iPhone (1290 x 2796 px – 6.7" / 6.9" Display)**:
     - `AppStore_Screenshots/iPhone/01_iPhone_Tagesfortschritt.png`
     - `AppStore_Screenshots/iPhone/02_iPhone_Wochenhistorie.png`
     - `AppStore_Screenshots/iPhone/03_iPhone_Ziele_Motivation.png`
   - **Apple Watch (410 x 502 px – Ultra & Series 9/10)**:
     - `AppStore_Screenshots/AppleWatch/01_Watch_App.png`
     - `AppStore_Screenshots/AppleWatch/02_Watch_Komplikationen.png`

3. **Code-Anpassung**:
   - Die Test-Buttons („Testschritte simulieren“) wurden mit `#if DEBUG` gekapselt, sodass sie in der offiziellen App Store Version für Endkunden automatisch ausgeblendet sind (wichtig zur Vermeidung von Review-Ablehnungen).

---

## 🌐 1. GitHub Pages aktivieren (für Support & Datenschutz URLs)

Apple verlangt zwingend eine **Datenschutz-URL** und eine **Support-URL**. So aktivierst du sie kostenlos über GitHub Pages:

1. Öffne dein Repository auf GitHub.
2. Gehe auf **Settings** &rarr; **Pages** (in der linken Seitenleiste).
3. Unter **Build and deployment**:
   - Source: **Deploy from a branch**
   - Branch: **main** (oder master) & Ordner: **/docs**
4. Klicke auf **Save**.
5. Nach ca. 1–2 Minuten ist deine Website online unter:
   - Landing Page: `https://victorymouth.github.io/schrittweise/`
   - Datenschutzerklärung: `https://victorymouth.github.io/schrittweise/privacy.html`
   - Support & FAQ: `https://victorymouth.github.io/schrittweise/support.html`

*(Ersetze `<dein-github-username>` und `<repo-name>` durch deinen GitHub-Account und Repository-Namen).*

---

## ✍️ 2. Texte für App Store Connect (Einfach kopieren & einfügen)

Melde dich unter [appstoreconnect.apple.com](https://appstoreconnect.apple.com) an und lege unter **Meine Apps** mit dem `+`-Symbol eine neue App an.

### A. Allgemeine App-Informationen
- **Name (max. 30 Zeichen)**:
  ```text
  Schrittweise: Schrittzähler
  ```
- **Untertitel (max. 30 Zeichen)**:
  ```text
  Schritte, Distanz & Kalorien
  ```
- **Primäre Kategorie**:
  `Gesundheit und Fitness` (Health & Fitness)
- **Sekundäre Kategorie (optional)**:
  `Lifestyle` oder `Hilfsprogramme`
- **Bundle-ID**:
  `com.siegmundmurer.schritte`
- **SKU**:
  `SCHRITTWEISE001`
- **Altersfreigabe**:
  Fragebogen ausfüllen &rarr; überall „Nein“ wählen &rarr; Ergebnis: **4+**

---

### B. Preis und Verfügbarkeit
- **Preis**: `Kostenlos` (0,00 €)
- **Verfügbarkeit**: Alle Länder und Regionen (oder nach Wunsch)

---

### C. App-Datenschutz (Privacy Nutrition Labels)
Apple fragt im Bereich **App-Datenschutz** nach der Datenerfassung:
- **Erfasst du oder deine Drittanbieter Daten aus dieser App?**
  &rarr; Wähle: **Nein, wir erfassen keine Daten aus dieser App.**
  *(Begründung: Alle HealthKit-Daten werden ausschließlich auf dem iPhone/der Watch lokal verarbeitet, es gibt keine Tracker, keine Analyse-Tools und keine externen Server).*

---

### D. Version 1.0.0 – Metadaten & Beschreibungen

- **Werbetext (Promotional Text – max. 170 Zeichen)**:
  ```text
  Erreiche deine täglichen Schrittziele mit Schrittweise: Flüssiger Aktivitätsring, smarte Apple Watch Komplikationen und 100 % Datenschutz ohne Werbung oder Abos.
  ```

- **Suchbegriffe / Keywords (max. 100 Zeichen, kommagetrennt, ohne Leerzeichen)**:
  ```text
  schrittzähler,schritte,pedometer,healthkit,apple watch,fitness,gesundheit,distanz,kalorien,aktivität
  ```

- **Support-URL**:
  ```text
  https://victorymouth.github.io/schrittweise/support.html
  ```

- **Marketing-URL (optional)**:
  ```text
  https://victorymouth.github.io/schrittweise/
  ```

- **Datenschutzrichtlinie-URL (Zwingend erforderlich!)**:
  ```text
  https://victorymouth.github.io/schrittweise/privacy.html
  ```

- **Copyright**:
  ```text
  © 2026 Siegmund Murer
  ```

- **Versionshinweise (Was ist neu in Version 1.0.0)**:
  ```text
  Willkommen bei Schrittweise!
  • Flüssig animierter Aktivitätsring für deine täglichen Schritte
  • Anzeige von Distanz (km) und aktiven Kalorien (kcal)
  • 7-Tage-Historie mit übersichtlichem Balkendiagramm
  • Vollständige Apple Watch App mit Live-Synchronisation
  • 3 verschiedene Komplikationen für dein Apple Watch Zifferblatt
  • Smarte, motivierende Zwischenstands-Mitteilungen
  • 100 % Privatsphäre: Keine Werbung, kein Tracking, alle Daten verbleiben auf deinen Geräten
  ```

- **Vollständige Beschreibung (Description)**:
  ```text
  Schrittweise ist dein moderner, minimalistischer Schrittzähler für iPhone und Apple Watch – entwickelt mit Fokus auf Ästhetik, Motivation und kompromisslosen Datenschutz.

  FUNKTIONEN IM ÜBERBLICK:

  🎯 DYNAMISCHER FORTSCHRITTS-RING
  Verfolge deine täglichen Schritte in Echtzeit mit einem flüssig animierten Fortschrittsring. Sieh auf einen Blick deinen aktuellen Prozentsatz und wie viele Schritte dir noch bis zum Tagesziel fehlen.

  🔥 DISTANZ & KALORIEN
  Zusätzlich zu deinen Schritten berechnet Schrittweise automatisch deine zurückgelegte Geh- und Laufstrecke in Kilometern sowie deine aktiv verbrannten Kalorien.

  📊 7-TAGE-HISTORIE & TRENDS
  Ein übersichtliches Balkendiagramm zeigt dir deine Aktivität der letzten 7 Tage. Erreichte Ziele werden sofort optisch hervorgehoben, damit du deine Serie nicht abreißen lässt.

  ⌚ VOLLE APPLE WATCH UNTERSTÜTZUNG
  • Eigenständige Watch-App mit flüssiger Visualisierung und Statusübersicht.
  • 3 Zifferblatt-Komplikationen: Wähle zwischen detaillierter Ring-Ansicht („Schritte & Fortschritt“), extragroßer Schrittzahl („Nur Schritte“) oder Countdown („Verbleibende Schritte“).
  • Schnelle, akkuschonende Hintergrund-Aktualisierungen direkt aus Apple Health.

  🔔 SMARTE MOTIVATION
  Erhalte optionale, sanfte Motivations-Mitteilungen bei 25%, 50%, 75%, 90% und beim Erreichen deines vollen Tagesziels.

  🔒 100 % DATENSCHUTZ – DEINE DATEN GEHÖREN DIR
  Schrittweise respektiert deine Privatsphäre:
  • Keine Benutzerkonten oder Registrierung erforderlich
  • Keine Werbung, keine Tracking-Dienste, keine Third-Party-SDKs
  • Alle Daten werden direkt aus Apple Health (HealthKit) gelesen und verbleiben ausschließlich lokal auf deinen Apple-Geräten.
  ```

---

### E. App-Überprüfungsinformationen (App Review Information)

Die Apple-Prüfer testen die App vor der Freigabe. Gib hier Folgendes an:

- **Anmeldung erforderlich**: `Nein` (Checkbox deaktiviert lassen)
- **Hinweise für die Überprüfung (Review Notes)**:
  ```text
  Die App liest Schritte, Geh-/Laufdistanz und aktive Energie ausschließlich über HealthKit aus. 
  Beim ersten Start fordert die App die entsprechenden Leserechte an.
  Es werden zu keinem Zeitpunkt Daten an externe Server übertragen. 
  Die Apple Watch Komplikationen synchronisieren sich über den gemeinsamen App-Group-Speicher und direkte HealthKit-Hintergrundabfragen.
  ```
- **Kontaktinformationen**:
  - Vorname & Nachname: Siegmund Murer
  - Telefonnummer: deine Handynummer (inkl. Ländervorwahl, z. B. +49 ...)
  - E-Mail-Adresse: deine E-Mail-Adresse

---

## 📦 3. App in Xcode archivieren & hochladen

1. Wähle in Xcode ganz oben in der Leiste als Scheme **`Schritte-Apple Watch`** aus.
2. Wähle als Zielgerät (Run Destination) **`Any iOS Device (arm64)`** aus (nicht einen Simulator!).
3. Klicke in der Menüleiste auf **Product &rarr; Archive**.
4. Sobald der Build abgeschlossen ist, öffnet sich automatisch das **Organizer**-Fenster.
5. Klicke rechts auf **Distribute App**.
6. Wähle **App Store Connect** &rarr; **Upload** und folge den Schritten (automatische Signierung mit deinem Team `TA5AHN6TPZ`).
7. Nach wenigen Minuten ist der Build in App Store Connect unter deiner App verfügbar.
8. Wähle den Build in App Store Connect aus, lade die Screenshots hoch und klicke auf **Zur Überprüfung einreichen**!
