import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';

class OnboardingProvider extends ChangeNotifier {
  Map<int, int> tempSelectedSubjects = {};
  String? legalName;
  DateTime? dateOfBirth;
  int? selectedCountryId;
  int? selectedStateId;
  String? city;
  String? address;

  File? personalPhoto;
  File? documentFile;

  File? profilePhoto;
  String? gender;

  bool isLoading = false;
  bool countryHasStates = false;

  static const int maxOnboardingSubjects = 3;

  bool toggleTempSubject(int subjectId, int groupId) {
    if (tempSelectedSubjects.containsKey(subjectId)) {
      tempSelectedSubjects.remove(subjectId);
      notifyListeners();
      return true;
    } else {
      if (tempSelectedSubjects.length < maxOnboardingSubjects) {
        tempSelectedSubjects[subjectId] = groupId;
        notifyListeners();
        return true;
      } else {
        return false;
      }
    }
  }

  int getSelectedCountForGroup(int groupId) {
    return tempSelectedSubjects.values.where((id) => id == groupId).length;
  }

  bool get isStepOneValid => tempSelectedSubjects.isNotEmpty;

  bool get isStepTwoValid =>
      dateOfBirth != null &&
      selectedCountryId != null &&
      gender != null &&
      profilePhoto != null &&
      (!countryHasStates || selectedStateId != null);

  bool get isStepThreeValid => personalPhoto != null && documentFile != null;

  Future<Map<String, dynamic>> submitFullOnboarding({
    required String token,
    required String role,
    required int userId,
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    isLoading = true;
    notifyListeners();

    if (selectedCountryId == null) {
      isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Faltan datos de ubicación.'};
    }
    if (gender == null) {
      isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Selecciona tu género.'};
    }
    if (countryHasStates && selectedStateId == null) {
      isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Selecciona tu departamento.'};
    }
    if (profilePhoto == null) {
      isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Sube tu foto de perfil.'};
    }
    if (personalPhoto == null || documentFile == null) {
      isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Faltan documentos obligatorios.'};
    }

    String docKey = role == 'tutor' ? 'identificationCard' : 'transcript';
    String formattedDate =
        "${dateOfBirth!.year}-${dateOfBirth!.month.toString().padLeft(2, '0')}-${dateOfBirth!.day.toString().padLeft(2, '0')}";

    try {
      // 1. Actualizar perfil (texto)
      final profileData = <String, String>{
        'first_name': firstName,
        'last_name': lastName,
        'phone_number': phoneNumber,
        'gender': gender!,
      };

      await updateUserProfile(
        token: token,
        userId: userId,
        profileData: profileData,
      );

      // 2. Subir foto de perfil (avatar público)
      final imageResponse = await updateProfileImage(
        token: token,
        userId: userId,
        imagePath: profilePhoto!.path,
      );

      if (imageResponse['success'] != true) {
        isLoading = false;
        notifyListeners();
        return {
          'success': false,
          'message': 'Error al subir la foto de perfil.'
        };
      }

      // 3. Enviar verificación de identidad
      final identityResponse = await submitIdentityVerification(
        token: token,
        documentKey: docKey,
        name: legalName ?? firstName,
        dateOfBirth: formattedDate,
        countryId: selectedCountryId!,
        stateId: selectedStateId ?? 0,
        address: address ?? '',
        image: personalPhoto!,
        document: documentFile!,
      );

      if (identityResponse['success'] != true) {
        isLoading = false;
        notifyListeners();
        return identityResponse;
      }

      // 4. Guardar materias (tutor)
      if (role == 'tutor' && tempSelectedSubjects.isNotEmpty) {
        for (int subjectId in tempSelectedSubjects.keys) {
          await addTutorSubject(token, userId, subjectId, null, null);
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }

      isLoading = false;
      notifyListeners();
      return {'success': true, 'message': 'Perfil completado con éxito'};

    } catch (e) {
      isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Ocurrió un error inesperado'};
    }
  }

  void updatePersonalData({
    required DateTime dob,
    required int countryId,
    int? stateId,
    required String userCity,
    required String userAddress,
    required bool hasStates,
    String? selectedGender,
  }) {
    dateOfBirth = dob;
    selectedCountryId = countryId;
    selectedStateId = hasStates ? stateId : null;
    city = userCity;
    address = userAddress;
    countryHasStates = hasStates;
    if (selectedGender != null) gender = selectedGender;
    notifyListeners();
  }

  void updateStepTwoFiles({File? profilePic}) {
    if (profilePic != null) {
      profilePhoto = profilePic;
    }
    notifyListeners();
  }

  void updateDocuments({File? personalPic, File? docFile, required String role}) {
    if (personalPic != null) {
      personalPhoto = personalPic;
    }
    if (docFile != null) {
      documentFile = docFile;
    }
    notifyListeners();
  }

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void clearData() {
    tempSelectedSubjects.clear();
    legalName = null;
    dateOfBirth = null;
    selectedCountryId = null;
    selectedStateId = null;
    address = null;
    personalPhoto = null;
    documentFile = null;
    profilePhoto = null;
    gender = null;
    countryHasStates = false;
    isLoading = false;
    notifyListeners();
  }
}
