import 'dart:io';
import 'package:http/io_client.dart';
import 'package:http/http.dart' as http;

class NetworkConfig {
  static http.Client? _httpClient;
  
  // Configurar cliente HTTP con manejo de TLS mejorado
  static http.Client get httpClient {
    _httpClient ??= _createHttpClient();
    return _httpClient!;
  }
  
  static http.Client _createHttpClient() {
    final HttpClient client = HttpClient();
    
    // Configurar timeouts
    client.connectionTimeout = Duration(seconds: 30);
    client.idleTimeout = Duration(seconds: 30);
    
    // Configurar para manejar certificados SSL
    client.badCertificateCallback = (X509Certificate cert, String host, int port) {
      print('NetworkConfig: Certificate validation failed for $host:$port');
      print('Certificate subject: ${cert.subject}');
      print('Certificate issuer: ${cert.issuer}');
      
      // Solo para desarrollo - NO usar en producción
      // En producción, el servidor debe tener certificados SSL válidos
      return true;
    };
    
    return IOClient(client);
  }
  
  // Función para probar conectividad
  static Future<bool> testConnectivity(String url) async {
    try {
      final response = await httpClient.get(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      print('NetworkConfig: Connectivity test failed: $e');
      return false;
    }
  }
  
  // Función para hacer requests con retry automático y fallback HTTP
  static Future<http.Response> makeRequestWithRetry(
    String url,
    Map<String, String> headers,
    String body, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    Exception? lastException;
    
    // Primero intentar HTTPS
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('NetworkConfig: HTTPS Attempt $attempt/$maxRetries for $url');
        
        final response = await httpClient.post(
          Uri.parse(url),
          headers: headers,
          body: body,
        );
        
        return response;
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        print('NetworkConfig: HTTPS Attempt $attempt failed: $e');
        
        if (attempt < maxRetries) {
          print('NetworkConfig: Retrying HTTPS in ${retryDelay.inSeconds} seconds...');
          await Future.delayed(retryDelay);
        }
      }
    }
    
    // Si HTTPS falla, intentar HTTP como fallback
    if (url.startsWith('https://')) {
      final httpUrl = url.replaceFirst('https://', 'http://');
      print('NetworkConfig: HTTPS failed, trying HTTP fallback: $httpUrl');
      
      try {
        final response = await http.post(
          Uri.parse(httpUrl),
          headers: headers,
          body: body,
        );
        print('NetworkConfig: HTTP fallback successful');
        return response;
      } catch (e) {
        print('NetworkConfig: HTTP fallback also failed: $e');
        lastException = e is Exception ? e : Exception(e.toString());
      }
    }
    
    throw lastException ?? Exception('All retry attempts failed');
  }
}
