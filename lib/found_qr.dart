import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:game_of_qr/poly_to_poly.dart';

class FoundQr {
  final List<math.Point<int>> cornerPoints;
  final Size imageSize;
  final String rawData;
  final DateTime found = DateTime.now();

  FoundQr(this.cornerPoints, this.rawData, this.imageSize);

  Matrix4? calculateTransformationMatrix(double sideLength, Size viewport) {
    double xScale = viewport.width / imageSize.width;
    double yScale = viewport.height / imageSize.height;
    return setPolyToPoly(
      [
        const Offset(0, 0),
        Offset(sideLength, 0),
        Offset(sideLength, sideLength),
        Offset(0, sideLength),
      ],
      cornerPoints
          .map(
            (e) => Offset(
              (e.x.toDouble() - cornerPoints[0].x) * xScale,
              (e.y.toDouble() - cornerPoints[0].y) * yScale,
            ),
          )
          .toList(),
    );
  }

  Offset topLeft(Size viewport) {
    double xScale = viewport.width / imageSize.width;
    double yScale = viewport.height / imageSize.height;
    return Offset(
      cornerPoints[0].x.toDouble() * xScale,
      cornerPoints[0].y.toDouble() * yScale,
    );
  }
}
