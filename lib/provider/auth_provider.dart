import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/api_structure/config/app_config.dart';
import 'package:flutter_projects/view/tutor/certificate/certificate_detail.dart';
import 'package:flutter_projects/view/tutor/experience/experience_detail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_projects/view/tutor/education/education_details.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

class AuthProvider with ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _userData;
  List<Education> _educationList = [];
  List<Experience> _experienceList = [];
  List<Certificate> _certificateList = [];
  List<int> favoriteTutorIds = [];

  String? _firstName;
  String? _lastName;
  String? _email;
  String? _phone;
  String? _country;
  String? _state;
  String? _city;
  String? _zipCode;
  String? _description;
  String? _company;
  bool _isLoading = true;
  bool _isSessionLoaded =
      false; // Nuevo: indica si la sesión se cargó completamente

  String? get firstName => _firstName;
  String? get lastName => _lastName;
  String? get email => _email;
  String? get phone => _phone;
  String? get country => _country;
  String? get state => _state;
  String? get city => _city;
  String? get zipCode => _zipCode;
  String? get description => _description;
  String? get company => _company;

  String? get token => _token;
  Map<String, dynamic>? get userData => _userData;
  List<Education> get educationList => _educationList;
  List<Experience> get experienceList => _experienceList;
  List<Certificate> get certificateList => _certificateList;
  bool get isLoading => _isLoading;
  bool get isSessionLoaded => _isSessionLoaded; // Nuevo getter

  bool get isLoggedIn =>
      _token != null &&
      _isSessionLoaded; // Modificado: requiere que la sesión esté cargada

  /// Obtiene el rol del usuario
  String? get userRole {
    if (_userData != null &&
        _userData!.containsKey('user') &&
        _userData!['user'].containsKey('role')) {
      String role = _userData!['user']['role'];
      print('DEBUG - userRole detectado: $role');
      return role;
    }
    print('DEBUG - userRole no encontrado. userData: $_userData');
    return null;
  }

  /// Verifica si el usuario es un tutor
  bool get isTutor {
    bool result = userRole == 'tutor';
    print('DEBUG - isTutor: $result (userRole: ${userRole})');
    return result;
  }

  /// Verifica si el usuario es un estudiante
  bool get isStudent {
    bool result = userRole == 'student';
    print('DEBUG - isStudent: $result (userRole: ${userRole})');
    return result;
  }

  int? get userId {
    if (_userData != null &&
        _userData!.containsKey('user') &&
        _userData!['user'].containsKey('id')) {
      return _userData!['user']['id'];
    }
    return null;
  }

  /// Obtiene el nombre completo del usuario
  String get userName {
    print('DEBUG - userName llamado');
    print('DEBUG - userData: $_userData');

    if (_userData != null && _userData!.containsKey('user')) {
      final user = _userData!['user'];
      print('DEBUG - user keys: ${user.keys}');
      print('DEBUG - user data: $user');

      // Verificar si existe profile
      if (user['profile'] != null) {
        final profile = user['profile'];
        print('DEBUG - profile keys: ${profile.keys}');
        print('DEBUG - profile data: $profile');

        // Intentar obtener full_name primero
        if (profile['full_name'] != null) {
          print('DEBUG - Usando full_name: ${profile['full_name']}');
          return profile['full_name'];
        }

        // Intentar obtener first_name y last_name
        if (profile['first_name'] != null && profile['last_name'] != null) {
          final name = '${profile['first_name']} ${profile['last_name']}';
          print('DEBUG - Usando first_name + last_name: $name');
          return name;
        } else if (profile['first_name'] != null) {
          print('DEBUG - Usando solo first_name: ${profile['first_name']}');
          return profile['first_name'];
        } else if (profile['last_name'] != null) {
          print('DEBUG - Usando solo last_name: ${profile['last_name']}');
          return profile['last_name'];
        }
      }

      // Fallback: buscar en user directamente
      if (user['first_name'] != null && user['last_name'] != null) {
        final name = '${user['first_name']} ${user['last_name']}';
        print('DEBUG - Usando first_name + last_name del user: $name');
        return name;
      } else if (user['first_name'] != null) {
        print('DEBUG - Usando solo first_name del user: ${user['first_name']}');
        return user['first_name'];
      } else if (user['last_name'] != null) {
        print('DEBUG - Usando solo last_name del user: ${user['last_name']}');
        return user['last_name'];
      } else if (user['name'] != null) {
        print('DEBUG - Usando name del user: ${user['name']}');
        return user['name'];
      }
    }
    print('DEBUG - No se encontró nombre, usando "Usuario"');
    return 'Usuario';
  }

  AuthProvider() {
    _loadSession();
    loadFromPreferences();
    _initializeToken();
  }

  void updateBalance(double newBalance) {
    if (userData != null && userData!['user'] != null) {
      userData!['user']['balance'] = newBalance;
      notifyListeners();
    }
  }

  Future<void> _initializeToken() async {
    _token = _token;
    notifyListeners();
  }

  Future<void> _loadSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    print('DEBUG - Token cargado: ${_token != null ? "SÍ" : "NO"}');

    final userDataString = prefs.getString('userData');
    if (userDataString != null) {
      _userData = jsonDecode(userDataString) as Map<String, dynamic>;
      print('DEBUG - userData cargado: ${_userData != null ? "SÍ" : "NO"}');
      if (_userData != null) {
        print('DEBUG - userData keys: ${_userData!.keys}');
        if (_userData!.containsKey('user')) {
          print('DEBUG - user keys: ${_userData!['user'].keys}');
        }
      }
    } else {
      print('DEBUG - No se encontró userData en SharedPreferences');
    }

    final educationListString = prefs.getString('educationList');
    if (educationListString != null) {
      final List<dynamic> educationData = jsonDecode(educationListString);
      _educationList = educationData
          .map((item) => Education.fromJson(jsonDecode(item)))
          .toList();
    } else {
      _educationList = [];
    }

    final experienceListString = prefs.getString('experienceList');
    if (experienceListString != null) {
      final List<dynamic> experienceData = jsonDecode(experienceListString);
      _experienceList = experienceData
          .map((item) => Experience.fromJson(jsonDecode(item)))
          .toList();
    } else {
      _experienceList = [];
    }

    // Marcar que la sesión se cargó completamente
    _isSessionLoaded = true;
    _isLoading = false;
    print(
        'DEBUG - Sesión cargada. isLoggedIn: $isLoggedIn, isTutor: $isTutor, isStudent: $isStudent');
    notifyListeners();
  }

  Future<void> saveEducation(Education education) async {
    int index = _educationList.indexWhere((edu) => edu.id == education.id);
    if (index >= 0) {
      _educationList[index] = education;
    } else {
      _educationList.add(education);
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> educationJsonList =
        _educationList.map((edu) => jsonEncode(edu.toJson())).toList();
    await prefs.setString('educationList', jsonEncode(educationJsonList));

    notifyListeners();
  }

  void updateEducation(int index, Education updatedEducation) async {
    if (index >= 0 && index < _educationList.length) {
      _educationList[index] = updatedEducation;

      SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> educationJsonList =
          _educationList.map((edu) => jsonEncode(edu.toJson())).toList();
      await prefs.setString('educationList', jsonEncode(educationJsonList));

      notifyListeners();
    }
  }

  Future<void> removeEducation(int index) async {
    if (index >= 0 && index < _educationList.length) {
      _educationList.removeAt(index);

      SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> educationJsonList =
          _educationList.map((edu) => jsonEncode(edu.toJson())).toList();
      await prefs.setString('educationList', jsonEncode(educationJsonList));

      notifyListeners();
    }
  }

  Future<void> _saveExperienceToPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final List<String> experienceJsonList =
        _experienceList.map((exp) => jsonEncode(exp.toJson())).toList();

    await prefs.setString('experienceList', jsonEncode(experienceJsonList));
  }

  Future<void> loadExperiences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? experienceJson = prefs.getString('experienceList');

    if (experienceJson != null) {
      List<dynamic> decoded = jsonDecode(experienceJson);

      _experienceList =
          decoded.map((exp) => Experience.fromJson(jsonDecode(exp))).toList();

      notifyListeners();
    }
  }

  Future<void> removeExperience(int index) async {
    if (index >= 0 && index < _experienceList.length) {
      _experienceList.removeAt(index);
      await _saveExperienceToPreferences();
      notifyListeners();
    } else {}
  }

  Future<void> saveExperience(Experience newExperience) async {
    _experienceList.add(newExperience);
    await _saveExperienceToPreferences();
    notifyListeners();
  }

  Future<void> updateExperienceList(Experience updatedExperience) async {
    int index =
        _experienceList.indexWhere((exp) => exp.id == updatedExperience.id);
    if (index >= 0) {
      _experienceList[index] = updatedExperience;
      await _saveExperienceToPreferences();
      notifyListeners();
    }
  }

  Future<void> setToken(String token) async {
    print('setToken llamado con token: $token');
    _token = token;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    print('Token guardado en SharedPreferences');
    notifyListeners();
    print('setToken completado y notificados los listeners');
  }

  Future<void> setAuthToken(String token) async {
    print('setAuthToken llamado con token: $token');
    _token = token;
    print('Token guardado en memoria: $_token');
    notifyListeners();
    print('Listeners notificados en setAuthToken');

    // Enviar el token FCM al backend
    print('Obteniendo token FCM...');
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    print('Token FCM obtenido:  [32m${fcmToken ?? 'null'} [0m');
    int? userIdValue = userId;
    print('User ID obtenido:  [32m$userIdValue [0m');

    if (fcmToken != null && userIdValue != null) {
      try {
        print('Enviando token FCM al backend...');
        print('URL: https://classgoapp.com/api/update-fcm-token');
        print(
            'Headers: Content-Type: application/json, Accept: application/json');
        print('Body: {"user_id": $userIdValue, "fcm_token": "$fcmToken"}');

        final response = await http.post(
          Uri.parse('https://classgoapp.com/api/update-fcm-token'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'User-Agent': 'ClassGoApp/1.0',
          },
          body: jsonEncode({'user_id': userIdValue, 'fcm_token': fcmToken}),
        );
        print(
            'Respuesta backend FCM:  [34m${response.statusCode} [0m - ${response.body}');

        if (response.statusCode == 200) {
          print('Token FCM enviado exitosamente al backend');
        } else {
          print('Error en respuesta del backend: ${response.statusCode}');
        }
      } catch (e) {
        print('Error enviando FCM token al backend: $e');
        print('Stack trace: ${StackTrace.current}');
      }
    } else {
      print('No se pudo obtener el token FCM o el user_id');
    }
    // Escuchar cambios de token FCM y actualizar en el backend
    print('Configurando listener para cambios de token FCM...');
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      int? userIdValue = userId;
      print('Token FCM actualizado: $newToken');
      print('User ID obtenido:  [32m$userIdValue [0m');
      if (userIdValue != null) {
        try {
          print('Enviando token FCM actualizado al backend...');
          final response = await http.post(
            Uri.parse('https://classgoapp.com/api/update-fcm-token'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'User-Agent': 'ClassGoApp/1.0',
            },
            body: jsonEncode({'user_id': userIdValue, 'fcm_token': newToken}),
          );
          print(
              'FCM token actualizado en backend:  [34m${response.statusCode} [0m - ${response.body}');

          if (response.statusCode == 200) {
            print('Token FCM actualizado exitosamente en el backend');
          } else {
            print(
                'Error actualizando token FCM en backend: ${response.statusCode}');
          }
        } catch (e) {
          print('Error actualizando FCM token en backend: $e');
          print('Stack trace: ${StackTrace.current}');
        }
      } else {
        print('No se pudo obtener el user_id para actualizar el token FCM');
      }
    });
    print('Listener de token FCM configurado');
  }

  Future<void> setUserData(Map<String, dynamic> userData) async {
    print('setUserData llamado con datos: $userData');
    _userData = userData;
    print('Datos de usuario guardados en memoria: $_userData');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userData', jsonEncode(userData));
    print('Datos de usuario guardados en SharedPreferences');
    notifyListeners();
    print('setUserData completado y notificados los listeners');
  }

  Future<void> clearToken() async {
    _token = null;
    _userData = null;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    notifyListeners();
  }

  Future<void> saveCertificate(Certificate certificate) async {
    int index = _certificateList
        .indexWhere((cert) => cert.jobTitle == certificate.jobTitle);
    if (index >= 0) {
      _certificateList[index] = certificate;
    } else {
      _certificateList.add(certificate);
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> certificateJsonList =
        _certificateList.map((cert) => jsonEncode(cert.toJson())).toList();
    await prefs.setString('certificateList', jsonEncode(certificateJsonList));

    notifyListeners();
  }

  Future<Map<String, dynamic>> addCertificateToApi(
      String token, Certificate certificate) async {
    final Map<String, dynamic> certificateData = certificate.toJson()
      ..remove('id');

    final response = await addCertification(token, certificateData);

    if (response['status'] == 200) {
      final responseData = response['data'];
      if (responseData != null && responseData.containsKey('id')) {
        int newCertificateId = responseData['id'];

        final Certificate updatedCertificate =
            certificate.copyWith(id: newCertificateId);
        await saveCertificate(updatedCertificate);
      }
    } else {
      final errors = response['errors'] ?? {};
      if (errors.isNotEmpty) {
        final errorMessages = errors.values.join(', ');
      }

      throw Exception(response['message'] ?? 'Failed to add certificate');
    }

    return response;
  }

  Future<void> removeCertificate(int index) async {
    if (index >= 0 && index < _certificateList.length) {
      _certificateList.removeAt(index);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> certificateJsonList =
          _certificateList.map((cert) => jsonEncode(cert.toJson())).toList();
      await prefs.setString('certificateList', jsonEncode(certificateJsonList));

      notifyListeners();
    } else {}
  }

  Future<void> loadCertificates() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final certificateListString = prefs.getString('certificateList');
    if (certificateListString != null) {
      try {
        final List<dynamic> certificateData = jsonDecode(certificateListString);
        _certificateList = certificateData.map((item) {
          if (item is Map<String, dynamic>) {
            return Certificate.fromJson(item);
          } else if (item is String) {
            return Certificate.fromJson(jsonDecode(item));
          } else {
            throw Exception(
                "Unexpected type in certificate data: ${item.runtimeType}");
          }
        }).toList();
      } catch (e) {}
    } else {
      _certificateList = [];
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>> updateCertificateToApi(
      String token, Certificate certificate) async {
    final Map<String, dynamic> certificationData = certificate.toJson();
    certificationData.remove('id');

    try {
      final response =
          await updateCertification(token, certificate.id, certificationData);

      if (response['status'] == 200) {
        int index =
            _certificateList.indexWhere((cert) => cert.id == certificate.id);
        if (index >= 0) {
          _certificateList[index] = certificate;
        }

        notifyListeners();
        return response;
      } else {
        throw Exception(response['message'] ?? 'Failed to update certificate');
      }
    } catch (e) {
      throw e;
    }
  }

  Future<void> updateUserProfiles(Map<String, dynamic>? updatedProfile) async {
    if (updatedProfile != null && _userData != null) {
      // Construir full_name si tenemos first_name y last_name
      if (updatedProfile['first_name'] != null && updatedProfile['last_name'] != null) {
        updatedProfile['full_name'] = '${updatedProfile['first_name']} ${updatedProfile['last_name']}';
      }
      
      // Actualizar _userData['user']['profile']
      _userData!['user']['profile'] = updatedProfile;
      
      // Actualizar los campos individuales para mantener sincronizados los datos
      if (updatedProfile['first_name'] != null) {
        _firstName = updatedProfile['first_name'];
      }
      if (updatedProfile['last_name'] != null) {
        _lastName = updatedProfile['last_name'];
      }
      if (updatedProfile['phone_number'] != null) {
        _phone = updatedProfile['phone_number'];
      }
      if (updatedProfile['description'] != null) {
        _description = updatedProfile['description'];
      }
      
      // Guardar en SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userData', jsonEncode(_userData));
      
      // Guardar los campos individuales también
      await prefs.setString('firstName', _firstName ?? '');
      await prefs.setString('lastName', _lastName ?? '');
      await prefs.setString('phone', _phone ?? '');
      await prefs.setString('description', _description ?? '');
      
      notifyListeners();
    } else {}
  }

  void updateProfileImage(String newImageUrl) {
    if (_userData != null && _userData!['user'] != null) {
      // Asegurar que la estructura profile existe
      if (_userData!['user']['profile'] == null) {
        _userData!['user']['profile'] = {};
      }
      
      // Limpiar y normalizar la URL
      final cleanedUrl = _cleanUrl(newImageUrl);
      
      // Actualizar la imagen de perfil
      _userData!['user']['profile']['image'] = cleanedUrl;
      
      // También actualizar profile_image si existe
      _userData!['user']['profile']['profile_image'] = cleanedUrl;
      
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('userData', jsonEncode(_userData));
        notifyListeners();
      });
    }
  }

  String _cleanUrl(String url) {
    // Si la URL ya es completa (comienza con http), devolverla tal como está
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    
    // Si la URL es relativa, construir la URL completa
    if (url.startsWith('/')) {
      return '${AppConfig.mediaBaseUrl}${url.substring(1)}';
    }
    
    // Si la URL no tiene slash inicial, agregarlo
    return '${AppConfig.mediaBaseUrl}$url';
  }

  Future<void> updateUserProfile(Map<String, dynamic> newProfileData) async {
    if (_userData != null) {
      _userData!['profile'] = newProfileData;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userData', jsonEncode(_userData));
      notifyListeners();
    }
  }

  void setFirstName(String value) {
    _firstName = value;
    saveToPreferences();
    notifyListeners();
  }

  void setLastName(String value) {
    _lastName = value;
    saveToPreferences();
    notifyListeners();
  }

  void setEmail(String value) {
    _email = value;
    saveToPreferences();
    notifyListeners();
  }

  void setPhone(String value) {
    _phone = value;
    saveToPreferences();
    notifyListeners();
  }

  void setCountry(String value) {
    _country = value;
    saveToPreferences();
    notifyListeners();
  }

  void setState(String value) {
    _state = value;
    saveToPreferences();
    notifyListeners();
  }

  void setCity(String value) {
    _city = value;
    saveToPreferences();
    notifyListeners();
  }

  void setZipCode(String value) {
    _zipCode = value;
    saveToPreferences();
    notifyListeners();
  }

  void setDescription(String value) {
    _description = value;
    saveToPreferences();
    notifyListeners();
  }

  void setCompany(String value) {
    _company = value;
    saveToPreferences();
    notifyListeners();
  }

  Future<void> saveToPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('firstName', _firstName ?? '');
    await prefs.setString('lastName', _lastName ?? '');
    await prefs.setString('email', _email ?? '');
    await prefs.setString('phone', _phone ?? '');
    await prefs.setString('country', _country ?? '');
    await prefs.setString('state', _state ?? '');
    await prefs.setString('city', _city ?? '');
    await prefs.setString('zipCode', _zipCode ?? '');
    await prefs.setString('description', _description ?? '');
    await prefs.setString('company', _company ?? '');
  }

  Future<void> loadFromPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _firstName = prefs.getString('firstName') ?? '';
    _lastName = prefs.getString('lastName') ?? '';
    _email = prefs.getString('email') ?? '';
    _phone = prefs.getString('phone') ?? '';
    _country = prefs.getString('country') ?? '';
    _state = prefs.getString('state') ?? '';
    _city = prefs.getString('city') ?? '';
    _zipCode = prefs.getString('zipCode') ?? '';
    _description = prefs.getString('description') ?? '';
    _company = prefs.getString('company') ?? '';

    notifyListeners();
  }

  /// Cierra la sesión del usuario
  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Limpiar token
    _token = null;
    await prefs.remove('token');

    // Limpiar datos del usuario
    _userData = null;
    await prefs.remove('userData');

    // Limpiar listas
    _educationList.clear();
    _experienceList.clear();
    _certificateList.clear();
    await prefs.remove('educationList');
    await prefs.remove('experienceList');

    // Limpiar datos del perfil
    _firstName = null;
    _lastName = null;
    _email = null;
    _phone = null;
    _country = null;
    _state = null;
    _city = null;
    _zipCode = null;
    _description = null;
    _company = null;

    await prefs.remove('firstName');
    await prefs.remove('lastName');
    await prefs.remove('email');
    await prefs.remove('phone');
    await prefs.remove('country');
    await prefs.remove('state');
    await prefs.remove('city');
    await prefs.remove('zipCode');
    await prefs.remove('description');
    await prefs.remove('company');

    notifyListeners();
  }
}
