# ============================================================================
# FILE: converter_tail.py
# AUTHOR: Jacob Niehus <jacob.niehus (at) gmail.com>
# License: MIT license
# ============================================================================

from .base import Base
import os


class Filter(Base):

    def __init__(self, vim):
        super().__init__(vim)

        self.name = 'converter_tail'
        self.description = 'convert candidate word to tail filename'

    def filter(self, context):
        for candidate in context['candidates']:
            candidate['word'] = os.path.basename(candidate['word'])
        return context['candidates']
