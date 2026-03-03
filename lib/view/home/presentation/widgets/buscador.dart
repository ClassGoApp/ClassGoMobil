import 'package:flutter/material.dart';

class Buscador extends StatelessWidget {
  final VoidCallback? onTap;
  final String hintText;
  final String imageAsset;

  const Buscador({
    Key? key,
    this.onTap,
    this.hintText = '¿Qué materia necesitas?',
    this.imageAsset = 'assets/images/cara.png',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                Text(
                  hintText,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 18,
                  ),
                ),
                Spacer(),
                Icon(Icons.search, color: Colors.white, size: 27),
              ],
            ),
          ],
        ),
      ),
    );
  }
}