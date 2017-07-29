from __future__ import division, print_function
import matplotlib as mpl
import matplotlib.pyplot as plt
import numpy as np
from plotinteract import create, dataobj, flatten, merge_dicts
from plottools.angle2dcm import angle2dcm
from plottools.dcm2angle import dcm2angle
from plottools.indexing import (ArrayBunch, array_bunchify, azip,
                                DefaultBunch, BunchBunch,
                                index_all, map_dict, product_items,
                                shift, unmask, where_first, where_last)


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


def cursor(artists=None, axes=None, **kwargs):
    """Add mpldatacursor to the current artists."""
    import mpldatacursor
    defaults = dict(formatter=_fmt, props_override=_snap, draggable=True)
    defaults.update(kwargs)
    return mpldatacursor.datacursor(artists=artists, axes=axes, **defaults)


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
    return [func(plt.figure(n)) for n in plt.get_fignums() for func in args]


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
    attrs = (' ' + ' '.join('{}="{}"'.format(a, html_attrs[a])
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
        print(var.shape, var.dtype)
        print('min = {} max = {}'.format(
            numpy.nanmin(var), numpy.nanmax(var)))
        print('mean = {} std = {}'.format(
            numpy.nanmean(var), numpy.nanstd(var)))
    elif isinstance(var, (dict, list, tuple, set)):
        print('n = %d' % len(var))


def pad(array, length, filler=float('nan')):
    """Extend a 1D array to `length` by appending `filler` values."""
    import numpy
    if not isinstance(array, numpy.ndarray):
        return array
    return numpy.pad(array, ((0, length - array.shape[0]),) * array.ndim,
                     mode='constant', constant_values=(filler,))


def styles(order=('-', '--', '-.', ':')):
    """Generate a cycle of line styles to pair with `axes.color_cycle`."""
    from itertools import cycle
    from matplotlib import rcParams
    from numpy import repeat
    try:
        color_cycle = rcParams['axes.prop_cycle'].by_key()['color']
    except (AttributeError, KeyError):
        color_cycle = rcParams['axes.color_cycle']
    return cycle(repeat(order, len(color_cycle)))


def fix_angles(angles, pi=np.pi, axis=0):
    """Limit angle changes to within +/- pi to remove discontinuities."""
    start = np.take(angles, [0], axis=axis)
    delta = np.unwrap(np.diff(
        angles * np.pi / pi, axis=axis), axis=axis) * pi / np.pi
    return start + np.concatenate((np.zeros(start.shape),
                                   np.cumsum(delta, axis=axis)))


def angle_difference(a, b, pi=np.pi):
    """Find the unwrapped difference in angle between `a` and `b`."""
    diff = np.subtract(a, b)
    div = np.floor_divide(pi + np.abs(diff), 2 * pi) * 2 * pi
    diff[diff > pi] -= div[diff > pi]
    diff[diff < -pi] += div[diff < -pi]
    return diff


def axis_equal_3d(axes=None, xlim=None, ylim=None, zlim=None):
    """Adjust axis limits for equal scaling in Axes3D instance `ax`."""
    if axes is None:
        axes = plt.gca()
    radii = []
    for ax in np.atleast_1d(axes).ravel():
        ax.set_aspect('equal')
        radii.append(max(np.abs(lim - lim.mean()).max()
                         for lim in (getattr(ax, 'get_%slim3d' % axis)()
                                     for axis in 'xyz')))
        for axis, lim in zip('xyz', (xlim, ylim, zlim)):
            if lim is None:
                lim = getattr(ax, 'get_%slim3d' % axis)()
            getattr(ax, 'set_%slim3d' % axis)(
                np.array([-radii[-1], radii[-1]]) + np.mean(lim))
    return radii


def cdfplot(x, *args, **kwargs):
    """Plot the empirical cumulative distribution function of `x`."""
    kwargs.setdefault('drawstyle', 'steps')
    return_data = kwargs.pop('return_data', False)
    ax = kwargs.pop('ax', None)
    x = np.sort(np.atleast_2d(np.squeeze(x)).T, axis=0)
    X = np.append(x, x[-1:], axis=0)
    Y = np.repeat(np.linspace(
        0.0, 1.0, x.shape[0] + 1), x.shape[1]).reshape(X.shape)
    artists = getattr(ax, 'plot', plt.plot)(X, Y, *args, **kwargs)
    if return_data:
        return artists, X, Y
    return artists


def colored_line(x, y, c, norm=None, ax=None, **kwargs):
    """Create a LineCollection with segments of `x` and `y` colored by `c`."""
    x = np.squeeze(x)
    y = np.squeeze(y)
    xmid = (x[1:] + x[:-1]) / 2.0
    ymid = (y[1:] + y[:-1]) / 2.0
    x = np.append(np.array([x[:-1], xmid, xmid]).T.ravel(), x[-1])
    y = np.append(np.array([y[:-1], ymid, ymid]).T.ravel(), y[-1])
    pairs = np.array([x, y]).T
    segments = np.array([pairs[:-1], pairs[1:]]).swapaxes(0, 1)
    if norm and not callable(norm):
        norm = plt.Normalize(*norm)
    lc = mpl.collections.LineCollection(segments, norm=norm, **kwargs)
    lc.set_array(np.repeat(c, 3)[1:-1])
    if ax:
        ax.add_collection(lc)
        ax.autoscale_view()
    return lc


def dcm2quat(dcm):
    """Create quaternion array from direction cosine matrix array."""
    if isinstance(dcm, np.ma.MaskedArray):
        zeros = np.ma.zeros
    else:
        zeros = np.zeros
    quat = zeros((4,) + dcm.shape[2:], dtype=dcm.dtype)
    quat[0] = np.sqrt(np.trace(dcm) + 1.0) / 2.0
    quat[1] = dcm[1, 2] - dcm[2, 1]
    quat[2] = dcm[2, 0] - dcm[0, 2]
    quat[3] = dcm[0, 1] - dcm[1, 0]
    quat[1:] /= 4.0 * quat[0]
    return quat


def quat2dcm(quat):
    """Create a direction cosine matrix array from quaternion array."""
    quat = np.array(quat, subok=True)
    quat /= np.sqrt(np.sum(quat ** 2, axis=0))
    q0, q1, q2, q3 = quat
    if isinstance(quat, np.ma.MaskedArray):
        zeros = np.ma.zeros
    else:
        zeros = np.zeros
    dcm = zeros((3, 3) + quat.shape[1:], dtype=quat.dtype)

    qsq = quat ** 2.0
    q0sq = qsq[0]
    for i in range(3):
        dcm[i, i] = q0sq + qsq[i + 1] - 0.5

    q0q1 = q0 * q1
    q0q2 = q0 * q2
    q0q3 = q0 * q3
    q1q2 = q1 * q2
    q1q3 = q1 * q3
    q2q3 = q2 * q3

    dcm[0, 1] = q1q2 + q0q3
    dcm[0, 2] = q1q3 - q0q2
    dcm[1, 0] = q1q2 - q0q3

    dcm[1, 2] = q2q3 + q0q1
    dcm[2, 0] = q1q3 + q0q2
    dcm[2, 1] = q2q3 - q0q1

    return 2.0 * dcm


def loadmat(filename, **kwargs):
    """Load a .mat file with sensible default options."""
    import scipy.io
    defaults = dict(squeeze_me=True,
                    chars_as_strings=True,
                    struct_as_record=False)
    defaults.update(kwargs)

    def dictify(struct):
        if isinstance(struct, dict):
            return {k: dictify(v) for k, v in struct.items()}
        elif isinstance(struct, scipy.io.matlab.mio5_params.mat_struct):
            return {k: dictify(getattr(struct, k)) for k in struct._fieldnames}
        return struct

    return dict2obj(dictify(scipy.io.loadmat(filename, **defaults)))


def savemat(filename, obj, **kwargs):
    """Save a .mat file with sensible default options."""
    import scipy.io
    kwargs.setdefault('long_field_names', True)
    kwargs.setdefault('do_compression', True)
    return scipy.io.savemat(filename, obj, **kwargs)


def minmax(a, **kwargs):
    """Return a tuple (min, max) of `a`."""
    return np.amin(a, **kwargs), np.amax(a, **kwargs)


def nanminmax(a, **kwargs):
    """Return a tuple (min, max) of `a` ignoring NaNs."""
    return np.nanmin(a, **kwargs), np.nanmax(a, **kwargs)


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
        input = kwargs.get('input', not kwargs.get('output', None))
        output = kwargs.get('output', not input)
        if input in (True, False):
            input = Ellipsis if input else ()
        if output in (True, False):
            output = Ellipsis if output else ()

        def g(*args, **kwargs):
            dtype = None if np.issubdtype(
                np.asanyarray(args[0]).dtype, float) else np.float64
            args = np.array(args, dtype=dtype, subok=True)
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


class SymmetricMaxNLocator(mpl.ticker.MaxNLocator):

    """Select around N intervals symmetric about zero."""

    def __init__(self, *args, **kwargs):
        kwargs['symmetric'] = True
        super(SymmetricMaxNLocator, self).__init__(*args, **kwargs)

    def bin_boundaries(self, vmin, vmax):
        v = max(map(abs, (vmin, vmax)))
        return super(SymmetricMaxNLocator, self).bin_boundaries(-v, v)


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
    'BunchBunch',
    'Conversion',
    'SymmetricMaxNLocator',
    'angle2dcm',
    'angle_difference',
    'array_bunchify',
    'axis_equal_3d',
    'azip',
    'cdfplot',
    'cl',
    'colored_line',
    'create',
    'cursor',
    'd2r',
    'dataobj',
    'dcm2angle',
    'dcm2quat',
    'DefaultBunch',
    'dict2obj',
    'fg',
    'fig',
    'figdo',
    'fix_angles',
    'flatten',
    'index_all',
    'loadmat',
    'map_dict',
    'merge_dicts',
    'minmax',
    'nanminmax',
    'pad',
    'picker',
    'product_items',
    'quat2dcm',
    'r2d',
    'resize',
    'savehtml',
    'savemat',
    'savepdf',
    'savesvg',
    'shift',
    'styles',
    'unique_legend',
    'unmask',
    'where_first',
    'where_last',
    'varinfo',
]
