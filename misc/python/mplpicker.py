import numpy as np
import matplotlib.pyplot as plt

LEFT_CLICK = 1
MIDDLE_CLICK = 2
RIGHT_CLICK = 3


class Picker:

    annotation_kwargs = dict(bbox=dict(alpha=0.5,
                                       boxstyle='round,pad=0.5',
                                       facecolor='yellow'),
                             arrowprops=dict(arrowstyle='->',
                                             shrinkB=0,
                                             connectionstyle='arc3, rad=0'),
                             xytext=(-15, 15),
                             textcoords='offset points',
                             verticalalignment='bottom',
                             horizontalalignment='right')

    def __init__(self, axes):
        if hasattr(axes, '_active_picker'):
            raise Exception("Only one picker allowed per axes. "
                            "Use picker() instead of Picker().")
        self.axes = axes
        self.artist = None
        self.canvas = axes.figure.canvas
        self.annotation = None
        self.point = None
        self.shift = False
        self.control = False
        self.repeat_timer = None
        self.measure_line = None
        self.measure_box = None
        self.cids = []

        if not hasattr(self.canvas, '_active_picker'):
            self.canvas._active_picker = None

        for line in self.axes.get_lines():
            line.set_picker(self)
            line.set_pickradius(5)
        for event in ['button_press', 'key_release', 'key_press', 'pick']:
            self.cids.append(self.canvas.mpl_connect(event + '_event',
                                                     getattr(self, event)))

        # Timer to prevent looping when clicking on multiple lines
        self.waiting = False

        def expire():
            self.waiting = False
            self.timer.stop()

        self.timer = self.canvas.new_timer(interval=100,
                                           callbacks=[(expire, [], {})])

    def disable(self):
        self.remove()
        [self.canvas.mpl_disconnect(c) for c in self.cids]
        [self.timer.remove_callback(c) for c in self.timer.callbacks]
        del self.axes._active_picker

    def button_press(self, event):
        for line in self.axes.get_lines():
            if line and line.contains(event)[0]:
                line.pick(event)
        if self.annotation and (self.annotation.contains(event)[0] or
                                (self.canvas._active_picker == self and
                                 self.control)):
            self.annotation.pick(event)
        if (self.measure_box and self.measure_box.contains(event)[0] and
                event.button == RIGHT_CLICK):
            self.remove_measurement()

    def key_press(self, event):
        if event.key == 'd':
            self.remove()
        elif event.key == ']':
            self.move(1)
        elif event.key == '[':
            self.move(-1)
        elif event.key == '}':
            self.move(1, all_pickers=True)
        elif event.key == '{':
            self.move(-1, all_pickers=True)
        elif event.key == 'shift':
            self.shift = True
        elif event.key == 'control':
            self.control = True

    def key_release(self, event):
        if event.key == 'shift':
            self.shift = False
        elif event.key == 'control':
            self.control = False
        elif event.key in [']', '[', '}', '{']:
            if self.repeat_timer:
                self.repeat_timer.stop()
                [self.repeat_timer.remove_callback(c)
                 for c in self.repeat_timer.callbacks]
                self.repeat_timer = None

    def pick(self, event):
        if self.waiting:
            return

        artist = event.artist
        axes = artist.axes
        if (self.control and self.point and self.annotation and
                axes == self.axes):
            # Measure to another point
            self.remove_measurement()
            point = self.snap(event)
            f = 0.1 * (1 if point[0] < self.point[0] and
                       point[1] < self.point[1] else -1)
            self.measure_line = self.axes.annotate(
                s="",
                xy=self.point[:2],
                xytext=point[:2],
                arrowprops=dict(arrowstyle="<|-|>",
                                linestyle="dashed",
                                shrinkA=0, shrinkB=0,
                                connectionstyle="bar, fraction=%f" % f,
                                ),
            )
            self.measure_box = self.axes.annotate(
                s=self.format_measurement(point),
                xy=point[:2],
                **self.annotation_kwargs)
            self.measure_box.draggable()

            self.canvas._active_picker = self
            self.canvas.draw()

        elif artist in self.axes.get_lines():
            self.artist = artist
            point = self.snap(event)
            text = self.format(point)

            self.remove_measurement()

            if self.shift and self.annotation:
                # Change target point without moving bbox
                self.point = point
                self.annotation.set_text(self.format(self.point))
                self.annotation.xy = (self.point[0], self.point[1])

            elif not self.control and not self.shift:
                # Choose a new point and draw annotation
                if self.annotation:
                    self.remove()

                self.point = point
                self.annotation = self.axes.annotate(
                    s=text,
                    xy=self.point[:2],
                    **self.annotation_kwargs)

                self.annotation.draggable()

            self.canvas._active_picker = self
            self.canvas.draw()

        elif artist == self.annotation:
            self.canvas._active_picker = self
            if (event.mouseevent.button == RIGHT_CLICK and
                    not self.shift and not self.control):
                self.remove()

        self.waiting = True
        self.timer.start()

    def remove(self):
        self.remove_measurement(draw=False)
        if self.annotation:
            self.annotation.remove()
            self.annotation = None
            self.canvas._active_picker = None
            self.canvas.draw()

    def remove_measurement(self, draw=True):
        if self.measure_line:
            self.measure_line.remove()
            self.measure_line = None
        if self.measure_box:
            self.measure_box.remove()
            self.measure_box = None
        if draw:
            self.canvas.draw()

    def move(self, offset, all_pickers=False):
        if not self.annotation:
            return

        self.remove_measurement()

        if not self.canvas._active_picker and self.annotation:
            self.canvas._active_picker = self

        if all_pickers or self.canvas._active_picker == self:
            xdata, ydata = self.artist.get_xdata(), self.artist.get_ydata()
            ind = self.point[2] + offset
            if 0 <= ind < len(xdata):
                self.point = xdata[ind], ydata[ind], ind
                self.annotation.set_text(self.format(self.point))
                self.annotation.xy = (self.point[0], self.point[1])
                self.canvas.draw()
            self.repeat_timer = self.canvas.new_timer(
                interval=100,
                callbacks=[(self.move, [offset, all_pickers], {})])
            self.repeat_timer.start()

    def snap(self, event):
        """Return the xy coordinates and index of the nearest point."""
        xdata, ydata = event.artist.get_xdata(), event.artist.get_ydata()
        ind = event.ind[0]
        point = event.mouseevent.x, event.mouseevent.y
        inv = event.artist.axes.transData.inverted()
        xclick, yclick = inv.transform_point(point)

        if ind + 1 >= len(xdata) or None in [xclick, yclick]:
            return xdata[ind], ydata[ind], ind

        x0, y0 = xdata[ind], ydata[ind]
        x1, y1 = xdata[ind + 1], ydata[ind + 1]
        to_next_point = np.linalg.norm([x1 - x0, y1 - y0])
        to_click = np.linalg.norm([xclick - x0, yclick - y0])

        return ((x0, y0, ind) if to_click < to_next_point / 2 else
                (x1, y1, ind + 1))

    def format(self, point):
        label = self.artist.get_label()
        output = [label] if not label.startswith('_') else []
        output.append('%.6g' % point[0])
        output.append('%.6g' % point[1])
        output.append('[%d]' % point[2])
        return "\n".join(output)

    def format_measurement(self, point):
        output = []
        output.append('dx: %.6g' % (point[0] - self.point[0]))
        output.append('dy: %.6g' % (point[1] - self.point[1]))
        output.append('dist: %.6g' % np.linalg.norm(
            [point[0] - self.point[0], point[1] - self.point[1]]))
        output.append('[%d]' % point[2])
        return "\n".join(output)


def picker(axes):
    if hasattr(axes, '_active_picker'):
        for line in self.axes.get_lines():
            line.set_picker(axes._active_picker)
            line.set_pickradius(5)
        return axes._active_picker
    else:
        p = Picker(axes)
        axes._active_picker = p
        return p

if __name__ == '__main__':
    plt.figure()
    time = np.linspace(0, 10, num=200)
    y = np.cos(time) + np.random.normal(size=time.shape) * 0.1
    z = np.sin(time) + np.random.normal(size=time.shape) * 0.1
    artist = plt.plot(time, y, label='y')[0]
    ax = plt.gca()
    self = picker(ax)
    artist = ax.plot(time, 10 * z, 'r', label='z')[0]
    self = picker(ax)
    ax = plt.gca().twinx()
    artist = ax.plot(time, -10 * z, 'g', label='z')[0]
    self = picker(ax)
    plt.show()
