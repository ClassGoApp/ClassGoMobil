import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';

class FilterTutorBottomSheet extends StatefulWidget {
  final List<String> subjectGroups;
  
  final int? selectedGroupId;
  final String? keyword;
  final int? minCourses;
  final double? minRating;

  final Function({
    int? groupId,
    String? keyword,
    int? minCourses,
    double? minRating,
  }) onApplyFilters;

  const FilterTutorBottomSheet({
    Key? key,
    required this.subjectGroups,
    this.selectedGroupId,
    this.keyword,
    this.minCourses,
    this.minRating,
    required this.onApplyFilters,
  }) : super(key: key);

  @override
  _FilterTutorBottomSheetState createState() => _FilterTutorBottomSheetState();
}

class _FilterTutorBottomSheetState extends State<FilterTutorBottomSheet> {
  int? _selectedGroupId;
  late TextEditingController _keywordController;
  double _minCourses = 0;
  double _minRating = 0.0;

  @override
  void initState() {
    super.initState();
    _selectedGroupId = widget.selectedGroupId;
    _keywordController = TextEditingController(text: widget.keyword);
    _minCourses = widget.minCourses?.toDouble() ?? 0;
    _minRating = widget.minRating ?? 0.0;
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _selectedGroupId = null;
      _keywordController.clear();
      _minCourses = 0;
      _minRating = 0.0;
    });
  }

  void _applyFilters() {
    widget.onApplyFilters(
      groupId: _selectedGroupId,
      keyword: _keywordController.text.trim(),
      minCourses: _minCourses.toInt(),
      minRating: _minRating,
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
                  style: TextStyle(color: AppColors.whiteColor.withOpacity(0.7)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _keywordController,
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
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16),
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
           Text(
            'Calificación Mínima: ${_minRating.toStringAsFixed(1)} ★',
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16),
          ),
          Slider(
            value: _minRating,
            min: 0,
            max: 5,
            divisions: 50,
            label: '${_minRating.toStringAsFixed(1)} ★',
            activeColor: AppColors.orangeprimary,
            inactiveColor: AppColors.orangeprimary.withOpacity(0.3),
            onChanged: (value) {
              setState(() {
                _minRating = value;
              });
            },
          ),
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
              child: const Text('Aplicar Filtros', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
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
          hintStyle: AppTextStyles.body.copyWith(color: AppColors.whiteColor.withOpacity(0.7), fontSize: 14),
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
          hint: Text(hint, style: AppTextStyles.body.copyWith(color: AppColors.whiteColor.withOpacity(0.7), fontSize: 14)),
          icon: Icon(Icons.arrow_drop_down, color: AppColors.whiteColor.withOpacity(0.7)),
          dropdownColor: AppColors.blurprimary,
          style: AppTextStyles.body.copyWith(color: AppColors.whiteColor, fontSize: 14),
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
