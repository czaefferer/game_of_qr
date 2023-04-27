/* This file is part of Game-of-QR.
Game-of-QR is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
Game-of-QR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with Game-of-QR. If not, see <https://www.gnu.org/licenses/>. */

import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:qr/qr.dart';

import 'package:game_of_qr/game_of_life.dart';
import 'package:game_of_qr/header.dart';
import 'package:game_of_qr/settings_store.dart';
import 'package:game_of_qr/util.dart';

class MainGame extends StatefulWidget {
  const MainGame({super.key});

  @override
  State<MainGame> createState() => _MainGameState();
}

class _MainGameState extends State<MainGame> {
  /// async initialization future for build() to wait for
  late final Future<void> initialization;

  /// camera controller once it is initialized (if a camera is found)
  CameraController? cameraController;

  /// rotation of the camera sensor, will be initialized with the camera-controller, but is usually 90°
  int rotationRequiredBySensor = 90;

  /// scanner to find QR codes in the camera stream
  BarcodeScanner barcodeScanner = BarcodeScanner(formats: [BarcodeFormat.qrCode]);

  /// mutex to prevent multiple images from being analyzed at the same time
  bool analyzingImage = false;

  /// last time an image-analysis was completed
  DateTime lastAnalyzationCompleted = DateTime.now();

  /// information about the last found QR code
  QRInformation? foundQr;

  /// cached device-pixel-ratio without subscribing to MediaQuery
  double devicePixelRatio = MediaQueryData.fromWindow(window).devicePixelRatio;

  @override
  void initState() {
    super.initState();
    initialization = Future.microtask(() async {
      await initVideo();
    });
  }

  Future<void> initVideo() async {
    List<CameraDescription> cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw Exception('No camera found');
    }

    rotationRequiredBySensor = cameras[0].sensorOrientation;

    cameraController = CameraController(
      cameras[0],
      AppSettings.resultion,
      enableAudio: false,
    )..initialize().then((_) async {
        if (!mounted) {
          return;
        }
        await cameraController!.lockCaptureOrientation(DeviceOrientation.portraitUp);
        return cameraController!.startImageStream(analyzeImageFromStream);
      });
  }

  @override
  void dispose() {
    if (cameraController != null) {
      cameraController!.dispose();
    }
    barcodeScanner.close();
    super.dispose();
  }

  // async so calls from the videostream can execute immediately instead of piling up and filling the RAM. A check inside will drop most frames.
  void analyzeImageFromStream(CameraImage image) async {
    QRInformation? previousQr = foundQr;
    QRInformation? nextQr;
    // frame can be dropped if ...
    if (analyzingImage // ... already analyzing an image
            ||
            !mounted // ... widget is not mounted anymore
            ||
            lastAnalyzationCompleted.add(Duration(milliseconds: AppSettings.delay)).isAfter(DateTime.now()) // ... last anayzation was less than configured delay ago
            ||
            (!AppSettings.arEnabled && previousQr != null) // ... not in AR mode and a QR code is already displayed
        ) {
      return;
    }

    analyzingImage = true;

    try {
      // convert CameraImage to InputImage and find all codes in the image
      final List<Barcode> barcodes = await barcodeScanner.processImage(cameraImageToInputImage(image, rotationRequiredBySensor));

      // check if a QR code was found
      if (barcodes.isNotEmpty && barcodes[0].cornerPoints != null && barcodes[0].cornerPoints!.length == 4 && barcodes[0].rawValue != null) {
        // then check if found QR code is the same as the previously found one
        if (previousQr != null && previousQr.rawDataHash == barcodes[0].rawValue.hashCode) {
          // then only update the position
          nextQr = previousQr..updateCornerPoints(barcodes[0].cornerPoints!);
        } else {
          // otherwise create new QR code information
          nextQr = QRInformation(
            barcodes[0].cornerPoints!,
            barcodes[0].rawValue!,
            // Android streams in landscape mode, iOS in portrait. Since camera is locked to portrait mode, assume the smaller value is width and the larger value is height
            Size(
              math.min(image.width, image.height).toDouble(),
              math.max(image.width, image.height).toDouble(),
            ),
          );
        }
        // no QR code was found, check if one was previously found that is less than 1s old
      } else if (previousQr != null && previousQr.lastUpdate.add(const Duration(seconds: 1)).isAfter(DateTime.now())) {
        // then keep it alive
        nextQr = previousQr;
      }
    } catch (e, s) {
      log("error while analyzing image $e");
      log(s.toString());
    }

    if (mounted) {
      setState(() {
        foundQr = nextQr;
        analyzingImage = false;
        lastAnalyzationCompleted = DateTime.now();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Header("Game of QR", showCloseButton: true),
      body: FutureBuilder(
        future: initialization,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (snapshot.connectionState != ConnectionState.done || cameraController == null || !cameraController!.value.isInitialized) {
            return const SizedBox.shrink();
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              Size viewport = Size(constraints.maxWidth, constraints.maxHeight);
              QRInformation? foundQr = this.foundQr;
              double qrOverlayEdgeLength = //
                  foundQr == null //
                      ? 0
                      : AppSettings.arEnabled //
                          ? foundQr.pixelsAxisCount.toDouble() // minimum, will get stretched to the size of the QR code in the CameraPreview
                          : getCenteredCodeEdgeLength(constraints.maxWidth, foundQr.pixelsAxisCount);
              Matrix4? transformationMatrix = //
                  foundQr != null && AppSettings.arEnabled //
                      ? foundQr.calculateTransformationMatrix(qrOverlayEdgeLength, viewport)
                      : null;
              return Stack(
                children: <Widget>[
                  // camera preview
                  Positioned.fill(
                    child: CameraPreview(cameraController!),
                  ),
                  // AR mode overlay
                  if (foundQr != null && AppSettings.arEnabled && transformationMatrix != null)
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
