import collections
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


def hashable(obj):
    """Check if an object is hashable (can be a dict key)."""
    try:
        obj in {}
    except TypeError:
        return False
    return True


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
        if isinstance(key, six.string_types) or hashable(key) and key in self:
            return super(ArrayBunch, self).__getitem__(key)
        return index_all(self, copy=self._copy, ignore=self._ignore,
                         types=self._types, callback=self._callback)[key]


class DefaultBunch(Bunch, collections.defaultdict):

    """A defaultdict which behaves like a Bunch."""


def BunchBunch():
    """A recursive DefaultBunch."""
    return DefaultBunch(BunchBunch)


def array_bunchify(mapping, **kwargs):
    """Recursively transform mappings into ArrayBunch."""
    from collections import Mapping
    if isinstance(mapping, Mapping):
        return ArrayBunch(((k, array_bunchify(v, **kwargs))
                           for k, v in six.iteritems(mapping)), **kwargs)
    elif isinstance(mapping, (list, tuple)):
        return type(mapping)(array_bunchify(v, **kwargs) for v in mapping)
    elif hasattr(mapping, '_fieldnames'):
        return ArrayBunch(((k, array_bunchify(getattr(mapping, k), **kwargs))
                           for k in mapping._fieldnames), **kwargs)
    else:
        return mapping


def azip(*iterables, **kwargs):
    """Move `axis` (default -1) to the front of ndarrays in `iterables`."""
    from six.moves import map as imap, zip as izip
    return izip(*(
        imap(kwargs.get('func', unmask),
             np.rollaxis(i, kwargs.get('axis', -1), kwargs.get('start', 0)))
        if isinstance(i, np.ndarray) else i for i in iterables))


def shift(arr, to_front=False, out=None, copy_dict=True):
    """Shift array padding to the front or back of the array."""

    if isinstance(arr, dict):
        return map_dict(lambda x: shift(x, to_front=to_front),
                        arr, copy=copy_dict, types=np.ndarray)

    import numpy.ma as ma
    empty, masked = np.empty, np.nan
    if isinstance(arr, ma.MaskedArray):
        empty, masked = ma.empty, ma.masked
    new = empty(arr.shape) if out is None else out
    for i, (a,) in enumerate(azip(arr)):
        new[..., i] = masked
        if to_front:
            new[..., :a.shape[-1], i] = a
        else:
            new[..., arr.shape[-2] - a.shape[-1]:, i] = a
    return new


def unmask(arr, unnan=True, axis=-1):
    """Return a view of the unmasked portion of an array."""
    import numpy.ma as ma
    if not isinstance(arr, np.ndarray):
        return arr
    if axis < 0:
        axis += arr.ndim
    axes = tuple(x for x in range(arr.ndim) if x != axis)
    if isinstance(arr, ma.MaskedArray) and arr.mask.any():
        ix = np.where(~np.all(arr.mask, axis=axes))[0]
    elif unnan:
        ix = np.where(~np.all(np.isnan(arr), axis=axes))[0]
    else:
        return arr
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


def where_first(cond, *out, **kwargs):
    """Return values from `out` where `cond` is first true along axis 0."""
    import numpy.ma as ma
    last = kwargs.pop('last', False)
    cond = np.atleast_1d(cond)
    if last:
        ix = cond.shape[0] - ma.argmax(cond[::-1], axis=0) - 1
        mask = Ellipsis, (ix + 1 == cond.shape[0]) & ~cond[-1]
    else:
        ix = ma.argmax(cond, axis=0)
        mask = Ellipsis, (ix == 0) & ~cond[0]
    ix = (Ellipsis, ix) + tuple(np.indices(cond.shape[1:]))
    if not out:
        return ix, mask
    out = [ma.masked_array(np.atleast_1d(a)[ix], **kwargs) for a in out]
    if mask[-1].any():
        for o in out:
            o[mask] = ma.masked
    return out[0] if len(out) == 1 else out


def where_last(cond, *out, **kwargs):
    """Return values from `out` where `cond` is last true along axis 0."""
    kwargs['last'] = True
    return where_first(cond, *out, **kwargs)
