import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class EmailVerificationHelper {
  static const String _baseUrl = 'https://classgoapp.com/api';

  /// Reenvía el email de verificación
  static Future<Map<String, dynamic>> resendVerificationEmail(
      String email) async {
    try {
      final url = Uri.parse('$_baseUrl/resend-email');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': email,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Email reenviado exitosamente',
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al reenviar el email',
          'error': data,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message':
            'Error de conexión. Verifica tu internet e inténtalo de nuevo.',
        'error': e.toString(),
      };
    }
  }

  /// Verifica el email usando el API
  static Future<Map<String, dynamic>> verifyEmail(
      String id, String hash) async {
    try {
      final url = Uri.parse('$_baseUrl/verify-email?id=$id&hash=$hash');
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
        },
      );

      final data = json.decode(response.body);
      print('RESPUESTA API VERIFICACION: ' + response.body);

      if (response.statusCode == 200) {
        return {
          'success': data['status'] == true,
          'message': data['message'] ?? 'Email verificado exitosamente',
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al verificar el email',
          'error': data,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message':
            'Error de conexión. Verifica tu internet e inténtalo de nuevo.',
        'error': e.toString(),
      };
    }
  }

  /// Muestra un snackbar con el resultado de la operación
  static void showResultSnackBar(
      BuildContext context, Map<String, dynamic> result) {
    final backgroundColor = result['success'] ? Colors.green : Colors.red;
    final icon = result['success'] ? Icons.check_circle : Icons.error;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                result['message'],
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: 4),
      ),
    );
  }
}
