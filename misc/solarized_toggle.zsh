if [[ -z "$SOLARIZED_TOGGLE" ]]; then
  export SOLARIZED_TOGGLE=0
fi

if [ $SOLARIZED_TOGGLE = "1" ]; then
  xtermcontrol --bg='#002b36' --fg='#839496' --cursor='#93a1a1' \
    --mouse-bg='#586e75' --mouse-fg='#93a1a1' --highlight='#000000'
  export SOLARIZED_TOGGLE=0
  >~/.vim/after/bg.vim <<< 'set background=dark'
else
  xtermcontrol --bg='#fdf6e3' --fg='#657b83' --cursor='#586e75' \
    --mouse-bg='#93a1a1' --mouse-fg='#586e75' --highlight='#000000'
  export SOLARIZED_TOGGLE=1
  >~/.vim/after/bg.vim <<< 'set background=light'
fi
