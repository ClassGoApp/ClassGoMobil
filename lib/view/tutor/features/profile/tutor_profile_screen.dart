import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // IMPORTANTE: Agregado para el AnnotatedRegion
import 'package:flutter_projects/provider/tutor_subjects_provider.dart';
import 'package:flutter_projects/view/tutor/features/widgets/tutor_header.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_projects/styles/app_styles.dart';

import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/view/tutor/features/profile/video_presentation_modal.dart';
   
const String _kTitleFont = 'outfit';
const String _kBodyFont = 'manrope';

class TutorProfileScreen extends StatefulWidget {
  const TutorProfileScreen({Key? key}) : super(key: key);

  @override
  State<TutorProfileScreen> createState() => _TutorProfileScreenState();
}

class _TutorProfileScreenState extends State<TutorProfileScreen> {
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      Provider.of<TutorSubjectsProvider>(context, listen: false).loadTutorSubjects(authProvider);
    });
  }
  String _getShortName(String fullName) {
    if (fullName.trim().isEmpty) return "";
    List<String> parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0];
    if (parts.length == 2) return "${parts[0]} ${parts[1]}";
    return "${parts[0]} ${parts[2]}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userData?['user'];
    final profile = user?['profile'] ?? {};

    final String firstName = profile['first_name'] ?? '';
    final String lastName = profile['last_name'] ?? '';
    final String userName = '$firstName $lastName'.trim().isEmpty ? (user?['name'] ?? 'Tutor') : '$firstName $lastName'.trim();
        
    final String? photoUrl = profile['image'] ?? profile['profile_image'] ?? user?['profile_image'];
    final String description = profile['description'] ?? 'Sin descripción proporcionada.';

    final subjectsProvider = Provider.of<TutorSubjectsProvider>(context);
    List<String> subjectNames = [];
     if(!subjectsProvider.isLoading){
      subjectNames = subjectsProvider.subjects.map((s) => s.subject.name).toList();
      }
    final shortName = _getShortName(userName);

    final scaffoldBg = isDark ? AppColors.blackColor : AppColors.whiteColor; 
    final cardBgColor = isDark ? AppColors.blackColor : AppColors.whiteColor; 
    final mainTextColor = isDark ? AppColors.whiteColor : AppColors.brandBlue;

    // 💡 NUEVO: Envolvemos tu Scaffold con AnnotatedRegion para forzar la barra de estado
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // Barra siempre transparente
        statusBarIconBrightness: Brightness.light, // Íconos (batería, señal) blancos en Android
        statusBarBrightness: Brightness.dark, // Íconos blancos en iOS
      ),
      child: Scaffold(
        backgroundColor: scaffoldBg,
        body: SafeArea(
          top: false, 
          child: Column(
            children: [
              TutorHeader(
                title: "MI PERFIL",
                subtitle: "GESTIÓN DE PERFIL",
                onBackTap: () {
                  if (_isEditing) {
                    setState(() => _isEditing = false); 
                  } else {
                    Navigator.maybePop(context);
                  }
                },
                // onLogoutTap: () => print("Cerrar Sesión"),
              ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 120), 
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        _buildTopCard(photoUrl, shortName, isDark),

                        Container(
                          margin: const EdgeInsets.only(top: 20), 
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: cardBgColor,
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24), 
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: _isEditing 
                                  ? _buildEditForm(userName, description, isDark, mainTextColor) 
                                  : _buildMainView(description, subjectNames, isDark, mainTextColor), 
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopCard(String? photoUrl, String userName, bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
              ? [const Color(0xFF16181D), const Color(0xFF232833)] 
              : [AppColors.brandBlue, const Color(0xFF1A5A7A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : AppColors.brandBlue).withOpacity(0.35), 
            blurRadius: 25, 
            offset: const Offset(0, 15)
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: -60, right: -40,
              child: Container(
                width: 180, height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.0)]),
                ),
              ),
            ),
            Positioned(
              bottom: -40, left: -30,
              child: Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [AppColors.whiteColor.withOpacity(0.2), AppColors.whiteColor.withOpacity(0.0)]),
                ),
              ),
            ),

            Container(
              width: double.infinity, 
              padding: const EdgeInsets.only(top: 30, bottom: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center, 
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 115, height: 115,
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(35),
                          border: Border.all(color: Colors.white.withOpacity(0.9), width: 4),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8))],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(31),
                          child: photoUrl != null && photoUrl.isNotEmpty
                              ? CachedNetworkImage(imageUrl: photoUrl, fit: BoxFit.cover, errorWidget: (_,__,___) => const Icon(Icons.person, size: 50))
                              : const Icon(Icons.person, size: 60, color: Colors.grey),
                        ),
                      ),
                      Positioned(
                        bottom: -5, right: -5,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.brandOrange,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [BoxShadow(color: AppColors.brandOrange.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // NOMBRE
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      userName.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: _kTitleFont,
                        color: Colors.white, 
                        fontSize: 26, 
                        fontWeight: FontWeight.w900, 
                        letterSpacing: -0.5,
                        shadows: [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // BADGE "TUTOR VERIFICADO"
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.25)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded, color: AppColors.brandCyan, size: 16),
                        const SizedBox(width: 6),
                        const Text(
                          "TUTOR VERIFICADO",
                          style: TextStyle(fontFamily: _kBodyFont, color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.0),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
   Widget _buildMainView(String description, List<String> subjects, bool isDark, Color mainTextColor) {
    final innerBgColor = isDark ? const Color(0xFF1E222A) : const Color(0xFFF4F6F9);

    return Column(
      key: const ValueKey('MainView'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: "PERFIL COMPLETO", 
                value: "EDITAR", 
                icon: Icons.edit_document, 
                gradientColors: [AppColors.brandOrange, const Color(0xFFD96D00)], 
                onTap: () => setState(() => _isEditing = true) 
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                title: "MI PRESENTACIÓN", 
                value: "VIDEO", 
                icon: Icons.play_circle_fill_rounded, 
                gradientColors: [AppColors.brandCyan, const Color(0xFF1B8E9E)], 
                onTap: () => showDialog(context: context, builder: (_) => const VideoPresentationDialog())
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: innerBgColor, borderRadius: BorderRadius.circular(24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 5, height: 18, decoration: BoxDecoration(color: AppColors.brandCyan, borderRadius: BorderRadius.circular(10))),
                  const SizedBox(width: 10),
                  Text("FILOSOFÍA DE ENSEÑANZA", style: TextStyle(fontFamily: _kTitleFont, color: mainTextColor, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "“$description”", 
                style: const TextStyle(fontFamily: _kBodyFont, color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic, height: 1.6),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        _buildListTile("MÉTODOS DE COBRO", Icons.credit_card_outlined, mainTextColor, innerBgColor),
        const SizedBox(height: 12),
        _buildListTile("DIPLOMAS Y CERTIFICADOS", Icons.workspace_premium_outlined, mainTextColor, innerBgColor),
        const SizedBox(height: 12),
        _buildListTile("AJUSTES AVANZADOS", Icons.settings_outlined, Colors.grey, innerBgColor),
        
        const SizedBox(height: 24),

        _buildChipsSection(
          title: "MATERIAS", 
          items: subjects, 
          color: AppColors.brandCyan, 
          innerBgColor: innerBgColor, 
          mainTextColor: mainTextColor,
          actionIcon: Icons.calendar_month_rounded, 
          onChipTap: (nombreMateria) {
            print("Navegando al calendario de: $nombreMateria");
          }
        ),
        const SizedBox(height: 20),
        _buildChipsSection(
          title: "IDIOMAS", 
          items: const ["Español (Nativo)"], 
          color: AppColors.brandOrange, 
          innerBgColor: innerBgColor, 
          mainTextColor: mainTextColor
        ),
      ],
    );
  }

  Widget _buildEditForm(String userName, String description, bool isDark, Color mainTextColor) {
    List<String> nameParts = userName.split(' ');
    String initialName = nameParts.isNotEmpty ? nameParts.first : "";
    String initialLastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : "";
    final innerBgColor = isDark ? const Color(0xFF1E222A) : const Color(0xFFF4F6F9);

    return Column(
      key: const ValueKey('EditView'),
      children: [
        Row(
          children: [
            Expanded(child: _buildTextField("NOMBRE", initialName, innerBgColor, mainTextColor)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField("APELLIDO", initialLastName, innerBgColor, mainTextColor)),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField("CELULAR", "+1 (555) 012-3456", innerBgColor, mainTextColor),
        const SizedBox(height: 16),
        _buildTextField(
          "DESCRIPCIÓN", 
          description,
          innerBgColor,
          mainTextColor,
          maxLines: 4,
        ),
        
        const SizedBox(height: 30),

        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Aquí irá la lógica para guardar en la API
              setState(() => _isEditing = false); 
            },
            icon: const Icon(Icons.save_outlined, color: Colors.white, size: 20),
            label: const Text("Guardar Perfil", style: TextStyle(fontFamily: _kTitleFont, color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandCyan,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({required String title, required String value, required IconData icon, required List<Color> gradientColors, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 125, 
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [BoxShadow(color: gradientColors.last.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            children: [
              Positioned(
                right: -15, bottom: -15,
                child: Transform.rotate(angle: -0.2, child: Icon(icon, size: 90, color: Colors.white.withOpacity(0.15))),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                      child: Icon(icon, color: Colors.white, size: 22),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(value, style: const TextStyle(fontFamily: _kTitleFont, color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                        const SizedBox(height: 2),
                        Text(title, style: TextStyle(fontFamily: _kBodyFont, color: Colors.white.withOpacity(0.9), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChipsSection({
    required String title, 
    required List<String> items, 
    required Color color, 
    required Color innerBgColor, 
    required Color mainTextColor,
    IconData? actionIcon, 
    Function(String)? onChipTap, 
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 5, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10))),
            const SizedBox(width: 10),
            Text(title, style: TextStyle(fontFamily: _kTitleFont, color: mainTextColor, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: innerBgColor, borderRadius: BorderRadius.circular(20)),
          child: items.isEmpty 
            ? const Text(
                "Aún no hay registros.", 
                style: TextStyle(fontFamily: _kBodyFont, color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic),
              )
            : Wrap(
                spacing: 8.0, runSpacing: 10.0,
                children: items.map((s) => _buildStyledChip(s, color, actionIcon: actionIcon, onTap: onChipTap)).toList(),
              ),
        ),
      ],
    );
  }

  Widget _buildStyledChip(String label, Color baseColor, {IconData? actionIcon, Function(String)? onTap}) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap(label);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [baseColor.withOpacity(0.9), baseColor.withOpacity(0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: baseColor.withOpacity(0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontFamily: _kBodyFont, color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
            if (actionIcon != null) ...[
              const SizedBox(width: 6),
              Icon(actionIcon, color: Colors.white, size: 14),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(String title, IconData icon, Color textColor, Color bgColor) {
    return Container(
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)), 
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        leading: Icon(icon, color: textColor, size: 22),
        title: Text(title, style: TextStyle(fontFamily: _kTitleFont, color: textColor, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
        onTap: () {},
      ),
    );
  }

  Widget _buildTextField(String label, String initialValue, Color fillColor, Color textColor, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(label, style: const TextStyle(fontFamily: _kBodyFont, color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w800)),
        ),
        TextFormField(
          initialValue: initialValue,
          maxLines: maxLines,
          style: TextStyle(fontFamily: _kBodyFont, color: textColor, fontSize: 13, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            filled: true,
            fillColor: fillColor, 
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
      ],
    );
  }
}