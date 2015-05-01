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
    c.IPythonWidget.syntax_style = "solarizedlight"

    def add(item):
        if item not in c.InteractiveShellApp.exec_lines:
            c.InteractiveShellApp.exec_lines.append(item)

    lines = [
        'from __future__ import division',
        'from plottools import *',
        'import plottools as pt',
        'import matplotlib as mpl',
        'import scipy.io as sio',
        'import os',
        'import re',
        'import subprocess',
        'import numpy as np',
        'import scipy.constants as sc',
        ('def setwidth(): os.environ["COLUMNS"] = '
         'subprocess.check_output(["tput", "cols"])'),
        'env = {k: v for k, v in os.environ.iteritems()}',
        'exec("del who" if "who" in globals() else "pass")',
        'from collections import Iterable',
        ('from numpy import (arccos as acos, arccosh as acosh,'
         '                   arcsin as asin, arcsinh as asinh,'
         '                   arctan as atan, arctan2 as atan2,'
         '                   arctanh as atanh, rad2deg as deg)'),
    ]
    map(add, lines)
