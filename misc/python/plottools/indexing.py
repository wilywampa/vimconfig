import copy
import numpy as np
import six
try:
    from bunch import Bunch
except ImportError:
    Bunch = None

no_index = object()


def map_dict(func, mapping, copy=copy.copy, types=object, ignore=()):
    """Apply `func` recursively to all instances of `types` in `mapping`."""
    return _Visitor(func=func, copy=copy,
                    types=types, ignore=ignore).visit(mapping)


def index_all(mapping, ix=no_index, types=np.ndarray, **kwargs):
    """Index all ndarrays in a nested Mapping with the index object ix."""

    class Indexer(object):

        def __getitem__(self, index):
            return map_dict(lambda x: x[index], mapping, types=types, **kwargs)

    return Indexer() if ix is no_index else Indexer()[ix]


class ArrayBunch(Bunch):

    """Like Bunch but support indexing via index_all."""

    def __getitem__(self, key):
        if isinstance(key, six.string_types):
            return super(ArrayBunch, self).__getitem__(key)
        return index_all(self)[key]


def array_bunchify(mapping):
    """Recursively transform mappings into ArrayBunch."""
    from collections import Mapping
    if isinstance(mapping, Mapping):
        return ArrayBunch((k, array_bunchify(v))
                          for k, v in six.iteritems(mapping))
    elif isinstance(mapping, (list, tuple)):
        return type(mapping)(array_bunchify(v) for v in mapping)
    else:
        return mapping


class _Visitor(object):

    def __init__(self, **kwargs):
        self.__dict__.update(kwargs)
        self.visited = {}
        self.keep_alive = self.visited[id(self.visited)] = []

    def visit(self, mapping, keys=()):
        import copy
        from collections import Mapping
        if id(mapping) in self.visited:
            return self.visited[id(mapping)]

        if self.copy is not None:
            try:
                mapping = self.copy(mapping)
            except TypeError:
                if self.copy:
                    mapping = copy.deepcopy(mapping)
                else:
                    mapping = copy.copy(mapping)

        for k, v in mapping.items():
            if isinstance(v, self.types):
                if id(v) in self.visited:
                    mapping[k] = self.visited[id(v)]
                else:
                    mapping[k] = self.apply(v, keys + (k,))
            elif isinstance(v, Mapping):
                mapping[k] = self.visit(v, keys=keys + (k,))
            self.visited[id(v)] = mapping[k]
            self.keep_alive.append(v)

        return mapping

    def apply(self, v, keys):
        try:
            return self.func(v, keys=keys)
        except TypeError:
            try:
                return self.func(v)
            except Exception as e:
                if not isinstance(e, self.ignore):
                    raise
        return v
