call ale#linter#Define('python', {
\   'name': 'flake8_ignore',
\   'executable_callback': 'ale_linters#python#flake8#GetExecutable',
\   'command_chain': [
\       {'callback': 'ale_linters#python#flake8#VersionCheck'},
\       {'callback': 'ale_linters#python#flake8#GetCommand', 'output_stream': 'both'},
\   ],
\   'callback': {buffer, lines ->
\       pylama_ignores#handle('ale_linters#python#flake8#Handle',
\                             buffer, lines)},
\})
