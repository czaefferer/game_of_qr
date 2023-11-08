/* This file is part of Game-of-QR.
Game-of-QR is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
Game-of-QR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with Game-of-QR. If not, see <https://www.gnu.org/licenses/>. */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:game_of_qr/menues/header.dart';
import 'package:game_of_qr/game/main_game.dart';
import 'package:game_of_qr/menues/menus_layout.dart';
import 'package:game_of_qr/settings/settings_screen.dart';

class MainMenu extends StatelessWidget {
  const MainMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: Theme.of(context).colorScheme.background,
      ),
      child: Scaffold(
        appBar: const Header("Game of QR"),
        body: MenusLayout(
          children: [
            WoodenButton(
              title: "Start",
              openPage: () => const MainGame(),
            ),
            WoodenButton(
              title: "Settings",
              openPage: () => const SettingsScreen(),
            ),
            Text(
              "How to play:",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const Text(
              "Point camera on a QR code, and Conway's Game of Life starts with the pixels of the QR code as he initial generation.",
              textAlign: TextAlign.center,
            ),
            const Text(
              "New cells can be added manually via touch.",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
