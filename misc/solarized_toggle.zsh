if [[ -z "$SOLARIZED_TOGGLE" ]]; then
  export SOLARIZED_TOGGLE=0
fi

if [ $SOLARIZED_TOGGLE = "1" ]; then
  TERM=xterm-256color xtermcontrol --bg='#012833' --fg='#839496' \
    --mouse-bg='#586e75' --mouse-fg='#93a1a1' --highlight='#000000'
  export SOLARIZED_TOGGLE=0
  >~/.vim/after/plugin/bg.vim <<< 'set background=dark'
else
  TERM=xterm-256color xtermcontrol --bg='#fdf6e3' --fg='#657b83' \
    --mouse-bg='#93a1a1' --mouse-fg='#586e75' --highlight='#000000'
  export SOLARIZED_TOGGLE=1
  >~/.vim/after/plugin/bg.vim <<< 'set background=light'
fi
