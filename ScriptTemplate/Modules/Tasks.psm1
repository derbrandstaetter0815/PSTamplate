# ExampleTasks.psm1
# Beispielmodul mit einer einfachen Tätigkeit:
# Es wird geprüft, ob ein Ordner existiert.

function Invoke-ExampleFolderCheck {
<#
.SYNOPSIS
Prüft, ob ein bestimmter Ordner existiert.

.PARAMETER Path
Pfad, der geprüft werden soll.

.BEISPIEL
PS> Invoke-ExampleFolderCheck -Path 'C:\Windows'
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    Write-Log "Invoke-ExampleFolderCheck gestartet für Pfad: $Path" 'INFO'

    if (-not (Test-Path $Path)) {
        Write-Log "Pfad existiert NICHT: $Path" 'ERROR'
        Add-Body "Fehler: Der Pfad '$Path' existiert nicht."
        Set-Subject 'NOK'
        throw "Der Pfad '$Path' existiert nicht."
    }

    Write-Log "Pfad existiert: $Path" 'SUCCESS'
    Add-Body "Der Pfad '$Path' wurde erfolgreich geprüft und existiert."
}

Export-ModuleMember -Function Invoke-ExampleFolderCheck
