from __future__ import division
from PyQt4 import QtCore, QtGui
from PyQt4.QtCore import SIGNAL
import matplotlib as mpl
from collections import Iterable
from types import StringTypes
from matplotlib.figure import Figure
from matplotlib.backends.backend_qt4agg import (
    FigureCanvasQTAgg as FigureCanvas,
    NavigationToolbar2QT as NavigationToolbar)
from matplotlib.backend_bases import key_press_handler
import sys
import numpy as np
import re
import scipy.constants as const
from itertools import cycle
from mplpicker import picker

if sys.platform == 'darwin':
    CONTROL_MODIFIER = QtCore.Qt.MetaModifier
else:
    CONTROL_MODIFIER = QtCore.Qt.ControlModifier


def flatten(d, prefix=''):
    """Join nested keys with '.' and unstack arrays."""
    out = {}
    for key, value in d.iteritems():
        key = (prefix + '.' if prefix else '') + key
        if isinstance(value, dict):
            out.update(flatten(value, key))
        else:
            out[key] = value
            if isinstance(value, np.ndarray) and value.ndim > 2:
                queue = [key]
                while queue:
                    key = queue.pop()
                    array = out.pop(key)
                    new = {key + '[%d]' % i: a
                           for i, a in enumerate(array)}
                    out.update(new)
                    queue.extend([q for q in new.keys()
                                  if new[q].ndim > 2])
    return out


def _delete_word(self, event, parent, lineEdit):
    if lineEdit.selectionStart() == -1:
        lineEdit.cursorWordBackward(True)
        lineEdit.backspace()


def _select_all(self, event, parent, lineEdit):
    lineEdit.selectAll()


def _quit(self, event, parent, lineEdit):
    self.emit(SIGNAL('closed()'))
    self.window().close()


control_actions = {
    QtCore.Qt.Key_A: _select_all,
    QtCore.Qt.Key_D: lambda self, *args: self.emit(SIGNAL('remove()')),
    QtCore.Qt.Key_L: lambda self, *args: self.emit(SIGNAL('relabel()')),
    QtCore.Qt.Key_N: lambda self, *args: self.emit(SIGNAL('duplicate()')),
    QtCore.Qt.Key_Q: _quit,
    QtCore.Qt.Key_T: lambda self, *args: self.emit(SIGNAL('twin()')),
    QtCore.Qt.Key_W: _delete_word,
}


def handle_key(self, event, parent, lineEdit):
    if event.type() == QtCore.QEvent.KeyPress:
        if (event.modifiers() == CONTROL_MODIFIER and
                event.key() in control_actions):
            control_actions[event.key()](self, event, parent, lineEdit)
            return True
        elif self.completer.popup().viewport().isVisible():
            if event.key() == QtCore.Qt.Key_Tab:
                self.emit(SIGNAL('tabPressed(int)'), 1)
                return True
            elif event.key() == QtCore.Qt.Key_Backtab:
                self.emit(SIGNAL('tabPressed(int)'), -1)
                return True
            elif event.key() == QtCore.Qt.Key_Return:
                self.emit(SIGNAL('returnPressed()'))

    return parent.event(self, event)


def KeyHandler(parent):
    class KeyHandlerClass(parent):

        def set_completer(self, completer):
            self.completer = completer

        def event(self, event):
            try:
                lineEdit = self.lineEdit()
            except AttributeError:
                lineEdit = self
            return handle_key(self, event, parent, lineEdit)

    return KeyHandlerClass


class TabCompleter(QtGui.QCompleter):

    def __init__(self, words, *args, **kwargs):
        QtGui.QCompleter.__init__(self, words, *args, **kwargs)
        self.setCaseSensitivity(QtCore.Qt.CaseInsensitive)
        self.setMaxVisibleItems(50)
        self.words = words
        self.connect(self.popup(), SIGNAL('activated(int)'), self.confirm)

    def set_textbox(self, textbox):
        self.textbox = textbox
        self.connect(self.textbox, SIGNAL('tabPressed(int)'),
                     self.select_completion)
        self.connect(self.textbox, SIGNAL('activated(int)'), self.close_popup)
        self.connect(self.textbox, SIGNAL('closed()'), self.close_popup)
        self.connect(self.textbox, SIGNAL('returnPressed()'), self.confirm)

    def select_completion(self, direction):
        if not self.popup().selectionModel().hasSelection():
            if direction == 0:
                return
            direction = 0
        self.setCurrentRow((self.currentRow() + direction) %
                           self.completionCount())
        self.popup().setCurrentIndex(self.completionModel().
                                     index(self.currentRow(), 0))

    def close_popup(self):
        popup = self.popup()
        if popup.isVisible():
            self.confirm()
            popup.close()

    def confirm(self):
        try:
            text = unicode(self.textbox.currentText())
        except AttributeError:
            pass
        else:
            if self.words.findText(text) == -1:
                self.select_completion(0)
            else:
                return self.emit(SIGNAL('activated(QString)'), text)
        self.emit(SIGNAL('activated(QString)'), self.currentCompletion())


class CustomQCompleter(TabCompleter):

    def __init__(self, *args, **kwargs):
        super(CustomQCompleter, self).__init__(*args, **kwargs)
        self.parent = kwargs.get('parent', None)
        self.local_completion_prefix = ''
        self.source_model = None
        self.filterProxyModel = QtGui.QSortFilterProxyModel(self)
        self.usingOriginalModel = False

    def setModel(self, model):
        self.source_model = model
        self.filterProxyModel = QtGui.QSortFilterProxyModel(self)
        self.filterProxyModel.setSourceModel(self.source_model)
        super(CustomQCompleter, self).setModel(self.filterProxyModel)
        self.usingOriginalModel = True

    def updateModel(self):
        if not self.usingOriginalModel:
            self.filterProxyModel.setSourceModel(self.source_model)

        pattern = QtCore.QRegExp(
            self.local_completion_prefix,
            QtCore.Qt.CaseSensitive
            if re.match('.*[A-Z]', self.local_completion_prefix)
            else QtCore.Qt.CaseInsensitive,
            QtCore.QRegExp.RegExp)

        self.filterProxyModel.setFilterRegExp(pattern)

    def splitPath(self, path):
        words = [unicode(QtCore.QRegExp.escape(word.replace(r'\ ', ' ')))
                 for word in re.split(r'(?<!\\)\s+', unicode(path))]

        includes = [re.sub(r'^\\\\!', '!', word) for word in words
                    if not word.startswith('!')]
        excludes = [word[1:] for word in words
                    if len(word) > 1 and word.startswith('!')]

        self.local_completion_prefix = QtCore.QString(
            '^' + ''.join(['(?=.*%s)' % word for word in includes]) +
            ''.join(['(?!.*%s)' % word for word in excludes]) + '.+')

        self.updateModel()
        if self.completionCount() == 0:
            self.local_completion_prefix = path
        if self.filterProxyModel.rowCount() == 0:
            self.usingOriginalModel = False
            self.filterProxyModel.setSourceModel(
                QtGui.QStringListModel([path]))
            return [path]

        return []


class AutoCompleteComboBox(QtGui.QComboBox):

    def __init__(self, *args, **kwargs):
        super(AutoCompleteComboBox, self).__init__(*args, **kwargs)

        self.setEditable(True)
        self.setInsertPolicy(self.NoInsert)

        self.completer = CustomQCompleter(self)
        self.completer.setCompletionMode(QtGui.QCompleter.PopupCompletion)
        self.setCompleter(self.completer)

    def setModel(self, strList):
        self.clear()
        self.insertItems(0, strList)
        self.completer.setModel(self.model())


class DataObj(object):

    def __init__(self, parent, obj, name, **kwargs):
        self.parent = parent
        self.obj = obj
        self.name = name
        self.labels = kwargs.get('labels', name)
        self.widgets = []
        self.twin = False
        draw = self.parent.draw
        connect = self.parent.connect

        self.label = QtGui.QLabel(name + ':', parent=self.parent)
        self.scale_label = QtGui.QLabel('scale:', parent=self.parent)
        self.xscale_label = QtGui.QLabel('scale:', parent=self.parent)

        self.obj = flatten(self.obj)
        words = [k for k in self.obj.keys()
                 if isinstance(self.obj[k], np.ndarray)]
        words.sort(key=lambda w: w.lower())

        def new_text_box():
            menu = KeyHandler(AutoCompleteComboBox)(parent=self.parent)
            menu.setMinimumWidth(100)
            menu.setModel(words)
            menu.setMaxVisibleItems(50)
            completer = menu.completer
            completer.set_textbox(menu)

            connect(menu, SIGNAL('activated(QString)'), draw)
            connect(completer, SIGNAL('activated(int)'), draw)

            return completer, menu

        self.completer, self.menu = new_text_box()
        self.xcompleter, self.xmenu = new_text_box()

        self.menu.setCurrentIndex(0)
        self.xmenu.setCurrentIndex(0)
        self.xlabel = QtGui.QLabel('x axis:', parent=self.parent)

        words = [c for c in dir(const) if isinstance(getattr(const, c), float)]
        words.sort(key=lambda w: w.lower())

        def new_scale_box():
            scale_compl = TabCompleter(words, parent=self.parent)
            scale_box = KeyHandler(QtGui.QLineEdit)(parent=self.parent)
            scale_box.set_completer(scale_compl)
            scale_box.setMinimumWidth(100)
            scale_compl.setWidget(scale_box)
            scale_box.setText('1.0')
            scale_compl.set_textbox(scale_box)

            def text_changed(text):
                cursor_pos = scale_box.cursorPosition()
                text = unicode(scale_box.text())[:cursor_pos]
                prefix = re.split(r'\W', text)[-1].strip()
                scale_compl.setCompletionPrefix(prefix)
                scale_compl.complete()
                scale_compl.select_completion(0)

            def complete_text(text):
                if not scale_box.text():
                    return scale_box.setText(u'1.0')
                text = unicode(text)
                cursor_pos = scale_box.cursorPosition()
                before_text = unicode(scale_box.text())[:cursor_pos]
                after_text = unicode(scale_box.text())[cursor_pos:]
                prefix_len = len(re.split(r'\W', before_text)[-1].strip())
                part = before_text[-prefix_len:]
                if len(part) and text.startswith(part):
                    scale_box.setText(before_text[:cursor_pos - prefix_len] +
                                      text + after_text)
                    scale_box.setCursorPosition(cursor_pos -
                                                prefix_len + len(text))

            connect(scale_box, SIGNAL('editingFinished()'), draw)
            connect(scale_box, SIGNAL('textChanged(QString)'), text_changed)
            connect(scale_compl, SIGNAL('activated(QString)'), complete_text)

            return scale_box, scale_compl

        self.scale_box, self.scale_compl = new_scale_box()
        self.xscale_box, self.xscale_compl = new_scale_box()

        self.process_kwargs(kwargs)

    def process_kwargs(self, kwargs):
        if 'yname' in kwargs:
            self.menu.setCurrentIndex(self.menu.findText(kwargs['yname']))
        if 'yscale' in kwargs:
            self.scale_box.setText(str(kwargs['yscale']))
        if 'xname' in kwargs:
            self.xmenu.setCurrentIndex(self.menu.findText(kwargs['xname']))
        if 'xscale' in kwargs:
            self.xscale_box.setText(str(kwargs['xscale']))

    def duplicate(self):
        self.parent.add_data(self.obj, self.name)
        data = self.parent.datas[-1]
        data.menu.setCurrentIndex(self.menu.currentIndex())
        data.scale_box.setText(self.scale_box.text())
        data.xmenu.setCurrentIndex(self.xmenu.currentIndex())
        data.xscale_box.setText(self.xscale_box.text())
        self.parent.set_layout()
        data.menu.setFocus()
        data.menu.lineEdit().selectAll()

    def remove(self):
        self.parent.remove_data(self)

    def change_label(self):
        text, ok = QtGui.QInputDialog.getText(self.parent,
                                              'Rename data object',
                                              'New label:')
        if ok:
            self.name = unicode(text)
            self.label.setText(text + ':')
            if not isinstance(self.labels, list):
                self.labels = self.name
            self.parent.draw()

    def toggle_twin(self):
        self.twin = not self.twin
        self.parent.draw()


class Interact(QtGui.QMainWindow):

    def __init__(self, data, title, parent=None):
        QtGui.QMainWindow.__init__(self, parent)
        if title is not None:
            self.setWindowTitle(title)
        else:
            self.setWindowTitle(', '.join([d[1] for d in data]))
        self.grid = QtGui.QGridLayout()

        self.frame = QtGui.QWidget()
        self.dpi = 100

        self.fig = Figure()
        self.canvas = FigureCanvas(self.fig)
        self.canvas.setParent(self.frame)
        self.canvas.setFocusPolicy(QtCore.Qt.ClickFocus)
        self.canvas.mpl_connect('key_press_event', self.canvas_key_press)
        self.axes = self.fig.add_subplot(111)
        self.axes2 = self.axes.twinx()
        self.fig.delaxes(self.axes2)

        self.xlim = None
        self.ylim = None
        self.xlogscale = 'linear'
        self.ylogscale = 'linear'

        self.mpl_toolbar = NavigationToolbar(self.canvas, self.frame)
        self.pickers = None

        self.vbox = QtGui.QVBoxLayout()
        self.vbox.addWidget(self.mpl_toolbar)

        self.datas = []
        for d in data:
            self.add_data(*d)

        self.vbox.addLayout(self.grid)
        self.set_layout()

    def set_layout(self):
        self.vbox.addWidget(self.canvas)

        self.frame.setLayout(self.vbox)
        self.setCentralWidget(self.frame)

        for data in self.datas:
            self.setTabOrder(data.menu, data.scale_box)
            self.setTabOrder(data.scale_box, data.xmenu)
            self.setTabOrder(data.xmenu, data.xscale_box)

        if len(self.datas) >= 2:
            for d1, d2 in zip(self.datas[:-1], self.datas[1:]):
                self.setTabOrder(d1.menu, d2.menu)

        self.draw()

    def add_data(self, obj, name, kwargs=None):
        self.datas.append(DataObj(self, obj, name, **(kwargs or {})))
        data = self.datas[-1]

        self.row = self.grid.rowCount()
        self.column = 0

        def add_widget(w):
            self.grid.addWidget(w, self.row, self.column)
            data.widgets.append(w)
            self.connect(w, SIGNAL('duplicate()'), data.duplicate)
            self.connect(w, SIGNAL('remove()'), data.remove)
            self.connect(w, SIGNAL('relabel()'), data.change_label)
            self.connect(w, SIGNAL('twin()'), data.toggle_twin)
            self.column += 1

        add_widget(data.label)
        add_widget(data.menu)
        add_widget(data.scale_label)
        add_widget(data.scale_box)
        add_widget(data.xlabel)
        add_widget(data.xmenu)
        add_widget(data.xscale_label)
        add_widget(data.xscale_box)

    def warn(self, message):
        self.warnings = [message]
        self.draw_warnings()
        self.canvas.draw()

    def remove_data(self, data):
        if len(self.datas) < 2:
            return self.warn("Can't delete last row")

        index = self.datas.index(data)
        self.datas.pop(index)

        for widget in data.widgets:
            self.grid.removeWidget(widget)
            widget.deleteLater()

        self.set_layout()
        self.draw()
        self.datas[index-1].menu.setFocus()
        self.datas[index-1].menu.lineEdit().selectAll()

    def get_scale(self, textbox, completer):
        completer.close_popup()
        text = unicode(textbox.text())
        try:
            return eval(text, const.__dict__, {})
        except Exception as e:
            self.warnings.append('Error setting scale: ' + str(e))
            return 1.0

    def get_key(self, menu):
        key = unicode(menu.itemText(menu.currentIndex()))
        text = unicode(menu.lineEdit().text())
        if key != text:
            self.warnings.append(
                'Plotted key (%s) does not match typed key (%s)' %
                (key, text))
        return key

    @staticmethod
    def cla(axes):
        tight, xmargin, ymargin = (axes._tight, axes._xmargin, axes._ymargin)
        axes.clear()
        axes._tight, axes._xmargin, axes._ymargin = (tight, xmargin, ymargin)

    def clear_pickers(self):
        if self.pickers is not None:
            [p.disable() for p in self.pickers]
            self.pickers = None

    @staticmethod
    def plot(axes, x, y, label):
        try:
            axes.plot(x, y, label=label)
        except ValueError:
            axes.plot(x, y.T, label=label)

    def draw(self):
        twin = any(map(lambda x: x.twin, self.datas))
        if twin and len(self.fig.axes) < 2:
            self.fig.add_axes(self.axes2)
        elif not twin and len(self.fig.axes) >= 2:
            self.fig.delaxes(self.axes2)

        self.clear_pickers()
        self.cla(self.axes)
        self.cla(self.axes2)

        xlabel = []
        ylabel = []
        xlabel2 = []
        ylabel2 = []
        self.warnings = []
        for d in self.datas:
            if d.twin:
                axes, x, y = self.axes2, xlabel2, ylabel2
            else:
                axes, x, y = self.axes, xlabel, ylabel
            scale = self.get_scale(d.scale_box, d.scale_compl)
            xscale = self.get_scale(d.xscale_box, d.xscale_compl)
            text = self.get_key(d.menu)
            xtext = self.get_key(d.xmenu)
            if isinstance(d.labels, list):
                for i, l in enumerate(d.labels):
                    self.plot(axes, d.obj[xtext][..., i] * xscale,
                              d.obj[text][..., i] * scale, label=l)
            else:
                self.plot(axes, d.obj[xtext] * xscale, d.obj[text] * scale,
                          label=d.labels)
            axes.set_xlabel('')
            x.append(xtext + ' (' + d.name + ')')
            y.append(text + ' (' + d.name + ')')

        lines = self.axes.get_lines() + self.axes2.get_lines()
        clist = cycle(mpl.rcParams['axes.color_cycle'])
        for index, line in enumerate(lines):
            line.set_linestyle(self.get_linestyle(index))
            line.set_color(clist.next())

        self.axes.set_xlabel('\n'.join(xlabel))
        self.axes.set_ylabel('\n'.join(ylabel))
        self.draw_warnings()

        self.axes2.set_xlabel('\n'.join(xlabel2))
        self.axes2.set_ylabel('\n'.join(ylabel2))

        self.axes.set_xlim(self.xlim)
        self.axes.set_ylim(self.ylim)
        self.axes.set_xscale(self.xlogscale)
        self.axes.set_yscale(self.ylogscale)

        legend = self.axes.legend(tuple(lines), (l.get_label() for l in lines))
        legend.draggable(True)
        self.pickers = [picker(ax) for ax in [self.axes, self.axes2]]
        self.canvas.draw()

    def draw_warnings(self):
        self.axes.text(0.05, 0.05, '\n'.join(self.warnings),
                       transform=self.axes.transAxes, color='red')

    def get_linestyle(self, index):
        styles = ['-', '--', '-.', ':']
        ncolors = len(mpl.rcParams['axes.color_cycle'])
        return styles[((index + 1) // ncolors) % len(styles)]

    def canvas_key_press(self, event):
        key_press_handler(event, self.canvas, self.mpl_toolbar)

    def edit_parameters(self):
        xlim = self.axes.get_xlim()
        ylim = self.axes.get_ylim()
        self.mpl_toolbar.edit_parameters()
        if xlim != self.axes.get_xlim():
            self.xlim = self.axes.get_xlim()
        if ylim != self.axes.get_ylim():
            self.ylim = self.axes.get_ylim()
        self.xlogscale = self.axes.get_xscale()
        self.ylogscale = self.axes.get_yscale()

    def _margins(self):
        self.axes._tight = not self.axes._tight
        for ax in [self.axes, self.axes2]:
            if self.axes._tight:
                ax.margins(0.05)
            else:
                ax._xmargin = ax._ymargin = 0
        self.draw()

    def _options(self):
        self.edit_parameters()

    def _close(self):
        self.window().close()

    def _resetx(self):
        self.xlim = None
        self.draw()

    def _resety(self):
        self.ylim = None
        self.draw()

    control_actions = {
        QtCore.Qt.Key_M: '_margins',
        QtCore.Qt.Key_O: '_options',
        QtCore.Qt.Key_Q: '_close',
        QtCore.Qt.Key_X: '_resetx',
        QtCore.Qt.Key_Y: '_resety',
    }

    @staticmethod
    def data_dict(d):
        return dict(xname=str(d.xmenu.lineEdit().text()),
                    yname=str(d.menu.lineEdit().text()),
                    xscale=str(d.xscale_box.text()),
                    yscale=str(d.scale_box.text()))

    def event(self, event):
        if (event.type() == QtCore.QEvent.KeyPress and
            event.modifiers() & CONTROL_MODIFIER and
                event.key() in self.control_actions):
            getattr(self, self.control_actions[event.key()])()
            return True

        # Create duplicate of entire GUI with Ctrl+Shift+N
        elif (event.type() == QtCore.QEvent.KeyPress and
              event.modifiers() & CONTROL_MODIFIER and
              event.modifiers() & QtCore.Qt.ShiftModifier and
              event.key() == QtCore.Qt.Key_N):
            create(*[[d.obj, d.name, self.data_dict(d)] for d in self.datas])
            return True

        # Print dictionaries of keys and scales for all data with Ctrl+Shift+P
        elif (event.type() == QtCore.QEvent.KeyPress and
              event.modifiers() & CONTROL_MODIFIER and
              event.modifiers() & QtCore.Qt.ShiftModifier and
              event.key() == QtCore.Qt.Key_P):
            print "\n".join([str(self.data_dict(d)) for d in self.datas])
            return True
        return super(Interact, self).event(event)


def merge_dicts(*dicts):
    """Pad and concatenate arrays present in all input dictionaries."""
    sets = [set(d.keys()) for d in dicts]
    keys = sets[0].intersection(*sets)

    def validate(array):
        return isinstance(array, np.ndarray) and np.squeeze(array).ndim == 1

    def pad(array):
        return np.pad(np.squeeze(array), (0, length - array.size),
                      mode='constant', constant_values=(float('nan'),))

    merged = {}
    for key in keys:
        if all(map(validate, [d[key] for d in dicts])):
            length = max(map(len, [d[key] for d in dicts]))
            merged[key] = np.array([pad(d[key]) for d in dicts]).T
        elif all(map(lambda x: isinstance(x, dict), [d[key] for d in dicts])):
            merged[key] = merge_dicts(*[d[key] for d in dicts])

    return merged


def create(*data, **kwargs):
    """
    Create an interactive plot window for the given data.

    >>> create([dict1, 'Title1', 'XaxisKey1',
                dict(labels=['a', 'b'], xscale='1/degree')],
               [dict2, 'Title2'])

    The inputs should define data dictionaries to plot as a list
    containing the dictionary itself, a name for the dictionary to use
    in titles and labels, and optionally a dictionary of extra settings
    described below. The only optional keyword argument is `title`
    which sets the window title.

    Dictionary options allowed per data definition:
        'labels': a list of labels for 2+ dimensional data
        'xname':  a dictionary key (string) to plot on the x-axis
        'yname':  a dictionary key (string) to plot on the y-axis
        'xscale': a string or number defining scale factor for x-axis
        'yscale': a string or number defining scale factor for y-axis
    """
    app_created = False
    app = QtCore.QCoreApplication.instance()
    if app is None:
        app = QtGui.QApplication(sys.argv)
        app_created = True
    app.references = set()

    # Backwards compatibility
    for d in data:
        if len(d) == 4 and (isinstance(d[-1], Iterable) and
                            not isinstance(d[-1], StringTypes)):
            d[-2] = {'xname': d[-2], 'labels': d[-1]}
            d.pop()
        elif len(d) >= 3 and isinstance(d[2], basestring):
            if len(d) == 3:
                d[-1] = {'xname': d[-1]}
            else:
                d[-1]['xname'] = d[-1].get('xname', d[2])
                d.pop(2)

    i = Interact(data, kwargs.get('title', None))
    app.references.add(i)
    i.show()
    i.raise_()
    if app_created:
        app.exec_()


def main():
    time = np.linspace(0, 10)
    d = {
        'time': time,
        'x': np.cos(time),
        'y': np.sin(time),
    }
    create([d, 'data', 'time', {'yname': 'x', 'yscale': 3.0}])


if __name__ == '__main__':
    main()
