import greenlet
import logging
import neovim
import os
from functools import partial
from jupyter_client import KernelManager, find_connection_file

logger = logging.getLogger(__name__)
error, debug, info, warn = (
    logger.error, logger.debug, logger.info, logger.warn,)
if 'NVIM_IPY_DEBUG_FILE' in os.environ:
    logfile = os.environ['NVIM_IPY_DEBUG_FILE'].strip()
    logger.addHandler(logging.FileHandler(logfile, 'w'))
    logger.level = logging.DEBUG


class RedirectingKernelManager(KernelManager):
    def _launch_kernel(self, cmd, **b):
        debug('_launch_kernel')
        # stdout is used to communicate with nvim, redirect it somewhere else
        self._null = open("/dev/null", "wb", 0)
        b['stdout'] = self._null.fileno()
        b['stderr'] = self._null.fileno()
        return super(RedirectingKernelManager, self)._launch_kernel(cmd, **b)


class Async(object):
    """Wrapper that defers all method calls on a plugin object to the event
    loop, given that the object has vim attribute"""

    def __init__(self, wraps):
        self.wraps = wraps

    def __getattr__(self, name):
        return partial(self.wraps.vim.async_call, getattr(self.wraps, name))


@neovim.plugin
@neovim.encoding(True)
class IPythonPlugin(object):

    def __init__(self, vim):
        debug('__init__')
        self.vim = vim

    @neovim.function("IPyConnect", sync=True)
    def ipy_connect(self, args):
        debug('ipy_connect')
        # 'connect' waits for kernelinfo, and so must be async
        client.vim = self.vim
        Async(client).connect(args)


class IPythonClient(object):

    def __init__(self):
        self.has_connection = False
        self.wrote_connected = False
        self.pending_shell_msgs = {}
        self.km = None
        self.kc = None

    def connect(self, argv):
        debug('connect')
        self.km = RedirectingKernelManager(
            client_class='jupyter_client.threaded.ThreadedKernelClient')
        self.km.load_connection_file(
            connection_file=find_connection_file(*argv))
        if self.kc:
            self.kc.stop_channels()
            self.kc = None
        self.kc = self.km.client()
        self.kc.shell_channel.call_handlers = Async(self).on_shell_msg
        self.kc.hb_channel.call_handlers = Async(self).on_hb_msg
        self.kc.start_channels()
        self.has_connection = True
        self.wrote_connected = False

    def handle(self, msg_id, handler):
        debug('handle')
        self.pending_shell_msgs[msg_id] = handler

    def waitfor(self, msg_id, retval=None):
        debug('waitfor')
        # FIXME: add some kind of timeout
        gr = greenlet.getcurrent()
        self.handle(msg_id, gr)
        return gr.parent.switch(retval)

    def ignore(self, msg_id):
        debug('ignore')
        self.handle(msg_id, None)

    def on_shell_msg(self, m):
        debug('on_shell_msg')
        if not self.wrote_connected:
            self.vim.out_write('IPython connected.\n')
            self.wrote_connected = True
        msg_id = m['parent_header']['msg_id']
        try:
            handler = self.pending_shell_msgs.pop(msg_id)
        except KeyError:
            debug('unexpected shell msg: %r', m)
            return
        if isinstance(handler, greenlet.greenlet):
            handler.parent = greenlet.getcurrent()
            handler.switch(m)
        elif handler is not None:
            handler(m)

    def on_hb_msg(self, time_since):
        """this gets called when heartbeat is lost."""
        debug('on_hb_msg')
        if self.has_connection:
            self.vim.err_write('IPython connection lost.\n')
        self.has_connection = False
        self.kc.stop_channels()


client = IPythonClient()
