call ale#linter#Define('python', {
    \   'name': 'pycodestyle_ignore',
    \   'executable': function('ale_linters#python#pycodestyle#GetExecutable'),
    \   'command': function('ale_linters#python#pycodestyle#GetCommand'),
    \   'callback': {buffer, lines ->
    \       pylama_ignores#handle('ale_linters#python#pycodestyle#Handle',
    \                             buffer, lines)},
    \})
