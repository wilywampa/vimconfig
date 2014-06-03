if [[ -z "$SOLARIZED_TOGGLE" ]]; then
  export SOLARIZED_TOGGLE=0
fi

if [ $SOLARIZED_TOGGLE = "1" ]; then
  xtermcontrol \
    --bg='#002b36'       --fg='#839496'       --cursor='#93a1a1'  \
    --mouse-bg='#586e75' --mouse-fg='#93a1a1' --color0='#073642'  \
    --color1='#dc322f'   --color2='#859900'   --color3='#b58900'  \
    --color4='#268bd2'   --color5='#d33682'   --color6='#2aa198'  \
    --color7='#eee8d5'   --color8='#002b36'   --color9='#cb4b16'  \
    --color10='#586e75'  --color11='#657b83'  --color12='#839496' \
    --color13='#6c71c4'  --color14='#93a1a1'  --color15='#fdf6e3'
  export SOLARIZED_TOGGLE=0
else
  xtermcontrol \
    --bg='#fdf6e3'       --fg='#657b83'       --cursor='#586e75'  \
    --mouse-bg='#93a1a1' --mouse-fg='#586e75' --color0='#eee8d5'  \
    --color1='#dc322f'   --color2='#859900'   --color3='#b58900'  \
    --color4='#268bd2'   --color5='#d33682'   --color6='#2aa198'  \
    --color7='#073642'   --color8='#fdf6e3'   --color9='#cb4b16'  \
    --color10='#93a1a1'  --color11='#839496'  --color12='#657b83' \
    --color13='#6c71c4'  --color14='#586e75'  --color15='#002b36'
  export SOLARIZED_TOGGLE=1
fi
