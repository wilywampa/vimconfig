import cPickle as pickle


def _pkl_name(fname):
    return fname + ("" if fname.endswith(".pkl") else ".pkl")


def dump(obj, fname):
    with open(_pkl_name(fname), "wb") as f:
        pickle.dump(obj, f, -1)


def load(fname):
    with open(_pkl_name(fname), "rb") as f:
        return pickle.load(f)


def sortnkey(s):
    """Split string into numeric components for sorting."""
    import re

    def tryint(s):
        try:
            return int(s)
        except ValueError:
            return s

    return [tryint(c) for c in re.split('([0-9]+)', s)]


def sortn(xs):
    """Sort list by numeric components."""
    return sorted(xs, key=sortnkey)


def globn(pathname):
    """Like glob.glob but try to sort numerically."""
    from glob import glob
    return sortn(glob(pathname))


def configure(c):
    """
    Global IPython configuration.

    >>> import imp
    >>> import os
    >>> imp.load_source('_ipython_config', os.path.join(
    ...     os.environ['VIMCONFIG'], 'misc', 'python', 'ipython_config.py')
    ... ).configure(c)

    """
    c.TerminalInteractiveShell.colors = 'Linux'
    c.TerminalInteractiveShell.autocall = 1
    c.TerminalInteractiveShell.confirm_exit = False
    c.PromptManager.color_scheme = 'Linux'
    c.IPCompleter.greedy = True
    try:
        import pygments.styles
    except ImportError:
        pass
    else:
        if "solarizedlight" in pygments.styles.get_all_styles():
            c.IPythonWidget.syntax_style = "solarizedlight"

    def add(item):
        if item not in c.InteractiveShellApp.exec_lines:
            c.InteractiveShellApp.exec_lines.append(item)

    lines = [
        'from __future__ import division',
        'import IPython.parallel as px',
        'import cPickle as pickle',
        'import collections',
        'import ein',
        'import ipython_autocd as _; _.register()',
        'import itertools as it',
        'import lambda_filter as _; _.register()',
        'import matplotlib as mpl',
        'import matplotlib.cm as cm',
        'import matplotlib.colors as colors',
        'import numpy as np',
        'import operator as op',
        'import os',
        'import plottools as pt',
        'import re',
        'import scipy.constants as sc',
        'import scipy.interpolate as si',
        'import scipy.io as sio',
        'import scipy.optimize as opt',
        'import subprocess',
        'from IPython.parallel import Client',
        'from IPython.external.path import Path, path',
        'from IPython.utils.text import LSString, SList',
        'from bunch import Bunch, bunchify, unbunchify',
        'from collections import defaultdict, namedtuple',
        'from ipython_config import dump, globn, load, sortn, sortnkey',
        ('from itertools import (chain, count, cycle, dropwhile, groupby, '
         '                       ifilter, ifilterfalse, imap, islice, izip, '
         '                       izip_longest, starmap, takewhile, tee)'),
        'from mathtools import *',
        'from plottools import *',
        ('def setwidth(): os.environ["COLUMNS"] = '
         'subprocess.check_output(["tput", "cols"])'),
        'env = {k: v for k, v in os.environ.iteritems()}',
        'exec("del who" if "who" in globals() else "pass")',
        ('from numpy import (arccos as acos, arccosh as acosh,'
         '                   arcsin as asin, arcsinh as asinh,'
         '                   arctan as atan, arctan2 as atan2,'
         '                   arctanh as atanh, rad2deg as deg,'
         '                   deg2rad as rad)'),
        ('from numpy.ma import (getdata, getmaskarray, masked_all,'
         '                      masked_array as marray)'),
        'from subprocess import PIPE, Popen, call, check_output',
        'from __builtin__ import abs, all, any, max, min, round, sum',
        'ip = get_ipython()',
    ]
    map(add, lines)
