# -*- coding: utf-8 -*-
from __future__ import division, print_function
import ast
import collections
import copy
import logging
import matplotlib as mpl
import numpy as np
import re
import sys
from PyQt5 import QtCore, QtGui, QtWidgets
from PyQt5.QtCore import pyqtSignal
from collections import OrderedDict
from cycler import cycler
from itertools import chain, count, cycle, tee
from matplotlib.backend_bases import key_press_handler
from matplotlib.backends.backend_qt5agg import (FigureCanvasQTAgg as
                                                FigureCanvas,
                                                NavigationToolbar2QT
                                                as NavigationToolbar)
from matplotlib.figure import Figure
from mplpicker import picker
from six import string_types, text_type
logger = logging.getLogger('plotinteract')

try:
    QString = unicode
except NameError:
    QString = str

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

if sys.platform == 'darwin':
    CONTROL_MODIFIER = QtCore.Qt.MetaModifier
else:
    CONTROL_MODIFIER = QtCore.Qt.ControlModifier

IDENTIFIER_RE = re.compile('^[A-Za-z_][A-Za-z0-9_]*$')
KEYWORDS_RE = re.compile(r'\b[a-zA-Z_]\w*(?:\.[a-zA-Z_]\w*)*\.?')
EvalResult = collections.namedtuple('EvalResult', 'value ok warnings')


def flatten(d, ndim=None, prefix=''):
    """Join nested keys with '.' and unstack arrays."""
    if ndim is None:
        ndim = next(iter(sorted(
            len(v.shape) for v in d.values() if hasattr(v, 'dtype'))), None)
    out = {}
    for key, value in d.items():
        key = (prefix + '.' if prefix else '') + key
        if isinstance(value, collections.Mapping):
            out.update(flatten(value, ndim=ndim, prefix=key))
        else:
            out[key] = value
            if hasattr(value, 'dtype') and len(value.shape) > ndim:
                queue = [key]
                while queue:
                    key = queue.pop()
                    array = out.pop(key)
                    new = {key + '[%d]' % i: a for i, a in enumerate(array)}
                    out.update(new)
                    queue.extend(q for q in new if len(new[q].shape) > ndim)
    return out


def isiterable(obj):
    """Check if an object is iterable (but not a string)."""
    if isinstance(obj, string_types):
        return False
    return hasattr(obj, '__iter__')


def unique(seq):
    seen = set()
    for item in seq:
        if item not in seen:
            seen.add(item)
            yield item


def nth_color_value(c):
    prop_cycler = mpl.rcParams['axes.prop_cycle']
    colors = prop_cycler.by_key().get('color', ['k'])
    return colors[int(c[1]) % len(colors)]


def props_repr(value):
    if isinstance(value, text_type) and not isinstance(value, str):
        value = str(value)
    return repr(value)


def process_props_format(props):
    props = dict(zip(('linestyle', 'marker', 'color'),
                     mpl.axes._base._process_plot_format(props)))
    for key, value in list(props.items()):
        if value is None or value == 'None':
            del props[key]
    return props


def dict_repr(d, top=True):
    if isinstance(d, dict):
        return ('{}' if top else 'dict({})').format(', '.join(
            ['{}={}'.format(k, dict_repr(v, False)) for k, v in d.items()]))
    elif isinstance(d, string_types):
        return repr(str(d))
    return repr(d)


class KeyHandlerMixin(object):

    axisEqual = pyqtSignal()
    closed = pyqtSignal()
    duplicate = pyqtSignal()
    editProps = pyqtSignal()
    editCdata = pyqtSignal()
    relabel = pyqtSignal()
    remove = pyqtSignal()
    returnPressed = pyqtSignal()
    sync = pyqtSignal()
    syncAxis = pyqtSignal()
    tabPressed = pyqtSignal(int)
    twin = pyqtSignal()
    xlim = pyqtSignal()
    ylim = pyqtSignal()

    def __init__(self, *args, **kwargs):
        self.parent = kwargs['parent']
        super(KeyHandlerMixin, self).__init__(*args, **kwargs)
        self._lineEdit = self.lineEdit() if hasattr(self, 'lineEdit') else self

    def select_all(self, event):
        return self._lineEdit.selectAll()

    def quit(self, event):
        self.closed.emit()
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
            QtCore.Qt.Key_D: 'remove',
            QtCore.Qt.Key_E: 'axisEqual',
            QtCore.Qt.Key_L: 'relabel',
            QtCore.Qt.Key_N: 'duplicate',
            QtCore.Qt.Key_P: 'editProps',
            QtCore.Qt.Key_Q: self.quit,
            QtCore.Qt.Key_S: 'sync',
            QtCore.Qt.Key_T: 'twin',
            QtCore.Qt.Key_W: self.delete_word,
            QtCore.Qt.Key_X: 'xlim',
            QtCore.Qt.Key_Y: 'ylim',
            QtCore.Qt.Key_Return: 'sync',
        }

        if event.type() == QtCore.QEvent.KeyPress:
            logger.debug('KeyPress %s', next(
                (k for k, v in QtCore.Qt.__dict__.items() if v == event.key()),
                None))
            if (event.modifiers() == CONTROL_MODIFIER and
                    event.key() in control_actions):
                action = control_actions[event.key()]
                try:
                    action(event)
                except TypeError:
                    getattr(self, action).emit()
                return True
            elif (event.modifiers() ==
                  CONTROL_MODIFIER | QtCore.Qt.ShiftModifier and
                  event.key() == QtCore.Qt.Key_C):
                self.editCdata.emit()
            elif (event.modifiers() ==
                  CONTROL_MODIFIER | QtCore.Qt.ShiftModifier and
                  event.key() == QtCore.Qt.Key_S):
                self.syncAxis.emit()
            elif event.key() in (QtCore.Qt.Key_Home,
                                 QtCore.Qt.Key_End):
                return self.move_cursor(event)
            elif event.key() == QtCore.Qt.Key_Return:
                self.returnPressed.emit()
            elif self.completer.popup().viewport().isVisible():
                if event.key() == QtCore.Qt.Key_Tab:
                    self.tabPressed.emit(1)
                    return True
                elif event.key() == QtCore.Qt.Key_Backtab:
                    self.tabPressed.emit(-1)
                    return True

        return super(KeyHandlerMixin, self).event(event)


class KeyHandlerLineEdit(KeyHandlerMixin, QtWidgets.QLineEdit):
    pass


class TabCompleter(QtWidgets.QCompleter):

    def __init__(self, words, *args, **kwargs):
        QtWidgets.QCompleter.__init__(self, words, *args, **kwargs)
        self.setMaxVisibleItems(50)
        self.words = words
        self.skip = False
        self.skip_text = None
        self.popup().activated.connect(self.confirm)

    def set_textbox(self, textbox):
        self.textbox = textbox
        self.textbox.tabPressed.connect(self.select_completion)
        self.textbox.closed.connect(self.close_popup)
        self.textbox.returnPressed.connect(self.confirm)

    def select_completion(self, direction):
        if not self.popup().selectionModel().hasSelection():
            if direction == 0:
                return
            direction = 0
        self.setCurrentRow((self.currentRow() + direction) %
                           self.completionCount())
        self.popup().setCurrentIndex(
            self.completionModel().index(self.currentRow(), 0))

    def close_popup(self):
        popup = self.popup()
        if popup.isVisible():
            self.confirm()
            popup.close()

    def confirm(self):
        logger.debug('TabCompleter confirm')
        try:
            text = text_type(self.textbox.currentText())
        except AttributeError:
            if self.skip_text is not None:
                self.skip = True
                self.activated.emit(self.skip_text)
        else:
            self.activated.emit(text)


class CustomQCompleter(TabCompleter):

    def __init__(self, parent, *args, **kwargs):
        super(CustomQCompleter, self).__init__(parent, *args, **kwargs)
        self.parent = parent
        self.local_completion_prefix = ''
        self.source_model = None
        self.filterProxyModel = QtCore.QSortFilterProxyModel(self)
        self.usingOriginalModel = False
        try:
            self.sortkey = parent.parent.sortkey
        except AttributeError:
            self.sortkey = str.lower

    def setModel(self, model):
        self.source_model = model
        self.filterProxyModel = QtCore.QSortFilterProxyModel(self)
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
            logger.debug('rowCount == 0')
            completions = set()
            model = self.source_model
            if model:
                # Find keys that complete any partial key in path
                keys = [model.data(model.index(i, 0))
                        for i in range(model.rowCount())]
                for m in KEYWORDS_RE.finditer(path):
                    word = m[0]
                    logger.debug('word = %s', m[0])
                    if word in keys:
                        continue
                    for key in keys:
                        if key.lower().startswith(word.lower()):
                            c = path[:m.start()] + key + path[m.end():]
                            while '.' in c and len(c) >= len(word):
                                completions.add(c)
                                c = c.rpartition('.')[0]
                            if len(c) >= len(word):
                                completions.add(c)
                logger.debug('completions = %r', completions)
            self.usingOriginalModel = False
            completions = sorted(completions, key=self.sortkey)
            self.filterProxyModel.setSourceModel(
                QtCore.QStringListModel(completions))
            self.filterProxyModel.setFilterRegExp(QtCore.QRegExp('.*'))
            return []

        return []


class AutoCompleteComboBox(QtWidgets.QComboBox):

    def __init__(self, *args, **kwargs):
        super(AutoCompleteComboBox, self).__init__(*args, **kwargs)

        self.setEditable(True)
        self.setInsertPolicy(self.NoInsert)

        self.completer = CustomQCompleter(self)
        self.completer.setCompletionMode(QtWidgets.QCompleter.PopupCompletion)
        self.setCompleter(self.completer)

    def setModel(self, strList):
        self.clear()
        self.insertItems(0, strList)
        self.completer.setModel(self.model())


class KeyHandlerComboBox(KeyHandlerMixin, AutoCompleteComboBox):
    pass


class PropertyEditor(QtWidgets.QTableWidget):

    def __init__(self, parent, *args, **kwargs):
        super(PropertyEditor, self).__init__(*args, **kwargs)
        self.setFixedSize(300, 400)
        self.setSizePolicy(QtWidgets.QSizePolicy.Expanding,
                           QtWidgets.QSizePolicy.Expanding)
        self.setColumnCount(2)
        self.setHorizontalHeaderLabels(['property', 'value'])
        self.parent = parent
        self.dataobj = None
        self.setRowCount(len(PROPERTIES))
        self.setCurrentCell(0, 1)
        self.horizontalHeader().setSectionResizeMode(
            QtWidgets.QHeaderView.Stretch)
        self.horizontalHeader().setStretchLastSection(True)
        self.move(0, 0)

    def closeEvent(self, event):
        self.parent.draw(keeplims=True)

    def hideEvent(self, event):
        self.parent.draw(keeplims=True)

    def confirm(self, draw=True):
        cell = self.currentRow(), self.currentColumn()
        self.setCurrentItem(None)
        self.setCurrentCell(*cell)
        if draw:
            self.parent.draw(keeplims=True)

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
                         QtWidgets.QTableWidgetItem(''))
            return True
        elif (event.type() == QtCore.QEvent.ShortcutOverride and
              self.state() == self.EditingState and
              event.key() in (QtCore.Qt.Key_Down, QtCore.Qt.Key_Up)):
            self.focusNextPrevChild(event.key() == QtCore.Qt.Key_Down)
            self.focusNextPrevChild(event.key() != QtCore.Qt.Key_Down)
            return True
        try:
            return super(PropertyEditor, self).event(event)
        except TypeError:
            return False


class ComboBoxDialog(QtWidgets.QInputDialog):

    @staticmethod
    def getComboBoxItem(parent, title, label, items,
                        text='', editable=True, flags=0, hints=0):
        dialog = QtWidgets.QInputDialog(
            parent, QtCore.Qt.WindowFlags(flags))
        dialog.setWindowTitle(title)
        dialog.setLabelText(label)
        dialog.setComboBoxItems(items)
        dialog.setComboBoxEditable(editable)
        dialog.setInputMethodHints(QtCore.Qt.InputMethodHints(hints))
        dialog.setTextValue(text)
        if dialog.exec_() == QtWidgets.QDialog.Accepted:
            return dialog.textValue(), True
        return text, False


class DataObj(object):

    def __init__(self, parent, obj, name, **kwargs):
        self.parent = parent
        self.name = name
        self.widgets = []
        self.twin = False
        self.props = kwargs.get('props', {})
        self.process_props()
        if hasattr(obj, 'dtype'):
            obj = {n: obj[n] for n in obj.dtype.names}
        self.obj = flatten(obj, ndim=self.guess_ndim(obj, kwargs))
        self.label = QtWidgets.QLabel('', parent=self.parent)
        self._labels = getattr(obj, 'labels', kwargs.get('labels', None))
        self.choose_label()

        draw = self.parent.draw

        self.scale_label = QtWidgets.QLabel('scale:', parent=self.parent)
        self.xscale_label = QtWidgets.QLabel('scale:', parent=self.parent)

        self.words = [k for k in self.obj if hasattr(self.obj[k], 'dtype')]
        self.words.sort(key=parent.sortkey)

        def new_text_box():
            menu = KeyHandlerComboBox(parent=self.parent)
            menu.setModel(self.words)
            menu.setSizePolicy(QtWidgets.QSizePolicy(
                QtWidgets.QSizePolicy.MinimumExpanding,
                QtWidgets.QSizePolicy.Fixed))
            menu.setMaxVisibleItems(50)
            completer = menu.completer
            completer.set_textbox(menu)

            menu.activated.connect(draw)
            completer.activated.connect(draw)

            return completer, menu

        self.completer, self.menu = new_text_box()
        self.xcompleter, self.xmenu = new_text_box()
        self.xmenu.setModel(self.words + ['_'])

        self.menu.setCurrentIndex(0)
        self.xmenu.setCurrentIndex(0)
        self.xlabel = QtWidgets.QLabel('x axis:', parent=self.parent)

        words = sorted(CONSTANTS, key=str.lower)

        def new_scale_box():
            scale_compl = TabCompleter(words, parent=self.parent)
            scale_box = KeyHandlerLineEdit(parent=self.parent)
            scale_box.completer = scale_compl
            scale_box.setFixedWidth(100)
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

            scale_box.returnPressed.connect(draw)
            scale_box.textEdited.connect(text_edited)
            scale_compl.activated.connect(complete_text)
            scale_compl.highlighted.connect(highlight)

            return scale_box, scale_compl

        self.scale_box, self.scale_compl = new_scale_box()
        self.xscale_box, self.xscale_compl = new_scale_box()

        self.kwargs = kwargs
        self.process_kwargs()
        self.process_cdata()

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
                return np.ndim(obj[kwargs[key]])
            except KeyError:
                pass
        try:
            return min(len(v.shape) for v in obj.values()
                       if hasattr(v, 'dtype'))
        except ValueError:
            return None

    def eval_key(self, text, cache=collections.OrderedDict()):
        if text in self.obj:
            return EvalResult(value=self.obj[text], ok=True, warnings=[])
        elif text == '_':
            return EvalResult(value=None, ok=False, warnings=[])

        cache_key = text
        try:
            return cache[cache_key]
        except KeyError:
            pass

        keys = set(self.obj)
        replace = {}
        for key, value in self.obj.items():
            if IDENTIFIER_RE.match(key) or key not in text:
                continue
            pattern = re.compile(r'\b' + re.escape(key) +
                                 r'(\b|(?=[^A-Za-z0-9_])|$)')
            var = '__' + str(next(i for i in count()
                                  if '__' + str(i) not in keys))
            keys.add(var)
            text = pattern.sub('(' + var + ')', text)
            replace[var] = value
        logger.debug('eval_key after text = %s', text)

        try:
            value = eval(
                text, {'np': np, 'numpy': np}, collections.ChainMap(
                    replace, self.obj, CONSTANTS, np.__dict__)), True, []
        except Exception as e:
            warning = 'Error evaluating key: ' + text_type(e)
            try:
                return EvalResult(value=self.obj[text_type(
                    self.menu.itemText(self.menu.currentIndex()))],
                    ok=False, warnings=[warning])
            except Exception:
                return EvalResult(value=None, ok=False, warnings=[warning])

        cache[cache_key] = value
        while len(cache) > 100:
            cache.popitem(last=False)
        return value

    @property
    def cdata(self):
        if isinstance(self._cdata, str):
            if not self._cdata:
                return None
            value, ok, _ = self.eval_key(self._cdata)
            if not ok:
                logger.warning('invalid cdata key: %r', self._cdata)
                self._cdata = None
                return
            return value
        return self._cdata

    @cdata.setter
    def cdata(self, value):
        logger.debug('cdata.setter %r', value)
        self._cdata = value

    def set_name(self, menu, name):
        index = self.menu.findText(name)
        if index >= 0:
            menu.setCurrentIndex(index)
        value, ok, warnings = self.eval_key(name)
        if ok:
            menu.setCurrentText(name)
        return ok

    def set_xname(self, xname):
        logger.debug('set_xname %r', xname)
        return self.set_name(self.xmenu, xname)

    def set_xscale(self, xscale):
        self.xscale_box.setText(text_type(xscale))

    def set_yname(self, yname):
        logger.debug('set_yname %r', yname)
        return self.set_name(self.menu, yname)

    def set_yscale(self, yscale):
        self.scale_box.setText(text_type(yscale))

    def process_kwargs(self):
        for k, v in self.kwargs.items():
            k = ALIASES.get(k, k)
            if k in PROPERTIES:
                for p in self.props:
                    p.setdefault(k, v)
            else:
                getattr(self, 'set_' + k, lambda _: None)(v)

        for alias, prop in ALIASES.items():
            for p in self.props:
                if alias in p:
                    p[prop] = p.get(prop, p.pop(alias))

        for k in 'c', 'color', 'linestyle', 'ls':
            self.kwargs.pop(k, None)

        for p in self.props:
            if mpl.colors._is_nth_color(p.get('color', None)):
                p['color'] = nth_color_value(p['color'])

    def process_cdata(self):
        self.cdata = self.kwargs.get('cdata', None)
        if self.cdata is not None:
            self.norm = self.kwargs.get('norm', None)
            if not self.norm:
                self.norm = np.nanmin(self.cdata), np.nanmax(self.cdata)
            if not isinstance(self.norm, mpl.colors.Normalize):
                self.norm = mpl.colors.Normalize(*self.norm)
            try:
                self.cmap = mpl.cm.get_cmap(
                    self.kwargs.get('cmap', mpl.rcParams['image.cmap']))
            except Exception:
                self.cmap = mpl.cm.jet

    def process_props(self):
        logger.debug('processing props: %s', self.props)
        if isinstance(self.props, dict):
            self.props = self.props.copy()
            if self.props:
                keys, values = zip(*self.props.items())
                if all(isinstance(vs, collections.Sized)
                       for vs in values) and all(len(vs) == len(values[0])
                                                 for vs in values):
                    self.props = [{} for v in values[0]]
                    for k, vs in zip(keys, values):
                        for p, v in zip(self.props, vs):
                            p[k] = v
                else:
                    self.props = [self.props.copy()]
            else:
                self.props = [self.props.copy()]
        elif isinstance(self.props, text_type):
            self.props = [process_props_format(self.props)]
        else:
            self.props = [process_props_format(p) if isinstance(p, text_type)
                          else p.copy() for p in self.props]

    def copy(self):
        kwargs = self.kwargs.copy()
        kwargs['props'] = copy.deepcopy(self.props)
        kwargs['xname'] = self.xmenu.lineEdit().text()
        kwargs['xscale'] = self.xscale_box.text()
        kwargs['yname'] = self.menu.lineEdit().text()
        kwargs['yscale'] = self.scale_box.text()
        kwargs.update({k: getattr(self, k, None)
                       for k in ('cdata', 'cmap', 'norm')})
        if isinstance(getattr(self, '_cdata', None), str):
            kwargs['cdata'] = self._cdata
        return dataobj(self.obj, name=self.name, **kwargs)

    def duplicate(self):
        data = self.copy()
        if self.parent.in_cycle(self):
            new_props = next(self.parent.props_iter)
            for p in data[-1]['props']:
                p.update(new_props)
        self.parent.add_data(*data)
        if len(self.parent.datas) == 2:
            self.parent.init_props()
        data = self.parent.datas[-1]
        self.parent.set_layout()
        data.menu.setFocus()
        data.menu.lineEdit().selectAll()

    def remove(self):
        self.parent.remove_data(self)

    def change_label(self):
        text, ok = QtWidgets.QInputDialog.getText(
            self.parent, 'Rename data object', 'New label:',
            QtWidgets.QLineEdit.Normal, self.name)
        if ok and text_type(text):
            self.name = text_type(text)
            self._labels = None
            self.choose_label()
            if not isiterable(self.labels):
                self.labels = self.name
            self.parent.draw()

    def edit_cdata(self):
        logger.debug('edit_cdata %r', getattr(self, '_cdata', None))
        text, ok = ComboBoxDialog.getComboBoxItem(
            parent=self.parent,
            title='Set color data',
            label='Color data key:',
            items=self.words,
            flags=QtWidgets.QLineEdit.Normal,
            text=self._cdata
            if isinstance(getattr(self, '_cdata', None), str)
            else '',
        )
        if not ok:
            return

        try:
            self.cdata = text
            self.props[0].pop('color', None)
            norm = getattr(self, 'norm', (np.nanmin(self.cdata),
                                          np.nanmax(self.cdata)))
            if not isinstance(norm, mpl.colors.Normalize):
                norm = mpl.colors.Normalize(*norm)
            text, ok = QtWidgets.QInputDialog.getText(
                self.parent, 'Set color limits', 'Color limits:',
                QtWidgets.QLineEdit.Normal, str((norm.vmin, norm.vmax)))
            if not ok:
                return
            try:
                self.norm = mpl.colors.Normalize(*ast.literal_eval(text))
            except Exception:
                self.norm = norm

            cmap = mpl.cm.get_cmap(
                getattr(self, 'cmap', mpl.rcParams['image.cmap']))
            text, ok = QtWidgets.QInputDialog.getText(
                self.parent, 'Set colormap', 'Colormap:',
                QtWidgets.QLineEdit.Normal, cmap.name)
            if not ok:
                return
            try:
                self.cmap = mpl.cm.get_cmap(text)
            except Exception:
                self.cmap = cmap
        finally:
            if not hasattr(self, 'norm') or not hasattr(self, 'cdata'):
                self.cdata = None
            self.parent.draw()

    def edit_props(self):
        props_editor = self.parent.props_editor
        try:
            props_editor.itemChanged.disconnect()
        except TypeError:
            pass
        props_editor.dataobj = self
        for i, k in enumerate(PROPERTIES):
            item = QtWidgets.QTableWidgetItem(k)
            item.setFlags(QtCore.Qt.ItemIsEditable)
            item.setForeground(QtGui.QColor(0, 0, 0))
            props_editor.setItem(i, 0, item)
            props_editor.setItem(i, 1, QtWidgets.QTableWidgetItem(''))
            if self.props and (all(k in p for p in self.props) and
                               all(p[k] == self.props[0][k]
                                   for p in self.props[1:])):
                props_editor.setItem(i, 1, QtWidgets.QTableWidgetItem(
                    props_repr(self.props[0][k])))
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
            if key == 'color' and mpl.colors._is_nth_color(value):
                value = nth_color_value(value)
            if all(key in p and p[key] == value for p in self.props):
                return
            elif value == '' and any(key in p for p in self.props):
                for p in self.props:
                    p.pop(key, None)
            elif str(value):
                for p in self.props:
                    p[key] = value
                self.parent.props_editor.setItem(
                    row, 1, QtWidgets.QTableWidgetItem(props_repr(value)))
        self.parent.draw(keeplims=True)

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


class Interact(QtWidgets.QMainWindow):

    def __init__(self, data, app, title=None, sortkey=None, axisequal=False,
                 parent=None, max_label_len=None, **kwargs):
        self.app = app
        QtWidgets.QMainWindow.__init__(self, parent)
        self.setAttribute(QtCore.Qt.WA_DeleteOnClose, True)
        self.setWindowTitle(title or ', '.join(d[1] for d in data))
        if sortkey is None:
            self.sortkey = kwargs.get('key', str.lower)
        else:
            self.sortkey = sortkey
        self.grid = QtWidgets.QGridLayout()

        self.frame = QtWidgets.QWidget()
        self.dpi = 100

        self.fig = Figure(tight_layout=False)
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
        self.max_label_len = max_label_len
        self.margins = 0

        self.mpl_toolbar = NavigationToolbar(self.canvas, self.frame)
        self.pickers = None

        self.vbox = QtWidgets.QVBoxLayout()
        self.vbox.addWidget(self.mpl_toolbar)

        self.props_editor = PropertyEditor(self)

        self.datas = []
        for d in data:
            self.add_data(*d)

        self.cycle = kwargs.get('prop_cycle', mpl.rcParams['axes.prop_cycle'])
        self.init_props()

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
        data = DataObj(self, obj, **kwargs)
        self.datas.append(data)

        self.row = self.grid.rowCount()
        self.column = 0

        def axisequal():
            self.axisequal = not self.axisequal
            self.draw()

        def add_widget(w, axis=None):
            self.grid.addWidget(w, self.row, self.column)
            data.widgets.append(w)
            if isinstance(w, KeyHandlerMixin):
                w.duplicate.connect(data.duplicate)
                w.remove.connect(data.remove)
                w.closed.connect(data.close)
                w.axisEqual.connect(axisequal)
                w.relabel.connect(data.change_label)
                w.editCdata.connect(data.edit_cdata)
                w.editProps.connect(data.edit_props)
                w.sync.connect(data.sync)
                w.twin.connect(data.toggle_twin)
                w.xlim.connect(self.set_xlim)
                w.ylim.connect(self.set_ylim)
                if axis:
                    w.syncAxis.connect(lambda axes=[axis]: data.sync(axes))
            self.column += 1

        add_widget(data.label)
        add_widget(data.menu, 'y')
        add_widget(data.scale_label)
        add_widget(data.scale_box, 'y')
        add_widget(data.xlabel)
        add_widget(data.xmenu, 'x')
        add_widget(data.xscale_label)
        add_widget(data.xscale_box, 'x')

    def init_props(self):
        self.props_iter = cycle(self.cycle)
        if len(self.datas) > 1:
            for data, props in zip(self.datas, self.props_iter):
                if data.cdata is not None and 'color' in props:
                    continue
                for k, v in props.items():
                    for p in data.props:
                        p.setdefault(k, v)

    def warn(self, message):
        self.warnings = {message}
        self.draw_warnings()
        self.canvas.draw()

    def remove_data(self, data):
        if len(self.datas) < 2:
            return self.warn("Can't delete last row")

        # Check if props can be reused
        if self.in_cycle(data):
            self.props_iter = chain([{p: data.props[0][p]
                                      for p in self.cycle.keys}],
                                    self.props_iter)

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

    def in_cycle(self, data):
        if not data.props:
            return False
        d0 = {k: v for k, v in data.props[0].items() if k in self.cycle.keys}
        if d0 not in self.cycle:
            return False
        for props in data.props[1:]:
            if any(props.get(k, None) != v for k, v in d0.items()):
                return False
        return True

    def get_scale(self, textbox, completer):
        completer.close_popup()
        text = text_type(textbox.text())
        try:
            return eval(text, CONSTANTS.copy())
        except Exception as e:
            self.warnings.add('Error setting scale: ' + text_type(e))
            return 1.0

    def get_key(self, data, menu):
        text = menu.currentText()
        value, ok, warnings = data.eval_key(text)
        if ok:
            return text

        model = menu.completer.completionModel()
        for row in range(model.rowCount()):
            key = model.data(model.index(row, 0))
            if data.eval_key(key).ok:
                logger.debug('replacing %r with %r', text, key)
                menu.focusNextChild()
                menu.lineEdit().setText(key)
                menu.setFocus()
                return key
        else:
            self.warnings.update(warnings)
            return text

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
        xname = self.get_key(data, data.xmenu)
        yname = self.get_key(data, data.menu)

        y, ok, warnings = data.eval_key(yname)
        self.warnings.update(warnings)
        logger.debug('eval_key y %r ok = %s', yname, ok)
        if ok:
            y = np.asanyarray(y) * yscale
        x, xok, warnings = data.eval_key(xname)
        self.warnings.update(warnings)
        ok = ok and xok
        logger.debug('eval_key x %r ok = %s', xname, ok)
        if ok:
            x = np.asanyarray(x) * xscale
        elif xname == '_':
            x = mpl.cbook.index_of(y)

        if ok and x is not None and x.shape[0] in y.shape:
            xaxis = y.shape.index(x.shape[0])
            lines = self.lines(axes, data, x, np.rollaxis(y, xaxis))
        else:
            if ok and x is not None:
                self.warnings.add(
                    '{} {} and {} {} have incompatible dimensions'.format(
                        xname, x.shape, yname, y.shape))
            lines = self.lines(axes, data, None, y)

        auto = False
        if not isiterable(data.labels):
            if len(lines) > 1:
                auto = data.labels
                data.labels = ['%s %d' % (auto, i) for i in range(len(lines))]
            else:
                data.labels = [data.labels]

        while len(data.props) < len(lines):
            data.props.append(data.props[-1])

        keys = set()
        for i, (line, label, props) in enumerate(
                zip(lines, data.labels, data.props)):
            line.set_label(label)
            for key, value in props.items():
                getattr(line, 'set_' + key, lambda _: None)(value)
            props = copy.copy(props)
            props.update([('color', line.get_color()),
                          ('linestyle', line.get_linestyle()),
                          ('linewidth', line.get_linewidth())])

            # Don't add multi-colored lines to legend
            if isinstance(line, mpl.collections.LineCollection):
                continue

            key = tuple(sorted(zip(*(map(str, x) for x in props.items()))))
            keys.add(key)
            self.label_lists.setdefault(key, []).append(label)
            self.handles.setdefault(key, line)

        if auto and len(keys) == 1:
            for line in lines:
                line.set_label(auto)
            self.label_lists[key] = [auto]

        return lines

    def lines(self, axes, data, x, y):
        colors = [p.get('color', None) for p in data.props]
        if data.cdata is not None and not any(colors):
            cdata = data.cdata
            if x is not None and cdata.shape == y.shape:
                lines = []
                x, y = np.ma.filled(x, np.nan), np.ma.filled(y, np.nan)
                x, y, cdata = map(np.atleast_2d,
                                  map(np.transpose, (x, y, cdata)))
                for x, y, c in zip(x, y, cdata):
                    xmid = (x[1:] + x[:-1]) / 2.0
                    ymid = (y[1:] + y[:-1]) / 2.0
                    x = np.append(np.array([x[:-1], xmid, xmid]).T.flat, x[-1])
                    y = np.append(np.array([y[:-1], ymid, ymid]).T.flat, y[-1])
                    points = np.array([x, y]).T.reshape(-1, 1, 2)
                    segments = np.concatenate(
                        [points[:-1], points[1:]], axis=1)
                    line = mpl.collections.LineCollection(
                        segments, norm=data.norm, cmap=data.cmap)
                    line.set_array(c)
                    axes.add_collection(line)
                    axes.autoscale_view()
                    lines.append(line)
                return lines
            else:
                lines = axes.plot(y) if x is None else axes.plot(x, y)
                for line, c in zip(lines, cdata):
                    line.set_color(data.cmap(data.norm(c)))
                return lines
        else:
            return axes.plot(y) if x is None else axes.plot(x, y)

    def draw(self, *, keeplims=False):
        logger.debug('Interact.draw keeplims=%r', keeplims)
        self.mpl_toolbar.home = self.draw
        if keeplims:
            limits = self.axes.axis(), self.axes2.axis()
        twin = any(d.twin for d in self.datas)
        self.clear_pickers()
        self.fig.clear()
        self.axes = self.fig.add_subplot(111)

        data = next((d for d in self.datas if d.cdata is not None), None)
        if data and not twin:
            self.mappable = mpl.cm.ScalarMappable(norm=data.norm,
                                                  cmap=data.cmap)
            self.mappable.set_array(data.cdata)
            self.colorbar = self.fig.colorbar(
                self.mappable, ax=self.axes, fraction=0.1, pad=0.02)
            self.colorbar.set_label(data._cdata if isinstance(data._cdata, str)
                                    else data.name)
        elif twin:
            self.axes2 = self.axes.twinx()

        for ax in self.axes, self.axes2:
            if len(self.datas) > 1 and any(k in data.props
                                           for k in self.cycle.keys
                                           for data in self.datas):
                ax.set_prop_cycle(cycler(color=['C0']))
            ax._tight = bool(self.margins)
            if self.margins:
                ax.margins(self.margins)

        lines = []
        xlabel = []
        ylabel = []
        xlabel2 = []
        ylabel2 = []
        self.warnings = set()
        self.label_lists, self.handles = OrderedDict(), OrderedDict()
        for i, d in enumerate(self.datas, 1):
            logger.debug('plotting data %s of %s', i, len(self.datas))
            if d.twin:
                axes, x, y = self.axes2, xlabel2, ylabel2
            else:
                axes, x, y = self.axes, xlabel, ylabel
            lines.extend(self.plot(axes, d))
            text = self.get_key(d, d.menu)
            xtext = self.get_key(d, d.xmenu)
            if xtext:
                x.append(xtext + ' (' + d.name + ')')
            y.append(text + ' (' + d.name + ')')

        self.axes.set_xlabel('\n'.join(xlabel))
        self.axes.set_ylabel('\n'.join(ylabel))
        self.draw_warnings()

        self.axes2.set_xlabel('\n'.join(xlabel2))
        self.axes2.set_ylabel('\n'.join(ylabel2))

        if self.xlim:
            self.axes.set_xlim(self.xlim)
            ylim = self.find_ylim(lines)
            if ylim and not self.ylim:
                self.axes.set_ylim(ylim)
        if self.ylim:
            self.axes.set_ylim(self.ylim)

        self.axes.set_xscale(self.xlogscale)
        self.axes.set_yscale(self.ylogscale)

        for ax in self.axes, self.axes2:
            ax.set_aspect('equal' if self.axisequal else 'auto', 'datalim')
        labels = [', '.join(unique(x)) for x in self.label_lists.values()]
        for i, label in enumerate(labels):
            if self.max_label_len and len(label) > self.max_label_len:
                labels[i] = label[:self.max_label_len] + '…'
        self.pickers = [picker(ax) for ax in [self.axes, self.axes2]]

        if keeplims:
            self.axes.axis(limits[0])
            self.axes2.axis(limits[1])

        # Ignore the legend in in tight_layout
        self.fig.tight_layout()
        self.axes.legend(self.handles.values(), labels,
                         ncol=1 + len(labels) // 10,
                         handlelength=1.5).draggable(True)

        self.canvas.draw()

    def find_ylim(self, lines):
        lower, upper = self.axes.get_xlim()
        ymin, ymax = np.inf, -np.inf
        ylim = None
        _lines = []
        for line in lines:
            if isinstance(line, mpl.collections.LineCollection):
                _lines.extend(seg.T for seg in line.get_segments() if seg.size)
            else:
                _lines.append(line.get_data())
        for x, y in _lines:
            p0, p1 = tee(zip(x, y))
            try:
                next(p1)
            except StopIteration:
                continue
            for (x0, y0), (x1, y1) in zip(p0, p1):
                if x0 > x1:
                    (x0, y0), (x1, y1) = (x1, y1), (x0, y0)
                if not (lower <= x0 <= upper or lower <= x1 <= upper):
                    continue
                X = np.array(sorted({lower, x0, x1, upper}))
                if not X.size:
                    continue
                X = X[(X >= lower) & (X <= upper)]
                Y = np.interp(X, (x0, x1), (y0, y1))
                if np.isfinite(Y).any():
                    ylim = ymin, ymax = (min(ymin, np.nanmin(Y)),
                                         max(ymax, np.nanmax(Y)))
        return ylim

    def draw_warnings(self):
        logger.debug('drawing warnings = %s', self.warnings)
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
            self.set_xlim()
        elif event.key == 'ctrl+y':
            self.set_ylim()
        elif event.key == 'ctrl+l':
            self.draw(keeplims=True)
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

    def closeEvent(self, event):
        self._close()

    def _close(self):
        self.app.references.discard(self)
        self.window().close()

    def _input_lim(self, axis, default):
        default = text_type(default)
        if re.match(r'^\(.*\)$', default) or re.match(r'^\[.*\]$', default):
            default = default[1:-1]
        text, ok = QtWidgets.QInputDialog.getText(
            self, 'Set axis limits', '{} limits:'.format(axis),
            QtWidgets.QLineEdit.Normal, default)
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
            create(*[d.copy() for d in self.datas])
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
    sets = [set(d) for d in dicts]
    keys = sets[0].intersection(*sets)

    def validate(array):
        return (hasattr(array, 'dtype') and
                (np.issubdtype(array.dtype, np.number) or
                 np.issubdtype(array.dtype, np.bool_)) and
                np.squeeze(array).ndim == 1)

    def pad(array):
        return np.pad(np.squeeze(array), (0, length - array.size),
                      mode='constant', constant_values=(float('nan'),))

    # Preserve non-dict types
    merged = copy.copy(dicts[0])
    try:
        merged.clear()
    except Exception:
        merged = {}
    for key in keys:
        if all(validate(d[key]) for d in dicts):
            length = max(len(d[key]) for d in dicts)
            merged[key] = np.array([pad(d[key]) for d in dicts]).T
        elif all(isinstance(d[key], collections.Mapping) for d in dicts):
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
        app = QtWidgets.QApplication(sys.argv)
        app_created = True
    app.references = getattr(app, 'references', set())

    # Backwards compatibility
    data = list(data)
    for i, d in enumerate(data):
        if isinstance(d, dict):
            data[i] = [d, '']
        elif hasattr(d, 'dtype') and isiterable(d.dtype.names):
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
    n = 10
    time = np.tile(np.linspace(0, 10), (n, 1)).T
    cdata = np.linspace(0, 1, n)
    d = {'time': time, 'x': np.sin(time + cdata)}
    props = {'linewidth': [1, 4]}
    obj = dataobj(d, name='data', xname='time', yname='x', yscale=3.0,
                  props=props, cdata=cdata)
    create(obj)
    d, name, data = copy.deepcopy(obj)
    d['x'] = d['x'] * 1.3 + 0.2
    del data['props']
    create(obj, [d, 'other', data])


if __name__ == '__main__':
    main()
