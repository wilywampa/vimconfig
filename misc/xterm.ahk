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
    Loop, 100
    {
        WinActivate, GVIM
        IfWinActive, GVIM
        {
            Break
        }
        Sleep, 100
    }
    Loop, 100
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
        Sleep, 100
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
    Loop, 100
    {
        WinActivate, xterm
        IfWinActive, xterm
        {
            Break
        }
        Sleep, 100
    }
    Loop, 100
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
        Sleep, 100
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

; Adjust mouse sensitivity
#F1::DllCall("SystemParametersInfo", Int,113, Int,0, UInt,4, Int,2)
#F2::DllCall("SystemParametersInfo", Int,113, Int,0, UInt,6, Int,2)
#F3::DllCall("SystemParametersInfo", Int,113, Int,0, UInt,8, Int,2)
