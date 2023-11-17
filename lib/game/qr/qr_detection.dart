/* This file is part of Game-of-QR.
Game-of-QR is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
Game-of-QR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with Game-of-QR. If not, see <https://www.gnu.org/licenses/>. */

import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game_of_qr/app/backend.dart';
import 'package:game_of_qr/game/qr/qr_information.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class QrDetection extends StatefulWidget {
  const QrDetection({super.key});

  @override
  State<QrDetection> createState() => _QrdetectionState();
}

class _QrdetectionState extends State<QrDetection> {
  Future<void>? initialization;

  /// camera used
  CameraDescription? camera;

  /// camera controller once it is initialized (if a camera is found)
  CameraController? cameraController;

  /// scanner to find QR codes in the camera stream
  BarcodeScanner barcodeScanner = BarcodeScanner(formats: [BarcodeFormat.qrCode]);

  /// mutex to prevent multiple images from being analyzed at the same time
  bool analyzingImage = false;

  /// last time an image-analysis was completed
  DateTime lastAnalyzationCompleted = DateTime.now();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    initialization ??= asyncInitState();
  }

  Future<void> asyncInitState() async {
    List<CameraDescription> cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw Exception('No camera found');
    }
    camera = cameras[0];
    cameraController = CameraController(
      camera!,
      settings.resolution,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : Platform.isIOS
              ? ImageFormatGroup.bgra8888
              : throw Exception("unsupported platform"),
    );
    await cameraController!.initialize();
    if (!mounted) {
      return;
    }
    await cameraController!.lockCaptureOrientation(DeviceOrientation.portraitUp);
    await cameraController!.startImageStream(analyzeImageFromStream);
  }

  @override
  void dispose() {
    if (cameraController != null) {
      cameraController!.dispose();
    }
    barcodeScanner.close();
    super.dispose();
  }

  // async so calls from the videostream can execute immediately in parallel instead of piling up and filling the RAM. A check inside will drop most frames.
  void analyzeImageFromStream(CameraImage image) async {
    // frame can be dropped if ...
    if (analyzingImage || // ... already analyzing an image
            !mounted || // ... widget is not mounted anymore
            lastAnalyzationCompleted.add(Duration(milliseconds: settings.delay)).isAfter(DateTime.now()) || // ... last analyzation completed less than configured delay ago
            backend.detectionPaused // ... detection is paused
        ) {
      return;
    }

    analyzingImage = true;

    try {
      final QRInformation? latestFoundQr = backend.latestFoundQr;

      // convert CameraImage to InputImage and find all codes in the image
      final InputImage inputImageFromCameraImage = _inputImageFromCameraImage(image) ?? (throw Exception("could not convert image"));
      final List<Barcode> barcodes = await barcodeScanner.processImage(inputImageFromCameraImage);

      // check if a QR code was found
      if (barcodes.isEmpty || barcodes[0].cornerPoints.length != 4 || barcodes[0].rawValue == null) {
        // no valid QR code was found, check if one was previously found that is less than 1s old
        if (latestFoundQr != null && latestFoundQr.lastUpdate.add(const Duration(seconds: 1)).isAfter(DateTime.now())) {
          // then keep it alive
          return;
        } else {
          // otherwise remove the old qr code
          updateQr(null);
          return;
        }
      }

      // a QR code was found, check if it is the same as the previously found one
      if (latestFoundQr != null && latestFoundQr.rawDataHash == barcodes[0].rawValue.hashCode) {
        // then only update the position
        updateQr(latestFoundQr.withUpdatedCornerPoints(barcodes[0].cornerPoints));
        return;
      }

      // the found QR code is a new one, create new QR code information
      updateQr(QRInformation.withCalculatedPixels(
        barcodes[0].cornerPoints,
        barcodes[0].rawValue!,
        // Android streams in landscape mode, iOS in portrait. Since camera is locked to portrait mode, assume the smaller value is width and the larger value is height
        Size(
          math.min(image.width, image.height).toDouble(),
          math.max(image.width, image.height).toDouble(),
        ),
      ));
    } catch (error, stacktrace) {
      log("error while analyzing image $error\n$stacktrace");
    } finally {
      analyzingImage = false;
      lastAnalyzationCompleted = DateTime.now();
    }
  }

  void updateQr(QRInformation? qrInformation) {
    if (!mounted) return;
    backend.latestFoundQr = qrInformation;
    if (!settings.arEnabled && qrInformation != null) {
      backend.detectionPaused = true;
    }
  }

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  // convert CameraImage from camera to InputImage required by ML kit, see https://github.com/bharat-biradar/Google-Ml-Kit-plugin/tree/master/packages/google_mlkit_commons#creating-an-inputimage
  InputImage? _inputImageFromCameraImage(CameraImage image) {
    // get image rotation
    // it is used in android to convert the InputImage from Dart to Java
    // `rotation` is not used in iOS to convert the InputImage from Dart to Obj-C
    // in both platforms `rotation` and `camera.lensDirection` can be used to compensate `x` and `y` coordinates on a canvas
    final sensorOrientation = camera!.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation = _orientations[cameraController!.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera!.lensDirection == CameraLensDirection.front) {
        // front-facing
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        // back-facing
        rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    // get image format
    final format = InputImageFormatValue.fromRawValue(image.format.raw as int);
    // validate format depending on platform
    // only supported formats:
    // * nv21 for Android
    // * bgra8888 for iOS
    if (format == null || (Platform.isAndroid && format != InputImageFormat.nv21) || (Platform.isIOS && format != InputImageFormat.bgra8888)) return null;

    // since format is constraint to nv21 or bgra8888, both only have one plane
    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    // compose InputImage using bytes
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation, // used only in Android
        format: format, // used only in iOS
        bytesPerRow: plane.bytesPerRow, // used only in iOS
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
        future: initialization,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            log("error while initializing camera ${snapshot.error}\n${snapshot.stackTrace}");
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (snapshot.connectionState != ConnectionState.done) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          return Positioned.fill(
            child: CameraPreview(cameraController!),
          );
        });
  }
}
