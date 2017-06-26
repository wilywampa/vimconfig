import re
from .base import Base
from path import Path


class Source(Base):

    def __init__(self, vim):
        super().__init__(vim)
        self.name = 'words'
        self.mark = '[w]'
        self.rank = 5

    def gather_candidates(self, context):
        vim = self.vim
        words = set()
        bufnums = set((vim.current.buffer.number,))
        inp = context['input'].strip()

        for win in vim.current.tabpage.windows:
            bufnums.add(win.buffer.number)

        for n in bufnums:
            buffer = vim.buffers[n]
            bufname = Path(buffer.name).basename()
            words.update(re.findall(r'\w{4,}', ' '.join(buffer)))

        return [{'word': w, 'menu': bufname}
                for w in words if w.startswith(inp)]
