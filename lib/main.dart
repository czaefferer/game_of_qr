import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:game_of_qr/main_menu.dart';
import 'package:game_of_qr/settings_store.dart';

void main() async {
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

class GameOfQrApp extends StatelessWidget {
  const GameOfQrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Game of QR',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blueGrey,
          cardColor: Colors.grey.shade400,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blueGrey,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const MainMenu(),
    );
  }
}
