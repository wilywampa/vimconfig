import re
from .base import Base
from pathlib import Path


class Source(Base):

    def __init__(self, vim):
        super().__init__(vim)
        self.name = 'lines'
        self.mark = '[L]'
        self.rank = 1
        self.input_pattern = '.*'

    def gather_candidates(self, context):
        vim = self.vim
        candidates = []
        bufnums = set((vim.current.buffer.number,))
        inp = context['input'].strip()

        for win in vim.current.tabpage.windows:
            bufnums.add(win.buffer.number)

        bufnums.discard(vim.current.buffer.number)

        for n in [vim.current.buffer.number] + list(bufnums):
            buffer = vim.buffers[n]
            bufname = Path(buffer.name).name
            for line in (x.strip() for x in buffer):
                if line.startswith(inp) and line != inp:
                    candidates.append({'word': line, 'menu': bufname})

        return candidates

    def get_complete_position(self, context):
        if re.match(r'^\s*$', context['input']):
            return -1
        return re.search(r'\S', context['input']).start()
