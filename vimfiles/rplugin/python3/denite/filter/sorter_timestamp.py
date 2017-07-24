import re
from .base import Base

term = re.compile('term://')


class Filter(Base):

    def __init__(self, vim):
        super().__init__(vim)

        self.name = 'sorter_timestamp'
        self.description = 'sort by buffer timestamp'

    def filter(self, context):

        def key(candidate):
            # Put current buffer last in list
            if context['bufnr'] == candidate.get('bufnr', -1):
                return 1
            # Put terminal buffers next-to-last in list
            elif term.search(candidate['word']):
                return 0
            return -candidate.get('timestamp', 0)

        return sorted(context['candidates'], key=key)
