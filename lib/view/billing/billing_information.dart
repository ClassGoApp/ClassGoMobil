import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/base_components/custom_snack_bar.dart';
import 'package:flutter_projects/base_components/textfield.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/billing/skeleton/billing_information_skeleton.dart';
import 'package:provider/provider.dart';
import '../../provider/auth_provider.dart';
import '../../provider/connectivity_provider.dart';
import '../components/bottom_sheet.dart';
import '../components/internet_alert.dart';

class BillingInformation extends StatefulWidget {
  @override
  _BillingInformationState createState() => _BillingInformationState();
}

class _BillingInformationState extends State<BillingInformation> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _companyTitleController = TextEditingController();
  final TextEditingController _emailAddressController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();

  final FocusNode _firstNameFocusNode = FocusNode();
  final FocusNode _lastNameFocusNode = FocusNode();
  final FocusNode _companyTitleFocusNode = FocusNode();
  final FocusNode _numberFocusNode = FocusNode();
  final FocusNode _cityFocusNode = FocusNode();
  final FocusNode _zipFocusNode = FocusNode();
  final FocusNode _addressFocusNode = FocusNode();

  bool _isFirstNameValid = true;
  bool _isLastNameValid = true;
  bool _isCompanyValid = true;
  bool _isEmailValid = true;
  bool _isPhoneNumberValid = true;
  bool _isCountryValid = true;
  bool _isCityValid = true;
  bool _isZipCodeValid = true;
  bool _isStateFieldVisible = false;
  bool _isStateValid = true;

  String? _selectedCountry;
  bool _allFieldsFilled = false;

  late double screenWidth;
  late double screenHeight;

  List<String> _countries = [];
  Map<int, String> _countryMap = {};
  int? _selectedCountryId;

  List<String> _states = [];
  Map<int, String> _statesMap = {};
  int? _selectedStateId;
  String? _selectedState;

  bool _isLoading = true;
  bool _onPressLoading = false;

  Map<String, dynamic>? _billingDetailData;

  void _checkFieldsFilled() {
    setState(() {
      _allFieldsFilled = _firstNameController.text.isNotEmpty &&
          _lastNameController.text.isNotEmpty &&
          _companyTitleController.text.isNotEmpty &&
          _emailAddressController.text.isNotEmpty &&
          _numberController.text.isNotEmpty &&
          _countryController.text.isNotEmpty &&
          _cityController.text.isNotEmpty &&
          _zipController.text.isNotEmpty &&
          (!_isStateFieldVisible || _stateController.text.isNotEmpty);
    });
  }

  @override
  void initState() {
    super.initState();

    _fetchCountries();
    _fetchBillingDetail();

    _firstNameController.addListener(_checkFieldsFilled);
    _lastNameController.addListener(_checkFieldsFilled);
    _companyTitleController.addListener(_checkFieldsFilled);
    _emailAddressController.addListener(_checkFieldsFilled);
    _numberController.addListener(_checkFieldsFilled);
    _countryController.addListener(_checkFieldsFilled);
    _cityController.addListener(_checkFieldsFilled);
    _zipController.addListener(_checkFieldsFilled);
    _stateController.addListener(_checkFieldsFilled);
    _addressController.addListener(_checkFieldsFilled);

    if (_selectedCountryId != null) {
      _fetchStates(_selectedCountryId!).then((_) {
        if (_selectedState != null) {
          _stateController.text = _selectedState!;
        }
      });
    } else if (_selectedState != null) {
      _stateController.text = _selectedState!;
    }
  }

  @override
  void dispose() {
    _firstNameController.removeListener(_checkFieldsFilled);
    _lastNameController.removeListener(_checkFieldsFilled);
    _companyTitleController.removeListener(_checkFieldsFilled);
    _emailAddressController.removeListener(_checkFieldsFilled);
    _numberController.removeListener(_checkFieldsFilled);
    _countryController.removeListener(_checkFieldsFilled);
    _cityController.removeListener(_checkFieldsFilled);
    _zipController.removeListener(_checkFieldsFilled);
    _addressController.removeListener(_checkFieldsFilled);
    _stateController.removeListener(_checkFieldsFilled);

    _firstNameController.dispose();
    _lastNameController.dispose();
    _companyTitleController.dispose();
    _emailAddressController.dispose();
    _numberController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _addressController.dispose();
    _stateController.dispose();

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

  Future<void> _fetchBillingDetail() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final userId = authProvider.userId;

    if (token != null) {
      try {
        final response = await getBillingDetail(token, userId!);
        final billingDetailData =
            response['data']['billingDetail'] as Map<String, dynamic>?;
        final billingDetailAddressData =
            billingDetailData?['address'] as Map<String, dynamic>?;

        if (billingDetailData == null || billingDetailAddressData == null) {
          throw Exception('Billing detail or address data is missing');
        }

        setState(() {
          _billingDetailData = billingDetailData;
          _firstNameController.text = billingDetailData['first_name'] ?? '';
          _lastNameController.text = billingDetailData['last_name'] ?? '';
          _companyTitleController.text = billingDetailData['company'] ?? '';
          _emailAddressController.text = billingDetailData['email'] ?? '';
          _numberController.text = billingDetailData['phone'] ?? '';
          _countryController.text =
              billingDetailAddressData['country']['name'] ?? '';
          _cityController.text = billingDetailAddressData['city'] ?? '';
          _zipController.text = billingDetailAddressData['zipcode'] ?? '';
          _addressController.text = billingDetailAddressData['address'] ?? '';
          _selectedCountryId = billingDetailAddressData['country_id'];
          _selectedStateId = billingDetailAddressData['state_id'];
          _stateController.text = billingDetailAddressData['state']?['name'];
          _isStateFieldVisible = _selectedCountryId != null;

          setState(() {
            _selectedStateId = billingDetailAddressData['state_id'];
            _selectedState = billingDetailAddressData['state']?['name'];

            if (_selectedState != null) {
              _stateController.text = _selectedState!;
            }
          });
        });

        if (_selectedCountryId != null) {
          await _fetchStates(_selectedCountryId!);
        }

        setState(() {
          _isLoading = false;
        });
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

        if (_selectedState != null && _states.contains(_selectedState)) {
          _stateController.text = _selectedState!;
        }
      });
    } catch (e) {
      setState(() {
        _isStateFieldVisible = false;
      });
    }
  }

  void _showCountryBottomSheet(TextEditingController countryController) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
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

                  _isStateFieldVisible = false;
                  _stateController.clear();
                  _selectedState = null;
                  _selectedStateId = null;
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

  void _showStateBottomSheet(TextEditingController stateController) {
    if (_isStateFieldVisible) {
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
  }

  void showCustomToast(BuildContext context, String message, bool isSuccess) {
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 1.0,
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

  String _firstNameError = '';
  String _lastNameError = '';
  String _companyError = '';
  String _emailError = '';
  String _phoneError = '';
  String _countryError = '';
  String _cityError = '';
  String _zipCodeError = '';
  String _isStateError = '';

  Future<void> _submitBillingInformation() async {
    String? _firstNameError;
    String? _lastNameError;
    String? _companyError;
    String? _emailError;
    String? _phoneError;
    String? _countryError;
    String? _cityError;
    String? _zipCodeError;
    String? _stateError;

    setState(() {
      _firstNameError =
          _isFirstNameValid ? null : "The first name field is required.";
      _lastNameError =
          _isLastNameValid ? null : "The last name field is required.";
      _companyError = _isCompanyValid ? null : "The company field is required.";
      _emailError = _isEmailValid ? null : "The email address is required.";
      _phoneError =
          _isPhoneNumberValid ? null : "The phone number field is required.";
      _countryError = _isCountryValid ? null : "The country field is required.";
      _cityError = _isCityValid ? null : "The city field is required.";
      _zipCodeError = _isZipCodeValid ? null : "The zip code is required.";
      _stateError = _isStateValid ? null : "The state is required.";
    });

    if (!_isFirstNameValid ||
        !_isLastNameValid ||
        !_isCompanyValid ||
        !_isEmailValid ||
        !_isPhoneNumberValid ||
        !_isCountryValid ||
        !_isCityValid ||
        !_isZipCodeValid ||
        !_isStateValid) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final billingId = _billingDetailData?['id'];

    if (token != null) {
      setState(() {
        _onPressLoading = true;
      });

      final Map<String, dynamic> billingData = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'company': _companyTitleController.text.trim(),
        'email': _emailAddressController.text.trim(),
        'phone': _numberController.text.trim(),
        'country': _selectedCountryId?.toString() ??
            _billingDetailData?['address']?['country_id']?.toString() ??
            '',
        'city': _cityController.text.trim(),
        'zipcode': _zipController.text.trim(),
        'address': _addressController.text.trim(),
        'state': _selectedStateId != null ? _selectedStateId.toString() : null,
      };

      try {
        Map<String, dynamic> response;

        if (_allFieldsFilled && billingId != null) {
          response = await updateBillingDetails(token, billingId, billingData);
        } else {
          response = await addBillingDetail(token, billingData);
        }

        if (response['status'] == 200) {
          showCustomToast(context,
              response['message'] ?? "Billing added successfully", true);
          setState(() {
            _onPressLoading = false;
          });
        } else if (response['status'] == 422) {
          final errors = response['errors'] as Map<String, dynamic>;

          String errorMessage = errors.entries.map((entry) {
            if (entry.value is String && entry.value != null) {
              return "${entry.key}: ${entry.value}";
            } else if (entry.value is List &&
                (entry.value as List).isNotEmpty) {
              return "${entry.key}: ${(entry.value as List).join(', ')}";
            } else {
              return "${entry.key}: No error details available";
            }
          }).join('\n');

          showCustomToast(context, errorMessage, false);

          setState(() {
            _onPressLoading = false;
          });
        } else {
          String message = response['message'] is String
              ? response['message']
              : 'An error occurred';
          showCustomToast(context, message, false);
          setState(() {
            _onPressLoading = false;
          });
        }
      } catch (e) {
        showCustomToast(
            context, 'Failed to submit billing information.', false);
        setState(() {
          _onPressLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

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
              color: AppColors.whiteColor,
              child: Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: AppBar(
                  backgroundColor: AppColors.whiteColor,
                  forceMaterialTransparency: true,
                  elevation: 0,
                  titleSpacing: 0,
                  title: Text(
                    'Datos de Facturación',
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      color: AppColors.blackColor,
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
                          size: 20, color: AppColors.blackColor),
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
              ? BillingInformationSkeleton()
              : SingleChildScrollView(
                  child: Container(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  CustomTextField(
                                    hint: 'Nombres',
                                    obscureText: false,
                                    controller: _firstNameController,
                                    focusNode: _firstNameFocusNode,
                                    hasError: !_isFirstNameValid,
                                  ),
                                  if (_firstNameError.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        _firstNameError,
                                        style: TextStyle(
                                            color: AppColors.redColor),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  CustomTextField(
                                    hint: 'Apellidos',
                                    obscureText: false,
                                    controller: _lastNameController,
                                    focusNode: _lastNameFocusNode,
                                    hasError: !_isLastNameValid,
                                  ),
                                  if (_lastNameError.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        _lastNameError,
                                        style: TextStyle(
                                            color: AppColors.redColor),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 15),
                        CustomTextField(
                          hint: 'Razón social',
                          mandatory: true,
                          controller: _companyTitleController,
                          focusNode: _companyTitleFocusNode,
                          hasError: !_isCompanyValid,
                        ),
                        if (_companyError.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _companyError,
                              style: TextStyle(color: AppColors.redColor),
                            ),
                          ),
                        SizedBox(height: 15),
                        CustomTextField(
                          hint: 'Correo electrónico',
                          controller: _emailAddressController,
                          hasError: !_isEmailValid,
                        ),
                        if (_emailError.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _emailError,
                              style: TextStyle(color: AppColors.redColor),
                            ),
                          ),
                        SizedBox(height: 15),
                        CustomTextField(
                          hint: 'Número de celular',
                          mandatory: true,
                          controller: _numberController,
                          focusNode: _numberFocusNode,
                          keyboardType: TextInputType.number,
                          hasError: !_isPhoneNumberValid,
                        ),
                        if (_phoneError.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _phoneError,
                              style: TextStyle(color: AppColors.redColor),
                            ),
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
                        if (_countryError.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _countryError,
                              style: TextStyle(color: AppColors.redColor),
                            ),
                          ),
                        if (_isStateFieldVisible) SizedBox(height: 16),
                        if (_isStateFieldVisible)
                          CustomTextField(
                            hint: 'Select State',
                            mandatory: true,
                            controller: _stateController,
                            absorbInput: true,
                            onTap: () {
                              _showStateBottomSheet(_stateController);
                            },
                          ),
                        if (_isStateFieldVisible)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 1.0),
                            child: Text(
                              _isStateError,
                              style: TextStyle(color: AppColors.redColor),
                            ),
                          ),
                        if (!_isStateFieldVisible) SizedBox(height: 16),
                        CustomTextField(
                          hint: 'Departamento',
                          mandatory: true,
                          controller: _cityController,
                          focusNode: _cityFocusNode,
                          hasError: !_isCityValid,
                        ),
                        if (_cityError.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _cityError,
                              style: TextStyle(color: AppColors.redColor),
                            ),
                          ),
                        SizedBox(height: 16),
                        CustomTextField(
                          hint: 'Código Postal',
                          mandatory: true,
                          controller: _zipController,
                          focusNode: _zipFocusNode,
                          hasError: !_isZipCodeValid,
                          keyboardType: TextInputType.number,
                        ),
                        if (_zipCodeError.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _zipCodeError,
                              style: TextStyle(color: AppColors.redColor),
                            ),
                          ),
                        SizedBox(height: 16),
                        CustomTextField(
                          hint: 'Dirección',
                          multiLine: true,
                          mandatory: false,
                          controller: _addressController,
                          focusNode: _addressFocusNode,
                        ),
                        SizedBox(height: 15),
                        Divider(
                          color: AppColors.dividerColor,
                        ),
                        SizedBox(height: 25),
                        Padding(
                          padding: const EdgeInsets.only(right: 15, left: 15),
                          child: ElevatedButton(
                            onPressed: _submitBillingInformation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              minimumSize: Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _allFieldsFilled
                                      ? 'Actualizar'
                                      : 'Guardar y Actualizar',
                                  style: TextStyle(
                                    fontSize: FontSize.scale(context, 16),
                                    color: AppColors.whiteColor,
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
                                      color: AppColors.whiteColor,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 15),
                      ],
                    ),
                  ),
                ),
        ),
      );
    });
  }
}
