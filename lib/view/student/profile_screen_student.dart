import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/auth/login_screen.dart';
import 'package:flutter_projects/view/home/widgets/suport_screen.dart';
import 'package:flutter_projects/view/profile/edit_profile_screen.dart';
import 'package:flutter_projects/view/profile/skeleton/profile_image_skeleton.dart';
import 'package:flutter_projects/view/settings/account_settings.dart';
import 'package:flutter_projects/base_components/custom_snack_bar.dart';
import 'package:flutter_projects/l10n/app_localizations.dart';
import 'package:flutter_projects/view/tutor/features/profile/widgets/logout_section.dart';
import 'package:flutter_projects/view/components/pulsing_book_icon.dart';
import 'package:provider/provider.dart';

import '../../provider/auth_provider.dart';
import '../../provider/locale_provider.dart';
import 'services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  final bool showAppBar;

  const ProfileScreen({Key? key, this.showAppBar = true}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLoading = false;
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isLoggedIn) return;
      final int? userId = authProvider.userId;
      if (userId != null) {
        try {
          final img = await ProfileService.fetchProfileImage(userId);
          setState(() {
            profileImageUrl = img;
          });
        } catch (_) {}
      }
    });
  }

  void showCustomToast(BuildContext context, String message, bool isSuccess) {
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 1.0,
        left: 16.0,
        right: 16.0,
        child: CustomToast(
          message: message,
          isSuccess: isSuccess,
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
    Future.delayed(const Duration(seconds: 1), () {
      overlayEntry.remove();
    });
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
                title: Text(AppLocalizations.of(dialogContext)!.spanish),
                trailing: currentLocale == 'es' ? const Icon(Icons.check) : null,
                onTap: () {
                  localeProvider.setLocale(const Locale('es'));
                  Navigator.of(dialogContext).pop();
                },
              ),
              ListTile(
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
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    // GUEST MODE (NOT LOGGED IN)
    if (!authProvider.isLoggedIn) {
      debugPrint('ProfileScreen: Entering Guest Mode');
      return _GuestProfile(l10n: l10n);
    }

    if (widget.showAppBar) {
      final double statusBarHeight = MediaQuery.of(context).padding.top;

      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Column(
          children: [
            // Header azul marino
            AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
                statusBarBrightness: Brightness.dark,
              ),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: statusBarHeight + 15,
                  left: 20,
                  right: 20,
                  bottom: 25,
                ),
                decoration: BoxDecoration(
                  color: AppColors.headerLight,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.headerLight.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        PulsingBookIcon(
                          color: Colors.white,
                          size: 28,
                          duration: const Duration(milliseconds: 1500),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          l10n.myProfile,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'outfit',
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _buildProfileContent(context, l10n),
            ),
          ],
        ),
      );
    } else {
      return _buildProfileContent(context, l10n);
    }
  }

  Widget _buildProfileContent(BuildContext context, AppLocalizations l10n) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userData = authProvider.userData;
    final String? fullName = userData != null &&
            userData['user'] != null &&
            userData['user']['profile'] != null
        ? (userData['user']['profile']['full_name'] ??
            (userData['user']['profile']['first_name'] != null &&
                    userData['user']['profile']['last_name'] != null
                ? '${userData['user']['profile']['first_name']} ${userData['user']['profile']['last_name']}'
                : userData['user']['profile']['first_name'] ??
                    userData['user']['profile']['last_name'] ??
                    'Usuario'))
        : null;
    final String? email = userData != null && userData['user'] != null
        ? userData['user']['email']
        : null;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: 20,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      child: Column(
        children: [
          // TARJETA SUPERIOR CON GRADIENTE (IGUAL AL TUTOR)
          Container(
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
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Decoraciones circulares
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
                  // Contenido principal
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(top: 30, bottom: 30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Foto de perfil
                        Container(
                          width: 115,
                          height: 115,
                          decoration: BoxDecoration(
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(35),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.9),
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              )
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(31),
                            child: profileImageUrl != null &&
                                    profileImageUrl!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: profileImageUrl!,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) =>
                                        const Icon(Icons.person, size: 50),
                                  )
                                : const Icon(Icons.person,
                                    size: 60, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Nombre
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            (fullName ?? l10n.defaultStudentName)
                                .toUpperCase(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'outfit',
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                )
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Email
                        Text(
                          email ?? l10n.defaultGuestEmail,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'manrope',
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Badge Estudiante
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                              )
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.school_rounded,
                                color: AppColors.brandCyan,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                l10n.student,
                                style: const TextStyle(
                                  fontFamily: 'outfit',
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Opciones del perfil - ListTile elegantes
          _buildListTile(
            l10n.edit.toUpperCase(),
            Icons.edit_document,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditProfileScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildListTile(
            l10n.accountSettings.toUpperCase(),
            Icons.security,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AccountSettings()),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildListTile(
            l10n.help.toUpperCase(),
            Icons.help_outline_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SupportScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildListTile(
            l10n.language.toUpperCase(),
            Icons.language,
            onTap: () => _showLanguageSelectionDialog(context),
          ),
          const SizedBox(height: 12),
          _buildLogoutButton(l10n),
        ],
      ),
    );
  }

  Widget _buildListTile(
    String title,
    IconData icon, {
    Color textColor = const Color(0xFF023047),
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.cardDark : theme.cardTheme.color;
    final finalTextColor = isDark ? Colors.white : textColor;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: !isDark
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
        border: isDark ? Border.all(color: Colors.white10) : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        leading: Icon(icon, color: finalTextColor, size: 22),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'outfit',
            color: finalTextColor,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutButton(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? Colors.redAccent.withOpacity(0.05) : Colors.red[50]!;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.power_settings_new_rounded,
            color: Colors.redAccent,
            size: 20,
          ),
        ),
        title: Text(
          l10n.logout.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'outfit',
            color: Colors.redAccent,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: Colors.redAccent.withOpacity(0.6),
        ),
        onTap: () => LogoutSection.showLogoutDialog(context),
      ),
    );
  }
}

class _GuestProfile extends StatelessWidget {
  final AppLocalizations l10n;
  
  const _GuestProfile({Key? key, required this.l10n}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint('GuestProfile: build method executed');
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: Colors.white.withOpacity(0.85),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.loginToAccessProfile,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.loginToAccessProfileDesc,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lightBlueColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 36,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  l10n.login,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
