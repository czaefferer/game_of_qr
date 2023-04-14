import 'package:flutter/material.dart';
import 'package:super_tooltip/super_tooltip.dart';

import 'package:game_of_qr/header.dart';
import 'package:game_of_qr/menus_layout.dart';
import 'package:game_of_qr/settings_store.dart';

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
                      AppSettings.resolution = AppSettings.intToResolutionPreset(value.round());
                    });
                  },
                  value: AppSettings.resolutionPresetToInt(AppSettings.resultion).toDouble(),
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
                      AppSettings.delay = 200 - value.round();
                    });
                  },
                  value: 200.0 - AppSettings.delay,
                  min: 0,
                  max: 200,
                ),
              ),
              const InfoIcon(
                  "The higher the sampling rate, the more frequently QR codes are searched for and the more frequently the position of the Game of Life is updated. However, this also requires more performance."),
            ],
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                AppSettings.arEnabled = !AppSettings.arEnabled;
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
                        AppSettings.arEnabled = !AppSettings.arEnabled;
                      });
                    },
                    value: AppSettings.arEnabled,
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
                      AppSettings.gameSpeed = 1000 - value.round();
                    });
                  },
                  value: 1000 - AppSettings.gameSpeed.toDouble(),
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
                AppSettings.reset();
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
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: showTooltip,
      child: const Icon(Icons.info),
    );
  }

  void showTooltip() {
    SuperTooltip(
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
    ).show(context);
  }
}
