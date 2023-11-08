/* This file is part of Game-of-QR.
Game-of-QR is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
Game-of-QR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with Game-of-QR. If not, see <https://www.gnu.org/licenses/>. */

import 'package:flutter/material.dart';
import 'package:game_of_qr/app/backend.dart';
import 'package:super_tooltip/super_tooltip.dart';

import 'package:game_of_qr/menues/header.dart';
import 'package:game_of_qr/menues/menus_layout.dart';
import 'package:game_of_qr/settings/settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Header("Settings", showCloseButton: true),
      body: MenusLayout(
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text("Camera resolution"),
              ),
              Expanded(
                child: Slider(
                  onChanged: (value) {
                    setState(() {
                      settings.resolution = Settings.intToResolutionPreset(value.round());
                    });
                  },
                  value: Settings.resolutionPresetToInt(settings.resolution).toDouble(),
                  min: 1,
                  max: 6,
                  divisions: 5,
                ),
              ),
              const InfoIcon("The higher the camera resolution, the better QR codes can be recognised. However, this also requires more performance."),
            ],
          ),
          Row(
            children: <Widget>[
              const Expanded(
                child: Text("Sampling rate"),
              ),
              Expanded(
                child: Slider(
                  onChanged: (value) {
                    setState(() {
                      settings.delay = 200 - value.round();
                    });
                  },
                  value: 200.0 - settings.delay,
                  min: 0,
                  max: 200,
                ),
              ),
              const InfoIcon("The higher the sampling rate, the more frequently QR codes are searched for and the more frequently the position of the Game of Life is updated. However, this also requires more performance."),
            ],
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                settings.arEnabled = !settings.arEnabled;
              });
            },
            child: Row(
              children: <Widget>[
                const Expanded(
                  child: Text("AR enabled"),
                ),
                Expanded(
                  child: Switch(
                    onChanged: (_) {
                      setState(() {
                        settings.arEnabled = !settings.arEnabled;
                      });
                    },
                    value: settings.arEnabled,
                  ),
                ),
                const InfoIcon("If activated, the Game of Life is displayed above the QR code found, otherwise it will be shown centered. Disabling AR can improve performance."),
              ],
            ),
          ),
          Row(
            children: <Widget>[
              const Expanded(
                child: Text("Game speed"),
              ),
              Expanded(
                child: Slider(
                  onChanged: (value) {
                    setState(() {
                      settings.gameSpeed = 1000 - value.round();
                    });
                  },
                  value: 1000 - settings.gameSpeed.toDouble(),
                  min: 0,
                  max: 1000,
                ),
              ),
              const InfoIcon("The higher the speed, the faster the Game of Life runs, but this also requires more performance."),
            ],
          ),
          WoodenButton(
            title: "Reset to default",
            action: () {
              setState(() {
                settings.reset();
              });
            },
          ),
          WoodenButton(
            title: "Close",
            action: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class InfoIcon extends StatefulWidget {
  const InfoIcon(this.text, {super.key});

  final String text;

  @override
  State<InfoIcon> createState() => _InfoIconState();
}

class _InfoIconState extends State<InfoIcon> {
  final _controller = SuperTooltipController();
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _controller.showTooltip,
      child: SuperTooltip(
        controller: _controller,
        arrowTipDistance: 12.0,
        popupDirection: TooltipDirection.left,
        backgroundColor: Theme.of(context).colorScheme.background,
        showCloseButton: ShowCloseButton.inside,
        closeButtonColor: Theme.of(context).colorScheme.onBackground,
        content: Material(
          child: Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Text(
              widget.text,
              softWrap: true,
            ),
          ),
        ),
        child: const Icon(Icons.info),
      ),
    );
  }
}
