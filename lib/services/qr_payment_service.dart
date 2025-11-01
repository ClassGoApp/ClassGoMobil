import 'dart:io';
import 'package:dio/dio.dart';

class QrPaymentService {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://classgoapp.com/api',
    connectTimeout: Duration(seconds: 30),
    receiveTimeout: Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  /// Obtener métodos de pago QR del usuario
  static Future<Map<String, dynamic>> getQrPaymentMethods(int userId) async {
    try {
      final response = await _dio.get('/qr-payout-methods/$userId');
      return response.data;
    } catch (e) {
      throw Exception('Error al obtener métodos de pago QR: $e');
    }
  }

  /// Agregar nuevo método de pago QR
  static Future<Map<String, dynamic>> addQrPaymentMethod({
    required int userId,
    required File imageFile,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'user_id': userId,
        'img_qr': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });

      final response = await _dio.post(
        '/qr-payout-methods',
        data: formData,
      );
      return response.data;
    } catch (e) {
      throw Exception('Error al agregar método de pago QR: $e');
    }
  }

  /// Actualizar método de pago QR existente
  static Future<Map<String, dynamic>> updateQrPaymentMethod({
    required int userId,
    required File imageFile,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'img_qr': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });

      final response = await _dio.post(
        '/qr-payout-methods/$userId/update',
        data: formData,
      );
      return response.data;
    } catch (e) {
      throw Exception('Error al actualizar método de pago QR: $e');
    }
  }

  /// Eliminar método de pago QR
  static Future<Map<String, dynamic>> deleteQrPaymentMethod(int userId) async {
    try {
      final response = await _dio.delete('/qr-payout-methods/$userId');
      return response.data;
    } catch (e) {
      throw Exception('Error al eliminar método de pago QR: $e');
    }
  }
}
