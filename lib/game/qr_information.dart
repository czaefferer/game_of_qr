/* This file is part of Game-of-QR.
Game-of-QR is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
Game-of-QR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with Game-of-QR. If not, see <https://www.gnu.org/licenses/>. */
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:game_of_qr/game/poly_to_poly.dart';
import 'package:qr/qr.dart';

class QRInformation {
  List<math.Point<int>> cornerPoints;
  DateTime lastUpdate = DateTime.now();
  final Size imageSize;
  final String rawData;
  final int rawDataHash;
  late final List<List<bool>> pixels;
  late final int pixelsAxisCount;

  QRInformation(this.cornerPoints, this.rawData, this.imageSize) : rawDataHash = rawData.hashCode {
    // recreate a QR code based on the content of the found QR code
    var qrImage = QrImage(QrCode.fromData(data: rawData, errorCorrectLevel: QrErrorCorrectLevel.Q));
    // and then read out the dimension and the pixels
    pixelsAxisCount = qrImage.moduleCount;
    pixels = List.generate(qrImage.moduleCount, (_) => List.generate(qrImage.moduleCount, (_) => false));
    for (int x = 0; x < qrImage.moduleCount; x++) {
      for (int y = 0; y < qrImage.moduleCount; y++) {
        pixels[x][y] = qrImage.isDark(x, y);
      }
    }
  }
  void updateCornerPoints(List<math.Point<int>> cornerPoints) {
    this.cornerPoints = cornerPoints;
    lastUpdate = DateTime.now();
  }

  // calulate the transformation matrix required to transform a square box with the given side length to the position of the QR code within the viewport
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

  // calculate the position of the top left corner of the QR code within the viewport
  Offset topLeft(Size viewport) {
    double xScale = viewport.width / imageSize.width;
    double yScale = viewport.height / imageSize.height;
    return Offset(
      cornerPoints[0].x.toDouble() * xScale,
      cornerPoints[0].y.toDouble() * yScale,
    );
  }
}

