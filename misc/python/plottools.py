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
