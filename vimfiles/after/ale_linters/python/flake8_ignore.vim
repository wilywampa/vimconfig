call ale#linter#Define('python', {
\   'name': 'flake8_ignore',
\   'executable': function('ale_linters#python#flake8#GetExecutable'),
\   'command': function('ale_linters#python#flake8#RunWithVersionCheck'),
\   'callback': {buffer, lines ->
\       pylama_ignores#handle('ale_linters#python#flake8#Handle',
\                             buffer, lines)},
\})
