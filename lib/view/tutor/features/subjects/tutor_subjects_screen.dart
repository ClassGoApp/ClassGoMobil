import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/provider/tutor_subjects_provider.dart'; 
import 'package:flutter_projects/view/tutor/dashboard/widgets/tutor_header-.dart';

import 'package:flutter_projects/view/tutor/features/subjects/sheets/add_subject_sheet.dart';
import 'package:flutter_projects/view/tutor/features/subjects/widgets/add_subject_button.dart';
import 'package:flutter_projects/view/tutor/features/subjects/widgets/subject_list_item.dart';
import 'package:flutter_projects/view/tutor/features/subjects/widgets/subjects_search_bar.dart';

class TutorSubjectsScreen extends StatefulWidget {

  const TutorSubjectsScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<TutorSubjectsScreen> createState() => _TutorSubjectsScreenState();
}

class _TutorSubjectsScreenState extends State<TutorSubjectsScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  int? _selectedSubjectId; 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
    _searchController.addListener(() => setState(() {})); 
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token != null && auth.userId != null) {
      await Provider.of<TutorSubjectsProvider>(context, listen: false)
          .loadTutorSubjects(auth);
    }
  }

  void _openAddSubjectModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddSubjectSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF0C0E12) : const Color(0xFFF4F6F9);

    final provider = Provider.of<TutorSubjectsProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    // Filtro local
    final searchQuery = _searchController.text.toLowerCase();
    final filteredSubjects = provider.subjects.where((item) {
      return item.subject.name.toLowerCase().contains(searchQuery);
    }).toList();

    final int listCount = filteredSubjects.isEmpty 
        ? 3 // 0: EmptyState, 1: Botón Añadir, 2: Espacio Fantasma
        : filteredSubjects.length + 2; // N: Materias, N+1: Botón Añadir, N+2: Espacio Fantasma

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            TutorHeader(
              title: "Materias",
              onBackTap: () => Navigator.maybePop(context),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: SubjectsSearchBar(controller: _searchController),
            ),

            const SizedBox(height: 8),

            // LISTA VERTICAL RECARGABLE
            Expanded(
              child: RefreshIndicator(
                color: AppColors.brandCyan,
                backgroundColor: isDark ? const Color(0xFF151A24) : Colors.white,
                onRefresh: _fetchData,
                child: provider.isLoading && provider.subjects.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: AppColors.brandCyan))
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: listCount, // Usamos la nueva cuenta segura
                        itemBuilder: (context, index) {
                          
                          // ESCENARIO A: NO HAY MATERIAS
                          if (filteredSubjects.isEmpty) {
                            if (index == 0) {
                              return _buildEmptyState(isDark);
                            }
                            if (index == 1) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 24.0),
                                child: AddSubjectButton(onPressed: _openAddSubjectModal),
                              );
                            }
                            if (index == 2) {
                              return const SizedBox(height: 120); 
                            }
                          }

                          // ESCENARIO B: SÍ HAY MATERIAS
                          else {
                            // 1. Dibujamos las tarjetas de materias
                            if (index < filteredSubjects.length) {
                              final item = filteredSubjects[index];
                              final isSelected = _selectedSubjectId == item.id;

                              return SubjectListItem(
                                key: ValueKey(item.id),
                                name: item.subject.name,
                                isSelected: isSelected,
                                onTap: () {
                                  setState(() {
                                    _selectedSubjectId = isSelected ? null : item.id;
                                  });
                                },
                                onDelete: () async {
                                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                                  final nombreMateria = item.subject.name;
                                  
                                  final success = await provider.deleteTutorSubjectFromApi(auth, item.id);
                                  if (success && mounted) {
                                    setState(() => _selectedSubjectId = null);
                                    scaffoldMessenger.clearSnackBars();
                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(content: Text("Materia '$nombreMateria' liminada"), backgroundColor: AppColors.primaryGreen, duration: const Duration(seconds: 2)),
                                    );
                                  } else if (mounted) {
                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(content: Text(provider.error ?? "Error al eliminar"), backgroundColor: Colors.redAccent),
                                    );
                                  }
                                },
                              );
                            } 
                            // 2. Dibujamos el botón de añadir al final de las materias
                            else if (index == filteredSubjects.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: AddSubjectButton(onPressed: _openAddSubjectModal),
                              );
                            } 
                            // 3. Dibujamos el Espacio Fantasma para salvar el Nav Bar
                            else {
                              return const SizedBox(height: 120);
                            }
                          }
                          return const SizedBox.shrink();
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0, top: 24.0),
        child: Column(
          children: [
            Icon(Icons.menu_book_rounded, size: 60, color: isDark ? Colors.white24 : Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty 
                  ? "No tienes materias agregadas aún." 
                  : "No se encontraron resultados.",
              style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600], fontSize: 14, fontFamily: 'outfit'),
            ),
          ],
        ),
      ),
    );
  }
}