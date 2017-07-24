# ============================================================================
# FILE: filter_modified.py
# AUTHOR: Jacob Niehus <jacob.niehus (at) gmail.com>
# License: MIT license
# ============================================================================

from .base import Base


class Filter(Base):

    def __init__(self, vim):
        super().__init__(vim)

        self.name = 'filter_modified'
        self.description = 'only match modified buffers'

    def filter(self, context):
        if '+' not in ''.join(context['args']):
            return context['candidates']
        return [candidate for candidate in context['candidates'] if
                self.vim.call('getbufvar',
                              candidate.get('action__bufnr', -1),
                              '&modified')]
