import 'package:flutter/material.dart';
import 'package:flutter_projects/base_components/custom_snack_bar.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'banner_card.dart';

class BannerTermsSection extends StatefulWidget {
  final String role;

  const BannerTermsSection({
    super.key,
    required this.role,
  });

  @override
  State<BannerTermsSection> createState() => _BannerTermsSectionState();
}

class _BannerTermsSectionState extends State<BannerTermsSection> {
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
            "¡Términos aceptados correctamente!",
            isSuccess: true,
          );
        }
      }
    } catch (e, stackTrace) {
      print(stackTrace);
      if (mounted) {
        CustomToast.show(
          context,
          "Error al aceptar los términos. Intenta nuevamente.",
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) setState(() => _isAcceptingTerms = false);
    }
  }

  Future<void> _launchTermsUrl() async {
    final url = Uri.parse(
        'https://classgoapp.com/terminos#tutorias-instantaneas');
    if (!await launchUrl(url, mode: LaunchMode.inAppWebView)) {
      if (mounted) {
        CustomToast.show(
            context, "No se pudo abrir el enlace", isSuccess: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final token = context.read<AuthProvider>().token ?? '';
    return _buildBanner(token);
  }

  Widget _buildBanner(String token) {
    const Color cardBg = AppColors.brandBlue;
    final Color accentCyan = AppColors.brandCyan;

    final isTutor = widget.role == 'tutor';
    final description = isTutor
        ? 'Recibe solicitudes de estudiantes en tiempo real para empezar a enseñar.'
        : 'Solicita tutorías en tiempo real y conecta con tutores al instante.';

    return BannerCard(
      gradientColors: [cardBg, cardBg],
      height: 290,
      circleColor: accentCyan.withOpacity(0.15),
      title: Text(
        'Tutorías al instante',
        style: const TextStyle(
          fontFamily: 'outfit',
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          height: 1.2,
        ),
      ),
      description: description,
      descriptionMaxLines: 2,
      extraContent: _buildCheckboxRow(accentCyan, cardBg),
      button: _buildAcceptButton(accentCyan, cardBg, token),
    );
  }

  Widget _buildCheckboxRow(Color accentCyan, Color cardBg) {
    return GestureDetector(
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              onChanged: (val) =>
                  setState(() => _termsChecked = val ?? false),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  "He leído y acepto los ",
                  style: const TextStyle(
                    fontFamily: 'manrope',
                    fontSize: 12,
                    color: AppColors.textLightSecondary,
                  ),
                ),
                InkWell(
                  onTap: _launchTermsUrl,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: accentCyan.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "términos y condiciones",
                          style: TextStyle(
                            fontFamily: 'manrope',
                            fontSize: 12,
                            color: accentCyan,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.open_in_new_rounded,
                            size: 12, color: accentCyan),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptButton(Color accentCyan, Color cardBg, String token) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          if (_termsChecked && !_isAcceptingTerms)
            BoxShadow(
              color: accentCyan.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: ElevatedButton(
        onPressed: (!_termsChecked || _isAcceptingTerms)
            ? null
            : () => _sendAcceptTermsToBackend(token),
        style: ElevatedButton.styleFrom(
          backgroundColor: accentCyan,
          disabledBackgroundColor: Colors.white10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          elevation: 0,
        ),
        child: _isAcceptingTerms
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bolt_rounded,
                      color: _termsChecked ? cardBg : Colors.white38,
                      size: 22),
                  const SizedBox(width: 8),
                  Text(
                    "ACEPTAR Y CONTINUAR",
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
    );
  }
}
