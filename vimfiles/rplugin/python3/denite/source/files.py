# ============================================================================
# FILE: file.py
# AUTHOR: Shougo Matsushita <Shougo.Matsu at gmail.com>
# License: MIT license
# ============================================================================

from .base import Base
import glob
import os
from denite.util import abspath


class Source(Base):

    def __init__(self, vim):
        super().__init__(vim)

        self.name = 'files'
        self.kind = 'file'
        self.matchers = ['matcher_regexp', 'matcher_ignore_globs']

    def gather_candidates(self, context):
        context['is_interactive'] = True
        candidates = []

        path = context['args'][0] if context['args'] else context['path']
        inputs = context['input'].split()
        narrowing = False
        if inputs and os.path.isabs(inputs[0]):
            path = inputs[0]
            narrowing = True

        for f in (glob.glob(os.path.join(path, '*')) +
                  glob.glob(os.path.join(path, '.*'))):
            candidates.append({
                'word': f if narrowing else os.path.basename(f),
                'abbr': f + (os.path.sep if os.path.isdir(f) else ''),
                'kind': 'directory' if os.path.isdir(f) else 'file',
                'action__path': abspath(self.vim, f),
            })
        return candidates
