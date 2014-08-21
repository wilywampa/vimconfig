if [[ -z "$SOLARIZED_TOGGLE" ]]; then
  export SOLARIZED_TOGGLE=0
fi

if [ $SOLARIZED_TOGGLE = "1" ]; then
  xtermcontrol -f --bg='#012833' --fg='#839496' \
    --mouse-bg='#586e75' --mouse-fg='#93a1a1' --highlight='#000000'
  echo 'set background=dark' > $HOME/.vim/after/plugin/bg.vim
  [[ -n $TMUX ]] && tmux run-shell "cut -c3- $HOME/.tmux.conf | sh -s status_dark"
  for instance in $(vim --serverlist); do
    vim --servername $instance --remote-send "<C-\><C-n>:set background=dark<CR>:redraw!<CR>"
  done
  export SOLARIZED_TOGGLE=0
else
  xtermcontrol -f --bg='#fdf6e3' --fg='#657b83' \
    --mouse-bg='#93a1a1' --mouse-fg='#586e75' --highlight='#000000'
  echo 'set background=light' > $HOME/.vim/after/plugin/bg.vim
  [[ -n $TMUX ]] && tmux run-shell "cut -c3- $HOME/.tmux.conf | sh -s status_light"
  for instance in $(vim --serverlist); do
    vim --servername $instance --remote-send "<C-\><C-n>:set background=light<CR>:redraw!<CR>"
  done
  export SOLARIZED_TOGGLE=1
fi
