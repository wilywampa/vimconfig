import ast
import functools
import logging
import os
import re
from .base import Base
from deoplete_ipyclient import IPythonClient

logger = logging.getLogger(__name__)
if 'DEOPLETE_IPY_LOG' in os.environ:
    logfile = os.environ['DEOPLETE_IPY_LOG'].strip()
    handler = logging.FileHandler(logfile, 'w')
    handler.setFormatter(logging.Formatter('%(asctime)s: %(message)s'))
    logger.addHandler(handler)
    logger.setLevel(logging.DEBUG)

imports = re.compile(
    r'^\s*(from\s+\.*\w+(\.\w+)*\s+import\s+(\w+,\s+)*|import\s+)')
magic = re.compile(r'^(\s|#)*%%?([A-Za-z]\w*)?$')
split_pattern = re.compile(r'[^= \r\n*(@-]|(\)(?!\.))')
keyword = re.compile('[A-Za-z0-9_]')
opening = re.compile('^(.*\[)[A-Za-z_''".]')
splitchars = frozenset('= \r\n*()@-:')

request = '''
try:
    _completions = completion_metadata(get_ipython())
except Exception:
    pass
'''


def parses(code):
    try:
        ast.parse(code)
        return code
    except SyntaxError:
        pass

    while opening.match(code):
        prefix, _, code = code.partition('[')
        try:
            ast.parse(prefix)
            return prefix + '['
        except SyntaxError:
            continue
    return ''


def _log(f):
    @functools.wraps(f)
    def g(self, context):
        start = f(self, context)
        line = self.vim.current.line
        col = self.vim.funcs.col('.')
        logger.debug('start: %d', start)
        logger.debug('base: %r', line[start:col])
        return start
    return g


def _catch_exceptions(f):
    @functools.wraps(f)
    def g(*args, **kwargs):
        try:
            return f(*args, **kwargs)
        except Exception as e:
            logger.exception('Exception: %s', e)
            return []
    return g


class Source(Base):

    def __init__(self, vim):
        super().__init__(vim)
        self.name = 'ipython'
        self.mark = '[IPy]'
        self.filetypes = ['cython', 'python']
        self.is_volatile = True
        self.rank = 2000
        self.input_pattern = (
            r'[\w\)\]\}\'\"]+\.(\w*.*)?$|'
            r'^\s*@\w*$|'
            r'^\s*from\s+[\w\.]*(?:\s+import\s+(?:\w*(?:,\s*)?)*)?|'
            r'^\s*import\s+(?:[\w\.]*(?:,\s*)?)*')
        self._client = IPythonClient(vim)
        self._kernel_file = None

    @_log
    def get_complete_position(self, context):
        line = self.vim.current.line
        col = self.vim.funcs.col('.')
        logger.debug('line: %r', line[:col])

        # return immediately for imports
        if imports.match(context['input']):
            logger.debug('matches imports')
            start = len(context['input'])
            while start > 0 and re.match('[._A-Za-z0-9]',
                                         context['input'][start - 1]):
                start -= 1
            return start

        # return immediately for magics
        if magic.match(context['input']):
            return line.index('%')

        # locate the start of the word
        start = col - 1
        if start == 0 or (len(line) == start and
                          not split_pattern.match(line[start - 2]) and
                          not (start >= 3 and
                               keyword.match(line[start - 3])) and
                          line[start - 3:start - 1] != '].'):
            return -1

        start = self.vim.funcs.strchars(line[:col]) - 1
        # Check if the cursor is in an incomplete string
        for char in ("'", '"'):
            bracket = line[:start + 1].rfind('[' + char)
            # Make sure the quote next to the bracket is the last
            # quote before the cursor
            if bracket > 0 and bracket + 1 == line[:start + 1].rfind(char):
                logger.debug('starts with %r', char)
                start = bracket
                break
        else:
            if len(line) > start and line[start] in splitchars:
                return -1

        stack = []
        while start > 0:
            char = line[start - 1]
            logger.debug('start=%r char=%r stack=%r', start, char, stack)
            if stack and stack[-1] in ("'", '"') and char == stack[-1]:
                stack.pop()
            elif char in '''"'])}''':
                stack.append(char)
            elif char in '[({':
                if not stack or stack.pop() != '])}'['[({'.index(char)]:
                    break
            elif not stack and char in splitchars:
                break
            start -= 1

        base = line[start:col]
        if not base:
            return -1
        elif not stack and not line[col:] and base.endswith(' '):
            if not re.match(r'^\s*(?:from|import).*\s+$', line):
                return -1

        return start

    @_catch_exceptions
    def gather_candidates(self, context):
        # Check if connected or connect
        kernel_file = context['vars'].get(
            'deoplete#ipython_kernel', 'kernel-*.json')
        client = self._client
        if not client.has_connection or kernel_file != self._kernel_file:
            logger.debug('connecting')
            self._kernel_file = kernel_file
            client.connect(kernel_file)
        if not client.has_connection:
            logger.debug('no connection')
            return []

        # Handle special inputs (imports, magics)
        base = context['complete_str']
        line = context['input']
        pos = context['complete_position'] + len(base)
        logger.debug('completing %r at %d from %r', base, pos, line)
        match = re.match('^\s*(import|from\s*)', line)
        if match:
            line = line.lstrip()
            pos = len(line)
        else:
            match = imports.match(line)
            if match:
                module = match.string.strip().split()[1]
                line = 'from {module} import {base}'.format(
                    module=module, base=base)
                pos = len(line)
            else:
                line = line[pos - len(base):pos]
                pos = len(base)
        if not line:
            return []

        # Send the complete request
        logger.debug('sending code=%r cursor_pos=%d', line, pos)
        try:
            msg_id = client.kc.complete(code=line, cursor_pos=pos)
        except TypeError:
            msg_id = client.kc.complete(text=base, line=line, cursor_pos=pos)
        reply = client.waitfor(msg_id)
        if not reply or reply.get('msg_type', '') != 'complete_reply':
            logger.debug('bad complete response')
            return []

        # Send the completion metadata request
        reply = client.waitfor(client.kc.execute(
            request, silent=True,
            user_expressions={'_completions': '_completions'}))
        if not reply:
            logger.debug('bad metadata response')
            return []

        # Try to read the metadata
        try:
            metadata = reply['content']['user_expressions']['_completions']
            matches = ast.literal_eval(metadata['data']['text/plain'])
        except ValueError:
            # Check if max_seq_length was exceeded
            if metadata['data']['text/plain'].endswith('...]'):
                matches = ast.literal_eval(
                    metadata['data']['text/plain'][:-4] + ']')

        logger.debug('got %d completions', len(matches))
        for candidate in matches:
            try:
                if match:
                    candidate['word'] = candidate['word'].rstrip('(')
                candidate['word'] = candidate['word'].rstrip()
                if not candidate['word'].startswith(base):
                    candidate['word'] = base + candidate['word']
                    candidate['abbr'] = base + candidate['abbr']
            except KeyError:
                pass
        return matches
