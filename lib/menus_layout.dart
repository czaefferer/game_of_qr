import 'package:flutter/material.dart';

import 'package:game_of_qr/util.dart';

class MenusLayout extends StatelessWidget {
  const MenusLayout({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    // strech container to full screen
    return Container(
      width: double.infinity,
      height: double.infinity,
      // repeating background image
      decoration: BoxDecoration(
        image: DecorationImage(
          repeat: ImageRepeat.repeat,
          image: Theme.of(context).brightness == Brightness.light
              ? const AssetImage("assets/marble.png") //
              : const AssetImage("assets/java.png"), // coffee beans, not the programming language
          fit: BoxFit.none,
        ),
      ),
      // use 75% of the screen width ...
      child: FractionallySizedBox(
        widthFactor: 0.75,
        // Center is somehow required in between...
        child: Center(
          // ... but only use up to 400px
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: intersperse(children, const SizedBox(height: 12)),
            ),
          ),
        ),
      ),
    );
  }
}

class WoodenButton extends StatelessWidget {
  const WoodenButton({this.openPage, this.action, required this.title, super.key})
      : assert(openPage != null || action != null),
        assert(openPage == null || action == null);

  final Widget Function()? openPage;
  final void Function()? action;
  final String title;

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      padding: EdgeInsets.zero,
      onPressed: openPage != null
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => openPage!(),
                ),
              );
            }
          : action!,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          image: const DecorationImage(
            repeat: ImageRepeat.repeat,
            image: AssetImage('assets/wood.png'),
            fit: BoxFit.none,
          ),
          border: Border.all(
            color: Theme.of(context).primaryColor,
          ),
          borderRadius: const BorderRadius.all(
            Radius.circular(12),
          ),
        ),
        child: Center(
          child: Text(title),
        ),
      ),
    );
  }
}
