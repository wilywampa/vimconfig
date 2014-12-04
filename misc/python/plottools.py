import matplotlib.pyplot as _plt


def fg(fig=None):
    """Raise figure to foreground."""
    _plt.figure((fig or _plt.gcf()).number)
    if _plt.get_backend()[0:2].lower() == 'qt':
        _plt.get_current_fig_manager().window.activateWindow()
        _plt.get_current_fig_manager().window.raise_()
    elif _plt.get_backend()[0:2].lower() == 'wx':
        _plt.get_current_fig_manager().window.Raise()


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


def savepdf(filename):
    """Save all open figures to a PDF file."""
    from matplotlib.backends.backend_pdf import PdfPages
    with PdfPages(filename) as pp:
        figs = [_plt.figure(n) for n in _plt.get_fignums()]
        for f in figs:
            f.savefig(pp, format='pdf')


def savesvg(basename):
    """Save all open figures to SVG files."""
    figs = [_plt.figure(n) for n in _plt.get_fignums()]
    for f in figs:
        f.savefig(basename + str(f.number) + '.svg', format='svg')


def varinfo(var):
    """Pretty print information about a variable."""
    from pprint import pprint
    import numpy
    print type(var)
    pprint(var)
    if isinstance(var, numpy.ndarray):
        print var.shape


def pad(array, length, filler=float('nan')):
    """Extend a 1D array to `length` by appending `filler` values."""
    import numpy
    if not isinstance(array, numpy.ndarray):
        return array
    return numpy.pad(array, ((0, length - array.shape[0]),) * array.ndim,
                     mode='constant', constant_values=(filler,))


try:
    from attrdict import AttrDict as dict2obj
except ImportError:
    class dict2obj(dict):

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

else:
    import sys
    _STRING = basestring if sys.version_info < (3,) else str

    # Make invalid attribute names still show up in IPython completion
    def _valid_name(cls, name):
        return isinstance(name, _STRING) and not hasattr(cls, name)

    dict2obj._valid_name = _valid_name
