# -*- coding: utf-8 -*-
import sys
from pygments.formatter import Formatter
from pygments.token import (Comment, Error, Generic, Keyword, Literal,
                            Name, Number, Operator, Other,
                            Punctuation, String, Text, Whitespace)
from pygments.util import get_choice_opt

esc = "\x1b["

codes = {
    "reset":     esc + "39;49;00m",
    "bold":      esc + "01m",
    "faint":     esc + "02m",
    "standout":  esc + "03m",
    "underline": esc + "04m",
    "blink":     esc + "05m",
    "overline":  esc + "06m",
    "":          "",
}

dark_colors = ["black", "darkred", "darkgreen", "brown", "darkblue",
               "purple", "teal", "lightgray"]
light_colors = ["darkgray", "red", "green", "yellow", "blue",
                "fuchsia", "turquoise", "white"]

x = 30
for d, l in zip(dark_colors, light_colors):
    codes[d] = esc + "%im" % x
    codes[l] = esc + "%im" % (x + 60)
    x += 1

del d, l, x

codes.update({
    "darkteal":   codes["turquoise"],
    "darkyellow": codes["brown"],
    "fuscia":     codes["fuchsia"],
    "white":      codes["bold"],
})


def reset_color():
    return codes["reset"]


def colorize(color_key, text):
    return codes[color_key] + text + codes["reset"]


def ansiformat(attr, text):
    """
    Format ``text`` with a color and/or some attributes::

        color       normal color
        *color*     bold color
        _color_     underlined color
        +color+     blinking color
    """
    result = []
    if attr[:1] == attr[-1:] == '+':
        result.append(codes['blink'])
        attr = attr[1:-1]
    if attr[:1] == attr[-1:] == '*':
        result.append(codes['bold'])
        attr = attr[1:-1]
    if attr[:1] == attr[-1:] == '_':
        result.append(codes['underline'])
        attr = attr[1:-1]
    result.append(codes[attr])
    result.append(text)
    result.append(codes['reset'])
    return ''.join(result)


#: Map token types to a tuple of color values for light and dark
#: backgrounds.
solarized_styles = {
    Text:                   ('blue',      'blue'),
    Whitespace:             ('darkgray',  'darkgray'),
    Error:                  ('darkred',   'darkred'),
    Other:                  ('blue',      'blue'),

    Comment:                ('green',     'green'),
    Comment.Multiline:      ('green',     'green'),
    Comment.Preproc:        ('green',     'green'),
    Comment.Single:         ('green',     'green'),
    Comment.Special:        ('green',     'green'),

    Keyword:                ('darkgreen', 'darkgreen'),
    Keyword.Constant:       ('darkgreen', 'darkgreen'),
    Keyword.Declaration:    ('darkgreen', 'darkgreen'),
    Keyword.Namespace:      ('red',       'red'),
    Keyword.Pseudo:         ('*red*',     'red'),
    Keyword.Reserved:       ('darkgreen', 'darkgreen'),
    Keyword.Type:           ('darkgreen', 'darkgreen'),

    Operator:               ('darkgreen', 'darkgreen'),
    Operator.Word:          ('darkgreen', 'darkgreen'),

    Name:                   ('blue',      'blue'),
    Name.Attribute:         ('blue',      'blue'),
    Name.Builtin:           ('darkblue',  'darkblue'),
    Name.Builtin.Pseudo:    ('darkblue',  'darkblue'),
    Name.Class:             ('brown',     'brown'),
    Name.Constant:          ('brown',     'brown'),
    Name.Decorator:         ('red',       'red'),
    Name.Entity:            ('red',       'red'),
    Name.Exception:         ('brown',     'brown'),
    Name.Function:          ('darkblue',  'darkblue'),
    Name.Property:          ('darkblue',  'darkblue'),
    Name.Label:             ('blue',      'blue'),
    Name.Namespace:         ('blue',      'blue'),
    Name.Other:             ('blue',      'blue'),
    Name.Tag:               ('darkgreen', 'darkgreen'),
    Name.Variable:          ('red',       'red'),
    Name.Variable.Class:    ('darkblue',  'darkblue'),
    Name.Variable.Global:   ('darkblue',  'darkblue'),
    Name.Variable.Instance: ('darkblue',  'darkblue'),

    Number:                 ('teal',      'teal'),
    Number.Float:           ('teal',      'teal'),
    Number.Hex:             ('teal',      'teal'),
    Number.Integer:         ('teal',      'teal'),
    Number.Integer.Long:    ('teal',      'teal'),
    Number.Oct:             ('teal',      'teal'),

    Literal:                ('blue',      'blue'),
    Literal.Date:           ('blue',      'blue'),

    Punctuation:            ('blue',      'blue'),

    String:                 ('teal',      'teal'),
    String.Backtick:        ('teal',      'teal'),
    String.Char:            ('teal',      'teal'),
    String.Doc:             ('teal',      'teal'),
    String.Double:          ('teal',      'teal'),
    String.Escape:          ('darkred',   'darkred'),
    String.Heredoc:         ('teal',      'teal'),
    String.Interpol:        ('darkred',   'darkred'),
    String.Other:           ('teal',      'teal'),
    String.Regex:           ('teal',      'teal'),
    String.Single:          ('teal',      'teal'),
    String.Symbol:          ('teal',      'teal'),

    Generic:                ('blue',      'blue'),
    Generic.Deleted:        ('blue',      'blue'),
    Generic.Emph:           ('blue',      'blue'),
    Generic.Error:          ('blue',      'blue'),
    Generic.Heading:        ('blue',      'blue'),
    Generic.Inserted:       ('blue',      'blue'),
    Generic.Output:         ('blue',      'blue'),
    Generic.Prompt:         ('blue',      'blue'),
    Generic.Strong:         ('blue',      'blue'),
    Generic.Subheading:     ('blue',      'blue'),
    Generic.Traceback:      ('blue',      'blue'),
}


class SolarizedTerminalFormatter(Formatter):

    r"""
    Format tokens with ANSI color sequences, for output in a text console.
    Color sequences are terminated at newlines, so that paging the output
    works correctly.

    The `get_style_defs()` method doesn't do anything special since there is
    no support for common styles.

    Options accepted:

    `bg`
        Set to ``"light"`` or ``"dark"`` depending on the terminal's background
        (default: ``"light"``).

    `colorscheme`
        A dictionary mapping token types to (lightbg, darkbg) color names or
        ``None`` (default: ``None`` = use builtin colorscheme).
    """
    name = 'Terminal'
    aliases = ['terminal', 'console']
    filenames = []

    def __init__(self, **options):
        Formatter.__init__(self, **options)
        self.darkbg = get_choice_opt(options, 'bg',
                                     ['light', 'dark'], 'light') == 'dark'
        self.colorscheme = options.get('colorscheme', None) or solarized_styles

    def format(self, tokensource, outfile):
        # hack: if the output is a terminal and has an encoding set,
        # use that to avoid unicode encode problems
        if not self.encoding and hasattr(outfile, "encoding") and \
           hasattr(outfile, "isatty") and outfile.isatty() and \
           sys.version_info < (3,):
            self.encoding = outfile.encoding
        return Formatter.format(self, tokensource, outfile)

    def format_unencoded(self, tokensource, outfile):
        for ttype, value in tokensource:
            color = self.colorscheme.get(ttype)
            while color is None:
                ttype = ttype[:-1]
                color = self.colorscheme.get(ttype)
            if color:
                color = color[self.darkbg]
                spl = value.split('\n')
                for line in spl[:-1]:
                    if line:
                        outfile.write(ansiformat(color, line))
                    outfile.write('\n')
                if spl[-1]:
                    outfile.write(ansiformat(color, spl[-1]))
            else:
                outfile.write(value)
