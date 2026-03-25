import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';

class StepOneSubjects extends StatefulWidget {
  final Function(List<String>) onSelectionChanged;

  const StepOneSubjects({Key? key, required this.onSelectionChanged}) : super(key: key);

  @override
  State<StepOneSubjects> createState() => _StepOneSubjectsState();
}

class _StepOneSubjectsState extends State<StepOneSubjects> {
  final List<String> _selectedSubjects = [];

  final List<Map<String, dynamic>> _categories = [
    {'id': '1', 'title': 'Contabilidad', 'icon': Icons.calculate_rounded, 'color': const Color(0xFF4A90E2)},
    {'id': '2', 'title': 'Química', 'icon': Icons.science_rounded, 'color': const Color(0xFF50E3C2)},
    {'id': '3', 'title': 'Programación', 'icon': Icons.terminal_rounded, 'color': const Color(0xFF9013FE)},
    {'id': '4', 'title': 'Inglés', 'icon': Icons.language_rounded, 'color': const Color(0xFFF5A623)},
    {'id': '5', 'title': 'Matemáticas', 'icon': Icons.functions_rounded, 'color': const Color(0xFFE1145C)},
    {'id': '6', 'title': 'Música', 'icon': Icons.music_note_rounded, 'color': const Color(0xFF8B572A)},
  ];

  void _toggleSubject(String subjectId) {
    setState(() {
      if (_selectedSubjects.contains(subjectId)) {
        _selectedSubjects.remove(subjectId);
      } else {
        _selectedSubjects.add(subjectId);
      }
    });
    widget.onSelectionChanged(_selectedSubjects);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¿Qué materias dominas?',
            style: TextStyle(
              fontFamily: 'outfit',
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.brandBlue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selecciona al menos una materia que te gustaría enseñar. Podrás agregar más adelante.',
            style: TextStyle(
              fontFamily: 'manrope',
              fontSize: 15,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 30),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = _selectedSubjects.contains(category['id']);

              return GestureDetector(
                onTap: () => _toggleSubject(category['id']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected ? category['color'].withOpacity(0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? category['color'] : Colors.grey.withOpacity(0.2),
                      width: isSelected ? 2.5 : 1.5,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: category['color'].withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                    ],
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: category['color'].withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                category['icon'],
                                color: category['color'],
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              category['title'],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'outfit',
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                color: isSelected ? category['color'] : AppColors.brandBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: category['color'],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, color: Colors.white, size: 14),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}