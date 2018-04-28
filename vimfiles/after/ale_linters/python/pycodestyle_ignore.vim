call ale#linter#Define('python', {
    \   'name': 'pycodestyle_ignore',
    \   'executable_callback': 'ale_linters#python#pycodestyle#GetExecutable',
    \   'command_callback': 'ale_linters#python#pycodestyle#GetCommand',
    \   'callback': {buffer, lines ->
    \       pylama_ignores#handle('ale_linters#python#pycodestyle#Handle',
    \                             buffer, lines)},
    \})
