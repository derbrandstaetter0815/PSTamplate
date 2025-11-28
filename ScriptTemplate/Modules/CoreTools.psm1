# CoreTools.psm1
# Gemeinsame Basis: Logging, Body-Verwaltung, Mailversand

# interner Zustand des Moduls
$script:CoreConfig = $null
$script:LogFile    = $null
$script:BodyLines  = @()
$script:Subject    = 'OK'

function Initialize-Core {
<#
.SYNOPSIS
Initialisiert Logging und Basiszustand auf Basis einer Config-Hashtable.

.PARAMETER Config
Hashtable aus einer PSD1-Konfigdatei (z.B. Import-PowerShellDataFile).
#>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config
    )

    $script:CoreConfig = $Config

    # Logfile bauen
    $logDir   = $Config.Logging.LogDirectory
    $prefix   = $Config.Logging.LogFilePrefix
    if (-not (Test-Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }
    $dateTag       = (Get-Date).ToString('yyyyMMdd')
    $script:LogFile = Join-Path $logDir "$prefix`_$dateTag.log"

    Write-Log "Core initialisiert. LogFile: $script:LogFile" 'INFO'
}

function Write-Log {
<#
.SYNOPSIS
Schreibt eine Zeile ins Logfile.

.PARAMETER Message
Die zu loggende Nachricht.

.PARAMETER Level
Log-Level (INFO, DEBUG, WARN, ERROR, SUCCESS).
#>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [ValidateSet('INFO','DEBUG','WARN','ERROR','SUCCESS')]
        [string]$Level = 'INFO'
    )

    if (-not $script:LogFile) {
        # Notfall: Fallback-Logfile im Modulordner
        $fallback = Join-Path $PSScriptRoot 'CoreTools_fallback.log'
        $script:LogFile = $fallback
    }

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $user      = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    $line      = "[$timestamp] [$user] [$Level] $Message"

    Add-Content -Path $script:LogFile -Value $line
}

function Add-Body {
<#
.SYNOPSIS
Fügt eine Zeile zum Mail-Body hinzu.
#>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Text
    )

    $script:BodyLines += $Text
}

function Set-Subject {
<#
.SYNOPSIS
Setzt den Gesamt-Status (z.B. OK / NOK) für den Mail-Betreff.
#>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Text
    )
    $script:Subject = $Text
}

function Get-Subject {
    [string]$script:Subject
}

function Get-BodyText {
    ($script:BodyLines -join [Environment]::NewLine)
}

function Send-StatusMail {
<#
.SYNOPSIS
Versendet eine Statusmail basierend auf Subject und BodyLines.

.BESCHREIBUNG
Verwendet die Mail-Konfiguration aus $script:CoreConfig.Mail.
Wenn Mail.Enabled = $false ist, wird nur geloggt, aber keine Mail versendet.
#>
    $mailCfg = $script:CoreConfig.Mail
    $enabled = $mailCfg.Enabled

    $subjectPrefix = $mailCfg.SubjectPrefix
    $subjectCore   = Get-Subject
    $subject       = "$subjectPrefix - $subjectCore"

    $bodyText = Get-BodyText
    if (-not $bodyText) {
        $bodyText = "(Kein Text im Body hinterlegt.)"
    }

    # Body zusätzlich in eine Datei schreiben (z.B. zur Ablage)
    if ($script:CoreConfig.Logging.BodyDumpDirectory) {
        $dumpDir = $script:CoreConfig.Logging.BodyDumpDirectory
        if (-not (Test-Path $dumpDir)) {
            New-Item -Path $dumpDir -ItemType Directory -Force | Out-Null
        }
        $dumpFile = Join-Path $dumpDir ("MailBody_{0:yyyyMMdd_HHmmss}.txt" -f (Get-Date))
        $bodyText | Out-File -FilePath $dumpFile -Encoding UTF8
        Write-Log "Mail-Body nach $dumpFile geschrieben." 'DEBUG'
    }

    if (-not $enabled) {
        Write-Log "Mailversand ist in der Konfiguration deaktiviert. (Subject: $subject)" 'INFO'
        return
    }

    try {
        Write-Log "Sende Mail an $($mailCfg.To) über $($mailCfg.SmtpServer) (Subject: $subject)" 'INFO'
        Send-MailMessage -From $mailCfg.From -To $mailCfg.To -SmtpServer $mailCfg.SmtpServer -Subject $subject -Body $bodyText
        Write-Log "Mail erfolgreich gesendet." 'SUCCESS'
    }
    catch {
        Write-Log "Fehler beim Mailversand: $($_.Exception.Message)" 'ERROR'
        # kein throw hier – Mailfehler soll das Script nicht komplett zerlegen
    }
}

Export-ModuleMember -Function Initialize-Core, Write-Log, Add-Body, Set-Subject, Get-Subject, Get-BodyText, Send-StatusMail
