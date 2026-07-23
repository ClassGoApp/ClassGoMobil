import 'package:flutter/material.dart';
import 'package:flutter_projects/provider/locale_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/l10n/app_localizations.dart';

class LanguageSelectorButton extends StatelessWidget {
  const LanguageSelectorButton({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = localeProvider.locale?.languageCode ?? 'es';

    return ListTile(
      title: Text(
        l10n.language,
        style: const TextStyle(
          fontFamily: 'SF-Pro-Text',
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        currentLocale == 'es' ? l10n.spanish : l10n.english,
        style: TextStyle(color: AppColors.greyColor),
      ),
      trailing: const Icon(Icons.language),
      onTap: () {
        _showLanguageBottomSheet(context);
      },
    );
  }

  void _showLanguageBottomSheet(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = localeProvider.locale?.languageCode ?? 'es';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.sheetBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.selectLanguage,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'SF-Pro-Text',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _LanguageOptionTile(
              languageName: l10n.spanish,
              languageCode: 'es',
              isSelected: currentLocale == 'es',
              onTap: () {
                localeProvider.setLocale(const Locale('es'));
                Navigator.pop(context);
              },
            ),
            const Divider(),
            _LanguageOptionTile(
              languageName: l10n.english,
              languageCode: 'en',
              isSelected: currentLocale == 'en',
              onTap: () {
                localeProvider.setLocale(const Locale('en'));
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _LanguageOptionTile extends StatelessWidget {
  final String languageName;
  final String languageCode;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOptionTile({
    required this.languageName,
    required this.languageCode,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        languageName,
        style: const TextStyle(fontFamily: 'SF-Pro-Text'),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: AppColors.primaryGreen)
          : const Icon(Icons.radio_button_unchecked),
      onTap: onTap,
    );
  }
}