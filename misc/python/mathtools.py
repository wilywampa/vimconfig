import numpy as np

__all__ = [
    'angle_between',
    'cat',
    'derivative',
    'ecat',
    'norm',
    'norm0',
    'projection',
    'unit',
]


def angle_between(a, b, axisa=0, axisb=0):
    """Compute the angle between arrays of vectors `a` and `b`."""
    import ein
    return np.arccos(ein.dot(a, b, axisa=axisa, axisb=axisb) /
                     (norm(a, axisa) * norm(b, axisb)))


def cat(*arrays):
    """Concatenate arrays along a new prepended axis."""
    return np.concatenate([a[np.newaxis] for a in arrays])


def derivative(t):
    """Create a callable that returns the derivative of its argument."""
    if t.ndim > 1:
        try:
            dt = np.gradient(t)[0]
        except ValueError:
            dt = np.gradient(np.squeeze(t))[..., np.newaxis]
        dt = np.rollaxis(dt, -1, 0)
    else:
        dt = np.gradient(t)

    def gradient(array):
        if dt.ndim == 1:
            return np.gradient(array, dt)
        else:
            return ecat(*[np.gradient(x, dx)
                          for x, dx in zip(np.rollaxis(array, -1, 0), dt)])

    return gradient


def ecat(*arrays):
    """Concatenate arrays along a new appended axis."""
    return np.concatenate([a[..., np.newaxis] for a in arrays], axis=-1)


def norm(array, axis=0):
    """Norm of `array` along `axis`."""
    try:
        return np.linalg.norm(array, axis=axis)
    except TypeError:
        return np.sqrt(sum(a ** 2 for a in np.rollaxis(array, axis)))


def norm0(array):
    """Compute the norm of an array along the first axis."""
    return norm(array, axis=0)


def projection(a, b, axisa=0, axisb=0):
    """Compute the component of `a` in the direction of `b`."""
    import ein
    return ein.dot(a, b, axisa=axisa, axisb=axisb) / norm(b, axisb)


def unit(array, axis=0):
    """Compute the unit vectors of `array` along `axis`."""
    return array / norm(array, axis)
