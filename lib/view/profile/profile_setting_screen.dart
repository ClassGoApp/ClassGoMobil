import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/api_structure/config/app_config.dart';
import 'package:flutter_projects/base_components/custom_snack_bar.dart';
import 'package:flutter_projects/base_components/textfield.dart';
import 'package:flutter_projects/provider/connectivity_provider.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/components/internet_alert.dart';
import 'package:flutter_projects/view/components/video_widget.dart';
import 'package:flutter_projects/view/profile/component/user_language_bottom_sheet.dart';
import 'package:flutter_projects/view/profile/skeleton/profile_setting_skeleton.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:provider/provider.dart';
import '../../provider/auth_provider.dart';
import '../components/bottom_sheet.dart';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;

class ProfileSettingsScreen extends StatefulWidget {
  @override
  _ProfileSettingsScreenState createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  File? _selectedVideo;

  String _gender = 'male';
  String? _selectedCountry;
  String? _selectedLanguage;
  String? _selectedState;
  late double screenWidth;
  late double screenHeight;
  List<String> _countries = [];
  List<String> _states = [];

  Map<int, String> _countryMap = {};
  Map<int, String> _statesMap = {};
  Map<int, String> _languageMap = {};

  int? _selectedCountryId;
  int? _selectedStateId;

  List<int> _selectedLanguageIds = [];

  Map<String, dynamic>? _profileData;
  bool _isLoading = false;

  bool _isStateFieldVisible = false;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _languagesController = TextEditingController();
  final TextEditingController _userLanguagesController =
      TextEditingController();
  final TextEditingController _stateController = TextEditingController();

  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _taglineController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCountries();
    _fetchLanguages();
    _fetchProfileData();
    _fetchUserLanguages();

    if (_selectedCountryId != null) {
      _fetchStates(_selectedCountryId!);
    }

    _descriptionController.addListener(_updateParsedDescription);
  }

  void _updateParsedDescription() {
    setState(() {
      String parsedText = parse(_descriptionController.text).body?.text ?? '';
      if (_descriptionController.text != parsedText) {
        _descriptionController.value = TextEditingValue(
          text: parsedText,
          selection: TextSelection.fromPosition(
            TextPosition(offset: parsedText.length),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _descriptionController.removeListener(_updateParsedDescription);
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchCountries() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final response = await getCountries(token!);
      final countriesData = response['data'];
      setState(() {
        _countries = countriesData.map<String>((country) {
          _countryMap[country['id']] = country['name'];
          return country['name'] as String;
        }).toList();
      });
    } catch (e) {}
  }

  Future<void> _fetchStates(int countryId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final response = await getCountryStates(token!, countryId);
      final statesData = response['data'];

      setState(() {
        _states = statesData.map<String>((state) {
          _statesMap[state['id']] = state['name'];
          return state['name'] as String;
        }).toList();
        _isStateFieldVisible = _states.isNotEmpty;

        if (_isStateFieldVisible && _selectedState != null) {
          _stateController.text = _selectedState!;
        } else {
          _stateController.clear();
        }
      });
    } catch (e) {
      setState(() {
        _isStateFieldVisible = false;
      });
    }
  }

  Future<void> _fetchUserLanguages() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final response = await getLanguages(token!);

      final languages = response['data'];

      setState(() {
        _languages = languages.map<String>((language) {
          _languageMap[language['id']] = language['name'];
          return language['name'] as String;
        }).toList();
      });
    } catch (e) {}
  }

  Future<void> _fetchLanguages() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final response = await getLanguages(token!);

      final languages = response['data'];

      setState(() {
        _languages = languages.map<String>((language) {
          return language['name'] as String;
        }).toList();
      });
    } catch (e) {}
  }

  void _showNaiveLanguageBottomSheet(
      TextEditingController languagesController) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return BottomSheetComponent(
              title: "Select Native Language",
              items: _languages,
              selectedItem: _selectedLanguage,
              onItemSelected: (selectedItem) {
                setModalState(() {
                  _selectedLanguage = selectedItem;
                  languagesController.text = selectedItem;
                });
              },
            );
          },
        );
      },
    );
  }

  void _playIntroVideo(String videoUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Scaffold(
          backgroundColor: AppColors.blackColor,
          body: Center(
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: VideoPlayerWidget(
                videoUrl: videoUrl,
                onClose: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _showUserLanguageBottomSheet(TextEditingController languagesController) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: false,
      builder: (BuildContext context) {
        return UserLanguageBottomSheetComponent(
          title: "Select Languages",
          items: _languages,
          selectedItems: _selectedLanguageIds
              .map((id) => _languageMap[id])
              .where((name) => name != null)
              .toList()
              .cast<String>(),
          onItemsSelected: (selectedItems) {
            setState(() {
              _selectedLanguageIds = selectedItems
                  .map((name) => _languageMap.entries
                      .firstWhere((entry) => entry.value == name)
                      .key)
                  .toList();
              languagesController.text = selectedItems.join(', ');
            });
          },
        );
      },
    );
  }

  void _showStateBottomSheet(TextEditingController stateController) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return BottomSheetComponent(
              title: _selectedState == null ? 'Select State' : '',
              items: _states,
              selectedItem: _selectedState,
              onItemSelected: (selectedItem) {
                setModalState(() {
                  _selectedState = selectedItem;
                  stateController.text = selectedItem;
                  _selectedStateId = _statesMap.entries
                      .firstWhere((entry) => entry.value == selectedItem)
                      .key;
                });
              },
            );
          },
        );
      },
    );
  }

  void _showCountryBottomSheet(TextEditingController countryController) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return BottomSheetComponent(
              title: "Select Country",
              items: _countries,
              selectedItem: _selectedCountry,
              onItemSelected: (selectedItem) async {
                setModalState(() {
                  _selectedCountry = selectedItem;
                  countryController.text = selectedItem;
                  _selectedCountryId = _countryMap.entries
                      .firstWhere((entry) => entry.value == selectedItem)
                      .key;
                });

                if (_selectedCountryId != null) {
                  await _fetchStates(_selectedCountryId!);
                }
              },
            );
          },
        );
      },
    );
  }

  Future<void> _fetchProfileData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final userId = authProvider.userId;

    setState(() {
      _isLoading = true;
    });

    if (token != null && userId != null) {
      try {
        final response = await getProfile(token, userId);

        setState(() {
          _profileData = response['data'];
          _isLoading = false;
        });

        if (_profileData != null && _profileData!['profile'] != null) {
          _firstNameController.text =
              _profileData!['profile']['first_name'] ?? '';
          _lastNameController.text =
              _profileData!['profile']['last_name'] ?? '';
          _emailController.text = _profileData!['email'] ?? '';
          _gender = _profileData!['profile']['gender'] ?? '';
          _descriptionController.text =
              _profileData!['profile']['description'] ?? '';
          _taglineController.text = _profileData!['profile']['tagline'] ?? '';
          _selectedLanguage = _profileData!['profile']['native_language'] ?? '';

          if (_profileData!['profile']['image'] != null) {
            String cleanedImageUrl =
                _cleanUrl(_profileData!['profile']['image']);
            authProvider.updateProfileImage(cleanedImageUrl);
          }

          if (_profileData!['profile']['intro_video'] != null) {
            String cleanedVideoUrl =
                _cleanUrl(_profileData!['profile']['intro_video']);
            authProvider.updateUserProfile({'intro_video': cleanedVideoUrl});
          }

          if (_profileData!['address'] != null) {
            _cityController.text = _profileData!['address']['city'] ?? '';
            _postalCodeController.text =
                _profileData!['address']['zipcode'] ?? '';

            if (_profileData!['address']['country'] != null) {
              _selectedCountry = _profileData!['address']['country']['name'];
              _countryController.text = _selectedCountry ?? '';
              _selectedCountryId = _profileData!['address']['country_id'];
            }

            if (_profileData!['address']['state'] != null) {
              _selectedState = _profileData!['address']['state']['name'];
              _stateController.text = _selectedState ?? '';
              _selectedStateId = _profileData!['address']['state_id'];
              _isStateFieldVisible = true;
            } else {
              _isStateFieldVisible = false;
            }

            if (_selectedCountryId != null) {
              _fetchStates(_selectedCountryId!);
            }
          }

          if (_profileData!['languages'] != null) {
            List<dynamic> languages = _profileData!['languages'];
            _selectedLanguageIds =
                languages.map<int>((lang) => lang['id'] as int).toList();
            _userLanguagesController.text =
                languages.map((lang) => lang['name'] as String).join(', ');
            _languagesController.text = _selectedLanguage!;
          }
        } else {}
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<String> _languages = [];
  bool _onPressLoading = false;

  void _saveAndUpdateProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final userId = authProvider.userId;

    if (token == null || userId == null) {
      return;
    }

    setState(() {
      _onPressLoading = true;
    });
    try {
      final Uri uri = Uri.parse('$baseUrl/profile-settings/$userId');
      var request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';

      request.fields['first_name'] = _firstNameController.text.trim();
      request.fields['last_name'] = _lastNameController.text.trim();
      request.fields['gender'] = _gender;
      request.fields['native_language'] = _selectedLanguage ?? '';
      request.fields['description'] = _descriptionController.text.trim();
      request.fields['country'] = _selectedCountryId?.toString() ??
          _profileData?['address']?['country_id']?.toString() ??
          '';
      request.fields['state'] = _selectedStateId?.toString() ??
          _profileData?['address']?['state_id']?.toString() ??
          '';
      request.fields['tagline'] = _taglineController.text.trim();
      request.fields['city'] = _cityController.text.trim();
      request.fields['zipcode'] = _postalCodeController.text.trim();
      request.fields['email'] = _emailController.text.trim();
      request.fields['recommend_tutor'] = 'true';

      for (int i = 0; i < _selectedLanguageIds.length; i++) {
        request.fields['user_languages[$i]'] =
            _selectedLanguageIds[i].toString();
      }

      if (_selectedImage != null) {
        var imageFile = File(_selectedImage!.path);
        String mimeType =
            lookupMimeType(imageFile.path) ?? 'application/octet-stream';
        var mimeTypeData = mimeType.split('/');
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType(mimeTypeData[0], mimeTypeData[1]),
        ));
      } else if (_profileData != null &&
          _profileData!['profile']['image'] != null) {
        String existingImageUrl = _profileData!['profile']['image'];
        request.fields['image'] = _cleanUrl(existingImageUrl);
      } else {}

      if (_selectedVideo != null) {
        var videoFile = File(_selectedVideo!.path);
        String mimeType =
            lookupMimeType(videoFile.path) ?? 'application/octet-stream';
        var mimeTypeData = mimeType.split('/');
        request.files.add(await http.MultipartFile.fromPath(
          'intro_video',
          videoFile.path,
          contentType: MediaType(mimeTypeData[0], mimeTypeData[1]),
        ));
      } else if (_profileData != null &&
          _profileData!['profile']['intro_video'] != null) {
        String existingVideoUrl = _profileData!['profile']['intro_video'];
        request.fields['intro_video'] = _cleanUrl(existingVideoUrl);
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        showCustomToast(context, responseData['message'], true);
        setState(() {
          _onPressLoading = false;
        });

        if (responseData != null &&
            responseData.containsKey('data') &&
            responseData['data'].containsKey('profile')) {
          var profileData = responseData['data']['profile'];
          authProvider.updateUserProfiles(profileData);

          if (_selectedImage != null) {
            authProvider.updateProfileImage(profileData['image']);
          }

          if (_selectedVideo != null) {
            authProvider
                .updateUserProfile({'intro_video': profileData['intro_video']});
          }
        } else {}
      } else if (response.statusCode == 422) {
        var errorData = jsonDecode(response.body);
        String errorMessages = errorData['errors']
            .entries
            .map((entry) => '${entry.key}: ${entry.value}')
            .join('\n');
        showCustomToast(context, errorMessages, false);
      } else {
        showCustomToast(context, 'Failed to update profile', false);
        setState(() {
          _onPressLoading = false;
        });
      }
    } catch (e) {
      showCustomToast(context, 'Error updating profile: $e', false);
    } finally {
      setState(() {
        _onPressLoading = false;
      });
    }
  }

  String _cleanUrl(String url) {
    if (url.contains(AppConfig.mediaBaseUrl)) {
      return url.replaceAll(AppConfig.mediaBaseUrl, '');
    }
    return url;
  }

  void showCustomToast(BuildContext context, String message, bool isSuccess) {
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 2.0,
        left: 16.0,
        right: 16.0,
        child: CustomToast(
          message: message,
          isSuccess: isSuccess,
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
    Future.delayed(const Duration(seconds: 1), () {
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    final authProvider = Provider.of<AuthProvider>(context);
    String? profileImageUrl =
        authProvider.userData?['user']?['profile']?['image'];

    return Consumer<ConnectivityProvider>(
      builder: (context, connectivityProvider, _) {
        if (!connectivityProvider.isConnected) {
          return Scaffold(
            backgroundColor: AppColors.backgroundColor,
            body: Center(
              child: InternetAlertDialog(
                onRetry: () async {
                  await connectivityProvider.checkInitialConnection();
                },
              ),
            ),
          );
        }

        return WillPopScope(
          onWillPop: () async {
            return !_isLoading;
          },
          child: Scaffold(
            backgroundColor: AppColors.backgroundColor,
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(70.0),
              child: Container(
                color: AppColors.primaryGreen,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: AppBar(
                    backgroundColor: AppColors.primaryGreen,
                    forceMaterialTransparency: true,
                    elevation: 0,
                    titleSpacing: 0,
                    title: Text(
                      'Configuración de Perfil',
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        color: AppColors.whiteColor,
                        fontSize: FontSize.scale(context, 20),
                        fontFamily: 'SF-Pro-Text',
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                    leading: Padding(
                      padding: const EdgeInsets.only(top: 3.0),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(Icons.arrow_back_ios,
                            size: 20, color: AppColors.whiteColor),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    centerTitle: false,
                  ),
                ),
              ),
            ),
            body: _isLoading
                ? ProfileSettingsSkeleton()
                : SingleChildScrollView(
                    child: Container(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Datos Personales',
                            style: TextStyle(
                              color: AppColors.greyColor,
                              fontSize: FontSize.scale(context, 16),
                              fontFamily: 'SF-Pro-Text',
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.normal,
                            ),
                          ),
                          SizedBox(height: 10),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            width: screenWidth,
                            decoration: BoxDecoration(
                              color: AppColors.whiteColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.rectangle,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: _selectedImage != null
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Image.file(
                                                _selectedImage!,
                                                fit: BoxFit.cover,
                                                width: 50,
                                                height: 50,
                                              ),
                                            )
                                          : (profileImageUrl != null &&
                                                  profileImageUrl.isNotEmpty
                                              ? ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  child: CachedNetworkImage(
                                                      imageUrl: profileImageUrl,
                                                      fit: BoxFit.cover,
                                                      width: 50,
                                                      height: 50,
                                                      placeholder: (context,
                                                              url) =>
                                                          Center(
                                                            child:
                                                                CircularProgressIndicator(
                                                              strokeWidth: 2.0,
                                                              color: AppColors
                                                                  .primaryGreen,
                                                            ),
                                                          ),
                                                      errorWidget: (context,
                                                              url, error) =>
                                                          Container(
                                                            width: 20,
                                                            height: 20,
                                                            padding:
                                                                EdgeInsets.all(
                                                                    10.0),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: AppColors
                                                                  .primaryGreen,
                                                              shape: BoxShape
                                                                  .rectangle,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10),
                                                            ),
                                                            child: SvgPicture
                                                                .asset(
                                                              AppImages
                                                                  .placeHolder,
                                                              height: 20,
                                                              fit: BoxFit.cover,
                                                            ),
                                                          )),
                                                )
                                              : Container(
                                                  width: 50,
                                                  height: 50,
                                                  padding: EdgeInsets.all(10.0),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        AppColors.primaryGreen,
                                                    shape: BoxShape.rectangle,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: SvgPicture.asset(
                                                    AppImages.placeHolder,
                                                    fit: BoxFit.cover,
                                                  ),
                                                )),
                                    ),
                                    Positioned(
                                      bottom: -8,
                                      right: -8,
                                      child: Container(
                                        padding: EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: AppColors.whiteColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: AppColors.whiteColor,
                                              width: 2),
                                        ),
                                        child: GestureDetector(
                                          onTap: _showPhotoActionSheet,
                                          child: CircleAvatar(
                                            radius: 12,
                                            backgroundColor:
                                                AppColors.primaryGreen,
                                            child: Icon(Icons.add,
                                                size: 16,
                                                color: AppColors.whiteColor),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Subir foto de perfil',
                                      style: TextStyle(
                                        color: AppColors.blackColor,
                                        fontSize: FontSize.scale(context, 14),
                                        fontFamily: 'SF-Pro-Text',
                                        fontWeight: FontWeight.w400,
                                        fontStyle: FontStyle.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 10),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            width: screenWidth,
                            decoration: BoxDecoration(
                              color: AppColors.whiteColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        if (_profileData!['profile']
                                                ['intro_video'] !=
                                            null) {
                                          String cleanedVideoUrl =
                                              _profileData!['profile']
                                                  ['intro_video'];
                                          _playIntroVideo(cleanedVideoUrl);
                                        } else {
                                          _pickVideo();
                                        }
                                      },
                                      child: Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryGreen,
                                          shape: BoxShape.rectangle,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          image: _selectedVideo != null
                                              ? DecorationImage(
                                                  image: _profileData![
                                                                  'profile']
                                                              ['intro_video'] !=
                                                          null
                                                      ? NetworkImage(
                                                          _profileData![
                                                                  'profile']
                                                              ['intro_video'],
                                                        )
                                                      : FileImage(
                                                              _selectedVideo!)
                                                          as ImageProvider,
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                        ),
                                        child: _selectedVideo != null
                                            ? Padding(
                                                padding: EdgeInsets.all(10.0),
                                                child: SvgPicture.asset(
                                                  AppImages.videoPlaceHolder,
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            : _profileData!['profile']
                                                        ['intro_video'] !=
                                                    null
                                                ? Icon(
                                                    Icons.play_circle_outline,
                                                    color: AppColors.whiteColor,
                                                    size: 24,
                                                  )
                                                : null,
                                      ),
                                    ),
                                    if (_selectedVideo == null &&
                                        _profileData!['profile']
                                                ['intro_video'] ==
                                            null)
                                      Positioned(
                                        bottom: -8,
                                        right: -8,
                                        child: Container(
                                          padding: EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: AppColors.whiteColor,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: AppColors.whiteColor,
                                                width: 2),
                                          ),
                                          child: GestureDetector(
                                            onTap: () {
                                              _pickVideo();
                                            },
                                            child: CircleAvatar(
                                              radius: 12,
                                              backgroundColor:
                                                  AppColors.primaryGreen,
                                              child: Icon(
                                                Icons.add,
                                                size: 16,
                                                color: AppColors.whiteColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                  ],
                                ),
                                SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          _profileData!['profile']
                                                      ['intro_video'] !=
                                                  null
                                              ? 'Reproducir video'
                                              : 'Subir video',
                                          style: TextStyle(
                                            color: AppColors.blackColor,
                                            fontSize:
                                                FontSize.scale(context, 14),
                                            fontFamily: 'SF-Pro-Text',
                                            fontWeight: FontWeight.w400,
                                            fontStyle: FontStyle.normal,
                                          ),
                                        ),
                                        if (_profileData!['profile']
                                                ['intro_video'] !=
                                            null)
                                          TextButton(
                                            onPressed: () {
                                              _pickVideo();
                                            },
                                            child: Text(
                                              'Reemplazar video',
                                              style: TextStyle(
                                                color: AppColors.primaryGreen,
                                                fontSize:
                                                    FontSize.scale(context, 12),
                                                fontFamily: 'SF-Pro-Text',
                                                fontWeight: FontWeight.w600,
                                                fontStyle: FontStyle.normal,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    Transform.translate(
                                      offset: const Offset(0.0, -10.0),
                                      child: Text(
                                        _profileData!['profile']
                                                    ['intro_video'] !=
                                                null
                                            ? 'Reproducir o reemplazar video'
                                            : '',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: AppColors.greyColor,
                                          fontSize: FontSize.scale(context, 12),
                                          fontFamily: 'SF-Pro-Text',
                                          fontWeight: FontWeight.w400,
                                          fontStyle: FontStyle.normal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    CustomTextField(
                                      hint: 'Nombres',
                                      obscureText: false,
                                      controller: _firstNameController,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    CustomTextField(
                                      hint: 'Apellidos',
                                      obscureText: false,
                                      controller: _lastNameController,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 15),
                          CustomTextField(
                            hint: 'Correo electrónico',
                            controller: _emailController,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Género',
                            style: TextStyle(
                                color: AppColors.greyColor,
                                fontSize: 16.0,
                                fontFamily: 'SF-Pro-Text',
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.normal),
                          ),
                          SizedBox(height: 16),
                          Wrap(
                            spacing: 28,
                            runSpacing: 16,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _gender = 'male';
                                  });
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _gender == 'male'
                                            ? AppColors.primaryGreen
                                            : AppColors.whiteColor,
                                        border: Border.all(
                                          color: _gender == 'male'
                                              ? Colors.transparent
                                              : AppColors.dividerColor,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Center(
                                        child: Container(
                                          width: 9,
                                          height: 9,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _gender == 'male'
                                                ? Colors.white
                                                : Colors.transparent,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Masculino',
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        fontFamily: 'SF-Pro-Text',
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.greyColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _gender =
                                        (_gender == 'female') ? '' : 'female';
                                  });
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _gender == 'female'
                                            ? AppColors.primaryGreen
                                            : AppColors.whiteColor,
                                        border: Border.all(
                                          color: _gender == 'female'
                                              ? Colors.transparent
                                              : AppColors.dividerColor,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Center(
                                        child: Container(
                                          width: 9,
                                          height: 9,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _gender == 'female'
                                                ? Colors.white
                                                : Colors.transparent,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Femenino',
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        fontFamily: 'SF-Pro-Text',
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.greyColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _gender = (_gender == 'not_specified')
                                        ? ''
                                        : 'not_specified';
                                  });
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _gender == 'not_specified'
                                            ? AppColors.primaryGreen
                                            : AppColors.whiteColor,
                                        border: Border.all(
                                          color: _gender == 'not_specified'
                                              ? Colors.transparent
                                              : AppColors.dividerColor,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Center(
                                        child: Container(
                                          width: 9,
                                          height: 9,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _gender == 'not_specified'
                                                ? Colors.white
                                                : Colors.transparent,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'No definido',
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        fontFamily: 'SF-Pro-Text',
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.greyColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          CustomTextField(
                            hint: 'Seleccionar País',
                            mandatory: true,
                            controller: _countryController,
                            absorbInput: true,
                            onTap: () {
                              _showCountryBottomSheet(_countryController);
                            },
                          ),
                          if (_isStateFieldVisible) SizedBox(height: 16),
                          if (_isStateFieldVisible)
                            CustomTextField(
                              hint: 'Seleccionar Departamento',
                              mandatory: true,
                              controller: _stateController,
                              absorbInput: true,
                              onTap: () {
                                _showStateBottomSheet(_stateController);
                              },
                            ),
                          SizedBox(height: 16),
                          CustomTextField(
                            hint: 'Municipio',
                            controller: _cityController,
                          ),
                          SizedBox(height: 16),
                          CustomTextField(
                            hint: 'Código Postal',
                            mandatory: false,
                            controller: _postalCodeController,
                            keyboardType: TextInputType.number,
                          ),
                          SizedBox(height: 16),
                          CustomTextField(
                            hint: 'Lenguaje nativo',
                            mandatory: true,
                            controller: _languagesController,
                            absorbInput: true,
                            onTap: () {
                              _showNaiveLanguageBottomSheet(
                                  _languagesController);
                            },
                          ),
                          SizedBox(height: 16),
                          CustomTextField(
                            hint: 'Lenguaje secundario',
                            mandatory: true,
                            controller: _userLanguagesController,
                            absorbInput: true,
                            onTap: () {
                              _showUserLanguageBottomSheet(
                                  _userLanguagesController);
                            },
                          ),
                          SizedBox(height: 16),
                          CustomTextField(
                            hint: 'Descripción corta',
                            mandatory: false,
                            controller: _taglineController,
                          ),
                          SizedBox(height: 16),
                          CustomTextField(
                            hint: 'Descripción personal',
                            multiLine: true,
                            mandatory: false,
                            controller: _descriptionController,
                          ),
                          SizedBox(height: 15),
                          Divider(
                            color: AppColors.dividerColor,
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed:
                                _onPressLoading ? null : _saveAndUpdateProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _onPressLoading
                                  ? AppColors.fadeColor
                                  : AppColors.primaryGreen,
                              minimumSize: Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Guardar y Actualizar',
                                  textScaler: TextScaler.noScaling,
                                  style: TextStyle(
                                    fontSize: FontSize.scale(context, 16),
                                    color: _onPressLoading
                                        ? AppColors.greyColor
                                        : AppColors.whiteColor,
                                    fontFamily: 'SF-Pro-Text',
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FontStyle.normal,
                                  ),
                                ),
                                if (_onPressLoading) ...[
                                  SizedBox(width: 10),
                                  SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primaryGreen,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 20,
                          )
                        ],
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickVideo() async {
    try {
      final pickedFile = await _picker.pickVideo(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _selectedVideo = File(pickedFile.path);
        });
      } else {}
    } catch (e) {}
  }

  void _viewProfilePhoto() {
    if (_selectedImage != null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Foto de Perfil'),
            content: Image.file(_selectedImage!),
            actions: <Widget>[
              TextButton(
                child: Text('Cerrar'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('No Profile Photo Selected'),
            content: Text('Please upload a profile photo first.'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  void _showPhotoActionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.sheetBackgroundColor,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
          child: Container(
            constraints: BoxConstraints(maxHeight: screenHeight * 0.25),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppColors.topBottomSheetDismissColor,
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                Text(
                  "Selecciona una opción",
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    color: AppColors.blackColor,
                    fontSize: FontSize.scale(context, 18),
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.normal,
                    fontFamily: "SF-Pro-Text",
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryWhiteColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildActionItem(
                            icon: Icons.photo_library,
                            text: 'Subir foto de perfil',
                            onTap: () {
                              Navigator.pop(context);
                              _pickImage();
                            },
                          ),
                          Divider(
                            color: AppColors.dividerColor,
                            height: 0,
                            thickness: 0.5,
                            indent: 24,
                            endIndent: 24,
                          ),
                          _buildActionItem(
                            icon: Icons.image,
                            text: 'Ver foto de perfil',
                            onTap: () {
                              Navigator.pop(context);
                              _viewProfilePhoto();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionItem(
      {required IconData icon,
      required String text,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 18.0, horizontal: 24.0),
        decoration: BoxDecoration(
            color: AppColors.primaryWhiteColor,
            borderRadius: BorderRadius.circular(10.0)),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: AppColors.greyColor,
            ),
            SizedBox(width: 24.0),
            Text(
              text,
              style: TextStyle(
                color: AppColors.greyColor,
                fontSize: FontSize.scale(context, 16),
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.normal,
                fontFamily: "SF-Pro-Text",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
