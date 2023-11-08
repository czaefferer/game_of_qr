/* This file is part of Game-of-QR.
Game-of-QR is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
Game-of-QR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with Game-of-QR. If not, see <https://www.gnu.org/licenses/>. */

import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

class _SettingsDefault {
  static ResolutionPreset resolution = Platform.isIOS ? ResolutionPreset.low : ResolutionPreset.high;
  static int delay = 100;
  static bool arEnabled = false;
  static int gameSpeed = 500;
}

class Settings {
  bool _writeOnChangeEnabled = false;
  ResolutionPreset _resolution = _SettingsDefault.resolution;
  int _delay = _SettingsDefault.delay;
  bool _arEnabled = _SettingsDefault.arEnabled;
  int _gameSpeed = _SettingsDefault.gameSpeed;

  Settings();

  factory Settings.emptySettings() {
    return Settings()..enableWriteOnChange();
  }

  static Future<Settings> load() async {
    try {
      final file = await _settingsFile();
      if (!file.existsSync()) {
        return Settings.emptySettings();
      }
      final contents = await file.readAsString();
      var data = jsonDecode(contents);
      if (data == null || data is! Map<String, dynamic>) {
        return Settings.emptySettings();
      }
      Settings settings = Settings();
      if (data['resolution'] is int) {
        settings._resolution = intToResolutionPreset(data['resolution'] as int);
      }
      if (data['delay'] is int) {
        settings._delay = data['delay'] as int;
      }
      if (data['arEnabled'] is bool) {
        settings._arEnabled = data['arEnabled'] as bool;
      }
      if (data['gameSpeed'] is int) {
        settings._gameSpeed = data['gameSpeed'] as int;
      }

      // load completed, from now on save changes to settings
      settings.enableWriteOnChange();

      return settings;
    } on Exception catch (e, stacktrace) {
      log('Error while loading settings from disc: $e\n$stacktrace');
      return Settings.emptySettings();
    }
  }

  Future<void> save() async {
    Map<String, dynamic> data = {
      'resolution': resolutionPresetToInt(_resolution),
      'delay': _delay,
      'arEnabled': _arEnabled,
      'gameSpeed': _gameSpeed,
    };
    final file = await _settingsFile();
    file.writeAsStringSync(jsonEncode(data));
  }

  static Future<File> _settingsFile() async {
    final path = (await getApplicationDocumentsDirectory()).path;
    return File('$path/settings.json');
  }

  void reset() {
    _resolution = _SettingsDefault.resolution;
    _delay = _SettingsDefault.delay;
    _arEnabled = _SettingsDefault.arEnabled;
    _gameSpeed = _SettingsDefault.gameSpeed;
    if (_writeOnChangeEnabled) {
      save();
    }
  }

  bool get arEnabled => _arEnabled;
  set arEnabled(bool arEnabled) {
    _arEnabled = arEnabled;
    if (_writeOnChangeEnabled) {
      save();
    }
  }

  int get delay => _delay;
  set delay(int delay) {
    _delay = delay;
    if (_writeOnChangeEnabled) {
      save();
    }
  }

  int get gameSpeed => _gameSpeed;
  set gameSpeed(int gameSpeed) {
    _gameSpeed = gameSpeed;
    if (_writeOnChangeEnabled) {
      save();
    }
  }

  ResolutionPreset get resolution => _resolution;
  set resolution(ResolutionPreset resolution) {
    _resolution = resolution;
    if (_writeOnChangeEnabled) {
      save();
    }
  }

  void enableWriteOnChange() {
    _writeOnChangeEnabled = true;
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
}
