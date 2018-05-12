import re
from .base import Base
from itertools import chain
from pathlib import Path


def getbuflines(vim, buf=1, start=1, end='$'):
    if end == '$':
        end = len(vim.current.buffer)
    max_len = min([end - start, 5000])
    current = start
    while current <= end:
        yield from enumerate(vim.call(
            'getbufline', buf, current, current + max_len), current)
        current += max_len + 1


class Source(Base):

    def __init__(self, vim):
        super().__init__(vim)
        self.name = 'lines'
        self.mark = '[L]'
        self.rank = 1
        self.input_pattern = r'\S+'

    def gather_candidates(self, context):
        vim = self.vim
        candidates = []
        bufnr = vim.current.buffer.number
        pos = vim.current.buffer.mark('.')
        inp = context['input'].strip()
        curline = vim.current.line.strip()

        bufnums = set(win.buffer.number
                      for win in vim.current.tabpage.windows
                      if vim.call('buflisted', win.buffer.number))

        for n in chain([bufnr], bufnums.difference({bufnr})):
            buffer = vim.buffers[n]
            bufname = Path(buffer.name).name
            for linenr, line in getbuflines(vim, n):
                if n == bufnr and linenr == pos[0]:
                    continue
                line = line.strip()
                if line.startswith(inp) and line != curline:
                    candidates.append({'word': line, 'menu': bufname})

        return candidates

    def get_complete_position(self, context):
        if re.match(r'^\s*$', context['input']):
            return -1
        return re.search(r'\S', context['input']).start()
