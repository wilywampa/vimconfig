try:
    import cPickle as pickle
except ImportError:
    import pickle
import collections
import numpy.ma as ma
import sys
from IPython.utils.text import SList
_print_templates = ma.core._print_templates
PY3 = sys.version_info[0] == 3

__all__ = ['S', 'SliceIndex', 'dump', 'fields_dict', 'globn', 'items_dict',
           'load', 'sortn', 'sortnkey']

_imports = """\
from __future__ import division
import IPython.parallel as px  # python2
try:
    import cPickle as pickle
except ImportError:
    import pickle
import collections
import ein
import ipyparallel as px  # python3
import itertools as it
import logging
import mathtools as mt
import matplotlib as mpl
import matplotlib.cm as cm
import matplotlib.colors as colors
import numpy as np
import operator as op
import os
import plottools as pt
import re
import scipy.constants as sc
import scipy.interpolate as si
import scipy.io as sio
import scipy.optimize as opt
import six
import subprocess
import sys
from IPython.core.display import display
from IPython.lib.pretty import pretty
from IPython.parallel import Client  # python2
try:  # python2
    from IPython.external.path import path as Path  # python2
except ImportError:  # python2
    from IPython.external.path import Path # python2
from IPython.utils.text import LSString, SList
from bunch import Bunch, bunchify, unbunchify
from collections import defaultdict, namedtuple
from contextlib import suppress  # python3
from functools import reduce
from ipyparallel import Client  # python3
from ipython_config import *
from itertools import (chain, count, cycle, dropwhile, groupby, islice,
                       starmap, takewhile, tee)
from six.moves import (filter as ifilter, filterfalse as ifilterfalse, map as
                       imap, xrange, zip as izip, zip_longest as izip_longest)
from mathtools import *
from plottools import *
from numpy import (arccos as acos, arccosh as acosh, arcsin as asin,
                   arcsinh as asinh, arctan as atan, arctan2 as atan2,
                   arctanh as atanh, rad2deg as deg, deg2rad as rad)
from numpy.ma import (getdata, getmaskarray, masked_all,
                      masked_array as marray)
from path import Path  # python3
from subprocess import PIPE, Popen, call, check_output
from __builtin__ import abs, all, any, max, min, round, sum  # python2
from builtins    import abs, all, any, max, min, round, sum  # python3
"""


def _marray_pprint(a, p, cycle):
    """Print mask as 'False' if mask is all False."""
    try:
        n = len(a.shape)
        name = 'array'

        parameters = dict(name=name, nlen=" " * len(name),
                          data=str(a), mask=str(a._mask),
                          fill=str(a.fill_value), dtype=str(a.dtype))
        if not ma.getmaskarray(a).any():
            parameters['mask'] = 'False'
        if a.dtype.names:
            if n <= 1:
                p.text(_print_templates['short_flx'] % parameters)
            p.text(_print_templates['long_flx'] % parameters)
        elif n <= 1:
            p.text(_print_templates['short_std'] % parameters)
        p.text(_print_templates['long_std'] % parameters)
    except Exception:
        p.text(repr(a))


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


class SliceIndex(object):

    """Allow indexing generators with square brackets."""

    def __init__(self, iterator):
        try:
            self.iterator = iter(iterator)
        except TypeError:
            self.iterator = iter(iterator())

    def __iter__(self):
        for elt in self.iterator:
            yield elt

    def __getitem__(self, ix):
        from itertools import islice
        try:
            return next(islice(self.iterator, ix, ix + 1))
        except TypeError:
            start, stop, step = ix.start, ix.stop, ix.step
            if stop is None:
                return islice(self.iterator, start, stop, step)
            if stop == -1:
                stop = None
            return list(islice(self.iterator, start, stop, step))
S = SliceIndex


def items_dict(slist, key=None):
    """Return a list of dictionaries representing the fields of each line."""
    fields = slist.fields()
    items = [collections.OrderedDict((k, f) for k, f in zip(fields[0], item))
             for item in fields[1:]]
    if key:
        return collections.OrderedDict((i[key], i) for i in items)
    else:
        return items


def fields_dict(slist, type=SList):
    """Return a dictionary with a list of values for each field."""
    fields = slist.fields()
    names = fields.pop(0)
    out = collections.OrderedDict()
    for i, name in enumerate(names[:-1]):
        out[name] = type(slist.fields(i)[1:])
    out[names[-1]] = type([' '.join(f[i + 1:]) for f in fields])
    return out


def _install():
    import io
    from IPython import get_ipython
    from IPython.core import magic

    import ipython_autocd
    ipython_autocd.register()

    import lambda_filter
    lambda_filter.register()

    @magic.register_line_magic
    def run_cython(args):
        """Run a Cython file using %%cython magic."""
        args = magic.arg_split(args, posix=True)
        filename = args.pop()
        if '--force' not in args:
            args.append('--force')
        ip = get_ipython()
        ip.extension_manager.load_extension('cython')
        with io.open(filename, 'r', encoding='utf-8') as f:
            ip.run_cell_magic('cython', ' '.join(args), f.read())
    del run_cython


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

    from IPython.lib.pretty import _set_pprinter_factory
    c.PlainTextFormatter.type_printers.update({
        ma.core.MaskedArray: _marray_pprint,
        set: _set_pprinter_factory('set({', '})', set),
    })

    def add(item):
        if item not in c.InteractiveShellApp.exec_lines:
            c.InteractiveShellApp.exec_lines.append(item)

    lines = [
        'import ipython_config as _; _._install()',
        '\n'.join(line for line in _imports.splitlines()
                  if not line.endswith('python2' if PY3 else 'python3')),
        ('def setwidth(): os.environ["COLUMNS"] = '
         'subprocess.check_output(["tput", "cols"])'),
        'env = {k: v for k, v in os.environ.items()}',
        'exec("del who" if "who" in globals() else "pass")',
        'ip = get_ipython()',
    ]
    for line in lines:
        add(line)

    ls_sort = ' --sort=none' if sys.platform == 'darwin' else ''
    c.AliasManager.default_aliases = []
    c.AliasManager.user_aliases = [
        ('l', 'ls -h --color=always' + ls_sort),
        ('ls', 'ls -h --color=always' + ls_sort),
        ('la', 'ls -hA --color=always' + ls_sort),
        ('ll', 'ls -lsh --color=always' + ls_sort),
        ('lls', 'ls -lshrt --color=always'),
        ('lla', 'ls -lshA --color=always'),
        ('llas', 'ls -lshrtA --color=always'),
        ('llsa', 'ls -lshrtA --color=always'),
        ('lu', 'ls -1U --color=always' + ls_sort),
        ('llu', 'ls -1lUsh --color=always' + ls_sort),
        ('llua', 'ls -1lUshA --color=always' + ls_sort),
        ('llau', 'ls -1lUshA --color=always' + ls_sort),
    ]
