import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/student/instant_tutoring/logic/subject_selection_controller.dart';
import 'package:flutter_projects/view/student/instant_tutoring/widgets/radar_search_screen.dart';

class SubjectSelectionScreen extends StatefulWidget {
  const SubjectSelectionScreen({super.key});

  @override
  State<SubjectSelectionScreen> createState() => _SubjectSelectionScreenState();
}

class _SubjectSelectionScreenState extends State<SubjectSelectionScreen> {
  late SubjectSelectionController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SubjectSelectionController();
    _init();
  }

  Future<void> _init() async {
    await _controller.initialize();
    
    // Si al cargar detectamos un batch activo, redirigimos de inmediato
    if (_controller.activeBatch != null && mounted) {
      final batch = _controller.activeBatch!;
      _navigateToRadar(
        batch['subject_id'].toString(), 
        "Recuperando tutoría...", // Podrías buscar el nombre real si quisieras
        batch['seconds_left'] ?? 300
      );
      _controller.clearActiveBatch();
    }
  }

  void _navigateToRadar(String id, String name, int seconds) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RadarSearchScreen(
          subjectId: id,
          subjectName: name,
          timerSeconds: seconds,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text("Tutoría al Instante", 
          style: TextStyle(fontFamily: 'outfit', fontWeight: FontWeight.bold, color: AppColors.brandBlue)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.brandBlue));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _controller.categories.length,
            itemBuilder: (context, index) {
              final category = _controller.categories[index];
              return _buildCategoryGroup(category);
            },
          );
        },
      ),
    );
  }

  Widget _buildCategoryGroup(dynamic category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Text(
            category['name'].toString().toUpperCase(),
            style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w800, 
              color: AppColors.greyColor, letterSpacing: 1.2
            ),
          ),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.dividerColor.withOpacity(0.5))
          ),
          child: Column(
            children: (category['subjects'] as List).map((subject) {
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                title: Text(subject['name'], 
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primaryColor)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.brandCyan),
                onTap: () => _navigateToRadar(
                  subject['id'].toString(), 
                  subject['name'], 
                  300
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}