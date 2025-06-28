🛡️ Allgemeine Funktion
Dieses PowerShell-Skript ersetzt die Sperrbildschirm-Hintergrundbilder eines Windows-Systems mit einem eigenen Bild (img100.jpg) und deaktiviert die Spotlight-Funktion, die automatisch wechselnde Hintergrundbilder anzeigt.

Es erfordert Administratorrechte, da es auf geschützte Verzeichnisse und die Windows-Registry zugreift.

🔍 Ablauf im Detail
1. Adminprüfung und ggf. Neustart mit erhöhten Rechten
powershell
Kopieren
Bearbeiten
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
...
if (-not ([Security.Principal.WindowsPrincipal] $currentUser).IsInRole($adminRole)) {
    ...
}
Das Skript prüft, ob es mit Administratorrechten gestartet wurde.

Falls nicht, startet es sich selbst neu mit erhöhten Rechten (UAC-Eingabeaufforderung erscheint).

2. Eigene Bilddatei & Systemdatenpfad
powershell
Kopieren
Bearbeiten
$newImg = "C:\Windows\Web\Screen\img100.jpg"
$sysDataRoot = "C:\ProgramData\Microsoft\Windows\SystemData"
Gibt an, welches Bild verwendet wird.

Legt den Pfad zum geschützten Systemordner fest, in dem Windows Sperrbildschirmbilder speichert.

3. Aktuell angemeldete Benutzer-SID ermitteln
powershell
Kopieren
Bearbeiten
Get-Process explorer ...
$sid = $proc.GetOwnerSid().Sid
Über den explorer.exe-Prozess wird die Sicherheits-ID (SID) des aktuell angemeldeten Benutzers ermittelt.

Diese wird benötigt, um zum benutzerspezifischen Lockscreen-Verzeichnis zu navigieren.

4. Besitz übernehmen & Zugriffsrechte setzen
powershell
Kopieren
Bearbeiten
Force-AdminAccess -targetPath ...
Enable-Inheritance -path ...
Das Skript übernimmt den Besitz geschützter Ordner (SystemData & Unterordner).

Es setzt Vollzugriffsrechte für Administratoren.

Außerdem wird die Vererbung von Berechtigungen wieder aktiviert.

5. Sperrbildschirmbilder ersetzen
powershell
Kopieren
Bearbeiten
Get-ChildItem ... | Copy-Item ...
Sucht in den ReadOnly-Verzeichnissen nach Lockscreen-Bildern (*.jpg, z. B. img*.jpg, lock*.jpg).

Ersetzt jedes gefundene Bild durch das benutzerdefinierte Bild img100.jpg.

6. Theme-Cache löschen
powershell
Kopieren
Bearbeiten
Remove-Item "$env:APPDATA\Microsoft\Windows\Themes\CachedFiles\*" ...
Löscht den Cache für Theme-Bilder, damit Windows nicht alte Lockscreen-Bilder erneut verwendet.

7. Windows Spotlight per Gruppenrichtlinie deaktivieren
powershell
Kopieren
Bearbeiten
reg add ...
Legt in der Registry unter HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent zwei Werte an:

DisableWindowsSpotlightFeatures = 1

DisableSpotlightOnLockScreen = 1

Diese verhindern, dass Windows automatisch neue Bilder oder Spotlight-Inhalte auf dem Sperrbildschirm lädt.

Vor dem Schreiben wird geprüft, ob die Werte bereits existieren, um Redundanz zu vermeiden.

8. Abschlussmeldung
powershell
Kopieren
Bearbeiten
Write-Host "`n✅ Sperrbildschirm ersetzt & Änderungen durchgesetzt."
Das Skript weist den Benutzer darauf hin, dass ein Neustart erforderlich ist, damit alle Änderungen sichtbar werden.

⚠️ Voraussetzungen
Das Skript muss mit Administratorrechten ausgeführt werden (erkennt das selbst).

Das Bild img100.jpg muss existieren und gut geeignet sein (richtige Auflösung, Format etc.).

Wenn du möchtest, kann ich die Beschreibung auch als Kommentarblock direkt in das Skript integrieren oder eine gekürzte Version für Dokumentationszwecke schreiben.
