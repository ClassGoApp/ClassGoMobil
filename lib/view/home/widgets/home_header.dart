import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/styles/app_design.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/student/serch_Tutor/search_tutors_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_projects/provider/locale_provider.dart';
import 'package:flutter_projects/l10n/app_localizations.dart';

class HomeHeader extends StatefulWidget {
  final VoidCallback onMenuTap;
  final VoidCallback onProfileTap;

  const HomeHeader({
    Key? key,
    required this.onMenuTap,
    required this.onProfileTap,
  }) : super(key: key);

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounce;
  List<Map<String, dynamic>> _suggestions = [];
  bool _showSuggestions = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _fetchSuggestions(value.trim());
    });
  }

  Future<void> _fetchSuggestions(String keyword) async {
    try {
      final data = await findTutors(null, perPage: 5, keyword: keyword);
      if (!mounted) return;
      final List<dynamic>? tutors = data['data'];
      if (tutors != null && tutors.isNotEmpty) {
        setState(() {
          _suggestions = tutors.cast<Map<String, dynamic>>();
          _showSuggestions = true;
        });
      } else {
        setState(() {
          _suggestions = [];
          _showSuggestions = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
    }
  }

  void _navigateToSearch([String? keyword]) {
    final value = keyword ?? _searchController.text.trim();
    _searchFocusNode.unfocus();
    setState(() => _showSuggestions = false);
    if (value.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchTutorsScreen(initialKeyword: value),
      ),
    );
  }

    void _showLanguageSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final localeProvider = Provider.of<LocaleProvider>(dialogContext, listen: false);
        final currentLocale = localeProvider.locale?.languageCode ?? Localizations.localeOf(dialogContext).languageCode;

        return AlertDialog(
          title: Text(AppLocalizations.of(dialogContext)!.selectLanguage),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Text('🇪🇸', style: TextStyle(fontSize: 24)),
                title: Text(AppLocalizations.of(dialogContext)!.spanish),
                trailing: currentLocale == 'es' ? const Icon(Icons.check) : null,
                onTap: () {
                  localeProvider.setLocale(const Locale('es'));
                  Navigator.of(dialogContext).pop();
                },
              ),
              ListTile(
                leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
                title: Text(AppLocalizations.of(dialogContext)!.english),
                trailing: currentLocale == 'en' ? const Icon(Icons.check) : null,
                onTap: () {
                  localeProvider.setLocale(const Locale('en'));
                  Navigator.of(dialogContext).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      pinned: true,
      stretch: false,
      expandedHeight: 270.0,
      toolbarHeight: 70.0,
      collapsedHeight: 70.0,
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      shape: const ContinuousRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(60),
          bottomRight: Radius.circular(60),
        ),
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.fromARGB(255, 36, 107, 124), AppColors.brandBlue],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
        child: FlexibleSpaceBar(
          background: SafeArea(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.only(top: 80.0, left: 20, right: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.65,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            AppLocalizations.of(context)!.findTutors,
                            style: const TextStyle(
                              fontFamily: AppFonts.heading,
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.cardLight,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 15,
                                offset: const Offset(0, 5)),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          textInputAction: TextInputAction.search,
                          onChanged: _onSearchChanged,
                          onSubmitted: (value) => _navigateToSearch(),
                          style: const TextStyle(
                              fontFamily: AppFonts.body,
                              color: AppColors.textLightPrimary),
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)!.searchSubjectHint,
                            hintStyle: const TextStyle(
                                fontFamily: AppFonts.body,
                                color: AppColors.lightGreyColor,
                                fontSize: 15),
                            prefixIcon: const Icon(Icons.search,
                                color: AppColors.brandCyan, size: 24),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close_rounded,
                                        color: AppColors.lightGreyColor,
                                        size: 20),
                                    onPressed: () {
                                      _searchController.clear();
                                      _onSearchChanged('');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        child: _showSuggestions && _suggestions.isNotEmpty
                            ? Container(
                                margin: const EdgeInsets.only(top: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.cardLight,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.12),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      for (int i = 0;
                                          i < _suggestions.length;
                                          i++)
                                        _buildSuggestionTile(
                                            _suggestions[i], i),
                                    ],
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 15,
                  top: 70,
                  child: Image.asset(
                    'assets/images/ave_animada.gif',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: widget.onMenuTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.menu, color: Colors.white, size: 24),
            ),
          ),
          Image.asset('assets/images/logo_classgo.png', height: 36),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botón de idioma con bandera
              Consumer<LocaleProvider>(
                builder: (context, localeProvider, _) {
                  final isSpanish = localeProvider.locale?.languageCode == 'es' || 
                                   (localeProvider.locale == null && Localizations.localeOf(context).languageCode == 'es');
                  return InkWell(
                    onTap: () => _showLanguageSelectionDialog(context),
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        isSpanish ? '🇪🇸' : '🇬🇧',
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: widget.onProfileTap,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(Icons.person_outline,
                      color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionTile(Map<String, dynamic> tutor, int index) {
    final name = tutor['full_name'] ?? tutor['name'] ?? 'Tutor';
    final subjects = tutor['subjects'] ?? [];
    final imageUrl = tutor['image'] ?? '';
    final rating = tutor['avg_rating'];

    String subjectsStr = '';
    if (subjects is List && subjects.isNotEmpty) {
      subjectsStr = subjects.take(3).join(', ');
    }

    return InkWell(
      onTap: () {
        _searchController.text = name;
        _navigateToSearch(name);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl, vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          border: index < _suggestions.length - 1
              ? const Border(
                  bottom: BorderSide(color: AppColors.dividerLight))
              : null,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildDefaultAvatar(name),
                    )
                  : _buildDefaultAvatar(name),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontFamily: AppFonts.heading,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLightPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subjectsStr.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subjectsStr,
                      style: const TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 12,
                        color: AppColors.textLightSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (rating != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.brandOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Text(
                  '⭐ ${rating.toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandOrange,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(String name) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: AppColors.brandCyan,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontFamily: AppFonts.heading,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
