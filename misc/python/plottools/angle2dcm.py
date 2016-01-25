import numpy as np


def angle2dcm(r1, r2=None, r3=None, rotation_sequence='zyx'):
    """
    angle2dcm Create direction cosine matrix from rotation angles.

    N = angle2dcm( R1, R2, R3 ) calculates the direction cosine matrix, N,
    for a given set of rotation angles, R1, R2, R3.   R1 is an M array of
    first rotation angles.  R2 is an M array of second rotation angles.  R3
    is an M array of third rotation angles.  N returns an 3-by-3-by-M
    matrix containing M direction cosine matrices.  Rotation angles are
    input in radians.

    N = angle2dcm( R1, R2, R3, S ) calculates the direction cosine matrix,
    N, for a given set of rotation angles, R1, R2, R3, and a specified
    rotation sequence, S.

    The default rotation sequence is 'ZYX' where the order of rotation
    angles for the default rotation are R1 = Z Axis Rotation, R2 = Y Axis
    Rotation, and R3 = X Axis Rotation.

    All rotation sequences, S, are supported: 'ZYX', 'ZYZ', 'ZXY', 'ZXZ',
    'YXZ', 'YXY', 'YZX', 'YZY', 'XYZ', 'XYX', 'XZY', and 'XZX'.

    Examples:

    Determine the direction cosine matrix from rotation angles:
       yaw = 0.7854
       pitch = 0.1
       roll = 0
       dcm = angle2dcm( yaw, pitch, roll )

    Determine the direction cosine matrix from multiple rotation angles:
       yaw = [0.7854 0.5]
       pitch = [0.1 0.3]
       roll = [0 0.1]
       dcm = angle2dcm( pitch, roll, yaw, 'YXZ' )

    See also DCM2ANGLE, DCM2QUAT, QUAT2DCM, QUAT2ANGLE.

    Copyright 2000-2007 The MathWorks, Inc.
    $Revision: 1.1.6.5 $  $Date: 2007/08/15 17:16:07 $
    """
    if any(isinstance(x, np.ma.MaskedArray) for x in (r1, r2, r3)):
        numpy = np.ma
    else:
        numpy = np
    if r2 is not None:
        r1, r2, r3 = [numpy.asanyarray(r) for r in (r1, r2, r3)]
    else:
        r1, r2, r3 = numpy.asanyarray(r1)
    if r1.shape:
        angles = numpy.concatenate([r[np.newaxis] for r in (r1, r2, r3)])
    else:
        angles = numpy.array([r1, r2, r3])
    dcm = numpy.zeros((3,) + angles.shape)
    return _angle2dcm(rotation_sequence).rot(
        dcm, numpy.cos(angles), numpy.sin(angles))


class _angle2dcm(object):

    def __init__(self, rotation_sequence):
        try:
            self.rot = getattr(self, str(rotation_sequence).lower().
                               replace('1', 'x').
                               replace('2', 'y').
                               replace('3', 'z'))
        except AttributeError:
            raise ValueError('Invalid rotation sequence')

    def zyx(self, dcm, cang, sang):
        # [          cy*cz,          cy*sz,            -sy]
        # [ sy*sx*cz-sz*cx, sy*sx*sz+cz*cx,          cy*sx]
        # [ sy*cx*cz+sz*sx, sy*cx*sz-cz*sx,          cy*cx]

        dcm[0, 0] = cang[1] * cang[0]
        dcm[0, 1] = cang[1] * sang[0]
        dcm[0, 2] = -sang[1]
        dcm[1, 0] = sang[2] * sang[1] * cang[0] - cang[2] * sang[0]
        dcm[1, 1] = sang[2] * sang[1] * sang[0] + cang[2] * cang[0]
        dcm[1, 2] = sang[2] * cang[1]
        dcm[2, 0] = cang[2] * sang[1] * cang[0] + sang[2] * sang[0]
        dcm[2, 1] = cang[2] * sang[1] * sang[0] - sang[2] * cang[0]
        dcm[2, 2] = cang[2] * cang[1]

        return dcm

    def zyz(self, dcm, cang, sang):
        # [  cz2*cy*cz-sz2*sz,  cz2*cy*sz+sz2*cz,           -cz2*sy]
        # [ -sz2*cy*cz-cz2*sz, -sz2*cy*sz+cz2*cz,            sz2*sy]
        # [             sy*cz,             sy*sz,                cy]

        dcm[0, 0] = cang[0] * cang[2] * cang[1] - sang[0] * sang[2]
        dcm[0, 1] = sang[0] * cang[2] * cang[1] + cang[0] * sang[2]
        dcm[0, 2] = -sang[1] * cang[2]
        dcm[1, 0] = -cang[0] * cang[1] * sang[2] - sang[0] * cang[2]
        dcm[1, 1] = -sang[0] * cang[1] * sang[2] + cang[0] * cang[2]
        dcm[1, 2] = sang[1] * sang[2]
        dcm[2, 0] = cang[0] * sang[1]
        dcm[2, 1] = sang[0] * sang[1]
        dcm[2, 2] = cang[1]

        return dcm

    def zxy(self, dcm, cang, sang):
        # [ cy*cz-sy*sx*sz, cy*sz+sy*sx*cz,         -sy*cx]
        # [         -sz*cx,          cz*cx,             sx]
        # [ sy*cz+cy*sx*sz, sy*sz-cy*sx*cz,          cy*cx]

        dcm[0, 0] = cang[2] * cang[0] - sang[1] * sang[2] * sang[0]
        dcm[0, 1] = cang[2] * sang[0] + sang[1] * sang[2] * cang[0]
        dcm[0, 2] = -sang[2] * cang[1]
        dcm[1, 0] = -cang[1] * sang[0]
        dcm[1, 1] = cang[1] * cang[0]
        dcm[1, 2] = sang[1]
        dcm[2, 0] = sang[2] * cang[0] + sang[1] * cang[2] * sang[0]
        dcm[2, 1] = sang[2] * sang[0] - sang[1] * cang[2] * cang[0]
        dcm[2, 2] = cang[1] * cang[2]

        return dcm

    def zxz(self, dcm, cang, sang):
        # [  cz2*cz-sz2*cx*sz,  cz2*sz+sz2*cx*cz,            sz2*sx]
        # [ -sz2*cz-cz2*cx*sz, -sz2*sz+cz2*cx*cz,            cz2*sx]
        # [             sz*sx,            -cz*sx,                cx]

        dcm[0, 0] = -sang[0] * cang[1] * sang[2] + cang[0] * cang[2]
        dcm[0, 1] = cang[0] * cang[1] * sang[2] + sang[0] * cang[2]
        dcm[0, 2] = sang[1] * sang[2]
        dcm[1, 0] = -sang[0] * cang[2] * cang[1] - cang[0] * sang[2]
        dcm[1, 1] = cang[0] * cang[2] * cang[1] - sang[0] * sang[2]
        dcm[1, 2] = sang[1] * cang[2]
        dcm[2, 0] = sang[0] * sang[1]
        dcm[2, 1] = -cang[0] * sang[1]
        dcm[2, 2] = cang[1]

        return dcm

    def yxz(self, dcm, cang, sang):
        # [  cy*cz+sy*sx*sz,           sz*cx, -sy*cz+cy*sx*sz]
        # [ -cy*sz+sy*sx*cz,           cz*cx,  sy*sz+cy*sx*cz]
        # [           sy*cx,             -sx,           cy*cx]

        dcm[0, 0] = cang[0] * cang[2] + sang[1] * sang[0] * sang[2]
        dcm[0, 1] = cang[1] * sang[2]
        dcm[0, 2] = -sang[0] * cang[2] + sang[1] * cang[0] * sang[2]
        dcm[1, 0] = -cang[0] * sang[2] + sang[1] * sang[0] * cang[2]
        dcm[1, 1] = cang[1] * cang[2]
        dcm[1, 2] = sang[0] * sang[2] + sang[1] * cang[0] * cang[2]
        dcm[2, 0] = sang[0] * cang[1]
        dcm[2, 1] = -sang[1]
        dcm[2, 2] = cang[1] * cang[0]

        return dcm

    def yxy(self, dcm, cang, sang):
        # [ cy2*cy-sy2*cx*sy,            sy2*sx, -cy2*sy-sy2*cx*cy]
        # [            sy*sx,                cx,             cy*sx]
        # [ sy2*cy+cy2*cx*sy,           -cy2*sx, -sy2*sy+cy2*cx*cy]

        dcm[0, 0] = -sang[0] * cang[1] * sang[2] + cang[0] * cang[2]
        dcm[0, 1] = sang[1] * sang[2]
        dcm[0, 2] = -cang[0] * cang[1] * sang[2] - sang[0] * cang[2]
        dcm[1, 0] = sang[0] * sang[1]
        dcm[1, 1] = cang[1]
        dcm[1, 2] = cang[0] * sang[1]
        dcm[2, 0] = sang[0] * cang[2] * cang[1] + cang[0] * sang[2]
        dcm[2, 1] = -sang[1] * cang[2]
        dcm[2, 2] = cang[0] * cang[2] * cang[1] - sang[0] * sang[2]

        return dcm

    def yzx(self, dcm, cang, sang):
        # [           cy*cz,              sz,          -sy*cz]
        # [ -sz*cx*cy+sy*sx,           cz*cx,  sy*cx*sz+cy*sx]
        # [  cy*sx*sz+sy*cx,          -cz*sx, -sy*sx*sz+cy*cx]

        dcm[0, 0] = cang[0] * cang[1]
        dcm[0, 1] = sang[1]
        dcm[0, 2] = -sang[0] * cang[1]
        dcm[1, 0] = -cang[2] * cang[0] * sang[1] + sang[2] * sang[0]
        dcm[1, 1] = cang[1] * cang[2]
        dcm[1, 2] = cang[2] * sang[0] * sang[1] + sang[2] * cang[0]
        dcm[2, 0] = sang[2] * cang[0] * sang[1] + cang[2] * sang[0]
        dcm[2, 1] = -sang[2] * cang[1]
        dcm[2, 2] = -sang[2] * sang[0] * sang[1] + cang[2] * cang[0]

        return dcm

    def yzy(self, dcm, cang, sang):
        # [  cy2*cz*cy-sy2*sy,            cy2*sz, -cy2*cz*sy-sy2*cy]
        # [            -cy*sz,                cz,             sy*sz]
        # [  sy2*cz*cy+cy2*sy,            sy2*sz, -sy2*cz*sy+cy2*cy]

        dcm[0, 0] = cang[0] * cang[2] * cang[1] - sang[0] * sang[2]
        dcm[0, 1] = sang[1] * cang[2]
        dcm[0, 2] = -sang[0] * cang[2] * cang[1] - cang[0] * sang[2]
        dcm[1, 0] = -cang[0] * sang[1]
        dcm[1, 1] = cang[1]
        dcm[1, 2] = sang[0] * sang[1]
        dcm[2, 0] = cang[0] * cang[1] * sang[2] + sang[0] * cang[2]
        dcm[2, 1] = sang[1] * sang[2]
        dcm[2, 2] = -sang[0] * cang[1] * sang[2] + cang[0] * cang[2]

        return dcm

    def xyz(self, dcm, cang, sang):
        # [  cy*cz, sz*cx+sy*sx*cz, sz*sx-sy*cx*cz]
        # [ -cy*sz, cz*cx-sy*sx*sz, cz*sx+sy*cx*sz]
        # [     sy,         -cy*sx,          cy*cx]

        dcm[0, 0] = cang[1] * cang[2]
        dcm[0, 1] = sang[0] * sang[1] * cang[2] + cang[0] * sang[2]
        dcm[0, 2] = -cang[0] * sang[1] * cang[2] + sang[0] * sang[2]
        dcm[1, 0] = -cang[1] * sang[2]
        dcm[1, 1] = -sang[0] * sang[1] * sang[2] + cang[0] * cang[2]
        dcm[1, 2] = cang[0] * sang[1] * sang[2] + sang[0] * cang[2]
        dcm[2, 0] = sang[1]
        dcm[2, 1] = -sang[0] * cang[1]
        dcm[2, 2] = cang[0] * cang[1]

        return dcm

    def xyx(self, dcm, cang, sang):
        # [     cy,             sy*sx,            -sy*cx]
        # [ sx2*sy,  cx2*cx-sx2*cy*sx,  cx2*sx+sx2*cy*cx]
        # [ cx2*sy, -sx2*cx-cx2*cy*sx, -sx2*sx+cx2*cy*cx]

        dcm[0, 0] = cang[1]
        dcm[0, 1] = sang[0] * sang[1]
        dcm[0, 2] = -cang[0] * sang[1]
        dcm[1, 0] = sang[1] * sang[2]
        dcm[1, 1] = -sang[0] * cang[1] * sang[2] + cang[0] * cang[2]
        dcm[1, 2] = cang[0] * cang[1] * sang[2] + sang[0] * cang[2]
        dcm[2, 0] = sang[1] * cang[2]
        dcm[2, 1] = -sang[0] * cang[2] * cang[1] - cang[0] * sang[2]
        dcm[2, 2] = cang[0] * cang[2] * cang[1] - sang[0] * sang[2]

        return dcm

    def xzy(self, dcm, cang, sang):
        # [ cy*cz, sz*cx*cy+sy*sx, cy*sx*sz-sy*cx]
        # [   -sz,          cz*cx,          cz*sx]
        # [ sy*cz, sy*cx*sz-cy*sx, sy*sx*sz+cy*cx]

        dcm[0, 0] = cang[2] * cang[1]
        dcm[0, 1] = cang[0] * cang[2] * sang[1] + sang[0] * sang[2]
        dcm[0, 2] = sang[0] * cang[2] * sang[1] - cang[0] * sang[2]
        dcm[1, 0] = -sang[1]
        dcm[1, 1] = cang[0] * cang[1]
        dcm[1, 2] = sang[0] * cang[1]
        dcm[2, 0] = sang[2] * cang[1]
        dcm[2, 1] = cang[0] * sang[1] * sang[2] - sang[0] * cang[2]
        dcm[2, 2] = sang[0] * sang[1] * sang[2] + cang[0] * cang[2]

        return dcm

    def xzx(self, dcm, cang, sang):
        # [      cz,             sz*cx,             sz*sx]
        # [ -cx2*sz,  cx2*cz*cx-sx2*sx,  cx2*cz*sx+sx2*cx]
        # [  sx2*sz, -sx2*cz*cx-cx2*sx, -sx2*cz*sx+cx2*cx]

        dcm[0, 0] = cang[1]
        dcm[0, 1] = cang[0] * sang[1]
        dcm[0, 2] = sang[0] * sang[1]
        dcm[1, 0] = -sang[1] * cang[2]
        dcm[1, 1] = cang[0] * cang[2] * cang[1] - sang[0] * sang[2]
        dcm[1, 2] = sang[0] * cang[2] * cang[1] + cang[0] * sang[2]
        dcm[2, 0] = sang[1] * sang[2]
        dcm[2, 1] = -cang[0] * cang[1] * sang[2] - sang[0] * cang[2]
        dcm[2, 2] = -sang[0] * cang[1] * sang[2] + cang[0] * cang[2]

        return dcm
