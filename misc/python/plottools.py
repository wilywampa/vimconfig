import matplotlib.pyplot as plt


def fig(num=1):
    plt.figure(num - 1)
    try:
        plt.get_current_fig_manager().window.activateWindow()
    except AttributeError:
        plt.get_current_fig_manager().window.Raise()


def cl():
    plt.close('all')
