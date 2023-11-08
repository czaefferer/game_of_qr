/* This file is part of Game-of-QR.
Game-of-QR is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
Game-of-QR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with Game-of-QR. If not, see <https://www.gnu.org/licenses/>. */
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:game_of_qr/app/game_of_qr_backend.dart';
import 'package:game_of_qr/menues/main_menu.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';

class GameOfQrApp extends StatefulWidget {
  const GameOfQrApp({super.key});

  @override
  State<GameOfQrApp> createState() => _GameOfQrAppState();
}

class _GameOfQrAppState extends State<GameOfQrApp> {
  Future<void>? _appLoader;
  late Backend backend;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.deferFirstFrame();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _appLoader ??= _loadApp(context).whenComplete(
      () => RendererBinding.instance.allowFirstFrame(),
    );
  }

  Future<void> _loadApp(BuildContext context) async {
    backend = await Backend.initialize();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _appLoader,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          log("Error during initialization: ${snapshot.error}\n${snapshot.stackTrace}");
          return MaterialAppWrapper(
            Material(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error during initialization:'),
                  Text(snapshot.error?.toString() ?? ""),
                  FilledButton(
                    onPressed: () {
                      Phoenix.rebirth(context);
                    },
                    child: Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialAppWrapper(
            Material(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }
        return BackendInheritedWidget(
          backend: backend,
          child: const MaterialAppWrapper(
            const MainMenu(),
          ),
        );
      },
    );
  }
}

class MaterialAppWrapper extends StatelessWidget {
  final Widget child;
  const MaterialAppWrapper(this.child, {super.key});

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
      home: child,
    );
  }
}
