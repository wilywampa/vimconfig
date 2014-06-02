; Maximize gVim
SetTitleMatchMode, 2
lOop, 50
{
	WinActivate, GVIM
	IfWinActive, GVIM
	{
		Break
	}
	Sleep, 100
}
lOop, 50
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
