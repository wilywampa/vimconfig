from IPython import get_ipython
from IPython.core.inputtransformer import StatelessInputTransformer
from os.path import expanduser, expandvars, isdir, sep

_REGISTRIES = ['input_splitter', 'input_transformer_manager']


@StatelessInputTransformer.wrap
def autocd_transformer(line):
    """Automatically prepend 'cd' to a line containing a bare directory."""
    # Check for blank line
    stripped = line.strip()
    if not stripped:
        return line

    if stripped[0] not in [sep, '~', '$', '.']:
        return line

    path = expandvars(expanduser(stripped))
    if isdir(path):
        return 'cd ' + path

    return line


def register():
    unregister()
    for registry in _REGISTRIES:
        getattr(get_ipython(), registry).logical_line_transforms.insert(
            0, autocd_transformer())


def unregister():
    for registry in _REGISTRIES:
        transforms = getattr(get_ipython(), registry).logical_line_transforms
        transforms[:] = [t for t in transforms
                         if t.func.__name__ != 'autocd_transformer']
