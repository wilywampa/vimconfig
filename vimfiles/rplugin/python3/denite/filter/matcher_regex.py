# ============================================================================
# FILE: matcher_regex.py
# AUTHOR: Jacob Niehus <jacob.niehus (at) gmail.com>
# License: MIT license
# ============================================================================

import re
from .base import Base


class Filter(Base):

    def __init__(self, vim):
        super().__init__(vim)

        self.name = 'matcher_regex'
        self.description = 'regex matcher'

    def filter(self, context):
        if context['input'] == '':
            return context['candidates']
        positive = []
        negative = []
        for x in context['input'].strip().split():
            try:
                p = re.compile(x[1:] if x.startswith('!') else x,
                               flags=re.IGNORECASE
                               if context['ignorecase'] else 0)
            except Exception:
                pass
            else:
                if x.startswith('!'):
                    negative.append(p)
                else:
                    positive.append(p)
        if not (positive or negative):
            return context['candidates']

        result = []
        for c in context['candidates']:
            self.debug(c['word'])
            failed = False
            for p in positive:
                if p.search(c['word']):
                    pass
                else:
                    self.debug('failed')
                    failed = True
                if failed:
                    break
            if failed:
                continue
            for p in negative:
                if p.search(c['word']):
                    self.debug('failed')
                    failed = True
                if failed:
                    break
            if not failed:
                result.append(c)

        return result
