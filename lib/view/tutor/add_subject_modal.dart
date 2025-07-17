import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/provider/tutor_subjects_provider.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:provider/provider.dart';

class AddSubjectModal extends StatefulWidget {
  @override
  _AddSubjectModalState createState() => _AddSubjectModalState();
}

class _AddSubjectModalState extends State<AddSubjectModal> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  int? _selectedSubjectId;
  String? _selectedImagePath;
  bool _isLoading = false;
  bool _isLoadingSubjects = true;
  List<Map<String, dynamic>> _availableSubjects = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableSubjects();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableSubjects() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.token == null) return;

      final response = await getAvailableSubjects(authProvider.token!);

      if (response['status'] == 200 && response['data'] != null) {
        final List<dynamic> subjectsData = response['data'];
        setState(() {
          _availableSubjects = subjectsData
              .map((subject) => {
                    'id': subject['id'],
                    'name': subject['name'],
                  })
              .toList();
          _isLoadingSubjects = false;
        });
      } else {
        // Si no hay API de materias disponibles, usar lista por defecto
        setState(() {
          _availableSubjects = [
            {'id': 1, 'name': 'Matemáticas'},
            {'id': 2, 'name': 'Física'},
            {'id': 3, 'name': 'Química'},
            {'id': 4, 'name': 'Biología'},
            {'id': 5, 'name': 'Historia'},
            {'id': 6, 'name': 'Geografía'},
            {'id': 7, 'name': 'Literatura'},
            {'id': 8, 'name': 'Inglés'},
            {'id': 9, 'name': 'Español'},
            {'id': 10, 'name': 'Programación'},
          ];
          _isLoadingSubjects = false;
        });
      }
    } catch (e) {
      print('Error loading available subjects: $e');
      // Usar lista por defecto en caso de error
      setState(() {
        _availableSubjects = [
          {'id': 1, 'name': 'Matemáticas'},
          {'id': 2, 'name': 'Física'},
          {'id': 3, 'name': 'Química'},
          {'id': 4, 'name': 'Biología'},
          {'id': 5, 'name': 'Historia'},
          {'id': 6, 'name': 'Geografía'},
          {'id': 7, 'name': 'Literatura'},
          {'id': 8, 'name': 'Inglés'},
          {'id': 9, 'name': 'Español'},
          {'id': 10, 'name': 'Programación'},
        ];
        _isLoadingSubjects = false;
      });
    }
  }

  Future<void> _addSubject() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor selecciona una materia')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final subjectsProvider =
        Provider.of<TutorSubjectsProvider>(context, listen: false);

    final success = await subjectsProvider.addTutorSubjectToApi(
      authProvider,
      _selectedSubjectId!,
      _descriptionController.text.trim(),
      _selectedImagePath,
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Materia agregada exitosamente'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(subjectsProvider.error ?? 'Error al agregar la materia'),
          backgroundColor: AppColors.redColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 18,
      ),
      decoration: BoxDecoration(
        color: AppColors.darkBlue,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Text(
              'Agregar materia',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            SizedBox(height: 24),

            // Selector de materia
            Text(
              'Materia',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            if (_isLoadingSubjects)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Cargando materias...',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: DropdownButtonFormField<int>(
                  value: _selectedSubjectId,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    hintText: 'Selecciona una materia',
                    hintStyle: TextStyle(color: Colors.white70),
                  ),
                  dropdownColor: AppColors.darkBlue,
                  style: TextStyle(color: Colors.white),
                  items: _availableSubjects.map((subject) {
                    return DropdownMenuItem<int>(
                      value: subject['id'],
                      child: Text(subject['name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSubjectId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Por favor selecciona una materia';
                    }
                    return null;
                  },
                ),
              ),
            SizedBox(height: 20),

            // Campo de descripción
            Text(
              'Descripción',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Describe tu experiencia en esta materia...',
                hintStyle: TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primaryGreen),
                ),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresa una descripción';
                }
                if (value.trim().length < 10) {
                  return 'La descripción debe tener al menos 10 caracteres';
                }
                return null;
              },
            ),
            SizedBox(height: 24),

            // Botones
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _isLoading ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _addSubject,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Agregar',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
