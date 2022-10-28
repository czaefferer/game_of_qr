import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:game_of_qr/settings.dart';
import 'package:qr/qr.dart';
import 'package:collection/collection.dart';
import 'package:native_device_orientation/native_device_orientation.dart';

class GameOfLife extends StatefulWidget {
  const GameOfLife({super.key, required String qrRawData}) : initialQrRawData = qrRawData;
  final String initialQrRawData;
  @override
  State<GameOfLife> createState() => _GameOfLifeState();
}

class _GameOfLifeState extends State<GameOfLife> {
  late List<List<bool>> data;
  late final int moduleCount;
  late StreamSubscription<NativeDeviceOrientation> orientationListener;
  bool lateVariablesInitialized = false;

  NativeDeviceOrientation currentDeviceOrientation = NativeDeviceOrientation.portraitUp;
  DateTime lastUpdateTime = DateTime.now();
  int gameSpeed = 500;
  @override
  void initState() {
    super.initState();
    scheduleMicrotask(asyncInit);
  }

  void asyncInit() async {
    gameSpeed = await appConfigurationService.getValue<int>(AppConfigurationOptions.gameSpeed, 500);
    await initQrData();
    await initOrientationListener();
    await updateDeviceOrientation();
    setState(() {
      lateVariablesInitialized = true;
    });
    SchedulerBinding.instance.scheduleFrameCallback(_tick);
  }

  Future<void> initOrientationListener() async {
    orientationListener = NativeDeviceOrientationCommunicator().onOrientationChanged(useSensor: true).listen((NativeDeviceOrientation newDeviceOrientation) {
      setState(() {
        currentDeviceOrientation = newDeviceOrientation;
      });
    });
  }

  Future<void> initQrData() async {
    var qrImage = QrImage(QrCode.fromData(data: widget.initialQrRawData, errorCorrectLevel: QrErrorCorrectLevel.Q));
    moduleCount = qrImage.moduleCount;
    data = List.generate(qrImage.moduleCount, (_) => List.generate(qrImage.moduleCount, (_) => false));
    for (int x = 0; x < qrImage.moduleCount; x++) {
      for (int y = 0; y < qrImage.moduleCount; y++) {
        data[x][y] = qrImage.isDark(x, y);
      }
    }
  }

  @override
  void dispose() {
    orientationListener.cancel();
    super.dispose();
  }

  Future<void> updateDeviceOrientation() async {
    currentDeviceOrientation = await NativeDeviceOrientationCommunicator().orientation(useSensor: true);
  }

  void _tick(_) async {
    if (lastUpdateTime.add(Duration(milliseconds: gameSpeed)).isAfter(DateTime.now())) {
      if (mounted) {
        SchedulerBinding.instance.scheduleFrameCallback(_tick);
      }
      return;
    }
    await updateDeviceOrientation();
    advanceGame();
    if (mounted) {
      SchedulerBinding.instance.scheduleFrameCallback(_tick);
      lastUpdateTime = DateTime.now();
    }
  }

  void advanceGame() {
    List<List<bool>> newData = List.generate(moduleCount, (_) => List.generate(moduleCount, (_) => false));
    for (int x = 0; x < moduleCount; x++) {
      for (int y = 0; y < moduleCount; y++) {
        int aliveNeightborsCount = getAliveNeightborsCount(x, y);
        bool newStatus = data[x][y];

        if (data[x][y] && aliveNeightborsCount < 2) {
          // 1. Any live cell with fewer than two live neighbours dies, as if by underpopulation.
          newStatus = false;
        } else if (data[x][y] && (aliveNeightborsCount == 2 || aliveNeightborsCount == 3)) {
          // 2. Any live cell with two or three live neighbours lives on to the next generation.
          newStatus = true;
        } else if (data[x][y] && aliveNeightborsCount > 3) {
          // 3. Any live cell with more than three live neighbours dies, as if by overpopulation.
          newStatus = false;
        } else if (!data[x][y] && aliveNeightborsCount == 3) {
          // 4. Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction.
          newStatus = true;
        }
        newData[x][y] = newStatus;
      }
    }
    if (mounted) {
      setState(() {
        data = newData;
      });
    }
  }

  int getAliveNeightborsCount(int x, int y) {
    return isCellAlive(x - 1, y - 1) +
        isCellAlive(x, y - 1) +
        isCellAlive(x + 1, y - 1) +
        isCellAlive(x - 1, y) +
        isCellAlive(x, y) +
        isCellAlive(x + 1, y) +
        isCellAlive(x - 1, y + 1) +
        isCellAlive(x, y + 1) +
        isCellAlive(x + 1, y + 1);
  }

  int isCellAlive(int x, int y) {
    if (x < 0 || x >= moduleCount || y < 0 || y >= moduleCount) {
      return 0;
    } else {
      return data[x][y] ? 1 : 0;
    }
  }

  double calculateRotationToBeApplied() {
    switch (currentDeviceOrientation) {
      case NativeDeviceOrientation.portraitDown:
        return 180;

      case NativeDeviceOrientation.landscapeLeft:
        return 90;

      case NativeDeviceOrientation.landscapeRight:
        return 270;

      case NativeDeviceOrientation.portraitUp:
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return !lateVariablesInitialized
        ? Container(color: Colors.transparent)
        : Transform.rotate(
            angle: calculateRotationToBeApplied() * (math.pi / 180),
            child: Container(
              color: Colors.white,
              child: Draggable<bool>(
                data: true,
                feedback: Container(),
                child: GridView.count(
                  primary: false,
                  scrollDirection: Axis.vertical,
                  crossAxisCount: moduleCount,
                  physics: const NeverScrollableScrollPhysics(),
                  children: data
                      .mapIndexed(
                        (x, row) => row.mapIndexed(
                          (y, cell) => DragTarget(
                            builder: (context, candidateItems, rejectedItems) {
                              return Container(color: (cell) ? Colors.black : Colors.white);
                            },
                            onMove: (item) {
                              if (!data[x][y]) {
                                setState(() {
                                  data[x][y] = true;
                                });
                              }
                            },
                          ),
                        ),
                      )
                      .expand((i) => i)
                      .toList(),
                ),
              ),
            ),
          );
  }
}
