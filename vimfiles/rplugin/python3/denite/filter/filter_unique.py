# ============================================================================
# FILE: filter_unique.py
# AUTHOR: Jacob Niehus <jacob.niehus (at) gmail.com>
# License: MIT license
# ============================================================================

from .base import Base
import os


class Filter(Base):

    def __init__(self, vim):
        super().__init__(vim)

        self.name = 'filter_unique'
        self.description = 'only include each file at most once'

        class _dict(dict):
            def update(s, *args):
                dict.update(s, *args)
                self.seen = dict()

        self.vars = _dict()
        self.vars.update({})

    def filter(self, context):
        seen = self.seen
        result = []
        for candidate in context['candidates']:
            if 'action__path' in candidate:
                path = candidate['action__path']
            elif 'action__bufnr' in candidate:
                bufnr = candidate['action__bufnr']
                path = self.vim.eval('expand("#%d:p")' % bufnr)
            else:
                continue
            if os.path.isabs(path):
                path = os.path.realpath(path)
            else:
                path = os.path.realpath(os.path.join(context['path'], path))
            if path in seen:
                continue
            seen[path] = candidate
            result.append(candidate)
        return list(seen.values())
