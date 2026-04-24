import 'package:flutter/material.dart';

class ChipsSection extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color color;
  final Color innerBgColor;
  final Color mainTextColor;

  const ChipsSection({
    Key? key,
    required this.title,
    required this.items,
    required this.color,
    required this.innerBgColor,
    required this.mainTextColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
                width: 5,
                height: 16,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(10))),
            const SizedBox(width: 10),
            Text(title,
                style: TextStyle(
                    fontFamily: 'outfit',
                    color: mainTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: innerBgColor, borderRadius: BorderRadius.circular(20)),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 10.0,
            children: items.map((s) => _buildStyledChip(s, color)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildStyledChip(String label, Color baseColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [baseColor.withOpacity(0.9), baseColor.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: baseColor.withOpacity(0.3), width: 1),
      ),
      child: Text(label,
          style: const TextStyle(
              fontFamily: 'manrope',
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3)),
    );
  }
}