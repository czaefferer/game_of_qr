/* This file is part of Game-of-QR.
Game-of-QR is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
Game-of-QR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with Game-of-QR. If not, see <https://www.gnu.org/licenses/>. */
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:qr/qr.dart';

@immutable
class QRInformation {
  final DateTime lastUpdate = DateTime.now();
  final List<math.Point<int>> cornerPoints;
  final Size imageSize;
  final String rawData;
  final int rawDataHash;
  final List<List<bool>> pixels;
  final int pixelsAxisCount;

  QRInformation({
    required this.cornerPoints,
    required this.imageSize,
    required this.rawData,
    required this.rawDataHash,
    required this.pixels,
    required this.pixelsAxisCount,
  });

  factory QRInformation.withCalculatedPixels(List<math.Point<int>> cornerPoints, String rawData, Size imageSize) {
    // recreate a QR code based on the content of the found QR code
    var qrImage = QrImage(QrCode.fromData(data: rawData, errorCorrectLevel: QrErrorCorrectLevel.Q));
    // and then read out the dimension and the pixels
    var pixelsAxisCount = qrImage.moduleCount;
    var pixels = List.generate(qrImage.moduleCount, (_) => List.generate(qrImage.moduleCount, (_) => false));
    for (int x = 0; x < qrImage.moduleCount; x++) {
      for (int y = 0; y < qrImage.moduleCount; y++) {
        pixels[x][y] = qrImage.isDark(x, y);
      }
    }
    return QRInformation(
      cornerPoints: cornerPoints,
      imageSize: imageSize,
      rawData: rawData,
      rawDataHash: rawData.hashCode,
      pixels: pixels,
      pixelsAxisCount: pixelsAxisCount,
    );
  }

  QRInformation withUpdatedCornerPoints(List<math.Point<int>> newCornerPoints) {
    return QRInformation(
      cornerPoints: newCornerPoints,
      imageSize: imageSize,
      rawData: rawData,
      rawDataHash: rawDataHash,
      pixels: pixels,
      pixelsAxisCount: pixelsAxisCount,
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
