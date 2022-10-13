import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

InputImage cameraImageToInputImage(CameraImage cameraImage, int sensorOrientation) {
  final WriteBuffer allBytes = WriteBuffer();
  for (final Plane plane in cameraImage.planes) {
    allBytes.putUint8List(plane.bytes);
  }
  final bytes = allBytes.done().buffer.asUint8List();

  final Size imageSize = Size(cameraImage.width.toDouble(), cameraImage.height.toDouble());

  final InputImageRotation? imageRotation = InputImageRotationValue.fromRawValue(sensorOrientation);
  if (imageRotation == null) {
    throw Exception("could not get InputImageRotation");
  }

  final InputImageFormat? inputImageFormat = InputImageFormatValue.fromRawValue(cameraImage.format.raw as int);
  if (inputImageFormat == null) {
    throw Exception("could not get InputImageFormat");
  }

  final planeData = cameraImage.planes.map(
    (Plane plane) {
      return InputImagePlaneMetadata(
        bytesPerRow: plane.bytesPerRow,
        height: plane.height,
        width: plane.width,
      );
    },
  ).toList();

  final inputImageData = InputImageData(
    size: imageSize,
    imageRotation: imageRotation,
    inputImageFormat: inputImageFormat,
    planeData: planeData,
  );

  return InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);
}
