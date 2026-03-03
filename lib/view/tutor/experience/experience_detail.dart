import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/base_components/custom_snack_bar.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/components/bottom_sheet.dart';
import 'package:flutter_projects/view/insights/component/custom_field.dart';
import 'package:flutter_projects/view/tutor/component/dialog_component.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ExperienceDetailsScreen extends StatefulWidget {
  @override
  _ExperienceDetailsScreenState createState() =>
      _ExperienceDetailsScreenState();
}

class _ExperienceDetailsScreenState extends State<ExperienceDetailsScreen> {
  List<String> _countries = [];
  Map<int, String> _countryMap = {};
  int? _selectedCountryId;
  String? _selectedCountry;
  bool _isLoading = false;
  late double screenWidth;
  late double screenHeight;

  final Map<String, String> _employmentTypeMap = {
    "full_time": 'Full Time',
    "self_employed": 'Self Employed',
    "contract": 'Contract',
    "part_time": 'Part Time',
  };

  String? _selectedEmploymentTypeId;

  @override
  void initState() {
    super.initState();
    _fetchCountries();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.loadExperiences();
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

  void _openBottomSheet(
      {Experience? experience, int? index, required bool isUpdate}) {
    final TextEditingController jobTitleController = TextEditingController(
      text: experience != null ? experience.jobTitle : '',
    );
    final TextEditingController companyController = TextEditingController(
      text: experience != null ? experience.company : '',
    );
    final TextEditingController descriptionController = TextEditingController(
      text: experience != null ? experience.description : '',
    );

    DateTime? fromDate = experience != null
        ? DateFormat('MMM dd, yyyy').parse(experience.fromDate)
        : null;
    DateTime? toDate = experience != null
        ? DateFormat('MMM dd, yyyy').parse(experience.toDate)
        : null;

    if (experience != null) {
      _selectedEmploymentTypeId = experience.employmentType;
      _selectedCountryId = _countryMap.entries
          .firstWhere((entry) => entry.value == experience.country,
              orElse: () => MapEntry(0, "Unknown"))
          .key;
    }

    final TextEditingController employmentTypeController =
        TextEditingController(
      text: experience != null
          ? _employmentTypeMap[experience.employmentType] ?? ''
          : '',
    );
    final TextEditingController countryController = TextEditingController(
      text: experience != null ? experience.country : '',
    );
    final TextEditingController cityController = TextEditingController(
      text: experience != null ? experience.city : '',
    );
    final TextEditingController locationTypeController = TextEditingController(
      text: experience != null ? capitalize(experience.location) : '',
    );

    bool _isChecked = experience?.isCurrent ?? false;

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
                      horizontal: 10.0, vertical: 10.0),
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
                        padding: const EdgeInsets.all(16.0),
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
                                  color: AppColors.greyColor.withOpacity(0.1),
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
                                CustomField(
                                  controller: jobTitleController,
                                  labelText: 'Cargo Ocupado',
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'This field is required';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 10),
                                CustomField(
                                  controller: companyController,
                                  labelText: 'Nombre de Institución',
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'This field is required';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 10),
                                TextField(
                                  cursorColor: AppColors.blackColor,
                                  controller: employmentTypeController,
                                  onTap: () {
                                    _openEmploymentTypeBottomSheet(
                                        context,
                                        setModalState,
                                        employmentTypeController);
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Tipo de empleo',
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
                                    suffixIcon: Icon(
                                      Icons.keyboard_arrow_down,
                                      size: 25,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10),
                                TextField(
                                  cursorColor: AppColors.blackColor,
                                  controller: locationTypeController,
                                  onTap: () {
                                    _openCompanyTypeBottomSheet(context,
                                        setModalState, locationTypeController);
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Modalidad de Trabajo',
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
                                    suffixIcon: Icon(
                                      Icons.keyboard_arrow_down,
                                      size: 25,
                                      color: Colors.grey,
                                    ),
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
                                        labelText: 'Seleccionar País',
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
                                CustomField(
                                  controller: cityController,
                                  labelText: 'Ciudad',
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'This field is required';
                                    }
                                    return null;
                                  },
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
                                        labelText: 'Fecha de inicio',
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
                                        labelText: 'Fecha fin',
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
                                        offset: Offset(-12, -10),
                                        child: Text(
                                          'Actualmente trabajo en este rol.',
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
                                Divider(
                                  color: AppColors.dividerColor,
                                  thickness: 2,
                                  height: 1,
                                  indent: 2.0,
                                  endIndent: 2.0,
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
                                    contentPadding: EdgeInsets.only(bottom: 10),
                                    alignLabelWithHint: true,
                                  ),
                                ),
                                SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: () async {
                                    if (jobTitleController.text.isNotEmpty &&
                                        companyController.text.isNotEmpty &&
                                        fromDate != null &&
                                        (toDate != null || _isChecked)) {
                                      final authProvider =
                                          Provider.of<AuthProvider>(context,
                                              listen: false);
                                      final token = authProvider.token;

                                      if (_selectedCountryId == null ||
                                          _selectedCountryId == 0) {
                                        showCustomToast(
                                            context,
                                            "Please select a valid country.",
                                            false);
                                        return;
                                      }

                                      String? employmentTypeKey;
                                      _employmentTypeMap.forEach((key, value) {
                                        if (value ==
                                            employmentTypeController.text) {
                                          employmentTypeKey = key;
                                        }
                                      });

                                      if (employmentTypeKey == null) {
                                        showCustomToast(
                                            context,
                                            "Please select a valid employment type.",
                                            false);
                                        return;
                                      }

                                      final Map<String, dynamic>
                                          experienceData = {
                                        "title": jobTitleController.text,
                                        "employment_type": employmentTypeKey,
                                        "company": companyController.text,
                                        "location": locationTypeController.text
                                            .toLowerCase(),
                                        "country":
                                            _selectedCountryId!.toString(),
                                        "city": cityController.text,
                                        "start_date": DateFormat('yyyy-MM-dd')
                                            .format(fromDate!),
                                        "end_date": toDate != null
                                            ? DateFormat('yyyy-MM-dd')
                                                .format(toDate!)
                                            : '',
                                        "is_current": _isChecked ? "1" : "0",
                                        "description":
                                            descriptionController.text,
                                      };

                                      try {
                                        setState(() {
                                          _isLoading = true;
                                        });
                                        final response = isUpdate
                                            ? await updateExperience(token!,
                                                experience!.id, experienceData)
                                            : await addExperience(
                                                token!, experienceData);

                                        if (response['status'] == 200) {
                                          final responseData = response['data'];
                                          final employmentType =
                                              responseData['employment_type'];
                                          final countryId =
                                              responseData['country_id'];
                                          final countryName = _countryMap[
                                                  int.parse(countryId)] ??
                                              "Unknown Country";

                                          final newExperience = Experience(
                                            id: responseData['id'] ?? 0,
                                            jobTitle:
                                                responseData['title'] ?? '',
                                            company:
                                                responseData['company'] ?? '',
                                            country: countryName,
                                            city: responseData['city'] ??
                                                'Unknown City',
                                            employmentType: employmentType,
                                            location:
                                                responseData['location'] ?? '',
                                            fromDate:
                                                responseData['start_date'] ??
                                                    '',
                                            toDate:
                                                responseData['end_date'] ?? '',
                                            description:
                                                responseData['description'] ??
                                                    '',
                                          );

                                          if (isUpdate) {
                                            authProvider.updateExperienceList(
                                                newExperience);
                                          } else {
                                            await authProvider
                                                .saveExperience(newExperience);
                                          }

                                          Navigator.pop(context);

                                          showCustomToast(
                                            context,
                                            response['message'],
                                            true,
                                          );
                                        } else {
                                          final errors = response['errors'];
                                          if (errors != null &&
                                              errors.isNotEmpty) {
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
                                          "Failed to add/update experience: ${error.toString()}",
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
                                SizedBox(height: 30),
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

  void _openEmploymentTypeBottomSheet(BuildContext context,
      StateSetter setModalState, TextEditingController controller) {
    showModalBottomSheet(
      backgroundColor: AppColors.sheetBackgroundColor,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              height: screenHeight * 0.35,
              decoration: BoxDecoration(
                color: AppColors.sheetBackgroundColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10.0),
                  topRight: Radius.circular(10.0),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
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
                      padding: const EdgeInsets.all(10.0),
                      child: Text(
                        'Select Employment Type',
                        style: TextStyle(
                          fontSize: FontSize.scale(context, 18),
                          color: AppColors.blackColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 10),
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
                        children: _employmentTypeMap.entries.map((entry) {
                          return Column(
                            children: [
                              _buildRadioTile(
                                context: context,
                                value: entry.value,
                                groupValue: controller.text,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedEmploymentTypeId = entry.key;
                                    controller.text = value!;
                                    Navigator.pop(context);
                                  });
                                },
                              ),
                              Divider(
                                color: AppColors.dividerColor,
                                thickness: 1,
                                height: 1,
                                indent: 16.0,
                                endIndent: 16.0,
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openCompanyTypeBottomSheet(BuildContext context,
      StateSetter setModalState, TextEditingController controller) {
    final List<String> _locationTypes = ['remote', 'onsite', 'hybrid'];

    showModalBottomSheet(
      backgroundColor: AppColors.sheetBackgroundColor,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              height: screenHeight * 0.35,
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
                    horizontal: 10.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
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
                      padding: const EdgeInsets.all(10.0),
                      child: Text(
                        'Select Location Type',
                        style: TextStyle(
                          fontSize: FontSize.scale(context, 18),
                          color: AppColors.blackColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 10),
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
                            children:
                                List.generate(_locationTypes.length, (index) {
                              final locationType = _locationTypes[index];
                              return Column(
                                children: [
                                  _buildRadioTile(
                                    context: context,
                                    value: capitalize(locationType),
                                    groupValue: controller.text,
                                    onChanged: (value) {
                                      setState(() {
                                        controller.text = value!;
                                        Navigator.pop(context);
                                      });
                                    },
                                  ),
                                  if (index != _locationTypes.length - 1)
                                    Divider(
                                      color: AppColors.dividerColor,
                                      thickness: 1,
                                      height: 1,
                                      indent: 16.0,
                                      endIndent: 16.0,
                                    ),
                                ],
                              );
                            }),
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
      },
    );
  }

  Widget _buildRadioTile({
    required BuildContext context,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    return ListTile(
      title: Text(value),
      trailing: Radio<String>(
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        activeColor: AppColors.primaryGreen,
        fillColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primaryGreen;
            }
            return AppColors.greyColor;
          },
        ),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16),
      onTap: () {
        onChanged(value);
      },
    );
  }

  String capitalize(String input) {
    if (input.isEmpty) return input;
    return input.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  void _showRemoveDialog(BuildContext context, int index) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (index >= 0 && index < authProvider.experienceList.length) {
      final experienceId = authProvider.experienceList[index].id;

      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return DialogComponent(
            onRemove: () async {
              if (token != null) {
                try {
                  final response = await deleteExperience(token, experienceId);

                  if (response['status'] == 200) {
                    final message = response['message'] ??
                        'Experience deleted successfully';

                    if (context.mounted) {
                      showCustomToast(context, message, true);
                    }
                    await authProvider.removeExperience(index);
                  } else {
                    if (context.mounted) {
                      showCustomToast(
                        context,
                        "Failed to delete experience: ${response['message']}",
                        false,
                      );
                    }
                  }
                } catch (error) {
                  if (context.mounted) {
                    showCustomToast(
                      context,
                      "Error occurred: $error",
                      false,
                    );
                  }
                }
              } else {
                if (context.mounted) {
                  showCustomToast(
                    context,
                    "Authentication error. Please login again.",
                    false,
                  );
                }
              }
            },
            title: 'Are you sure?',
            message: "You're going to remove this item.\nThis cannot be undone",
          );
        },
      );
    } else {
      if (context.mounted) {
        showCustomToast(
          context,
          "Invalid operation. Please try again.",
          false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    final authProvider = Provider.of<AuthProvider>(context);

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
                'Experiencia Laboral',
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
          if (authProvider.experienceList.isEmpty)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      AppImages.emptyExperience,
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
                        color: AppColors.greyColor,
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
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return ListView.builder(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.0, vertical: 20.0),
                    itemCount: authProvider.experienceList.length,
                    itemBuilder: (context, index) {
                      final experienceList = authProvider.experienceList[index];

                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.whiteColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              experienceList.jobTitle,
                              style: TextStyle(
                                fontSize: FontSize.scale(context, 12),
                                color: AppColors.greyColor,
                                fontFamily: 'SF-Pro-Text',
                                fontWeight: FontWeight.w400,
                                fontStyle: FontStyle.normal,
                              ),
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 4,
                              ),
                              Text(
                                experienceList.company,
                                style: TextStyle(
                                  fontSize: FontSize.scale(context, 15),
                                  color: AppColors.blackColor,
                                  fontFamily: 'SF-Pro-Text',
                                  fontWeight: FontWeight.w500,
                                  fontStyle: FontStyle.normal,
                                ),
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  SvgPicture.asset(
                                    AppImages.dateIcon,
                                    width: 14,
                                    height: 14,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '${experienceList.fromDate} - ${experienceList.toDate}',
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
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  SvgPicture.asset(
                                    AppImages.locationIcon,
                                    width: 14,
                                    height: 14,
                                    color: AppColors.greyColor,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    experienceList.country.isNotEmpty &&
                                            experienceList.city.isNotEmpty
                                        ? '${experienceList.country}, ${experienceList.city}'
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
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  SvgPicture.asset(
                                    AppImages.briefcase,
                                    width: 14,
                                    height: 14,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    _employmentTypeMap[
                                            experienceList.employmentType] ??
                                        "Unknown",
                                    style: TextStyle(
                                      fontSize: FontSize.scale(context, 12),
                                      color: AppColors.greyColor,
                                      fontFamily: 'SF-Pro-Text',
                                      fontWeight: FontWeight.w400,
                                      fontStyle: FontStyle.normal,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  SvgPicture.asset(
                                    AppImages.locationIcon,
                                    width: 14,
                                    height: 14,
                                    color: AppColors.greyColor,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    experienceList.location[0].toUpperCase() +
                                        experienceList.location
                                            .substring(1)
                                            .toLowerCase(),
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
                                        experience: experienceList,
                                        isUpdate: true,
                                        index: index,
                                      );
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
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 65),
                                    ),
                                    child: Text(
                                      "Edit",
                                      style: TextStyle(
                                        fontSize: FontSize.scale(context, 16),
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
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 60),
                                    ),
                                    child: Text(
                                      "Delete",
                                      style: TextStyle(
                                        fontSize: FontSize.scale(context, 14),
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
                                height: 10,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          if (authProvider.experienceList.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundColor,
                border: Border(
                  top: BorderSide(width: 1.0, color: AppColors.dividerColor),
                ),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
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
    );
  }
}

class Experience {
  final int id;
  final String jobTitle;
  final String company;
  final String location;
  final String country;
  final String city;
  final String employmentType;
  final String fromDate;
  final String toDate;
  final String description;
  final bool isCurrent;

  Experience({
    required this.id,
    required this.jobTitle,
    required this.company,
    required this.location,
    required this.country,
    required this.city,
    required this.employmentType,
    required this.fromDate,
    required this.toDate,
    required this.description,
    this.isCurrent = false,
  });

  factory Experience.fromJson(Map<String, dynamic> json) {
    return Experience(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']) ?? 0,
      jobTitle: json['title'] as String? ?? '',
      company: json['company'] as String? ?? '',
      country: json['country'] as String? ?? '',
      city: json['city'] as String? ?? '',
      employmentType: json['employment_type'] as String ?? '',
      location: json['location'] as String? ?? '',
      fromDate: json['fromDate'] as String? ?? '',
      toDate: json['toDate'] as String? ?? '',
      description: json['description'] as String? ?? '',
      isCurrent: json['is_current'] == '1' ? true : false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': jobTitle,
      'company': company,
      'location': location,
      'country': country,
      'city': city,
      'employment_type': employmentType,
      'fromDate': fromDate,
      'toDate': toDate,
      'description': description,
      'is_current': isCurrent ? "1" : "0",
    };
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
  Future.delayed(const Duration(seconds: 3), () {
    overlayEntry.remove();
  });
}
