import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/tutor/dashboard/widgets/theme_toggle_button.dart';

class DashboardHeader extends StatelessWidget {
  // --- DATOS ---
  final String tutorName;
  final String? profileImageUrl;
  final double rating;
  final bool isVerified;

  // --- ESTADOS ---
  final bool isLoadingImage;
  final bool isAvailable;

  // --- ACCIONES ---
  final VoidCallback onLogoutTap;

  const DashboardHeader({
    Key? key,
    required this.tutorName,
    this.profileImageUrl,
    required this.rating,
    this.isVerified = true,
    this.isLoadingImage = false,
    required this.isAvailable,
    required this.onLogoutTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _HeaderProfileImage(
            imageUrl: profileImageUrl,
            isLoading: isLoadingImage,
            isOnline: isAvailable,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _HeaderUserInfo(
              tutorName: tutorName,
              rating: rating,
              isVerified: isVerified,
              textColor: colorScheme.onSurface,
            ),
          ),
          _HeaderActions(
            onLogoutTap: onLogoutTap,
            iconColor: colorScheme.onSurface,
          ),
        ],
      ),
    );
  }
}

class _HeaderProfileImage extends StatelessWidget {
  final String? imageUrl;
  final bool isLoading;
  final bool isOnline;

  const _HeaderProfileImage({
    Key? key,
    required this.imageUrl,
    required this.isLoading,
    required this.isOnline,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    // ⬇️ AGREGA ESTA LÍNEA AQUÍ PARA VER QUÉ ESTÁ LLEGANDO ⬇️
    print("====== URL DE LA FOTO DEL TUTOR: $imageUrl ======");
    
    const double size = 56.0;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(18),
            // NUESTRA UI NEOCLEAN (Borde sutil)
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              width: 1.5,
            ),
            boxShadow: !isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            // TU LÓGICA ORIGINAL INTACTA
            child: isLoading
                ? Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: theme.colorScheme.primary),
                    ),
                  )
                : (imageUrl != null && imageUrl!.isNotEmpty)
                    ? CachedNetworkImage(
                        imageUrl: imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                            color: theme.colorScheme.surfaceContainerHighest),
                        errorWidget: (context, url, error) => Icon(
                          Icons.person,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    : Icon(Icons.person,
                        color: theme.colorScheme.onSurfaceVariant),
          ),
        ),

        // PUNTO DE ESTADO (ONLINE / OFFLINE)
        Positioned(
          bottom: -2,
          right: -2,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: isOnline ? const Color(0xFF00D856) : AppColors.greyColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.scaffoldBackgroundColor,
                width: 2.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderUserInfo extends StatelessWidget {
  final String tutorName;
  final double rating;
  final bool isVerified;
  final Color textColor;

  const _HeaderUserInfo({
    Key? key,
    required this.tutorName,
    required this.rating,
    required this.isVerified,
    required this.textColor,
  }) : super(key: key);

  String _getFirstName(String fullName) {
    if (fullName.isEmpty) return "Tutor";
    return fullName.trim().split(' ')[0];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final ratingCardBg = isDark ? const Color(0xFF1B3B48) : AppColors.cardDark;

    final verifiedBg = const Color(0xFF1B3B48);
    final verifiedText = Colors.white;
    final verifiedIcon = AppColors.brandCyan;

    final unverifiedBg = Color.fromRGBO(255, 255, 255, 0.1);
    
    final unverifiedText = Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. SALUDO
        Text(
          "Hola, ${_getFirstName(tutorName)}",
          style: TextStyle(
              color: textColor,
              fontSize: 24,
              fontFamily: 'outfit',
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              height: 1),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 6),

        // 2. RATING Y VERIFICACION
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: ratingCardBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded,
                      color: Color(0xFFFFC107), size: 18),
                  const SizedBox(width: 4),
                  Text(
                    rating.toStringAsFixed(1),
                    style: TextStyle(
                      color: textColor,
                      fontFamily: 'manrope',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: isVerified ? verifiedBg : unverifiedBg,
                  borderRadius: BorderRadius.circular(8),
                  border: isVerified
                      ? null
                      : Border.all(color: Colors.grey.withOpacity(0.3))),
              child: Row(
                children: [
                  Icon(
                    isVerified
                        ? Icons.verified_user_outlined
                        : Icons.hourglass_empty_rounded,
                    color: isVerified ? verifiedIcon : unverifiedText,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(isVerified ? "VERIFICADO" : "PENDIENTE",
                      style: TextStyle(
                        color: isVerified ? verifiedText : unverifiedText,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'manrope',
                        letterSpacing: 0.5,
                      ))
                ],
              ),
            )
          ],
        ),
      ],
    );
  }
}

/// Botones de acción
class _HeaderActions extends StatelessWidget {
  final VoidCallback onLogoutTap;
  final Color iconColor;

  const _HeaderActions({
    Key? key,
    required this.onLogoutTap,
    required this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const ThemeToggleButton(),
        const SizedBox(width: 8),
        _buildCircleButton(
          context,
          icon: Icons.logout_rounded,
          onTap: onLogoutTap,
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildCircleButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color finalIconColor =
        isDestructive ? const Color(0xFFFF453A) : iconColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDestructive
                ? const Color(0xFFFF453A).withOpacity(0.1) // Rojo suave
                : (isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05)),
            shape: BoxShape.circle,
            border: Border.all(
              color: isDestructive
                  ? const Color(0xFFFF453A).withOpacity(0.3)
                  : (isDark ? Colors.white10 : Colors.black12),
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: finalIconColor,
          ),
        ),
      ),
    );
  }
}
