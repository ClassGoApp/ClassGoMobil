import 'package:flutter/material.dart';
import 'package:flutter_projects/base_components/custom_snack_bar.dart';
import 'package:flutter_projects/base_components/confirm_dialog.dart';
import 'package:flutter_projects/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/styles/app_styles.dart';

const String _kTitleFont = 'outfit';
const String _kBodyFont = 'manrope';

class LogoutSection extends StatelessWidget {
  const LogoutSection({Key? key}) : super(key: key);

  static void executeLogout(BuildContext context) {
    Provider.of<AuthProvider>(context, listen: false).logout();

    CustomToast.show(context, AppLocalizations.of(context)!.logoutSuccess, isSuccess: true);
  }

  static void showLogoutDialog(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      icon: Icons.logout_rounded,
      iconColor: Colors.redAccent,
      title: AppLocalizations.of(context)!.logoutTitle,
      message: AppLocalizations.of(context)!.logoutConfirmMessage,
      cancelLabel: AppLocalizations.of(context)!.cancelButton,
      confirmLabel: AppLocalizations.of(context)!.logoutButton,
      confirmColor: Colors.redAccent,
    );
    if (confirmed == true) {
      executeLogout(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          child: const Icon(Icons.power_settings_new_rounded,
              color: Colors.redAccent, size: 20),
        ),
        title: Text(
          AppLocalizations.of(context)!.logoutTitle,
          style: const TextStyle(
            fontFamily: _kTitleFont,
            color: Colors.redAccent,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: Colors.redAccent.withOpacity(0.5)),
        onTap: () => LogoutSection.showLogoutDialog(context),
      ),
    );
  }
}