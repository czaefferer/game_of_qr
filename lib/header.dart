import 'package:flutter/material.dart';

class Header extends StatelessWidget implements PreferredSizeWidget {
  const Header(this.title, {this.showCloseButton = false, super.key});

  final String title;
  final bool showCloseButton;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      leading: SizedBox.square(
        dimension: 44,
        child: !showCloseButton
            ? null
            : GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close),
              ),
      ),
      title: Center(
        child: Text(title),
      ),
      // to have the text centered
      actions: const [
        SizedBox.square(
          dimension: 44,
        )
      ],
    );
  }
}
