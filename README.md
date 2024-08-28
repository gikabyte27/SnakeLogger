# SnakeLogger
A (not so simple) simple keylogger malware
> George Tudor | 27/07/2024

---
```
 $$$$$$\  $$\   $$\  $$$$$$\  $$\   $$\ $$$$$$$$\ $$\       $$$$$$\   $$$$$$\   $$$$$$\  $$$$$$$$\ $$$$$$$\  
$$  __$$\ $$$\  $$ |$$  __$$\ $$ | $$  |$$  _____|$$ |     $$  __$$\ $$  __$$\ $$  __$$\ $$  _____|$$  __$$\ 
$$ /  \__|$$$$\ $$ |$$ /  $$ |$$ |$$  / $$ |      $$ |     $$ /  $$ |$$ /  \__|$$ /  \__|$$ |      $$ |  $$ |
\$$$$$$\  $$ $$\$$ |$$$$$$$$ |$$$$$  /  $$$$$\    $$ |     $$ |  $$ |$$ |$$$$\ $$ |$$$$\ $$$$$\    $$$$$$$  |
 \____$$\ $$ \$$$$ |$$  __$$ |$$  $$<   $$  __|   $$ |     $$ |  $$ |$$ |\_$$ |$$ |\_$$ |$$  __|   $$  __$$< 
$$\   $$ |$$ |\$$$ |$$ |  $$ |$$ |\$$\  $$ |      $$ |     $$ |  $$ |$$ |  $$ |$$ |  $$ |$$ |      $$ |  $$ |
\$$$$$$  |$$ | \$$ |$$ |  $$ |$$ | \$$\ $$$$$$$$\ $$$$$$$$\ $$$$$$  |\$$$$$$  |\$$$$$$  |$$$$$$$$\ $$ |  $$ |
 \______/ \__|  \__|\__|  \__|\__|  \__|\________|\________|\______/  \______/  \______/ \________|\__|  \__|
```                                                                                                                                                                                                                       
---
## Overview

The project features as they were planned have been completed - with a successful **keylogger** creation. This keylogger asynchronously sends keystrokes at certain times via SMTP protocol as an attached text file, accompanied by a preview of the file within the mail body. This will act as as a module towards building a **RAT** (Soon) 

## Components

- Script generator
- PowerShell core keylogger payload
- Log File sending via e-mail
- Log File as attachment within the e-mail

## Further work

After the initial keylogger will be finished, additional modules will be available, such as:
- Live keystroke capture
- Periodic clipboard inspection
