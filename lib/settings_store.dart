/* This file is part of Game-of-QR.
Game-of-QR is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
Game-of-QR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with Game-of-QR. If not, see <https://www.gnu.org/licenses/>. */

import 'dart:convert';
import 'dart:io';
import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

// split into abstract class and specific class for reusage of Settings class
abstract class Settings {
  Future<String> get _appDataDirectory async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _settingsFile async {
    final path = await _appDataDirectory;
    return File('$path/settings.json');
  }

  Future<void> loadInitialValues() async {
    try {
      final file = await _settingsFile;
      final contents = await file.readAsString();
      var data = json.decode(contents);
      if (data == null || data is! Map<String, dynamic>) {
        return;
      }
      _initializeData(data);
    } on Exception catch (e) {
      log("loading settings from disc failed: $e");
    }
  }

  Future<void> _persist() async {
    try {
      Map<String, dynamic> data = _getData();
      final file = await _settingsFile;
      file.writeAsString(json.encode(data));
    } on Exception catch (e) {
      log("saving settings on disc failed: $e");
    }
  }

  Map<String, dynamic> _getData();

  void _initializeData(Map<String, dynamic> data);
}

// from here on specific for this app
class AppSettings extends Settings {
  // singleton instance
  AppSettings._internal();
  static final AppSettings _instance = AppSettings._internal();
  static AppSettings get instance => _instance;

  // initialization
  @override
  _initializeData(Map<String, dynamic> data) {
    if (data['resolution'] is int) {
      _resolution = intToResolutionPreset(data['resolution'] as int);
    }
    if (data['delay'] is int) {
      _delay = data['delay'] as int;
    }
    if (data['arEnabled'] is bool) {
      _arEnabled = data['arEnabled'] as bool;
    }
    if (data['gameSpeed'] is int) {
      _gameSpeed = data['gameSpeed'] as int;
    }
  }

  // persistance
  @override
  Map<String, dynamic> _getData() {
    return {
      'resolution': resolutionPresetToInt(_resolution),
      'delay': _delay,
      'arEnabled': _arEnabled,
      'gameSpeed': _gameSpeed,
    };
  }

  // setting: resolution
  ResolutionPreset _resolution = Platform.isIOS ? ResolutionPreset.low : ResolutionPreset.high;
  static ResolutionPreset get resultion => AppSettings.instance._resolution;
  static set resolution(ResolutionPreset resolution) {
    AppSettings.instance._resolution = resolution;
    AppSettings.instance._persist();
  }

  // setting: delay
  int _delay = 100;
  static int get delay => AppSettings.instance._delay;
  static set delay(int delay) {
    AppSettings.instance._delay = delay;
    AppSettings.instance._persist();
  }

  // setting: AR enabled
  bool _arEnabled = false;
  static bool get arEnabled => AppSettings.instance._arEnabled;
  static set arEnabled(bool arEnabled) {
    AppSettings.instance._arEnabled = arEnabled;
    AppSettings.instance._persist();
  }

  // setting: game speed
  int _gameSpeed = 500;
  static int get gameSpeed => AppSettings.instance._gameSpeed;
  static set gameSpeed(int gameSpeed) {
    AppSettings.instance._gameSpeed = gameSpeed;
    AppSettings.instance._persist();
  }

  // reset to default values
  static void reset() {
    AppSettings.instance._resolution = Platform.isIOS ? ResolutionPreset.low : ResolutionPreset.high;
    AppSettings.instance._delay = 100;
    AppSettings.instance._arEnabled = false;
    AppSettings.instance._gameSpeed = 500;
    AppSettings.instance._persist();
  }

  // resolution to int conversion
  static int resolutionPresetToInt(ResolutionPreset resolutionPreset) {
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

  // int to resolution conversion
  static ResolutionPreset intToResolutionPreset(int resolutionPreset) {
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
    throw StateError("unhandled resolution-preset $resolutionPreset");
  }
}
