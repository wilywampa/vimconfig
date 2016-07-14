from __future__ import division, print_function
import ast
import matplotlib as mpl
import numpy as np
import re
import sys
from PyQt4 import QtCore, QtGui
from PyQt4.QtCore import SIGNAL
from collections import OrderedDict
from itertools import cycle, product
from matplotlib.backend_bases import key_press_handler
from matplotlib.backends.backend_qt4agg import (FigureCanvasQTAgg as
                                                FigureCanvas,
                                                NavigationToolbar2QT
                                                as NavigationToolbar)
from matplotlib.figure import Figure
from mplpicker import picker
from six import string_types, text_type


QString = str if text_type is str else QtCore.QString
PROPERTIES = ('color', 'linestyle', 'linewidth', 'alpha', 'marker',
              'markersize', 'markerfacecolor', 'markevery', 'antialiased',
              'dash_capstyle', 'dash_joinstyle', 'drawstyle', 'fillstyle',
              'markeredgecolor', 'markeredgewidth', 'markerfacecoloralt',
              'pickradius', 'solid_capstyle', 'solid_joinstyle')
ALIASES = dict(aa='antialiased', c='color', ec='edgecolor', fc='facecolor',
               ls='linestyle', lw='linewidth', mew='markeredgewidth')
try:
    import scipy.constants as const
except ImportError:
    CONSTANTS = dict(r2d=np.rad2deg(1), d2r=np.deg2rad(1))
else:
    CONSTANTS = {k: v for k, v in const.__dict__.items()
                 if isinstance(v, float)}
    CONSTANTS.update(dict(d2r=const.degree,
                          nmi=const.nautical_mile,
                          r2d=1.0 / const.degree,
                          psf=const.pound_force / (const.foot ** 2)))
try:
    color_cycle = list(OrderedDict.fromkeys(
        x['color'] for x in mpl.rcParams['axes.prop_cycle']))
except KeyError:
    color_cycle = mpl.rcParams['axes.color_cycle']
linestyle_cycle = '-', '--', '-.', ':'

if sys.platform == 'darwin':
    CONTROL_MODIFIER = QtCore.Qt.MetaModifier
else:
    CONTROL_MODIFIER = QtCore.Qt.ControlModifier


def flatten(d, ndim=None, prefix=''):
    """Join nested keys with '.' and unstack arrays."""
    if ndim is None:
        ndim = next(iter(sorted(
            v.ndim for v in d.values()
            if isinstance(v, np.ndarray))), None)
    out = {}
    for key, value in d.items():
        key = (prefix + '.' if prefix else '') + key
        if isinstance(value, dict):
            out.update(flatten(value, ndim=ndim, prefix=key))
        else:
            out[key] = value
            if isinstance(value, np.ndarray) and value.ndim > ndim:
                queue = [key]
                while queue:
                    key = queue.pop()
                    array = out.pop(key)
                    new = {key + '[%d]' % i: a
                           for i, a in enumerate(array)}
                    out.update(new)
                    queue.extend(q for q in new.keys() if new[q].ndim > ndim)
    return out


def isiterable(obj):
    """Check if an object is iterable (but not a string)."""
    if isinstance(obj, string_types):
        return False
    return hasattr(obj, '__iter__')


def props_repr(value):
    if isinstance(value, text_type) and not isinstance(value, str):
        value = str(value)
    return repr(value)


def dict_repr(d, top=True):
    if isinstance(d, dict):
        return ('{}' if top else 'dict({})').format(', '.join(
            ['{}={}'.format(k, dict_repr(v, False)) for k, v in d.items()]))
    elif isinstance(d, string_types):
        return repr(str(d))
    return repr(d)


class KeyHandlerMixin(object):

    def __init__(self, *args, **kwargs):
        self.parent = kwargs['parent']
        super(KeyHandlerMixin, self).__init__(*args, **kwargs)
        self._lineEdit = self.lineEdit() if hasattr(self, 'lineEdit') else self

    def select_all(self, event):
        return self._lineEdit.selectAll()

    def quit(self, event):
        self.emit(SIGNAL('closed()'))
        self.window().close()
        while not isinstance(self, Interact):
            try:
                self = self.parent
            except AttributeError:
                return
        self._close()

    def move_cursor(self, event):
        if event.key() == QtCore.Qt.Key_Home:
            if event.modifiers() == QtCore.Qt.ShiftModifier:
                self._lineEdit.cursorBackward(True, len(self._lineEdit.text()))
            else:
                self._lineEdit.setCursorPosition(0)
        elif event.key() == QtCore.Qt.Key_End:
            if event.modifiers() == QtCore.Qt.ShiftModifier:
                self._lineEdit.cursorForward(True, len(self._lineEdit.text()))
            else:
                self._lineEdit.setCursorPosition(len(self._lineEdit.text()))
        else:
            return False
        return True

    def delete_word(self, event):
        if self._lineEdit.selectionStart() == -1:
            self._lineEdit.cursorWordBackward(True)
            self._lineEdit.backspace()

    def event(self, event):
        control_actions = {
            QtCore.Qt.Key_A: self.select_all,
            QtCore.Qt.Key_D: 'remove()',
            QtCore.Qt.Key_E: 'axisequal()',
            QtCore.Qt.Key_L: 'relabel()',
            QtCore.Qt.Key_N: 'duplicate()',
            QtCore.Qt.Key_P: 'edit_props()',
            QtCore.Qt.Key_Q: self.quit,
            QtCore.Qt.Key_S: 'sync()',
            QtCore.Qt.Key_T: 'twin()',
            QtCore.Qt.Key_W: self.delete_word,
            QtCore.Qt.Key_X: 'xlim()',
            QtCore.Qt.Key_Y: 'ylim()',
            QtCore.Qt.Key_Return: 'sync()',
        }

        if event.type() == QtCore.QEvent.KeyPress:
            if (event.modifiers() == CONTROL_MODIFIER and
                    event.key() in control_actions):
                action = control_actions[event.key()]
                try:
                    action(event)
                except TypeError:
                    self.emit(SIGNAL(action))
                return True
            elif (event.modifiers() ==
                  CONTROL_MODIFIER | QtCore.Qt.ShiftModifier and
                  event.key() == QtCore.Qt.Key_S):
                self.emit(SIGNAL('sync_axis()'))
            elif event.key() in (QtCore.Qt.Key_Home,
                                 QtCore.Qt.Key_End):
                return self.move_cursor(event)
            elif self.completer.popup().viewport().isVisible():
                if event.key() == QtCore.Qt.Key_Tab:
                    self.emit(SIGNAL('tabPressed(int)'), 1)
                    return True
                elif event.key() == QtCore.Qt.Key_Backtab:
                    self.emit(SIGNAL('tabPressed(int)'), -1)
                    return True
                elif event.key() == QtCore.Qt.Key_Return:
                    self.emit(SIGNAL('returnPressed()'))

        return super(KeyHandlerMixin, self).event(event)


class KeyHandlerLineEdit(KeyHandlerMixin, QtGui.QLineEdit):
    pass


class TabCompleter(QtGui.QCompleter):

    def __init__(self, words, *args, **kwargs):
        QtGui.QCompleter.__init__(self, words, *args, **kwargs)
        self.setMaxVisibleItems(50)
        self.words = words
        self.skip = False
        self.skip_text = None
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
            text = text_type(self.textbox.currentText())
        except AttributeError:
            if self.skip_text is not None:
                self.skip = True
                return self.emit(SIGNAL('activated(QString)'), self.skip_text)
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
            QtCore.Qt.CaseSensitive if re.search(
                '[A-Z]', self.local_completion_prefix)
            else QtCore.Qt.CaseInsensitive,
            QtCore.QRegExp.RegExp)

        self.filterProxyModel.setFilterRegExp(pattern)

    def splitPath(self, path):
        words = [text_type(QtCore.QRegExp.escape(word.replace(r'\ ', ' ')))
                 for word in re.split(r'(?<!\\)\s+', text_type(path))]

        includes = [re.sub(r'^\\\\!', '!', word) for word in words
                    if not word.startswith('!')]
        excludes = [word[1:] for word in words
                    if len(word) > 1 and word.startswith('!')]

        self.local_completion_prefix = QString(
            '^' + ''.join('(?=.*%s)' % word for word in includes) +
            ''.join('(?!.*%s)' % word for word in excludes) + '.+')

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


class KeyHandlerComboBox(KeyHandlerMixin, AutoCompleteComboBox):
    pass


class PropertyEditor(QtGui.QTableWidget):

    def __init__(self, parent, *args, **kwargs):
        super(PropertyEditor, self).__init__(*args, **kwargs)
        self.setFixedSize(300, 400)
        self.setSizePolicy(QtGui.QSizePolicy.Expanding,
                           QtGui.QSizePolicy.Expanding)
        self.setColumnCount(2)
        self.setHorizontalHeaderLabels(['property', 'value'])
        self.parent = parent
        self.dataobj = None
        self.setRowCount(len(PROPERTIES))
        self.setCurrentCell(0, 1)
        self.horizontalHeader().setResizeMode(QtGui.QHeaderView.Stretch)
        self.horizontalHeader().setStretchLastSection(True)
        self.move(0, 0)

    def closeEvent(self, event):
        self.parent.draw()

    def hideEvent(self, event):
        self.parent.draw()

    def focusNextPrevChild(self, next):
        self.setCurrentCell((
            self.currentRow() + (1 if next else - 1)) % self.rowCount(), 1)

    def confirm(self, draw=True):
        cell = self.currentRow(), self.currentColumn()
        self.setCurrentItem(None)
        self.setCurrentCell(*cell)
        if draw:
            self.parent.draw()

    def cycle_editors(self, direction):
        self.confirm(draw=False)
        try:
            index = (self.parent.datas.index(
                self.dataobj) + direction) % len(self.parent.datas)
        except ValueError:
            index = 0
        self.parent.datas[index].edit_props()

    control_actions = {
        QtCore.Qt.Key_J: lambda self: self.focusNextPrevChild(True),
        QtCore.Qt.Key_K: lambda self: self.focusNextPrevChild(False),
        QtCore.Qt.Key_L: lambda self: self.confirm(),
        QtCore.Qt.Key_N: lambda self: self.cycle_editors(1),
        QtCore.Qt.Key_P: lambda self: self.cycle_editors(-1),
        QtCore.Qt.Key_Q: lambda self: self.close(),
        QtCore.Qt.Key_W: lambda self: self.close(),
    }

    def keyPressEvent(self, e):
        if self.state() == self.EditingState:
            if e.key() in (QtCore.Qt.Key_Down, QtCore.Qt.Key_Up):
                return self.focusNextPrevChild(e.key() == QtCore.Qt.Key_Down)
        return super(PropertyEditor, self).keyPressEvent(e)

    def event(self, event):
        if (event.type() == QtCore.QEvent.KeyPress and
            event.modifiers() == CONTROL_MODIFIER and
                event.key() in self.control_actions):
            self.control_actions[event.key()](self)
            return True
        elif (event.type() == QtCore.QEvent.KeyPress and
              self.state() == self.NoState and
              event.key() in (QtCore.Qt.Key_Delete,
                              QtCore.Qt.Key_Backspace)):
            self.setItem(self.currentRow(),
                         self.currentColumn(),
                         QtGui.QTableWidgetItem(''))
            return True
        elif (event.type() == QtCore.QEvent.ShortcutOverride and
              self.state() == self.EditingState and
              event.key() in (QtCore.Qt.Key_Down, QtCore.Qt.Key_Up)):
            self.focusNextPrevChild(event.key() == QtCore.Qt.Key_Down)
            return True
        try:
            return super(PropertyEditor, self).event(event)
        except TypeError:
            return False


class DataObj(object):

    def __init__(self, parent, obj, name, **kwargs):
        self.parent = parent
        self.name = name
        self.widgets = []
        self.twin = False
        self.props = kwargs.get('props', {}).copy()
        if isinstance(obj, np.ndarray):
            obj = {n: obj[n] for n in obj.dtype.names}
        self.obj = flatten(obj, ndim=self.guess_ndim(obj, kwargs))
        self.label = QtGui.QLabel('', parent=self.parent)
        self._labels = getattr(obj, 'labels', kwargs.get('labels', None))
        self.choose_label()

        draw = self.parent.draw
        connect = self.parent.connect

        self.scale_label = QtGui.QLabel('scale:', parent=self.parent)
        self.xscale_label = QtGui.QLabel('scale:', parent=self.parent)

        words = [k for k in self.obj.keys()
                 if isinstance(self.obj[k], np.ndarray)]
        words.sort(key=parent.sortkey)

        def new_text_box():
            menu = KeyHandlerComboBox(parent=self.parent)
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
        self.xmenu.setModel(words + ['_'])

        self.menu.setCurrentIndex(0)
        self.xmenu.setCurrentIndex(0)
        self.xlabel = QtGui.QLabel('x axis:', parent=self.parent)

        words = sorted(CONSTANTS.keys(), key=lambda w: w.lower())

        def new_scale_box():
            scale_compl = TabCompleter(words, parent=self.parent)
            scale_box = KeyHandlerLineEdit(parent=self.parent)
            scale_box.completer = scale_compl
            scale_box.setMinimumWidth(100)
            scale_compl.setWidget(scale_box)
            scale_box.setText('1.0')
            scale_compl.set_textbox(scale_box)

            def text_edited(text):
                scale_compl.skip_text = None
                if scale_compl.skip:
                    scale_compl.skip = False
                    return
                cursor_pos = scale_box.cursorPosition()
                text = text_type(scale_box.text())[:cursor_pos]
                prefix = re.split(r'\W', text)[-1].strip()
                scale_compl.setCompletionPrefix(prefix)
                scale_compl.complete()
                scale_compl.select_completion(0)

            def complete_text(text):
                if not scale_box.text():
                    return scale_box.setText(u'1.0')
                text = text_type(text)
                cursor_pos = scale_box.cursorPosition()
                before_text = text_type(scale_box.text())[:cursor_pos]
                after_text = text_type(scale_box.text())[cursor_pos:]
                prefix_len = len(re.split(r'\W', before_text)[-1].strip())
                part = before_text[-prefix_len:] if prefix_len else ''
                if not part and scale_compl.skip_text:
                    part = scale_compl.skip_text[0]
                if part and text.startswith(part):
                    scale_box.setText(before_text[:cursor_pos - prefix_len] +
                                      text + after_text)
                    scale_box.setCursorPosition(cursor_pos -
                                                prefix_len + len(text))

            def highlight(text):
                scale_compl.skip_text = text

            connect(scale_box, SIGNAL('editingFinished()'), draw)
            connect(scale_box, SIGNAL('textEdited(QString)'), text_edited)
            connect(scale_compl, SIGNAL('activated(QString)'), complete_text)
            connect(scale_compl, SIGNAL('highlighted(QString)'), highlight)

            return scale_box, scale_compl

        self.scale_box, self.scale_compl = new_scale_box()
        self.xscale_box, self.xscale_compl = new_scale_box()

        self.kwargs = kwargs
        self.process_kwargs()

    def choose_label(self):
        names = [d.name for d in self.parent.datas if d is not self]
        if self.name in names:
            labels = [text_type(d.label.text()).rstrip(':')
                      for d in self.parent.datas if d is not self]
            i = -1
            label = self.name
            while label in labels:
                i += 1
                label = '{} ({})'.format(self.name, i)
        else:
            label = self.name
        self.label.setText(label + ':')
        if self._labels is None:
            self.labels = getattr(self.obj, 'labels', label)
        else:
            self.labels = self._labels

    def guess_ndim(self, obj, kwargs):
        if isinstance(kwargs.get('ndim', None), int):
            return kwargs['ndim']
        for key in 'yname', 'xname':
            try:
                return obj[kwargs[key]].ndim
            except (AttributeError, KeyError, IndexError):
                pass
        try:
            return min(v.ndim for v in obj.values()
                       if isinstance(v, np.ndarray))
        except ValueError:
            return None

    def set_xname(self, xname):
        index = self.menu.findText(xname)
        if index >= 0:
            self.xmenu.setCurrentIndex(index)
        return index >= 0

    def set_xscale(self, xscale):
        self.xscale_box.setText(text_type(xscale))

    def set_yname(self, yname):
        index = self.menu.findText(yname)
        if index >= 0:
            self.menu.setCurrentIndex(index)
        return index >= 0

    def set_yscale(self, yscale):
        self.scale_box.setText(text_type(yscale))

    def process_kwargs(self):
        for k, v in self.kwargs.items():
            k = ALIASES.get(k, k)
            if k in PROPERTIES:
                self.props[k] = v
            else:
                getattr(self, 'set_' + k, lambda _: None)(v)

        for alias, prop in ALIASES.items():
            if alias in self.props:
                self.props[prop] = self.props.get(prop, self.props.pop(alias))

        for k in 'c', 'color', 'linestyle', 'ls':
            self.kwargs.pop(k, None)

        if 'cdata' in self.kwargs:
            self.cdata = np.squeeze(self.kwargs['cdata'])
            self.norm = self.kwargs.get(
                'norm', mpl.colors.Normalize(self.cdata.min(),
                                             self.cdata.max()))
            if not isinstance(self.norm, mpl.colors.Normalize):
                self.norm = mpl.colors.Normalize(*self.norm)
            self.cmap = mpl.cm.get_cmap(self.kwargs.get('cmap', 'rainbow'))

    def duplicate(self):
        kwargs = self.kwargs.copy()
        kwargs['props'] = self.props.copy()
        if kwargs['props'].get('linestyle', None) in linestyle_cycle:
            kwargs['props']['linestyle'] = (2 * linestyle_cycle)[
                linestyle_cycle.index(kwargs['props']['linestyle']) + 1]
        elif kwargs['props'].get('color', None) in color_cycle:
            kwargs['props']['color'] = (2 * color_cycle)[
                color_cycle.index(kwargs['props']['color']) + 1]
        self.parent.add_data(self.obj, self.name, kwargs=kwargs)
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
        text, ok = QtGui.QInputDialog.getText(
            self.parent, 'Rename data object', 'New label:',
            QtGui.QLineEdit.Normal, self.name)
        if ok and text_type(text):
            self.name = text_type(text)
            self.choose_label()
            if not isiterable(self.labels):
                self.labels = self.name
            self.parent.draw()

    def edit_props(self):
        props_editor = self.parent.props_editor
        try:
            props_editor.itemChanged.disconnect()
        except TypeError:
            pass
        props_editor.dataobj = self
        for i, k in enumerate(PROPERTIES):
            item = QtGui.QTableWidgetItem(k)
            item.setFlags(QtCore.Qt.ItemIsEditable)
            props_editor.setItem(i, 0, item)
            props_editor.setItem(i, 1, QtGui.QTableWidgetItem(
                props_repr(self.props[k]) if k in self.props else ''))
        props_editor.setWindowTitle(text_type(self.label.text()))
        props_editor.itemChanged.connect(self.update_props)
        props_editor.show()

    def update_props(self, item):
        if self.parent.props_editor.dataobj is not self:
            return
        row = item.row()
        key = text_type(self.parent.props_editor.item(row, 0).text())
        value = self.parent.props_editor.item(row, 1)
        if value:
            try:
                value = ast.literal_eval(text_type(value.text()))
            except (SyntaxError, ValueError):
                value = text_type(value.text())
            if key in self.props and self.props[key] == value:
                return
            elif value == '' and key in self.props:
                del self.props[key]
            elif str(value):
                self.props[key] = value
                self.parent.props_editor.setItem(
                    row, 1, QtGui.QTableWidgetItem(props_repr(value)))

    def close(self):
        self.parent.props_editor.close()

    def toggle_twin(self):
        self.twin = not self.twin
        self.parent.draw()

    def sync(self, axes='xy'):
        for completer in (self.completer, self.xcompleter,
                          self.scale_compl, self.xscale_compl):
            completer.close_popup()
        for ax in axes:
            menu, scale = (self.xmenu, self.xscale_box) if ax == 'x' else (
                self.menu, self.scale_box)
            for d in self.parent.datas:
                if getattr(d, 'set_%sname' % ax)(
                        text_type(menu.lineEdit().text())):
                    getattr(d, 'set_%sscale' % ax)(text_type(scale.text()))
        self.parent.draw()


class Interact(QtGui.QMainWindow):

    def __init__(self, data, app, title=None, sortkey=None, axisequal=False,
                 parent=None, **kwargs):
        self.app = app
        QtGui.QMainWindow.__init__(self, parent)
        self.setAttribute(QtCore.Qt.WA_DeleteOnClose, True)
        self.setWindowTitle(title or ', '.join(d[1] for d in data))
        if sortkey is not None:
            self.sortkey = sortkey
        else:
            self.sortkey = kwargs.get('key', lambda x: x.lower())
        self.grid = QtGui.QGridLayout()

        self.frame = QtGui.QWidget()
        self.dpi = 100

        self.fig = Figure(tight_layout=True)
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
        self.axisequal = axisequal
        self.margins = 0

        self.mpl_toolbar = NavigationToolbar(self.canvas, self.frame)
        self.pickers = None

        self.vbox = QtGui.QVBoxLayout()
        self.vbox.addWidget(self.mpl_toolbar)

        self.props_editor = PropertyEditor(self)

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
        kwargs = kwargs or {}
        kwargs['name'] = kwargs.get('name', name) or 'data'
        self.datas.append(DataObj(self, obj, **kwargs))
        data = self.datas[-1]

        self.row = self.grid.rowCount()
        self.column = 0

        def axisequal():
            self.axisequal = not self.axisequal
            self.draw()

        def add_widget(w, axis=None):
            self.grid.addWidget(w, self.row, self.column)
            data.widgets.append(w)
            self.connect(w, SIGNAL('duplicate()'), data.duplicate)
            self.connect(w, SIGNAL('remove()'), data.remove)
            self.connect(w, SIGNAL('closed()'), data.close)
            self.connect(w, SIGNAL('axisequal()'), axisequal)
            self.connect(w, SIGNAL('relabel()'), data.change_label)
            self.connect(w, SIGNAL('edit_props()'), data.edit_props)
            self.connect(w, SIGNAL('sync()'), data.sync)
            self.connect(w, SIGNAL('twin()'), data.toggle_twin)
            self.connect(w, SIGNAL('xlim()'), self.set_xlim)
            self.connect(w, SIGNAL('ylim()'), self.set_ylim)
            if axis:
                self.connect(w, SIGNAL('sync_axis()'),
                             lambda axes=[axis]: data.sync(axes))
            self.column += 1

        add_widget(data.label)
        add_widget(data.menu, 'y')
        add_widget(data.scale_label)
        add_widget(data.scale_box, 'y')
        add_widget(data.xlabel)
        add_widget(data.xmenu, 'x')
        add_widget(data.xscale_label)
        add_widget(data.xscale_box, 'x')

    def warn(self, message):
        self.warnings = {message}
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

        if self.props_editor.dataobj is data:
            self.props_editor.close()

        self.set_layout()
        self.draw()
        self.datas[index - 1].menu.setFocus()
        self.datas[index - 1].menu.lineEdit().selectAll()

    def get_scale(self, textbox, completer):
        completer.close_popup()
        text = text_type(textbox.text())
        try:
            return eval(text, CONSTANTS.copy())
        except Exception as e:
            self.warnings.add('Error setting scale: ' + text_type(e))
            return 1.0

    def get_key(self, menu):
        key = text_type(menu.itemText(menu.currentIndex()))
        text = text_type(menu.lineEdit().text())
        if key != text:
            self.warnings.add(
                'Plotted key (%s) does not match typed key (%s)' %
                (key, text))
        return key

    @staticmethod
    def cla(axes):
        tight, xmargin, ymargin = axes._tight, axes._xmargin, axes._ymargin
        axes.clear()
        axes._tight, axes._xmargin, axes._ymargin = tight, xmargin, ymargin

    def clear_pickers(self):
        if self.pickers:
            [p.disable() for p in self.pickers]
            self.pickers = None

    def plot(self, axes, data):
        xscale = self.get_scale(data.xscale_box, data.xscale_compl)
        yscale = self.get_scale(data.scale_box, data.scale_compl)
        xname = self.get_key(data.xmenu)
        yname = self.get_key(data.menu)

        if xname in data.obj:
            x = data.obj[xname] * xscale
        y = data.obj[yname] * yscale

        if xname in data.obj and x.shape[0] in y.shape:
            xaxis = y.shape.index(x.shape[0])
            lines = axes.plot(x, np.rollaxis(y, xaxis))
        else:
            if xname in data.obj:
                self.warnings.add(
                    '{} {} and {} {} have incompatible dimensions'.format(
                        xname, x.shape, yname, y.shape))
            lines = axes.plot(y)

        if not isiterable(data.labels):
            if len(lines) > 1:
                data.labels = ['%s %d' % (data.labels, i)
                               for i in range(len(lines))]
            else:
                data.labels = [data.labels]

        for i, (line, label) in enumerate(zip(lines, data.labels)):
            line.set_label(label)
            if hasattr(data, 'cdata'):
                line.set_color(data.cmap(data.norm(data.cdata[i])))
                self.handles[(label,)] = line
            elif 'color' not in data.props and 'linestyle' not in data.props:
                style, color = next(self.styles)
                line.set_color(color)
                line.set_linestyle(style)
                self.handles[(label, color, style)] = line
            elif 'color' not in data.props:
                line.set_color(color_cycle[i % len(color_cycle)])
                self.handles[
                    (label, line.get_color(), data.props['linestyle'])] = line
            else:
                self.handles[
                    (label,
                     data.props.get('color', line.get_color()),
                     data.props.get('linestyle', line.get_linestyle()))] = line
            for key, value in data.props.items():
                getattr(line, 'set_' + key, lambda _: None)(value)

        return len(lines)

    def draw(self):
        self.mpl_toolbar.home = self.draw
        twin = any(d.twin for d in self.datas)
        self.clear_pickers()
        self.fig.clear()
        self.axes = self.fig.add_subplot(111)

        color_data = next((d for d in self.datas if hasattr(d, 'cdata')), None)
        if color_data and not twin:
            self.mappable = mpl.cm.ScalarMappable(norm=color_data.norm,
                                                  cmap=color_data.cmap)
            self.mappable.set_array(color_data.cdata)
            self.colorbar = self.fig.colorbar(
                self.mappable, ax=self.axes, fraction=0.1, pad=0.02)
        elif twin:
            self.axes2 = self.axes.twinx()

        for ax in self.axes, self.axes2:
            ax._tight = bool(self.margins)
            if self.margins:
                ax.margins(self.margins)

        xlabel = []
        ylabel = []
        xlabel2 = []
        ylabel2 = []
        self.warnings = set()
        self.handles = OrderedDict()
        self.styles = cycle(product(linestyle_cycle, color_cycle))
        for d in self.datas:
            if d.twin:
                axes, x, y = self.axes2, xlabel2, ylabel2
            else:
                axes, x, y = self.axes, xlabel, ylabel
            self.plot(axes, d)
            text = self.get_key(d.menu)
            xtext = self.get_key(d.xmenu)
            if xtext:
                x.append(xtext + ' (' + d.name + ')')
            y.append(text + ' (' + d.name + ')')

        self.axes.set_xlabel('\n'.join(xlabel))
        self.axes.set_ylabel('\n'.join(ylabel))
        self.draw_warnings()

        self.axes2.set_xlabel('\n'.join(xlabel2))
        self.axes2.set_ylabel('\n'.join(ylabel2))

        self.axes.set_xlim(self.xlim)
        self.axes.set_ylim(self.ylim)
        self.axes.set_xscale(self.xlogscale)
        self.axes.set_yscale(self.ylogscale)

        for ax in self.axes, self.axes2:
            ax.set_aspect('equal' if self.axisequal else 'auto', 'box-forced')
        legend = self.axes.legend(self.handles.values(),
                                  [k[0] for k in self.handles.keys()])
        legend.draggable(True)
        self.pickers = [picker(ax) for ax in [self.axes, self.axes2]]

        self.canvas.draw()

    def draw_warnings(self):
        self.axes.text(0.05, 0.05, '\n'.join(self.warnings),
                       transform=self.axes.transAxes, color='red')

    def canvas_key_press(self, event):
        key_press_handler(event, self.canvas, self.mpl_toolbar)
        if event.key == 'ctrl+q':
            self._close()
        elif event.key in mpl.rcParams['keymap.home']:
            self.xlim = self.ylim = None
            self.draw()
        elif event.key == 'ctrl+x':
            self.set_xlim(draw=False)
        elif event.key == 'ctrl+y':
            self.set_ylim(draw=False)
        elif event.key == 'ctrl+l':
            self.draw()
        self.xlogscale = self.axes.get_xscale()
        self.ylogscale = self.axes.get_yscale()

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
        self.margins = 0 if self.margins else 0.05
        self.draw()

    def _close(self):
        self.app.references.discard(self)
        self.window().close()

    def _input_lim(self, axis, default):
        default = text_type(default)
        if re.match(r'^\(.*\)$', default) or re.match(r'^\[.*\]$', default):
            default = default[1:-1]
        text, ok = QtGui.QInputDialog.getText(
            self, 'Set axis limits', '{} limits:'.format(axis),
            QtGui.QLineEdit.Normal, default)
        if ok:
            try:
                return eval(text_type(text), CONSTANTS.copy())
            except Exception:
                return None
        else:
            return None

    def set_xlim(self, draw=True):
        self.xlim = self._input_lim(
            'x', self.xlim or self.axes.get_xlim())
        if draw:
            self.draw()

    def set_ylim(self, draw=True):
        self.ylim = self._input_lim(
            'y', self.ylim or self.axes.get_ylim())
        if draw:
            self.draw()

    @staticmethod
    def data_dict(d):
        kwargs = OrderedDict((
            ('name', d.name),
            ('xname', text_type(d.xmenu.lineEdit().text())),
            ('xscale', text_type(d.xscale_box.text())),
            ('yname', text_type(d.menu.lineEdit().text())),
            ('yscale', text_type(d.scale_box.text())),
            ('props', d.props),
            ('labels', d.labels),
        ))
        for key in 'xscale', 'yscale':
            try:
                kwargs[key] = ast.literal_eval(kwargs[key])
            except ValueError:
                pass
            else:
                if float(kwargs[key]) == 1.0:
                    del kwargs[key]
        if not kwargs['props']:
            del kwargs['props']
        return kwargs

    def data_dicts(self):
        return "\n".join(text_type(dict_repr(self.data_dict(d)))
                         for d in self.datas)

    def event(self, event):
        control_actions = {
            QtCore.Qt.Key_M: self._margins,
            QtCore.Qt.Key_O: self.edit_parameters,
            QtCore.Qt.Key_Q: self._close,
        }

        if (event.type() == QtCore.QEvent.KeyPress and
            event.modifiers() == CONTROL_MODIFIER and
                event.key() in control_actions):
            control_actions[event.key()]()
            return True

        # Create duplicate of entire GUI with Ctrl+Shift+N
        elif (event.type() == QtCore.QEvent.KeyPress and
              event.modifiers() ==
              CONTROL_MODIFIER | QtCore.Qt.ShiftModifier and
              event.key() == QtCore.Qt.Key_N):
            create(*[[d.obj, d.name, self.data_dict(d)] for d in self.datas])
            return True

        # Print dictionaries of keys and scales for all data with Ctrl+Shift+P
        elif (event.type() == QtCore.QEvent.KeyPress and
              event.modifiers() ==
              CONTROL_MODIFIER | QtCore.Qt.ShiftModifier and
              event.key() == QtCore.Qt.Key_P):
            print(self.data_dicts())
            sys.stdout.flush()
            return True
        return super(Interact, self).event(event)


def merge_dicts(*dicts):
    """Pad and concatenate arrays present in all input dictionaries."""
    sets = [set(d.keys()) for d in dicts]
    keys = sets[0].intersection(*sets)

    def validate(array):
        return (isinstance(array, np.ndarray) and
                (np.issubdtype(array.dtype, np.number) or
                 np.issubdtype(array.dtype, np.bool_))
                and np.squeeze(array).ndim == 1)

    def pad(array):
        return np.pad(np.squeeze(array), (0, length - array.size),
                      mode='constant', constant_values=(float('nan'),))

    merged = {}
    for key in keys:
        if all(validate(d[key]) for d in dicts):
            length = max(len(d[key]) for d in dicts)
            merged[key] = np.array([pad(d[key]) for d in dicts]).T
        elif all(isinstance(d[key], dict) for d in dicts):
            merged[key] = merge_dicts(*[d[key] for d in dicts])

    return merged


def dataobj(data, name='',
            xname=None, yname=None,
            xscale=None, yscale=None,
            labels=None, props=None, ndim=None,
            cdata=None, cmap=None, norm=None, **kwargs):
    locals().update(kwargs)
    return [data, name,
            {k: v for k, v in locals().items()
             if k not in ('data', 'name') and v is not None}]


def create(*data, **kwargs):
    """
    Create an interactive plot window for the given data.

    >>> create(dataobj(dict1, 'Title1', 'XaxisKey1',
    ...        labels=['a', 'b'], xscale='1/degree'),
    ...        dataobj(dict2, 'Title2'))

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
    app.references = getattr(app, 'references', set())

    # Backwards compatibility
    data = list(data)
    for i, d in enumerate(data):
        if isinstance(d, dict):
            data[i] = [d, '']
        elif isinstance(d, np.ndarray) and isiterable(d.dtype.names):
            data[i] = [{n: d[n] for n in d.dtype.names}, '']
        elif isiterable(d[-1]) and len(d) == 4:
            d[-2] = {'xname': d[-2], 'labels': list(d[-1])}
            d.pop()
        elif isinstance(d[2], string_types) and len(d) >= 3:
            if len(d) == 3:
                d[-1] = {'xname': d[-1]}
            else:
                d[-1]['xname'] = d[-1].get('xname', d[2])
                d.pop(2)

    interactive = mpl.is_interactive()
    try:
        mpl.interactive(False)
        i = Interact(data, app, **kwargs)
    finally:
        mpl.interactive(interactive)
    app.references.add(i)
    i.show()
    i.raise_()
    if app_created:
        app.exec_()
    return i


def main():
    time = np.linspace(0, 10)
    d = {'time': time, 'x': np.cos(time), 'y': np.sin(time)}
    create(dataobj(d, 'data', 'time', yname='x', yscale=3.0))


if __name__ == '__main__':
    main()
