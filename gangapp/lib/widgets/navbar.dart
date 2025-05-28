import 'package:flutter/material.dart';
import '../config/language.dart';

class Navbar extends StatelessWidget {
  final int currentIndex;

  const Navbar({
    Key? key,
    required this.currentIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: Language.translate('home'),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.psychology),
          label: Language.translate('ai'),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: Language.translate('profile'),
        ),
      ],
      onTap: (index) {
        if (index == currentIndex) return;
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/home');
            break;
          case 1:
            Navigator.pushReplacementNamed(context, '/groups');
            break;
          case 2:
            Navigator.pushReplacementNamed(context, '/profile');
            break;
        }
      },
    );
  }
}
