import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:game_of_qr/header.dart';
import 'package:game_of_qr/main_game.dart';
import 'package:game_of_qr/menus_layout.dart';
import 'package:game_of_qr/settings_screen.dart';

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
