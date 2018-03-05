import logging
import os
import zmq
from jupyter_client import KernelManager, find_connection_file
from queue import Empty

logger = logging.getLogger(__name__)
error, debug, info, warn = (
    logger.error, logger.debug, logger.info, logger.warn,)
if 'NVIM_IPY_DEBUG_FILE' in os.environ:
    logfile = os.environ['NVIM_IPY_DEBUG_FILE'].strip()
    handler = logging.FileHandler(logfile, 'w')
    handler.setFormatter(logging.Formatter('%(asctime)s: %(message)s'))
    logger.addHandler(handler)
    logger.setLevel(logging.DEBUG)


class RedirectingKernelManager(KernelManager):
    def _launch_kernel(self, cmd, **b):
        debug('_launch_kernel')
        # stdout is used to communicate with nvim, redirect it somewhere else
        self._null = open("/dev/null", "wb", 0)
        b['stdout'] = self._null.fileno()
        b['stderr'] = self._null.fileno()
        return super(RedirectingKernelManager, self)._launch_kernel(cmd, **b)


class IPythonClient(object):

    def __init__(self, vim):
        self.has_connection = False
        self.pending_shell_msgs = {}
        self.km = None
        self.kc = None
        self.vim = vim

    def connect(self, connection_file=None):
        debug('connect')
        self.has_connection = False
        self.km = RedirectingKernelManager(
            client_class='jupyter_client.blocking.BlockingKernelClient')
        if isinstance(connection_file, str) and not os.path.isfile(
                connection_file):
            connection_file = find_connection_file(connection_file)
        try:
            self.km.load_connection_file(connection_file=connection_file)
        except OSError:
            self.vim.out_write('Could not load Jupyter connection file')
            return
        if self.kc:
            self.kc.stop_channels()
            self.kc = None
        self.kc = self.km.client()
        self.kc.shell_channel.call_handlers = self.on_shell_msg
        self.kc.hb_channel.call_handlers = self.on_hb_msg
        self.kc.start_channels()
        if self.waitfor(self.kc.kernel_info()):
            self.has_connection = True

    def handle(self, msg_id, handler):
        debug('handle')
        self.pending_shell_msgs[msg_id] = handler

    def waitfor(self, msg_id, timeout=None):
        debug('waitfor')
        if not timeout:
            timeout = float(self.vim.vars.get('ipython_timeout', 1))
        while 1:
            try:
                reply = self.kc.shell_channel.get_msg(timeout=timeout)
            except Empty:
                return
            except zmq.error.ZMQError:
                self.has_connection = False
                return
            if reply and reply['parent_header']['msg_id'] == msg_id:
                return reply

    def ignore(self, msg_id):
        debug('ignore')
        self.handle(msg_id, None)

    def on_shell_msg(self, m):
        debug('on_shell_msg')
        msg_id = m['parent_header']['msg_id']
        try:
            handler = self.pending_shell_msgs.pop(msg_id)
        except KeyError:
            debug('unexpected shell msg: %r', m)
            return
        if handler is not None:
            handler(m)

    def on_hb_msg(self, time_since):
        """this gets called when heartbeat is lost."""
        debug('on_hb_msg')
        if self.has_connection:
            self.vim.err_write('IPython connection lost.\n')
        self.has_connection = False
        try:
            self.kc.stop_channels()
        except RuntimeError:
            pass
