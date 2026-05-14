import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/home/widgets/suport_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class AlliancesScreen extends StatefulWidget {
  const AlliancesScreen({super.key});

  @override
  State<AlliancesScreen> createState() => _AlliancesScreenState();
}

class _AlliancesScreenState extends State<AlliancesScreen> {
  List<dynamic> allAlliances = [];
  List<dynamic> filteredAlliances = [];
  List<String> dynamicCategories = [];
  String? selectedCategory;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final response = await fetchAlliances();
      if (!mounted) return;

      if (response.containsKey('data')) {
        List<dynamic> data = response['data'];

        for (var item in data) {
          String rawCat =
              (item['categoria'] ?? 'otros').toString().toLowerCase().trim();

          if (rawCat == 'empresas') {
            item['categoria'] = 'Empresas';
          } else if (rawCat == 'colegio de profesionales') {
            item['categoria'] = 'Colegio de Profesionales';
          } else if (rawCat == 'universidad e instituto') {
            item['categoria'] = 'Universidad e Instituto';
          } else {
            item['categoria'] = 'Otros';
          }

          if (item['imagen'] != null) {
            String imgUrl = item['imagen'].toString();
            item['imagen'] = Uri.encodeFull(imgUrl.trim());
          }
        }

        final setOfCategories =
            data.map((item) => item['categoria'].toString()).toSet().toList();

        setOfCategories.sort((a, b) {
          int getPriority(String cat) {
            switch (cat) {
              case 'Colegio de Profesionales':
                return 1;
              case 'Universidad e Instituto':
                return 2;
              case 'Empresas':
                return 3;
              case 'Otros':
                return 999;
              default:
                return 50;
            }
          }

          return getPriority(a).compareTo(getPriority(b));
        });

        setState(() {
          allAlliances = data;
          filteredAlliances = data;
          dynamicCategories = setOfCategories;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error en Alliances: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _filterAlliances(String? category) {
    if (!mounted) return;
    setState(() {
      selectedCategory = category;
      if (category == null) {
        filteredAlliances = allAlliances;
      } else {
        filteredAlliances = allAlliances
            .where((item) => item['categoria']?.toString() == category)
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.brandBlue, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Nuestras Alianzas',
          style: TextStyle(
              fontFamily: 'outfit',
              fontWeight: FontWeight.bold,
              color: AppColors.brandBlue),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildCategoryFilters(),
          Expanded(
            child: isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.brandCyan))
                : filteredAlliances.isEmpty
                    ? _buildEmptyState()
                    : _buildGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters() {
    if (dynamicCategories.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20),
        itemCount: dynamicCategories.length,
        itemBuilder: (context, index) {
          final cat = dynamicCategories[index];
          final isSelected = selectedCategory == cat;

          return GestureDetector(
            onTap: () => _filterAlliances(isSelected ? null : cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.brandCyan : Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color:
                      isSelected ? AppColors.brandCyan : AppColors.dividerLight,
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: AppColors.brandCyan.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4))
                      ]
                    : [],
              ),
              child: Center(
                child: Text(
                  cat,
                  style: TextStyle(
                    fontFamily: 'outfit',
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.brandBlue,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGrid() {
    print(
        "Mostrando ${filteredAlliances.length} alianzas bajo el filtro: $selectedCategory");
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 0.85,
      ),
      itemCount: filteredAlliances.length,
      itemBuilder: (context, index) {
        final item = filteredAlliances[index];
        return _AllianceCard(
          name: item['titulo'] ?? 'Sin nombre',
          logoUrl: item['imagen'] ?? '',
          onTap: () => _showAllianceDetails(item),
        );
      },
    );
  }

  void _showAllianceDetails(Map<String, dynamic> alianza) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 25),
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: _SmartAllianceImage(
                imageUrl: alianza['imagen'] ?? '',
                title: alianza['titulo'] ?? '',
                height: 100,
                iconSize: 50,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              alianza['titulo'] ?? 'Sin título',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'outfit',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandBlue),
            ),
            const SizedBox(height: 15),
            Text(
              alianza['descripcion'] ?? 'Sin descripción disponible.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'manrope',
                  fontSize: 14,
                  color: AppColors.textLightSecondary,
                  height: 1.5),
            ),
            const SizedBox(height: 30),
            AnimatedScaleButton(
              onTap: () async {
                final url = alianza['enlace'];
                if (url != null && url.isNotEmpty) {
                  await launchUrl(Uri.parse(url),
                      mode: LaunchMode.externalApplication);
                }
              },
              color: AppColors.brandCyan,
              icon: Icons.language_rounded,
              label: 'Visitar Alianza',
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar',
                  style: TextStyle(
                      color: AppColors.lightGreyColor,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.handshake_outlined,
              size: 80, color: AppColors.lightGreyColor.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('No hay alianzas disponibles',
              style: TextStyle(
                  fontFamily: 'manrope', color: AppColors.lightGreyColor)),
        ],
      ),
    );
  }
}

class _AllianceCard extends StatelessWidget {
  final String name;
  final String logoUrl;
  final VoidCallback onTap;

  const _AllianceCard(
      {required this.name, required this.logoUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardLight,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.dividerLight),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: _SmartAllianceImage(
                  imageUrl: logoUrl,
                  title: name,
                  iconSize: 40,
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: AppColors.brandBlue.withOpacity(0.03),
                borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24)),
              ),
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontFamily: 'outfit',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.brandBlue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmartAllianceImage extends StatelessWidget {
  final String imageUrl;
  final String title;
  final double height;
  final double iconSize;

  const _SmartAllianceImage({
    required this.imageUrl,
    required this.title,
    this.height = double.infinity,
    this.iconSize = 40,
  });

  static const Map<String, String> _localAllianceAssets = {
    'cognikids': 'assets/images/home/alliances/CogniKids.jpeg',
    'colegiodecontadorespublicos': 'assets/images/home/alliances/ColegiodeContadoresPúblicosdeSantaCruz.jpeg',
    'colegiodeprofesionalesencomunicacion': 'assets/images/home/alliances/ColegiodeProfesionalesenComunicación.png',
    'colegiodeingenieroscomerciales': 'assets/images/home/alliances/ColegiodedeIngenierosComercialesSantaCruz.jpeg',
    'constructorachassa': 'assets/images/home/alliances/ConstructoraChassa.jpeg',
    'camarainmobiliariadesantacruz': 'assets/images/home/alliances/CámaraInmobiliariadeSantaCruz.webp',
    'estilocolorcuracautin': 'assets/images/home/alliances/EstiloColorCuracautin.jpeg',
    'lacocinadeluchita': 'assets/images/home/alliances/LaCocinadeLuchita.png',
    'asociaciondeprofesionalesfinancieros': 'assets/images/home/alliances/asociaciondeprofesionalesfinancieros.jpeg',
    'uagrm': 'assets/images/home/alliances/CarreradeContaduríaPúblicaUAGRM.jpeg',
  };

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll(RegExp(r'[ñ]'), 'n')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  String? _findLocalAsset() {
    final normalizedTitle = _normalize(title);
    final normalizedUrl = _normalize(imageUrl);

    for (final entry in _localAllianceAssets.entries) {
      if (normalizedTitle.contains(entry.key) || normalizedUrl.contains(entry.key)) {
        return entry.value;
      }
    }
  print("TITLE REAL: $title");
print("IMAGE URL: $imageUrl");
print("NORMALIZED TITLE: ${_normalize(title)}");
print("NORMALIZED URL: ${_normalize(imageUrl)}");
    return null;
  }

  @override
  Widget build(BuildContext context) {
    Widget fallback() {
      final localAsset = _findLocalAsset();
      if (localAsset != null) {
        return Image.asset(
          localAsset,
          height: height == double.infinity ? null : height,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => SizedBox(
            height: height == double.infinity ? null : height,
            child: Center(
              child: Icon(Icons.business_rounded,
                  color: AppColors.lightGreyColor, size: iconSize),
            ),
          ),
        );
      }

      return SizedBox(
        height: height == double.infinity ? null : height,
        child: Center(
          child: Icon(Icons.business_rounded,
              color: AppColors.lightGreyColor, size: iconSize),
        ),
      );
    }

    if (imageUrl.isEmpty) return fallback();

    if (imageUrl.startsWith('data:image')) {
      try {
        final base64String = imageUrl.split(',').last;
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          height: height,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => fallback(),
        );
      } catch (e) {
        return fallback();
      }
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      height: height,
      fit: BoxFit.contain,
      placeholder: (context, url) => SizedBox(
        height: height == double.infinity ? null : height,
        child: const Center(
            child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: AppColors.brandCyan, strokeWidth: 2))),
      ),
      errorWidget: (context, url, error) => fallback(),
    );
  }
}
