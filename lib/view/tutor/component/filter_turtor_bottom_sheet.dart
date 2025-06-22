import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';

class FilterTutorBottomSheet extends StatefulWidget {
  final List<String> subjectGroups;

  final int? selectedGroupId;
  final String? tutorName;
  final int? minCourses;
  final double? minRating;

  final void Function({
    int? groupId,
    String? tutorName,
    int? minCourses,
    double? minRating,
  }) onApplyFilters;

  const FilterTutorBottomSheet({
    Key? key,
    required this.subjectGroups,
    this.selectedGroupId,
    this.tutorName,
    this.minCourses,
    this.minRating,
    required this.onApplyFilters,
  }) : super(key: key);

  @override
  _FilterTutorBottomSheetState createState() => _FilterTutorBottomSheetState();
}

class _FilterTutorBottomSheetState extends State<FilterTutorBottomSheet> {
  int? _selectedGroupId;
  TextEditingController? _tutorNameController;
  double _minCourses = 0;
  double _minRating = 0.0;

  @override
  void initState() {
    super.initState();
    _selectedGroupId = widget.selectedGroupId;
    _tutorNameController = TextEditingController(text: widget.tutorName ?? '');
    _minCourses = widget.minCourses?.toDouble() ?? 0;
    _minRating = widget.minRating ?? 0.0;
  }

  @override
  void dispose() {
    _tutorNameController?.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _selectedGroupId = null;
      _tutorNameController?.clear();
      _minCourses = 0;
      _minRating = 0.0;
    });
  }

  void _applyFilters() {
    widget.onApplyFilters(
      groupId: _selectedGroupId,
      tutorName: _tutorNameController?.text.trim() ?? '',
      minCourses: _minCourses.toInt(),
      minRating: _minRating > 0 ? _minRating : null,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30.0)),
        border: Border(
          top: BorderSide(color: AppColors.navbar.withOpacity(0.3), width: 1.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filtros de Búsqueda',
                style: AppTextStyles.heading2.copyWith(color: Colors.white),
              ),
              TextButton(
                onPressed: _clearFilters,
                child: Text(
                  'Limpiar',
                  style:
                      TextStyle(color: AppColors.whiteColor.withOpacity(0.7)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _tutorNameController!,
            hint: 'Nombre del Tutor',
          ),
          const SizedBox(height: 20),
          _buildDropdown(
            hint: 'Categoría de Materia',
            value: _selectedGroupId,
            items: widget.subjectGroups.asMap().entries.map((entry) {
              return DropdownMenuItem<int>(
                value: entry.key + 1,
                child: Text(entry.value),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedGroupId = value;
              });
            },
          ),
          const SizedBox(height: 30),
          Text(
            'Cursos Completados (mínimo): ${_minCourses.toInt()}',
            style:
                TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16),
          ),
          Slider(
            value: _minCourses,
            min: 0,
            max: 18,
            divisions: 18,
            label: _minCourses.toInt().toString(),
            activeColor: AppColors.orangeprimary,
            inactiveColor: AppColors.orangeprimary.withOpacity(0.3),
            onChanged: (value) {
              setState(() {
                _minCourses = value;
              });
            },
          ),
          const SizedBox(height: 20),
          _buildStarRating(),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orangeprimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text('Aplicar Filtros',
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: controller,
        style: AppTextStyles.body.copyWith(color: AppColors.whiteColor),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.body.copyWith(
              color: AppColors.whiteColor.withOpacity(0.7), fontSize: 14),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required int? value,
    required List<DropdownMenuItem<int>> items,
    required void Function(int?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          hint: Text(hint,
              style: AppTextStyles.body.copyWith(
                  color: AppColors.whiteColor.withOpacity(0.7), fontSize: 14)),
          icon: Icon(Icons.arrow_drop_down,
              color: AppColors.whiteColor.withOpacity(0.7)),
          dropdownColor: AppColors.blurprimary,
          style: AppTextStyles.body
              .copyWith(color: AppColors.whiteColor, fontSize: 14),
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildStarRating() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Calificación mínima:',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_minRating.floor() == index + 1) {
                          _minRating = 0.0;
                        } else {
                          _minRating = index + 1.0;
                        }
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(
                        index < _minRating.floor()
                            ? Icons.star
                            : Icons.star_border,
                        color: index < _minRating.floor()
                            ? AppColors.orangeprimary
                            : Colors.white.withOpacity(0.5),
                        size: 28,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          SizedBox(height: 8),
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.orangeprimary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.orangeprimary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                _minRating > 0 ? '${_minRating.floor()} ★' : 'Sin filtro',
                style: TextStyle(
                  color: AppColors.orangeprimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (_minRating > 0) ...[
            SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _minRating = 0.0;
                });
              },
              child: Text(
                'Limpiar calificación',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
