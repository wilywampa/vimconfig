import autopep8
import docformatter
import io
import os
import re
import subprocess
import textwrap
import tokenize
import vim
from getpass import getuser

try:
    unicode = unicode
except NameError:
    unicode = str


def get_ipython_file():
    proc = subprocess.Popen(['ps', '-u', getuser(), '-o', 'args'],
                            stdout=subprocess.PIPE)
    procs, err = proc.communicate()
    procs = procs.decode('utf-8')

    for proc in procs.splitlines():
        if '-console' in proc or 'ipykernel' in proc:
            for arg in proc.split():
                if re.match('^(.*/)?kernel-[0-9]+\.json$', arg):
                    if os.path.exists(arg):
                        vim.vars['ipython_connected'] = 1
                        vim.vars['deoplete#ipython_kernel'] = arg
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
        aggressive = int(vim.vars.get('pep8_aggressive', 1))
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
    end = start + vim.vvars['count']

    first_non_blank = int(vim.eval('nextnonblank(v:lnum)')) - 1
    last_non_blank = int(vim.eval('prevnonblank(v:lnum + v:count - 1)')) - 1

    doc_string = False
    if (first_non_blank >= 0 and
            doc_start.match(vim.current.buffer[first_non_blank]) and
            doc_end.match(vim.current.buffer[last_non_blank])):
        doc_string = True
    else:
        # Include trailing blanks at end of file
        if not ''.join(vim.current.buffer[end:]).strip():
            end = len(vim.current.buffer)
        else:
            # Otherwise, ignore trailing blanks
            while (0 < end < len(vim.current.buffer) and
                   not vim.current.buffer[end - 1].strip()):
                end -= 1

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
        line = lines[0] if lines else ''
        indent = line[:len(line) - len(line.lstrip())]
        options.max_line_length -= len(indent)
        text = textwrap.dedent('\n'.join(lines))
        fixed = autopep8.fix_lines(text.splitlines(), options)
        new_lines = textwrap.indent(fixed, indent)

    new_lines = new_lines.splitlines()
    if new_lines != lines:
        vim.current.buffer[start:end] = new_lines
