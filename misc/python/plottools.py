import matplotlib.pyplot as plt
import pprint
import numpy


def fig(num=1):
    plt.figure(num - 1)
    if plt.get_backend()[0:2].lower() == 'qt':
        plt.get_current_fig_manager().window.activateWindow()
    elif plt.get_backend()[0:2].lower() == 'wx':
        plt.get_current_fig_manager().window.Raise()


def cl():
    plt.close('all')


def varinfo(var):
    print type(var)
    pp = pprint.PrettyPrinter()
    pp.pprint(var)
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
        while newkey in seen:
            newkey = newkey + '_'
        seen.append(newkey)
        if newkey != key:
            dic[newkey] = dic.pop(key)

    obj = namedtuple('obj', dic.keys())

    return obj(**dic)
