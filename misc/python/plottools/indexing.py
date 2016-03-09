import copy
import numpy as np
import six
try:
    from bunch import Bunch
except ImportError:
    Bunch = None


class no_index(object):
    __repr__ = __str__ = lambda self: type(self).__name__
no_index = no_index()


def map_dict(func, mapping, copy=copy.copy, types=object, ignore=()):
    """Apply `func` recursively to all instances of `types` in `mapping`."""
    return _Visitor(func=func, copy=copy,
                    types=types, ignore=ignore).visit(mapping)


def index_all(mapping, ix=no_index, copy=copy.copy, types=np.ndarray,
              ignore=(), callback=None):
    """Index all ndarrays in a nested Mapping with the index object ix."""

    class Indexer(object):

        def __getitem__(self, index):
            return map_dict(
                lambda x, keys:
                    callback(x, index, keys) if callback else x[index],
                mapping, copy=copy, types=types, ignore=ignore)

    return Indexer() if ix is no_index else Indexer()[ix]


class ArrayBunch(Bunch):

    """Like Bunch but support indexing via index_all."""

    def __init__(self, *args, **kwargs):
        for attr, default in (('types', np.ndarray),
                              ('copy', copy.copy),
                              ('ignore', ()),
                              ('callback', None)):
            super(Bunch, self).__setattr__(
                '_' + attr, kwargs.pop(attr, default))
        super(ArrayBunch, self).__init__(*args, **kwargs)

    def __getitem__(self, key):
        if isinstance(key, six.string_types):
            return super(ArrayBunch, self).__getitem__(key)
        return index_all(self, copy=self._copy, ignore=self._ignore,
                         types=self._types, callback=self._callback)[key]


def array_bunchify(mapping, **kwargs):
    """Recursively transform mappings into ArrayBunch."""
    from collections import Mapping
    if isinstance(mapping, Mapping):
        return ArrayBunch(((k, array_bunchify(v, **kwargs))
                           for k, v in six.iteritems(mapping)), **kwargs)
    elif isinstance(mapping, (list, tuple)):
        return type(mapping)(array_bunchify(v, **kwargs) for v in mapping)
    else:
        return mapping


def azip(*iterables, **kwargs):
    """Move `axis` (default -1) to the front of ndarrays in `iterables`."""
    from six.moves import map as imap, zip as izip
    return izip(*(
        imap(kwargs.get('func', unmask),
             np.rollaxis(i, kwargs.get('axis', -1), kwargs.get('start', 0)))
        if isinstance(i, np.ndarray) else i for i in iterables))


def unmask(arr):
    """Return a view of the unmasked portion of an array."""
    import numpy.ma as ma
    if not isinstance(arr, ma.MaskedArray):
        return arr
    ix = np.argwhere(~np.all(arr.mask, axis=tuple(range(arr.ndim - 1))))
    if not ix.size:
        return arr[..., :0]
    return arr[..., ix[0]:ix[-1] + 1]


def product_items(params, names, enum=1, dtypes=None):
    """Make a masked record array representing variables in a Cartesian
    product."""
    import itertools as it
    from numpy.ma.mrecords import mrecarray
    items = list(it.product(*params))
    if enum is not None:
        items = [(i,) + item for i, item in enumerate(items, enum)]
        names = ('enum',) + names
        dtype = 'int32',
    else:
        dtype = ()
    if dtypes is None:
        dtypes = it.chain(dtype, it.repeat(float))
    elif not isinstance(dtypes, (list, tuple, np.ndarray)):
        dtypes = it.chain(dtype, it.repeat(dtypes))
    elif enum is not None:
        dtypes = dtype + dtypes
    return np.ma.array(
        items, dtype=[(name, dtype) for name, dtype in
                      zip(names, dtypes)]).view(mrecarray)


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
