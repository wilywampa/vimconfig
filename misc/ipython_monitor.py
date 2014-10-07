from IPython.kernel import KernelManager
from IPython.kernel import find_connection_file
import sys
from pygments import highlight
from pygments.lexers import PythonLexer
from pygments.formatters import TerminalFormatter

colors = {
    'red':      '31',
    'orange':   '31;1',
    'green':    '32',
    'yellow':   '33',
    'blue':     '34',
    'magenta':  '35',
    'purple':   '35;1',
    'cyan':     '36',
    'white':    '37',
    'black':    '30',
    'none':     '32;1',
}

km = KernelManager()
fullpath = find_connection_file('kernel*')
km = KernelManager(connection_file=fullpath)
km.load_connection_file()

kc = km.client()
kc.start_channels()

if len(sys.argv) > 1:
    term = open(sys.argv[1], 'w+')
    sys.stdout = term

lexer = PythonLexer()
formatter = TerminalFormatter()

print_idle = False
socket = km.connect_iopub()
while socket.recv():
    kc.iopub_channel.flush()
    msgs = kc.iopub_channel.get_msgs()
    for msg in msgs:
        if msg['msg_type'] == 'pyin':
            prompt = ''.join('In [%d]: ' % msg['content']['execution_count'])
            dots = '.' * len(prompt.rstrip()) + ' '
            prompt = '\n\033[' + colors['green'] + 'm' + prompt + '\033[0m'
            sys.stdout.write(prompt)
            code = highlight(msg['content']['code'], lexer, formatter)
            output = code.rstrip().replace('\n', '\n' + dots)
            sys.stdout.write(output + '\n')
            print_idle = True
        elif msg['msg_type'] == 'pyout':
            sys.stdout.write(''.join(('\n\033[', colors['red'], 'm', 'Out [%d]:'
                                      % msg['content']['execution_count'],
                                      '\n\033[m%s' %
                                      msg['content']['data']['text/plain'])))
        elif msg['msg_type'] == 'pyerr':
            for line in msg['content']['traceback']:
                sys.stdout.write('\n' + line)
        elif msg['msg_type'] == 'stream':
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
