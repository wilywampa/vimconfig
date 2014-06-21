; Reload automatically if already running
#SingleInstance force

$^1::
WinGet, Active_ID, ID, A
WinGet, Active_Process, ProcessName, ahk_id %Active_ID%
if ( Active_Process ="XWin.exe" )
    SendInput 1
else
    SendInput ^1
return
$^2::
WinGet, Active_ID, ID, A
WinGet, Active_Process, ProcessName, ahk_id %Active_ID%
if ( Active_Process ="XWin.exe" )
    SendInput 2
else
    SendInput ^2
return
$^3::
WinGet, Active_ID, ID, A
WinGet, Active_Process, ProcessName, ahk_id %Active_ID%
if ( Active_Process ="XWin.exe" )
    SendInput 3
else
    SendInput ^3
return
$^4::
WinGet, Active_ID, ID, A
WinGet, Active_Process, ProcessName, ahk_id %Active_ID%
if ( Active_Process ="XWin.exe" )
    SendInput 4
else
    SendInput ^4
return
$^5::
WinGet, Active_ID, ID, A
WinGet, Active_Process, ProcessName, ahk_id %Active_ID%
if ( Active_Process ="XWin.exe" )
    SendInput 5
else
    SendInput ^5
return
$^6::
WinGet, Active_ID, ID, A
WinGet, Active_Process, ProcessName, ahk_id %Active_ID%
if ( Active_Process ="XWin.exe" )
    SendInput 6
else
    SendInput ^6
return
$^7::
WinGet, Active_ID, ID, A
WinGet, Active_Process, ProcessName, ahk_id %Active_ID%
if ( Active_Process ="XWin.exe" )
    SendInput 7
else
    SendInput ^7
return
$^8::
WinGet, Active_ID, ID, A
WinGet, Active_Process, ProcessName, ahk_id %Active_ID%
if ( Active_Process ="XWin.exe" )
    SendInput 8
else
    SendInput ^8
return
$^9::
WinGet, Active_ID, ID, A
WinGet, Active_Process, ProcessName, ahk_id %Active_ID%
if ( Active_Process ="XWin.exe" )
    SendInput 9
else
    SendInput ^9
return
$^0::
WinGet, Active_ID, ID, A
WinGet, Active_Process, ProcessName, ahk_id %Active_ID%
if ( Active_Process ="XWin.exe" )
    SendInput 0
else
    SendInput ^0
return

; Send XTerm escape code for <C-Tab>
$^Tab::
WinGet, Active_ID, ID, A
WinGet, Active_Process, ProcessName, ahk_id %Active_ID%
if ( Active_Process ="XWin.exe" )
    SendInput {Esc}[27;5;9~
else
    SendInput ^{Tab}
return

; Send XTerm escape code for <C-S-Tab>
$^+Tab::
WinGet, Active_ID, ID, A
WinGet, Active_Process, ProcessName, ahk_id %Active_ID%
if ( Active_Process ="XWin.exe" )
    SendInput {Esc}[27;6;9~
else
    SendInput ^+{Tab}
return

; Make <C-_> work without shift key
$^-::
WinGet, Active_ID, ID, A
WinGet, Active_Process, ProcessName, ahk_id %Active_ID%
if ( Active_Process ="XWin.exe" )
    SendInput ^/
else
    SendInput ^-
return

; Make <C-^> work without shift key
^`::
SendInput ^+~
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
    SendInput #4
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
    SendInput #2
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
    SendInput tmx{Enter}
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
