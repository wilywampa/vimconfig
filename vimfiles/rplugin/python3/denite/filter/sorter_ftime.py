import os
from .base import Base


class Filter(Base):

    def __init__(self, vim):
        super().__init__(vim)

        self.name = 'sorter_ftime'
        self.description = 'sort by file modification time'

    def filter(self, context):
        return sorted(context['candidates'], key=key)


def key(candidate):
    try:
        return -os.path.getmtime(candidate['action__path'])
    except Exception:
        return 1
