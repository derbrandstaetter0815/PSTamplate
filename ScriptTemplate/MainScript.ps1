param(
    # Optional: alternative Konfigurationsdatei übergeben
    [string]$ConfigFile = "$PSScriptRoot\config.psd1"
)

$global:ErrorActionPreference = 'Stop'

# Config-File laden
if (-not (Test-Path $ConfigFile)) {
    Write-Host "Konfigurationsdatei nicht gefunden: $ConfigFile" -ForegroundColor Red
    exit 1
}
$Config = Import-PowerShellDataFile -Path $ConfigFile
#$config.GetType()

# Module importieren
$modulesRoot = Join-Path $PSScriptRoot 'Modules'

Import-Module (Join-Path $modulesRoot 'CoreTools.psm1') -Force
Import-Module (Join-Path $modulesRoot 'Tasks.psm1') -Force

# Core initialisieren (Logging, Mail-Basis)
Initialize-Core -Config $Config

Write-Log "MainScript.ps1 gestartet (Environment: $($Config.Environment))" 'INFO'
Add-Body "Scriptstart: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Add-Body "Environment: $($Config.Environment)"


# --- Hauptablauf ---
try {
    # einfache Beispiel-Aufgabe:
    $folder = $Config.Example.FolderToCheck
    Invoke-ExampleFolderCheck -Path $folder

    # Wenn du mehrere Tätigkeiten hast, hier weitere Funktionsaufrufe:
    # Invoke-AnotherTask ...
}
catch {
    # globaler Fehler-Handler
    if ((Get-Subject) -ne 'NOK') {
        Set-Subject 'NOK'
    }
    write-warning "Fehler im Hauptablauf: $($_.Exception.Message)"
    Write-Log "Fehler im Hauptablauf: $($_.Exception.Message)" 'ERROR'
    Add-Body "Globaler Fehler im Script:"
    Add-Body $($_.Exception.Message)
}
finally {
    # 5) Abschluss & Mailversand
    Add-Body "Scriptende: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    write-host "MainScript.ps1 beendet (Subject=$(Get-Subject))." 
    Write-Log "MainScript.ps1 beendet (Subject=$(Get-Subject))." 'INFO'

    Send-StatusMail
}
