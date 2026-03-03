import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/base_components/custom_snack_bar.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/components/bottom_sheet.dart';
import 'package:flutter_projects/view/tutor/component/dialog_component.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class EducationalDetailsScreen extends StatefulWidget {
  @override
  _EducationalDetailsScreenState createState() =>
      _EducationalDetailsScreenState();
}

class _EducationalDetailsScreenState extends State<EducationalDetailsScreen> {
  late double screenWidth;
  late double screenHeight;
  List<Education> _educationList = [];
  bool _isChecked = false;
  List<String> _countries = [];
  Map<int, String> _countryMap = {};
  int? _selectedCountryId;
  String? _selectedCountry;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCountries();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    setState(() {
      _educationList = authProvider.educationList;
    });
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

  void _showCountryBottomSheet(
      StateSetter setModalState, TextEditingController countryController) {
    showModalBottomSheet(
      backgroundColor: AppColors.sheetBackgroundColor,
      context: context,
      isScrollControlled: true,
      useRootNavigator: false,
      builder: (BuildContext context) {
        return BottomSheetComponent(
          title: "Select Country",
          items: _countries,
          selectedItem: _selectedCountry,
          onItemSelected: (selectedItem) {
            setModalState(() {
              _selectedCountry = selectedItem;
              countryController.text = selectedItem;
              _selectedCountryId = _countryMap.entries
                  .firstWhere((entry) => entry.value == selectedItem)
                  .key;
            });
          },
        );
      },
    );
  }

  void showCustomToast(BuildContext context, String message, bool isSuccess) {
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 5.0,
        left: 16.0,
        right: 16.0,
        child: CustomToast(
          message: message,
          isSuccess: isSuccess,
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  void _openBottomSheet(
      {Education? education, int? index, required bool isUpdate}) {
    final TextEditingController degreeController =
        TextEditingController(text: education != null ? education.degree : '');
    final TextEditingController instituteController = TextEditingController(
        text: education != null ? education.institute : '');
    final TextEditingController cityController =
        TextEditingController(text: education != null ? education.city : '');
    final TextEditingController descriptionController = TextEditingController(
        text: education != null ? education.description : '');
    final TextEditingController countryController = TextEditingController(
      text: education != null ? education.country : '',
    );
    DateTime? fromDate = education != null
        ? DateFormat('MMM dd, yyyy').parse(education.fromDate)
        : null;
    DateTime? toDate = education != null
        ? DateFormat('MMM dd, yyyy').parse(education.toDate)
        : null;

    bool _isChecked = education?.ongoing ?? false;

    if (education != null && education.country.isNotEmpty) {
      _selectedCountryId = _countryMap.entries
          .firstWhere((entry) => entry.value == education.country)
          .key;
    }

    Future<void> _selectDate(BuildContext context, DateTime? initialDate,
        Function(DateTime) onDateSelected) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: initialDate ?? DateTime.now(),
        firstDate: DateTime(1900),
        lastDate: DateTime(2100),
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: ColorScheme.light(
                primary: AppColors.primaryGreen,
                onPrimary: AppColors.whiteColor,
              ),
            ),
            child: child!,
          );
        },
      );
      if (picked != null) {
        onDateSelected(picked);
      }
    }

    showModalBottomSheet(
      backgroundColor: AppColors.sheetBackgroundColor,
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return GestureDetector(
              onTap: () {
                FocusScope.of(context).requestFocus(FocusNode());
              },
              child: Container(
                height: MediaQuery.of(context).size.height * 0.75,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                decoration: BoxDecoration(
                  color: AppColors.sheetBackgroundColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10.0),
                    topRight: Radius.circular(10.0),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4.0, vertical: 10.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 10),
                        child: Text(
                          'Agregar/editar detalles de la experiencia',
                          style: TextStyle(
                            fontSize: FontSize.scale(context, 18),
                            color: AppColors.blackColor,
                            fontFamily: 'SF-Pro-Text',
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.normal,
                          ),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                ),
                              ],
                              borderRadius: BorderRadius.circular(8.0),
                              color: AppColors.whiteColor,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 10),
                                TextField(
                                  cursorColor: AppColors.blackColor,
                                  controller: degreeController,
                                  decoration: InputDecoration(
                                    labelText: 'Agregar título de grado',
                                    labelStyle: TextStyle(
                                      fontSize: FontSize.scale(context, 16),
                                      color: AppColors.greyColor,
                                      fontFamily: 'SF-Pro-Text',
                                      fontWeight: FontWeight.w400,
                                      fontStyle: FontStyle.normal,
                                    ),
                                    border: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                          color: AppColors.dividerColor,
                                          width: 1.5),
                                    ),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                          color: AppColors.dividerColor,
                                          width: 1.5),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                          color: AppColors.dividerColor,
                                          width: 1.5),
                                    ),
                                    contentPadding: EdgeInsets.only(bottom: 8),
                                  ),
                                ),
                                SizedBox(height: 10),
                                TextField(
                                  cursorColor: AppColors.blackColor,
                                  controller: instituteController,
                                  decoration: InputDecoration(
                                    labelText: 'Agregar nombre de institución',
                                    labelStyle: TextStyle(
                                      fontSize: FontSize.scale(context, 16),
                                      color: AppColors.greyColor,
                                      fontFamily: 'SF-Pro-Text',
                                      fontWeight: FontWeight.w400,
                                      fontStyle: FontStyle.normal,
                                    ),
                                    border: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                          color: AppColors.dividerColor,
                                          width: 1.5),
                                    ),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                          color: AppColors.dividerColor,
                                          width: 1.5),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                          color: AppColors.dividerColor,
                                          width: 1.5),
                                    ),
                                    contentPadding: EdgeInsets.only(bottom: 8),
                                  ),
                                ),
                                SizedBox(height: 10),
                                TextField(
                                  cursorColor: AppColors.blackColor,
                                  controller: cityController,
                                  decoration: InputDecoration(
                                    labelText: 'Agregar nombre de ciudad',
                                    labelStyle: TextStyle(
                                      fontSize: FontSize.scale(context, 16),
                                      color: AppColors.greyColor,
                                      fontFamily: 'SF-Pro-Text',
                                      fontWeight: FontWeight.w400,
                                      fontStyle: FontStyle.normal,
                                    ),
                                    border: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                          color: AppColors.dividerColor,
                                          width: 1.5),
                                    ),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                          color: AppColors.dividerColor,
                                          width: 1.5),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                          color: AppColors.dividerColor,
                                          width: 1.5),
                                    ),
                                    contentPadding: EdgeInsets.only(bottom: 8),
                                  ),
                                ),
                                SizedBox(height: 10),
                                GestureDetector(
                                  onTap: () {
                                    _showCountryBottomSheet(
                                        setModalState, countryController);
                                  },
                                  child: AbsorbPointer(
                                    child: TextField(
                                      cursorColor: AppColors.blackColor,
                                      controller: countryController,
                                      decoration: InputDecoration(
                                        labelText: 'Selecciona un departamento',
                                        labelStyle: TextStyle(
                                          fontSize: FontSize.scale(context, 16),
                                          color: AppColors.greyColor,
                                          fontFamily: 'SF-Pro-Text',
                                          fontWeight: FontWeight.w400,
                                          fontStyle: FontStyle.normal,
                                        ),
                                        border: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                              color: AppColors.dividerColor,
                                              width: 1.5),
                                        ),
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                              color: AppColors.dividerColor,
                                              width: 1.5),
                                        ),
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                              color: AppColors.dividerColor,
                                              width: 1.5),
                                        ),
                                        contentPadding:
                                            EdgeInsets.only(bottom: 8),
                                        suffixIcon: Icon(
                                          Icons.keyboard_arrow_down,
                                          size: 25,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10),
                                GestureDetector(
                                  onTap: () => _selectDate(context, fromDate,
                                      (selectedDate) {
                                    setModalState(() {
                                      fromDate = selectedDate;
                                    });
                                  }),
                                  child: AbsorbPointer(
                                    child: TextField(
                                      cursorColor: AppColors.blackColor,
                                      controller: TextEditingController(
                                        text: fromDate != null
                                            ? DateFormat('MMM dd, yyyy')
                                                .format(fromDate!)
                                            : '',
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Fecha Inicio',
                                        labelStyle: TextStyle(
                                          fontSize: FontSize.scale(context, 16),
                                          color: AppColors.greyColor,
                                          fontFamily: 'SF-Pro-Text',
                                          fontWeight: FontWeight.w400,
                                          fontStyle: FontStyle.normal,
                                        ),
                                        border: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                              color: AppColors.dividerColor,
                                              width: 1.5),
                                        ),
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                              color: AppColors.dividerColor,
                                              width: 1.5),
                                        ),
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                              color: AppColors.dividerColor,
                                              width: 1.5),
                                        ),
                                        contentPadding:
                                            EdgeInsets.only(bottom: 8),
                                        suffixIcon: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14),
                                          child: SvgPicture.asset(
                                            AppImages.dateTimeIcon,
                                            width: 14,
                                            height: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10),
                                GestureDetector(
                                  onTap: () => _selectDate(context, toDate,
                                      (selectedDate) {
                                    setModalState(() {
                                      toDate = selectedDate;
                                    });
                                  }),
                                  child: AbsorbPointer(
                                    child: TextField(
                                      cursorColor: AppColors.blackColor,
                                      controller: TextEditingController(
                                        text: toDate != null
                                            ? DateFormat('MMM dd, yyyy')
                                                .format(toDate!)
                                            : '',
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Fecha Fin',
                                        labelStyle: TextStyle(
                                          fontSize: FontSize.scale(context, 16),
                                          color: AppColors.greyColor,
                                          fontFamily: 'SF-Pro-Text',
                                          fontWeight: FontWeight.w400,
                                          fontStyle: FontStyle.normal,
                                        ),
                                        border: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                              color: AppColors.dividerColor,
                                              width: 1.5),
                                        ),
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                              color: AppColors.dividerColor,
                                              width: 1.5),
                                        ),
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                              color: AppColors.dividerColor,
                                              width: 1.5),
                                        ),
                                        contentPadding:
                                            EdgeInsets.only(bottom: 8),
                                        suffixIcon: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14),
                                          child: SvgPicture.asset(
                                            AppImages.dateTimeIcon,
                                            width: 14,
                                            height: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Transform.translate(
                                      offset: Offset(-10, -10),
                                      child: Transform.scale(
                                        scale: 1.3,
                                        child: Checkbox(
                                          value: _isChecked,
                                          checkColor: AppColors.whiteColor,
                                          activeColor: AppColors.primaryGreen,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(5.0),
                                          ),
                                          side: BorderSide(
                                            color: AppColors.dividerColor,
                                            width: 1.5,
                                          ),
                                          onChanged: (bool? value) {
                                            setModalState(() {
                                              _isChecked = value ?? false;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Transform.translate(
                                        offset: Offset(-12, 0),
                                        child: Text(
                                          'Este título/curso está actualmente en curso.',
                                          style: TextStyle(
                                            fontSize:
                                                FontSize.scale(context, 16),
                                            color: AppColors.greyColor,
                                            fontWeight: FontWeight.w400,
                                            fontFamily: "SF-Pro-Text",
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                Divider(
                                  color: AppColors.dividerColor,
                                  thickness: 2,
                                  height: 1,
                                  indent: 2.0,
                                  endIndent: 2.0,
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                TextField(
                                  cursorColor: AppColors.blackColor,
                                  controller: descriptionController,
                                  maxLines: 5,
                                  decoration: InputDecoration(
                                    labelText: 'Descripción',
                                    labelStyle: TextStyle(
                                      fontSize: FontSize.scale(context, 16),
                                      color: AppColors.greyColor,
                                      fontFamily: 'SF-Pro-Text',
                                      fontWeight: FontWeight.w400,
                                      fontStyle: FontStyle.normal,
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.only(bottom: 8),
                                    alignLabelWithHint: true,
                                  ),
                                ),
                                SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: () async {
                                    if (degreeController.text.isNotEmpty &&
                                        instituteController.text.isNotEmpty &&
                                        fromDate != null &&
                                        (toDate != null || _isChecked) &&
                                        _selectedCountryId != null &&
                                        cityController.text.isNotEmpty) {
                                      if (toDate == null ||
                                          fromDate!.isBefore(toDate!)) {
                                        final authProvider =
                                            Provider.of<AuthProvider>(context,
                                                listen: false);
                                        final token = authProvider.token;

                                        final Map<String, dynamic>
                                            educationData = {
                                          "course_title": degreeController.text,
                                          "institute_name":
                                              instituteController.text,
                                          "country": _selectedCountryId,
                                          "city": cityController.text,
                                          "start_date":
                                              DateFormat('MMM dd, yyyy')
                                                  .format(fromDate!),
                                          "end_date": toDate != null
                                              ? DateFormat('MMM dd, yyyy')
                                                  .format(toDate!)
                                              : '',
                                          "ongoing": _isChecked ? "1" : "0",
                                          "description":
                                              descriptionController.text,
                                        };

                                        try {
                                          setState(() {
                                            _isLoading = true;
                                          });

                                          final response = isUpdate
                                              ? await updateEducation(token!,
                                                  education!.id, educationData)
                                              : await addEducation(
                                                  token!, educationData);

                                          if (response['status'] == 200) {
                                            final newEducation = Education(
                                              id: response['data']['id'] ??
                                                  'N/A',
                                              degree: response['data']
                                                      ['course_title'] ??
                                                  'N/A',
                                              institute: response['data']
                                                      ['institute_name'] ??
                                                  'N/A',
                                              country: _countryMap[
                                                      response['data']
                                                          ['country_id']] ??
                                                  'Unknown Country',
                                              city: response['data']['city'] ??
                                                  'Unknown City',
                                              fromDate: response['data']
                                                      ['start_date'] ??
                                                  '',
                                              toDate: response['data']
                                                      ['end_date'] ??
                                                  '',
                                              description: response['data']
                                                      ['description'] ??
                                                  '',
                                            );

                                            if (isUpdate) {
                                              authProvider.updateEducation(
                                                  index!, newEducation);
                                            } else {
                                              await authProvider
                                                  .saveEducation(newEducation);
                                            }

                                            Navigator.pop(context);

                                            showCustomToast(
                                              context,
                                              response['message'],
                                              true,
                                            );
                                          } else {
                                            if (response
                                                    .containsKey('errors') &&
                                                response['errors'] != null) {
                                              final errors = response['errors'];
                                              String errorMessage = '';

                                              errors.forEach((key, value) {
                                                if (value is List) {
                                                  errorMessage +=
                                                      value.join(', ') + '\n';
                                                } else {
                                                  errorMessage +=
                                                      value.toString() + '\n';
                                                }
                                              });

                                              showCustomToast(
                                                context,
                                                errorMessage.trim(),
                                                false,
                                              );
                                            } else {
                                              showCustomToast(
                                                context,
                                                response['message'] ??
                                                    "An unknown error occurred.",
                                                false,
                                              );
                                            }
                                          }
                                        } catch (error) {
                                          showCustomToast(
                                            context,
                                            "Failed to add/update education: ${error.toString()}",
                                            false,
                                          );
                                        } finally {
                                          setState(() {
                                            _isLoading = false;
                                          });
                                        }
                                      } else {
                                        showCustomToast(
                                          context,
                                          "End date must be after start date.",
                                          false,
                                        );
                                      }
                                    } else {
                                      showCustomToast(
                                        context,
                                        "Please fill all required fields.",
                                        false,
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryGreen,
                                    minimumSize: Size(double.infinity, 45),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Save & Update',
                                        style: TextStyle(
                                          fontSize: FontSize.scale(context, 16),
                                          color: AppColors.whiteColor,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'SF-Pro-Text',
                                          fontStyle: FontStyle.normal,
                                        ),
                                      ),
                                      if (_isLoading) ...[
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
                                SizedBox(height: 20),
                                Text(
                                  'Click "Save & Update" to update your educational details',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: FontSize.scale(context, 14),
                                    color: AppColors.greyColor.withOpacity(0.7),
                                    fontFamily: 'SF-Pro-Text',
                                    fontWeight: FontWeight.w400,
                                    fontStyle: FontStyle.normal,
                                  ),
                                ),
                                SizedBox(
                                  height: 10,
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showRemoveDialog(BuildContext context, int index) {
    if (index < 0 || index >= _educationList.length) {
      showCustomToast(
          context, "Invalid item selection. Please try again.", false);
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return DialogComponent(
          onRemove: () async {
            final authProvider =
                Provider.of<AuthProvider>(context, listen: false);
            final token = authProvider.token;
            final educationId = _educationList[index].id;
            String message = '';
            bool isSuccess = false;

            if (token != null) {
              try {
                final response = await deleteEducation(token, educationId);

                if (response['status'] == 200) {
                  await authProvider.removeEducation(index);
                  message =
                      response['message'] ?? 'Education removed successfully';
                  isSuccess = true;
                } else if (response['status'] == 404) {
                  await authProvider.removeEducation(index);
                  message = "Education not found. Removed from list.";
                } else {
                  message =
                      response['message'] ?? "Failed to delete education.";
                }
              } catch (error) {
                message = "An error occurred while deleting education.";
              }
            } else {
              message = "Authorization token is missing.";
            }

            if (mounted) {
              showCustomToast(context, message, isSuccess);
            } else {
              showCustomToast(context, message, isSuccess);
            }
          },
          title: 'Are you sure?',
          message: "You're going to remove this item.\nThis cannot be undone.",
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    final authProvider = Provider.of<AuthProvider>(context);
    final educationList = authProvider.educationList;

    return Scaffold(
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
                'Formación Académica',
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
      body: Column(
        children: [
          if (educationList.isEmpty)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      AppImages.emptyEducation,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                    SizedBox(height: 15),
                    Text(
                      '¡Aún no se ha añadido ningún registro!',
                      style: TextStyle(
                        fontSize: FontSize.scale(context, 16),
                        color: AppColors.blackColor.withOpacity(0.7),
                        fontFamily: 'SF-Pro-Text',
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'No hay registros disponibles para mostrar en este momento.\nPresione el botón a continuación para agregar uno nuevo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: FontSize.scale(context, 12),
                        color: AppColors.blackColor.withOpacity(0.7),
                        fontFamily: 'SF-Pro-Text',
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => _openBottomSheet(isUpdate: false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      child: Text(
                        'Agregar nuevo',
                        style: TextStyle(
                          fontSize: FontSize.scale(context, 16),
                          color: AppColors.whiteColor,
                          fontFamily: 'SF-Pro-Text',
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  SizedBox(
                    height: 20,
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 12.0),
                      itemCount: educationList.length,
                      itemBuilder: (context, index) {
                        final education = educationList[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.whiteColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            child: ListTile(
                              title: Text(
                                education.institute.isNotEmpty
                                    ? education.institute
                                    : "Institute not available",
                                style: TextStyle(
                                  fontSize: FontSize.scale(context, 12),
                                  color: AppColors.greyColor,
                                  fontFamily: 'SF-Pro-Text',
                                  fontWeight: FontWeight.w400,
                                  fontStyle: FontStyle.normal,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    education.degree.isNotEmpty
                                        ? education.degree
                                        : "Degree not available",
                                    style: TextStyle(
                                      fontSize: FontSize.scale(context, 15),
                                      color: AppColors.blackColor,
                                      fontFamily: 'SF-Pro-Text',
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FontStyle.normal,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 4,
                                  ),
                                  Row(
                                    children: [
                                      SvgPicture.asset(
                                        AppImages.locationIcon,
                                        width: 14,
                                        height: 14,
                                        color: AppColors.greyColor,
                                      ),
                                      SizedBox(
                                        width: 8,
                                      ),
                                      Text(
                                        education.country.isNotEmpty &&
                                                education.city.isNotEmpty
                                            ? '${education.country}, ${education.city}'
                                            : "Location not available",
                                        style: TextStyle(
                                          fontSize: FontSize.scale(context, 12),
                                          color: AppColors.greyColor,
                                          fontFamily: 'SF-Pro-Text',
                                          fontWeight: FontWeight.w400,
                                          fontStyle: FontStyle.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: 4,
                                  ),
                                  Row(
                                    children: [
                                      SvgPicture.asset(
                                        AppImages.dateIcon,
                                        width: 14,
                                        height: 14,
                                      ),
                                      SizedBox(
                                        width: 8,
                                      ),
                                      Text(
                                        '${education.fromDate} - ${education.toDate}',
                                        style: TextStyle(
                                          fontSize: FontSize.scale(context, 12),
                                          color: AppColors.greyColor,
                                          fontFamily: 'SF-Pro-Text',
                                          fontWeight: FontWeight.w400,
                                          fontStyle: FontStyle.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 14),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      OutlinedButton(
                                        onPressed: () {
                                          _openBottomSheet(
                                              education: education,
                                              isUpdate: true,
                                              index: index);
                                        },
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: AppColors.whiteColor,
                                          side: BorderSide(
                                            color: AppColors.greyColor,
                                            width: 0.1,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 60),
                                        ),
                                        child: Text(
                                          "Edit",
                                          style: TextStyle(
                                            fontSize:
                                                FontSize.scale(context, 16),
                                            color: AppColors.greyColor,
                                            fontFamily: 'SF-Pro-Text',
                                            fontWeight: FontWeight.w500,
                                            fontStyle: FontStyle.normal,
                                          ),
                                        ),
                                      ),
                                      OutlinedButton(
                                        onPressed: () {
                                          _showRemoveDialog(context, index);
                                        },
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor:
                                              AppColors.redBackgroundColor,
                                          side: BorderSide(
                                            color: AppColors.redBorderColor,
                                            width: 2,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 55),
                                        ),
                                        child: Text(
                                          "Delete",
                                          style: TextStyle(
                                            fontSize:
                                                FontSize.scale(context, 14),
                                            color: AppColors.redColor,
                                            fontFamily: 'SF-Pro-Text',
                                            fontWeight: FontWeight.w500,
                                            fontStyle: FontStyle.normal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: 14,
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundColor,
                      border: Border(
                        top: BorderSide(
                            width: 1.0, color: AppColors.dividerColor),
                      ),
                    ),
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
                    child: ElevatedButton(
                      onPressed: () => _openBottomSheet(isUpdate: false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      child: Text(
                        'Add new',
                        style: TextStyle(
                          fontSize: FontSize.scale(context, 16),
                          color: AppColors.whiteColor,
                          fontFamily: 'SF-Pro-Text',
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.normal,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class Education {
  final int id;
  final String degree;
  final String institute;
  final String country;
  final String city;
  final String fromDate;
  final String toDate;
  final String description;
  final bool ongoing;

  Education({
    required this.id,
    required this.degree,
    required this.institute,
    required this.country,
    required this.city,
    required this.fromDate,
    required this.toDate,
    required this.description,
    this.ongoing = false,
  });

  factory Education.fromJson(Map<String, dynamic> json) {
    return Education(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']) ?? 0,
      degree: json['degree'] as String? ?? '',
      institute: json['institute'] as String? ?? '',
      country: json['country'] as String? ?? '',
      city: json['city'] as String? ?? '',
      fromDate: json['fromDate'] as String? ?? '',
      toDate: json['toDate'] as String? ?? '',
      description: json['description'] as String? ?? '',
      ongoing: json['ongoing'] == '1' ? true : false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'degree': degree,
      'institute': institute,
      'country': country,
      'city': city,
      'fromDate': fromDate,
      'toDate': toDate,
      'description': description,
      'ongoing': ongoing ? "1" : "0",
    };
  }
}
