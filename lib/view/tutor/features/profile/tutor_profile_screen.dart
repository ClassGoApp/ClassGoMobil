import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_projects/base_components/custom_snack_bar.dart';
import 'package:flutter_projects/view/tutor/features/profile/widgets/logout_section.dart';
import 'package:flutter_projects/view/tutor/features/profile/widgets/price_section.dart';
import 'package:flutter_projects/view/tutor/features/profile/widgets/qr_payment_screen.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter_projects/provider/tutor_subjects_provider.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/tutor/features/widgets/tutor_header.dart';
import 'package:flutter_projects/view/tutor/features/profile/video_presentation_modal.dart';
import 'package:flutter_projects/view/profile/edit_profile_screen.dart';
import 'package:flutter_projects/api_structure/config/app_config.dart';
import 'package:url_launcher/url_launcher.dart';

const String _kTitleFont = 'outfit';
const String _kBodyFont = 'manrope';

class TutorProfileScreen extends StatefulWidget {
  final Function(int) onNavigate;
  const TutorProfileScreen({Key? key, required this.onNavigate})
      : super(key: key);
  @override
  State<TutorProfileScreen> createState() => _TutorProfileScreenState();
}

class _TutorProfileScreenState extends State<TutorProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      Provider.of<TutorSubjectsProvider>(context, listen: false)
          .loadTutorSubjects(authProvider);
    });
  }

  bool _isExpanded = false;

  Future<void> _launchTermsUrl() async {
    final url = Uri.parse('https://classgoapp.com/terminos#tutorias-instantaneas');
    if (!await launchUrl(url, mode: LaunchMode.inAppWebView)) {
      if (mounted) {
        CustomToast.show(
          context,
          "No se pudo abrir el enlace",
          isSuccess: false,
        );
      }
    }
  }

  String _getShortName(String fullName) {
    if (fullName.trim().isEmpty) return "";
    List<String> parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0];
    if (parts.length == 2) return "${parts[0]} ${parts[1]}";
    return "${parts[0]} ${parts[2]}";
  }

  String _buildFullVideoUrl(String videoPath) {
    if (videoPath.startsWith('http://') || videoPath.startsWith('https://')) {
      return videoPath;
    }
    final baseUrl = AppConfig.mediaBaseUrl;
    String cleanBaseUrl = baseUrl;
    if (!cleanBaseUrl.endsWith('/')) cleanBaseUrl = '$cleanBaseUrl/';

    String cleanVideoPath = videoPath;
    if (cleanVideoPath.startsWith('/'))
      cleanVideoPath = cleanVideoPath.substring(1);

    return '$cleanBaseUrl$cleanVideoPath';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userData?['user'];
    final profile = user?['profile'] ?? {};

    final String email = user['email'];
    final bool isVerified = profile['verified'] == true;
    final String firstName = profile['first_name'] ?? '';
    final String lastName = profile['last_name'] ?? '';
    final String userName = '$firstName $lastName'.trim().isEmpty
        ? (user?['name'] ?? 'Tutor')
        : '$firstName $lastName'.trim();

    final String? photoUrl =
        profile['image'] ?? profile['profile_image'] ?? user?['profile_image'];

    String? videoPath = profile['intro_video'];
    String? videoUrl = (videoPath != null && videoPath.isNotEmpty)
        ? _buildFullVideoUrl(videoPath)
        : null;

    print(
        'DEBUG - TutorProfileScreen leyendo intro_video desde provider: $videoPath');
    print('DEBUG - TutorProfileScreen videoUrl construido: $videoUrl');

    final String description = profile['description'] ?? '';

    final subjectsProvider = Provider.of<TutorSubjectsProvider>(context);
    List<String> subjectNames = [];
    if (!subjectsProvider.isLoading) {
      subjectNames =
          subjectsProvider.subjects.map((s) => s.subject.name).toList();
    }
    final shortName = _getShortName(userName);

    final scaffoldBg = isDark ? AppColors.blackColor : AppColors.whiteColor;
    final cardBgColor = isDark ? AppColors.blackColor : AppColors.whiteColor;
    final mainTextColor = isDark ? AppColors.whiteColor : AppColors.brandBlue;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: scaffoldBg,
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              const TutorHeader(
                title: "MI PERFIL",
                subtitle: "GESTIÓN DE PERFIL",
                //onBackTap: () {Navigator.maybePop(context);},
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 120),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildTopCard(photoUrl, shortName, isDark, isVerified, email),
                        Container(
                          margin: const EdgeInsets.only(top: 20),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: cardBgColor,
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10)),
                            ],
                          ),
                          child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: _buildMainView(description, subjectNames,
                                  isDark, mainTextColor, videoUrl)),
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

  Widget _buildTopCard(String? photoUrl, String userName, bool isDark, bool isVerified, String email) {
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
              color: (isDark ? Colors.black : AppColors.brandBlue)
                  .withOpacity(0.35),
              blurRadius: 25,
              offset: const Offset(0, 15)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: -60,
              right: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.0)
                  ]),
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              left: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppColors.whiteColor.withOpacity(0.2),
                    AppColors.whiteColor.withOpacity(0.0)
                  ]),
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
                        width: 115,
                        height: 115,
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(35),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.9), width: 4),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 20,
                                offset: const Offset(0, 8))
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(31),
                          child: photoUrl != null && photoUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: photoUrl,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) =>
                                      const Icon(Icons.person, size: 50))
                              : const Icon(Icons.person,
                                  size: 60, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
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
                        shadows: [
                          Shadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2))
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: _kBodyFont,
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: isVerified
                              ? Colors.white.withOpacity(0.25)
                              : Colors.grey.withOpacity(0.5)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10)
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                            isVerified
                                ? Icons.verified_rounded
                                : Icons.hourglass_empty_rounded,
                            color: isVerified
                                ? AppColors.brandCyan
                                : Colors.grey[400],
                            size: 16),
                        const SizedBox(width: 6),
                        Text(
                          isVerified
                              ? "TUTOR VERIFICADO"
                              : "TUTOR SIN VERIFICAR",
                          style: TextStyle(
                              fontFamily: _kBodyFont,
                              color:
                                  isVerified ? Colors.white : Colors.grey[400],
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0),
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

  Widget _buildMainView(String description, List<String> subjects, bool isDark,
      Color mainTextColor, String? videoUrl) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userData?['user'];
    final innerBgColor =
        isDark ? const Color(0xFF1E222A) : const Color(0xFFF4F6F9);

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
                  gradientColors: [
                    AppColors.brandOrange,
                    const Color(0xFFD96D00)
                  ],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => EditProfileScreen()),
                    ).then((isUpdated) {
                      if (isUpdated == true) {
                        setState(() {});
                      }
                    });
                  }),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                  title: "MI PRESENTACIÓN",
                  value: "VIDEO",
                  icon: Icons.play_circle_fill_rounded,
                  gradientColors: [
                    AppColors.brandCyan,
                    const Color(0xFF1B8E9E)
                  ],
                  onTap: () => showDialog(
                      context: context,
                      builder: (_) => VideoPresentationDialog(
                            videoUrl: videoUrl,
                          ))),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: innerBgColor, borderRadius: BorderRadius.circular(24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                      width: 5,
                      height: 18,
                      decoration: BoxDecoration(
                          color: AppColors.brandCyan,
                          borderRadius: BorderRadius.circular(10))),
                  const SizedBox(width: 10),
                  Text("FILOSOFÍA DE ENSEÑANZA",
                      style: TextStyle(
                          fontFamily: _kTitleFont,
                          color: mainTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "“$description”",
                style: const TextStyle(
                    fontFamily: _kBodyFont,
                    color: Colors.grey,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    height: 1.6),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(children: [
          Container(
              width: 5,
              height: 18,
              decoration: BoxDecoration(
                  color: AppColors.brandOrange,
                  borderRadius: BorderRadius.circular(10))),
          const SizedBox(width: 10),
          Text("CONFIGURACION DE PAGOS ",
              style: TextStyle(
                  fontFamily: _kTitleFont,
                  color: mainTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5)),
        ]),
        const SizedBox(height: 12),
        const TutorPriceSection(),
        const SizedBox(height: 12),
        _buildListTile("MÉTODO DE PAGO (QR)", Icons.qr_code_scanner_rounded,
            mainTextColor, innerBgColor, onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const QrPaymentScreen(initialQrUrl: null),
            ),
          );
        }),

        const SizedBox(height: 24),
        Row(
          children: [
            Container(
                width: 5,
                height: 18,
                decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(10))),
            const SizedBox(width: 10),
            Text("LEGAL",
                style: TextStyle(
                    fontFamily: _kTitleFont,
                    color: mainTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5)),
          ],
        ),
        const SizedBox(height: 12),
        _buildListTile(
            user?['terms_accepted'] == true
                ? "TÉRMINOS Y CONDICIONES"
                : "TÉRMINOS Y CONDICIONES (PENDIENTE)",
            Icons.gavel_rounded,
            mainTextColor,
            isDark ? const Color(0xFF1E222A) : const Color(0xFFF4F6F9),
            onTap: () {
          if (user?['terms_accepted'] == true) {
            _launchTermsUrl();
          } else {
            CustomToast.show(
              context,
              "Debes aceptar los términos y condiciones",
              isWarning: true,
            );
            widget.onNavigate(0);
          }
        }),

        const SizedBox(height: 40),
        // const SizedBox(height: 12),
        // _buildListTile("DIPLOMAS Y CERTIFICADOS",
        //     Icons.workspace_premium_outlined, mainTextColor, innerBgColor),
        // const SizedBox(height: 12),
        // _buildListTile("AJUSTES AVANZADOS", Icons.settings_outlined,
        //     Colors.grey, innerBgColor),

        // ELEMENTOS OCULTOS POR REDUNDANCIA UX
        /*
        const SizedBox(height: 24),
        _buildChipsSection(
          title: "MATERIAS",
          items: subjects,
          color: AppColors.brandCyan,
          innerBgColor: innerBgColor,
          mainTextColor: mainTextColor,
          actionIcon: Icons.auto_stories_outlined,
          onChipTap: null,
        ),
        const SizedBox(height: 20),
        _buildChipsSection(
          title: "IDIOMAS",
          items: const ["Español (Nativo)"],
          color: AppColors.brandOrange,
          innerBgColor: innerBgColor,
          mainTextColor: mainTextColor,
          actionIcon: Icons.language_outlined,
          onChipTap: null,
        ),
        const SizedBox(height: 30),
        */
        const LogoutSection(),
      ],
    );
  }

  Widget _buildActionCard(
      {required String title,
      required String value,
      required IconData icon,
      required List<Color> gradientColors,
      VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 125,
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
                color: gradientColors.last.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 8))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            children: [
              Positioned(
                right: -15,
                bottom: -15,
                child: Transform.rotate(
                    angle: -0.2,
                    child: Icon(icon,
                        size: 90, color: Colors.white.withOpacity(0.15))),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle),
                      child: Icon(icon, color: Colors.white, size: 22),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(value,
                            style: const TextStyle(
                                fontFamily: _kTitleFont,
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5)),
                        const SizedBox(height: 2),
                        Text(title,
                            style: TextStyle(
                                fontFamily: _kBodyFont,
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5)),
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
            Container(
                width: 5,
                height: 16,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(10))),
            const SizedBox(width: 10),
            Text(title,
                style: TextStyle(
                    fontFamily: _kTitleFont,
                    color: mainTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5)),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text(
                "${items.length}",
                style: TextStyle(
                  fontFamily: _kTitleFont,
                  color: mainTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: innerBgColor, borderRadius: BorderRadius.circular(20)),
          child: items.isEmpty
              ? const Text(
                  " Aún no tienes materias agregadas.",
                  style: TextStyle(
                    fontFamily: _kBodyFont,
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 10,
                      children: [
                        ...items
                            .take(_isExpanded ? items.length : 4)
                            .map((s) => _buildStyledChip(
                                  s,
                                  color,
                                  actionIcon: actionIcon,
                                  onTap: onChipTap,
                                ))
                            .toList(),
                      ],
                    ),
                    if (items.length > 4) const SizedBox(height: 12),
                    if (items.length > 4)
                      Align(
                        alignment: Alignment.centerRight,
                        child: ActionChip(
                          label: Text(
                            _isExpanded
                                ? "Ver menos"
                                : "+${items.length - 4} más",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _isExpanded ? Colors.grey : color,
                            ),
                          ),
                          backgroundColor:
                              _isExpanded ? Colors.transparent : Colors.white,
                          side: BorderSide(
                            color: _isExpanded
                                ? Colors.grey.withOpacity(0.3)
                                : color.withOpacity(0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          onPressed: () {
                            setState(() {
                              _isExpanded = !_isExpanded;
                            });
                          },
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildStyledChip(String label, Color baseColor,
      {IconData? actionIcon, Function(String)? onTap}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 7.0),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: baseColor.withOpacity(0.5), width: 1),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 180),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (actionIcon != null) ...[
              Icon(actionIcon, color: baseColor, size: 14),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
                style: TextStyle(
                  fontFamily: _kBodyFont,
                  color: baseColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(
      String title, IconData icon, Color textColor, Color bgColor,
      {VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        leading: Icon(icon, color: textColor, size: 22),
        title: Text(title,
            style: TextStyle(
                fontFamily: _kTitleFont,
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5)),
        trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
        onTap: onTap,
      ),
    );
  }
}
