# ============================
# ⚠️ Muss als Administrator ausgeführt werden!
# Ersetzt Sperrbildschirmbilder mit img100.jpg und deaktiviert Spotlight
# ============================

# ▶️ Adminprüfung & ggf. Neustart mit Adminrechten
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator
if (-not ([Security.Principal.WindowsPrincipal] $currentUser).IsInRole($adminRole)) {
    Write-Host "🔐 Starte Skript neu mit Administratorrechten..." -ForegroundColor Yellow
    Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 🔧 Pfad zum eigenen Sperrbild
$newImg = "C:\Windows\Web\Screen\img100.jpg"

# 🔧 SystemData-Basis
$sysDataRoot = "C:\ProgramData\Microsoft\Windows\SystemData"

# 🔍 Interaktiv angemeldete Benutzer-SID ermitteln (über explorer.exe-Prozess)
$explorer = Get-Process explorer -ErrorAction SilentlyContinue | Select-Object -First 1
if ($explorer) {
    $proc = Get-WmiObject Win32_Process -Filter "ProcessId = $($explorer.Id)"
    $sid = $proc.GetOwnerSid().Sid
    Write-Host "`n🔎 Benutzer-SID (interaktiv): $sid" -ForegroundColor Cyan
} else {
    Write-Warning "❌ Kein interaktiver Benutzer (explorer.exe) gefunden – SID kann nicht bestimmt werden."
    exit 1
}

# 🔧 Benutzer-spezifischer ReadOnly-Pfad
$readOnlyUserSID = Join-Path $sysDataRoot "$sid\ReadOnly"

# 🛠 Funktion: Besitz übernehmen und ACL setzen
function Force-AdminAccess {
    param([string]$targetPath)

    if (-Not (Test-Path $targetPath)) {
        Write-Warning "⚠️ Pfad existiert nicht: $targetPath"
        return
    }

    try {
        Write-Host "`n🔐 Übernehme Besitz für: $targetPath" -ForegroundColor Cyan
        takeown /F "$targetPath" /A /R /D N | Out-Null

        $acl = Get-Acl -Path $targetPath
        $adminGroup = New-Object System.Security.Principal.NTAccount("Administratoren")

        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $adminGroup,
            "FullControl",
            "ContainerInherit,ObjectInherit",
            "None",
            "Allow"
        )

        $acl.SetAccessRule($rule)
        Set-Acl -Path $targetPath -AclObject $acl

        Write-Host "✔️ Zugriff gesetzt: $targetPath" -ForegroundColor Green
    } catch {
        Write-Warning "❌ Fehler bei Rechtevergabe für ${targetPath}: $_"
    }
}

# 🛠 Funktion: Vererbung aktivieren
function Enable-Inheritance {
    param([string]$path)
    if (Test-Path $path) {
        Write-Host "🔄 Aktiviere Vererbung: $path" -ForegroundColor Cyan
        icacls "$path" /inheritance:e | Out-Null
    } else {
        Write-Warning "⚠️ Pfad existiert nicht: $path"
    }
}

# 👉 Schritt 1: Besitz & Rechte setzen
Force-AdminAccess -targetPath $sysDataRoot
Enable-Inheritance -path $sysDataRoot

Force-AdminAccess -targetPath $readOnlyUserSID
Enable-Inheritance -path $readOnlyUserSID

# 👉 Schritt 2: Login-/Lockscreen-Bilder ersetzen
Write-Host "`n🖼️ Ersetze Lockscreen-Bilder..." -ForegroundColor Cyan
$imgFiles = Get-ChildItem -Path $readOnlyUserSID -Recurse -Include *lockscreen*.jpg,*lock*.jpg,*img*.jpg -ErrorAction SilentlyContinue

if ($imgFiles.Count -eq 0) {
    Write-Warning "Keine ersetzbaren Bilddateien gefunden unter $readOnlyUserSID"
} else {
    foreach ($file in $imgFiles) {
        try {
            Copy-Item -Path $newImg -Destination $file.FullName -Force
            Write-Host "✔️ Ersetzt: $($file.FullName)" -ForegroundColor Green
        } catch {
            Write-Warning "❌ Fehler bei: $($file.FullName) - $_"
        }
    }
}

# 👉 Schritt 3: Theme-Cache löschen
Write-Host "`n🧹 Lösche Theme-Caches..." -ForegroundColor Cyan
Remove-Item "$env:APPDATA\Microsoft\Windows\Themes\CachedFiles\*" -Force -ErrorAction SilentlyContinue

# 👉 Schritt 4: Spotlight per Gruppenrichtlinie deaktivieren
Write-Host "`n🚫 Deaktiviere Spotlight (per Richtlinie)..." -ForegroundColor Cyan

$policyKey = "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent"

function Test-RegistryValue {
    param (
        [string]$Path,
        [string]$Name
    )
    try {
        $null = Get-ItemProperty -Path "Registry::$Path" -Name $Name -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

try {
    # Setze nur, wenn der Wert noch nicht existiert oder nicht korrekt ist
    if (-not (Test-RegistryValue -Path $policyKey -Name "DisableWindowsSpotlightFeatures")) {
        reg add $policyKey /v DisableWindowsSpotlightFeatures /t REG_DWORD /d 1 /f | Out-Null
        Write-Host "✔️ DisableWindowsSpotlightFeatures gesetzt." -ForegroundColor Green
    } else {
        Write-Host "ℹ️ DisableWindowsSpotlightFeatures bereits vorhanden." -ForegroundColor Yellow
    }

    if (-not (Test-RegistryValue -Path $policyKey -Name "DisableSpotlightOnLockScreen")) {
        reg add $policyKey /v DisableSpotlightOnLockScreen /t REG_DWORD /d 1 /f | Out-Null
        Write-Host "✔️ DisableSpotlightOnLockScreen gesetzt." -ForegroundColor Green
    } else {
        Write-Host "ℹ️ DisableSpotlightOnLockScreen bereits vorhanden." -ForegroundColor Yellow
    }
} catch {
    Write-Warning "❌ Fehler beim Schreiben in die Registry. Skript muss mit vollständigen Adminrechten ausgeführt werden."
}


# ✅ Abschluss
Write-Host "`n✅ Sperrbildschirm ersetzt & Änderungen durchgesetzt." -ForegroundColor Cyan
Write-Host "🔁 Bitte Windows neu starten, um alle Änderungen zu übernehmen." -ForegroundColor Yellow
