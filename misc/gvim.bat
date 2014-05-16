echo %* 1>C:\temp\tempfname
start /b run zsh -l -c '/home/Jake/vimopen'
tasklist /nh /fi "imagename eq AutoHotkey.exe" | find /i "AutoHotkey.exe" > nul || (start "" "C:\Users\Jake\xterm.ahk")
