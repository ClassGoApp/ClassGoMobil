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
  File? documentFileBack; // Para foto trasera del carnet (solo tutores)

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
      selectedCountryId != 0 &&
      gender != null &&
      profilePhoto != null &&
      (!countryHasStates || selectedStateId != null);

  bool get isStepThreeValid {
    // Para tutores: validar que ambas fotos del carnet estén presentes
    if (personalPhoto == null || documentFile == null) {
      return false;
    }
    // Solo tutores necesitan la foto trasera del carnet
    // Los estudiantes solo necesitan el transcript (documentFile)
    return true;
  }

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

    if (selectedCountryId == null || selectedCountryId == 0 || gender == null || profilePhoto == null ||
        (countryHasStates && selectedStateId == null) ||
        personalPhoto == null || documentFile == null) {
      isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Completa todos los campos requeridos.'};
    }
    
    // Validación adicional para tutores: foto trasera del carnet es obligatoria
    if (role == 'tutor' && documentFileBack == null) {
      isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Debes subir ambas caras del carnet de identidad.'};
    }

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
        role: role,
        name: legalName ?? firstName,
        dateOfBirth: formattedDate,
        countryId: selectedCountryId!,
        stateId: selectedStateId ?? 0,
        address: address ?? '',
        image: personalPhoto!,
        documentFront: documentFile!,
        documentBack: documentFileBack, // Puede ser null para estudiantes
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
    int? countryId,
    int? stateId,
    required String userCity,
    required String userAddress,
    required bool hasStates,
    String? selectedGender,
  }) {
    dateOfBirth = dob;
    if (countryId != null && countryId != 0) {
      selectedCountryId = countryId;
    }
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

  void updateDocuments({File? personalPic, File? docFile, File? docFileBack, required String role}) {
    if (personalPic != null) {
      personalPhoto = personalPic;
    }
    if (docFile != null) {
      documentFile = docFile;
    }
    if (docFileBack != null) {
      documentFileBack = docFileBack;
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
    documentFileBack = null;
    profilePhoto = null;
    gender = null;
    countryHasStates = false;
    isLoading = false;
    notifyListeners();
  }
}
