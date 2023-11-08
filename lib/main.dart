/* This file is part of Game-of-QR.
Game-of-QR is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
Game-of-QR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with Game-of-QR. If not, see <https://www.gnu.org/licenses/>. */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game_of_qr/app/game_of_qr_app.dart';

import 'package:game_of_qr/settings/settings_store.dart';

void main() async {
  // TODO move to backend
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    AppSettings.instance.loadInitialValues(),
    // handling rotation of device makes handling of camera stream more complicated, while not fully supporting rotation anyways (see concession 1), so lock to portrait mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]),
  ]);
  runApp(const GameOfQrApp());
}
