import 'package:flutter/material.dart';

class AppFooter extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabTapped;

  const AppFooter({
    super.key,
    required this.currentIndex,
    required this.onTabTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Home Icon
          GestureDetector(
            onTap: () => onTabTapped(0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  currentIndex == 0
                      ? 'assets/images/home-active.png'
                      : 'assets/images/home-inactive.png',
                  width: 28,
                  height: 28,
                ),
              ],
            ),
          ),

          // Stat Icon
          GestureDetector(
            onTap: () => onTabTapped(2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  currentIndex == 2
                      ? 'assets/images/statistics-active.png'
                      : 'assets/images/statistics-inactive.png',
                  width: 22,
                  height: 22,
                ),
              ],
            ),
          ),
          // Profile Icon
          GestureDetector(
            onTap: () => onTabTapped(1),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  currentIndex == 1
                      ? 'assets/images/profile-active.png'
                      : 'assets/images/profile-inactive.png',
                  width: 28,
                  height: 28,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
