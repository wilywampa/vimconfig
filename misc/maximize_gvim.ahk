; Maximize gVim
SetTitleMatchMode, 2
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
		Exit
	}
	Else
	{
		WinMaximize
	}
	Sleep, 100
}
