" AnsiEsc.vim: Uses syntax highlighting.  A vim 7.0 plugin!
" Language:             Text with ansi escape sequences
" Maintainer:           Charles E. Campbell <NdrOchipS@PcampbellAfamily.Mbiz>
" Version:              13e         ASTRO-ONLY
" Date:                 Dec 06, 2012
"
" Usage: :AnsiEsc
" Note:   This plugin requires +conceal
"
" GetLatestVimScripts: 302 1 :AutoInstall: AnsiEsc.vim
"redraw!|call DechoSep()|call inputsave()|call input("Press <cr> to continue")|call inputrestore()
" ---------------------------------------------------------------------
"DechoTabOn
"  Load Once: {{{1
if exists("g:loaded_AnsiEsc")
 finish
endif
let g:loaded_AnsiEsc = "v13e"
if v:version < 700
 echohl WarningMsg
 echo "***warning*** this version of AnsiEsc needs vim 7.0"
 echohl Normal
 finish
endif
let s:keepcpo= &cpo
set cpo&vim

" ---------------------------------------------------------------------
" AnsiEsc#AnsiEsc: toggles ansi-escape code visualization {{{2
fun! AnsiEsc#AnsiEsc(rebuild)
"  call Dfunc("AnsiEsc#AnsiEsc(rebuild=".a:rebuild.")")
  if a:rebuild
"   call Decho("rebuilding AnsiEsc tables")
   call AnsiEsc#AnsiEsc(0)
   call AnsiEsc#AnsiEsc(0)
"   call Dret("AnsiEsc#AnsiEsc")
   return
  endif
  let bn= bufnr("%")
  if !exists("s:AnsiEsc_enabled_{bn}")
   let s:AnsiEsc_enabled_{bn}= 0
  endif
  if s:AnsiEsc_enabled_{bn}
   " disable AnsiEsc highlighting
"   call Decho("disable AnsiEsc highlighting: s:AnsiEsc_ft_".bn."<".s:AnsiEsc_ft_{bn}."> bn#".bn)
   if exists("g:colors_name")|let colorname= g:colors_name|endif
   if exists("s:conckeep_{bufnr('%')}")|let &l:conc= s:conckeep_{bufnr('%')}|unlet s:conckeep_{bufnr('%')}|endif
   if exists("s:colekeep_{bufnr('%')}")|let &l:cole= s:colekeep_{bufnr('%')}|unlet s:colekeep_{bufnr('%')}|endif
   if exists("s:cocukeep_{bufnr('%')}")|let &l:cocu= s:cocukeep_{bufnr('%')}|unlet s:cocukeep_{bufnr('%')}|endif
   hi! link ansiStop NONE
   syn clear
   hi  clear
   syn reset
   exe "set ft=".s:AnsiEsc_ft_{bn}
   if exists("colorname")|exe "colors ".colorname|endif
   let s:AnsiEsc_enabled_{bn}= 0
   if has("gui_running") && has("menu") && &go =~# 'm'
    " menu support
    exe 'silent! unmenu '.g:DrChipTopLvlMenu.'AnsiEsc'
    exe 'menu '.g:DrChipTopLvlMenu.'AnsiEsc.Start<tab>:AnsiEsc                      :AnsiEsc<cr>'
   endif
   if !has('nvim')
     let &l:hl= s:hlkeep_{bufnr("%")}
   endif
"   call Dret("AnsiEsc#AnsiEsc")
   return
  else
   let s:AnsiEsc_ft_{bn}      = &ft
   let s:AnsiEsc_enabled_{bn} = 1
"   call Decho("enable AnsiEsc highlighting: s:AnsiEsc_ft_".bn."<".s:AnsiEsc_ft_{bn}."> bn#".bn)
   if has("gui_running") && has("menu") && &go =~# 'm'
    " menu support
    exe 'silent! unmenu '.g:DrChipTopLvlMenu.'AnsiEsc'
    exe 'menu '.g:DrChipTopLvlMenu.'AnsiEsc.Stop<tab>:AnsiEsc                       :AnsiEsc<cr>'
   endif

   " -----------------
   "  Conceal Support: {{{2
   " -----------------
   if has("conceal")
    if v:version < 703
     if &l:conc != 3
      let s:conckeep_{bufnr('%')}= &cole
      setlocal conc=3
"      call Decho("l:conc=".&l:conc)
     endif
    else
     if &l:cole != 3 || &l:cocu != "n"
      let s:colekeep_{bufnr('%')}= &l:cole
      let s:cocukeep_{bufnr('%')}= &l:cocu
      setlocal cole=3 cocu=n
"      call Decho("l:cole=".&l:cole." l:cocu=".&l:cocu)
     endif
    endif
   endif
  endif

  syn clear

  " suppress escaped sequences that don't involve colors (which may or may not be ansi-compliant)
  if has("conceal")
   syn match ansiSuppress           conceal     '\e\[[0-9;]*[^m]'
   syn match ansiSuppress           conceal     '\e\[?\d*[^m]'
   syn match ansiSuppress           conceal     '\e\[\(\d\+;\)\?39\(;\d\+\)\?m'
   syn match ansiSuppress           conceal     '\b'
  else
   syn match ansiSuppress                       '\e\[[0-9;]*[^m]'
   syn match ansiSuppress                       '\e\[?\d*[^m]'
   syn match ansiSuppress                       '\b'
  endif

  " ------------------------------
  " Ansi Escape Sequence Handling: {{{2
  " ------------------------------
  syn region ansiNone               start="\e\[\([01;]\|49\)m"  end="\e\["me=e-2 contains=ansiConceal
  syn region ansiNone               start="\e\[m"               end="\e\["me=e-2 contains=ansiConceal

  syn region ansiBold               start="\e\[0;1m"            end="\e\["me=e-2 contains=ansiConceal
  syn region ansiUnderline          start="\e\[0;4m"            end="\e\["me=e-2 contains=ansiConceal

  syn region ansiBlack              start="\e\[;\=0\{0,2};\=30m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiRed                start="\e\[;\=0\{0,2};\=31m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiGreen              start="\e\[;\=0\{0,2};\=32m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiYellow             start="\e\[;\=0\{0,2};\=33m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBlue               start="\e\[;\=0\{0,2};\=34m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiMagenta            start="\e\[;\=0\{0,2};\=35m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiCyan               start="\e\[;\=0\{0,2};\=36m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiWhite              start="\e\[;\=0\{0,2};\=37m" end="\e\["me=e-2 contains=ansiConceal

  syn region ansiBoldBlack          start="\e\[;\=0\{0,2};\=\%(1;30\|30;1\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBoldRed            start="\e\[;\=0\{0,2};\=\%(1;31\|31;1\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBoldGreen          start="\e\[;\=0\{0,2};\=\%(1;32\|32;1\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBoldYellow         start="\e\[;\=0\{0,2};\=\%(1;33\|33;1\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBoldBlue           start="\e\[;\=0\{0,2};\=\%(1;34\|34;1\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBoldMagenta        start="\e\[;\=0\{0,2};\=\%(1;35\|35;1\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBoldCyan           start="\e\[;\=0\{0,2};\=\%(1;36\|36;1\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBoldWhite          start="\e\[;\=0\{0,2};\=\%(1;37\|37;1\)m" end="\e\["me=e-2 contains=ansiConceal

  syn region ansiStandoutBlack      start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(3;30\|30;3\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiStandoutRed        start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(3;31\|31;3\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiStandoutGreen      start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(3;32\|32;3\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiStandoutYellow     start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(3;33\|33;3\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiStandoutBlue       start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(3;34\|34;3\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiStandoutMagenta    start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(3;35\|35;3\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiStandoutCyan       start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(3;36\|36;3\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiStandoutWhite      start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(3;37\|37;3\)m" end="\e\["me=e-2 contains=ansiConceal

  syn region ansiItalicBlack        start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(2;30\|30;2\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiItalicRed          start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(2;31\|31;2\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiItalicGreen        start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(2;32\|32;2\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiItalicYellow       start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(2;33\|33;2\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiItalicBlue         start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(2;34\|34;2\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiItalicMagenta      start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(2;35\|35;2\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiItalicCyan         start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(2;36\|36;2\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiItalicWhite        start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(2;37\|37;2\)m" end="\e\["me=e-2 contains=ansiConceal

  syn region ansiUnderlineBlack     start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(4;30\|30;4\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiUnderlineRed       start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(4;31\|31;4\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiUnderlineGreen     start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(4;32\|32;4\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiUnderlineYellow    start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(4;33\|33;4\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiUnderlineBlue      start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(4;34\|34;4\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiUnderlineMagenta   start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(4;35\|35;4\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiUnderlineCyan      start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(4;36\|36;4\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiUnderlineWhite     start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(4;37\|37;4\)m" end="\e\["me=e-2 contains=ansiConceal

  syn region ansiBlinkBlack         start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(5;30\|30;5\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBlinkRed           start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(5;31\|31;5\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBlinkGreen         start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(5;32\|32;5\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBlinkYellow        start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(5;33\|33;5\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBlinkBlue          start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(5;34\|34;5\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBlinkMagenta       start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(5;35\|35;5\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBlinkCyan          start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(5;36\|36;5\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBlinkWhite         start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(5;37\|37;5\)m" end="\e\["me=e-2 contains=ansiConceal

  syn region ansiRapidBlinkBlack    start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(6;30\|30;6\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiRapidBlinkRed      start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(6;31\|31;6\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiRapidBlinkGreen    start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(6;32\|32;6\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiRapidBlinkYellow   start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(6;33\|33;6\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiRapidBlinkBlue     start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(6;34\|34;6\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiRapidBlinkMagenta  start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(6;35\|35;6\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiRapidBlinkCyan     start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(6;36\|36;6\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiRapidBlinkWhite    start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(6;37\|37;6\)m" end="\e\["me=e-2 contains=ansiConceal

  syn region ansiRV                 start="\e\[;\=0\{0,2};\=\%(1;\)\=7m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiRVBlack            start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(7;30\|30;7\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiRVRed              start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(7;31\|31;7\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiRVGreen            start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(7;32\|32;7\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiRVYellow           start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(7;33\|33;7\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiRVBlue             start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(7;34\|34;7\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiRVMagenta          start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(7;35\|35;7\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiRVCyan             start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(7;36\|36;7\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiRVWhite            start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(7;37\|37;7\)m" end="\e\["me=e-2 contains=ansiConceal

  syn region ansiBrightBlack              start="\e\[;\=0\{0,2};\=90m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightRed                start="\e\[;\=0\{0,2};\=91m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightGreen              start="\e\[;\=0\{0,2};\=92m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightYellow             start="\e\[;\=0\{0,2};\=93m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightBlue               start="\e\[;\=0\{0,2};\=94m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightMagenta            start="\e\[;\=0\{0,2};\=95m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightCyan               start="\e\[;\=0\{0,2};\=96m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightWhite              start="\e\[;\=0\{0,2};\=97m" end="\e\["me=e-2 contains=ansiConceal

  syn region ansiBrightBoldBlack          start="\e\[;\=0\{0,2};\=\%(1;90\|90;1\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightBoldRed            start="\e\[;\=0\{0,2};\=\%(1;91\|91;1\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightBoldGreen          start="\e\[;\=0\{0,2};\=\%(1;92\|92;1\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightBoldYellow         start="\e\[;\=0\{0,2};\=\%(1;93\|93;1\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightBoldBlue           start="\e\[;\=0\{0,2};\=\%(1;94\|94;1\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightBoldMagenta        start="\e\[;\=0\{0,2};\=\%(1;95\|95;1\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightBoldCyan           start="\e\[;\=0\{0,2};\=\%(1;96\|96;1\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightBoldWhite          start="\e\[;\=0\{0,2};\=\%(1;97\|97;1\)m" end="\e\["me=e-2 contains=ansiConceal

  syn region ansiBrightStandoutBlack      start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(3;90\|90;3\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightStandoutRed        start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(3;91\|91;3\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightStandoutGreen      start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(3;92\|92;3\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightStandoutYellow     start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(3;93\|93;3\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightStandoutBlue       start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(3;94\|94;3\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightStandoutMagenta    start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(3;95\|95;3\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightStandoutCyan       start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(3;96\|96;3\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightStandoutWhite      start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(3;97\|97;3\)m" end="\e\["me=e-2 contains=ansiConceal

  syn region ansiBrightItalicBlack        start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(2;90\|90;2\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightItalicRed          start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(2;91\|91;2\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightItalicGreen        start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(2;92\|92;2\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightItalicYellow       start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(2;93\|93;2\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightItalicBlue         start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(2;94\|94;2\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightItalicMagenta      start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(2;95\|95;2\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightItalicCyan         start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(2;96\|96;2\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightItalicWhite        start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(2;97\|97;2\)m" end="\e\["me=e-2 contains=ansiConceal

  syn region ansiBrightUnderlineBlack     start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(4;90\|90;4\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightUnderlineRed       start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(4;91\|91;4\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightUnderlineGreen     start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(4;92\|92;4\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightUnderlineYellow    start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(4;93\|93;4\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightUnderlineBlue      start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(4;94\|94;4\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightUnderlineMagenta   start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(4;95\|95;4\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightUnderlineCyan      start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(4;96\|96;4\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightUnderlineWhite     start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(4;97\|97;4\)m" end="\e\["me=e-2 contains=ansiConceal

  syn region ansiBrightBlinkBlack         start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(5;90\|90;5\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightBlinkRed           start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(5;91\|91;5\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightBlinkGreen         start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(5;92\|92;5\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightBlinkYellow        start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(5;93\|93;5\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightBlinkBlue          start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(5;94\|94;5\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightBlinkMagenta       start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(5;95\|95;5\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightBlinkCyan          start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(5;96\|96;5\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightBlinkWhite         start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(5;97\|97;5\)m" end="\e\["me=e-2 contains=ansiConceal

  syn region ansiBrightRapidBlinkBlack    start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(6;90\|90;6\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightRapidBlinkRed      start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(6;91\|91;6\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightRapidBlinkGreen    start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(6;92\|92;6\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightRapidBlinkYellow   start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(6;93\|93;6\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightRapidBlinkBlue     start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(6;94\|94;6\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightRapidBlinkMagenta  start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(6;95\|95;6\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightRapidBlinkCyan     start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(6;96\|96;6\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightRapidBlinkWhite    start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(6;97\|97;6\)m" end="\e\["me=e-2 contains=ansiConceal

  syn region ansiBrightRV                 start="\e\[;\=0\{0,2};\=\%(1;\)\=7m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightRVBlack            start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(7;90\|90;7\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightRVRed              start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(7;91\|91;7\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightRVGreen            start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(7;92\|92;7\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightRVYellow           start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(7;93\|93;7\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightRVBlue             start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(7;94\|94;7\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightRVMagenta          start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(7;95\|95;7\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightRVCyan             start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(7;96\|96;7\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBrightRVWhite            start="\e\[;\=0\{0,2};\=\%(1;\)\=\%(7;97\|97;7\)m" end="\e\["me=e-2 contains=ansiConceal

  if v:version >= 703
   " handles implicit background highlighting
"   call Decho("installing implicit background highlighting")

   syn cluster AnsiBlackBgGroup contains=ansiFgBlackBlack,ansiFgRedBlack,ansiFgGreenBlack,ansiFgYellowBlack,ansiFgBlueBlack,ansiFgMagentaBlack,ansiFgCyanBlack,ansiFgWhiteBlack
   syn region ansiBlackBg           start="\e\[;\=0\{0,2};\=\%(1;\)\=40\%(1;\)\=m" end="\e\[[04]\?"me=e-3 contains=ansiConceal,@ansiBlackBgGroup
   syn region ansiFgBlackBlack      contained   start="\e\[30m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgRedBlack        contained   start="\e\[31m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgGreenBlack      contained   start="\e\[32m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgYellowBlack     contained   start="\e\[33m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgBlueBlack       contained   start="\e\[34m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgMagentaBlack    contained   start="\e\[35m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgCyanBlack       contained   start="\e\[36m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgWhiteBlack      contained   start="\e\[37m" end="\e\["me=e-2 contains=ansiConceal
   hi link ansiFgBlackBlack         ansiBlackBlack
   hi link ansiFgRedBlack           ansiRedBlack
   hi link ansiFgGreenBlack         ansiGreenBlack
   hi link ansiFgYellowBlack        ansiYellowBlack
   hi link ansiFgBlueBlack          ansiBlueBlack
   hi link ansiFgMagentaBlack       ansiMagentaBlack
   hi link ansiFgCyanBlack          ansiCyanBlack
   hi link ansiFgWhiteBlack         ansiWhiteBlack

   syn cluster AnsiRedBgGroup contains=ansiFgBlackRed,ansiFgRedRed,ansiFgGreenRed,ansiFgYellowRed,ansiFgBlueRed,ansiFgMagentaRed,ansiFgCyanRed,ansiFgWhiteRed
   syn region ansiRedBg             start="\e\[;\=0\{0,2};\=\%(1;\)\=41\%(1;\)\=m" end="\e\[[04]\?"me=e-3 contains=ansiConceal,@ansiRedBgGroup
   syn region ansiFgBlackRed        contained   start="\e\[30m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgRedRed          contained   start="\e\[31m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgGreenRed        contained   start="\e\[32m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgYellowRed       contained   start="\e\[33m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgBlueRed         contained   start="\e\[34m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgMagentaRed      contained   start="\e\[35m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgCyanRed         contained   start="\e\[36m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgWhiteRed        contained   start="\e\[37m" end="\e\["me=e-2 contains=ansiConceal
   hi link ansiFgBlackRed           ansiBlackRed
   hi link ansiFgRedRed             ansiRedRed
   hi link ansiFgGreenRed           ansiGreenRed
   hi link ansiFgYellowRed          ansiYellowRed
   hi link ansiFgBlueRed            ansiBlueRed
   hi link ansiFgMagentaRed         ansiMagentaRed
   hi link ansiFgCyanRed            ansiCyanRed
   hi link ansiFgWhiteRed           ansiWhiteRed

   syn cluster AnsiGreenBgGroup contains=ansiFgBlackGreen,ansiFgRedGreen,ansiFgGreenGreen,ansiFgYellowGreen,ansiFgBlueGreen,ansiFgMagentaGreen,ansiFgCyanGreen,ansiFgWhiteGreen
   syn region ansiGreenBg           start="\e\[;\=0\{0,2};\=\%(1;\)\=42\%(1;\)\=m" end="\e\[[04]\?"me=e-3 contains=ansiConceal,@ansiGreenBgGroup
   syn region ansiFgBlackGreen      contained   start="\e\[30m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgRedGreen        contained   start="\e\[31m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgGreenGreen      contained   start="\e\[32m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgYellowGreen     contained   start="\e\[33m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgBlueGreen       contained   start="\e\[34m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgMagentaGreen    contained   start="\e\[35m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgCyanGreen       contained   start="\e\[36m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgWhiteGreen      contained   start="\e\[37m" end="\e\["me=e-2 contains=ansiConceal
   hi link ansiFgBlackGreen         ansiBlackGreen
   hi link ansiFgGreenGreen         ansiGreenGreen
   hi link ansiFgGreenGreen         ansiGreenGreen
   hi link ansiFgYellowGreen        ansiYellowGreen
   hi link ansiFgBlueGreen          ansiBlueGreen
   hi link ansiFgMagentaGreen       ansiMagentaGreen
   hi link ansiFgCyanGreen          ansiCyanGreen
   hi link ansiFgWhiteGreen         ansiWhiteGreen

   syn cluster AnsiYellowBgGroup contains=ansiFgBlackYellow,ansiFgRedYellow,ansiFgGreenYellow,ansiFgYellowYellow,ansiFgBlueYellow,ansiFgMagentaYellow,ansiFgCyanYellow,ansiFgWhiteYellow
   syn region ansiYellowBg          start="\e\[;\=0\{0,2};\=\%(1;\)\=43\%(1;\)\=m" end="\e\[[04]\?"me=e-3 contains=ansiConceal,@ansiYellowBgGroup
   syn region ansiFgBlackYellow     contained   start="\e\[30m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgRedYellow       contained   start="\e\[31m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgGreenYellow     contained   start="\e\[32m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgYellowYellow    contained   start="\e\[33m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgBlueYellow      contained   start="\e\[34m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgMagentaYellow   contained   start="\e\[35m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgCyanYellow      contained   start="\e\[36m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgWhiteYellow     contained   start="\e\[37m" end="\e\["me=e-2 contains=ansiConceal
   hi link ansiFgBlackYellow        ansiBlackYellow
   hi link ansiFgYellowYellow       ansiYellowYellow
   hi link ansiFgGreenYellow        ansiGreenYellow
   hi link ansiFgYellowYellow       ansiYellowYellow
   hi link ansiFgBlueYellow         ansiBlueYellow
   hi link ansiFgMagentaYellow      ansiMagentaYellow
   hi link ansiFgCyanYellow         ansiCyanYellow
   hi link ansiFgWhiteYellow        ansiWhiteYellow

   syn cluster AnsiBlueBgGroup contains=ansiFgBlackBlue,ansiFgRedBlue,ansiFgGreenBlue,ansiFgYellowBlue,ansiFgBlueBlue,ansiFgMagentaBlue,ansiFgCyanBlue,ansiFgWhiteBlue
   syn region ansiBlueBg            contained   start="\e\[;\=0\{0,2};\=\%(1;\)\=44\%(1;\)\=m" end="\e\[[04]\?"me=e-3 contains=ansiConceal,@ansiBlueBgGroup
   syn region ansiFgBlackBlue       contained   start="\e\[30m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgRedBlue         contained   start="\e\[31m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgGreenBlue       contained   start="\e\[32m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgYellowBlue      contained   start="\e\[33m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgBlueBlue        contained   start="\e\[34m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgMagentaBlue     contained   start="\e\[35m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgCyanBlue        contained   start="\e\[36m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgWhiteBlue       contained   start="\e\[37m" end="\e\["me=e-2 contains=ansiConceal
   hi link ansiFgBlackBlue          ansiBlackBlue
   hi link ansiFgBlueBlue                       ansiBlueBlue
   hi link ansiFgGreenBlue          ansiGreenBlue
   hi link ansiFgYellowBlue         ansiYellowBlue
   hi link ansiFgBlueBlue           ansiBlueBlue
   hi link ansiFgMagentaBlue        ansiMagentaBlue
   hi link ansiFgCyanBlue           ansiCyanBlue
   hi link ansiFgWhiteBlue          ansiWhiteBlue

   syn cluster AnsiBlueBgGroup contains=ansiFgBlackBlue,ansiFgRedBlue,ansiFgGreenBlue,ansiFgYellowBlue,ansiFgBlueBlue,ansiFgMagentaBlue,ansiFgCyanBlue,ansiFgWhiteBlue
   syn region ansiFgBlackBlue       contained   start="\e\[30m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgRedBlue         contained   start="\e\[31m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgGreenBlue       contained   start="\e\[32m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgYellowBlue      contained   start="\e\[33m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgBlueBlue        contained   start="\e\[34m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgMagentaBlue     contained   start="\e\[35m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgCyanBlue        contained   start="\e\[36m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgWhiteBlue       contained   start="\e\[37m" end="\e\["me=e-2 contains=ansiConceal
   hi link ansiFgBlackBlue          ansiBlackBlue
   hi link ansiFgBlueBlue           ansiBlueBlue
   hi link ansiFgGreenBlue          ansiGreenBlue
   hi link ansiFgYellowBlue         ansiYellowBlue
   hi link ansiFgBlueBlue           ansiBlueBlue
   hi link ansiFgMagentaBlue        ansiMagentaBlue
   hi link ansiFgCyanBlue           ansiCyanBlue
   hi link ansiFgWhiteBlue          ansiWhiteBlue

   syn cluster AnsiMagentaBgGroup contains=ansiFgBlackMagenta,ansiFgRedMagenta,ansiFgGreenMagenta,ansiFgYellowMagenta,ansiFgBlueMagenta,ansiFgMagentaMagenta,ansiFgCyanMagenta,ansiFgWhiteMagenta
   syn region ansiMagentaBg         contained   start="\e\[;\=0\{0,2};\=\%(1;\)\=45\%(1;\)\=m" end="\e\[[04]\?"me=e-3 contains=ansiConceal,@ansiMagentaBgGroup
   syn region ansiFgBlackMagenta    contained   start="\e\[30m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgRedMagenta      contained   start="\e\[31m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgGreenMagenta    contained   start="\e\[32m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgYellowMagenta   contained   start="\e\[33m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgBlueMagenta     contained   start="\e\[34m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgMagentaMagenta  contained   start="\e\[35m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgCyanMagenta     contained   start="\e\[36m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgWhiteMagenta    contained   start="\e\[37m" end="\e\["me=e-2 contains=ansiConceal
   hi link ansiFgBlackMagenta       ansiBlackMagenta
   hi link ansiFgMagentaMagenta     ansiMagentaMagenta
   hi link ansiFgGreenMagenta       ansiGreenMagenta
   hi link ansiFgYellowMagenta      ansiYellowMagenta
   hi link ansiFgBlueMagenta        ansiBlueMagenta
   hi link ansiFgMagentaMagenta     ansiMagentaMagenta
   hi link ansiFgCyanMagenta        ansiCyanMagenta
   hi link ansiFgWhiteMagenta       ansiWhiteMagenta

   syn cluster AnsiCyanBgGroup contains=ansiFgBlackCyan,ansiFgRedCyan,ansiFgGreenCyan,ansiFgYellowCyan,ansiFgBlueCyan,ansiFgMagentaCyan,ansiFgCyanCyan,ansiFgWhiteCyan
   syn region ansiCyanBg            start="\e\[;\=0\{0,2};\=\%(1;\)\=46\%(1;\)\=m" end="\e\[[04]\?"me=e-3 contains=ansiConceal,@ansiCyanBgGroup
   syn region ansiFgBlackCyan       contained   start="\e\[30m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgRedCyan         contained   start="\e\[31m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgGreenCyan       contained   start="\e\[32m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgYellowCyan      contained   start="\e\[33m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgBlueCyan        contained   start="\e\[34m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgMagentaCyan     contained   start="\e\[35m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgCyanCyan        contained   start="\e\[36m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgWhiteCyan       contained   start="\e\[37m" end="\e\["me=e-2 contains=ansiConceal
   hi link ansiFgBlackCyan          ansiBlackCyan
   hi link ansiFgCyanCyan           ansiCyanCyan
   hi link ansiFgGreenCyan          ansiGreenCyan
   hi link ansiFgYellowCyan         ansiYellowCyan
   hi link ansiFgBlueCyan           ansiBlueCyan
   hi link ansiFgMagentaCyan        ansiMagentaCyan
   hi link ansiFgCyanCyan           ansiCyanCyan
   hi link ansiFgWhiteCyan          ansiWhiteCyan

   syn cluster AnsiWhiteBgGroup contains=ansiFgBlackWhite,ansiFgRedWhite,ansiFgGreenWhite,ansiFgYellowWhite,ansiFgBlueWhite,ansiFgMagentaWhite,ansiFgCyanWhite,ansiFgWhiteWhite
   syn region ansiWhiteBg           start="\e\[;\=0\{0,2};\=\%(1;\)\=47\%(1;\)\=m" end="\e\[[04]\?"me=e-3 contains=ansiConceal,@ansiWhiteBgGroup
   syn region ansiFgBlackWhite      contained   start="\e\[30m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgRedWhite        contained   start="\e\[31m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgGreenWhite      contained   start="\e\[32m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgYellowWhite     contained   start="\e\[33m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgBlueWhite       contained   start="\e\[34m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgMagentaWhite    contained   start="\e\[35m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgCyanWhite       contained   start="\e\[36m" end="\e\["me=e-2 contains=ansiConceal
   syn region ansiFgWhiteWhite      contained   start="\e\[37m" end="\e\["me=e-2 contains=ansiConceal
   hi link ansiFgBlackWhite         ansiBlackWhite
   hi link ansiFgWhiteWhite         ansiWhiteWhite
   hi link ansiFgGreenWhite         ansiGreenWhite
   hi link ansiFgYellowWhite        ansiYellowWhite
   hi link ansiFgBlueWhite          ansiBlueWhite
   hi link ansiFgMagentaWhite       ansiMagentaWhite
   hi link ansiFgCyanWhite          ansiCyanWhite
   hi link ansiFgWhiteWhite         ansiWhiteWhite

  endif

  if has("conceal")
   syn match ansiStop               conceal "\e\[;\=0\{1,2}m"
   syn match ansiStop               conceal "\e\[K"
   syn match ansiStop               conceal "\e\[H"
   syn match ansiStop               conceal "\e\[2J"
  else
   syn match ansiStop               "\e\[;\=0\{0,2}m"
   syn match ansiStop               "\e\[K"
   syn match ansiStop               "\e\[H"
   syn match ansiStop               "\e\[2J"
  endif

  "syn match ansiIgnore             conceal "\e\[\([56];3[0-9]\|3[0-9];[56]\)m"
  "syn match ansiIgnore             conceal "\e\[\([0-9]\+;\)\{2,}[0-9]\+m"

  " ---------------------------------------------------------------------
  " Some Color Combinations: - can't do 'em all, the qty of highlighting groups is limited! {{{2
  " ---------------------------------------------------------------------
  syn region ansiBlackBlack         start="\e\[0\{0,2};\=\(30;40\|40;30\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiRedBlack           start="\e\[0\{0,2};\=\(31;40\|40;31\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiGreenBlack         start="\e\[0\{0,2};\=\(32;40\|40;32\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiYellowBlack        start="\e\[0\{0,2};\=\(33;40\|40;33\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBlueBlack          start="\e\[0\{0,2};\=\(34;40\|40;34\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiMagentaBlack       start="\e\[0\{0,2};\=\(35;40\|40;35\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiCyanBlack          start="\e\[0\{0,2};\=\(36;40\|40;36\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiWhiteBlack         start="\e\[0\{0,2};\=\(37;40\|40;37\)m" end="\e\["me=e-2 contains=ansiConceal

  syn region ansiBlackRed           start="\e\[0\{0,2};\=\(30;41\|41;30\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiRedRed             start="\e\[0\{0,2};\=\(31;41\|41;31\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiGreenRed           start="\e\[0\{0,2};\=\(32;41\|41;32\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiYellowRed          start="\e\[0\{0,2};\=\(33;41\|41;33\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBlueRed            start="\e\[0\{0,2};\=\(34;41\|41;34\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiMagentaRed         start="\e\[0\{0,2};\=\(35;41\|41;35\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiCyanRed            start="\e\[0\{0,2};\=\(36;41\|41;36\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiWhiteRed           start="\e\[0\{0,2};\=\(37;41\|41;37\)m" end="\e\["me=e-2 contains=ansiConceal

  syn region ansiBlackGreen         start="\e\[0\{0,2};\=\(30;42\|42;30\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiRedGreen           start="\e\[0\{0,2};\=\(31;42\|42;31\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiGreenGreen         start="\e\[0\{0,2};\=\(32;42\|42;32\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiYellowGreen        start="\e\[0\{0,2};\=\(33;42\|42;33\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBlueGreen          start="\e\[0\{0,2};\=\(34;42\|42;34\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiMagentaGreen       start="\e\[0\{0,2};\=\(35;42\|42;35\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiCyanGreen          start="\e\[0\{0,2};\=\(36;42\|42;36\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiWhiteGreen         start="\e\[0\{0,2};\=\(37;42\|42;37\)m" end="\e\["me=e-2 contains=ansiConceal

  syn region ansiBlackYellow        start="\e\[0\{0,2};\=\(30;43\|43;30\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiRedYellow          start="\e\[0\{0,2};\=\(31;43\|43;31\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiGreenYellow        start="\e\[0\{0,2};\=\(32;43\|43;32\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiYellowYellow       start="\e\[0\{0,2};\=\(33;43\|43;33\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBlueYellow         start="\e\[0\{0,2};\=\(34;43\|43;34\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiMagentaYellow      start="\e\[0\{0,2};\=\(35;43\|43;35\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiCyanYellow         start="\e\[0\{0,2};\=\(36;43\|43;36\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiWhiteYellow        start="\e\[0\{0,2};\=\(37;43\|43;37\)m" end="\e\["me=e-2 contains=ansiConceal

  syn region ansiBlackBlue          start="\e\[0\{0,2};\=\(30;44\|44;30\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiRedBlue            start="\e\[0\{0,2};\=\(31;44\|44;31\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiGreenBlue          start="\e\[0\{0,2};\=\(32;44\|44;32\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiYellowBlue         start="\e\[0\{0,2};\=\(33;44\|44;33\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBlueBlue           start="\e\[0\{0,2};\=\(34;44\|44;34\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiMagentaBlue        start="\e\[0\{0,2};\=\(35;44\|44;35\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiCyanBlue           start="\e\[0\{0,2};\=\(36;44\|44;36\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiWhiteBlue          start="\e\[0\{0,2};\=\(37;44\|44;37\)m" end="\e\["me=e-2 contains=ansiConceal

  syn region ansiBlackMagenta       start="\e\[0\{0,2};\=\(30;45\|45;30\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiRedMagenta         start="\e\[0\{0,2};\=\(31;45\|45;31\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiGreenMagenta       start="\e\[0\{0,2};\=\(32;45\|45;32\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiYellowMagenta      start="\e\[0\{0,2};\=\(33;45\|45;33\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBlueMagenta        start="\e\[0\{0,2};\=\(34;45\|45;34\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiMagentaMagenta     start="\e\[0\{0,2};\=\(35;45\|45;35\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiCyanMagenta        start="\e\[0\{0,2};\=\(36;45\|45;36\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiWhiteMagenta       start="\e\[0\{0,2};\=\(37;45\|45;37\)m" end="\e\["me=e-2 contains=ansiConceal

  syn region ansiBlackCyan          start="\e\[0\{0,2};\=\(30;46\|46;30\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiRedCyan            start="\e\[0\{0,2};\=\(31;46\|46;31\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiGreenCyan          start="\e\[0\{0,2};\=\(32;46\|46;32\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiYellowCyan         start="\e\[0\{0,2};\=\(33;46\|46;33\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBlueCyan           start="\e\[0\{0,2};\=\(34;46\|46;34\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiMagentaCyan        start="\e\[0\{0,2};\=\(35;46\|46;35\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiCyanCyan           start="\e\[0\{0,2};\=\(36;46\|46;36\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiWhiteCyan          start="\e\[0\{0,2};\=\(37;46\|46;37\)m" end="\e\["me=e-2 contains=ansiConceal

  syn region ansiBlackWhite         start="\e\[0\{0,2};\=\(30;47\|47;30\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiRedWhite           start="\e\[0\{0,2};\=\(31;47\|47;31\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiGreenWhite         start="\e\[0\{0,2};\=\(32;47\|47;32\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiYellowWhite        start="\e\[0\{0,2};\=\(33;47\|47;33\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiBlueWhite          start="\e\[0\{0,2};\=\(34;47\|47;34\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiMagentaWhite       start="\e\[0\{0,2};\=\(35;47\|47;35\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiCyanWhite          start="\e\[0\{0,2};\=\(36;47\|47;36\)m" end="\e\["me=e-2 contains=ansiConceal
  syn region ansiWhiteWhite         start="\e\[0\{0,2};\=\(37;47\|47;37\)m" end="\e\["me=e-2 contains=ansiConceal

  syn match ansiExtended            "\e\[;\=\(0;\)\=[34]8;\(\d*;\)*\d*m"   contains=ansiConceal

  if has("conceal")
   syn match ansiConceal                        contained conceal       "\e\[\(\d*;\)*\d*m"
  else
   syn match ansiConceal                        contained               "\e\[\(\d*;\)*\d*m"
  endif

  " -------------
  " Highlighting: {{{2
  " -------------
  if !has("conceal")
   " --------------
   " ansiesc_ignore: {{{3
   " --------------
   hi def link ansiConceal          Ignore
   hi def link ansiSuppress         Ignore
   hi def link ansiIgnore           ansiStop
   hi def link ansiStop             Ignore
   hi def link ansiExtended         Ignore
  endif
  let s:hlkeep_{bufnr("%")}= &l:hl
  if !has('nvim')
    exe "setlocal hl=".substitute(&hl,'8:[^,]\{-},','8:Ignore,',"")
  endif

  " handle 3 or more element ansi escape sequences by building syntax and highlighting rules
  " specific to the current file
  call AnsiEsc#MultiElementHandler()

  hi ansiNone           cterm=NONE      gui=NONE
  hi ansiBold           cterm=bold      gui=bold
  hi ansiUnderline      cterm=underline gui=underline

  if &t_Co == 8 || &t_Co == 256
   " ---------------------
   " eight-color handling: {{{3
   " ---------------------
"   call Decho("set up 8-color highlighting groups")
   hi ansiBlack             ctermfg=0          guifg=#073642                                      cterm=none         gui=none
   hi ansiRed               ctermfg=1          guifg=#dc322f                                      cterm=none         gui=none
   hi ansiGreen             ctermfg=2          guifg=#859900                                      cterm=none         gui=none
   hi ansiYellow            ctermfg=3          guifg=#b58900                                      cterm=none         gui=none
   hi ansiBlue              ctermfg=4          guifg=#268bd2                                      cterm=none         gui=none
   hi ansiMagenta           ctermfg=5          guifg=#d33682                                      cterm=none         gui=none
   hi ansiCyan              ctermfg=6          guifg=#2aa198                                      cterm=none         gui=none
   hi ansiWhite             ctermfg=7          guifg=#eee8d5                                      cterm=none         gui=none

   hi ansiBlackBg           ctermbg=0          guibg=#073642                                      cterm=none         gui=none
   hi ansiRedBg             ctermbg=1          guibg=#dc322f                                      cterm=none         gui=none
   hi ansiGreenBg           ctermbg=2          guibg=#859900                                      cterm=none         gui=none
   hi ansiYellowBg          ctermbg=3          guibg=#b58900                                      cterm=none         gui=none
   hi ansiBlueBg            ctermbg=4          guibg=#268bd2                                      cterm=none         gui=none
   hi ansiMagentaBg         ctermbg=5          guibg=#d33682                                      cterm=none         gui=none
   hi ansiCyanBg            ctermbg=6          guibg=#2aa198                                      cterm=none         gui=none
   hi ansiWhiteBg           ctermbg=7          guibg=#eee8d5                                      cterm=none         gui=none

   hi ansiBoldBlack         ctermfg=0          guifg=#073642                                      cterm=bold         gui=bold
   hi ansiBoldRed           ctermfg=1          guifg=#dc322f                                      cterm=bold         gui=bold
   hi ansiBoldGreen         ctermfg=2          guifg=#859900                                      cterm=bold         gui=bold
   hi ansiBoldYellow        ctermfg=3          guifg=#b58900                                      cterm=bold         gui=bold
   hi ansiBoldBlue          ctermfg=4          guifg=#268bd2                                      cterm=bold         gui=bold
   hi ansiBoldMagenta       ctermfg=5          guifg=#d33682                                      cterm=bold         gui=bold
   hi ansiBoldCyan          ctermfg=6          guifg=#2aa198                                      cterm=bold         gui=bold
   hi ansiBoldWhite         ctermfg=7          guifg=#eee8d5                                      cterm=bold         gui=bold

   hi ansiStandoutBlack     ctermfg=0          guifg=#073642                                      cterm=standout     gui=standout
   hi ansiStandoutRed       ctermfg=1          guifg=#dc322f                                      cterm=standout     gui=standout
   hi ansiStandoutGreen     ctermfg=2          guifg=#859900                                      cterm=standout     gui=standout
   hi ansiStandoutYellow    ctermfg=3          guifg=#b58900                                      cterm=standout     gui=standout
   hi ansiStandoutBlue      ctermfg=4          guifg=#268bd2                                      cterm=standout     gui=standout
   hi ansiStandoutMagenta   ctermfg=5          guifg=#d33682                                      cterm=standout     gui=standout
   hi ansiStandoutCyan      ctermfg=6          guifg=#2aa198                                      cterm=standout     gui=standout
   hi ansiStandoutWhite     ctermfg=7          guifg=#eee8d5                                      cterm=standout     gui=standout

   hi ansiItalicBlack       ctermfg=0          guifg=#073642                                      cterm=italic       gui=italic
   hi ansiItalicRed         ctermfg=1          guifg=#dc322f                                      cterm=italic       gui=italic
   hi ansiItalicGreen       ctermfg=2          guifg=#859900                                      cterm=italic       gui=italic
   hi ansiItalicYellow      ctermfg=3          guifg=#b58900                                      cterm=italic       gui=italic
   hi ansiItalicBlue        ctermfg=4          guifg=#268bd2                                      cterm=italic       gui=italic
   hi ansiItalicMagenta     ctermfg=5          guifg=#d33682                                      cterm=italic       gui=italic
   hi ansiItalicCyan        ctermfg=6          guifg=#2aa198                                      cterm=italic       gui=italic
   hi ansiItalicWhite       ctermfg=7          guifg=#eee8d5                                      cterm=italic       gui=italic

   hi ansiUnderlineBlack    ctermfg=0          guifg=#073642                                      cterm=underline    gui=underline
   hi ansiUnderlineRed      ctermfg=1          guifg=#dc322f                                      cterm=underline    gui=underline
   hi ansiUnderlineGreen    ctermfg=2          guifg=#859900                                      cterm=underline    gui=underline
   hi ansiUnderlineYellow   ctermfg=3          guifg=#b58900                                      cterm=underline    gui=underline
   hi ansiUnderlineBlue     ctermfg=4          guifg=#268bd2                                      cterm=underline    gui=underline
   hi ansiUnderlineMagenta  ctermfg=5          guifg=#d33682                                      cterm=underline    gui=underline
   hi ansiUnderlineCyan     ctermfg=6          guifg=#2aa198                                      cterm=underline    gui=underline
   hi ansiUnderlineWhite    ctermfg=7          guifg=#eee8d5                                      cterm=underline    gui=underline

   hi ansiBlinkBlack        ctermfg=0          guifg=#073642                                      cterm=standout     gui=undercurl
   hi ansiBlinkRed          ctermfg=1          guifg=#dc322f                                      cterm=standout     gui=undercurl
   hi ansiBlinkGreen        ctermfg=2          guifg=#859900                                      cterm=standout     gui=undercurl
   hi ansiBlinkYellow       ctermfg=3          guifg=#b58900                                      cterm=standout     gui=undercurl
   hi ansiBlinkBlue         ctermfg=4          guifg=#268bd2                                      cterm=standout     gui=undercurl
   hi ansiBlinkMagenta      ctermfg=5          guifg=#d33682                                      cterm=standout     gui=undercurl
   hi ansiBlinkCyan         ctermfg=6          guifg=#2aa198                                      cterm=standout     gui=undercurl
   hi ansiBlinkWhite        ctermfg=7          guifg=#eee8d5                                      cterm=standout     gui=undercurl

   hi ansiRapidBlinkBlack   ctermfg=0          guifg=#073642                                      cterm=standout     gui=undercurl
   hi ansiRapidBlinkRed     ctermfg=1          guifg=#dc322f                                      cterm=standout     gui=undercurl
   hi ansiRapidBlinkGreen   ctermfg=2          guifg=#859900                                      cterm=standout     gui=undercurl
   hi ansiRapidBlinkYellow  ctermfg=3          guifg=#b58900                                      cterm=standout     gui=undercurl
   hi ansiRapidBlinkBlue    ctermfg=4          guifg=#268bd2                                      cterm=standout     gui=undercurl
   hi ansiRapidBlinkMagenta ctermfg=5          guifg=#d33682                                      cterm=standout     gui=undercurl
   hi ansiRapidBlinkCyan    ctermfg=6          guifg=#2aa198                                      cterm=standout     gui=undercurl
   hi ansiRapidBlinkWhite   ctermfg=7          guifg=#eee8d5                                      cterm=standout     gui=undercurl

   hi ansiRV                                                                                      cterm=reverse      gui=reverse
   hi ansiRVBlack           ctermfg=0          guifg=#073642                                      cterm=reverse      gui=reverse
   hi ansiRVRed             ctermfg=1          guifg=#dc322f                                      cterm=reverse      gui=reverse
   hi ansiRVGreen           ctermfg=2          guifg=#859900                                      cterm=reverse      gui=reverse
   hi ansiRVYellow          ctermfg=3          guifg=#b58900                                      cterm=reverse      gui=reverse
   hi ansiRVBlue            ctermfg=4          guifg=#268bd2                                      cterm=reverse      gui=reverse
   hi ansiRVMagenta         ctermfg=5          guifg=#d33682                                      cterm=reverse      gui=reverse
   hi ansiRVCyan            ctermfg=6          guifg=#2aa198                                      cterm=reverse      gui=reverse
   hi ansiRVWhite           ctermfg=7          guifg=#eee8d5                                      cterm=reverse      gui=reverse

   hi ansiBrightBlack             ctermfg=8          guifg=#073642                                      cterm=none         gui=none
   hi ansiBrightRed               ctermfg=9          guifg=#cb4b16                                      cterm=none         gui=none
   hi ansiBrightGreen             ctermfg=10         guifg=#586e75                                      cterm=none         gui=none
   hi ansiBrightYellow            ctermfg=11         guifg=#657b83                                      cterm=none         gui=none
   hi ansiBrightBlue              ctermfg=12         guifg=#839496                                      cterm=none         gui=none
   hi ansiBrightMagenta           ctermfg=13         guifg=#6c71c4                                      cterm=none         gui=none
   hi ansiBrightCyan              ctermfg=14         guifg=#93a1a1                                      cterm=none         gui=none
   hi ansiBrightWhite             ctermfg=15         guifg=#fdf6e3                                      cterm=none         gui=none

   hi ansiBrightBlackBg           ctermbg=8          guibg=#073642                                      cterm=none         gui=none
   hi ansiBrightRedBg             ctermbg=9          guibg=#cb4b16                                      cterm=none         gui=none
   hi ansiBrightGreenBg           ctermbg=10         guibg=#586e75                                      cterm=none         gui=none
   hi ansiBrightYellowBg          ctermbg=11         guibg=#657b83                                      cterm=none         gui=none
   hi ansiBrightBlueBg            ctermbg=12         guibg=#839496                                      cterm=none         gui=none
   hi ansiBrightMagentaBg         ctermbg=13         guibg=#6c71c4                                      cterm=none         gui=none
   hi ansiBrightCyanBg            ctermbg=14         guibg=#93a1a1                                      cterm=none         gui=none
   hi ansiBrightWhiteBg           ctermbg=15         guibg=#fdf6e3                                      cterm=none         gui=none

   hi ansiBrightBoldBlack         ctermfg=8          guifg=#073642                                      cterm=bold         gui=bold
   hi ansiBrightBoldRed           ctermfg=9          guifg=#cb4b16                                      cterm=bold         gui=bold
   hi ansiBrightBoldGreen         ctermfg=10         guifg=#586e75                                      cterm=bold         gui=bold
   hi ansiBrightBoldYellow        ctermfg=11         guifg=#657b83                                      cterm=bold         gui=bold
   hi ansiBrightBoldBlue          ctermfg=12         guifg=#839496                                      cterm=bold         gui=bold
   hi ansiBrightBoldMagenta       ctermfg=13         guifg=#6c71c4                                      cterm=bold         gui=bold
   hi ansiBrightBoldCyan          ctermfg=14         guifg=#93a1a1                                      cterm=bold         gui=bold
   hi ansiBrightBoldWhite         ctermfg=15         guifg=#fdf6e3                                      cterm=bold         gui=bold

   hi ansiBrightStandoutBlack     ctermfg=8          guifg=#073642                                      cterm=standout     gui=standout
   hi ansiBrightStandoutRed       ctermfg=9          guifg=#cb4b16                                      cterm=standout     gui=standout
   hi ansiBrightStandoutGreen     ctermfg=10         guifg=#586e75                                      cterm=standout     gui=standout
   hi ansiBrightStandoutYellow    ctermfg=11         guifg=#657b83                                      cterm=standout     gui=standout
   hi ansiBrightStandoutBlue      ctermfg=12         guifg=#839496                                      cterm=standout     gui=standout
   hi ansiBrightStandoutMagenta   ctermfg=13         guifg=#6c71c4                                      cterm=standout     gui=standout
   hi ansiBrightStandoutCyan      ctermfg=14         guifg=#93a1a1                                      cterm=standout     gui=standout
   hi ansiBrightStandoutWhite     ctermfg=15         guifg=#fdf6e3                                      cterm=standout     gui=standout

   hi ansiBrightItalicBlack       ctermfg=8          guifg=#073642                                      cterm=italic       gui=italic
   hi ansiBrightItalicRed         ctermfg=9          guifg=#cb4b16                                      cterm=italic       gui=italic
   hi ansiBrightItalicGreen       ctermfg=10         guifg=#586e75                                      cterm=italic       gui=italic
   hi ansiBrightItalicYellow      ctermfg=11         guifg=#657b83                                      cterm=italic       gui=italic
   hi ansiBrightItalicBlue        ctermfg=12         guifg=#839496                                      cterm=italic       gui=italic
   hi ansiBrightItalicMagenta     ctermfg=13         guifg=#6c71c4                                      cterm=italic       gui=italic
   hi ansiBrightItalicCyan        ctermfg=14         guifg=#93a1a1                                      cterm=italic       gui=italic
   hi ansiBrightItalicWhite       ctermfg=15         guifg=#fdf6e3                                      cterm=italic       gui=italic

   hi ansiBrightUnderlineBlack    ctermfg=8          guifg=#073642                                      cterm=underline    gui=underline
   hi ansiBrightUnderlineRed      ctermfg=9          guifg=#cb4b16                                      cterm=underline    gui=underline
   hi ansiBrightUnderlineGreen    ctermfg=10         guifg=#586e75                                      cterm=underline    gui=underline
   hi ansiBrightUnderlineYellow   ctermfg=11         guifg=#657b83                                      cterm=underline    gui=underline
   hi ansiBrightUnderlineBlue     ctermfg=12         guifg=#839496                                      cterm=underline    gui=underline
   hi ansiBrightUnderlineMagenta  ctermfg=13         guifg=#6c71c4                                      cterm=underline    gui=underline
   hi ansiBrightUnderlineCyan     ctermfg=14         guifg=#93a1a1                                      cterm=underline    gui=underline
   hi ansiBrightUnderlineWhite    ctermfg=15         guifg=#fdf6e3                                      cterm=underline    gui=underline

   hi ansiBrightBlinkBlack        ctermfg=8          guifg=#073642                                      cterm=standout     gui=undercurl
   hi ansiBrightBlinkRed          ctermfg=9          guifg=#cb4b16                                      cterm=standout     gui=undercurl
   hi ansiBrightBlinkGreen        ctermfg=10         guifg=#586e75                                      cterm=standout     gui=undercurl
   hi ansiBrightBlinkYellow       ctermfg=11         guifg=#657b83                                      cterm=standout     gui=undercurl
   hi ansiBrightBlinkBlue         ctermfg=12         guifg=#839496                                      cterm=standout     gui=undercurl
   hi ansiBrightBlinkMagenta      ctermfg=13         guifg=#6c71c4                                      cterm=standout     gui=undercurl
   hi ansiBrightBlinkCyan         ctermfg=14         guifg=#93a1a1                                      cterm=standout     gui=undercurl
   hi ansiBrightBlinkWhite        ctermfg=15         guifg=#fdf6e3                                      cterm=standout     gui=undercurl

   hi ansiBrightRapidBlinkBlack   ctermfg=8          guifg=#073642                                      cterm=standout     gui=undercurl
   hi ansiBrightRapidBlinkRed     ctermfg=9          guifg=#cb4b16                                      cterm=standout     gui=undercurl
   hi ansiBrightRapidBlinkGreen   ctermfg=10         guifg=#586e75                                      cterm=standout     gui=undercurl
   hi ansiBrightRapidBlinkYellow  ctermfg=11         guifg=#657b83                                      cterm=standout     gui=undercurl
   hi ansiBrightRapidBlinkBlue    ctermfg=12         guifg=#839496                                      cterm=standout     gui=undercurl
   hi ansiBrightRapidBlinkMagenta ctermfg=13         guifg=#6c71c4                                      cterm=standout     gui=undercurl
   hi ansiBrightRapidBlinkCyan    ctermfg=14         guifg=#93a1a1                                      cterm=standout     gui=undercurl
   hi ansiBrightRapidBlinkWhite   ctermfg=15         guifg=#fdf6e3                                      cterm=standout     gui=undercurl

   hi ansiBrightRV                                                                                      cterm=reverse      gui=reverse
   hi ansiBrightRVBlack           ctermfg=8          guifg=#073642                                      cterm=reverse      gui=reverse
   hi ansiBrightRVRed             ctermfg=9          guifg=#cb4b16                                      cterm=reverse      gui=reverse
   hi ansiBrightRVGreen           ctermfg=10         guifg=#586e75                                      cterm=reverse      gui=reverse
   hi ansiBrightRVYellow          ctermfg=11         guifg=#657b83                                      cterm=reverse      gui=reverse
   hi ansiBrightRVBlue            ctermfg=12         guifg=#839496                                      cterm=reverse      gui=reverse
   hi ansiBrightRVMagenta         ctermfg=13         guifg=#6c71c4                                      cterm=reverse      gui=reverse
   hi ansiBrightRVCyan            ctermfg=14         guifg=#93a1a1                                      cterm=reverse      gui=reverse
   hi ansiBrightRVWhite           ctermfg=15         guifg=#fdf6e3                                      cterm=reverse      gui=reverse

   hi ansiBlackBlack        ctermfg=0          ctermbg=0          guifg=#073642    guibg=#073642  cterm=none         gui=none
   hi ansiRedBlack          ctermfg=1          ctermbg=0          guifg=#dc322f    guibg=#073642  cterm=none         gui=none
   hi ansiGreenBlack        ctermfg=2          ctermbg=0          guifg=#859900    guibg=#073642  cterm=none         gui=none
   hi ansiYellowBlack       ctermfg=3          ctermbg=0          guifg=#b58900    guibg=#073642  cterm=none         gui=none
   hi ansiBlueBlack         ctermfg=4          ctermbg=0          guifg=#268bd2    guibg=#073642  cterm=none         gui=none
   hi ansiMagentaBlack      ctermfg=5          ctermbg=0          guifg=#d33682    guibg=#073642  cterm=none         gui=none
   hi ansiCyanBlack         ctermfg=6          ctermbg=0          guifg=#2aa198    guibg=#073642  cterm=none         gui=none
   hi ansiWhiteBlack        ctermfg=7          ctermbg=0          guifg=#eee8d5    guibg=#073642  cterm=none         gui=none

   hi ansiBlackRed          ctermfg=0          ctermbg=1          guifg=#073642    guibg=#dc322f  cterm=none         gui=none
   hi ansiRedRed            ctermfg=1          ctermbg=1          guifg=#dc322f    guibg=#dc322f  cterm=none         gui=none
   hi ansiGreenRed          ctermfg=2          ctermbg=1          guifg=#859900    guibg=#dc322f  cterm=none         gui=none
   hi ansiYellowRed         ctermfg=3          ctermbg=1          guifg=#b58900    guibg=#dc322f  cterm=none         gui=none
   hi ansiBlueRed           ctermfg=4          ctermbg=1          guifg=#268bd2    guibg=#dc322f  cterm=none         gui=none
   hi ansiMagentaRed        ctermfg=5          ctermbg=1          guifg=#d33682    guibg=#dc322f  cterm=none         gui=none
   hi ansiCyanRed           ctermfg=6          ctermbg=1          guifg=#2aa198    guibg=#dc322f  cterm=none         gui=none
   hi ansiWhiteRed          ctermfg=7          ctermbg=1          guifg=#eee8d5    guibg=#dc322f  cterm=none         gui=none

   hi ansiBlackGreen        ctermfg=0          ctermbg=2          guifg=#073642    guibg=#859900  cterm=none         gui=none
   hi ansiRedGreen          ctermfg=1          ctermbg=2          guifg=#dc322f    guibg=#859900  cterm=none         gui=none
   hi ansiGreenGreen        ctermfg=2          ctermbg=2          guifg=#859900    guibg=#859900  cterm=none         gui=none
   hi ansiYellowGreen       ctermfg=3          ctermbg=2          guifg=#b58900    guibg=#859900  cterm=none         gui=none
   hi ansiBlueGreen         ctermfg=4          ctermbg=2          guifg=#268bd2    guibg=#859900  cterm=none         gui=none
   hi ansiMagentaGreen      ctermfg=5          ctermbg=2          guifg=#d33682    guibg=#859900  cterm=none         gui=none
   hi ansiCyanGreen         ctermfg=6          ctermbg=2          guifg=#2aa198    guibg=#859900  cterm=none         gui=none
   hi ansiWhiteGreen        ctermfg=7          ctermbg=2          guifg=#eee8d5    guibg=#859900  cterm=none         gui=none

   hi ansiBlackYellow       ctermfg=0          ctermbg=3          guifg=#073642    guibg=#b58900  cterm=none         gui=none
   hi ansiRedYellow         ctermfg=1          ctermbg=3          guifg=#dc322f    guibg=#b58900  cterm=none         gui=none
   hi ansiGreenYellow       ctermfg=2          ctermbg=3          guifg=#859900    guibg=#b58900  cterm=none         gui=none
   hi ansiYellowYellow      ctermfg=3          ctermbg=3          guifg=#b58900    guibg=#b58900  cterm=none         gui=none
   hi ansiBlueYellow        ctermfg=4          ctermbg=3          guifg=#268bd2    guibg=#b58900  cterm=none         gui=none
   hi ansiMagentaYellow     ctermfg=5          ctermbg=3          guifg=#d33682    guibg=#b58900  cterm=none         gui=none
   hi ansiCyanYellow        ctermfg=6          ctermbg=3          guifg=#2aa198    guibg=#b58900  cterm=none         gui=none
   hi ansiWhiteYellow       ctermfg=7          ctermbg=3          guifg=#eee8d5    guibg=#b58900  cterm=none         gui=none

   hi ansiBlackBlue         ctermfg=0          ctermbg=4          guifg=#073642    guibg=#268bd2  cterm=none         gui=none
   hi ansiRedBlue           ctermfg=1          ctermbg=4          guifg=#dc322f    guibg=#268bd2  cterm=none         gui=none
   hi ansiGreenBlue         ctermfg=2          ctermbg=4          guifg=#859900    guibg=#268bd2  cterm=none         gui=none
   hi ansiYellowBlue        ctermfg=3          ctermbg=4          guifg=#b58900    guibg=#268bd2  cterm=none         gui=none
   hi ansiBlueBlue          ctermfg=4          ctermbg=4          guifg=#268bd2    guibg=#268bd2  cterm=none         gui=none
   hi ansiMagentaBlue       ctermfg=5          ctermbg=4          guifg=#d33682    guibg=#268bd2  cterm=none         gui=none
   hi ansiCyanBlue          ctermfg=6          ctermbg=4          guifg=#2aa198    guibg=#268bd2  cterm=none         gui=none
   hi ansiWhiteBlue         ctermfg=7          ctermbg=4          guifg=#eee8d5    guibg=#268bd2  cterm=none         gui=none

   hi ansiBlackMagenta      ctermfg=0          ctermbg=5          guifg=#073642    guibg=#d33682  cterm=none         gui=none
   hi ansiRedMagenta        ctermfg=1          ctermbg=5          guifg=#dc322f    guibg=#d33682  cterm=none         gui=none
   hi ansiGreenMagenta      ctermfg=2          ctermbg=5          guifg=#859900    guibg=#d33682  cterm=none         gui=none
   hi ansiYellowMagenta     ctermfg=3          ctermbg=5          guifg=#b58900    guibg=#d33682  cterm=none         gui=none
   hi ansiBlueMagenta       ctermfg=4          ctermbg=5          guifg=#268bd2    guibg=#d33682  cterm=none         gui=none
   hi ansiMagentaMagenta    ctermfg=5          ctermbg=5          guifg=#d33682    guibg=#d33682  cterm=none         gui=none
   hi ansiCyanMagenta       ctermfg=6          ctermbg=5          guifg=#2aa198    guibg=#d33682  cterm=none         gui=none
   hi ansiWhiteMagenta      ctermfg=7          ctermbg=5          guifg=#eee8d5    guibg=#d33682  cterm=none         gui=none

   hi ansiBlackCyan         ctermfg=0          ctermbg=6          guifg=#073642    guibg=#2aa198  cterm=none         gui=none
   hi ansiRedCyan           ctermfg=1          ctermbg=6          guifg=#dc322f    guibg=#2aa198  cterm=none         gui=none
   hi ansiGreenCyan         ctermfg=2          ctermbg=6          guifg=#859900    guibg=#2aa198  cterm=none         gui=none
   hi ansiYellowCyan        ctermfg=3          ctermbg=6          guifg=#b58900    guibg=#2aa198  cterm=none         gui=none
   hi ansiBlueCyan          ctermfg=4          ctermbg=6          guifg=#268bd2    guibg=#2aa198  cterm=none         gui=none
   hi ansiMagentaCyan       ctermfg=5          ctermbg=6          guifg=#d33682    guibg=#2aa198  cterm=none         gui=none
   hi ansiCyanCyan          ctermfg=6          ctermbg=6          guifg=#2aa198    guibg=#2aa198  cterm=none         gui=none
   hi ansiWhiteCyan         ctermfg=7          ctermbg=6          guifg=#eee8d5    guibg=#2aa198  cterm=none         gui=none

   hi ansiBlackWhite        ctermfg=0          ctermbg=7          guifg=#073642    guibg=#eee8d5  cterm=none         gui=none
   hi ansiRedWhite          ctermfg=1          ctermbg=7          guifg=#dc322f    guibg=#eee8d5  cterm=none         gui=none
   hi ansiGreenWhite        ctermfg=2          ctermbg=7          guifg=#859900    guibg=#eee8d5  cterm=none         gui=none
   hi ansiYellowWhite       ctermfg=3          ctermbg=7          guifg=#b58900    guibg=#eee8d5  cterm=none         gui=none
   hi ansiBlueWhite         ctermfg=4          ctermbg=7          guifg=#268bd2    guibg=#eee8d5  cterm=none         gui=none
   hi ansiMagentaWhite      ctermfg=5          ctermbg=7          guifg=#d33682    guibg=#eee8d5  cterm=none         gui=none
   hi ansiCyanWhite         ctermfg=6          ctermbg=7          guifg=#2aa198    guibg=#eee8d5  cterm=none         gui=none
   hi ansiWhiteWhite        ctermfg=7          ctermbg=7          guifg=#eee8d5    guibg=#eee8d5  cterm=none         gui=none

   if v:version >= 700 && exists("+t_Co") && &t_Co == 256 && exists("g:ansiesc_256color")
    " ---------------------------
    " handle 256-color terminals: {{{3
    " ---------------------------
"    call Decho("set up 256-color highlighting groups")
    let icolor= 1
    while icolor < 256
     let jcolor= 1
     exe "hi ansiHL_".icolor."_0 ctermfg=".icolor
     exe "hi ansiHL_0_".icolor." ctermbg=".icolor
"     call Decho("exe hi ansiHL_".icolor." ctermfg=".icolor)
     while jcolor < 256
      exe "hi ansiHL_".icolor."_".jcolor." ctermfg=".icolor." ctermbg=".jcolor
"      call Decho("exe hi ansiHL_".icolor."_".jcolor." ctermfg=".icolor." ctermbg=".jcolor)
      let jcolor= jcolor + 1
     endwhile
     let icolor= icolor + 1
    endwhile
   endif

  else
   " ----------------------------------
   " not 8 or 256 color terminals (gui): {{{3
   " ----------------------------------
"   call Decho("set up gui highlighting groups")
   hi ansiBlack             ctermfg=0          guifg=#073642                                      cterm=none         gui=none
   hi ansiRed               ctermfg=1          guifg=#dc322f                                      cterm=none         gui=none
   hi ansiGreen             ctermfg=2          guifg=#859900                                      cterm=none         gui=none
   hi ansiYellow            ctermfg=3          guifg=#b58900                                      cterm=none         gui=none
   hi ansiBlue              ctermfg=4          guifg=#268bd2                                      cterm=none         gui=none
   hi ansiMagenta           ctermfg=5          guifg=#d33682                                      cterm=none         gui=none
   hi ansiCyan              ctermfg=6          guifg=#2aa198                                      cterm=none         gui=none
   hi ansiWhite             ctermfg=7          guifg=#eee8d5                                      cterm=none         gui=none

   hi ansiBlackBg           ctermbg=0          guibg=#073642                                      cterm=none         gui=none
   hi ansiRedBg             ctermbg=1          guibg=#dc322f                                      cterm=none         gui=none
   hi ansiGreenBg           ctermbg=2          guibg=#859900                                      cterm=none         gui=none
   hi ansiYellowBg          ctermbg=3          guibg=#b58900                                      cterm=none         gui=none
   hi ansiBlueBg            ctermbg=4          guibg=#268bd2                                      cterm=none         gui=none
   hi ansiMagentaBg         ctermbg=5          guibg=#d33682                                      cterm=none         gui=none
   hi ansiCyanBg            ctermbg=6          guibg=#2aa198                                      cterm=none         gui=none
   hi ansiWhiteBg           ctermbg=7          guibg=#eee8d5                                      cterm=none         gui=none

   hi ansiBoldBlack         ctermfg=0          guifg=#073642                                      cterm=bold         gui=bold
   hi ansiBoldRed           ctermfg=1          guifg=#dc322f                                      cterm=bold         gui=bold
   hi ansiBoldGreen         ctermfg=2          guifg=#859900                                      cterm=bold         gui=bold
   hi ansiBoldYellow        ctermfg=3          guifg=#b58900                                      cterm=bold         gui=bold
   hi ansiBoldBlue          ctermfg=4          guifg=#268bd2                                      cterm=bold         gui=bold
   hi ansiBoldMagenta       ctermfg=5          guifg=#d33682                                      cterm=bold         gui=bold
   hi ansiBoldCyan          ctermfg=6          guifg=#2aa198                                      cterm=bold         gui=bold
   hi ansiBoldWhite         ctermfg=7          guifg=#eee8d5                                      cterm=bold         gui=bold

   hi ansiStandoutBlack     ctermfg=0          guifg=#073642                                      cterm=standout     gui=standout
   hi ansiStandoutRed       ctermfg=1          guifg=#dc322f                                      cterm=standout     gui=standout
   hi ansiStandoutGreen     ctermfg=2          guifg=#859900                                      cterm=standout     gui=standout
   hi ansiStandoutYellow    ctermfg=3          guifg=#b58900                                      cterm=standout     gui=standout
   hi ansiStandoutBlue      ctermfg=4          guifg=#268bd2                                      cterm=standout     gui=standout
   hi ansiStandoutMagenta   ctermfg=5          guifg=#d33682                                      cterm=standout     gui=standout
   hi ansiStandoutCyan      ctermfg=6          guifg=#2aa198                                      cterm=standout     gui=standout
   hi ansiStandoutWhite     ctermfg=7          guifg=#eee8d5                                      cterm=standout     gui=standout

   hi ansiItalicBlack       ctermfg=0          guifg=#073642                                      cterm=italic       gui=italic
   hi ansiItalicRed         ctermfg=1          guifg=#dc322f                                      cterm=italic       gui=italic
   hi ansiItalicGreen       ctermfg=2          guifg=#859900                                      cterm=italic       gui=italic
   hi ansiItalicYellow      ctermfg=3          guifg=#b58900                                      cterm=italic       gui=italic
   hi ansiItalicBlue        ctermfg=4          guifg=#268bd2                                      cterm=italic       gui=italic
   hi ansiItalicMagenta     ctermfg=5          guifg=#d33682                                      cterm=italic       gui=italic
   hi ansiItalicCyan        ctermfg=6          guifg=#2aa198                                      cterm=italic       gui=italic
   hi ansiItalicWhite       ctermfg=7          guifg=#eee8d5                                      cterm=italic       gui=italic

   hi ansiUnderlineBlack    ctermfg=0          guifg=#073642                                      cterm=underline    gui=underline
   hi ansiUnderlineRed      ctermfg=1          guifg=#dc322f                                      cterm=underline    gui=underline
   hi ansiUnderlineGreen    ctermfg=2          guifg=#859900                                      cterm=underline    gui=underline
   hi ansiUnderlineYellow   ctermfg=3          guifg=#b58900                                      cterm=underline    gui=underline
   hi ansiUnderlineBlue     ctermfg=4          guifg=#268bd2                                      cterm=underline    gui=underline
   hi ansiUnderlineMagenta  ctermfg=5          guifg=#d33682                                      cterm=underline    gui=underline
   hi ansiUnderlineCyan     ctermfg=6          guifg=#2aa198                                      cterm=underline    gui=underline
   hi ansiUnderlineWhite    ctermfg=7          guifg=#eee8d5                                      cterm=underline    gui=underline

   hi ansiBlinkBlack        ctermfg=0          guifg=#073642                                      cterm=standout     gui=undercurl
   hi ansiBlinkRed          ctermfg=1          guifg=#dc322f                                      cterm=standout     gui=undercurl
   hi ansiBlinkGreen        ctermfg=2          guifg=#859900                                      cterm=standout     gui=undercurl
   hi ansiBlinkYellow       ctermfg=3          guifg=#b58900                                      cterm=standout     gui=undercurl
   hi ansiBlinkBlue         ctermfg=4          guifg=#268bd2                                      cterm=standout     gui=undercurl
   hi ansiBlinkMagenta      ctermfg=5          guifg=#d33682                                      cterm=standout     gui=undercurl
   hi ansiBlinkCyan         ctermfg=6          guifg=#2aa198                                      cterm=standout     gui=undercurl
   hi ansiBlinkWhite        ctermfg=7          guifg=#eee8d5                                      cterm=standout     gui=undercurl

   hi ansiRapidBlinkBlack   ctermfg=0          guifg=#073642                                      cterm=standout     gui=undercurl
   hi ansiRapidBlinkRed     ctermfg=1          guifg=#dc322f                                      cterm=standout     gui=undercurl
   hi ansiRapidBlinkGreen   ctermfg=2          guifg=#859900                                      cterm=standout     gui=undercurl
   hi ansiRapidBlinkYellow  ctermfg=3          guifg=#b58900                                      cterm=standout     gui=undercurl
   hi ansiRapidBlinkBlue    ctermfg=4          guifg=#268bd2                                      cterm=standout     gui=undercurl
   hi ansiRapidBlinkMagenta ctermfg=5          guifg=#d33682                                      cterm=standout     gui=undercurl
   hi ansiRapidBlinkCyan    ctermfg=6          guifg=#2aa198                                      cterm=standout     gui=undercurl
   hi ansiRapidBlinkWhite   ctermfg=7          guifg=#eee8d5                                      cterm=standout     gui=undercurl

   hi ansiRV                                                                                      cterm=reverse      gui=reverse
   hi ansiRVBlack           ctermfg=0          guifg=#073642                                      cterm=reverse      gui=reverse
   hi ansiRVRed             ctermfg=1          guifg=#dc322f                                      cterm=reverse      gui=reverse
   hi ansiRVGreen           ctermfg=2          guifg=#859900                                      cterm=reverse      gui=reverse
   hi ansiRVYellow          ctermfg=3          guifg=#b58900                                      cterm=reverse      gui=reverse
   hi ansiRVBlue            ctermfg=4          guifg=#268bd2                                      cterm=reverse      gui=reverse
   hi ansiRVMagenta         ctermfg=5          guifg=#d33682                                      cterm=reverse      gui=reverse
   hi ansiRVCyan            ctermfg=6          guifg=#2aa198                                      cterm=reverse      gui=reverse
   hi ansiRVWhite           ctermfg=7          guifg=#eee8d5                                      cterm=reverse      gui=reverse

   hi ansiBrightBlack             ctermfg=8          guifg=#073642                                      cterm=none         gui=none
   hi ansiBrightRed               ctermfg=9          guifg=#cb4b16                                      cterm=none         gui=none
   hi ansiBrightGreen             ctermfg=10         guifg=#586e75                                      cterm=none         gui=none
   hi ansiBrightYellow            ctermfg=11         guifg=#657b83                                      cterm=none         gui=none
   hi ansiBrightBlue              ctermfg=12         guifg=#839496                                      cterm=none         gui=none
   hi ansiBrightMagenta           ctermfg=13         guifg=#6c71c4                                      cterm=none         gui=none
   hi ansiBrightCyan              ctermfg=14         guifg=#93a1a1                                      cterm=none         gui=none
   hi ansiBrightWhite             ctermfg=15         guifg=#fdf6e3                                      cterm=none         gui=none

   hi ansiBrightBlackBg           ctermbg=8          guibg=#073642                                      cterm=none         gui=none
   hi ansiBrightRedBg             ctermbg=9          guibg=#cb4b16                                      cterm=none         gui=none
   hi ansiBrightGreenBg           ctermbg=10         guibg=#586e75                                      cterm=none         gui=none
   hi ansiBrightYellowBg          ctermbg=11         guibg=#657b83                                      cterm=none         gui=none
   hi ansiBrightBlueBg            ctermbg=12         guibg=#839496                                      cterm=none         gui=none
   hi ansiBrightMagentaBg         ctermbg=13         guibg=#6c71c4                                      cterm=none         gui=none
   hi ansiBrightCyanBg            ctermbg=14         guibg=#93a1a1                                      cterm=none         gui=none
   hi ansiBrightWhiteBg           ctermbg=15         guibg=#fdf6e3                                      cterm=none         gui=none

   hi ansiBrightBoldBlack         ctermfg=8          guifg=#073642                                      cterm=bold         gui=bold
   hi ansiBrightBoldRed           ctermfg=9          guifg=#cb4b16                                      cterm=bold         gui=bold
   hi ansiBrightBoldGreen         ctermfg=10         guifg=#586e75                                      cterm=bold         gui=bold
   hi ansiBrightBoldYellow        ctermfg=11         guifg=#657b83                                      cterm=bold         gui=bold
   hi ansiBrightBoldBlue          ctermfg=12         guifg=#839496                                      cterm=bold         gui=bold
   hi ansiBrightBoldMagenta       ctermfg=13         guifg=#6c71c4                                      cterm=bold         gui=bold
   hi ansiBrightBoldCyan          ctermfg=14         guifg=#93a1a1                                      cterm=bold         gui=bold
   hi ansiBrightBoldWhite         ctermfg=15         guifg=#fdf6e3                                      cterm=bold         gui=bold

   hi ansiBrightStandoutBlack     ctermfg=8          guifg=#073642                                      cterm=standout     gui=standout
   hi ansiBrightStandoutRed       ctermfg=9          guifg=#cb4b16                                      cterm=standout     gui=standout
   hi ansiBrightStandoutGreen     ctermfg=10         guifg=#586e75                                      cterm=standout     gui=standout
   hi ansiBrightStandoutYellow    ctermfg=11         guifg=#657b83                                      cterm=standout     gui=standout
   hi ansiBrightStandoutBlue      ctermfg=12         guifg=#839496                                      cterm=standout     gui=standout
   hi ansiBrightStandoutMagenta   ctermfg=13         guifg=#6c71c4                                      cterm=standout     gui=standout
   hi ansiBrightStandoutCyan      ctermfg=14         guifg=#93a1a1                                      cterm=standout     gui=standout
   hi ansiBrightStandoutWhite     ctermfg=15         guifg=#fdf6e3                                      cterm=standout     gui=standout

   hi ansiBrightItalicBlack       ctermfg=8          guifg=#073642                                      cterm=italic       gui=italic
   hi ansiBrightItalicRed         ctermfg=9          guifg=#cb4b16                                      cterm=italic       gui=italic
   hi ansiBrightItalicGreen       ctermfg=10         guifg=#586e75                                      cterm=italic       gui=italic
   hi ansiBrightItalicYellow      ctermfg=11         guifg=#657b83                                      cterm=italic       gui=italic
   hi ansiBrightItalicBlue        ctermfg=12         guifg=#839496                                      cterm=italic       gui=italic
   hi ansiBrightItalicMagenta     ctermfg=13         guifg=#6c71c4                                      cterm=italic       gui=italic
   hi ansiBrightItalicCyan        ctermfg=14         guifg=#93a1a1                                      cterm=italic       gui=italic
   hi ansiBrightItalicWhite       ctermfg=15         guifg=#fdf6e3                                      cterm=italic       gui=italic

   hi ansiBrightUnderlineBlack    ctermfg=8          guifg=#073642                                      cterm=underline    gui=underline
   hi ansiBrightUnderlineRed      ctermfg=9          guifg=#cb4b16                                      cterm=underline    gui=underline
   hi ansiBrightUnderlineGreen    ctermfg=10         guifg=#586e75                                      cterm=underline    gui=underline
   hi ansiBrightUnderlineYellow   ctermfg=11         guifg=#657b83                                      cterm=underline    gui=underline
   hi ansiBrightUnderlineBlue     ctermfg=12         guifg=#839496                                      cterm=underline    gui=underline
   hi ansiBrightUnderlineMagenta  ctermfg=13         guifg=#6c71c4                                      cterm=underline    gui=underline
   hi ansiBrightUnderlineCyan     ctermfg=14         guifg=#93a1a1                                      cterm=underline    gui=underline
   hi ansiBrightUnderlineWhite    ctermfg=15         guifg=#fdf6e3                                      cterm=underline    gui=underline

   hi ansiBrightBlinkBlack        ctermfg=8          guifg=#073642                                      cterm=standout     gui=undercurl
   hi ansiBrightBlinkRed          ctermfg=9          guifg=#cb4b16                                      cterm=standout     gui=undercurl
   hi ansiBrightBlinkGreen        ctermfg=10         guifg=#586e75                                      cterm=standout     gui=undercurl
   hi ansiBrightBlinkYellow       ctermfg=11         guifg=#657b83                                      cterm=standout     gui=undercurl
   hi ansiBrightBlinkBlue         ctermfg=12         guifg=#839496                                      cterm=standout     gui=undercurl
   hi ansiBrightBlinkMagenta      ctermfg=13         guifg=#6c71c4                                      cterm=standout     gui=undercurl
   hi ansiBrightBlinkCyan         ctermfg=14         guifg=#93a1a1                                      cterm=standout     gui=undercurl
   hi ansiBrightBlinkWhite        ctermfg=15         guifg=#fdf6e3                                      cterm=standout     gui=undercurl

   hi ansiBrightRapidBlinkBlack   ctermfg=8          guifg=#073642                                      cterm=standout     gui=undercurl
   hi ansiBrightRapidBlinkRed     ctermfg=9          guifg=#cb4b16                                      cterm=standout     gui=undercurl
   hi ansiBrightRapidBlinkGreen   ctermfg=10         guifg=#586e75                                      cterm=standout     gui=undercurl
   hi ansiBrightRapidBlinkYellow  ctermfg=11         guifg=#657b83                                      cterm=standout     gui=undercurl
   hi ansiBrightRapidBlinkBlue    ctermfg=12         guifg=#839496                                      cterm=standout     gui=undercurl
   hi ansiBrightRapidBlinkMagenta ctermfg=13         guifg=#6c71c4                                      cterm=standout     gui=undercurl
   hi ansiBrightRapidBlinkCyan    ctermfg=14         guifg=#93a1a1                                      cterm=standout     gui=undercurl
   hi ansiBrightRapidBlinkWhite   ctermfg=15         guifg=#fdf6e3                                      cterm=standout     gui=undercurl

   hi ansiBrightRV                                                                                      cterm=reverse      gui=reverse
   hi ansiBrightRVBlack           ctermfg=8          guifg=#073642                                      cterm=reverse      gui=reverse
   hi ansiBrightRVRed             ctermfg=9          guifg=#cb4b16                                      cterm=reverse      gui=reverse
   hi ansiBrightRVGreen           ctermfg=10         guifg=#586e75                                      cterm=reverse      gui=reverse
   hi ansiBrightRVYellow          ctermfg=11         guifg=#657b83                                      cterm=reverse      gui=reverse
   hi ansiBrightRVBlue            ctermfg=12         guifg=#839496                                      cterm=reverse      gui=reverse
   hi ansiBrightRVMagenta         ctermfg=13         guifg=#6c71c4                                      cterm=reverse      gui=reverse
   hi ansiBrightRVCyan            ctermfg=14         guifg=#93a1a1                                      cterm=reverse      gui=reverse
   hi ansiBrightRVWhite           ctermfg=15         guifg=#fdf6e3                                      cterm=reverse      gui=reverse


   hi ansiBlackBlack        ctermfg=0          ctermbg=0          guifg=#073642    guibg=#073642  cterm=none         gui=none
   hi ansiRedBlack          ctermfg=1          ctermbg=0          guifg=#dc322f    guibg=#073642  cterm=none         gui=none
   hi ansiGreenBlack        ctermfg=2          ctermbg=0          guifg=#859900    guibg=#073642  cterm=none         gui=none
   hi ansiYellowBlack       ctermfg=3          ctermbg=0          guifg=#b58900    guibg=#073642  cterm=none         gui=none
   hi ansiBlueBlack         ctermfg=4          ctermbg=0          guifg=#268bd2    guibg=#073642  cterm=none         gui=none
   hi ansiMagentaBlack      ctermfg=5          ctermbg=0          guifg=#d33682    guibg=#073642  cterm=none         gui=none
   hi ansiCyanBlack         ctermfg=6          ctermbg=0          guifg=#2aa198    guibg=#073642  cterm=none         gui=none
   hi ansiWhiteBlack        ctermfg=7          ctermbg=0          guifg=#eee8d5    guibg=#073642  cterm=none         gui=none

   hi ansiBlackRed          ctermfg=0          ctermbg=1          guifg=#073642    guibg=#dc322f  cterm=none         gui=none
   hi ansiRedRed            ctermfg=1          ctermbg=1          guifg=#dc322f    guibg=#dc322f  cterm=none         gui=none
   hi ansiGreenRed          ctermfg=2          ctermbg=1          guifg=#859900    guibg=#dc322f  cterm=none         gui=none
   hi ansiYellowRed         ctermfg=3          ctermbg=1          guifg=#b58900    guibg=#dc322f  cterm=none         gui=none
   hi ansiBlueRed           ctermfg=4          ctermbg=1          guifg=#268bd2    guibg=#dc322f  cterm=none         gui=none
   hi ansiMagentaRed        ctermfg=5          ctermbg=1          guifg=#d33682    guibg=#dc322f  cterm=none         gui=none
   hi ansiCyanRed           ctermfg=6          ctermbg=1          guifg=#2aa198    guibg=#dc322f  cterm=none         gui=none
   hi ansiWhiteRed          ctermfg=7          ctermbg=1          guifg=#eee8d5    guibg=#dc322f  cterm=none         gui=none

   hi ansiBlackGreen        ctermfg=0          ctermbg=2          guifg=#073642    guibg=#859900  cterm=none         gui=none
   hi ansiRedGreen          ctermfg=1          ctermbg=2          guifg=#dc322f    guibg=#859900  cterm=none         gui=none
   hi ansiGreenGreen        ctermfg=2          ctermbg=2          guifg=#859900    guibg=#859900  cterm=none         gui=none
   hi ansiYellowGreen       ctermfg=3          ctermbg=2          guifg=#b58900    guibg=#859900  cterm=none         gui=none
   hi ansiBlueGreen         ctermfg=4          ctermbg=2          guifg=#268bd2    guibg=#859900  cterm=none         gui=none
   hi ansiMagentaGreen      ctermfg=5          ctermbg=2          guifg=#d33682    guibg=#859900  cterm=none         gui=none
   hi ansiCyanGreen         ctermfg=6          ctermbg=2          guifg=#2aa198    guibg=#859900  cterm=none         gui=none
   hi ansiWhiteGreen        ctermfg=7          ctermbg=2          guifg=#eee8d5    guibg=#859900  cterm=none         gui=none

   hi ansiBlackYellow       ctermfg=0          ctermbg=3          guifg=#073642    guibg=#b58900  cterm=none         gui=none
   hi ansiRedYellow         ctermfg=1          ctermbg=3          guifg=#dc322f    guibg=#b58900  cterm=none         gui=none
   hi ansiGreenYellow       ctermfg=2          ctermbg=3          guifg=#859900    guibg=#b58900  cterm=none         gui=none
   hi ansiYellowYellow      ctermfg=3          ctermbg=3          guifg=#b58900    guibg=#b58900  cterm=none         gui=none
   hi ansiBlueYellow        ctermfg=4          ctermbg=3          guifg=#268bd2    guibg=#b58900  cterm=none         gui=none
   hi ansiMagentaYellow     ctermfg=5          ctermbg=3          guifg=#d33682    guibg=#b58900  cterm=none         gui=none
   hi ansiCyanYellow        ctermfg=6          ctermbg=3          guifg=#2aa198    guibg=#b58900  cterm=none         gui=none
   hi ansiWhiteYellow       ctermfg=7          ctermbg=3          guifg=#eee8d5    guibg=#b58900  cterm=none         gui=none

   hi ansiBlackBlue         ctermfg=0          ctermbg=4          guifg=#073642    guibg=#268bd2  cterm=none         gui=none
   hi ansiRedBlue           ctermfg=1          ctermbg=4          guifg=#dc322f    guibg=#268bd2  cterm=none         gui=none
   hi ansiGreenBlue         ctermfg=2          ctermbg=4          guifg=#859900    guibg=#268bd2  cterm=none         gui=none
   hi ansiYellowBlue        ctermfg=3          ctermbg=4          guifg=#b58900    guibg=#268bd2  cterm=none         gui=none
   hi ansiBlueBlue          ctermfg=4          ctermbg=4          guifg=#268bd2    guibg=#268bd2  cterm=none         gui=none
   hi ansiMagentaBlue       ctermfg=5          ctermbg=4          guifg=#d33682    guibg=#268bd2  cterm=none         gui=none
   hi ansiCyanBlue          ctermfg=6          ctermbg=4          guifg=#2aa198    guibg=#268bd2  cterm=none         gui=none
   hi ansiWhiteBlue         ctermfg=7          ctermbg=4          guifg=#eee8d5    guibg=#268bd2  cterm=none         gui=none

   hi ansiBlackMagenta      ctermfg=0          ctermbg=5          guifg=#073642    guibg=#d33682  cterm=none         gui=none
   hi ansiRedMagenta        ctermfg=1          ctermbg=5          guifg=#dc322f    guibg=#d33682  cterm=none         gui=none
   hi ansiGreenMagenta      ctermfg=2          ctermbg=5          guifg=#859900    guibg=#d33682  cterm=none         gui=none
   hi ansiYellowMagenta     ctermfg=3          ctermbg=5          guifg=#b58900    guibg=#d33682  cterm=none         gui=none
   hi ansiBlueMagenta       ctermfg=4          ctermbg=5          guifg=#268bd2    guibg=#d33682  cterm=none         gui=none
   hi ansiMagentaMagenta    ctermfg=5          ctermbg=5          guifg=#d33682    guibg=#d33682  cterm=none         gui=none
   hi ansiCyanMagenta       ctermfg=6          ctermbg=5          guifg=#2aa198    guibg=#d33682  cterm=none         gui=none
   hi ansiWhiteMagenta      ctermfg=7          ctermbg=5          guifg=#eee8d5    guibg=#d33682  cterm=none         gui=none

   hi ansiBlackCyan         ctermfg=0          ctermbg=6          guifg=#073642    guibg=#2aa198  cterm=none         gui=none
   hi ansiRedCyan           ctermfg=1          ctermbg=6          guifg=#dc322f    guibg=#2aa198  cterm=none         gui=none
   hi ansiGreenCyan         ctermfg=2          ctermbg=6          guifg=#859900    guibg=#2aa198  cterm=none         gui=none
   hi ansiYellowCyan        ctermfg=3          ctermbg=6          guifg=#b58900    guibg=#2aa198  cterm=none         gui=none
   hi ansiBlueCyan          ctermfg=4          ctermbg=6          guifg=#268bd2    guibg=#2aa198  cterm=none         gui=none
   hi ansiMagentaCyan       ctermfg=5          ctermbg=6          guifg=#d33682    guibg=#2aa198  cterm=none         gui=none
   hi ansiCyanCyan          ctermfg=6          ctermbg=6          guifg=#2aa198    guibg=#2aa198  cterm=none         gui=none
   hi ansiWhiteCyan         ctermfg=7          ctermbg=6          guifg=#eee8d5    guibg=#2aa198  cterm=none         gui=none

   hi ansiBlackWhite        ctermfg=0          ctermbg=7          guifg=#073642    guibg=#eee8d5  cterm=none         gui=none
   hi ansiRedWhite          ctermfg=1          ctermbg=7          guifg=#dc322f    guibg=#eee8d5  cterm=none         gui=none
   hi ansiGreenWhite        ctermfg=2          ctermbg=7          guifg=#859900    guibg=#eee8d5  cterm=none         gui=none
   hi ansiYellowWhite       ctermfg=3          ctermbg=7          guifg=#b58900    guibg=#eee8d5  cterm=none         gui=none
   hi ansiBlueWhite         ctermfg=4          ctermbg=7          guifg=#268bd2    guibg=#eee8d5  cterm=none         gui=none
   hi ansiMagentaWhite      ctermfg=5          ctermbg=7          guifg=#d33682    guibg=#eee8d5  cterm=none         gui=none
   hi ansiCyanWhite         ctermfg=6          ctermbg=7          guifg=#2aa198    guibg=#eee8d5  cterm=none         gui=none
   hi ansiWhiteWhite        ctermfg=7          ctermbg=7          guifg=#eee8d5    guibg=#eee8d5  cterm=none         gui=none
  endif
"  call Dret("AnsiEsc#AnsiEsc")
endfun

" ---------------------------------------------------------------------
" AnsiEsc#MultiElementHandler: builds custom syntax highlighting for three or more element ansi escape sequences {{{2
fun! AnsiEsc#MultiElementHandler()
"  call Dfunc("AnsiEsc#MultiElementHandler()")
  let curwp= SaveWinPosn(0)
  keepj 1
  keepj norm! 0
  let mehcnt = 0
  let mehrules     = []
  while search('\e\[;\=\d\+;\d\+;\d\+\(;\d\+\)*m','cW')
   let curcol  = col(".")+1
   call search('m','cW')
   let mcol    = col(".")
   let ansiesc = strpart(getline("."),curcol,mcol - curcol)
   let aecodes = split(ansiesc,'[;m]')
"   call Decho("ansiesc<".ansiesc."> aecodes=".string(aecodes))
   let skip         = 0
   let mod          = "NONE,"
   let fg           = ""
   let bg           = ""

   " if the ansiesc is
   if index(mehrules,ansiesc) == -1
    let mehrules+= [ansiesc]

    for code in aecodes

     " handle multi-code sequences (38;5;color  and 48;5;color)
     if skip == 38 && code == 5
      " handling <esc>[38;5
      let skip= 385
"      call Decho(" 1: building code=".code." skip=".skip.": mod<".mod."> fg<".fg."> bg<".bg.">")
      continue
     elseif skip == 385
      " handling <esc>[38;5;...
      if has("gui") && has("gui_running")
       let fg= AnsiEsc#Ansi2Gui(code)
      else
       let fg= code
      endif
      let skip= 0
"      call Decho(" 2: building code=".code." skip=".skip.": mod<".mod."> fg<".fg."> bg<".bg.">")
      continue

     elseif skip == 48 && code == 5
      " handling <esc>[48;5
      let skip= 485
"      call Decho(" 3: building code=".code." skip=".skip.": mod<".mod."> fg<".fg."> bg<".bg.">")
      continue
     elseif skip == 485
      " handling <esc>[48;5;...
      if has("gui") && has("gui_running")
       let bg= AnsiEsc#Ansi2Gui(code)
      else
       let bg= code
      endif
      let skip= 0
"      call Decho(" 4: building code=".code." skip=".skip.": mod<".mod."> fg<".fg."> bg<".bg.">")
      continue

     else
      let skip= 0
     endif

     " handle single-code sequences
     if code == 1
      let mod=mod."bold,"
     elseif code == 2
      let mod=mod."italic,"
     elseif code == 3
      let mod=mod."standout,"
     elseif code == 4
      let mod=mod."underline,"
     elseif code == 5 || code == 6
      let mod=mod."undercurl,"
     elseif code == 7
      let mod=mod."reverse,"

     elseif code >= 90 && code < 98
      let fg= code - 90 + 8

     elseif code >= 30 && code < 38
      let fg= code - 30

     elseif code >= 100 && code < 108
      let bg= code - 100 + 8

     elseif code >= 40 && code < 48
      let bg= code - 40

     elseif code == 38
      let skip= 38

     elseif code == 48
      let skip= 48
     endif

"     call Decho(" 5: building code=".code." skip=".skip.": mod<".mod."> fg<".fg."> bg<".bg.">")
    endfor

    " fixups
    let mod= substitute(mod,',$','','')

    " build syntax-recognition rule
    let mehcnt  = mehcnt + 1
    let synrule = "syn region ansiMEH".mehcnt
    let synrule = synrule.' start="\e\['.ansiesc.'"'
    let synrule = synrule.' end="\e\["me=e-2'
    let synrule = synrule." contains=ansiConceal"
"    call Decho(" exe synrule: ".synrule)
    exe synrule

    " build highlighting rule
    let hirule= "hi ansiMEH".mehcnt
    if has("gui") && has("gui_running")
     let hirule=hirule." gui=".mod
     if fg != ""| let hirule=hirule." guifg=".fg| endif
     if bg != ""| let hirule=hirule." guibg=".bg| endif
    else
     let hirule=hirule." cterm=".mod
     if fg != ""| let hirule=hirule." ctermfg=".fg| endif
     if bg != ""| let hirule=hirule." ctermbg=".bg| endif
    endif
"    call Decho(" exe hirule: ".hirule)
    exe hirule
   endif

  endwhile

  call RestoreWinPosn(curwp)
"  call Dret("AnsiEsc#MultiElementHandler")
endfun

" ---------------------------------------------------------------------
" AnsiEsc#Ansi2Gui: converts an ansi-escape sequence (for 256-color xterms) {{{2
"           to an equivalent gui color
"           colors   0- 15:
"           colors  16-231:  6x6x6 color cube, code= 16+r*36+g*6+b  with r,g,b each in [0,5]
"           colors 232-255:  grayscale ramp,   code= 10*gray + 8    with gray in [0,23] (black,white left out)
fun! AnsiEsc#Ansi2Gui(code)
"  call Dfunc("AnsiEsc#Ansi2Gui(code=)".a:code)
  let guicolor= a:code
  if a:code < 16
   let code2rgb = [ "black", "red3", "green3", "yellow3", "blue3", "magenta3", "cyan3", "gray70", "gray40", "red", "green", "yellow", "royalblue3", "magenta", "cyan", "white"]
   let guicolor = code2rgb[a:code]
  elseif a:code >= 232
   let code     = a:code - 232
   let code     = 10*code + 8
   let guicolor = printf("#%02x%02x%02x",code,code,code)
  else
   let code     = a:code - 16
   let code2rgb = [43,85,128,170,213,255]
   let r        = code2rgb[code/36]
   let g        = code2rgb[(code%36)/6]
   let b        = code2rgb[code%6]
   let guicolor = printf("#%02x%02x%02x",r,g,b)
  endif
"  call Dret("AnsiEsc#Ansi2Gui ".guicolor)
  return guicolor
endfun

" ---------------------------------------------------------------------
"  Restore: {{{1
let &cpo= s:keepcpo
unlet s:keepcpo

" ---------------------------------------------------------------------
"  Modelines: {{{1
" vim: ts=12 fdm=marker
