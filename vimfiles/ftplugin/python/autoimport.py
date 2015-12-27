import ast
import imp
import io
import itertools
import os
import re
import textwrap
import tokenize
import vim
from collections import namedtuple

Import = namedtuple('Import',
                    ['module', 'names', 'asnames', 'alias', 'lrange'])

imports = []
start = 0                      # Start of import block near top of file
end = len(vim.current.buffer)  # End of import block
blank = None                   # First blank line after start of import block
first = None                   # First regular import or import ... as
last = None                    # Last regular import or import ... as
first_from = None              # First from ... import
last_from = None               # Last from ... import

try:
    root = ast.parse('\n'.join(vim.current.buffer))
except SyntaxError as e:
    root = ast.parse('\n'.join(vim.current.buffer[:e.lineno - 1]))


def import_len(node):
    length = 1
    tries = [s.strip() for s in vim.current.buffer[node.lineno - 1].split(';')]
    while True:
        try:
            if len(tries) > 1:
                text = [tries[0]]
            else:
                text = vim.current.buffer[
                    (node.lineno - 1): (node.lineno - 1 + length)]
                text[0] = tries[0]
            root = ast.parse('\n'.join(text))
        except SyntaxError:
            length += 1
            continue
        if (set([n.asname for n in root.body[0].names]) ==
                set([n.asname for n in node.names])):
            break
        elif length >= len(vim.current.buffer):
            break
        if len(tries) > 1:
            tries.pop(0)
        else:
            length += 1
    return length


for node in ast.iter_child_nodes(root):
    if blank and node.lineno >= blank:
        break

    if isinstance(node, ast.Import):
        module = []
        if not first:
            first = node.lineno
        last = node.lineno
    elif isinstance(node, ast.ImportFrom):
        module = node.module
        if not first_from:
            first_from = node.lineno
        last_from = node.lineno
    elif start:
        break
    else:
        continue

    end = node.lineno + import_len(node) - 1

    if not start:
        try:
            blank = next(
                (i for i, l in enumerate(
                    vim.current.buffer[end:], end)
                    if re.match('^\s*(#.*)?$', l))) + 1
        except StopIteration:
            blank = len(vim.current.buffer)
    start = start or first or first_from

    imports.append(Import(module=module, names=[n.name for n in node.names],
                          asnames=[n.asname or n.name for n in node.names],
                          alias=next((n.asname for n in node.names
                                      if n.asname), None),
                          lrange=(node.lineno, end)))

if int(vim.eval('getbufvar("%", "ipython_user_ns", 0)')):
    add = -1
    found = False
    for line in vim.current.buffer[end:]:
        if re.match(r'^\s*$', line):
            add += 1
        elif re.match(r"^(\S+) \= get_ipython\(\).user_ns\['\1'\]$", line):
            found = True
            add += 1
        else:
            break
    end += add if found else 0

messages = [(m['lnum'], m['text']) for m in vim.eval('messages')]
unused = {int(k): v.split("'")[1] for k, v in messages
          if start <= int(k) <= end and 'W0611' in v}
missing = [m.split("'")[1] for _, m in messages if 'E0602' in m]
redefined = {int(k): v.split("'")[1] for k, v in messages
             if start <= int(k) <= end and 'W0404' in v}

aliases = dict(
    cm='matplotlib.cm',
    colors='matplotlib.colors',
    it='itertools',
    mpl='matplotlib',
    linalg='numpy.linalg',
    ma='numpy.ma',
    mt='mathtools',
    np='numpy',
    op='operator',
    opt='scipy.optimize',
    pickle='cPickle',
    plt='matplotlib.pyplot',
    pt='plottools',
    sc='scipy.constants',
    si='scipy.interpolate',
    signal='scipy.signal',
    sint='scipy.integrate',
    sio='scipy.io',
    spatial='scipy.spatial',
)

froms = {
    'IPython': ['get_ipython', 'parallel'],
    'IPython.core.display': ['display'],
    'IPython.external.path': ['Path', 'path'],
    'IPython.lib.pretty': ['pretty'],
    'IPython.parallel': ['Client', 'Reference', 'interactive'],
    'IPython.utils.text': ['LSString', 'SList'],
    'bs4': ['BeautifulSoup'],
    'bunch': ['Bunch', 'bunchify', 'unbunchify'],
    'collections':
        ['Mapping', 'OrderedDict', 'defaultdict', 'deque', 'namedtuple'],
    'contextlib': ['closing', 'contextmanager', 'suppress'],
    'copy': ['copy', 'deepcopy'],
    'datetime': ['date', 'datetime', 'timedelta'],
    'ein': ['eijk', 'mtimesm', 'mtimesv'],
    'fractions': ['Fraction', 'gcd'],
    'functools': [
        'cmp_to_key', 'partial', 'reduce', 'total_ordering', 'update_wrapper',
        'wraps'],
    'itertools': [
        'chain', 'combinations', 'combinations_with_replacement', 'compress',
        'count', 'cycle', 'dropwhile', 'groupby', 'ifilter', 'ifilterfalse',
        'imap', 'islice', 'izip', 'izip_longest', 'permutations', 'product',
        'repeat', 'starmap', 'takewhile', 'tee'],
    'ipython_config': [
        'dump', 'fields_dict', 'globn', 'items_dict', 'load', 'sortn',
        'sortnkey'],
    'mathtools': ['cat', 'derivative', 'ecat', 'norm0', 'unit'],
    'matplotlib.backends.backend_pdf': ['PdfPages'],
    'matplotlib.pyplot': [
        'Line2D', 'Text', 'annotate', 'arrow', 'autoscale', 'axes', 'axis',
        'cla', 'clf', 'clim', 'close', 'colorbar', 'colormaps', 'colors',
        'contour', 'contourf', 'draw', 'errorbar', 'figaspect', 'figimage',
        'figlegend', 'figtext', 'figure', 'fill_between', 'gca', 'gcf', 'gci',
        'get_backend', 'get_cmap', 'get_current_fig_manager', 'get_figlabels',
        'get_fignums', 'grid', 'hist', 'hist2d', 'interactive', 'ioff', 'ion',
        'legend', 'loglog', 'margins', 'minorticks_off', 'minorticks_on',
        'new_figure_manager', 'normalize', 'plot', 'plot_date', 'plotfile',
        'plotting', 'polar', 'psd', 'quiver', 'quiverkey', 'rcParams',
        'rcParamsDefault', 'rcdefaults', 'savefig', 'scatter', 'semilogx',
        'semilogy', 'specgram', 'show', 'stackplot', 'stem', 'streamplot',
        'subplot', 'subplots', 'suptitle', 'text', 'tight_layout', 'title',
        'tricontour', 'tricontourf', 'triplot', 'twinx', 'twiny',
        'violinplot', 'vlines', 'xlabel', 'xlim', 'xscale', 'xticks',
        'ylabel', 'ylim', 'yscale', 'yticks'],
    'mpl_toolkits.mplot3d': ['Axes3D'],
    'numpy': [
        'allclose', 'alltrue', 'arange', 'arccos', 'arccosh', 'arcsin',
        'arcsinh', 'arctan', 'arctan2', 'arctanh', 'array', 'array_equal',
        'asarray', 'average', 'c_', 'column_stack', 'concatenate', 'cos',
        'cosh', 'cross', 'cumprod', 'cumproduct', 'cumsum', 'deg2rad',
        'degrees', 'diff', 'dot', 'dstack', 'dtype', 'einsum', 'empty', 'exp',
        'eye', 'fromfile', 'fromiter', 'genfromtxt', 'gradient', 'hstack',
        'index_exp', 'inner', 'isinf', 'isnan', 'isreal', 'ix_', 'linspace',
        'loadtxt', 'mat', 'matrix', 'mean', 'median', 'meshgrid', 'mgrid',
        'nanargmax', 'nanargmin', 'nan', 'nanmax', 'nanmean', 'nanmedian',
        'nanmin', 'nanpercentile', 'nanstd', 'nansum', 'nanvar', 'ndarray',
        'ndenumerate', 'ndfromtxt', 'ndim', 'nditer', 'newaxis', 'ones',
        'outer', 'pad', 'pi', 'polyfit', 'polyval', 'r_', 'rad2deg',
        'radians', 'random', 'ravel', 'ravel_multi_index', 'reshape',
        'rollaxis', 'rot90', 's_', 'savez', 'savez_compressed', 'seterr',
        'sin', 'sinc', 'sinh', 'sqrt', 'squeeze', 'std', 'take', 'tan',
        'tanh', 'tile', 'trace', 'transpose', 'trapz', 'vectorize', 'vstack',
        'where', 'zeros'],
    'numpy.core.records': ['fromarrays'],
    'numpy.ma': ['getdata', 'getmaskarray', 'masked_all'],
    'numpy.random': ['rand', 'randint', 'randn'],
    'numpy.linalg': [
        'eig', 'eigh', 'eigvals', 'eigvalsh', 'inv', 'norm', 'lstsq', 'solve',
        'svd', 'tensorinv', 'tensorsolve'],
    'plottools': [
        'azip', 'cl', 'create', 'cursor', 'dataobj', 'dict2obj', 'fg', 'fig',
        'figdo', 'index_all', 'merge_dicts', 'pad', 'picker', 'resize',
        'savehtml', 'savepdf', 'savesvg', 'unique_legend', 'unmask', 'varinfo'],
    'pprint': ['pprint'],
    'pyprimes': ['is_prime', 'primes'],
    'pyprimes.factors': ['factorise', 'factors'],
    're': ['findall', 'match', 'search', 'sub'],
    'scipy.constants': [
        'degree', 'foot', 'g', 'inch', 'kmh', 'knot', 'lb', 'lbf', 'mach',
        'mph', 'nautical_mile', 'pound', 'pound_force', 'psi',
        'speed_of_sound'],
    'scipy.integrate': ['cumtrapz', 'quad', 'romb', 'simps'],
    'six': [
        'BytesIO', 'PY3', 'StringIO', 'iteritems', 'iterkeys', 'iterlists',
        'itervalues', 'string_types', 'text_type', 'viewitems', 'viewkeys',
        'viewvalues'],
    'subprocess': ['PIPE', 'Popen', 'STDOUT', 'call', 'check_output',
                   'list2cmdline'],
    'time': ['time'],
}

froms_as = dict(
    S=('ipython_config', 'SliceIndex'),
    acos=('numpy', 'arccos'),
    acosh=('numpy', 'arccosh'),
    asin=('numpy', 'arcsin'),
    asinh=('numpy', 'arcsinh'),
    atan=('numpy', 'arctan'),
    atan2=('numpy', 'arctan2'),
    atanh=('numpy', 'arctanh'),
    deg=('numpy', 'rad2deg'),
    marray=('numpy.ma', 'masked_array'),
    rad=('numpy', 'deg2rad'),
)

aliases.update(vim.eval('get(g:, "python_autoimport_aliases", {})'))
froms_as.update(vim.eval('get(g:, "python_autoimport_froms_as", {})'))
for k, v in vim.eval('get(g:, "python_autoimport_froms", {})').items():
    froms[k] = set(v) | set(froms.get(k, []))


def remove(i, asname):
    index = i.asnames.index(asname)
    i.names.pop(index)
    i.asnames.pop(index)


def used(name):
    if name in unused.values():
        return False
    else:
        return name in tokens


def remove_unused(i):
    for asname in i.asnames[:]:
        if not used(asname):
            remove(i, asname)


for lnum, r in redefined.items():
    for i in imports:
        if r in i.asnames:
            remove(i, r)

tokens = set()
code = io.StringIO(u'\n'.join(
    line for line in vim.current.buffer[end:] if line.strip() != ''))
for ttype, token, _, _, _ in tokenize.generate_tokens(code.readline):
    if ttype == tokenize.NAME:
        tokens.add(token)

for i in imports:
    if any(n.split('.')[0] in unused.values() for n in i.asnames):
        remove_unused(i)
        for i2 in imports:
            if i.lrange[-1] == i2.lrange[0]:
                remove_unused(i2)

imports = [i for i in imports if i.asnames and i.alias not in unused.values()]


def check_exists(miss):
    exists = vim.eval('get(module_cache, "%s", "")' % miss)
    if exists:
        return int(exists)
    try:
        file_obj, file_path, _ = imp.find_module(miss)
        name = file_path or file_obj.name
        assert os.path.basename(name) in os.listdir(os.path.dirname(name))
        vim.command('let module_cache["%s"] = 1' % miss)
        return True
    except (AssertionError, AttributeError, ImportError):
        not_found.add(miss)
        vim.command('let module_cache["%s"] = 0' % miss)
        return False


names = set(itertools.chain(*[i.asnames + [i.alias] for i in imports]))
missing = list(set(missing) - names)
not_found = set()
for miss in set(missing):
    if miss in aliases:
        imports.append(Import(module=[], names=[aliases[miss]],
                              asnames=[aliases[miss]], alias=miss, lrange=()))
    elif miss in itertools.chain(*froms.values()):
        m = [m for m, v in froms.items() if miss in v][0]
        i = [i for i in imports if m == i.module]
        if i:
            i[0].names.append(miss)
            i[0].asnames.append(miss)
        else:
            imports.append(Import(module=m, names=[miss], asnames=[miss],
                                  alias=None, lrange=()))
    elif miss in froms_as:
        m, n = froms_as[miss]
        i = [i for i in imports if m == i.module]
        if i:
            i[0].names.append(n)
            i[0].asnames.append(miss)
        else:
            imports.append(Import(module=m, names=[n], asnames=[miss],
                                  alias=None, lrange=()))
    elif check_exists(miss):
        imports.append(Import(module=[], names=[miss], asnames=[miss],
                              alias=None, lrange=()))
    else:
        not_found.add(miss)

if not_found and int(vim.eval('getbufvar("%", "ipython_user_ns", 0)')):
    i = next(iter(i for i in imports if i.module == 'IPython'), None)
    if i:
        i.names.append('get_ipython')
        i.asnames.append('get_ipython')
    else:
        imports.append(Import(module='IPython', names=['get_ipython'],
                              asnames=['get_ipython'], alias=None, lrange=()))


def duplicates(imports):
    seen = set()
    duplicates = []
    for i in imports:
        if i.module and i.alias is None:
            if i.module in seen:
                duplicates.append(i.module)
            else:
                seen.add(i.module)
    return duplicates


def combine_duplicates(name):
    duplicates = [index for index, i in enumerate(imports)
                  if i.alias is None and i.module == name]
    new = Import(module=name,
                 names=[n for i in duplicates for n in imports[i].names],
                 asnames=[a for i in duplicates for a in imports[i].asnames],
                 alias=None, lrange=())
    return [i for index, i in enumerate(imports)
            if index not in duplicates] + [new]


for d in duplicates(imports):
    imports = combine_duplicates(d)

lines = []
for i in imports:
    names = set(zip(i.names, i.asnames))
    i.names[:], i.asnames[:] = zip(*names) if names else ([], [])
    if not i.module:
        if i.alias:
            lines.append(['import {module} as {alias}'.format(
                module=i.names[0], alias=i.alias)])
        else:
            lines.append(['import {module}'.format(module=i.names[0])])
    else:
        newline = 'from {module} import ({names})'.format(
            module=i.module, names=', '.join(sorted(
                [('{0}' if name[0] == name[1] else '{0} as {1}').format(*name)
                 for name in names], key=lambda s: s.split()[-1])))
        if len(newline) <= 80:
            lines.append([newline.replace('(', '').replace(')', '')])
        else:
            lines.append(textwrap.wrap(newline,
                                       subsequent_indent=" " * (
                                           newline.index('(') + 1),
                                       break_long_words=False))


def key(item):
    if item[0].lstrip().startswith('from __future__'):
        return -1
    elif item[0].lstrip().startswith('from'):
        return 1
    return 0


lines = sorted(sorted(lines), key=key)

if not_found and int(vim.eval('getbufvar("%", "ipython_user_ns", 0)')):
    lines.append([''])
    lines.extend(
        [["{0} = get_ipython().user_ns['{0}']".format(name)]
         for name in sorted(not_found)])

lines = [l for ls in lines for l in ls]
if unused or missing or redefined:
    if start:
        if vim.current.buffer[start - 1:end] != lines:
            if vim.current.buffer[end - 1] == '':
                end -= 1
            vim.current.buffer[start - 1:end] = lines
    elif lines:
        if re.match(r'^(@|class\s|def\s)', vim.current.buffer[0]):
            lines.extend(['', ''])
        elif re.search(r'\S', vim.current.buffer[0]):
            lines.append('')
        vim.current.buffer[:] = lines + vim.current.buffer[:]
if not lines:
    while re.match(r'^\s*$', vim.current.buffer[0]):
        vim.current.buffer[:2] = [vim.current.buffer[1]]
