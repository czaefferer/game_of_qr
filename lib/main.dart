import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game_of_qr/settings.dart';
import 'package:game_of_qr/main_game.dart';
import 'package:dynamic_color/dynamic_color.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  static final _defaultLightColorScheme = ColorScheme.fromSwatch(primarySwatch: Colors.blue);

  static final _defaultDarkColorScheme = ColorScheme.fromSwatch(primarySwatch: Colors.blue, brightness: Brightness.dark);
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

//     return MaterialApp(
//       title: 'Flutter Demo',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         //primarySwatch: Colors.blue,
// colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.brown),
//     useMaterial3: true,
//       ),
//       home: const MyHomePage(),
//     );

    return DynamicColorBuilder(builder: (lightColorScheme, darkColorScheme) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Game of QR',
        theme: ThemeData(
          colorScheme: lightColorScheme ?? _defaultLightColorScheme,
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: darkColorScheme ?? _defaultDarkColorScheme,
          useMaterial3: true,
        ),
        themeMode: ThemeMode.dark,
        home: const MyHomePage(),
      );
    });
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const SizedBox.square(
          dimension: 44,
        ),
        title: const Center(
          child: Text("Game of QR"),
        ),
        actions: const [
          SizedBox.square(
            dimension: 44,
          )
        ],
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width / 8),
        decoration: const BoxDecoration(
          image: DecorationImage(
            repeat: ImageRepeat.repeat,
            image: AssetImage("assets/java.png"),
            fit: BoxFit.none,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MaterialButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) {
                      return const TestScan();
                    },
                  ),
                );
              },
              child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      image: const DecorationImage(
                        repeat: ImageRepeat.repeat,
                        image: AssetImage('assets/wood.png'),
                        fit: BoxFit.none,
                      ),
                      border: Border.all(
                        color: Colors.black,
                      ),
                      borderRadius: const BorderRadius.all(Radius.circular(12))),
                  child: const Center(child: Text("Start"))),
            ),
            MaterialButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) {
                      return const Settings();
                    },
                  ),
                );
              },
              child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      image: const DecorationImage(
                        repeat: ImageRepeat.repeat,
                        image: AssetImage('assets/wood.png'),
                        fit: BoxFit.none,
                      ),
                      border: Border.all(
                        color: Colors.black,
                      ),
                      borderRadius: const BorderRadius.all(Radius.circular(12))),
                  child: const Center(child: Text("Einstellungen"))),
            ),
            Text("Wie spielen:", style: Theme.of(context).textTheme.headlineMedium),
            const Text(
              "Kamera auf einen QR Code richten, und Conway's Game of Life beginnt mit dem QR Code als Anfangsgeneration.",
              textAlign: TextAlign.center,
            ),
            const Text(
              "Per Wischen können neue Zellen hinzugefügt werden.",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
