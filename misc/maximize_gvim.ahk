; Maximize gVim
SetTitleMatchMode, 2
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
		Exit
	}
	Else
	{
		WinMaximize
	}
}
