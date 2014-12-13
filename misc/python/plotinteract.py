from PyQt4 import QtCore, QtGui
import matplotlib as mpl
from matplotlib.figure import Figure
from matplotlib.backends.backend_qt4agg import FigureCanvasQTAgg as FigureCanvas
from matplotlib.backends.backend_qt4agg \
    import NavigationToolbar2QT as NavigationToolbar
from matplotlib.backend_bases import key_press_handler
import sys
import numpy as np
import re
import scipy.constants as const

if sys.platform == 'darwin':
    CONTROL_MODIFIER = QtCore.Qt.MetaModifier
else:
    CONTROL_MODIFIER = QtCore.Qt.ControlModifier


class KeyHandlerMixin(QtGui.QWidget):

    def set_completer(self, completer):
        self.completer = completer

    def event(self, event):
        if event.type() == QtCore.QEvent.KeyPress:
            if (event.key() == QtCore.Qt.Key_W and event.modifiers() &
                    CONTROL_MODIFIER):
                try:
                    lineEdit = self.lineEdit()
                except AttributeError:
                    lineEdit = self
                if lineEdit.selectionStart() == -1:
                    lineEdit.cursorWordBackward(True)
                    lineEdit.backspace()
                    return True
            elif (event.key() == QtCore.Qt.Key_Q and event.modifiers() &
                    CONTROL_MODIFIER):
                self.window().close()
            elif self.completer.popup().viewport().isVisible():
                if event.key() == QtCore.Qt.Key_Tab:
                    self.emit(QtCore.SIGNAL('tabPressed(int)'), 1)
                    return True
                elif event.key() == QtCore.Qt.Key_Backtab:
                    self.emit(QtCore.SIGNAL('tabPressed(int)'), -1)
                    return True

        return super(KeyHandlerMixin, self).event(event)


class KeyHandlerLineEdit(QtGui.QLineEdit, KeyHandlerMixin):
    pass


class TabCompleter(QtGui.QCompleter):

    def __init__(self, words, *args, **kwargs):
        QtGui.QCompleter.__init__(self, words, *args, **kwargs)
        self.setCaseSensitivity(QtCore.Qt.CaseInsensitive)
        self.setMaxVisibleItems(50)

    def set_textbox(self, textbox):
        self.textbox = textbox
        self.connect(self.textbox,
                     QtCore.SIGNAL('tabPressed(int)'),
                     self.select_completion)
        self.connect(self.textbox,
                     QtCore.SIGNAL('activated(int)'),
                     self.popup().close)

    def select_completion(self, direction):
        if not self.popup().selectionModel().hasSelection():
            if direction == 0:
                return
            direction = 0
        self.setCurrentRow(self.currentRow() + direction)
        self.popup().setCurrentIndex(self.completionModel().
                                     index(self.currentRow(), 0))


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

        pattern = QtCore.QRegExp(self.local_completion_prefix,
                                 QtCore.Qt.CaseInsensitive,
                                 QtCore.QRegExp.WildcardUnix)

        self.filterProxyModel.setFilterRegExp(pattern)

    def splitPath(self, path):
        self.local_completion_prefix = path
        self.updateModel()
        if self.filterProxyModel.rowCount() == 0:
            self.usingOriginalModel = False
            self.filterProxyModel.setSourceModel(
                QtGui.QStringListModel([path]))
            return [path]

        return []


class AutoCompleteComboBox(QtGui.QComboBox, KeyHandlerMixin):

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


class DataObj():

    def __init__(self, parent, obj, name, xname, labels):
        self.parent = parent
        self.obj = obj
        self.name = name
        self.labels = labels or name

        self.label = QtGui.QLabel(name + ':', parent=self.parent)
        self.scale_label = QtGui.QLabel('scale:', parent=self.parent)
        self.xscale_label = QtGui.QLabel('scale:', parent=self.parent)

        words = [k for k in obj.keys() if isinstance(obj[k], np.ndarray)]
        words.sort(key=lambda w: w.lower())

        def new_text_box():
            menu = AutoCompleteComboBox(parent=self.parent)
            menu.setMinimumWidth(100)
            menu.setModel(words)
            menu.setMaxVisibleItems(50)
            completer = menu.completer
            completer.set_textbox(menu)

            return completer, menu

        self.completer, self.menu = new_text_box()
        self.xcompleter, self.xmenu = new_text_box()

        self.menu.setCurrentIndex(0)
        self.xmenu.setCurrentIndex(self.xmenu.findText(xname))
        self.xlabel = QtGui.QLabel('x axis:', parent=self.parent)

        words = [c for c in dir(const) if isinstance(getattr(const, c), float)]
        words.sort(key=lambda w: w.lower())

        def new_scale_box():
            scale_compl = TabCompleter(words, parent=self.parent)
            scale_box = KeyHandlerLineEdit(parent=self.parent)
            scale_box.set_completer(scale_compl)
            scale_box.setMinimumWidth(100)
            scale_compl.setWidget(scale_box)
            scale_box.setText('1.0')
            scale_compl.set_textbox(scale_box)

            return scale_box, scale_compl

        self.scale_box, self.scale_compl = new_scale_box()
        self.xscale_box, self.xscale_compl = new_scale_box()

    def text_changed(self, text, box, completer):
        cursor_pos = box.cursorPosition()
        text = unicode(box.text())[:cursor_pos]
        prefix = re.split(r'\W', text)[-1].strip()
        completer.setCompletionPrefix(prefix)
        completer.complete()
        completer.select_completion(0)

    def xtext_changed(self, text):
        self.text_changed(text, self.xscale_box, self.xscale_compl)

    def ytext_changed(self, text):
        self.text_changed(text, self.scale_box, self.scale_compl)

    def complete_text(self, text, box):
        text = unicode(text)
        cursor_pos = box.cursorPosition()
        before_text = unicode(box.text())[:cursor_pos]
        after_text = unicode(box.text())[cursor_pos:]
        prefix_len = len(re.split(r'\W', before_text)[-1].strip())
        box.setText(before_text[:cursor_pos - prefix_len] +
                    text + after_text)
        box.setCursorPosition(cursor_pos - prefix_len + len(text))
        box.emit(QtCore.SIGNAL('activated(int)'), 0)

    def xcomplete_text(self, text):
        self.complete_text(text, self.xscale_box)

    def ycomplete_text(self, text):
        self.complete_text(text, self.scale_box)

    def show_popup(self, text):
        if len(unicode(text)) == 0:
            self.menu.showPopup()

    def xshow_popup(self, text):
        if len(unicode(text)) == 0:
            self.xmenu.showPopup()


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

        self.mpl_toolbar = NavigationToolbar(self.canvas, self.frame)

        vbox = QtGui.QVBoxLayout()
        vbox.addWidget(self.mpl_toolbar)

        self.datas = []
        for d in data:
            self.add_data(*d)
        vbox.addLayout(self.grid)

        vbox.addWidget(self.canvas)

        self.frame.setLayout(vbox)
        self.setCentralWidget(self.frame)

        self.draw()

    def add_data(self, obj, name, xname, labels=None):
        self.datas.append(DataObj(self, obj, name, xname, labels))
        data = self.datas[-1]

        self.connect(data.menu, QtCore.SIGNAL('activated(int)'),
                     self.draw)
        self.connect(data.completer, QtCore.SIGNAL('activated(int)'),
                     self.draw)
        self.connect(data.xmenu, QtCore.SIGNAL('activated(int)'),
                     self.draw)
        self.connect(data.xcompleter, QtCore.SIGNAL('activated(int)'),
                     self.draw)
        self.connect(data.xmenu.lineEdit(),
                     QtCore.SIGNAL('textChanged(QString)'),
                     data.xshow_popup)

        self.connect(data.scale_box, QtCore.SIGNAL('editingFinished()'),
                     self.draw)
        self.connect(data.scale_box,
                     QtCore.SIGNAL('textChanged(QString)'),
                     data.ytext_changed)
        self.connect(data.scale_compl,
                     QtCore.SIGNAL('activated(QString)'),
                     data.ycomplete_text)

        self.connect(data.xscale_box, QtCore.SIGNAL('editingFinished()'),
                     self.draw)
        self.connect(data.xscale_box,
                     QtCore.SIGNAL('textChanged(QString)'),
                     data.xtext_changed)
        self.connect(data.xscale_compl,
                     QtCore.SIGNAL('activated(QString)'),
                     data.xcomplete_text)

        self.column = 0

        def add_widget(w):
            self.grid.addWidget(w, len(self.datas) - 1, self.column)
            self.column += 1

        add_widget(data.label)
        add_widget(data.menu)
        add_widget(data.scale_label)
        add_widget(data.scale_box)
        add_widget(data.xlabel)
        add_widget(data.xmenu)
        add_widget(data.xscale_label)
        add_widget(data.xscale_box)

    def get_scale(self, text):
        try:
            return eval(unicode(text), const.__dict__, {})
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

    def draw(self):
        self.axes.clear()

        xlabel = []
        ylabel = []
        self.warnings = []
        for d in self.datas:
            scale = self.get_scale(d.scale_box.text())
            xscale = self.get_scale(d.xscale_box.text())
            text = self.get_key(d.menu)
            xtext = self.get_key(d.xmenu)
            if isinstance(d.labels, list):
                for i, l in enumerate(d.labels):
                    self.axes.plot(d.obj[xtext][..., i] * xscale,
                                   d.obj[text][..., i] * scale,
                                   label=d.labels[i],
                                   linestyle=self.get_line_style())
            else:
                self.axes.plot(d.obj[xtext] * xscale, d.obj[text] * scale,
                               label=d.labels,
                               linestyle=self.get_line_style())
            self.axes.set_xlabel('')
            xlabel.append(xtext + ' (' + d.name + ')')
            ylabel.append(text + ' (' + d.name + ')')

        self.axes.set_xlabel('\n'.join(xlabel))
        self.axes.set_ylabel('\n'.join(ylabel))
        self.axes.text(0.05, 0.05, '\n'.join(self.warnings),
                       transform=self.axes.transAxes, color='red')
        legend = self.axes.legend()
        legend.draggable(True)
        self.canvas.draw()

    def get_line_style(self):
        styles = ['-', '--', '-.', ':']
        lines = len(self.axes.lines)
        ncolors = len(mpl.rcParams['axes.color_cycle'])
        return styles[int(lines / ncolors) % len(styles)]

    def canvas_key_press(self, event):
        key_press_handler(event, self.canvas, self.mpl_toolbar)


def merge_dicts(*dicts):
    """Pad and concatenate arrays present in all input dictionaries."""
    sets = [set(d.keys()) for d in dicts]
    keys = sets[0].intersection(*sets)

    def validate(array):
        return isinstance(array, np.ndarray) and array.ndim == 1

    def pad(array):
        return np.pad(array, (0, length - array.size), mode='constant',
                      constant_values=(float('nan'),))

    merged = {}
    for key in keys:
        if all(map(validate, [d[key] for d in dicts])):
            length = max(map(len, [d[key] for d in dicts]))
            merged[key] = np.array([pad(d[key]) for d in dicts]).T

    return merged


def create(*data, **kwargs):
    """
    Create an interactive plot window for the given data.

    The inputs should define data dictionaries to plot as a list
    containing the dictionary itself, a name for the dictionary to use
    in titles and labels, a default x-axis key, and optionally a list of
    legend labels if the data in the dictionary is 2-dimensional. The
    only optional keyword argument is `title` which sets the window
    title.
    """
    app_created = False
    app = QtCore.QCoreApplication.instance()
    if app is None:
        app = QtGui.QApplication(sys.argv)
        app_created = True
    app.references = set()
    i = Interact(data, kwargs.get('title', None))
    i.setFont(QtGui.QFont('Tahoma', 11))
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
    create([d, 'data', 'time'])


if __name__ == '__main__':
    main()
