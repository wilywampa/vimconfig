from __future__ import division, print_function
import matplotlib.pyplot as plt
import numpy as np
from plotinteract import create, dataobj, merge_dicts
from plottools.angle2dcm import angle2dcm
from plottools.dcm2angle import dcm2angle
from plottools.indexing import ArrayBunch, array_bunchify, index_all, map_dict


def fg(fig=None):
    """Raise figure to foreground."""
    plt.figure((fig or plt.gcf()).number)
    if plt.get_backend()[0:2].lower() == 'qt':
        plt.get_current_fig_manager().window.activateWindow()
        plt.get_current_fig_manager().window.raise_()
    elif plt.get_backend()[0:2].lower() == 'wx':
        plt.get_current_fig_manager().window.Raise()


def _snap(**kwargs):
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
    plt.figure((fig or plt.gcf()).number)
    kw = dict(formatter=_fmt, props_override=_snap)
    kw.update(kwargs)
    cursors = []
    axes = kwargs.get('axes', plt.gcf().get_axes())
    for ax in axes:
        cursors.append(datacursor(axes=ax, **kw))
        [a.draggable() for a in cursors[-1].annotations.values()]
    return cursors


def picker(fig=None, **kwargs):
    """Add mplpicker to a figure."""
    from mplpicker import picker
    plt.figure((fig or plt.gcf()).number)
    return [picker(ax, **kwargs) for ax in plt.gcf().get_axes()]


def unique_legend(*axes, **kwargs):
    """Add a legend with each label used only once."""
    from collections import OrderedDict
    from itertools import chain
    if not axes:
        axes = plt.gcf().get_axes()
    items = OrderedDict(
        (label, handle) for handle, label in chain.from_iterable(
            zip(*ax.get_legend_handles_labels()) for ax in axes))
    return plt.legend(items.values(), items.keys(), **kwargs)


def fig(num=1):
    """Raise a figure to foreground by number with 1 as default."""
    fg(plt.figure(num))


def figdo(*args):
    """Apply functions to all open figures."""
    [func(plt.figure(n)) for n in plt.get_fignums() for func in args]


def resize(width, height):
    """Resize the active figure window."""
    plt.get_current_fig_manager().resize(width, height)


def cl():
    """Close all figures."""
    plt.close('all')


def savepdf(filename, **kwargs):
    """Save all open figures to a PDF file."""
    from matplotlib.backends.backend_pdf import PdfPages
    with PdfPages(filename) as pp:
        [pp.savefig(plt.figure(n), **kwargs) for n in plt.get_fignums()]


def savesvg(basename, **kwargs):
    """Save all open figures to SVG files."""
    figs = [plt.figure(n) for n in plt.get_fignums()]
    for f in figs:
        f.savefig(basename + str(f.number) + '.svg', format='svg', **kwargs)


def savehtml(file_or_name, html_attrs=None, header=None, footer=None,
             template=None, **kwargs):
    """Save all open figures to an HTML file."""
    import base64
    from io import BytesIO
    from textwrap import dedent

    template = template or dedent("""\
    <center><img src="data:image/png;base64,{img}"{attrs}><br></center>
    """)
    attrs = (' ' + ' '.join('{0}="{1}"'.format(a, html_attrs[a])
                            for a in html_attrs)) if html_attrs else ''

    def save(fid):
        if header:
            fid.write(header)
        for n in plt.get_fignums():
            with BytesIO() as b:
                plt.figure(n).savefig(b, format='png', **kwargs)
                b.seek(0)
                value = b.getvalue()
            fid.write(template.format(
                img=base64.b64encode(value).decode('ascii'), attrs=attrs))
        if footer:
            fid.write(footer)

    if hasattr(file_or_name, 'write'):
        save(file_or_name)
    else:
        if not file_or_name.endswith('.html'):
            file_or_name += '.html'
        with open(file_or_name, 'w') as fid:
            save(fid)


def varinfo(var):
    """Pretty print information about a variable."""
    import numpy
    from IPython.lib.pretty import pretty
    from highlighter import highlight
    try:
        s = pretty(var, max_seq_length=20)
    except TypeError:
        s = pretty(var)
    lines = s.splitlines()
    if len(lines) > 20:
        s = '\n'.join(lines[:10] + ['...'] + lines[-10:])
    print(highlight(s).strip())
    print(type(var))
    if isinstance(var, numpy.ndarray):
        print(var.shape)
    elif isinstance(var, (dict, list, tuple, set)):
        print('n = %d' % len(var))


def pad(array, length, filler=float('nan')):
    """Extend a 1D array to `length` by appending `filler` values."""
    import numpy
    if not isinstance(array, numpy.ndarray):
        return array
    return numpy.pad(array, ((0, length - array.shape[0]),) * array.ndim,
                     mode='constant', constant_values=(filler,))


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


def styles(order=('-', '--', '-.', ':')):
    """Generate a cycle of line styles to pair with `axes.color_cycle`."""
    from itertools import cycle
    from matplotlib import rcParams
    from numpy import repeat
    return cycle(repeat(order, len(rcParams['axes.color_cycle'])))


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


def fix_angles(angles, pi=np.pi, axis=0):
    """Limit angle changes to within +/- pi to remove discontinuities."""
    start = np.take(angles, [0], axis=axis)
    delta = np.unwrap(np.diff(angles, axis=axis), discont=pi, axis=axis)
    return start + np.concatenate((np.zeros(start.shape),
                                   np.cumsum(delta, axis=axis)))


def axis_equal_3d(axes=None):
    """Adjust axis limits for equal scaling in Axes3D instance `ax`."""
    if axes is None:
        axes = plt.gca()
    for ax in np.atleast_1d(axes).ravel():
        radius = max(np.abs(lim - lim.mean()).max()
                     for lim in (getattr(ax, 'get_%slim3d' % axis)()
                                 for axis in 'xyz'))
        for axis in 'xyz':
            getattr(ax, 'set_%slim3d' % axis)(
                np.array([-radius, radius]) +
                getattr(ax, 'get_%slim3d' % axis)().mean())


class Conversion(float):

    """Callable unit conversion."""

    def __call__(self, other, **kwargs):
        if callable(other):
            return self.func(other, **kwargs)
        elif kwargs:
            raise TypeError("Unexpected keyword arguments")
        if isinstance(other, (list, tuple)):
            return type(other)(self * v for v in other)
        return self * other

    def func(self, f, **kwargs):
        """Modify the units of a function's inputs and/or outputs."""
        input = kwargs.get('input',
                           False if kwargs.get('output', None) else True)
        output = kwargs.get('output', False if input else True)
        if input in (True, False):
            input = Ellipsis if input else ()
        if output in (True, False):
            output = Ellipsis if output else ()

        def g(*args, **kwargs):
            dtype = None if np.issubdtype(
                np.asanyarray(args[0]).dtype, float) else np.float64
            args = np.asanyarray(args, dtype=dtype)
            if input:
                args[input] /= self
            result = np.asanyarray(f(*args.tolist(), **kwargs))
            if output:
                try:
                    result[output] *= self
                except IndexError:
                    result *= self
            return result

        return g


r2d = Conversion(np.rad2deg(1.0))
d2r = Conversion(np.deg2rad(1.0))


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

__all__ = [
    'ArrayBunch',
    'Conversion',
    'angle2dcm',
    'array_bunchify',
    'axis_equal_3d',
    'azip',
    'cl',
    'create',
    'cursor',
    'd2r',
    'dataobj',
    'dcm2angle',
    'dict2obj',
    'fg',
    'fig',
    'figdo',
    'fix_angles',
    'index_all',
    'map_dict',
    'merge_dicts',
    'pad',
    'picker',
    'product_items',
    'r2d',
    'resize',
    'savehtml',
    'savepdf',
    'savesvg',
    'styles',
    'unique_legend',
    'unmask',
    'varinfo',
]
