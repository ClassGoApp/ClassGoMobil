import 'package:flutter/material.dart';
import 'package:flutter_projects/base_components/custom_snack_bar.dart';
import 'package:flutter_projects/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/api_structure/api_service.dart';

class TermsAcceptanceSection extends StatefulWidget {
  final String role; 

  const TermsAcceptanceSection({
    Key? key,
    required this.role,
  }) : super(key: key);

  @override
  State<TermsAcceptanceSection> createState() => _TermsAcceptanceSectionState();
}

class _TermsAcceptanceSectionState extends State<TermsAcceptanceSection> {
  bool _isAcceptingTerms = false;
  bool _termsChecked = false;

  Future<void> _sendAcceptTermsToBackend(String token) async {
    setState(() => _isAcceptingTerms = true);
    
    try {
      final data = await acceptTerms(token, widget.role);

      if (data['success'] == true) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.markTermsAsAccepted();

        if (mounted) {
          CustomToast.show(
            context,
            AppLocalizations.of(context)!.termsAcceptedSuccessfully,
            isSuccess: true,
          );
        }
      }
    } catch (e, stackTrace) {
      print(stackTrace);
      if (mounted) {
        CustomToast.show(
          context,
          AppLocalizations.of(context)!.errorAcceptingTerms,
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) setState(() => _isAcceptingTerms = false);
    }
  }

  Future<void> _launchTermsUrl() async {
    final url = Uri.parse('https://classgoapp.com/terminos#tutorias-instantaneas');
    if (!await launchUrl(url, mode: LaunchMode.inAppWebView)) {
      if (mounted) {
        CustomToast.show(context, AppLocalizations.of(context)!.couldNotOpenLink, isSuccess: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final token = context.read<AuthProvider>().token ?? '';
    return _buildTermsCard(isDark, token);
  }

  Widget _buildTermsCard(bool isDark, String token) {
      const Color cardBg = AppColors.brandBlue;
      const Color titleColor = Colors.white;
      final Color textColor = Colors.white.withOpacity(0.75);
      final Color accentCyan = AppColors.brandCyan;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: accentCyan.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.3) : accentCyan.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              Positioned(
                right: -40,
                top: -40,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentCyan.withOpacity(0.15),
                  ),
                  child: BackdropFilter(
                    filter: ColorFilter.mode(Colors.transparent, BlendMode.srcOver),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accentCyan.withOpacity(0.2),
                            blurRadius: 50,
                            spreadRadius: 15,
                          )
                        ]
                      ),
                    ),
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: AppLocalizations.of(context)!.instantTutoring + "\n",
                            style: const TextStyle(
                              fontFamily: 'outfit',
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: titleColor,
                              height: 1.2,
                            ),
                          ),
                          TextSpan(
                            text: AppLocalizations.of(context)!.multiplyYourClasses,
                            style: TextStyle(
                              fontFamily: 'outfit',
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: accentCyan,
                              height: 1.2,
                              shadows: [
                                Shadow(color: accentCyan.withOpacity(0.4), blurRadius: 10)
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      AppLocalizations.of(context)!.receiveTutoringRequests,
                      style: TextStyle(
                        fontFamily: 'manrope',
                        fontSize: 13,
                        color: textColor,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    GestureDetector(
                      onTap: () => setState(() => _termsChecked = !_termsChecked),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _termsChecked,
                              activeColor: accentCyan,
                              checkColor: cardBg,
                              side: const BorderSide(color: Colors.white54, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              onChanged: (val) => setState(() => _termsChecked = val ?? false),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.iHaveReadAndAccept,
                                  style: TextStyle(
                                    fontFamily: 'manrope',
                                    fontSize: 12,
                                    color: textColor,
                                  ),
                                ),
                                InkWell(
                                  onTap: _launchTermsUrl,
                                  child: Text(
                                    AppLocalizations.of(context)!.termsAndConditions,
                                    style: TextStyle(
                                      fontFamily: 'manrope',
                                      fontSize: 12,
                                      color: accentCyan,
                                      decoration: TextDecoration.underline,
                                      decorationColor: accentCyan,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          if (_termsChecked && !_isAcceptingTerms)
                            BoxShadow(
                              color: accentCyan.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            )
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: (!_termsChecked || _isAcceptingTerms) 
                            ? null 
                            : () => _sendAcceptTermsToBackend(token),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentCyan,
                          disabledBackgroundColor: Colors.white10,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                          elevation: 0,
                        ),
                        child: _isAcceptingTerms
                            ? const SizedBox(
                                width: 24, height: 24, 
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.bolt_rounded, 
                                      color: _termsChecked ? cardBg : Colors.white38, 
                                      size: 22),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppLocalizations.of(context)!.acceptAndContinue,
                                    style: TextStyle(
                                      fontFamily: 'outfit',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                      color: _termsChecked ? cardBg : Colors.white38,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
}