import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';
import 'google_auth_api_service.dart';

class GoogleAuthService {
  // Usa el OAuth Client ID de tipo Web (del backend) para solicitar serverAuthCode
  static const String _webClientId =
      '777182771573-flpn0oct89s8avhdke1fdqmh6l48lccv.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
    serverClientId: _webClientId,
  );

  final GoogleAuthApiService _apiService = GoogleAuthApiService.instance;

  // Método 1: Usando Google Sign-In nativo (Recomendado)
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // Forzar logout primero para asegurar que se muestre la ventana de selección
      await _googleSignIn.signOut();
      
      // Esperar un momento para que se complete el logout
      await Future.delayed(Duration(milliseconds: 500));
      
      print('DEBUG - Iniciando Google Sign-In...');
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      
      if (account == null) {
        throw Exception('Usuario canceló el login');
      }

      print('DEBUG - Usuario seleccionado: ${account.email}');
      
      // Solicitar el código de autorización para intercambio en el backend
      final String? authCode = account.serverAuthCode;

      if (authCode == null) {
        throw Exception('No se pudo obtener el código de autorización (serverAuthCode)');
      }

      print('DEBUG - Enviando authCode al backend...');
      // Enviar code al backend (mismo flujo que en web)
      final response = await _apiService.handleGoogleCallback(authCode);
      
      print('DEBUG - Respuesta del backend: ${response['success']}');
      
      return response;
    } catch (e) {
      print('DEBUG - Error en Google Sign-In: $e');
      throw Exception('Error en Google Sign-In: $e');
    }
  }

  // Método 2: Usando URL personalizada (Para casos específicos)
  Future<Map<String, dynamic>> signInWithCustomUrl() async {
    try {
      // Obtener URL del backend
      final urlResponse = await _apiService.getGoogleAuthUrl();
      
      if (!urlResponse['success']) {
        throw Exception(urlResponse['message']);
      }

      final String authUrl = urlResponse['auth_url'];
      
      // Abrir URL en navegador
      if (await canLaunchUrl(Uri.parse(authUrl))) {
        await launchUrl(Uri.parse(authUrl), mode: LaunchMode.externalApplication);
      } else {
        throw Exception('No se puede abrir la URL de autenticación');
      }

      // Aquí necesitarías implementar un callback handler
      // para capturar el código de autorización
      
      return {'success': true, 'message': 'URL abierta'};
    } catch (e) {
      throw Exception('Error en autenticación personalizada: $e');
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _apiService.clearToken();
  }

  // Verificar si el usuario está autenticado
  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  // Obtener usuario actual
  Future<GoogleSignInAccount?> getCurrentUser() async {
    return _googleSignIn.currentUser;
  }
}
