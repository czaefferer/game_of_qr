import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import 'package:game_of_qr/settings_store.dart';

class GameOfLife extends StatefulWidget {
  const GameOfLife({
    required List<List<bool>> pixels,
    required this.pixelsAxisCount,
    super.key,
  }) : initialPixels = pixels;

  final List<List<bool>> initialPixels;
  final int pixelsAxisCount;

  @override
  State<GameOfLife> createState() => _GameOfLifeState();
}

class _GameOfLifeState extends State<GameOfLife> {
  late List<List<bool>> pixels;
  late Timer nextAdvanceGameTimer;

  @override
  void initState() {
    super.initState();
    pixels = widget.initialPixels;
    nextAdvanceGameTimer = Timer(Duration(milliseconds: AppSettings.gameSpeed), advanceGame);
  }

  @override
  void dispose() {
    nextAdvanceGameTimer.cancel();
    super.dispose();
  }

  void advanceGame() async {
    List<List<bool>> newPixels = List.generate(widget.pixelsAxisCount, (_) => List.generate(widget.pixelsAxisCount, (_) => false));
    for (int x = 0; x < widget.pixelsAxisCount; x++) {
      for (int y = 0; y < widget.pixelsAxisCount; y++) {
        int livingNeightborsCount = getLivingNeightborsCount(x, y);
        if (pixels[x][y] && livingNeightborsCount < 2) {
          // 1. Any live cell with fewer than two live neighbours dies, as if by underpopulation.
          newPixels[x][y] = false;
        } else if (pixels[x][y] && (livingNeightborsCount == 2 || livingNeightborsCount == 3)) {
          // 2. Any live cell with two or three live neighbours lives on to the next generation.
          newPixels[x][y] = true;
        } else if (pixels[x][y] && livingNeightborsCount > 3) {
          // 3. Any live cell with more than three live neighbours dies, as if by overpopulation.
          newPixels[x][y] = false;
        } else if (!pixels[x][y] && livingNeightborsCount == 3) {
          // 4. Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction.
          newPixels[x][y] = true;
        }
      }
    }

    if (mounted) {
      setState(() {
        pixels = newPixels;
      });
    }

    // schedule next execution
    nextAdvanceGameTimer = Timer(Duration(milliseconds: AppSettings.gameSpeed), advanceGame);
  }

  int getLivingNeightborsCount(int x, int y) {
    return [
      isCellAlive(x - 1, y - 1),
      isCellAlive(x, y - 1),
      isCellAlive(x + 1, y - 1),
      isCellAlive(x - 1, y),
      isCellAlive(x + 1, y),
      isCellAlive(x - 1, y + 1),
      isCellAlive(x, y + 1),
      isCellAlive(x + 1, y + 1)
    ].where((e) => e).length;
  }

  bool isCellAlive(int x, int y) {
    if (x < 0 || x >= widget.pixelsAxisCount || y < 0 || y >= widget.pixelsAxisCount) {
      return false;
    } else {
      return pixels[x][y];
    }
  }

  @override
  Widget build(BuildContext context) {
    // initializing this can be slow, because a lot of widgets might need to be created (depending on the axis-count). Using a custom painter might be better
    return ColoredBox(
      color: Colors.white,
      child: Draggable<bool>(
        data: true,
        feedback: const SizedBox.shrink(),
        child: GridView.count(
          primary: false,
          scrollDirection: Axis.vertical,
          crossAxisCount: widget.pixelsAxisCount,
          children: pixels
              .mapIndexed(
                (x, row) => row.mapIndexed(
                  (y, cell) => DragTarget(
                    builder: (_, __, ___) {
                      return cell //
                          ? const ColoredBox(color: Colors.black)
                          : const SizedBox.shrink();
                    },
                    onMove: (_) {
                      if (!pixels[x][y]) {
                        setState(() {
                          pixels[x][y] = true;
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
    );
  }
}
