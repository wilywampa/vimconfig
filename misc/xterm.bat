D:\Cygwin\bin\run.exe -p /usr/X11R6/bin xterm -display 127.0.0.1:0.0 -ls
tasklist /nh /fi "imagename eq AutoHotkey.exe" | find /i "AutoHotkey.exe" > nul || (start "" "C:\Users\Jake\xterm.ahk")
