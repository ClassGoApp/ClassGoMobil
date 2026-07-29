import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_projects/base_components/custom_snack_bar.dart';
import 'package:flutter_projects/l10n/app_localizations.dart';
import 'package:flutter_projects/view/tutor/features/widgets/tutor_header.dart';
import 'package:provider/provider.dart';

import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/provider/tutor_subjects_provider.dart';

import 'package:flutter_projects/view/tutor/features/subjects/sheets/add_subject_sheet.dart';
import 'package:flutter_projects/view/tutor/features/subjects/widgets/add_subject_button.dart';
import 'package:flutter_projects/view/tutor/features/subjects/widgets/subject_list_item.dart';
import 'package:flutter_projects/view/tutor/features/subjects/widgets/subjects_search_bar.dart';
import 'package:flutter_projects/view/tutor/features/subjects/services/subject_search_service.dart';

class TutorSubjectsScreen extends StatefulWidget {
  const TutorSubjectsScreen({Key? key}) : super(key: key);

  @override
  State<TutorSubjectsScreen> createState() => _TutorSubjectsScreenState();
}

class _TutorSubjectsScreenState extends State<TutorSubjectsScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  int? _selectedSubjectId; 

  Timer? _debounce;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  final Set<int> _addingIds = {}; 
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final q = _searchController.text.trim();
      if (q.isEmpty) {
        if (mounted) setState(() { _searchResults = []; _isSearching = false; });
      } else {
        _searchSubjects(q);
      }
    });
  }

  Future<void> _searchSubjects(String query) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final provider = Provider.of<TutorSubjectsProvider>(context, listen: false);

    if (auth.token == null) return;

    if (mounted) setState(() { _isSearching = true; _searchResults = []; });

    try {
      final results = await SubjectSearchService.searchSubjects(
        auth.token!,
        query,
        provider.subjects.map((s) => s.subjectId).toSet(),
        perPage: 50,
      );

      if (!mounted) return;
      setState(() { _searchResults = results; });
    } catch (e) {
      print('DEBUG searchSubjects error: $e');
    } finally {
      if (mounted) setState(() { _isSearching = false; });
    }
  }

  void _clearSearch() {
    if (_searchController.text.isEmpty) return;
    _searchController.clear();
    if (mounted) setState(() { _searchResults = []; _isSearching = false; });
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

    final searchQuery = _searchController.text.trim();
    final bool isSearching = searchQuery.isNotEmpty;

    final filteredSubjects = provider.subjects.where((item) {
      return item.subject.name.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    // Construir contenido central de la lista de materias según estado
    Widget content;
    if (provider.isLoading && provider.subjects.isEmpty && !isSearching) {
      content = const Center(child: CircularProgressIndicator(color: AppColors.brandCyan));
    } else if (isSearching) {
      if (_isSearching) {
        content = const Center(child: CircularProgressIndicator(color: AppColors.brandCyan));
      } else if (_searchResults.isEmpty) {
        content = _buildEmptyState(isDark);
      } else {
        content = ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: _searchResults.length + 1,
          itemBuilder: (context, index) {
            if (index == _searchResults.length) {
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: AddSubjectButton(onPressed: _openAddSubjectModal),
              );
            }

            final item = _searchResults[index];
            final bool isAdded = item['isAdded'] == true;

            return GestureDetector(
              onTap: () async {
                final int subjId = item['id'];
                if (isAdded) {
                  CustomToast.show(context, AppLocalizations.of(context)!.subjectAlreadyAdded, isSuccess: false);
                  return;
                }
                if (_addingIds.contains(subjId)) return;

                setState(() => _addingIds.add(subjId));

                final added = await Provider.of<TutorSubjectsProvider>(context, listen: false).addTutorSubjectToApi(auth, subjId, '', null);
                await Provider.of<TutorSubjectsProvider>(context, listen: false).loadTutorSubjects(auth);
                if (!mounted) return;

                setState(() {
                  _addingIds.remove(subjId);
                  _searchResults[index]['isAdded'] = added;
                  _searchResults.sort((a, b) => (a['isAdded'] ? 1 : 0) - (b['isAdded'] ? 1 : 0));
                });

                CustomToast.show(context, added ? AppLocalizations.of(context)!.subjectAddedSuccess(item['name']) : AppLocalizations.of(context)!.subjectAddedError(item['name']), isSuccess: added);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: isAdded ? AppColors.brandCyan.withOpacity(0.06) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isAdded ? AppColors.brandCyan : Colors.grey.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    _addingIds.contains(item['id'])
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(isAdded ? Icons.check_circle_rounded : Icons.circle_outlined, color: isAdded ? AppColors.brandCyan : Colors.grey),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        item['name'],
                        style: TextStyle(fontWeight: isAdded ? FontWeight.bold : FontWeight.w500, color: isAdded ? AppColors.brandCyan : Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    } else {
      content = ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: filteredSubjects.isEmpty ? 3 : filteredSubjects.length + 2,
        itemBuilder: (context, index) {
          if (filteredSubjects.isEmpty) {
            if (index == 0) return _buildEmptyState(isDark);
            if (index == 1) {
              return Padding(padding: const EdgeInsets.only(top: 24.0), child: AddSubjectButton(onPressed: _openAddSubjectModal));
            }
            if (index == 2) return const SizedBox(height: 120);
          } else {
            if (index < filteredSubjects.length) {
              final item = filteredSubjects[index];
              final isSelected = _selectedSubjectId == item.id;

              return SubjectListItem(
                key: ValueKey(item.id),
                name: item.subject.name,
                isSelected: isSelected,
                onTap: () {
                  setState(() { _selectedSubjectId = isSelected ? null : item.id; });
                },
                onDelete: () async {
                  final nombreMateria = item.subject.name.length > 25 ? "${item.subject.name.substring(0, 25)}..." : item.subject.name;
                  final success = await provider.deleteTutorSubjectFromApi(auth, item.id);
                  if (success && mounted) {
                    setState(() => _selectedSubjectId = null);
                    CustomToast.show(context, AppLocalizations.of(context)!.subjectDeletedSuccess(nombreMateria), isSuccess: true);
                  } else if (mounted) {
                    CustomToast.show(context, AppLocalizations.of(context)!.subjectDeleteError(nombreMateria), isSuccess: false);
                  }
                },
              );
            } else if (index == filteredSubjects.length) {
              return Padding(padding: const EdgeInsets.only(top: 8.0), child: AddSubjectButton(onPressed: _openAddSubjectModal));
            } else {
              return const SizedBox(height: 120);
            }
          }
          return const SizedBox.shrink();
        },
      );
    }

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            TutorHeader(
              title: AppLocalizations.of(context)!.subjectsTitle,
              subtitle: AppLocalizations.of(context)!.subjectsManagement,
            ),

            const SizedBox(height: 8),

            // Contador sutil de materias del tutor
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppLocalizations.of(context)!.youHaveSubjects(provider.subjects.length),
                  style: TextStyle(color: isDark ? Colors.white54 : Colors.grey[700], fontSize: 13, fontFamily: 'outfit'),
                ),
              ),
            ),

            const SizedBox(height: 6),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: SubjectsSearchBar(controller: _searchController, onClear: _clearSearch),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: RefreshIndicator(
                color: AppColors.brandCyan,
                backgroundColor: isDark ? const Color(0xFF151A24) : Colors.white,
                onRefresh: _fetchData,
                child: content,
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
              _searchController.text.isEmpty ? AppLocalizations.of(context)!.noSubjectsYet : AppLocalizations.of(context)!.noSearchResults,
              style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600], fontSize: 14, fontFamily: 'outfit'),
            ),
          ],
        ),
      ),
    );
  }
} 