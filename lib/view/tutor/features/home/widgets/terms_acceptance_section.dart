import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/api_structure/api_service.dart';

class TermsAcceptanceSection extends StatefulWidget {
  final String role; // 'tutor' o 'student'

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
      // Llamamos a la API enviando el token y el rol
      final data = await acceptTerms(token, widget.role);

      if (data['success'] == true) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        
        // Actualizamos localmente el estado del provider
        if (authProvider.userData?['user'] != null) {
          authProvider.userData!['user']['terms_accepted_at'] = DateTime.now().toIso8601String();
          authProvider.notifyListeners(); 
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Términos aceptados correctamente"), 
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll("Exception: ", "")), 
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isAcceptingTerms = false);
    }
  }

  Future<void> _launchTermsUrl() async {
    final url = Uri.parse('https://classgoapp.com/terminos#tutorias-instantaneas');
    if (!await launchUrl(url, mode: LaunchMode.inAppWebView)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo abrir el enlace")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();
    final token = authProvider.token ?? '';
    
    final termsAcceptedAt = authProvider.userData?['user']?['terms_accepted_at'];
    final hasAcceptedTerms = termsAcceptedAt != null && termsAcceptedAt.toString().isNotEmpty;

    if (authProvider.userData?['user'] != null) {
      print("=== VERIFICACIÓN MÓVIL ===");
      print("TERMS_ACCEPTED_AT: $termsAcceptedAt");
      print("HAS_ACCEPTED: $hasAcceptedTerms");
      print("==========================");
    }

    if (hasAcceptedTerms) {
      return _buildTermsAcceptedFooter(isDark);
    } else {
      return _buildTermsCard(isDark, token);
    }
  }

  Widget _buildTermsCard(bool isDark, String token) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151A24) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.brandCyan.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandCyan.withOpacity(isDark ? 0.05 : 0.02),
            blurRadius: 15, offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.brandCyan.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.gavel_rounded, color: AppColors.brandCyan, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Términos y Condiciones",
                  style: TextStyle(
                    fontFamily: 'outfit',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.brandBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.role == 'tutor' 
                ? "Para activar el radar, recibir alertas push de alumnos y postularte a clases al instante, es necesario aceptar los términos regulatorios de tutorías."
                : "Para buscar tutores disponibles al instante, es necesario aceptar nuestros términos de servicio y condiciones.",
            style: TextStyle(
              fontFamily: 'manrope',
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          
          GestureDetector(
            onTap: () => setState(() => _termsChecked = !_termsChecked),
            child: Row(
              children: [
                Checkbox(
                  value: _termsChecked,
                  activeColor: AppColors.brandCyan,
                  checkColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  onChanged: (val) => setState(() => _termsChecked = val ?? false),
                ),
                Expanded(
                  child: InkWell(
                    onTap: _launchTermsUrl,
                    child: const Text(
                      "Acepto los términos y condiciones de uso",
                      style: TextStyle(
                        fontFamily: 'manrope',
                        fontSize: 13,
                        color: AppColors.brandCyan,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: (!_termsChecked || _isAcceptingTerms) 
                  ? null 
                  : () => _sendAcceptTermsToBackend(token),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandCyan,
                disabledBackgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isAcceptingTerms
                  ? const SizedBox(
                      width: 20, height: 20, 
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : Text(
                      "ACEPTAR Y CONTINUAR",
                      style: TextStyle(
                        fontFamily: 'outfit',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _termsChecked ? Colors.black : Colors.grey[500],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsAcceptedFooter(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: InkWell(
          onTap: _launchTermsUrl,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline_rounded, size: 14, color: Colors.green[400]),
              const SizedBox(width: 6),
              Text(
                "Condiciones de Tutoría Aceptadas. Ver documento.",
                style: TextStyle(
                  fontFamily: 'manrope',
                  fontSize: 11,
                  color: isDark ? Colors.white38 : Colors.grey[500],
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
