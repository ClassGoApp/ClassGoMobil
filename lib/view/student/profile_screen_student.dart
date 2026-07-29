import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/auth/login_screen.dart';
import 'package:flutter_projects/view/home/widgets/suport_screen.dart';
import 'package:flutter_projects/view/profile/edit_profile_screen.dart';
import 'package:flutter_projects/view/profile/skeleton/profile_image_skeleton.dart';
import 'package:flutter_projects/view/settings/account_settings.dart';
import 'package:flutter_projects/base_components/custom_snack_bar.dart';
import 'package:flutter_projects/l10n/app_localizations.dart';
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
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            l10n.myProfile,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'outfit',
            ),
          ),
        ),
        body: _buildProfileContent(context, l10n),
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
        top: MediaQuery.of(context).padding.top + 20,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      child: Column(
        children: [
          // Información del perfil
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
              ],
              border: isDark ? Border.all(color: Colors.white10) : null,
            ),
            child: Column(
              children: [
                // Foto de perfil
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.transparent,
                    child: ClipOval(
                      child:
                          profileImageUrl != null && profileImageUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: profileImageUrl!,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      ProfileImageSkeleton(radius: 50),
                                  errorWidget: (context, url, error) =>
                                      CircleAvatar(
                                    radius: 50,
                                    backgroundColor:
                                        AppColors.primaryGreen.withOpacity(0.1),
                                    child: Icon(Icons.person,
                                        color: AppColors.primaryGreen,
                                        size: 50),
                                  ),
                                )
                              : CircleAvatar(
                                  radius: 50,
                                  backgroundColor:
                                      AppColors.primaryGreen.withOpacity(0.1),
                                  child: Icon(
                                    Icons.person,
                                    size: 50,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  fullName ?? l10n.defaultStudentName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleLarge?.color ??
                        AppColors.blackColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  email ?? l10n.defaultGuestEmail,
                  style: TextStyle(
                    color: isDark ? Colors.white54 : AppColors.greyColor,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlueColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    l10n.student,
                    style: TextStyle(
                      color: AppColors.lightBlueColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),

          // Opciones del perfil
          _buildProfileOption(
            icon: Icons.edit,
            title: l10n.edit,
            subtitle: l10n.editProfileSubtitle,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(),
                ),
              );
            },
          ),
          SizedBox(height: 12),
          _buildProfileOption(
            icon: Icons.security,
            title: l10n.accountSettings,
            subtitle: l10n.accountSettingsSubtitle,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AccountSettings(),
                ),
              );
            },
          ),
          SizedBox(height: 12),
          _buildProfileOption(
            icon: Icons.help_outline,
            title: l10n.help,
            subtitle: l10n.helpSubtitle,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SupportScreen(),
                ),
              );
            },
          ),
          SizedBox(height: 12),
          _buildProfileOption(
            icon: Icons.language,
            title: l10n.language,
            subtitle: l10n.selectLanguage,
            onTap: () => _showLanguageSelectionDialog(context),
          ),
          SizedBox(height: 12),
          _buildProfileOption(
            icon: Icons.logout,
            title: l10n.logout,
            subtitle: l10n.logoutSubtitle,
            color: Colors.red,
            onTap: () {
              _showLogoutDialog(l10n);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
        ],
        border: isDark ? Border.all(color: Colors.white10) : null,
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (color ?? AppColors.primaryGreen).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color ?? AppColors.primaryGreen,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyLarge?.color ?? AppColors.blackColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white54 : AppColors.greyColor,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: isDark ? Colors.white38 : AppColors.greyColor,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            l10n.logout,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.blackColor,
            ),
          ),
          content: Text(
            l10n.logoutConfirm,
            style: TextStyle(
              color: AppColors.greyColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                l10n.cancel,
                style: TextStyle(
                  color: AppColors.greyColor,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout(l10n);
              },
              child: Text(
                l10n.logout,
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout(AppLocalizations l10n) async {
    setState(() {
      isLoading = true;
    });
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        showCustomToast(context, l10n.logoutError, false);
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
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
