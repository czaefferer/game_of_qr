/* This file is part of Game-of-QR.
Game-of-QR is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
Game-of-QR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with Game-of-QR. If not, see <https://www.gnu.org/licenses/>. */

import 'package:flutter/material.dart';
import 'package:game_of_qr/app/backend.dart';
import 'package:game_of_qr/game/game_of_life.dart';
import 'package:game_of_qr/game/qr/ar_qr_display.dart';
import 'package:game_of_qr/game/qr/centered_qr_display.dart';
import 'package:game_of_qr/game/qr/qr_detection.dart';
import 'package:game_of_qr/game/qr/qr_information.dart';
import 'package:game_of_qr/menues/header.dart';

class MainGame extends StatelessWidget {
  const MainGame({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Header("Game of QR", showCloseButton: true),
      body: LayoutBuilder(
        builder: (context, constraints) {
          Size viewport = Size(constraints.maxWidth, constraints.maxHeight);
          return ValueListenableBuilder<QRInformation?>(
            valueListenable: context.backend.latestFoundQrNotifier,
            builder: (context, latestFoundQr, _) {
              return Stack(
                children: <Widget>[
                  QrDetection(),
                  if (latestFoundQr != null && context.settings.arEnabled)
                    ArQrDisplay(
                      viewport: viewport,
                      child: GameOfLife(
                        pixels: latestFoundQr.pixels,
                        pixelsAxisCount: latestFoundQr.pixelsAxisCount,
                        key: ValueKey(latestFoundQr.rawDataHash),
                      ),
                    ),
                  if (latestFoundQr != null && !context.settings.arEnabled) ...[
                    CenteredQrDisplay(
                      viewport: viewport,
                      child: GameOfLife(
                        pixels: latestFoundQr.pixels,
                        pixelsAxisCount: latestFoundQr.pixelsAxisCount,
                        key: ValueKey(latestFoundQr.rawDataHash),
                      ),
                    ),
                    CenteredQrDisplayCloseIcon(
                      viewport: viewport,
                      onClose: () {
                        context.backend.latestFoundQr = null;
                        context.backend.detectionPaused = false;
                      },
                    )
                  ]
                ],
              );
            },
          );
        },
      ),
    );
  }
}
