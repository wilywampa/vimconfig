from numpy import einsum as _einsum
from numpy import empty as _empty

eijk = _empty((3, 3, 3))
eijk[0, 1, 2] = eijk[1, 2, 0] = eijk[2, 0, 1] = 1
eijk[0, 2, 1] = eijk[2, 1, 0] = eijk[1, 0, 2] = -1


def dot(a, b):
    if len(a.shape) == 2 and len(b.shape) == 2:
        return _einsum('ni, ni -> n', a, b)
    elif len(a.shape) == 3 and len(b.shape) == 2:
        return _einsum('nij, nj -> ni', a, b)
    elif len(a.shape) == 3 and len(b.shape) == 3:
        return _einsum('nij, njk -> nik', a, b)
    else:
        raise ValueError('Unknown shapes')


def cross(a, b):
    if len(a.shape) == 1:
        return _einsum('ik, nk -> ni', _einsum('ijk, j -> ik', eijk, a), b)
    else:
        return _einsum('nik, nk -> ni', _einsum('ijk, nj -> nik', eijk, a), b)
