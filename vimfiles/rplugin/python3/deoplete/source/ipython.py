import ast
import functools
import logging
import os
import re
from .base import Base
from deoplete_ipyclient import client

logger = logging.getLogger(__name__)
if 'DEOPLETE_IPY_LOG' in os.environ:
    logfile = os.environ['DEOPLETE_IPY_LOG'].strip()
    logger.addHandler(logging.FileHandler(logfile, 'w'))
    logger.level = logging.DEBUG

imports = re.compile(
    r'^\s*(from\s+\.*\w+(\.\w+)*\s+import\s+(\w+,\s+)*|import\s+)')
split_pattern = re.compile(r'[^= \r\n*()@-]')
keyword = re.compile('[A-Za-z0-9_]')
opening = re.compile('^(.*\[)[A-Za-z_''".]')

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


def log(f):
    @functools.wraps(f)
    def g(self, context):
        start = f(self, context)
        line = self.vim.current.line
        col = self.vim.funcs.col('.')
        logger.debug('start: %d', start)
        logger.debug('base: %s', line[start:col])
        return start
    return g


class Source(Base):

    def __init__(self, vim):
        super().__init__(vim)
        self.name = 'ipython'
        self.mark = '[IPy]'
        self.filetypes = ['python']
        self.is_volatile = True
        self.rank = 2000
        self.input_pattern = r'\w+(\.\w+)*'

    @log
    def get_complete_position(self, context):
        line = self.vim.current.line
        col = self.vim.funcs.col('.')
        logger.debug('line: %s', line[:col])

        # return immediately for imports
        if imports.match(context['input']):
            start = len(context['input'])
            while start > 0 and re.match('[._A-Za-z0-9]',
                                         context['input'][start - 1]):
                start -= 1
            return start

        # locate the start of the word
        start = col - 1
        if start == 0 or (len(line) == start and
                          not split_pattern.match(line[start - 2]) and
                          not (start >= 2 and
                               keyword.match(line[start - 3])) and
                          line[start - 3:start - 1] != '].'):
            start = -1
            return start

        start = self.vim.funcs.strchars(line[:col]) - 1
        bracket_level = 0
        while start > 0 and (
            split_pattern.match(line[start - 1]) or
            ((line[start - 1] == '.' and
              start >= 2 and keyword.match(line[start - 2])) or
             (line[start - 1] in '-[' and
              start >= 2 and line[start - 2] == '[') or
             ''.join(line[start - 2:start]) == '].')):
            if line[start - 1] == '[':
                if (start == 1 or not re.match(
                        '[A-Za-z0-9_[\]]', line[start - 2])):
                    break
                bracket_level += 1
            elif line[start - 1] == ']':
                bracket_level -= 1
            start -= 1

        logger.debug('bracket level: %d', bracket_level)
        while bracket_level > 0 and opening.match(line[start:col]):
            prefix = parses(line[start:col])
            if prefix:
                logger.debug('removing %s at %d', prefix, start)
                start += len(prefix)
                bracket_level -= 1
            else:
                break

        logger.debug('bracket level: %d', bracket_level)
        return start

    def gather_candidates(self, context):
        if not client.has_connection:
            return []
        client.waitfor(client.kc.complete(
            context['input'] if imports.match(context['input'])
            else context['complete_str']))
        reply = client.waitfor(client.kc.execute(
            request, silent=True,
            user_expressions={'_completions': '_completions'}))
        try:
            metadata = reply['content']['user_expressions']['_completions']
            return ast.literal_eval(metadata['data']['text/plain'])
        except KeyError:
            return []
