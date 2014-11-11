import matplotlib.pyplot as _plt


def fg(fig):
    """
    Raise figure to foreground
    """
    _plt.figure(fig.number)
    if _plt.get_backend()[0:2].lower() == 'qt':
        _plt.get_current_fig_manager().window.activateWindow()
        _plt.get_current_fig_manager().window.raise_()
    elif _plt.get_backend()[0:2].lower() == 'wx':
        _plt.get_current_fig_manager().window.Raise()


def fig(num=1):
    fg(_plt.figure(num))


def figdo(*args):
    """
    Apply functions to all open figures
    """
    [func(_plt.figure(n)) for n in _plt.get_fignums() for func in args]


def resize(width, height):
    _plt.get_current_fig_manager().resize(width, height)


def cl():
    _plt.close('all')


def savepdf(filename):
    from matplotlib.backends.backend_pdf import PdfPages
    with PdfPages(filename) as pp:
        figs = [_plt.figure(n) for n in _plt.get_fignums()]
        for f in figs:
            f.savefig(pp, format='pdf')


def savesvg(basename):
    figs = [_plt.figure(n) for n in _plt.get_fignums()]
    for f in figs:
        f.savefig(basename + str(f.number) + '.svg', format='svg')


def varinfo(var):
    from pprint import pprint
    import numpy
    print type(var)
    pprint(var)
    if isinstance(var, numpy.ndarray):
        print var.shape


class dict2obj(dict):

    """
    Convert a dict to an object with the dictionary's keys as attributes.
    """

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
            value = self.__class__(value) if isinstance(value, dict) else value
        super(dict2obj, self).__setattr__(name, value)
        self[name] = value
