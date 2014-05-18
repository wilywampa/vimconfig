echo %* 1>C:\temp\tempfname
start /b run zsh -l -c "$HOME/vimopen"
tasklist /nh /fi "imagename eq AutoHotkey.exe" | find /i "AutoHotkey.exe" > nul || (start "" "C:\Users\%USERNAME%\xterm.ahk")
start "" "C:\Users\%USERNAME%\maximize_gvim.ahk"
