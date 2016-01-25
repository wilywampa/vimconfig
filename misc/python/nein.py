import numpy as _np


def dot(a, b, axisa=0, axisb=0, c=None):
    """Vector dot product along specified axes of ndarrays."""
    if a.shape[axisa] != b.shape[axisb]:
        raise ValueError(_error(a, b, axisa, axisb))
    if axisa:
        a = _np.rollaxis(a, axisa)
    if axisb:
        b = _np.rollaxis(b, axisb)
    if c is None:
        c = _empty(a, b, max((a.shape, b.shape), key=len)[1:], zero=True)
    else:
        c[:] = 0
    for a, b in zip(a, b):
        c += a * b
    return c


def mtimesv(a, b, axisa=0, axisb=0, axisc=0, transposea=False, **kwargs):
    """Matrix/vector multiplication along specified axes of ndarrays."""
    axisa, axisb = _normalize_indices(a, b, axisa, axisb)
    n = a.shape[axisa]
    if n != a.shape[axisa + 1] or n != b.shape[axisb]:
        raise ValueError(_error(a, b, axisa, axisb))
    a = _rollaxis_matrix(a, axisa)
    if axisb:
        b = _np.rollaxis(b, axisb)
    if kwargs.get('ta', transposea):
        a = a.swapaxes(0, 1)
    c = kwargs.get(
        'c', _empty(a, b, (3,) + max((a.shape[2:], b.shape[1:]), key=len)))
    for col, row in enumerate(a):
        c[col] = dot(row, b, c=c[col])
    return _np.rollaxis(c, 0, axisc + 1)


def mtimesm(a, b, axisa=0, axisb=0, axisc=0,
            transposea=False, transposeb=False, transposec=False, **kwargs):
    """Matrix/matrix multiplication along specified axes of ndarrays."""
    axisa, axisb = _normalize_indices(a, b, axisa, axisb)
    n = a.shape[axisa]
    if not (n == a.shape[axisa + 1] == b.shape[axisb] == b.shape[axisb + 1]):
        raise ValueError(_error(a, b, axisa, axisb))
    a = _rollaxis_matrix(a, axisa)
    b = _rollaxis_matrix(b, axisb)
    if kwargs.get('ta', transposea):
        a = a.swapaxes(0, 1)
    if kwargs.get('tb', transposea):
        b = b.swapaxes(0, 1)
    c = _empty(a, b, max((a.shape, b.shape), key=len))
    for col, row in enumerate(b.swapaxes(0, 1)):
        c[col] = mtimesv(a, row, c=c[col])
    if kwargs.get('tc', transposec):
        return c
    return c.swapaxes(0, 1)


def cross(a, b, axisa=0, axisb=0, axisc=0):
    """Vector cross product along specified axes of ndarrays."""
    if (a.ndim != b.ndim and
            a.shape not in [(2,), (3,)] and
            b.shape not in [(2,), (3,)]):
        return _np.cross(a, b, axisa=axisa, axisb=axisb, axisc=axisc)
    axisa, axisb = _normalize_indices(a, b, axisa, axisb)
    n = a.shape[axisa]
    if n not in [2, 3]:
        raise NotImplementedError(
            "Only 2D and 3D cross products are implemented")
    if n != b.shape[axisb]:
        raise ValueError(_error(a, b, axisa, axisb))
    if axisa:
        a = _np.rollaxis(a, axisa)
    if axisb:
        b = _np.rollaxis(b, axisb)
    if n == 2:
        c = a[0] * b[1] - a[1] * b[0]
    else:
        concatenate = _np.concatenate
        if any(isinstance(x, np.ma.MaskedArray) for x in (a, b)):
            concatenate = _np.ma.concatenate
        c = concatenate([x[_np.newaxis] for x in (
            a[1] * b[2] - a[2] * b[1],
            a[2] * b[0] - a[0] * b[2],
            a[0] * b[1] - a[1] * b[0],
        )])
    return _np.rollaxis(c, 0, axisc + 1)


def _empty(a, b, shape, zero=False):
    usemask = any(isinstance(x, _np.ma.MaskedArray) for x in (a, b))
    if zero:
        func = _np.ma.zeros if usemask else _np.zeros
    else:
        func = _np.ma.empty if usemask else _np.empty
    return func(shape)


def _normalize_indices(a, b, axisa, axisb):
    """Make indices positive."""
    if axisa < 0:
        axisa += len(a.shape)
    if axisb < 0:
        axisb += len(b.shape)
    return axisa, axisb


def _rollaxis_matrix(a, axis):
    """Roll `axis` and `axis + 1` to the front of `a`."""
    if not axis:
        return a
    return _np.rollaxis(_np.rollaxis(a, axis), axis + 1, 1)


def _error(a, b, axisa, axisb):
    def shape(x, axis):
        return 'shape={shape} axis={axis}'.format(
            shape=x.shape, axis=axis)

    return 'Shapes of a ({a}) and b ({b}) do not match'.format(
        a=shape(a, axisa), b=shape(b, axisb))


if __name__ == '__main__':
    import numpy as np
    from numpy.testing.utils import assert_allclose
    x = np.random.uniform(size=(100, 3, 200))
    y = np.random.uniform(size=(100, 200, 3))
    m = np.random.uniform(size=(3, 3, 100, 200))
    n = np.random.uniform(size=(100, 3, 3, 200))
    z = dot(x, y, axisa=1, axisb=2)
    assert_allclose(z[50, 75], np.dot(x[50, :, 75], y[50, 75, :]))
    z = dot(x, y, axisa=1, axisb=-1)
    assert_allclose(z[50, 75], np.dot(x[50, :, 75], y[50, 75, :]))
    a = mtimesv(m, y, axisa=0, axisb=2, axisc=2)
    assert_allclose(a[50, 75, :], np.dot(m[:, :, 50, 75], y[50, 75, :]))
    a = mtimesv(m, y, axisa=0, axisb=2, axisc=2, transposea=True)
    assert_allclose(a[50, 75, :], np.dot(m[:, :, 50, 75].T, y[50, 75, :]))
    z = np.random.uniform(size=(3,))
    assert_allclose(mtimesv(m, z)[:, 10, 20], np.dot(m[:, :, 10, 20], z))
    b = mtimesm(m, n, axisa=0, axisb=1)
    assert_allclose(b[:, :, 50, 75], np.dot(m[:, :, 50, 75], n[50, :, :, 75]))
    b = mtimesm(m, n, axisa=0, axisb=-3)
    assert_allclose(b[:, :, 50, 75], np.dot(m[:, :, 50, 75], n[50, :, :, 75]))
    c = np.random.uniform(size=(3, 3))
    d = mtimesm(m, c, axisa=0, axisb=0, transposec=True)
    assert_allclose(d[:, :, 50, 75], np.dot(m[:, :, 50, 75], c).T)
    d = mtimesm(c, m, axisa=0, axisb=0)
    assert_allclose(d[:, :, 50, 75], np.dot(c, m[:, :, 50, 75]))
    e = cross(x, y, axisa=1, axisb=2)
    assert_allclose(e[:, 75, 50], np.cross(x[75, :, 50], y[75, 50, :]))
    f = np.random.uniform(size=(3))
    g = cross(f, y, axisb=2)
    assert_allclose(g[:, 50, 75], np.cross(f, y[50, 75, :]))
    h = np.random.uniform(size=(20, 30, 2))
    i = np.random.uniform(size=(20, 2, 30))
    j = cross(h, i, axisa=-1, axisb=1)
    assert_allclose(j[10, 15], np.cross(h[10, 15, :], i[10, :, 15]))
    y = np.random.uniform(size=(3, 200))
    assert_allclose(cross(x, y, axisa=1)[:, 10, 20],
                    np.cross(x[10, :, 20], y[:, 20]))
