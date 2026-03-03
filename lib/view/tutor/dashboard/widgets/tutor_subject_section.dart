import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/models/tutor_subject.dart';

class TutorSubjectsSection extends StatelessWidget {
  final List<TutorSubject> subjects;
  final bool isLoading;
  final VoidCallback onAddPressed;
  final Function(int) onDeletePressed;

  const TutorSubjectsSection({
    Key? key,
    required this.subjects,
    required this.onAddPressed,
    required this.onDeletePressed,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkBlue.withOpacity(0.8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.lightBlueColor.withOpacity(0.6),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          if (isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.white))
          else if (subjects.isEmpty)
            _buildEmptyState()
          else
            _buildSubjectsList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mis Materias',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.lightBlueColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${subjects.length} materia${subjects.length != 1 ? 's' : ''}',
                style: const TextStyle(color: AppColors.lightBlueColor, fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: onAddPressed,
          icon: const Icon(Icons.add, color: Colors.white, size: 16),
          label: const Text('Añadir', style: TextStyle(color: Colors.white, fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'No tienes materias agregadas aún.',
        style: TextStyle(color: Colors.white70, fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSubjectsList() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: subjects.length,
        itemBuilder: (context, index) {
          final item = subjects[index];
          return _SubjectCard(
            name: item.subject.name,
            onDelete: () => onDeletePressed(item.id),
          );
        },
      ),
    );
  }
}

// Widget interno para la tarjeta individual (más limpio)
class _SubjectCard extends StatelessWidget {
  final String name;
  final VoidCallback onDelete;

  const _SubjectCard({required this.name, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: AppColors.darkBlue,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBlueColor.withOpacity(0.8), width: 2),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.book, color: AppColors.lightBlueColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}