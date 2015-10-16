from __future__ import division, print_function
import matplotlib.pyplot as _plt
from plotinteract import create, merge_dicts  # noqa


def fg(fig=None):
    """Raise figure to foreground."""
    _plt.figure((fig or _plt.gcf()).number)
    if _plt.get_backend()[0:2].lower() == 'qt':
        _plt.get_current_fig_manager().window.activateWindow()
        _plt.get_current_fig_manager().window.raise_()
    elif _plt.get_backend()[0:2].lower() == 'wx':
        _plt.get_current_fig_manager().window.Raise()


def _snap(**kwargs):
    import numpy as np
    event = kwargs['event']
    try:
        xdata, ydata = event.artist.get_xdata(), event.artist.get_ydata()
    except AttributeError:
        return kwargs
    ind = event.ind[0]
    xclick, yclick = event.mouseevent.xdata, event.mouseevent.ydata

    if ind + 1 >= len(xdata) or None in [xclick, yclick]:
        return kwargs

    x0, y0 = xdata[ind], ydata[ind]
    x1, y1 = xdata[ind + 1], ydata[ind + 1]
    to_next_point = np.linalg.norm([x1 - x0, y1 - y0])
    to_click = np.linalg.norm([xclick - x0, yclick - y0])

    kwargs['x'], kwargs['y'], event.ind[0] = np.array(
        [x0, y0, ind] if to_click < to_next_point / 2 else [x1, y1, ind + 1])
    event.ind = [event.ind[0]]
    return kwargs


def _fmt(x=None, y=None, label=None, **kwargs):
    event = kwargs['event']
    output = [label] if label and not label.startswith('_') else []
    output.append("{x:.6g}\n{y:.6g}\n{i}".format(x=x, y=y, i=event.ind))
    kwargs['arrowprops'] = dict(shrinkB=0)
    return "\n".join(output)


def cursor(fig=None, **kwargs):
    """Add mpldatacursor to a figure."""
    from mpldatacursor import datacursor
    _plt.figure((fig or _plt.gcf()).number)
    cursors = []
    for ax in _plt.gcf().get_axes():
        cursors.append(datacursor(axes=ax, formatter=_fmt,
                                  props_override=_snap, **kwargs))
        [a.draggable() for a in cursors[-1].annotations.values()]
    return cursors


def picker(fig=None, **kwargs):
    """Add mplpicker to a figure."""
    from mplpicker import picker
    _plt.figure((fig or _plt.gcf()).number)
    return [picker(ax, **kwargs) for ax in _plt.gcf().get_axes()]


def unique_legend(**kwargs):
    """Add a legend with each label used only once."""
    hs, ls = _plt.gca().get_legend_handles_labels()
    handles, labels = [], []
    for h, l in zip(hs, ls):
        if l not in labels:
            handles.append(h)
            labels.append(l)
    return _plt.legend(handles, labels, **kwargs)


def fig(num=1):
    """Raise a figure to foreground by number with 1 as default."""
    fg(_plt.figure(num))


def figdo(*args):
    """Apply functions to all open figures."""
    [func(_plt.figure(n)) for n in _plt.get_fignums() for func in args]


def resize(width, height):
    """Resize the active figure window."""
    _plt.get_current_fig_manager().resize(width, height)


def cl():
    """Close all figures."""
    _plt.close('all')


def savepdf(filename, **kwargs):
    """Save all open figures to a PDF file."""
    from matplotlib.backends.backend_pdf import PdfPages
    with PdfPages(filename) as pp:
        [pp.savefig(_plt.figure(n), **kwargs) for n in _plt.get_fignums()]


def savesvg(basename, **kwargs):
    """Save all open figures to SVG files."""
    figs = [_plt.figure(n) for n in _plt.get_fignums()]
    for f in figs:
        f.savefig(basename + str(f.number) + '.svg', format='svg', **kwargs)


def savehtml(file_or_name, html_attrs=None, **kwargs):
    """Save all open figures to an HTML file."""
    import base64
    from io import BytesIO

    def save(fid):
        for n in _plt.get_fignums():
            with BytesIO() as b:
                _plt.figure(n).savefig(b, format='png', **kwargs)
                b.seek(0)
                value = b.getvalue()
            fid.write('<img src="data:image/png;base64,{0}"{1}><br>\n'.format(
                base64.b64encode(value),
                (' ' + ' '.join('{0}="{1}"'.format(a, html_attrs[a])
                                for a in html_attrs)) if html_attrs else '',
            ))

    if hasattr(file_or_name, 'write'):
        save(file_or_name)
    else:
        if not file_or_name.endswith('.html'):
            file_or_name += '.html'
        with open(file_or_name, 'w') as fid:
            save(fid)


def varinfo(var):
    """Pretty print information about a variable."""
    from pprint import pprint
    import numpy
    print(type(var))
    pprint(var)
    if isinstance(var, numpy.ndarray):
        print(var.shape)


def pad(array, length, filler=float('nan')):
    """Extend a 1D array to `length` by appending `filler` values."""
    import numpy
    if not isinstance(array, numpy.ndarray):
        return array
    return numpy.pad(array, ((0, length - array.shape[0]),) * array.ndim,
                     mode='constant', constant_values=(filler,))


def index_all(mapping, ix, copy=False):
    """Index all ndarrays in a nested Mapping with the slice object ix."""
    from collections import Mapping
    from copy import deepcopy
    from numpy import ndarray
    if copy:
        mapping = deepcopy(mapping)
    for key, value in mapping.items():
        if isinstance(value, ndarray):
            mapping[key] = value[ix]
        elif isinstance(value, Mapping):
            index_all(value, ix)
    return mapping


def azip(*iterables, **kwargs):
    """Move `axis` (default -1) to the front of ndarrays in `iterables`."""
    import numpy as np
    from six.moves import map as imap, zip as izip
    return izip(*(
        imap(kwargs.get('func', lambda x: x),
             np.rollaxis(i, kwargs.get('axis', -1), kwargs.get('start', 0)))
        if isinstance(i, np.ndarray) else i for i in iterables))


def unmask(arr):
    """Return a view of the unmasked portion of an array."""
    import numpy as np
    import numpy.ma as ma
    if not isinstance(arr, ma.MaskedArray):
        return arr
    ix = np.argwhere(~np.all(arr.mask, axis=tuple(range(arr.ndim - 1))))
    if not ix.size:
        return arr[..., :0]
    return arr[..., ix[0]:ix[-1] + 1]


def styles(order=('-', '--', '-.', ':')):
    """Generate a cycle of line styles to pair with `axes.color_cycle`."""
    from itertools import cycle
    from matplotlib import rcParams
    from numpy import repeat
    return cycle(repeat(order, len(rcParams['axes.color_cycle'])))


class _dict2obj(dict):

    """Add attribute-style access to a dictionary."""

    def __init__(self, d=None, **kwargs):
        if d is None:
            d = {}
        if kwargs:
            d.update(**kwargs)
        for key, val in d.items():
            setattr(self, key, val)
        for key in self.__class__.__dict__.keys():
            if not (key.startswith('__') and key.endswith('__')):
                setattr(self, key, getattr(self, key))

    def __setattr__(self, name, value):
        if isinstance(value, (list, tuple)):
            value = [self.__class__(x)
                     if isinstance(x, dict) else x for x in value]
        else:
            if isinstance(value, dict):
                value = self.__class__(value)
        super(dict2obj, self).__setattr__(name, value)
        self[name] = value


try:
    from bunch import bunchify as dict2obj
except ImportError:
    try:
        from attrdict import AttrDict as dict2obj
    except ImportError:
        dict2obj = _dict2obj
