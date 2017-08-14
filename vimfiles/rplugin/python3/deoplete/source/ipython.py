import ast
import re
from .base import Base
from deoplete_ipyclient import client

imports = re.compile(
    r'^\s*(from\s+\.*\w+(\.\w+)*\s+import\s+(\w+,\s+)*|import\s+)')
split_pattern = re.compile('[^= \r\n*()@-]')
keyword = re.compile('[A-Za-z0-9_]')

request = '''
try:
    _completions = completion_metadata(get_ipython())
except Exception:
    pass
'''


class Source(Base):

    def __init__(self, vim):
        super().__init__(vim)
        self.name = 'ipython'
        self.mark = '[IPy]'
        self.filetypes = ['python']
        self.is_volatile = True
        self.rank = 2000
        self.input_pattern = r'\w+(\.\w+)*'

    def get_complete_position(self, context):
        line = self.vim.current.line

        # return immediately for imports
        if imports.match(context['input']):
            start = len(context['input'])
            while start > 0 and re.match('[._A-Za-z0-9]', line[start - 1]):
                start -= 1
            return start

        # locate the start of the word
        col = self.vim.funcs.col('.')
        start = col - 1
        if start == 0 or (len(line) == start and
                          not split_pattern.match(line[start - 2]) and
                          not (start >= 2 and keyword.match(line[start - 3]))
                          and line[start - 3:start - 1] != '].'):
            start = -1
            return start

        line = self.vim.funcs.getline('.')
        start = self.vim.funcs.strchars(line[:col]) - 1
        bracket_level = 0
        while start > 0 and (
            split_pattern.match(line[start - 1])
                or (line[start - 1] == '.'
                    and start >= 2 and keyword.match(line[start - 2])
                    or (line[start - 1] == '-'
                        and start >= 2 and line[start - 2] == '[')
                    or ''.join(line[start - 2:start]) == '].')):
            if line[start - 1] == '[':
                if (start == 1 or not re.match(
                        '[A-Za-z0-9_\]]', line[start-2])) or bracket_level > 0:
                    break
                bracket_level += 1
            elif line[start-1] == ']':
                bracket_level -= 1
            start -= 1

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
        metadata = reply['content']['user_expressions']['_completions']
        return ast.literal_eval(metadata['data']['text/plain'])
