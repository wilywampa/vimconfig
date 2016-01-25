import numpy as np
from numpy import concatenate, newaxis, rollaxis, squeeze

__all__ = ['cat', 'derivative', 'ecat', 'norm0', 'unit']


def cat(*arrays):
    """Concatenate arrays along a new prepended axis."""
    return concatenate([a[newaxis] for a in arrays])


def derivative(t):
    """Create a callable that returns the derivative of its argument."""
    if t.ndim > 1:
        try:
            dt = np.gradient(t)[0]
        except ValueError:
            dt = np.gradient(squeeze(t))[..., newaxis]
        dt = rollaxis(dt, -1, 0)
    else:
        dt = np.gradient(t)

    def gradient(array):
        if dt.ndim == 1:
            return np.gradient(array, dt)
        else:
            return ecat(*[np.gradient(x, dx)
                          for x, dx in zip(rollaxis(array, -1, 0), dt)])

    return gradient


def ecat(*arrays):
    """Concatenate arrays along a new appended axis."""
    return concatenate([a[..., newaxis] for a in arrays], axis=-1)


def norm(array, axis=0):
    """Norm of `array` along `axis`."""
    try:
        return np.linalg.norm(array, axis=axis)
    except TypeError:
        return np.sqrt(sum(a ** 2 for a in np.rollaxis(array, axis)))


def norm0(array):
    """Compute the norm of an array along the first axis."""
    return norm(array, axis=0)


def unit(array):
    """Compute the unit vectors along the first axis of an array."""
    return array / norm0(array)
