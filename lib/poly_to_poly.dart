
import 'package:flutter/rendering.dart';

Matrix4? setPolyToPoly(List<Offset> src, List<Offset> dst) {
  assert(src.length == 4 && dst.length == 4);

  Matrix4? srcMatrix = _poly4Proc(src);
  if (srcMatrix == null) {
    return null;
  }

  Matrix4? dstMatrix = _poly4Proc(dst);
  if (dstMatrix == null) {
    return null;
  }

  return dstMatrix * Matrix4.inverted(srcMatrix) as Matrix4;
}

Matrix4? _poly4Proc(List<Offset> src) {
  double a1, a2;
  double x0, y0, x1, y1, x2, y2;

  x0 = src[2].dx - src[0].dx;
  y0 = src[2].dy - src[0].dy;
  x1 = src[2].dx - src[1].dx;
  y1 = src[2].dy - src[1].dy;
  x2 = src[2].dx - src[3].dx;
  y2 = src[2].dy - src[3].dy;

  /* check if abs(x2) > abs(y2) */
  if ( x2 > 0 ? y2 > 0 ? x2 > y2 : x2 > -y2 : y2 > 0 ? -x2 > y2 : x2 < y2) {
    double denom = _ieeeFloatDivide(x1 * y2, x2) - y1;
    if (_checkForZero(denom)) {
      return null;
    }
    a1 = (((x0 - x1) * y2 / x2) - y0 + y1) / denom;
  } else {
    double denom = x1 - _ieeeFloatDivide(y1 * x2, y2);
    if (_checkForZero(denom)) {
      return null;
    }
    a1 = (x0 - x1 - _ieeeFloatDivide((y0 - y1) * x2, y2)) / denom;
  }

  /* check if abs(x1) > abs(y1) */
  if ( x1 > 0 ? y1 > 0 ? x1 > y1 : x1 > -y1 : y1 > 0 ? -x1 > y1 : x1 < y1) {
    double denom = y2 - _ieeeFloatDivide(x2 * y1, x1);
    if (_checkForZero(denom)) {
      return null;
    }
    a2 = (y0 - y2 - _ieeeFloatDivide((x0 - x2) * y1, x1)) / denom;
  } else {
    double denom = _ieeeFloatDivide(y2 * x1, y1) - x2;
    if (_checkForZero(denom)) {
      return null;
    }
    a2 = (_ieeeFloatDivide((y0 - y2) * x1, y1) - x0 + x2) / denom;
  }

  return Matrix4(
    a2 * src[3].dx + src[3].dx - src[0].dx, a2 * src[3].dy + src[3].dy - src[0].dy, 0, a2,
    a1 * src[1].dx + src[1].dx - src[0].dx, a1 * src[1].dy + src[1].dy - src[0].dy, 0, a1,
    0, 0, 1, 0,
    src[0].dx, src[0].dy, 0, 1,
  );
}

double _ieeeFloatDivide(double d0, double d1) => d0 / d1;

bool _checkForZero(double d) => d * d == 0;