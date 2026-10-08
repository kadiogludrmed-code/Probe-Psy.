# Probe Psy — Stufe 1

Native SwiftUI-App für Erwachsene ab 18 Jahren. Stand: 08.10.2026.
Entwicklungsprototyp, noch nicht klinisch validiert und nicht für die Patientenversorgung freigegeben.

## Enthalten

- Erststart direkt mit 🇩🇪 Deutsch / 🇬🇧 English / 🇹🇷 Türkçe, ohne Konto oder weiteres Onboarding.
- Sprache jederzeit über das Globus-Symbol wechseln. Alle app-eigenen festen Texte in `ProbePsy/Languages.json`.
- Stimmung 1–10 und optionaler Freitext (4.000 Zeichen). Mehrere Einträge pro Tag möglich, kein Überschreiben.
- Zeitstempel und lokale Zeitzone je Eintrag; Anzeige des letzten Eintrags zum Prüfen der Speicherung.
- AES-GCM-verschlüsselte lokale Datei in Application Support. Schlüssel ausschließlich in der lokalen Keychain (`WhenUnlockedThisDeviceOnly`, nicht synchronisierend).
- Vollständiger iOS-Dateischutz und Backup-Ausschluss für Verzeichnis und Datei.
- Kein Login, Netzwerkcode, OpenAI-Aufruf, Server, CloudKit, Tracking oder Drittanbieter-SDK.
- Privacy-Abdeckung im App-Umschalter; native Dynamic-Type-Schriften und VoiceOver-Beschriftungen.
- Native Navigation und Controls; `glassEffect` ab iOS 26, Material-Fallback für iOS 17/18. Reduzierte Transparenz berücksichtigt.
- Notruf 112 und deutsche TelefonSeelsorge 0800 1110111 jederzeit erreichbar. iOS verlangt ggf. seine eigene Anrufbestätigung.
- Begrenzte lokale Krisen-Phrasenprüfung in allen drei Sprachen. Ein Treffer aktiviert einen persistenten Hinweis. Text löschen, speichern, Sprachwechsel oder Anrufversuch setzen ihn nicht zurück. Nur „Ich habe Hilfe gesucht“ bestätigt ihn.

## Auf dem Mac testen

1. Xcode 26 oder neuer mit iOS-26-SDK installieren. Der Simulator muss zusätzlich installiert sein. Deployment Target ist iOS 17.0; älteres Xcode versteht `glassEffect` nicht.
2. Diesen Projekt-Branch herunterladen oder klonen. `ProbePsy.xcodeproj` öffnen — keine Pakete oder Projektgeneratoren erforderlich.
3. Oben das Scheme **ProbePsy** und einen iPhone-Simulator mit iOS 26 auswählen.
4. **⌘R** drücken. Für den Simulator ist kein Development Team erforderlich.
5. Sprache auswählen, Stimmung z. B. 7 einstellen, einen harmlosen Testtext eingeben und speichern.
6. App beenden und erneut starten. Sprache und letzter Eintrag müssen erhalten bleiben.
7. Auf dem eigenen iPhone: Target **ProbePsy → Signing & Capabilities → Team** wählen, bei Bedarf eindeutigen Bundle Identifier setzen. iPhone verbinden, Entwicklermodus aktivieren, Gerät auswählen und **⌘R**.

Terminal-Build auf einem Mac:

```sh
xcodebuild -project ProbePsy.xcodeproj -scheme ProbePsy -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

## Abnahmecheck für Stufe 1

Nur erfundene Testdaten verwenden. **Keine echten Notruf-Testanrufe durchführen.**

- Erstinstallation: genau eine Sprachauswahl, danach Eingabe. Alle drei Sprachen separat prüfen, auch in den Fehlermeldungen.
- Sprachwechsel über Globus: sofort andere Texte, kein Datenverlust; bleibt nach Neustart bestehen.
- Stimmung 1 und 10 speichern; ohne Notiz speichern; mehrere Einträge am selben Tag speichern.
- Neustart nach Speicherung: letzter Eintrag einschließlich Stimmung, Notiz und Zeit erscheint wieder.
- Im Flugmodus speichern und neu starten: gleiche Funktion.
- Signaltexte (Simulation): `ich will nicht mehr aufwachen`, `I don't want to wake up`, `uyanmak istemiyorum`, `ich werde ihn töten`. Hinweis muss schon beim Tippen/Einfügen erscheinen, auch wenn die UI eine andere Sprache nutzt.
- Hinweis aktivieren, Text löschen und App beenden: Hinweis bleibt. Erst nach ausdrücklicher Hilfebestätigung verschwindet er. Basis-Hilfebuttons bleiben immer da.
- Im Simulator auf Anrufbutton tippen: Fehlermeldung/Telefonnummern prüfen. Auf echtem Telefon keinen Notruf zum Testen auslösen.
- Größte Schriftgröße, VoiceOver, dunkler Modus und „Transparenz reduzieren“ ausprobieren. iOS-17/18-Fallback auf einem entsprechenden Simulator prüfen.
- Datenfehler auf einem **Test-Simulator**: App stoppen, `state.sealed` im App-Datencontainer verändern und neu starten. Fehleransicht statt stiller Datenlöschung; vorhandene Datei darf nicht überschrieben werden. Danach den Test-Simulator zurücksetzen.

Strukturprüfung ohne Mac: `python3 scripts/validate_project.py`. Sie prüft JSON-Schlüssel, Ressourcen, Xcode-Dateiverweise, Scheme und die dokumentierten Krisen-Beispiele. Sie kompiliert kein Swift.

## Grenzen und offene Schritte

Diese Stufe enthält **keine Sprachnotizen, Diagramme, Übungen oder KI**. Nach Rückmeldung zur Stufe 1 folgt jeweils genau eine weitere Funktion. Sinnvolle nächste Stufe: lokale Sprachnotiz mit Aufnahme, Wiedergabe und Löschen. Vor dem KI-Schritt muss die Architekturentscheidung geklärt werden: OpenAI-API-Nutzung überträgt Daten nach außen und ist mit strikt lokalem Betrieb unvereinbar. Kein API-Key gehört in ein öffentliches Repository oder fest in eine ausgelieferte App.

Die lokale Wortprüfung ist eine bewusst unvollständige Übergangslösung. Sie kann indirekte Aussagen übersehen, Zitate/Verneinungen falsch markieren und keine Entwarnung geben. Keine Risikowerte, Diagnosen oder automatische Notfallkontakte. Eine zuverlässige permanente KI-Überwachung ist nicht implementiert und darf nicht versprochen werden. Vor Patientennutzung sind fachliche Sicherheitsprüfung, Sprachprüfung und eine klinisch geeignete Validierung erforderlich.

Die App sendet selbst keine Eingaben. System-Diktat, fremde Tastaturen, Screenshots, ein kompromittiertes Gerät und Betriebssystem-Backups liegen nicht vollständig in der Kontrolle der App. Apples Backup-Ausschluss ist eine Systemvorgabe, keine absolute Zusicherung. Der nicht migrierbare Schlüssel schützt zusätzlich vor Entschlüsselung auf anderen Geräten. Datenverlust bei Deinstallation/Geräteverlust ist beabsichtigt; kein Wiederherstellungskonto.

112 und TelefonSeelsorge sind zwei unterschiedliche Angebote. Sprache ist kein Standortnachweis: Die deutsche Hotline bleibt in allen UI-Sprachen ausdrücklich als Angebot in Deutschland gekennzeichnet. Vor internationaler Veröffentlichung sind passende lokale Hilfsangebote zu ergänzen.

## Technische Prüfung in dieser Erstellung

Projektstruktur und Übersetzungsabdeckung sind statisch geprüft. In der Erstellungsumgebung stehen weder Xcode noch ein iOS-Simulator zur Verfügung. Deshalb sind Swift-Kompilierung, Keychain-Verhalten auf dem Gerät, Laufzeitlayout und Bedienbarkeit noch **nicht verifiziert**. Der Mac-Test oben ist der nächste notwendige Schritt.

## Quellen

- [Apple: Liquid Glass in SwiftUI](https://developer.apple.com/videos/play/wwdc2025/323/)
- [Apple: glassEffect](https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:))
- [Apple: Backup-Verhalten](https://developer.apple.com/documentation/foundation/optimizing-your-app-s-data-for-icloud-backup)
- [TelefonSeelsorge Deutschland](https://www.telefonseelsorge.de/telefon/)
