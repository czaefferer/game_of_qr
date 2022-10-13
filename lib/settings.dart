import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_tooltip/super_tooltip.dart';

final AppConfigurationService appConfigurationService = AppConfigurationService();

enum AppConfigurationOptions { resolution, delay, showCentered, gameSpeed }

class AppConfigurationService {
  static final AppConfigurationService _appConfigurationService = AppConfigurationService._internal();

  factory AppConfigurationService() {
    return _appConfigurationService;
  }
  AppConfigurationService._internal();
  final prefs = SharedPreferences.getInstance();

  Future<T> getValue<T>(AppConfigurationOptions name, T defaultValue) async {
// (await prefs).remove(AppConfigurationOptions.resolution.toString());
// (await prefs).remove(AppConfigurationOptions.delay.toString());
// (await prefs).remove(AppConfigurationOptions.showCentered.toString());
// (await prefs).remove(AppConfigurationOptions.gameSpeed.toString());

    if (T == bool) {
      return ((await prefs).getBool(name.toString()) ?? defaultValue) as T;
    } else if (T == int) {
      return ((await prefs).getInt(name.toString()) ?? defaultValue) as T;
    }
    throw StateError("type $T not implemented");
  }

  Future<void> setValue<T>(AppConfigurationOptions name, T value) async {
    if (T == bool) {
      await (await prefs).setBool(name.toString(), value as bool);
    } else if (T == int) {
      await (await prefs).setInt(name.toString(), value as int);
    } else {
      throw StateError("type $T not implemented");
    }
  }
}

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

int resolutionPresetToInt(ResolutionPreset resolutionPreset) {
  switch (resolutionPreset) {
    case ResolutionPreset.low:
      return 1;
    case ResolutionPreset.medium:
      return 2;
    case ResolutionPreset.high:
      return 3;
    case ResolutionPreset.veryHigh:
      return 4;
    case ResolutionPreset.ultraHigh:
      return 5;
    case ResolutionPreset.max:
      return 6;
  }
}

ResolutionPreset intToResolutionPreset(int resolutionPreset) {
  if (resolutionPreset <= 1) {
    return ResolutionPreset.low;
  }
  if (resolutionPreset == 2) {
    return ResolutionPreset.medium;
  }
  if (resolutionPreset == 3) {
    return ResolutionPreset.high;
  }
  if (resolutionPreset == 4) {
    return ResolutionPreset.veryHigh;
  }
  if (resolutionPreset == 5) {
    return ResolutionPreset.ultraHigh;
  }
  if (resolutionPreset >= 6) {
    return ResolutionPreset.max;
  }
  throw StateError("Apparently I can't count, unhandled resolution-preset");
}

class _SettingsState extends State<Settings> {
  bool isLoading = false;
  String? error;
  int resolution = resolutionPresetToInt(Platform.isIOS ? ResolutionPreset.low : ResolutionPreset.high);
  int delay = 100;
  bool showCentered = false;
  int gameSpeed = 500;

  @override
  void initState() {
    super.initState();
    scheduleMicrotask(loadValues);
  }

  Future<void> loadValues() async {
    resolution = await appConfigurationService.getValue<int>(AppConfigurationOptions.resolution, resolution);
    delay = await appConfigurationService.getValue<int>(AppConfigurationOptions.delay, delay);
    showCentered = await appConfigurationService.getValue<bool>(AppConfigurationOptions.showCentered, showCentered);
    gameSpeed = await appConfigurationService.getValue<int>(AppConfigurationOptions.gameSpeed, gameSpeed);
    setState(() {
      isLoading = false;
    });
  }

  void saveValue<T>(AppConfigurationOptions option, T value) async {
    try {
      await appConfigurationService.setValue<T>(option, value);
      await loadValues();
    } catch (e, stacktrace) {
      setState(() {
        log("$e - $stacktrace");
        error = e.toString();
        isLoading = false;
      });
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
          child: Text("Einstellungen"),
        ),
        actions: const [
          SizedBox.square(
            dimension: 44,
          )
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            repeat: ImageRepeat.repeat,
            image: AssetImage("assets/java.png"),
            fit: BoxFit.none,
          ),
        ),
        padding: const EdgeInsets.only(top: 16),
        child: ListView(
          children: <Widget>[
            if (error != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  error!,
                  style: Theme.of(context).textTheme.bodyText2!.copyWith(color: Theme.of(context).errorColor),
                ),
              ),
            Container(
              height: 44,
              margin: const EdgeInsets.only(bottom: 2),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      "Auflösung",
                      style: Theme.of(context).textTheme.bodyText2,
                    ),
                  ),
                  Slider(
                    onChanged: isLoading ? null : (value) => saveValue<int>(AppConfigurationOptions.resolution, value.round()),
                    value: resolution.toDouble(),
                    min: 1,
                    max: 6,
                    divisions: 5,
                    activeColor: Colors.green,
                    inactiveColor: Colors.red,
                  ),
                  Builder(
                    builder: (context) {
                      return GestureDetector(
                          onTap: () => createTooltip(context, "Je höher die Kamera-Auflösung ist, desto besser können QR-Codes erkannt werden. Dafür wird aber auch mehr Performance benötigt."),
                          child: const Icon(Icons.info));
                    },
                  ),
                ],
              ),
            ),
            Container(
              height: 44,
              margin: const EdgeInsets.only(bottom: 2),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      "Abtastrate",
                      style: Theme.of(context).textTheme.bodyText2,
                    ),
                  ),
                  Slider(
                    onChanged: isLoading ? null : (value) => saveValue<int>(AppConfigurationOptions.delay, 1000 - value.round()),
                    value: 1000 - delay.toDouble(),
                    min: 0,
                    max: 950,
                    activeColor: Colors.green,
                    inactiveColor: Colors.red,
                  ),
                  Builder(
                    builder: (context) {
                      return GestureDetector(
                          onTap: () => createTooltip(context,
                              "Je höher die Abtastrate ist, desto häufiger wird nach QR-Codes gesucht, und desto häufiger wird die Position des Game of Lifes aktualisiert. Dafür wird aber auch mehr Performance benötigt."),
                          child: const Icon(Icons.info));
                    },
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: isLoading ? null : () => saveValue(AppConfigurationOptions.showCentered, !showCentered),
              child: Container(
                height: 44,
                margin: const EdgeInsets.only(bottom: 2),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        "Game of Life zentriert anzeigen",
                        style: Theme.of(context).textTheme.bodyText2,
                      ),
                    ),
                    Switch(
                      value: showCentered,
                      onChanged: isLoading ? null : (_) => saveValue<bool>(AppConfigurationOptions.showCentered, !showCentered),
                      activeColor: Colors.green,
                      inactiveTrackColor: Colors.red,
                    ),
                    const SizedBox(width: 11),
                    Builder(
                      builder: (context) {
                        return GestureDetector(
                            onTap: () => createTooltip(context, "Wenn aktiviert, wird das Game of Life zentriert angezeigt statt über dem gefundenen QR Code. Dies kann die Performance verbessern."),
                            child: const Icon(Icons.info));
                      },
                    ),
                  ],
                ),
              ),
            ),
            Container(
              height: 44,
              margin: const EdgeInsets.only(bottom: 2),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      "Spielgeschwindigkeit",
                      style: Theme.of(context).textTheme.bodyText2,
                    ),
                  ),
                  Slider(
                    onChanged: isLoading ? null : (value) => saveValue<int>(AppConfigurationOptions.gameSpeed, 1500 - value.round()),
                    value: 1500 - gameSpeed.toDouble(),
                    min: 0,
                    max: 1300,
                    activeColor: Colors.green,
                    inactiveColor: Colors.red,
                  ),
                  Builder(
                    builder: (context) {
                      return GestureDetector(
                          onTap: () => createTooltip(context, "Je höher die Geschwindigkeit ist, desto schneller läuft das Game of Life, dafür wird aber auch mehr Performance benötigt."),
                          child: const Icon(Icons.info));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void createTooltip(BuildContext context, String text) {
    SuperTooltip(
      popupDirection: TooltipDirection.left,
      arrowTipDistance: 10.0,
      showCloseButton: ShowCloseButton.inside,
      closeButtonColor: Colors.black,
      closeButtonSize: 30.0,
      hasShadow: false,
      content: Material(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child: Text(
            text,
            softWrap: true,
            style: const TextStyle(color: Colors.black),
          ),
        ),
      ),
    ).show(context);
  }
}
