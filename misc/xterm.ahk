; Reload automatically if already running
#SingleInstance force

; Make <C-_> work without shift key
$^-::
WinGet, Active_ID, ID, A
WinGet, Active_Process, ProcessName, ahk_id %Active_ID%
if ( Active_Process ="XWin.exe" )
{
    Send ^7
}
else
{
    Send ^-
}
return

; Make <C-^> (<C-6>) work with shift key
^+`::
Send ^6
Return

; Make <C-^> (<C-6>) work without shift key
^`::
Send ^6
Return

; Activate/minimize gVim
$#4::
SetTitleMatchMode, 2
Process, Exist, gvim.exe
if !ErrorLevel = 0
{
    IfWinActive, GVIM
    {
        WinGet MMX, MinMax, GVIM
        If MMX = 1
        {
            WinMinimize
        }
        Else
        {
            WinMaximize
        }
        Return
    }
    else
    {
        WinActivate, GVIM
        WinMaximize
    }
}
else
{
    Send #4
    Loop
    {
        WinActivate, GVIM
        IfWinActive, GVIM
        {
            Break
        }
    }
    Loop
    {
        WinGet MMX, MinMax, GVIM
        If MMX = 1
        {
            Break
        }
        Else
        {
            WinMaximize
        }
    }
}
Return

; Activate/minimize XTerm
$#2::
SetTitleMatchMode, 3
Process, Exist, xterm.exe
if !ErrorLevel = 0
{
    IfWinActive, xterm
    {
        WinGet MMX, MinMax, xterm
        If MMX = 1
        {
            WinMinimize
        }
        Else
        {
            WinMaximize
        }
        Return
    }
    else
    {
        WinActivate, xterm
        WinMaximize
    }
}
else
{
    Send #2
    Loop
    {
        WinActivate, xterm
        IfWinActive, xterm
        {
            Break
        }
    }
    Loop
    {
        WinGet MMX, MinMax, xterm
        If MMX = 1
        {
            Break
        }
        Else
        {
            WinMaximize
        }
    }
    Send tmx{Enter}
}
Return

; Shut down if Battlefield is open
Loop
{
    Process,Exist, bf4.exe
    If !ErrorLevel
       Exit
    Sleep, 2000
}

