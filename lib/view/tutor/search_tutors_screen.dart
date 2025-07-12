import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/tutor/widgets/search_header_widget.dart';
import 'package:flutter_projects/view/tutor/widgets/tutor_list_widget.dart';
import 'package:flutter_projects/provider/search_tutors_provider.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_projects/view/tutor/component/filter_turtor_bottom_sheet.dart';
import 'package:flutter_projects/view/tutor/tutor_profile_screen.dart';
import 'package:flutter_projects/view/detailPage/detail_screen.dart';
import 'package:flutter_projects/helpers/slide_up_route.dart';

class SearchTutorsScreen extends StatefulWidget {
  final String? initialKeyword;
  final int? initialSubjectId;
  final String initialMode;

  const SearchTutorsScreen({
    Key? key,
    this.initialKeyword,
    this.initialSubjectId,
    this.initialMode = 'agendar',
  }) : super(key: key);

  @override
  State<SearchTutorsScreen> createState() => _SearchTutorsScreenState();
}

class _SearchTutorsScreenState extends State<SearchTutorsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  final List<String> _sortOptions = [
    'Nombre (A-Z)',
    'Nombre (Z-A)',
    'Materia (A-Z)',
    'Materia (Z-A)'
  ];

  @override
  void initState() {
    super.initState();
    _initializeSearch();
  }

  void _initializeSearch() {
    final searchProvider =
        Provider.of<SearchTutorsProvider>(context, listen: false);

    // Configurar valores iniciales
    if (widget.initialKeyword != null) {
      _searchController.text = widget.initialKeyword!;
      searchProvider.updateKeyword(widget.initialKeyword);
    }

    if (widget.initialSubjectId != null) {
      searchProvider.updateSubjectId(widget.initialSubjectId);
    }

    // Cargar tutores iniciales
    searchProvider.fetchInitialTutors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final searchProvider =
        Provider.of<SearchTutorsProvider>(context, listen: false);
    searchProvider.updateKeyword(_searchController.text);
  }

  void _onSortChanged(String? sortOption) {
    final searchProvider =
        Provider.of<SearchTutorsProvider>(context, listen: false);
    searchProvider.updateSortOption(sortOption);
  }

  void _onFilterTap() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterTutorBottomSheet(
        onFiltersApplied: (filters) {
          final searchProvider =
              Provider.of<SearchTutorsProvider>(context, listen: false);
          // Aplicar filtros al provider
          if (filters['maxPrice'] != null) {
            searchProvider.updateMaxPrice(filters['maxPrice']);
          }
          if (filters['country'] != null) {
            searchProvider.updateCountryId(filters['country']);
          }
          if (filters['sessionType'] != null) {
            searchProvider.updateSessionType(filters['sessionType']);
          }
          if (filters['languages'] != null) {
            searchProvider.updateLanguageIds(filters['languages']);
          }
        },
      ),
    );
  }

  void _onTutorTap(Map<String, dynamic> tutor) {
    Navigator.push(
      context,
      SlideUpRoute(
        child: TutorProfileScreen(
          tutorName: tutor['profile']['full_name'] ?? 'Tutor',
          tutorImage: tutor['profile']['image'] ?? '',
          subjects:
              (tutor['subjects'] as List?)?.map((s) => s['name']).join(', ') ??
                  '',
          tutorId: tutor['id']?.toString() ?? '',
          subjectId: widget.initialSubjectId?.toString() ?? '',
          description: tutor['profile']['description'] ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        title: Text(
          'Buscar Tutores',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<SearchTutorsProvider>(
        builder: (context, searchProvider, child) {
          return Column(
            children: [
              // Header con búsqueda y filtros
              Padding(
                padding: EdgeInsets.all(16),
                child: SearchHeaderWidget(
                  searchController: _searchController,
                  searchFocusNode: _searchFocusNode,
                  onSearchChanged: _onSearchChanged,
                  onFilterTap: _onFilterTap,
                  selectedSortOption: searchProvider.selectedSortOption,
                  sortOptions: _sortOptions,
                  onSortChanged: _onSortChanged,
                ),
              ),

              // Lista de tutores
              Expanded(
                child: searchProvider.isInitialLoading
                    ? Center(child: CircularProgressIndicator())
                    : searchProvider.error != null
                        ? _buildErrorWidget(searchProvider.error!)
                        : TutorListWidget(
                            tutors: searchProvider.tutors,
                            isLoading: searchProvider.isLoading,
                            hasMore: searchProvider.hasMore,
                            onLoadMore: searchProvider.loadMoreTutors,
                            onTutorTap: _onTutorTap,
                            scrollController: _scrollController,
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.greyColor,
          ),
          SizedBox(height: 16),
          Text(
            'Error al cargar tutores',
            style: TextStyle(
              color: AppColors.greyColor,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: AppColors.greyColor.withOpacity(0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final searchProvider =
                  Provider.of<SearchTutorsProvider>(context, listen: false);
              searchProvider.clearError();
              searchProvider.fetchInitialTutors();
            },
            child: Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
