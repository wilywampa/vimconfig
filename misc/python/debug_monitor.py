import logging
import runpy
import sys

logger = logging.getLogger('__main__')
logger.addHandler(logging.StreamHandler(sys.stderr))
logger.setLevel(logging.DEBUG)
runpy.run_module('ipython_monitor', run_name='__main__')
