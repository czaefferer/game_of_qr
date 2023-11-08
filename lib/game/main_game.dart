/* This file is part of Game-of-QR.
Game-of-QR is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
Game-of-QR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with Game-of-QR. If not, see <https://www.gnu.org/licenses/>. */

import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:game_of_qr/app/game_of_qr_backend.dart';
import 'package:game_of_qr/game/game_of_life.dart';
import 'package:game_of_qr/game/qr_detection.dart';
import 'package:game_of_qr/game/qr_information.dart';
import 'package:game_of_qr/menues/header.dart';

class MainGame extends StatefulWidget {
  const MainGame({super.key});

  @override
  State<MainGame> createState() => _MainGameState();
}

class _MainGameState extends State<MainGame> {
  /// async initialization future for build() to wait for
  late final Future<void> initialization;

  /// information about the last found QR code
  QRInformation? foundQr;

  /// cached device-pixel-ratio (initialized in didChangeDependencies)
  double devicePixelRatio = 1;

  /// class to detect QR codes in the camera stream
  QrDetection qrDetection = QrDetection();

  @override
  void initState() {
    super.initState();
    initialization = qrDetection.initialize(updateQr, settings);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // get the pixel ration without subscribing to MediaQuery, as that should never change
    devicePixelRatio = MediaQueryData.fromView(View.of(context)).devicePixelRatio;
  }

  @override
  void dispose() {
    qrDetection.dispose();
    super.dispose();
  }

  void updateQr(QRInformation? nextQr) {
    if (!settings.arEnabled && nextQr != null) {
      qrDetection.paused = true;
    }
    if (!mounted) return;
    setState(() {
      foundQr = nextQr;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Header("Game of QR", showCloseButton: true),
      body: FutureBuilder(
        future: initialization,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            log("error while initializing camera ${snapshot.error}\n${snapshot.stackTrace}");
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox.shrink();
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              Size viewport = Size(constraints.maxWidth, constraints.maxHeight);
              QRInformation? foundQr = this.foundQr;
              double qrOverlayEdgeLength = //
                  foundQr == null //
                      ? 0
                      : settings.arEnabled //
                          ? foundQr.pixelsAxisCount.toDouble() // minimum, will get stretched to the size of the QR code in the CameraPreview
                          : getCenteredCodeEdgeLength(constraints.maxWidth, foundQr.pixelsAxisCount);
              Matrix4? transformationMatrix = //
                  foundQr != null && settings.arEnabled //
                      ? foundQr.calculateTransformationMatrix(qrOverlayEdgeLength, viewport)
                      : null;
              return Stack(
                children: <Widget>[
                  // camera preview
                  Positioned.fill(
                    child: CameraPreview(qrDetection.cameraController!),
                  ),
                  // AR mode overlay
                  if (foundQr != null && settings.arEnabled && transformationMatrix != null)
                    Positioned(
                      left: foundQr.topLeft(viewport).dx,
                      top: foundQr.topLeft(viewport).dy,
                      child: Transform(
                        transform: transformationMatrix,
                        alignment: FractionalOffset.topLeft,
                        child: SizedBox(
                          width: qrOverlayEdgeLength,
                          height: qrOverlayEdgeLength,
                          child: GameOfLife(
                            pixels: foundQr.pixels,
                            pixelsAxisCount: foundQr.pixelsAxisCount,
                            key: ValueKey(foundQr.rawDataHash),
                          ),
                        ),
                      ),
                    )
                  // regular mode overlay
                  else if (foundQr != null) ...[
                    // QR code
                    Positioned(
                      left: constraints.maxWidth / 2 - qrOverlayEdgeLength / 2,
                      top: constraints.maxHeight / 2 - qrOverlayEdgeLength / 2,
                      child: SizedBox(
                        width: qrOverlayEdgeLength,
                        height: qrOverlayEdgeLength,
                        child: GameOfLife(
                          pixels: foundQr.pixels,
                          pixelsAxisCount: foundQr.pixelsAxisCount,
                          key: ValueKey(foundQr.rawDataHash),
                        ),
                      ),
                    ),
                    // close button
                    Positioned(
                      right: constraints.maxWidth / 2 - qrOverlayEdgeLength / 2 - 15,
                      top: constraints.maxHeight / 2 - qrOverlayEdgeLength / 2 - 15,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            this.foundQr = null;
                          });
                          qrDetection.paused = false;
                        },
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
                    ),
                    // ---
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }

  // the edge length should be about 3/4 of the screen width, but no more than 400px
  // the length in device pixels should be a multiple of pixelsAxisCount, otherwise there might be occasional gaps between pixels of the QR code
  double getCenteredCodeEdgeLength(double screenWidth, int pixelsAxisCount) {
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
}
