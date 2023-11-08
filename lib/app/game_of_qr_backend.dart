/* This file is part of Game-of-QR.
Game-of-QR is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
Game-of-QR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with Game-of-QR. If not, see <https://www.gnu.org/licenses/>. */

import 'package:flutter/material.dart';
import 'package:game_of_qr/settings/settings.dart';

class Backend {
  Backend._();

  // Settings
  Settings? _settings;
  Settings get settings => _settings ?? (throw Exception("Settings not yet loaded"));

  Future<void> _initialize() async {
    _settings = await Settings.load();
  }

  static Future<Backend> initialize() async {
    var backend = Backend._();
    await backend._initialize();
    return backend;
  }
}

@immutable
class BackendInheritedWidget extends InheritedWidget {
  const BackendInheritedWidget({
    Key? key,
    required this.backend,
    required Widget child,
  }) : super(key: key, child: child);

  final Backend backend;

  static Backend of(BuildContext context) {
    return context.getInheritedWidgetOfExactType<BackendInheritedWidget>()!.backend;
  }

  @override
  bool updateShouldNotify(BackendInheritedWidget oldWidget) {
    return backend != oldWidget.backend;
  }
}

extension BackendBuildContextExtension on BuildContext {
  Backend get backend => BackendInheritedWidget.of(this);
  Settings get settings => backend.settings;
}

extension BackendStateExtension<T extends StatefulWidget> on State<T> {
  Backend get backend => context.backend;
  Settings get settings => context.settings;
}
