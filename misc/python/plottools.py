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
    if type(var) is numpy.ndarray:
        print var.shape


def dict2obj(dic):
    """
    Convert a dict to an object with the dictionary's keys as attributes.
    Sanitizes illegal characters and keywords and resolves resulting
    duplicates.
    """
    from collections import namedtuple
    from keyword import iskeyword
    import re

    seen = []
    for key in dic.keys():
        newkey = key
        if iskeyword(key):
            newkey = key + '_'
        elif not key.isalnum():
            newkey = re.sub('[^_0-9A-Za-z]', '_', key)
        if newkey.startswith('_'):
            newkey = 'u' + newkey
        while newkey in seen:
            newkey = newkey + '_'
        seen.append(newkey)
        if newkey != key:
            dic[newkey] = dic.pop(key)

    obj = namedtuple('obj', dic.keys())

    return obj(**dic)
