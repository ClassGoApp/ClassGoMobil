import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/provider/location_provider.dart';
import 'package:flutter_projects/provider/onboarding_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:image_picker/image_picker.dart';

class StepTwoPersonal extends StatefulWidget {
  const StepTwoPersonal({Key? key}) : super(key: key);

  @override
  State<StepTwoPersonal> createState() => _StepTwoPersonalState();
}

class _StepTwoPersonalState extends State<StepTwoPersonal> {
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  DateTime? _selectedDob;
  int? _selectedCountryId;
  int? _selectedStateId;
  String? _selectedGender;
  File? _profilePhoto;
  bool _countryHasStates = false;

  final ImagePicker _picker = ImagePicker();

  static const List<Map<String, String>> _genderOptions = [
    {'value': 'male', 'label': 'Masculino'},
    {'value': 'female', 'label': 'Femenino'},
    {'value': 'not_specified', 'label': 'No especifica'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final provider = Provider.of<OnboardingProvider>(context, listen: false);
      Provider.of<LocationProvider>(context, listen: false).Countries(auth.token!);

      if (provider.dateOfBirth != null) {
        _selectedDob = provider.dateOfBirth;
        _dobController.text = DateFormat('yyyy-MM-dd').format(provider.dateOfBirth!);
      }
      if (provider.selectedCountryId != null) _selectedCountryId = provider.selectedCountryId;
      if (provider.selectedStateId != null) _selectedStateId = provider.selectedStateId;
      if (provider.city != null) _cityController.text = provider.city!;
      if (provider.address != null) _addressController.text = provider.address!;
      if (provider.gender != null) _selectedGender = provider.gender;
      if (provider.profilePhoto != null) _profilePhoto = provider.profilePhoto;
      _countryHasStates = provider.countryHasStates;

      setState(() {});
    });
  }

  @override
  void dispose() {
    _dobController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _syncWithProvider() {
    context.read<OnboardingProvider>().updatePersonalData(
      dob: _selectedDob ?? DateTime(2000),
      countryId: _selectedCountryId,
      stateId: _selectedStateId,
      userCity: _cityController.text,
      userAddress: _addressController.text,
      hasStates: _countryHasStates,
      selectedGender: _selectedGender,
    );
    context.read<OnboardingProvider>().updateStepTwoFiles(
      profilePic: _profilePhoto,
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.brandBlue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
      _syncWithProvider();
    }
  }

  void _showProfilePhotoOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text('Foto de Perfil', style: TextStyle(fontFamily: 'outfit', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.brandBlue)),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded, color: AppColors.brandCyan),
                title: const Text('Tomar una foto', style: TextStyle(fontFamily: 'manrope', fontSize: 16)),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickProfilePhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.brandCyan),
                title: const Text('Elegir de la galería', style: TextStyle(fontFamily: 'manrope', fontSize: 16)),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickProfilePhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickProfilePhoto(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1500,
      );

      if (image != null) {
        final File imageFile = File(image.path);
        final extension = imageFile.path.split('.').last.toLowerCase();
        if (extension != 'jpg' && extension != 'jpeg' && extension != 'png') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Solo se permiten imágenes JPG o PNG')),
            );
          }
          return;
        }

        final int bytes = await imageFile.length();
        if (bytes > 5242880) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('La imagen pesa más de 5MB. Intenta con otra.')),
            );
          }
          return;
        }

        setState(() {
          _profilePhoto = imageFile;
        });
        _syncWithProvider();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al acceder a la cámara/galería')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();

    int? safeCountryId;
    if (_selectedCountryId != null && locationProvider.countries.isNotEmpty) {
      bool exists = locationProvider.countries.any((c) {
        int currentId = c['id'] is int ? c['id'] : int.parse(c['id'].toString());
        return currentId == _selectedCountryId;
      });
      safeCountryId = exists ? _selectedCountryId : null;
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Un poco sobre ti',
            style: TextStyle(
              fontFamily: 'outfit',
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.brandBlue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Necesitamos estos datos para verificar tu identidad y mantener la comunidad segura.',
            style: TextStyle(
              fontFamily: 'manrope',
              fontSize: 15,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 30),

          _buildUploadBox(
            title: 'Foto de Perfil',
            icon: Icons.face_retouching_natural_rounded,
            imageFile: _profilePhoto,
            onTap: () => _showProfilePhotoOptions(context),
          ),
          const SizedBox(height: 24),

          _buildTextField(
            controller: _dobController,
            label: 'Fecha de Nacimiento',
            hint: 'YYYY-MM-DD',
            icon: Icons.calendar_today_rounded,
            readOnly: true,
            onTap: () => _selectDate(context),
          ),
          const SizedBox(height: 20),

          DropdownButtonFormField<int>(
            isExpanded: true,
            value: safeCountryId,
            hint: const Text("Selecciona tu país"),
            items: locationProvider.countries.map((c) {
              return DropdownMenuItem<int>(
                value: c['id'] is int ? c['id'] : int.parse(c['id'].toString()),
                child: Text(c['name']),
              );
            }).toList(),
            onChanged: (int? newValue) {
              setState(() {
                _selectedCountryId = newValue;
                _selectedStateId = null;
                _countryHasStates = false;
              });
              _syncWithProvider();
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final locProvider = Provider.of<LocationProvider>(context, listen: false);
              locProvider.clearStates();
              if (newValue != null) {
                locProvider.States(auth.token!, newValue);
              }
            },
            decoration: _getInputDecoration('País', Icons.public_rounded),
          ),
          const SizedBox(height: 20),

          Consumer<LocationProvider>(
            builder: (context, locProvider, child) {
              if (_selectedCountryId == null) return const SizedBox.shrink();

              if (locProvider.isLoadingStates) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(color: AppColors.brandBlue),
                  ),
                );
              }

              if (locProvider.states.isNotEmpty) {
                int? safeStateId;
                if (_selectedStateId != null) {
                  bool exists = locProvider.states.any((s) {
                    int currentId = s['id'] is int ? s['id'] : int.parse(s['id'].toString());
                    return currentId == _selectedStateId;
                  });
                  safeStateId = exists ? _selectedStateId : null;
                }

                if (!_countryHasStates) {
                  _countryHasStates = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) => _syncWithProvider());
                }

                return Column(
                  children: [
                    _buildDropdownField(
                      label: 'Estado / Departamento',
                      hint: 'Selecciona tu departamento',
                      icon: Icons.map_rounded,
                      value: safeStateId,
                      items: locProvider.states.map((s) {
                        return DropdownMenuItem<int>(
                          value: s['id'] is int ? s['id'] : int.parse(s['id'].toString()),
                          child: Text(s['name']),
                        );
                      }).toList(),
                      onChanged: (int? newValue) {
                        setState(() => _selectedStateId = newValue);
                        _syncWithProvider();
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              }

              if (_countryHasStates) {
                _countryHasStates = false;
                _selectedStateId = null;
                WidgetsBinding.instance.addPostFrameCallback((_) => _syncWithProvider());
              }

              return const SizedBox.shrink();
            },
          ),

          _buildDropdownField(
            label: 'Género',
            hint: 'Selecciona tu género',
            icon: Icons.wc_rounded,
            value: _genderOptions.indexWhere((g) => g['value'] == _selectedGender),
            items: _genderOptions.asMap().entries.map((entry) {
              return DropdownMenuItem<int>(
                value: entry.key,
                child: Text(entry.value['label']!),
              );
            }).toList(),
            onChanged: (int? index) {
              if (index != null) {
                setState(() {
                  _selectedGender = _genderOptions[index]['value'];
                });
                _syncWithProvider();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUploadBox({
    required String title,
    required IconData icon,
    required File? imageFile,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
              fontFamily: 'outfit',
              fontWeight: FontWeight.bold,
              color: AppColors.brandBlue,
              fontSize: 16),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: imageFile != null
                    ? AppColors.primaryGreen
                    : AppColors.brandBlue.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: imageFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.file(
                      imageFile,
                      fit: BoxFit.contain,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.brandBlue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 40, color: AppColors.brandBlue),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Toca para subir imagen',
                        style: TextStyle(
                            fontFamily: 'manrope',
                            color: AppColors.brandBlue,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'JPG, PNG (Máx. 5MB)',
                        style: TextStyle(
                            fontFamily: 'manrope',
                            color: Colors.grey.shade500,
                            fontSize: 12),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool readOnly = false,
    int maxLines = 1,
    VoidCallback? onTap,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontFamily: 'outfit', fontWeight: FontWeight.bold, color: AppColors.brandBlue, fontSize: 16),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          onChanged: onChanged,
          maxLines: maxLines,
          style: const TextStyle(fontFamily: 'manrope', fontSize: 16),
          decoration: _getInputDecoration(hint, icon),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required IconData icon,
    required int? value,
    required List<DropdownMenuItem<int>> items,
    required void Function(int?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontFamily: 'outfit', fontWeight: FontWeight.bold, color: AppColors.brandBlue, fontSize: 16),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          isExpanded: true,
          value: value != null && value >= 0 ? value : null,
          items: items,
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.brandBlue),
          style: const TextStyle(fontFamily: 'manrope', fontSize: 16, color: Colors.black),
          decoration: _getInputDecoration(hint, icon),
        ),
      ],
    );
  }

  InputDecoration _getInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      prefixIcon: Icon(icon, color: AppColors.brandBlue.withOpacity(0.5)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.brandBlue, width: 2),
      ),
    );
  }
}
