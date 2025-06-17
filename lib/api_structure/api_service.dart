import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

final String baseUrl = 'https://classgoapp.com/api';

Future<Map<String, dynamic>> registerUser(Map<String, dynamic> userData) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(userData),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
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

        throw {
          'message': errorMessage,
          'status': response.statusCode,
        };
      } catch (e) {
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
        throw {
          'message': responseData['message'] ??
              'An error occurred during registration',
          'status': response.statusCode,
        };
      } else {
        throw {
          'message':
              'An unexpected response was received from the server. Please try again later.',
          'status': response.statusCode,
        };
      }
    }
  } catch (e) {
    if (e is Map<String, dynamic> && e.containsKey('message')) {
      throw e;
    } else {
      throw {'message': 'An unexpected error occurred during registration.'};
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

    final Uri uri = Uri.parse('$baseUrl/find-tutors').replace(queryParameters: queryParams);

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
      throw Exception(error['message'] ?? 'Error al obtener tutores: ${response.statusCode}');
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

    final Uri uri = Uri.parse('$baseUrl/verified-tutors').replace(queryParameters: queryParams);

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
      throw Exception(error['message'] ?? 'Error al obtener tutores verificados: ${response.statusCode}');
    }
  } catch (e) {
    throw 'Error al obtener tutores verificados: $e';
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

    final decodedResponse = json.decode(response.body);

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
  final Uri uri = Uri.parse('$baseUrl/subject-slots').replace(
    queryParameters: {
      'user_id': userId,
    },
  );
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

Future<Map<String, dynamic>> getAllSubjects(String? token, {int page = 1, int perPage = 10, String? keyword}) async {
  try {
    final Map<String, dynamic> queryParams = {
      'page': page.toString(),
      'per_page': perPage.toString(),
      'keyword': keyword,
    };

    queryParams.removeWhere((key, value) => value == null);

    final Uri uri = Uri.parse('$baseUrl/all-subjects').replace(queryParameters: queryParams);
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
      throw Exception(error['message'] ?? 'Error al obtener fotos de tutores verificados: ${response.statusCode}');
    }
  } catch (e) {
    throw 'Error al obtener fotos de tutores verificados: $e';
  }
}
