Ziel des Skripts
Das Skript ersetzt die Sperrbildschirmbilder (Lockscreen-Bilder) des aktuell angemeldeten Benutzers durch ein eigenes Bild (img100.jpg) und deaktiviert die Windows-Spotlight-Funktion (die wechselnde Bilder und Vorschläge auf dem Sperrbildschirm anzeigt).
Zusätzlich wird der Zugriff auf geschützte Systemverzeichnisse automatisch ermöglicht für Administratoren.
Dieses Script ist auf ein deutsches System ausgerichtet und kann für die Verteilung via Matrix42 Intune etc verwendet wedrden.

⚠️ Voraussetzungen
Muss als Administrator ausgeführt werden.

Das Bild C:\Windows\Web\Screen\img100.jpg muss existieren.

Funktioniert nur, wenn ein interaktiv angemeldeter Benutzer aktiv ist (also ein Benutzer mit offenem Desktop, z. B. per RDP oder lokalem Login).

🔍 Schritt-für-Schritt-Erklärung
1. Initialisierung
Definiert den Pfad zu dem neuen Sperrbild (img100.jpg).

Setzt den Pfad zur SystemData-Struktur, in der Windows die Sperrbildschirmbilder verwaltet:
C:\ProgramData\Microsoft\Windows\SystemData.

2. Bestimmen der SID des interaktiv angemeldeten Benutzers
Holt sich den explorer.exe-Prozess.

Ermittelt mit WMI (Get-WmiObject) den Besitzer dieses Prozesses.

Daraus wird die Benutzer-SID abgeleitet, z. B. S-1-5-21-1234567890-....

Diese SID wird verwendet, um den benutzerspezifischen Ordner unter SystemData zu lokalisieren:
C:\ProgramData\Microsoft\Windows\SystemData\<SID>\ReadOnly.

3. Besitz übernehmen & Zugriffsrechte setzen
Verwendet zwei Funktionen:

🔧 Force-AdminAccess
Übernimmt den Besitz des angegebenen Verzeichnisses (takeown).

Gewährt der Administratorengruppe FullControl-Berechtigungen (Set-Acl).

🔧 Enable-Inheritance
Aktiviert die Vererbung von Berechtigungen im Dateisystem (icacls /inheritance:e).

Diese beiden Funktionen werden angewendet auf:

C:\ProgramData\Microsoft\Windows\SystemData

C:\ProgramData\Microsoft\Windows\SystemData\<BenutzerSID>\ReadOnly

4. Sperrbildschirmbilder ersetzen
Durchsucht rekursiv den ReadOnly-Ordner nach .jpg-Dateien, die typisch für Lockscreens sind (*lockscreen*.jpg, *img*.jpg, etc.).

Ersetzt jede gefundene Datei durch die Datei img100.jpg, mit -Force (überschreiben ohne Nachfrage).

5. Theme-Cache löschen
Entfernt gecachte Bilder im Benutzerprofil unter:
%APPDATA%\Microsoft\Windows\Themes\CachedFiles

Dadurch wird verhindert, dass alte Lockscreen-Bilder weiterhin angezeigt werden.

6. Windows Spotlight deaktivieren
Erstellt (falls nicht vorhanden) den Registrierungspfad:
HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent

Setzt zwei DWORD-Werte:

DisableWindowsSpotlightFeatures = 1 → Spotlight komplett deaktivieren

DisableSpotlightOnLockScreen = 1 → Sperrbildschirm-Spotlight deaktivieren

7. Abschlussmeldung
Gibt eine Bestätigung aus, dass alle Änderungen abgeschlossen sind.

Weist darauf hin, dass ein Neustart notwendig ist, damit alle Änderungen aktiv werden (besonders Bildwechsel & Policy-Anpassungen).

✅ Zusammenfassung der Wirkung
Bereich	Wirkung
Bilder	Ersetzt Sperrbildschirmbilder mit eigenem Bild (img100.jpg)
Zugriffsrechte	Erzwingt Admin-Zugriff auf geschützte Systemordner
Windows Spotlight	Wird über Gruppenrichtlinie deaktiviert
Benutzerbezug	Betrifft nur den aktuell angemeldeten interaktiven Benutzer
Cachereinigung	Löscht gecachte Theme-Bilder, damit alte Inhalte nicht angezeigt werden
Systemwirkung	Änderungen sind systemweit (Spotlight), aber bilderspezifisch benutzerbezogen
Neustart notwendig	Ja, zur vollständigen Aktivierung der Änderungen
