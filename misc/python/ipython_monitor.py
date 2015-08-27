from __future__ import print_function
import os
import sys
from IPython.kernel import KernelManager, find_connection_file
from Queue import Empty
from glob import glob
from pygments import highlight
from pygments.filter import simplefilter
from pygments.lexers import PythonLexer
from pygments.token import Name
try:
    from solarized_terminal import (SolarizedTerminalFormatter as
                                    TerminalFormatter)
except ImportError:
    print("Couldn't import solarized terminal formatter")
    from pygments.formatters import TerminalFormatter

colors = {k: i for i, k in enumerate([
    'black', 'red', 'green', 'yellow', 'blue', 'magenta', 'cyan', 'white'])}

types = set(['basestring', 'bool', 'buffer', 'bytearray', 'bytes', 'chr',
             'complex', 'dict', 'file', 'float', 'format', 'frozenset', 'help',
             'int', 'list', 'long', 'object', 'set', 'str', 'super', 'tuple',
             'type', 'unichr', 'unicode'])

connected = False
skip = set()
while not connected:
    try:
        filename = find_connection_file('kernel*')
    except IOError:
        continue

    for fullpath in glob(os.path.join(os.path.dirname(filename),
                                      'kernel*')):
        if fullpath in skip:
            continue
        km = KernelManager(connection_file=fullpath)
        km.load_connection_file()

        kc = km.client()
        kc.start_channels()

        msg_id = kc.shell_channel.execute(
            "_appname = get_ipython().config['IPKernelApp']['parent_appname']",
            user_expressions={'_appname': '_appname'}, silent=True,
        )
        try:
            msg = kc.shell_channel.get_msg(timeout=1)
            if msg['parent_header']['msg_id'] == msg_id:
                appname = msg['content']['user_expressions']['_appname']
                if appname['data']['text/plain'] == "'ipython-console'":
                    connected = True
                    socket = km.connect_iopub()
                    print('IPython monitor connected successfully')
                    break
                else:
                    skip.add(fullpath)
                    continue
        except KeyboardInterrupt:
            sys.exit(0)
        except (Empty, KeyError):
            continue
        except Exception as e:
            import traceback
            traceback.print_exc()

if len(sys.argv) > 1:
    term = open(sys.argv[1], 'w+')
    sys.stdout = term


@simplefilter
def color_types(self, lexer, stream, options):
    for ttype, value in stream:
        if ttype is Name.Builtin and value in types:
            ttype = Name.Exception
        elif ttype is Name.Builtin.Pseudo and value in [
                'False', 'True', 'None']:
            ttype = Name.Constant

        if ttype is Name.Decorator:
            yield ttype, '@'
            yield Name.Function, value.split('@')[-1]
        else:
            yield ttype, value


lexer = PythonLexer()
lexer.add_filter(color_types())
formatter = TerminalFormatter()


def colorize(string, color, bold=False, bright=False):
    return ''.join(['\033[', str(colors[color] + (90 if bright else 30)),
                    ';1' if bold else '', 'm', string, '\033[0m'])


class IPythonMonitor(object):

    def __init__(self):
        self.clients = set()
        self.execution_count_id = None
        self.awaiting_msg = False
        self.msg_id = None
        self.last_msg_type = None  # Only set when text written to stdout
        self.last_execution_count = None

    def print_prompt(self, color):
        l = self.prompt.index('[')
        r = self.prompt.index(']')
        sys.stdout.write(colorize(self.prompt[:l + 1], color))
        sys.stdout.write(colorize(self.prompt[l + 1:r], color, bold=True))
        sys.stdout.write(colorize(self.prompt[r:], color))

    def listen(self):
        while socket.recv():
            kc.iopub_channel.flush()
            msgs = kc.iopub_channel.get_msgs()
            for msg in msgs:
                try:
                    self.received_msg = (
                        self.msg_id and
                        msg['parent_header']['msg_id'] == self.msg_id)
                except KeyError:
                    self.received_msg = False

                msg_type = msg['msg_type']

                if msg_type == 'shutdown_reply':
                    sys.exit(0)
                elif self.awaiting_msg and msg_type == 'pyerr':
                    self.pyerr(msg)
                    continue

                client = msg['parent_header'].get('session', '')
                if (client and msg_type == 'pyin' and
                        msg['content']['code'] == '"_vim_client";_=_;__=__'):
                    self.clients.add(client)
                    continue
                if client not in self.clients:
                    continue

                try:
                    getattr(self, msg_type)(msg)
                except AttributeError:
                    self.other(msg)

                sys.stdout.flush()

    def pyin(self, msg):
        self.prompt = ''.join('In [%d]: ' % msg['content']['execution_count'])
        self.last_execution_count = msg['content']['execution_count']
        dots = '.' * len(self.prompt.rstrip()) + ' '
        sys.stdout.write('\r')
        self.print_prompt('green')
        code = highlight(msg['content']['code'], lexer, formatter)
        output = code.rstrip().replace('\n', '\n' + dots)
        sys.stdout.write(output)
        self.execution_count_id = msg['parent_header']['msg_id']
        self.last_msg_type = msg['msg_type']

    def pyout(self, msg, prompt=True, spaces=''):
        self.last_execution_count = msg['content']['execution_count']
        if prompt:
            self.prompt = ''.join('Out [%d]: ' %
                                  msg['content']['execution_count'])
            spaces = ' ' * len(self.prompt.rstrip()) + ' '
            sys.stdout.write('\n')
            self.print_prompt('red')
        output = msg['content']['data']['text/plain'].rstrip() \
            .replace('\n', '\n' + spaces)
        sys.stdout.write(output)
        self.execution_count_id = msg['parent_header']['msg_id']
        self.last_msg_type = msg['msg_type']

    def display_data(self, msg):
        sys.stdout.write('\n')
        self.pyout(msg, prompt=False)

    def pyerr(self, msg):
        if self.awaiting_msg and self.received_msg:
            with open(os.path.join(os.environ['HOME'], '.pyerr'), 'w') as f:
                f.write('\n'.join(msg['content']['traceback']).encode('utf-8'))
            self.msg_id = kc.shell_channel.execute('\n'.join([
                '%xmode Context', '%colors Linux']),
                silent=True)
            self.awaiting_msg = False
        else:
            for line in msg['content']['traceback']:
                sys.stdout.write('\n' + line)
            if not self.awaiting_msg:
                self.msg_id = kc.shell_channel.execute('\n'.join([
                    '%xmode Plain', '%colors NoColor', '%tb']),
                    silent=True)
                self.awaiting_msg = True
            else:
                self.awaiting_msg = False  # Missed the message
        self.last_msg_type = msg['msg_type']

    def stream(self, msg):
        if self.last_msg_type not in ['pyerr', 'stream']:
            sys.stdout.write('\n')
        if not self.received_msg:
            sys.stdout.write(colorize(msg['content']['data'],
                                      'cyan', bright=True))
            self.last_msg_type = msg['msg_type']

    def status(self, msg):
        if (msg['content']['execution_state'] == 'idle' and
                msg['parent_header']['msg_id'] == self.execution_count_id):
            self.prompt = '\n' + ''.join('In [%d]: ' % (
                self.last_execution_count + 1))
            self.print_prompt('green')
            self.execution_count_id = None

    def clear_output(self, msg):
        print('\033[2K\r', file=sys.stdout, end='')

    def other(self, msg):
        print('msg_type = %s' % str(msg['msg_type']))
        print('msg = %s' % str(msg))


monitor = IPythonMonitor()
monitor.listen()
