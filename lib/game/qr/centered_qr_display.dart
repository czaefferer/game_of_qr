/* This file is part of Game-of-QR.
Game-of-QR is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
Game-of-QR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with Game-of-QR. If not, see <https://www.gnu.org/licenses/>. */

import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:game_of_qr/app/backend.dart';
import 'package:game_of_qr/game/qr/qr_information.dart';

class CenteredQrDisplay extends StatelessWidget {
  const CenteredQrDisplay({
    required this.viewport,
    required this.child,
    super.key,
  });
  final Size viewport;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    QRInformation? qrInformation = context.backend.latestFoundQr;
    if (qrInformation == null) {
      log("latestFoundQr is null");
      return const SizedBox.shrink();
    }

    double devicePixelRatio = MediaQueryData.fromView(View.of(context)).devicePixelRatio;
    double qrOverlayEdgeLength = _getCenteredCodeEdgeLength(viewport.width, qrInformation.pixelsAxisCount, devicePixelRatio);
    return Positioned(
      left: viewport.width / 2 - qrOverlayEdgeLength / 2,
      top: viewport.height / 2 - qrOverlayEdgeLength / 2,
      child: SizedBox(
        width: qrOverlayEdgeLength,
        height: qrOverlayEdgeLength,
        child: child,
      ),
    );
  }
}

class CenteredQrDisplayCloseIcon extends StatelessWidget {
  const CenteredQrDisplayCloseIcon({
    required this.viewport,
    required this.onClose,
    super.key,
  });
  final Size viewport;
  final void Function() onClose;

  @override
  Widget build(BuildContext context) {
    QRInformation? qrInformation = context.backend.latestFoundQr;
    if (qrInformation == null) {
      log("latestFoundQr is null");
      return const SizedBox.shrink();
    }
    double devicePixelRatio = MediaQueryData.fromView(View.of(context)).devicePixelRatio;
    double qrOverlayEdgeLength = _getCenteredCodeEdgeLength(viewport.width, qrInformation.pixelsAxisCount, devicePixelRatio);
    return Positioned(
      right: viewport.width / 2 - qrOverlayEdgeLength / 2 - 15,
      top: viewport.height / 2 - qrOverlayEdgeLength / 2 - 15,
      child: GestureDetector(
        onTap: onClose,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).primaryColor,
              width: 2,
            ),
          ),
          child: const Icon(Icons.close),
        ),
      ),
    );
  }
}

// the edge length should be about 3/4 of the screen width, but no more than 400px
// the length in device pixels should be a multiple of pixelsAxisCount, otherwise there might be occasional gaps between pixels of the QR code
double _getCenteredCodeEdgeLength(double screenWidth, int pixelsAxisCount, double devicePixelRatio) {
  // get approximation of length in logical pixels: 3/4 of screen width, but no more than 400px
  var approximationLogicalPixels = math.min(screenWidth * 0.75, 400);
  // convert to device pixels
  var approximationDevicePixels = approximationLogicalPixels * devicePixelRatio;
  // round down to next multiple of pixelsAxisCount
  var targetDevicePixels = (approximationDevicePixels / pixelsAxisCount).floor() * pixelsAxisCount;
  // convert back to logical pixels
  var targetLogicalPixels = targetDevicePixels / devicePixelRatio;

  return targetLogicalPixels;
}
