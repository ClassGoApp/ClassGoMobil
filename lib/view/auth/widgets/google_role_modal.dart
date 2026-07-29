import 'package:flutter/material.dart';
import 'package:flutter_projects/l10n/app_localizations.dart';
import 'package:flutter_projects/styles/app_styles.dart';

Future<String?> showGoogleRoleSelectionDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return const _GoogleRoleDialogContent();
    },
  );
}

class _GoogleRoleDialogContent extends StatefulWidget {
  const _GoogleRoleDialogContent({Key? key}) : super(key: key);

  @override
  State<_GoogleRoleDialogContent> createState() => _GoogleRoleDialogContentState();
}

class _GoogleRoleDialogContentState extends State<_GoogleRoleDialogContent> {
  String _role = '';
  String _isChecked = '';

  bool get _isValid => _role.isNotEmpty && _isChecked == 'accepted';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: AppColors.primaryGreen,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: 32),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          l10n.signUpWithGoogle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'SF-Pro-Text',
                            fontWeight: FontWeight.w700,
                            fontSize: FontSize.scale(context, 22),
                            color: AppColors.whiteColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.authGoogleSelectRole, 
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'SF-Pro-Text',
                            fontWeight: FontWeight.w400,
                            fontSize: FontSize.scale(context, 14),
                            color: AppColors.whiteColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, color: AppColors.whiteColor.withValues(alpha: 0.7)),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: _RoleCardWidget(
                      title: l10n.student,
                      icon: Icons.school_outlined,
                      isSelected: _role == 'student',
                      onTap: () => setState(() => _role = 'student'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _RoleCardWidget(
                      title: l10n.tutor,
                      icon: Icons.desktop_windows_outlined,
                      isSelected: _role == 'tutor',
                      onTap: () => setState(() => _role = 'tutor'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _isChecked == 'accepted',
                      checkColor: AppColors.whiteColor,
                      activeColor: AppColors.lightBlueColor,
                      fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                        if (states.contains(WidgetState.selected)) {
                          return AppColors.lightBlueColor;
                        }
                        return AppColors.whiteColor;
                      }),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      side: BorderSide(
                        color: AppColors.dividerColor,
                        width: 1,
                      ),
                      onChanged: (bool? value) {
                        setState(() {
                          _isChecked = value! ? 'accepted' : '';
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        text: '${l10n.iHaveReadAndAgreeToAll} ',
                        style: TextStyle(
                          fontSize: FontSize.scale(context, 14),
                          fontFamily: 'SF-Pro-Text',
                          fontWeight: FontWeight.w400,
                          color: AppColors.whiteColor,
                          height: 1.4,
                        ),
                        children: [
                          TextSpan(
                            text: l10n.termsAndConditions,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: AppColors.lightBlueColor,
                            ),
                          ),
                          TextSpan(text: ' ${l10n.andWord} '),
                          TextSpan(
                            text: l10n.privacyPolicy,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: AppColors.lightBlueColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isValid ? () => Navigator.pop(context, _role) : () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isValid ? AppColors.whiteColor : AppColors.whiteColor.withValues(alpha: 0.3),
                  disabledBackgroundColor: AppColors.whiteColor.withValues(alpha: 0.3),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30), 
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/google_logo.png', 
                      height: 24,
                      width: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Continue with Google", 
                      style: TextStyle(
                        color: _isValid ? AppColors.primaryGreen : AppColors.primaryGreen.withOpacity(0.5),
                        fontSize: FontSize.scale(context, 16),
                        fontFamily: 'SF-Pro-Text',
                        fontWeight: FontWeight.w600,
                      ),
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
}

class _RoleCardWidget extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCardWidget({
    Key? key,
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.lightBlueColor.withOpacity(0.15) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? AppColors.lightBlueColor 
                : AppColors.dividerColor.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 42,
              color: isSelected ? AppColors.lightBlueColor : AppColors.whiteColor,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: FontSize.scale(context, 16),
                fontFamily: 'SF-Pro-Text',
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.lightBlueColor : AppColors.whiteColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}