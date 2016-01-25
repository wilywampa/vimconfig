import numpy as _np
import string as _str

eijk = _np.zeros((3, 3, 3), dtype='d')
eijk[0, 1, 2] = eijk[1, 2, 0] = eijk[2, 0, 1] = 1
eijk[0, 2, 1] = eijk[2, 1, 0] = eijk[1, 0, 2] = -1
eijk.flags.writeable = False

eij = _np.array([[0, 1], [-1, 0]], dtype='d')
eij.flags.writeable = False

_LS = _str.ascii_lowercase
_LS = _LS[_LS.index('m'):]


def _ein(a, b, stra, strb, strc):
    subscripts = '{a}, {b} -> {c}'.format(a=stra, b=strb, c=strc)
    return _np.einsum(subscripts, a, b)


def _normalize_indices(a, b, axisa, axisb):
    if axisa < 0:
        axisa += len(a.shape)
    if axisb < 0:
        axisb += len(b.shape)
    return axisa, axisb


def dot(a, b, axisa=0, axisb=0):
    """Vector dot product along specified axes of ndarrays."""
    axisa, axisb = _normalize_indices(a, b, axisa, axisb)
    if a.shape[axisa] != b.shape[axisb]:
        raise ValueError(_error(a, b, axisa, axisb))
    stra = '%si%s' % (_LS[:axisa], _LS[axisa:len(a.shape) - 1])
    strb = '%si%s' % (_LS[:axisb], _LS[axisb:len(b.shape) - 1])
    series = ''.join(sorted(x for x in _LS if x in stra or x in strb))
    return _ein(a, b, stra, strb, series)


def mtimesv(a, b, axisa=0, axisb=0, axisc=0, transposea=False, **kwargs):
    """Matrix/vector multiplication along specified axes of ndarrays."""
    axisa, axisb = _normalize_indices(a, b, axisa, axisb)
    n = a.shape[axisa]
    if n != a.shape[axisa + 1] or n != b.shape[axisb]:
        raise ValueError(_error(a, b, axisa, axisb))
    transposea = kwargs.get('ta', transposea)
    stra = '%s%s%s' % (_LS[:axisa], 'ji' if transposea else 'ij',
                       _LS[axisa:len(a.shape) - 2])
    strb = '%sj%s' % (_LS[:axisb], _LS[axisb:len(b.shape) - 1])
    series = ''.join(sorted(x for x in _LS if x in stra or x in strb))
    if axisc < 0:
        axisc += len(series) + 1
    strc = '%si%s' % (series[:axisc], series[axisc:])
    return _ein(a, b, stra, strb, strc)


def mtimesm(a, b, axisa=0, axisb=0, axisc=0,
            transposea=False, transposeb=False, transposec=False, **kwargs):
    """Matrix/matrix multiplication along specified axes of ndarrays."""
    axisa, axisb = _normalize_indices(a, b, axisa, axisb)
    n = a.shape[axisa]
    if not (n == a.shape[axisa + 1] == b.shape[axisb] == b.shape[axisb + 1]):
        raise ValueError(_error(a, b, axisa, axisb))
    transposea = kwargs.get('ta', transposea)
    transposeb = kwargs.get('tb', transposeb)
    transposec = kwargs.get('tc', transposec)
    stra = '%s%s%s' % (_LS[:axisa], 'ji' if transposea else 'ij',
                       _LS[axisa:len(a.shape) - 2])
    strb = '%s%s%s' % (_LS[:axisb], 'kj' if transposeb else 'jk',
                       _LS[axisb:len(b.shape) - 2])
    series = ''.join(sorted(x for x in _LS if x in stra or x in strb))
    if axisc < 0:
        axisc += len(series) + 2
    strc = '%s%s%s' % (series[:axisc], 'ki' if transposec else 'ik',
                       series[axisc:])
    return _ein(a, b, stra, strb, strc)


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
    if n == 2:
        return _cross2d(a, b, axisa, axisb, axisc)
    strb = '%sj%s' % (_LS[:axisa], _LS[axisa:len(a.shape) - 1])
    strc = 'ik%s' % strb.replace('j', '')
    a = _ein(eijk, a, 'ijk', strb, strc)
    stra = strc
    strb = '%sk%s' % (_LS[:axisb], _LS[axisb:len(b.shape) - 1])
    series = ''.join(sorted(x for x in _LS if x in stra or x in strb))
    if axisc < 0:
        axisc += len(series) + 1
    strc = '%si%s' % (series[:axisc], series[axisc:])
    return _ein(a, b, stra, strb, strc)


def _cross2d(a, b, axisa, axisb, axisc):
    strb = '%si%s' % (_LS[:axisa], _LS[axisa:len(a.shape) - 1])
    strc = 'j%s' % strb.replace('i', '')
    a = _ein(eij, a, 'ij', strb, strc)
    stra = strc
    strb = '%sj%s' % (_LS[:axisb], _LS[axisb:len(b.shape) - 1])
    series = ''.join(sorted(x for x in _LS if x in stra or x in strb))
    if axisc < 0:
        axisc += len(series) + 1
    strc = '%s%s' % (series[:axisc], series[axisc:])
    return _ein(a, b, stra, strb, strc)


def _error(a, b, axisa, axisb):
    def shape(x, axis):
        return 'shape={shape} axis={axis}'.format(
            shape=x.shape, axis=axis)

    return 'Shapes of a ({a}) and b ({b}) do not match'.format(
        a=shape(a, axisa), b=shape(b, axisb))


if not hasattr(_np, 'einsum'):
    from nein import cross, dot, mtimesm, mtimesv  # noqa

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
