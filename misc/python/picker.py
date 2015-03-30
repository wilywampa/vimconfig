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

    def __init__(self, artist, **kwargs):
        self.artist = artist
        self.canvas = artist.figure.canvas
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

        artist.set_picker(self)
        artist.set_pickradius(kwargs.get('pickradius', 5))
        for event in ['button_press', 'key_release', 'key_press', 'pick']:
            self.cids.append(self.canvas.mpl_connect(event + '_event',
                                                     getattr(self, event)))

    def disable(self):
        self.remove()
        [self.canvas.mpl_disconnect(c) for c in self.cids]

    def button_press(self, event):
        if self.artist and self.artist.contains(event)[0]:
            self.artist.pick(event)
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
        elif event.key == 'right':
            self.move(1)
        elif event.key == 'left':
            self.move(-1)
        elif event.key == 'shift+right':
            self.move(1, all_pickers=True)
        elif event.key == 'shift+left':
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
        elif event.key in ['right', 'left', 'shift+right', 'shift+left']:
            if self.repeat_timer:
                self.repeat_timer.stop()
                [self.repeat_timer.remove_callback(c)
                 for c in self.repeat_timer.callbacks]
                self.repeat_timer = None

    def pick(self, event):
        if event.artist is self.artist:

            point = self.snap(event)
            text = self.format(point)

            self.remove_measurement()

            if self.shift and self.annotation:
                # Change target point without moving bbox
                self.point = point
                self.annotation.set_text(self.format(self.point))
                self.annotation.xy = (self.point[0], self.point[1])

            elif (self.control and self.point and
                  event.artist.axes is self.artist.axes):
                # Measure to another point
                point = self.snap(event)
                self.measure_line = self.artist.axes.annotate(
                    s="",
                    xy=self.point[:2],
                    xytext=point[:2],
                    arrowprops=dict(arrowstyle="<|-|>",
                                    linestyle="dashed",
                                    shrinkA=0, shrinkB=0,
                                    connectionstyle="bar, fraction=-0.1",
                                    ),
                )
                self.measure_box = self.artist.axes.annotate(
                    s=self.format_measurement(point),
                    xy=point[:2],
                    **self.annotation_kwargs)
                self.measure_box.draggable()

            else:
                # Choose a new point and draw annotation
                if self.annotation:
                    self.remove()

                self.point = point
                self.annotation = self.artist.axes.annotate(
                    s=text,
                    xy=self.point[:2],
                    **self.annotation_kwargs)

                self.annotation.draggable()

            self.canvas._active_picker = self
            self.canvas.draw()

        elif event.artist == self.annotation:
            self.canvas._active_picker = self
            if (event.mouseevent.button == RIGHT_CLICK and
                    not self.shift and not self.control):
                self.remove()

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
        xclick, yclick = event.mouseevent.xdata, event.mouseevent.ydata

        if (ind + 1 >= len(xdata) or
            None in [xclick, yclick] or
                event.mouseevent.inaxes != self.artist.axes):
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


if __name__ == '__main__':
    plt.figure()
    time = np.linspace(0, 10, num=200)
    y = np.cos(time) + np.random.normal(size=time.shape) * 0.1
    z = np.sin(time) + np.random.normal(size=time.shape) * 0.1
    artist = plt.plot(time, y, label='y')[0]
    self = Picker(artist)
    ax = plt.gca().twinx()
    artist = ax.plot(time, 10 * z, 'r', label='z')[0]
    self = Picker(artist)
    plt.show()
