from IPython.kernel import KernelManager
from IPython.kernel import find_connection_file
import sys
import os
from pygments import highlight
from pygments.lexers import PythonLexer
try:
    from solarized_terminal import SolarizedTerminalFormatter \
        as TerminalFormatter
except ImportError:
    print "Couldn't import solarized terminal formatter"
    from pygments.formatters import TerminalFormatter

colors = {
    'black':    '30',
    'red':      '31',
    'green':    '32',
    'yellow':   '33',
    'blue':     '34',
    'magenta':  '35',
    'cyan':     '36',
    'white':    '37',
}

connected = False
km = None
kc = None
while not connected:
    try:
        fullpath = find_connection_file('kernel*')
    except IOError:
        continue
    if km is not None:
        del(km)
    if kc is not None:
        del(kc)
    km = KernelManager(connection_file=fullpath)
    km.load_connection_file()

    kc = km.client()
    kc.start_channels()

    kc.shell_channel.execute('', silent=True)
    try:
        msg = kc.shell_channel.get_msg(timeout=1)
        connected = True
        print 'IPython monitor connected successfully'
    except KeyboardInterrupt:
        sys.exit(1)
    except:
        pass

if len(sys.argv) > 1:
    term = open(sys.argv[1], 'w+')
    sys.stdout = term

lexer = PythonLexer()
formatter = TerminalFormatter()


def handle_error():
    global awaiting_msg, received_msg, kc, msg_id
    if awaiting_msg and received_msg:
        with open(os.path.join(os.environ['HOME'], '.pyerr'), 'w') as f:
            f.write('\n'.join(msg['content']['traceback']))
        msg_id = kc.shell_channel.execute('\n'.join([
            '%xmode Context', '%colors Linux']),
            silent=True)
        awaiting_msg = False
    else:
        for line in msg['content']['traceback']:
            sys.stdout.write('\n' + line)
        if not awaiting_msg:
            msg_id = kc.shell_channel.execute('\n'.join([
                '%xmode Plain', '%colors NoColor', '%tb']),
                silent=True)
            awaiting_msg = True


def colorize(string, color, bold=False):
    return ''.join(['\033[', colors[color], ';1' if bold else '', 'm',
                    string, '\033[0m'])


def print_prompt(color):
    l = prompt.index('[')
    r = prompt.index(']')
    sys.stdout.write(colorize(prompt[:l+1], color))
    sys.stdout.write(colorize(prompt[l+1:r], color, bold=True))
    sys.stdout.write(colorize(prompt[r:], color))


print_idle = False
socket = km.connect_iopub()
awaiting_msg = False
msg_id = None
while socket.recv():
    kc.iopub_channel.flush()
    msgs = kc.iopub_channel.get_msgs()
    for msg in msgs:
        received_msg = msg_id and msg['parent_header']['msg_id'] == msg_id
        if msg['msg_type'] == 'pyin':
            prompt = ''.join('In [%d]: ' % msg['content']['execution_count'])
            dots = '.' * len(prompt.rstrip()) + ' '
            sys.stdout.write('\r')
            print_prompt('green')
            code = highlight(msg['content']['code'], lexer, formatter)
            output = code.rstrip().replace('\n', '\n' + dots)
            sys.stdout.write(output)
            print_idle = True

        elif msg['msg_type'] == 'pyout':
            prompt = ''.join('Out [%d]: ' % msg['content']['execution_count'])
            spaces = ' ' * len(prompt.rstrip()) + ' '
            sys.stdout.write('\n')
            print_prompt('red')
            output = msg['content']['data']['text/plain'].rstrip() \
                .replace('\n', '\n' + spaces)
            sys.stdout.write(output)

        elif msg['msg_type'] == 'pyerr':
            handle_error()

        elif msg['msg_type'] == 'stream':
            if not received_msg:
                sys.stdout.write('\n' + msg['content']['data'])

        elif msg['msg_type'] == 'shutdown_reply':
            sys.exit(0)

        elif (msg['msg_type'] == 'status'
              and msg['content']['execution_state'] == 'idle'
              and print_idle):
            sys.stdout.write('\n' + 'idle')
            print_idle = False

        elif not msg['msg_type'] == 'status':
            print 'msg_type = %s' % str(msg['msg_type'])
            print 'msg = %s' % str(msg)
        sys.stdout.flush()
