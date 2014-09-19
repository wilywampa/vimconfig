import matplotlib.pyplot as plt


def fig(num=0):
    plt.figure(num)
    try:
        plt.get_current_fig_manager().window.activateWindow()
    except AttributeError:
        plt.get_current_fig_manager().window.Raise()


def cl():
    plt.close('all')
