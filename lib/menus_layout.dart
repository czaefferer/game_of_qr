/* This file is part of Game-of-QR.
Game-of-QR is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
Game-of-QR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with Game-of-QR. If not, see <https://www.gnu.org/licenses/>. */

import 'package:flutter/material.dart';

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

  List<Widget> intersperse(List<Widget> widgets, Widget separator) {
    if (widgets.isEmpty) {
      return widgets;
    }
    List<Widget> result = [];
    for (var i = 0; i < widgets.length; i++) {
      if (i != 0) {
        result.add(separator);
      }
      result.add(widgets[i]);
    }
    return result;
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
