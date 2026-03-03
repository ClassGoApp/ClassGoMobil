import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api_structure/api_service.dart';
import '../../provider/auth_provider.dart';
import '../../styles/app_styles.dart';
import 'register_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  const VerifyEmailScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isLoading = false;
  String? _feedback;

  Future<void> _resendEmail() async {
    setState(() {
      _isLoading = true;
      _feedback = null;
    });
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      if (token == null) {
        setState(() {
          _feedback = 'No se pudo obtener el token de usuario.';
          _isLoading = false;
        });
        return;
      }
      final response = await resendEmail(token);
      setState(() {
        _feedback = response['message'] ?? 'Correo reenviado.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _feedback = 'Error al reenviar el correo: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBlue,
      appBar: AppBar(
        backgroundColor: AppColors.darkBlue,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.email_outlined,
                  color: AppColors.orangeprimary, size: 64),
              SizedBox(height: 24),
              Text(
                '¡Verifica tu correo!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'Te hemos enviado un correo de verificación a:',
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                widget.email,
                style: TextStyle(
                    color: AppColors.lightBlueColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              _isLoading
                  ? CircularProgressIndicator(color: AppColors.orangeprimary)
                  : ElevatedButton.icon(
                      onPressed: _resendEmail,
                      icon: Icon(Icons.refresh, color: Colors.white),
                      label: Text('Reenviar correo de verificación'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orangeprimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding:
                            EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        textStyle: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
              if (_feedback != null) ...[
                SizedBox(height: 18),
                Text(
                  _feedback!,
                  style: TextStyle(color: Colors.white, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
              ],
              SizedBox(height: 32),
              Text(
                'Revisa tu bandeja de entrada y haz clic en el enlace para activar tu cuenta.',
                style: TextStyle(color: Colors.white60, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RegistrationScreen(),
                    ),
                  );
                },
                icon: Icon(Icons.arrow_back, color: Colors.white),
                label: Text('Volver al registro'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lightBlueColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  textStyle: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
