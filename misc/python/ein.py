# pylama: ignore=W0404
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


def dot(a, b, axisa=0, axisb=0):
    """Vector dot product along specified axes of ndarrays."""
    if not hasattr(_np, 'einsum'):
        import nein
        return nein.dot(a, b, axisa, axisb)
    a, b = _asarray(a, b)
    axisa, axisb = _normalize_indices(a, b, axisa, axisb)
    if a.shape[axisa] != b.shape[axisb]:
        raise ValueError(_error(a, b, axisa, axisb))
    stra = '%si%s' % (_LS[:axisa], _LS[axisa:len(a.shape) - 1])
    strb = '%si%s' % (_LS[:axisb], _LS[axisb:len(b.shape) - 1])
    series = ''.join(sorted(x for x in _LS if x in stra or x in strb))
    mask = _collapse_mask(_np.rollaxis(a, axisa),
                          _collapse_mask(_np.rollaxis(b, axisb)))
    return _ein(a, b, stra, strb, series, mask=mask)


def mtimesv(a, b, axisa=0, axisb=0, axisc=0, transposea=False, **kwargs):
    """Matrix/vector multiplication along specified axes of ndarrays."""
    if not hasattr(_np, 'einsum'):
        import nein
        return nein.mtimesm(a, b, axisa, axisb, axisc, transposea, **kwargs)
    a, b = _asarray(a, b)
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
    mask = _collapse_mask(_np.rollaxis(b, axisb))
    if isinstance(a, _np.ma.MaskedArray):
        if a.ndim > 2:
            x = _np.rollaxis(_np.rollaxis(a, axisa), axisa + 1, 1)
            for row in x:
                mask = _collapse_mask(row, mask)
        elif a.mask.any():
            mask = True
        elif mask is None:
            mask = False
    return _ein(a, b, stra, strb, strc, mask=mask, mask_axes=(axisc,))


def mtimesm(a, b, axisa=0, axisb=0, axisc=0,
            transposea=False, transposeb=False, transposec=False, **kwargs):
    """Matrix/matrix multiplication along specified axes of ndarrays."""
    if not hasattr(_np, 'einsum'):
        import nein
        return nein.mtimesm(a, b, axisa, axisb, axisc,
                            transposea, transposeb, transposec, **kwargs)
    a, b = _asarray(a, b)
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
    mask = None
    for x, ax in (a, axisa), (b, axisb):
        if isinstance(x, _np.ma.MaskedArray):
            if x.ndim > 2:
                x = _np.rollaxis(_np.rollaxis(a, ax), ax + 1, 1)
                for row in x:
                    mask = _collapse_mask(row, mask)
            elif x.mask.any():
                mask = True
            elif mask is None:
                mask = False
    return _ein(a, b, stra, strb, strc, mask=mask, mask_axes=(axisc, axisc + 1))


def cross(a, b, axisa=0, axisb=0, axisc=0):
    """Vector cross product along specified axes of ndarrays."""
    if not hasattr(_np, 'einsum'):
        import nein
        return nein.cross(a, b, axisa, axisb, axisc)
    a, b = _asarray(a, b)
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
    mask = _collapse_mask(_np.rollaxis(a, axisa),
                          _collapse_mask(_np.rollaxis(b, axisb)))
    return _ein(a, b, stra, strb, strc, mask=mask, mask_axes=(axisc,))


def _ein(a, b, stra, strb, strc, mask=None, mask_axes=()):
    subscripts = '{a}, {b} -> {c}'.format(a=stra, b=strb, c=strc)
    out = _np.einsum(subscripts, a, b)
    if mask is not None:
        if mask_axes and getattr(mask, 'shape', None):
            out = _np.ma.masked_array(out, mask=False)
            axes = mask_axes + tuple(x for x in range(out.ndim)
                                     if x not in mask_axes)
            out = _np.transpose(out, axes)
            out[..., mask] = _np.ma.masked
            out = _np.transpose(out, _np.argsort(axes))
        else:
            out = _np.ma.masked_array(out, mask=mask)
    return out


def _normalize_indices(a, b, axisa, axisb):
    """Make indices positive."""
    if axisa < 0:
        axisa += len(a.shape)
    if axisb < 0:
        axisb += len(b.shape)
    return axisa, axisb


def _collapse_mask(a, mask=None):
    """Combine masks along the first axis of `a`."""
    if not isinstance(a, _np.ma.MaskedArray):
        return mask
    if mask is None:
        mask = _np.zeros(a.shape[1:], dtype=bool)
    if a.mask.shape:
        for m in a.mask:
            mask |= m
    else:
        mask |= a.mask
    return mask


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
    mask = _collapse_mask(_np.rollaxis(a, axisa),
                          _collapse_mask(_np.rollaxis(b, axisb)))
    return _ein(a, b, stra, strb, strc, mask=mask)


def _error(a, b, axisa, axisb):
    def shape(x, axis):
        return 'shape={shape} axis={axis}'.format(
            shape=x.shape, axis=axis)

    return 'Shapes of a ({a}) and b ({b}) do not match'.format(
        a=shape(a, axisa), b=shape(b, axisb))


def _asarray(*arrays):
    return tuple(_np.asanyarray(a) for a in arrays)


if __name__ == '__main__':

    def test():
        import numpy as np
        from numpy.random import randn
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
        assert_allclose(a[50, 75, :], np.dot(m[..., 50, 75], y[50, 75, :]))
        a = mtimesv(m, y, axisa=0, axisb=2, axisc=2, transposea=True)
        assert_allclose(a[50, 75, :], np.dot(m[..., 50, 75].T, y[50, 75, :]))
        z = np.random.uniform(size=(3,))
        assert_allclose(mtimesv(m, z)[:, 10, 20], np.dot(m[..., 10, 20], z))
        b = mtimesm(m, n, axisa=0, axisb=1)
        assert_allclose(b[..., 50, 75], np.dot(m[..., 50, 75], n[50, ..., 75]))
        b = mtimesm(m, n, axisa=0, axisb=-3)
        assert_allclose(b[..., 50, 75], np.dot(m[..., 50, 75], n[50, ..., 75]))
        c = np.random.uniform(size=(3, 3))
        d = mtimesm(m, c, axisa=0, axisb=0, transposec=True)
        assert_allclose(d[..., 50, 75], np.dot(m[..., 50, 75], c).T)
        d = mtimesm(c, m, axisa=0, axisb=0)
        assert_allclose(d[..., 50, 75], np.dot(c, m[..., 50, 75]))
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
        mtimesv(np.ma.masked_array(randn(3, 3), mask=True),
                np.ma.masked_array(randn(3, 3, 1000)))
        x = mtimesv(np.ma.masked_array(randn(3, 3), mask=True),
                    randn(3, 3, 1000))
        assert x.mask.all()
        x = dot(np.ma.masked_array(randn(3)), randn(3, 10))
        assert isinstance(x, np.ma.MaskedArray)
        x = dot(randn(3, 10), np.ma.masked_array(randn(3), mask=False))
        assert not x.mask.any()
        x = dot(randn(3, 10), np.ma.masked_array(randn(3), mask=True))
        assert x.mask.all()
        x = dot(np.ma.masked_array(randn(3, 10), mask=True), randn(3))
        assert x.mask.all()
        x = mtimesv(randn(3, 3), np.ma.masked_array(randn(3), mask=True))
        assert x.mask.all()
        x = mtimesv(randn(3, 3), np.ma.masked_array(randn(3), mask=False))
        assert not x.mask.any()
        x = mtimesv(np.ma.masked_array(randn(3, 3), mask=True), randn(3))
        assert x.mask.all()
        x = mtimesv(np.ma.masked_array(randn(3, 3), mask=False), randn(3))
        assert not x.mask.any()
        x = mtimesm(randn(3, 3), np.ma.masked_array(randn(3, 3), mask=True))
        assert x.mask.all()
        x = mtimesm(np.ma.masked_array(randn(3, 3), mask=True), randn(3, 3))
        assert x.mask.all()
        x = mtimesm(randn(3, 3), np.ma.masked_array(randn(3, 3), mask=False))
        assert not x.mask.any()
        x = mtimesm(np.ma.masked_array(randn(3, 3), mask=False), randn(3, 3))
        assert not x.mask.any()

    assert hasattr(_np, 'einsum')
    test()
    from nein import cross, dot, mtimesm, mtimesv
    test()
