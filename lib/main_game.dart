import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game_of_qr/camera_image_to_input_image.dart';
import 'package:game_of_qr/game_of_life.dart';
import 'package:game_of_qr/found_qr.dart';
import 'package:game_of_qr/settings.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class TestScan extends StatefulWidget {
  const TestScan({super.key});

  @override
  State<TestScan> createState() => _TestScanState();
}

class _TestScanState extends State<TestScan> {
  late final BarcodeScanner barcodeScanner;
  late final CameraController controller;
  late final bool showCentered;
  bool lateMembersInitialized = false;

  bool analyzingImage = false;
  DateTime lastAnalyzationCompleted = DateTime.now();
  int rotationRequiredBySensor = 90;

  FoundQr? foundQr;

  @override
  void initState() {
    super.initState();
    barcodeScanner = BarcodeScanner(formats: [BarcodeFormat.qrCode]);
    scheduleMicrotask(asyncInit);
  }

  void asyncInit() async {
    await Future.wait([
      loadShowCentered(),
      initVideo(),
    ]);
    setState(() {
      lateMembersInitialized = true;
    });
  }

  Future<void> loadShowCentered() async {
    showCentered = await appConfigurationService.getValue<bool>(AppConfigurationOptions.showCentered, false);
  }

  Future<void> initVideo() async {
    List<CameraDescription> cameras = await availableCameras();
    rotationRequiredBySensor = cameras[0].sensorOrientation;

    controller = CameraController(
      cameras[0],
      intToResolutionPreset(await appConfigurationService.getValue<int>(AppConfigurationOptions.resolution, resolutionPresetToInt(Platform.isIOS ? ResolutionPreset.low : ResolutionPreset.high))),
      enableAudio: false,
    )..initialize().then((_) {
        if (!mounted) {
          return;
        }
        controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
        controller.startImageStream(analyzeImage);
        setState(() {});
      });
  }

  @override
  void dispose() {
    controller.dispose();
    barcodeScanner.close();
    super.dispose();
  }

  // async so calls from the videostream can execute immediately instead of piling up and filling the RAM. A check inside will only process a fraction of the calls.
  void analyzeImage(CameraImage image) async {
    if (analyzingImage || !mounted || lastAnalyzationCompleted.add(Duration(milliseconds: await appConfigurationService.getValue<int>(AppConfigurationOptions.delay, 100))).isAfter(DateTime.now())) {
      return;
    }

    analyzingImage = true;

    try {
      final List<Barcode> barcodes = await barcodeScanner.processImage(cameraImageToInputImage(image, rotationRequiredBySensor));
      if (barcodes.isNotEmpty && barcodes[0].cornerPoints != null && barcodes[0].cornerPoints!.length == 4 && barcodes[0].rawValue != null) {
        if (Platform.isIOS) {
          foundQr = FoundQr(barcodes[0].cornerPoints!, barcodes[0].rawValue!, Size(image.width.toDouble(), image.height.toDouble()));
        } else {
          foundQr = FoundQr(barcodes[0].cornerPoints!, barcodes[0].rawValue!, Size(image.height.toDouble(), image.width.toDouble()));
        }
      } else if (foundQr != null) {
        if (foundQr!.found.add(const Duration(seconds: 1)).isBefore(DateTime.now())) {
          // for one second no qr code has been found, remove previously found one
          foundQr = null;
        }
      }
    } catch (e, s) {
      log("error while analyzing image $e");
      log(s.toString());
    }
    analyzingImage = false;
    lastAnalyzationCompleted = DateTime.now();

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: SizedBox.square(
          dimension: 44,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.close),
          ),
        ),
        title: const Center(
          child: Text("Game of QR"),
        ),
        actions: const [
          SizedBox.square(
            dimension: 44,
          )
        ],
      ),
      body: !lateMembersInitialized || !controller.value.isInitialized
          ? Container()
          : LayoutBuilder(
              builder: (context, constraints) {
                Size viewport = Size(constraints.maxWidth, constraints.maxHeight);
                FoundQr? foundQr = this.foundQr;
                Matrix4? transformationMatrix = (foundQr != null && !showCentered) ? foundQr.calculateTransformationMatrix(100, viewport) : null;
                return Stack(
                  alignment: FractionalOffset.center,
                  children: <Widget>[
                    Positioned.fill(
                      child: AspectRatio(aspectRatio: controller.value.aspectRatio, child: CameraPreview(controller)),
                    ),
                    if (foundQr != null && !showCentered && transformationMatrix != null)
                      Positioned(
                        left: foundQr.topLeft(viewport).dx,
                        top: foundQr.topLeft(viewport).dy,
                        child: Transform(
                          transform: transformationMatrix,
                          alignment: FractionalOffset.topLeft,
                          child: SizedBox(
                            width: 100,
                            height: 100,
                            child: GameOfLife(
                              qrRawData: foundQr.rawData,
                              key: ValueKey(foundQr.rawData.hashCode),
                            ),
                          ),
                        ),
                      ),
                    if (foundQr != null && (showCentered || transformationMatrix == null))
                      Positioned(
                        left: MediaQuery.of(context).size.width / 4,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width / 2,
                          height: MediaQuery.of(context).size.width / 2,
                          child: GameOfLife(
                            qrRawData: foundQr.rawData,
                            key: ValueKey(foundQr.rawData.hashCode),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }
}
