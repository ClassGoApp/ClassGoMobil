import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'dart:io';
import 'dart:io' show File;
import 'package:path/path.dart' as path;

final String baseUrl = 'https://classgoapp.com/api';

Future<Map<String, dynamic>> registerUser(Map<String, dynamic> userData) async {
  try {
    print('Iniciando registro de usuario con datos: $userData');
    print('URL de registro: $baseUrl/register');
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(userData),
    );

    print('Respuesta del servidor - Status: ${response.statusCode}');
    print('Respuesta del servidor - Body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      print('Registro exitoso: $responseData');
      return responseData;
    } else if (response.statusCode == 422) {
      try {
        final responseData = jsonDecode(response.body);
        String errorMessage;
        if (responseData.containsKey('message')) {
          errorMessage = responseData['message'];
        } else if (responseData.containsKey('errors')) {
          errorMessage = responseData['errors']
              .values
              .expand((messages) => messages)
              .join(', ');
        } else {
          errorMessage = 'Validation error occurred';
        }

        print('Error de validación: $errorMessage');
        throw {
          'message': errorMessage,
          'status': response.statusCode,
        };
      } catch (e) {
        print('Error al parsear respuesta de validación: $e');
        throw {
          'message':
              'Validation error occurred, but the response could not be parsed.',
          'status': response.statusCode,
        };
      }
    } else {
      if (response.headers['content-type']?.contains('application/json') ??
          false) {
        final responseData = jsonDecode(response.body);
        print('Error del servidor: $responseData');
        throw {
          'message': responseData['message'] ??
              'An error occurred during registration',
          'status': response.statusCode,
        };
      } else {
        print('Respuesta no JSON del servidor: ${response.body}');
        throw {
          'message':
              'An unexpected response was received from the server. Please try again later.',
          'status': response.statusCode,
        };
      }
    }
  } catch (e) {
    print('Error en registerUser: $e');
    print('Tipo de error: ${e.runtimeType}');

    if (e is Map<String, dynamic> && e.containsKey('message')) {
      print('Error estructurado: $e');
      throw e;
    } else if (e.toString().contains('HandshakeException')) {
      print('Error de SSL/TLS detectado');
      throw {
        'message': 'Error de conexión segura. Verifica tu conexión a internet.',
        'status': 0
      };
    } else if (e.toString().contains('SocketException')) {
      print('Error de conexión detectado');
      throw {
        'message':
            'No se pudo conectar al servidor. Verifica tu conexión a internet.',
        'status': 0
      };
    } else {
      print('Error inesperado: $e');
      throw {
        'message':
            'An unexpected error occurred during registration: ${e.toString()}'
      };
    }
  }
}

Future<Map<String, dynamic>> loginUser(String email, String password) async {
  final uri = Uri.parse('$baseUrl/login');
  final headers = <String, String>{
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  final body = json.encode({
    'email': email,
    'password': password,
  });

  final response = await http.post(
    uri,
    headers: headers,
    body: body,
  );

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    final error = json.decode(response.body);
    throw Exception(error['message'] ?? 'Failed to login');
  }
}

Future<Map<String, dynamic>> forgetPassword(String email) async {
  final uri = Uri.parse('$baseUrl/forget-password');
  final headers = <String, String>{
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  final body = json.encode({
    'email': email,
  });

  final response = await http.post(
    uri,
    headers: headers,
    body: body,
  );

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    final error = json.decode(response.body);
    throw Exception(error['message'] ?? 'Failed to login');
  }
}

Future<Map<String, dynamic>> resendEmail(String token) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/resend-email');
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.get(
      uri,
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to resend email');
    }
  } catch (e) {
    throw 'Failed to resend email: $e';
  }
}

Future<Map<String, dynamic>> logout(String token) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/logout');
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.post(
      uri,
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to resend email');
    }
  } catch (e) {
    throw 'Failed to resend email: $e';
  }
}

Future<Map<String, dynamic>> updatePassword(
    Map<String, dynamic> userData, String token, int id) async {
  final uri = Uri.parse('$baseUrl/update-password/$id');
  final headers = <String, String>{
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  final response = await http.post(
    uri,
    headers: headers,
    body: json.encode(userData),
  );

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Failed to update password');
  }
}

Future<Map<String, dynamic>> findTutors(
  String? token, {
  int page = 1,
  int perPage = 10,
  String? keyword,
  int? subjectId,
  double? maxPrice,
  int? country,
  int? groupId,
  String? sessionType,
  List<int>? languageIds,
}) async {
  try {
    final Map<String, dynamic> queryParams = {
      'page': page.toString(),
      'per_page': perPage.toString(),
      'keyword': keyword,
      'subject_id': subjectId?.toString(),
      'max_price': maxPrice?.toString(),
      'country': country?.toString(),
      'group_id': groupId?.toString(),
      'session_type': sessionType,
      'language_id': languageIds != null ? languageIds.join(',') : null,
    };

    queryParams.removeWhere((key, value) => value == null);

    final Uri uri =
        Uri.parse('$baseUrl/find-tutors').replace(queryParameters: queryParams);

    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ??
          'Error al obtener tutores: ${response.statusCode}');
    }
  } catch (e) {
    throw 'Error al obtener tutores: $e';
  }
}

Future<Map<String, dynamic>> getVerifiedTutors(
  String? token, {
  int page = 1,
  int perPage = 10,
  String? keyword,
  String? tutorName,
  int? subjectId,
  int? groupId,
  double? maxPrice,
  int? country,
  String? sessionType,
  List<int>? languageIds,
  int? minCourses,
  double? minRating,
  bool instant = false,
}) async {
  try {
    final Map<String, dynamic> queryParams = {
      'page': page.toString(),
      'per_page': perPage.toString(),
      'keyword': keyword,
      'tutor_name': tutorName,
      'subject_id': subjectId?.toString(),
      'group_id': groupId?.toString(),
      'max_price': maxPrice?.toString(),
      'country': country?.toString(),
      'session_type': sessionType,
      'language_id': languageIds != null ? languageIds.join(',') : null,
      'min_courses': minCourses?.toString(),
      'min_rating': minRating?.toString(),
    };
    if (instant) {
      queryParams['instant'] = 'true';
    }
    queryParams.removeWhere((key, value) => value == null);

    final Uri uri = Uri.parse('$baseUrl/verified-tutors')
        .replace(queryParameters: queryParams);

    // Log de depuración
    print('DEBUG - API URL: $uri');
    print('DEBUG - Query params: $queryParams');

    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(uri, headers: headers);

    print('DEBUG - Response status: ${response.statusCode}');
    if (response.statusCode != 200) {
      print('DEBUG - Error response body: ${response.body}');
    }

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('DEBUG - Response data keys: ${responseData.keys.toList()}');
      if (responseData.containsKey('data')) {
        print('DEBUG - Data keys: ${responseData['data'].keys.toList()}');
      }
      return responseData;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ??
          'Error al obtener tutores verificados: ${response.statusCode}');
    }
  } catch (e) {
    throw 'Error al obtener tutores verificados: $e';
  }
}

Future<Map<String, dynamic>> getAvailableTutors(
  String? token, {
  int page = 1,
  int perPage = 10,
  String? keyword,
  String? tutorName,
  int? subjectId,
  int? groupId,
  double? maxPrice,
  int? country,
  String? sessionType,
  List<int>? languageIds,
  int? minCourses,
  double? minRating,
}) async {
  try {
    final Map<String, dynamic> queryParams = {
      'page': page.toString(),
      'per_page': perPage.toString(),
      'keyword': keyword,
      'tutor_name': tutorName,
      'subject_id': subjectId?.toString(),
      'group_id': groupId?.toString(),
      'max_price': maxPrice?.toString(),
      'country': country?.toString(),
      'session_type': sessionType,
      'language_id': languageIds != null ? languageIds.join(',') : null,
      'min_courses': minCourses?.toString(),
      'min_rating': minRating?.toString(),
    };

    queryParams.removeWhere((key, value) => value == null);

    final Uri uri = Uri.parse('$baseUrl/available-tutors')
        .replace(queryParameters: queryParams);

    // Log de depuración
    print('DEBUG - Available Tutors API URL: $uri');
    print('DEBUG - Available Tutors Query params: $queryParams');

    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(uri, headers: headers);

    print('DEBUG - Available Tutors Response status: ${response.statusCode}');
    if (response.statusCode != 200) {
      print('DEBUG - Available Tutors Error response body: ${response.body}');
    }

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('DEBUG - Available Tutors Response data keys: ${responseData.keys.toList()}');
      if (responseData.containsKey('data')) {
        print('DEBUG - Available Tutors Data keys: ${responseData['data'].keys.toList()}');
      }
      return responseData;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ??
          'Error al obtener tutores disponibles: ${response.statusCode}');
    }
  } catch (e) {
    throw 'Error al obtener tutores disponibles: $e';
  }
}

Future<Map<String, dynamic>> getTutors(String? token, String slug) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/tutor/$slug');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get tutors');
    }
  } catch (e) {
    throw 'Failed to get tutors $e';
  }
}

Future<Map<String, dynamic>> getTutorsEducation(String? token, int id) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/tutor-education/$id');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get education');
    }
  } catch (e) {
    throw 'Failed to get education $e';
  }
}

Future<Map<String, dynamic>> getTutorsExperience(String? token, int id) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/tutor-experience/$id');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get experience');
    }
  } catch (e) {
    throw 'Failed to get experience $e';
  }
}

Future<Map<String, dynamic>> getTutorsCertification(
    String? token, int id) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/tutor-certification/$id');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get certification');
    }
  } catch (e) {
    throw 'Failed to get certification $e';
  }
}

Future<Map<String, dynamic>> addEducation(
    String token, Map<String, dynamic> data) async {
  final Uri uri = Uri.parse('$baseUrl/tutor-education');
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  try {
    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(data),
    );

    final decodedResponse = json.decode(response.body);

    if (response.statusCode == 200) {
      return decodedResponse;
    } else {
      return {
        'status': response.statusCode,
        'message': decodedResponse['message'] ?? 'Failed to add education',
        'errors': decodedResponse['errors'],
      };
    }
  } catch (e) {
    return {'status': 500, 'message': 'Failed to add education'};
  }
}

Future<Map<String, dynamic>> getCountries(String? token) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/countries');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get countries');
    }
  } catch (e) {
    throw 'Failed to get countries $e';
  }
}

Future<Map<String, dynamic>> getLanguages(String? token) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/languages');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get languages');
    }
  } catch (e) {
    throw 'Failed to get languages $e';
  }
}

Future<Map<String, dynamic>> getSubjects(String? token) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/subjects');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get subjects');
    }
  } catch (e) {
    throw 'Failed to get subjects $e';
  }
}

Future<Map<String, dynamic>> getSubjectsGroup(String? token) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/subject-groups');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get subjects group');
    }
  } catch (e) {
    throw 'Failed to get subjects group $e';
  }
}

Future<Map<String, dynamic>> getCountryStates(
    String? token, int countryId) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/country-states').replace(
      queryParameters: {
        'country_id': countryId.toString(),
      },
    );
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get country states');
    }
  } catch (e) {
    throw 'Failed to get country states $e';
  }
}

Future<Map<String, dynamic>> deleteEducation(String token, int id) async {
  final url = Uri.parse('$baseUrl/tutor-education/$id');

  try {
    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {
        'status': response.statusCode,
        'message': 'Failed to delete education: ${response.reasonPhrase}',
      };
    }
  } catch (error) {
    return {
      'status': 500,
      'message': 'Error occurred: $error',
    };
  }
}

Future<Map<String, dynamic>> updateEducation(
    String token, int id, Map<String, dynamic> educationData) async {
  final url = Uri.parse('$baseUrl/tutor-education/$id');
  try {
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(educationData),
    );

    final decodedResponse = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return decodedResponse;
    } else {
      return {
        'status': response.statusCode,
        'message': decodedResponse['message'] ?? 'Failed to update education',
        'errors': decodedResponse['errors'],
      };
    }
  } catch (error) {
    return {
      'status': 500,
      'message': 'Error occurred: $error',
    };
  }
}

Future<Map<String, dynamic>> addExperience(
    String token, Map<String, dynamic> data) async {
  final Uri uri = Uri.parse('$baseUrl/tutor-experience');
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  try {
    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(data),
    );

    final decodedResponse = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return decodedResponse;
    } else {
      final error = decodedResponse;
      return {
        'status': response.statusCode,
        'message': error['message'] ?? 'Failed to add experience',
        'errors': error['errors'] ?? {},
      };
    }
  } catch (e) {
    return {'status': 500, 'message': 'Failed to add experience'};
  }
}

Future<Map<String, dynamic>> deleteExperience(String token, int id) async {
  final url = Uri.parse('$baseUrl/tutor-experience/$id');

  try {
    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {
        'status': response.statusCode,
        'message': 'Failed to delete experience: ${response.reasonPhrase}',
      };
    }
  } catch (error) {
    return {
      'status': 500,
      'message': 'Error occurred: $error',
    };
  }
}

Future<Map<String, dynamic>> updateExperience(
    String token, int id, Map<String, dynamic> experienceData) async {
  final url = Uri.parse('$baseUrl/tutor-experience/$id');

  try {
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(experienceData),
    );

    final decodedResponse = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return decodedResponse;
    } else {
      final error = decodedResponse;
      return {
        'status': response.statusCode,
        'message': error['message'] ?? 'Failed to update experience',
        'errors': error['errors'] ?? {},
      };
    }
  } catch (error) {
    return {
      'status': 500,
      'message': 'Error occurred: $error',
    };
  }
}

Future<Map<String, dynamic>> addCertification(
    String token, Map<String, dynamic> data) async {
  final Uri uri = Uri.parse('$baseUrl/tutor-certification');
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  try {
    var request = http.MultipartRequest('POST', uri)
      ..headers.addAll(headers)
      ..fields['title'] = data['title']
      ..fields['institute_name'] = data['institute_name']
      ..fields['issue_date'] = data['issue_date']
      ..fields['expiry_date'] = data['expiry_date']
      ..fields['description'] = data['description'];

    if (data['image'] != null && data['image']!.isNotEmpty) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          data['image']!,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    final decodedResponse = jsonDecode(responseBody);

    if (response.statusCode == 200) {
      return decodedResponse;
    } else {
      final error = decodedResponse;
      return {
        'status': response.statusCode,
        'message': error['message'] ?? 'Failed to add certification',
        'errors': error['errors'] ?? {},
      };
    }
  } catch (e) {
    return {'status': 500, 'message': 'Failed to add certification'};
  }
}

Future<Map<String, dynamic>> deleteCertification(String token, int id) async {
  final url = Uri.parse('$baseUrl/tutor-certification/$id');

  try {
    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {
        'status': response.statusCode,
        'message': 'Failed to delete certification: ${response.reasonPhrase}',
      };
    }
  } catch (error) {
    return {
      'status': 500,
      'message': 'Error occurred: $error',
    };
  }
}

Future<Map<String, dynamic>> updateCertification(
    String token, int id, Map<String, dynamic> certificationData) async {
  final Uri uri = Uri.parse('$baseUrl/tutor-certification/$id');
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  try {
    var request = http.MultipartRequest('POST', uri)
      ..headers.addAll(headers)
      ..fields['title'] = certificationData['title']
      ..fields['institute_name'] = certificationData['institute_name']
      ..fields['issue_date'] = certificationData['issue_date']
      ..fields['expiry_date'] = certificationData['expiry_date']
      ..fields['description'] = certificationData['description'];

    if (certificationData['image'] != null &&
        certificationData['image']!.isNotEmpty) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          certificationData['image']!,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return json.decode(responseBody);
    } else {
      final error = json.decode(responseBody);
      return {
        'status': response.statusCode,
        'message': error['message'] ?? 'Failed to update certification'
      };
    }
  } catch (error) {
    return {
      'status': 500,
      'message': 'Error occurred: $error',
    };
  }
}

Future<Map<String, dynamic>> getProfile(String token, int id) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/profile-settings/$id');
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get profile settings');
    }
  } catch (e) {
    throw 'Failed to get profile settings $e';
  }
}

Future<Map<String, dynamic>> updateProfile(
    String token, int id, Map<String, dynamic> data) async {
  final Uri uri = Uri.parse('$baseUrl/profile-settings/$id');
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  var request = http.MultipartRequest('POST', uri)
    ..headers.addAll(headers)
    ..fields['first_name'] = data['first_name']
    ..fields['last_name'] = data['last_name']
    ..fields['gender'] = data['gender']
    ..fields['native_language'] = data['native_language']
    ..fields['description'] = data['description']
    ..fields['tagline'] = data['tagline']
    ..fields['country'] = data['country']
    ..fields['state'] = data['state']
    ..fields['city'] = data['city']
    ..fields['zipcode'] = data['zipcode']
    ..fields['email'] = data['email']
    ..fields['recommend_tutor'] = data['recommend_tutor'];

  if (data['user_languages'] != null) {
    for (int i = 0; i < data['user_languages'].length; i++) {
      request.fields['user_languages[$i]'] = data['user_languages'][i];
    }
  }

  if (data['image'] != null && data['image'].isNotEmpty) {
    File imageFile = File(data['image']);
    String mimeType =
        lookupMimeType(imageFile.path) ?? 'application/octet-stream';
    var mimeTypeData = mimeType.split('/');

    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType(mimeTypeData[0], mimeTypeData[1]),
      ),
    );
  }

  if (data['intro_video'] != null && data['intro_video'].isNotEmpty) {
    File videoFile = File(data['intro_video']);
    String mimeType =
        lookupMimeType(videoFile.path) ?? 'application/octet-stream';
    var mimeTypeData = mimeType.split('/');

    request.files.add(
      await http.MultipartFile.fromPath(
        'intro_video',
        videoFile.path,
        contentType: MediaType(mimeTypeData[0], mimeTypeData[1]),
      ),
    );
  }

  var streamedResponse = await request.send();
  var response = await http.Response.fromStream(streamedResponse);
  return jsonDecode(response.body) as Map<String, dynamic>;
}

Future<Map<String, dynamic>> getMyEarnings(String token, int id) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/my-earning/$id');
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get earning');
    }
  } catch (e) {
    throw 'Failed to get earning $e';
  }
}

Future<Map<String, dynamic>> getPayouts(String token, int id) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/tutor-payouts/$id');
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get payouts');
    }
  } catch (e) {
    throw 'Failed to get payouts $e';
  }
}

Future<Map<String, dynamic>> getPayoutStatus(String token) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/payout-status');
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get earning');
    }
  } catch (e) {
    throw 'Failed to get earning $e';
  }
}

Future<Map<String, dynamic>> payoutMethod(
    String token, Map<String, dynamic> data) async {
  final Uri uri = Uri.parse('$baseUrl/payout-method');
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  try {
    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      return {
        'status': response.statusCode,
        'message': error['message'] ?? 'Failed to add payout method'
      };
    }
  } catch (e) {
    return {'status': 500, 'message': 'Failed to add payout method'};
  }
}

Future<Map<String, dynamic>> deletePayoutMethod(
    String token, String method) async {
  final Uri url = Uri.parse('$baseUrl/payout-method');
  final Map<String, String> headers = {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  try {
    final response = await http.delete(
      url,
      headers: headers,
      body: jsonEncode({'current_method': method}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {
        'status': response.statusCode,
        'message': 'Failed to delete payout method: ${response.reasonPhrase}',
      };
    }
  } catch (error) {
    return {
      'status': 500,
      'message': 'Error occurred: $error',
    };
  }
}

Future<Map<String, dynamic>> userWithdrawal(
    String token, Map<String, dynamic> data) async {
  final Uri uri = Uri.parse('$baseUrl/user-withdrawal');
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  try {
    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      return {
        'status': response.statusCode,
        'message': error['message'] ?? 'Failed to add withdrawal',
        'errors': error['errors'] ?? {},
      };
    }
  } catch (e) {
    return {'status': 500, 'message': 'Failed to add withdrawal', 'errors': {}};
  }
}

Future<Map<String, dynamic>> getBookings(
    String token, String startDate, String endDate) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/upcoming-bookings').replace(
      queryParameters: {
        'show_by': 'daily',
        'start_date': startDate,
        'end_date': endDate,
        'type': '',
      },
    );

    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load bookings');
    }
  } catch (e) {
    throw 'Error fetching bookings: $e';
  }
}

Future<Map<String, dynamic>> getInvoices(String token) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/invoices');
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get invoices');
    }
  } catch (e) {
    throw 'Failed to get invoices $e';
  }
}

Future<Map<String, dynamic>> getTutorAvailableSlots(
    String token, String userId) async {
  // ✅ CAMBIO: Usar el endpoint correcto para obtener slots del tutor
  final Uri uri = Uri.parse('$baseUrl/tutor/$userId/available-slots');
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  try {
    final response = await http.get(
      uri,
      headers: headers,
    );

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);

      // Si la respuesta es una lista, convertirla a un Map con estructura estándar
      if (decodedBody is List) {
        return {
          'status': 200,
          'data': decodedBody,
        };
      }

      // Si ya es un Map, devolverlo tal como está
      return decodedBody;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to fetch available slots');
    }
  } catch (e) {
    throw 'Error fetching available slots: $e';
  }
}

Future<Map<String, dynamic>> getStudentReviews(String? token, int id,
    {int page = 1, int perPage = 5}) async {
  try {
    final Uri uri =
        Uri.parse('$baseUrl/student-reviews/$id?page=$page&perPage=$perPage');

    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get student reviews');
    }
  } catch (e) {
    throw 'Failed to get student reviews $e';
  }
}

Future<Map<String, dynamic>> getBillingDetail(String token, int id) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/billing-detail/$id');
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get billing detail');
    }
  } catch (e) {
    throw 'Failed to get identity billing detail $e';
  }
}

Future<Map<String, dynamic>> addBillingDetail(
    String token, Map<String, dynamic> data) async {
  final Uri uri = Uri.parse('$baseUrl/billing-detail');
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  try {
    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(data),
    );

    final decodedResponse = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return decodedResponse;
    } else {
      final error = decodedResponse;
      return {
        'status': response.statusCode,
        'message': error['message'] ?? 'Failed to add billing detail:',
        'errors': error['errors'] ?? {},
      };
    }
  } catch (e) {
    return {'status': 500, 'message': 'Failed to add billing detail:'};
  }
}

Future<Map<String, dynamic>> updateBillingDetails(
    String token, int id, Map<String, dynamic> updateBillingData) async {
  final url = Uri.parse('$baseUrl/billing-detail/$id');

  try {
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(updateBillingData),
    );

    final decodedResponse = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return decodedResponse;
    } else {
      return {
        'status': response.statusCode,
        'errors': decodedResponse['errors'] ?? {},
      };
    }
  } catch (error) {
    return {
      'status': 500,
      'message': 'Error occurred: $error',
    };
  }
}

Future<Map<String, dynamic>> bookSessionCart(
    String token, Map<String, dynamic> data, String id) async {
  final Uri uri = Uri.parse('$baseUrl/booking-cart').replace(
    queryParameters: {
      'id': id,
    },
  );
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  try {
    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(data),
    );

    final decodedResponse = json.decode(response.body);

    if (response.statusCode == 200) {
      return decodedResponse;
    } else {
      return {
        'status': response.statusCode,
        'message': decodedResponse['message'] ?? 'Failed to book session',
        'errors': decodedResponse['errors'],
      };
    }
  } catch (e) {
    return {'status': 500, 'message': 'Failed to book session'};
  }
}

Future<Map<String, dynamic>> getBookingCart(String token) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/booking-cart');
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get booking cart');
    }
  } catch (e) {
    throw 'Failed to get booking cart $e';
  }
}

Future<Map<String, dynamic>> deleteBookingCart(String token, int id) async {
  final url = Uri.parse('$baseUrl/booking-cart/$id');

  try {
    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {
        'status': response.statusCode,
        'message': 'Failed to delete booking cart: ${response.reasonPhrase}',
      };
    }
  } catch (error) {
    return {
      'status': 500,
      'message': 'Error occurred: $error',
    };
  }
}

Future<Map<String, dynamic>> postCheckOut(
    String token, Map<String, dynamic> data) async {
  final Uri uri = Uri.parse('$baseUrl/checkout');
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  try {
    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(data),
    );

    final decodedResponse = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return decodedResponse;
    } else {
      final error = decodedResponse;
      return {
        'status': response.statusCode,
        'message': error['message'] ?? 'Failed to add billing detail:',
        'errors': error['errors'] ?? {},
      };
    }
  } catch (e) {
    return {'status': 500, 'message': 'Failed to add billing detail:'};
  }
}

Future<Map<String, dynamic>> getEarningDetails(String token) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/earning-detail');
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get earning details');
    }
  } catch (e) {
    throw 'Failed to get earning details $e';
  }
}

Future<Map<String, dynamic>> fetchAlliances() async {
  try {
    final Uri uri = Uri.parse('$baseUrl/alianzas');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      return {'data': json.decode(response.body)};
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Error al obtener alianzas');
    }
  } catch (e) {
    throw 'Error al obtener alianzas: $e';
  }
}

Future<Map<String, dynamic>> getAllSubjects(String? token,
    {int page = 1, int perPage = 10, String? keyword}) async {
  try {
    final Map<String, dynamic> queryParams = {
      'page': page.toString(),
      'per_page': perPage.toString(),
      'keyword': keyword,
    };

    queryParams.removeWhere((key, value) => value == null);

    final Uri uri = Uri.parse('$baseUrl/all-subjects')
        .replace(queryParameters: queryParams);
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get all subjects');
    }
  } catch (e) {
    throw 'Failed to get all subjects: $e';
  }
}

Future<Map<String, dynamic>> getVerifiedTutorsPhotos(String? token) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/verified-tutors-photos');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ??
          'Error al obtener fotos de tutores verificados: ${response.statusCode}');
    }
  } catch (e) {
    throw 'Error al obtener fotos de tutores verificados: $e';
  }
}

Future<Map<String, dynamic>> createSlotBooking(
    String token, Map<String, dynamic> data) async {
  final Uri uri = Uri.parse('$baseUrl/slot-bookings');
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  try {
    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(data),
    );

    final decodedResponse = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return decodedResponse;
    } else {
      return {
        'status': response.statusCode,
        'message':
            decodedResponse['message'] ?? 'Failed to create slot booking',
        'errors': decodedResponse['errors'],
      };
    }
  } catch (e) {
    return {'status': 500, 'message': 'Failed to create slot booking: $e'};
  }
}

Future<Map<String, dynamic>> createPaymentSlotBooking(
    String token, Map<String, dynamic> data) async {
  final Uri uri = Uri.parse('$baseUrl/payment-slot-bookings');
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  try {
    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(data),
    );

    final decodedResponse = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return decodedResponse;
    } else {
      return {
        'status': response.statusCode,
        'message': decodedResponse['message'] ??
            'Failed to create payment slot booking',
        'errors': decodedResponse['errors'],
      };
    }
  } catch (e) {
    return {
      'status': 500,
      'message': 'Failed to create payment slot booking: $e'
    };
  }
}

Future<Map<String, dynamic>> uploadPaymentReceipt(
    String token, File imageFile, int slotBookingId) async {
  final Uri uri = Uri.parse('$baseUrl/test-payment-upload');
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  final request = http.MultipartRequest('POST', uri);
  request.headers.addAll(headers);
  request.fields['slot_booking_id'] = slotBookingId.toString();
  request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

  final streamedResponse = await request.send();
  final response = await http.Response.fromStream(streamedResponse);

  final decodedResponse = jsonDecode(response.body);

  if (response.statusCode == 200 || response.statusCode == 201) {
    return decodedResponse;
  } else {
    return {
      'status': response.statusCode,
      'message': decodedResponse['message'] ?? 'Error al subir comprobante',
      'errors': decodedResponse['errors'],
    };
  }
}

Future<List<Map<String, dynamic>>> getUserBookingsById(
    String token, int userId) async {
  final Uri uri = Uri.parse('$baseUrl/user/$userId/bookings');
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  final response = await http.get(uri, headers: headers);
  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data.cast<Map<String, dynamic>>();
  } else {
    throw Exception('Error al obtener las tutorías del usuario');
  }
}

// Tutor Subjects API Methods
Future<Map<String, dynamic>> getTutorSubjects(String token, int userId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/tutor-subjects?user_id=$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get tutor subjects: ${response.statusCode}');
    }
  } catch (e) {
    print('Error getting tutor subjects: $e');
    throw e;
  }
}

Future<Map<String, dynamic>> addTutorSubject(String token, int userId,
    int subjectId, String description, String? imagePath) async {
  try {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/tutor-subjects'),
    );

    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    request.fields['user_id'] = userId.toString();
    request.fields['subject_id'] = subjectId.toString();
    request.fields['description'] = description;

    if (imagePath != null && imagePath.isNotEmpty) {
      final file = File(imagePath);
      if (await file.exists()) {
        final stream = http.ByteStream(file.openRead());
        final length = await file.length();
        final multipartFile = http.MultipartFile(
          'image',
          stream,
          length,
          filename: path.basename(imagePath),
        );
        request.files.add(multipartFile);
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add tutor subject: ${response.statusCode}');
    }
  } catch (e) {
    print('Error adding tutor subject: $e');
    throw e;
  }
}

Future<Map<String, dynamic>> deleteTutorSubject(
    String token, int tutorId, int subjectId) async {
  try {
    final url = '$baseUrl/tutor/$tutorId/subjects/$subjectId';
    print('🔍 DEBUG - URL de eliminación: $url');
    print('🔍 DEBUG - Token: ${token.substring(0, 20)}...');
    print('🔍 DEBUG - Tutor ID: $tutorId');
    print('🔍 DEBUG - Subject ID: $subjectId');
    
    final response = await http.delete(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    print('🔍 DEBUG - Status code de respuesta: ${response.statusCode}');
    print('🔍 DEBUG - Cuerpo de respuesta: ${response.body}');
    
    if (response.statusCode == 200 || response.statusCode == 204) {
      return {'success': true, 'message': 'Subject deleted successfully'};
    } else {
      final responseBody = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      final errorMessage = responseBody['message'] ?? 'Failed to delete tutor subject: ${response.statusCode}';
      return {'success': false, 'message': errorMessage, 'status': response.statusCode};
    }
  } catch (e) {
    print('Error deleting tutor subject: $e');
    return {'success': false, 'message': 'Error de conexión: $e'};
  }
}

// Get available subjects for dropdown
Future<Map<String, dynamic>> getAvailableSubjects(String token) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/subjects'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'Failed to get available subjects: ${response.statusCode}');
    }
  } catch (e) {
    print('Error getting available subjects: $e');
    throw e;
  }
}

// Create user subject slot
Future<Map<String, dynamic>> createUserSubjectSlot(
    String token, Map<String, dynamic> slotData) async {
  try {
    // Preparar los datos según el nuevo formato requerido
    final Map<String, dynamic> requestData = {
      'user_id': slotData['user_id'],
      'start_time': slotData['start_time'],
      'end_time': slotData['end_time'],
      'date': slotData['date'],
      'duracion': slotData['duracion'],
    };

    print('DEBUG - createUserSubjectSlot request data: $requestData');

    final response = await http.post(
      Uri.parse('$baseUrl/tutor/slots'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(requestData),
    );

    print(
        'DEBUG - createUserSubjectSlot response: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body);

      // Verificar si la respuesta tiene el formato esperado
      if (responseData['success'] == true) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Slot creado exitosamente',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Error al crear el slot',
          'data': responseData['data'],
        };
      }
    } else {
      final errorData = jsonDecode(response.body);
      return {
        'success': false,
        'message': errorData['message'] ?? 'Error al crear el slot',
        'status': response.statusCode,
      };
    }
  } catch (e) {
    print('Error creating user subject slot: $e');
    return {
      'success': false,
      'message': 'Error de conexión: $e',
    };
  }
}

// Delete user subject slot
Future<Map<String, dynamic>> deleteUserSubjectSlot(
    String token, int slotId, int userId) async {
  try {
    print('DEBUG - deleteUserSubjectSlot request: slot_id = $slotId, user_id = $userId');

    final response = await http.delete(
      Uri.parse('$baseUrl/tutor/slots'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'slot_id': slotId,
        'user_id': userId,
      }),
    );

    print('DEBUG - deleteUserSubjectSlot response: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 204) {
      final responseData = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      return {
        'success': true,
        'message': responseData['message'] ?? 'Slot eliminado exitosamente',
        'data': responseData['data'],
      };
    } else {
      final errorData = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      return {
        'success': false,
        'message': errorData['message'] ?? 'Error al eliminar el slot',
        'status': response.statusCode,
      };
    }
  } catch (e) {
    print('Error deleting user subject slot: $e');
    return {
      'success': false,
      'message': 'Error de conexión: $e',
    };
  }
}

// Cambiar estado de tutoría a "Cursando"
Future<Map<String, dynamic>> changeBookingToCursando(
    String token, int bookingId) async {
  try {
    print(
        'DEBUG - Cambiando estado de tutoría a Cursando: booking_id = $bookingId');

    final response = await http.post(
      Uri.parse('$baseUrl/booking/change-to-cursando'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'booking_id': bookingId,
      }),
    );

    print(
        'DEBUG - Respuesta del servidor: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return {
        'success': true,
        'message': responseData['message'] ??
            'Estado cambiado a Cursando exitosamente',
        'data': responseData['data'],
      };
    } else {
      final errorData = jsonDecode(response.body);
      return {
        'success': false,
        'message':
            errorData['message'] ?? 'Error al cambiar el estado de la tutoría',
        'status': response.statusCode,
      };
    }
  } catch (e) {
    print('Error changing booking to cursando: $e');
    return {
      'success': false,
      'message': 'Error de conexión: $e',
    };
  }
}

// Obtener imagen de perfil del usuario
Future<Map<String, dynamic>> getUserProfileImage(
    String token, int userId) async {
  try {
    print('DEBUG - Obteniendo imagen de perfil para usuario: $userId');

    final response = await http.get(
      Uri.parse('$baseUrl/user/$userId/profile-image'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    print(
        'DEBUG - Respuesta del servidor: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return {
        'success': true,
        'data': responseData,
      };
    } else {
      final errorData = jsonDecode(response.body);
      return {
        'success': false,
        'message':
            errorData['message'] ?? 'Error al obtener la imagen de perfil',
        'status': response.statusCode,
      };
    }
  } catch (e) {
    print('Error getting user profile image: $e');
    return {
      'success': false,
      'message': 'Error de conexión: $e',
    };
  }
}

// Verificar si el tutor tiene slot bookings para la hora actual
Future<Map<String, dynamic>> checkTutorCurrentSlotBookings(
    String? token, int tutorId) async {
  try {
    print('DEBUG - Verificando slot bookings actuales del tutor: $tutorId');
    print('DEBUG - URL del endpoint: $baseUrl/tutor/$tutorId/available-slots');
    
    // Obtener la hora actual en Bolivia (UTC-4)
    final now = DateTime.now().subtract(Duration(hours: 4));
    final currentDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00';
    
    print('DEBUG - Fecha actual: $currentDate, Hora actual: $currentTime');
    print('DEBUG - DateTime.now(): ${DateTime.now()}');
    print('DEBUG - DateTime.now() en Bolivia: $now');
    
    final Uri uri = Uri.parse('$baseUrl/tutor/$tutorId/available-slots');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    final response = await http.get(uri, headers: headers);
    print('DEBUG - Respuesta de slot bookings: ${response.statusCode} - ${response.body}');
    
    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      
            // Verificar si hay slots disponibles para la hora actual
      bool hasCurrentSlot = false;
      
      print('DEBUG - responseData completo: $responseData');
      
      // El responseData ya es la lista directamente, no tiene 'data' key
      if (responseData is List) {
        final slots = responseData;
        print('DEBUG - Número de slots encontrados: ${slots.length}');
        
        for (var slot in slots) {
          try {
            print('DEBUG - Procesando slot: $slot');
            
            // Verificar que el slot tenga los campos necesarios
            if (slot['start_time'] != null && 
                slot['end_time'] != null && 
                slot['date'] != null) {
              
              final slotDate = slot['date'].toString().trim();
              final startTimeUTC = DateTime.parse(slot['start_time'].toString().trim());
              final endTimeUTC = DateTime.parse(slot['end_time'].toString().trim());
              
              print('DEBUG - slotDate: $slotDate');
              print('DEBUG - startTimeUTC: $startTimeUTC');
              print('DEBUG - endTimeUTC: $endTimeUTC');
              
              // Convertir a hora local de Bolivia (UTC-4)
              final startTime = startTimeUTC.subtract(Duration(hours: 4));
              final endTime = endTimeUTC.subtract(Duration(hours: 4));
              
              print('DEBUG - startTime (Bolivia): $startTime');
              print('DEBUG - endTime (Bolivia): $endTime');
              
              // Verificar si el slot es para hoy y la hora actual está dentro del rango
              print('DEBUG - 🔍 Comparando fechas: slotDate="$slotDate" vs currentDate="$currentDate"');
              print('DEBUG - 🔍 ¿Son iguales?: ${slotDate == currentDate}');
              
              if (slotDate == currentDate) {
                print('DEBUG - ✅ Slot es para hoy, verificando horario...');
                
                final slotStartMinutes = startTime.hour * 60 + startTime.minute;
                final slotEndMinutes = endTime.hour * 60 + endTime.minute;
                final currentMinutes = now.hour * 60 + now.minute;
                
                print('DEBUG - slotStartMinutes: $slotStartMinutes');
                print('DEBUG - slotEndMinutes: $slotEndMinutes');
                print('DEBUG - currentMinutes: $currentMinutes');
                
                if (currentMinutes >= slotStartMinutes && currentMinutes < slotEndMinutes) {
                  hasCurrentSlot = true;
                  print('DEBUG - ✅ Encontrado slot válido: ${startTime.hour}:${startTime.minute} - ${endTime.hour}:${endTime.minute}');
                  break;
                } else {
                  print('DEBUG - ❌ Slot no válido para hora actual');
                }
              } else {
                print('DEBUG - ❌ Slot no es para hoy (slotDate: $slotDate, currentDate: $currentDate)');
              }
            } else {
              print('DEBUG - ❌ Slot no tiene campos necesarios');
            }
          } catch (e) {
            print('DEBUG - Error procesando slot: $e');
            continue;
          }
        }
      } else {
        print('DEBUG - ❌ responseData no es una lista: ${responseData.runtimeType}');
      }
      
      print('DEBUG - Resultado final: hasCurrentSlot = $hasCurrentSlot');
      
      return {
        'success': true,
        'has_current_slot': hasCurrentSlot,
        'current_date': currentDate,
        'current_time': currentTime,
      };
    } else {
      final error = json.decode(response.body);
      return {
        'success': false,
        'message': error['message'] ?? 'Error al verificar slot bookings: ${response.statusCode}',
        'has_current_slot': false,
      };
    }
  } catch (e) {
    print('Error checking tutor current slot bookings: $e');
    return {
      'success': false,
      'message': 'Error de conexión: $e',
      'has_current_slot': false,
    };
  }
}

// Verificar disponibilidad de un tutor específico antes de confirmar tutoría
Future<Map<String, dynamic>> checkTutorAvailabilityBeforeBooking(
    String? token, int tutorId) async {
  try {
    print('DEBUG - Verificando disponibilidad del tutor antes de confirmar tutoría: $tutorId');
    print('DEBUG - URL del endpoint: $baseUrl/verified-tutors-photos?tutor_id=$tutorId');
    
    final Uri uri = Uri.parse('$baseUrl/verified-tutors-photos?tutor_id=$tutorId');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    final response = await http.get(uri, headers: headers);
    print('DEBUG - Respuesta de verificación: ${response.statusCode} - ${response.body}');
    
    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      
      // Extraer la disponibilidad del primer tutor en la lista
      print('DEBUG - responseData: $responseData');
      print('DEBUG - responseData[\'data\']: ${responseData['data']}');
      
      if (responseData['data'] != null && 
          responseData['data'] is List && 
          responseData['data'].isNotEmpty) {
        final tutorData = responseData['data'][0];
        print('DEBUG - tutorData: $tutorData');
        final availableForTutoring = tutorData['available_for_tutoring'] ?? false;
        final tutorName = tutorData['name'] ?? 'Tutor';
        
        print('DEBUG - available_for_tutoring extraído: $availableForTutoring');
        print('DEBUG - tutorName extraído: $tutorName');
        
        return {
          'success': true,
          'available_for_tutoring': availableForTutoring,
          'tutor_name': tutorName,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': 'No se encontró información del tutor',
          'available_for_tutoring': false,
          'tutor_name': 'Tutor',
        };
      }
    } else {
      final error = json.decode(response.body);
      return {
        'success': false,
        'message': error['message'] ?? 'Error al verificar disponibilidad del tutor: ${response.statusCode}',
        'available_for_tutoring': false,
        'tutor_name': 'Tutor',
      };
    }
  } catch (e) {
    print('Error checking tutor availability: $e');
    return {
      'success': false,
      'message': 'Error de conexión: $e',
      'available_for_tutoring': false,
      'tutor_name': 'Tutor',
    };
  }
}

// Obtener disponibilidad de tutoría de un tutor específico
Future<Map<String, dynamic>> getTutorTutoringAvailability(
    String? token, int tutorId) async {
  try {
    print('DEBUG - Obteniendo disponibilidad de tutoría para tutor: $tutorId');
    
    final Uri uri = Uri.parse('$baseUrl/verified-tutors-photos?tutor_id=$tutorId');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    final response = await http.get(uri, headers: headers);
    print('DEBUG - Respuesta del servidor: ${response.statusCode} - ${response.body}');
    
    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      
      // Extraer la disponibilidad del primer tutor en la lista
      if (responseData['data'] != null && 
          responseData['data'] is List && 
          responseData['data'].isNotEmpty) {
        final tutorData = responseData['data'][0];
        final availableForTutoring = tutorData['available_for_tutoring'] ?? false;
        
        return {
          'success': true,
          'available_for_tutoring': availableForTutoring,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': 'No se encontró información del tutor',
          'available_for_tutoring': false,
        };
      }
    } else {
      final error = json.decode(response.body);
      return {
        'success': false,
        'message': error['message'] ?? 'Error al obtener disponibilidad del tutor: ${response.statusCode}',
        'available_for_tutoring': false,
      };
    }
  } catch (e) {
    print('Error getting tutor tutoring availability: $e');
    return {
      'success': false,
      'message': 'Error de conexión: $e',
      'available_for_tutoring': false,
    };
  }
}

// Actualizar disponibilidad de tutoría del usuario
Future<Map<String, dynamic>> updateTutoringAvailability(
    String token, int userId, bool availableForTutoring) async {
  try {
    print('DEBUG - Actualizando disponibilidad de tutoría para usuario: $userId');
    print('DEBUG - Disponibilidad: ${availableForTutoring ? "Activada" : "Desactivada"}');

    final response = await http.put(
      Uri.parse('$baseUrl/user/$userId/tutoring-availability'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'available_for_tutoring': availableForTutoring ? 1 : 0,
      }),
    );

    print('DEBUG - Respuesta del servidor: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return {
        'success': true,
        'message': availableForTutoring 
            ? 'Disponibilidad de tutoría activada exitosamente'
            : 'Disponibilidad de tutoría desactivada exitosamente',
        'data': responseData,
      };
    } else {
      final errorData = jsonDecode(response.body);
      return {
        'success': false,
        'message': errorData['message'] ?? 'Error al actualizar la disponibilidad de tutoría',
        'status': response.statusCode,
      };
    }
  } catch (e) {
    print('Error updating tutoring availability: $e');
    return {
      'success': false,
      'message': 'Error de conexión: $e',
    };
  }
}

/// Obtiene un tutor específico para una materia
/// 
/// ✅ NUEVO: Endpoint para buscar tutor por materia
/// /api/tutor-for-subject/{subjectId}
/// 
/// Devuelve:
/// - Un tutor si está disponible para esa materia
/// - 404 si no hay tutores disponibles
Future<Map<String, dynamic>> getTutorForSubject(String? token, int subjectId) async {
  try {
    print('DEBUG - Buscando tutor para materia: $subjectId');
    print('DEBUG - URL del endpoint: $baseUrl/tutor-for-subject/$subjectId');
    
    final Uri uri = Uri.parse('$baseUrl/tutor-for-subject/$subjectId');
    
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
    
    print('DEBUG - Respuesta del servidor: ${response.statusCode} - ${response.body}');
    
    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('DEBUG - Datos del tutor encontrado: $responseData');
      
      return {
        'success': true,
        'data': responseData['data'],
        'tutor': responseData['data']['tutor'],
        'subject': responseData['data']['subject'],
        'search_time': responseData['data']['search_time'],
      };
    } else if (response.statusCode == 404) {
      print('DEBUG - No se encontró tutor para la materia: $subjectId');
      return {
        'success': false,
        'message': 'No se encontró ningún tutor disponible para esta materia en este momento',
        'status': 404,
      };
    } else {
      print('DEBUG - Error del servidor: ${response.statusCode}');
      return {
        'success': false,
        'message': 'Error del servidor: ${response.statusCode}',
        'status': response.statusCode,
      };
    }
  } catch (e) {
    print('DEBUG - Error de conexión: $e');
    return {
      'success': false,
      'message': 'Error de conexión: $e',
      'status': 500,
    };
  }
}
