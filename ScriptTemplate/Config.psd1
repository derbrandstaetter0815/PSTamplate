@{
    Environment = 'LAB'

    Logging = @{
        LogDirectory       = 'C:\Scripting\ScriptTemplate\Logs'      # wird automatisch angelegt
        LogFilePrefix      = 'TemplateDemo'
        BodyDumpDirectory  = 'C:\Scripting\ScriptTemplate\MailDumps' # optional
    }

    Mail = @{
        Enabled       = $false            # im LAB z.B. false, in PROD true
        From          = 'script@example.com'
        To            = 'admin@example.com, admin2@example.com'
        SmtpServer    = 'smtp.example.com'
        SubjectPrefix = 'TemplateDemo'
    }

    Example = @{
        FolderToCheck = 'C:\Windows'      # Beispiel für deine Task
    }
}
