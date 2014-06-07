; Maximize gVim
SetTitleMatchMode, 2
lOop, 100
{
	WinActivate, GVIM
	IfWinActive, GVIM
	{
		Break
	}
	Sleep, 100
}
lOop, 100
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
