import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  final VoidCallback onMenuTap;
  final VoidCallback onProfileTap;
  final bool isLeftDrawerOpen;
  final bool isCustomDrawerOpen;

  const HomeHeader({
    Key? key,
    required this.onMenuTap,
    required this.onProfileTap,
    required this.isLeftDrawerOpen,
    required this.isCustomDrawerOpen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left menu icon
          Builder(
            builder: (context) => InkWell(
              onTap: onMenuTap,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.all(6),
                child: Icon(Icons.menu, color: Colors.white, size: 26),
              ),
            ),
          ),
          Image.asset(
            'assets/images/logo_classgo.png',
            height: 38,
          ),
          // Right person icon
          Builder(
            builder: (context) => InkWell(
              onTap: onProfileTap,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.all(6),
                child:
                    Icon(Icons.person_outline, color: Colors.white, size: 26),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
