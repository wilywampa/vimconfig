from .base import Base


class Filter(Base):

    def __init__(self, vim):
        super().__init__(vim)

        self.name = 'sorter_mru'
        self.description = 'sort by buffer most recently used'

    def filter(self, context):
        buffer_list = self.vim.call(
            'unite#sources#buffer#variables#get_buffer_list')

        def key(candidate):
            bufnr = candidate['action__bufnr']
            if bufnr == context['bufnr']:
                return 0
            if str(bufnr) in buffer_list:
                return -buffer_list[str(bufnr)]['source__time']
            return -1

        return sorted(context['candidates'], key=key)
