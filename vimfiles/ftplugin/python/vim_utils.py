import autopep8
import docformatter
import io
import re
import subprocess
import tokenize
import vim
from getpass import getuser

try:
    unicode = unicode
except NameError:
    unicode = str


def get_ipython_file():
    if vim.eval('executable("procps")') == '1':
        args = ['procps', '--user', getuser(), '-o', 'args']
    elif vim.eval('has("win16") || has("win32") || '
                  'has("win64") || has("win32unix")') == '1':
        return ''
    else:
        args = ['ps', '-u', getuser(), '-o', 'args']

    try:
        procs = subprocess.getoutput(args)
    except AttributeError:
        procs = subprocess.check_output(args=args)

    for proc in procs.splitlines():
        if 'ipython-console' in proc or 'ipykernel' in proc:
            for arg in proc.split():
                if re.match('^(.*/)?kernel-[0-9]+\.json$', arg):
                    vim.command('let g:ipython_connected = 1')
                    return arg

    return ''


def get_docstrings(source):
    io_obj = io.StringIO(source)
    prev_toktype = tokenize.INDENT
    only_comments = True
    docstrings = []
    for tok in tokenize.generate_tokens(io_obj.readline):
        token_type = tok[0]
        start_line = tok[2][0]
        end_line = tok[3][0]
        if token_type == tokenize.STRING:
            if prev_toktype == tokenize.INDENT or only_comments:
                docstrings.append((start_line, end_line))

        if token_type not in [tokenize.COMMENT,
                              tokenize.NL,
                              tokenize.INDENT,
                              tokenize.STRING]:
            only_comments = False

        prev_toktype = token_type

    return docstrings


def find_docstring(line, next=True):
    docstrings = get_docstrings(u'\n'.join(
        b if isinstance(b, unicode) else
        unicode(b, vim.eval('&encoding') or 'utf-8')
        for b in vim.current.buffer))
    for d in docstrings:
        if line in range(d[0], d[1] + 1):
            return d

    if next:
        for d in docstrings:
            if d[0] > line:
                return d
    else:
        docstrings.reverse()
        for d in docstrings:
            if d[1] < line:
                return d

    try:
        return docstrings[-1]
    except IndexError:
        return None, None


def select_docstring():
    start, end = find_docstring(
        int(vim.eval('line(".")')),
        next=True if int(vim.eval('a:forward')) else False)
    if start is not None:
        vim.command('call cursor(%d, 0)' % start)
        vim.command('normal! V')
        vim.command('call cursor(%d, 0)' % end)


doc_start = re.compile('^\s*[ur]?("""|' + (3 * "'") + ').*')
doc_end = re.compile('.*("""|' + (3 * "'") + ')' + '\s*$')


def PEP8():

    class Options(object):
        aggressive = vim.vars.get('pep8_aggressive', 1)
        diff = False
        experimental = True
        ignore = vim.vars.get('pymode_lint_ignore', ())
        in_place = False
        indent_size = autopep8.DEFAULT_INDENT_SIZE
        line_range = None
        max_line_length = int(vim.vars.get('pep8_max_line_length', 78))
        pep8_passes = 100
        recursive = False
        select = vim.vars.get('pymode_lint_select', ())
        verbose = 0

    start = vim.vvars['lnum'] - 1
    end = vim.vvars['lnum'] + vim.vvars['count'] - 1

    first_non_blank = int(vim.eval('nextnonblank(v:lnum)')) - 1
    last_non_blank = int(vim.eval('prevnonblank(v:lnum + v:count - 1)')) - 1

    doc_string = False
    if (first_non_blank >= 0
            and doc_start.match(vim.current.buffer[first_non_blank])
            and doc_end.match(vim.current.buffer[last_non_blank])):
        doc_string = True
    else:
        # Don't remove trailing blank lines except at end of file
        while (end < len(vim.current.buffer)
               and re.match('^\s*$', vim.current.buffer[end - 1])):
            end += 1

    lines = vim.current.buffer[start:end]
    if not isinstance(lines[0], unicode):
        lines = [unicode(line, vim.eval('&encoding') or 'utf-8')
                 for line in lines]

    if doc_string:
        new_lines = docformatter.format_code(
            u'\n'.join(lines),
            force_wrap=bool(vim.vars.get('pep8_force_wrap', 0)),
            post_description_blank=False,
            pre_summary_newline=True)
    else:
        options = Options()
        if vim.vars['pep8_indent_only']:
            options.select = ['E1', 'W1']
        new_lines = autopep8.fix_lines(lines, options).lstrip()

    new_lines = new_lines.split('\n')[: None if doc_string else -1]

    if new_lines != lines:
        vim.current.buffer[start:end] = new_lines
