import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/base_components/custom_snack_bar.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/tutor/component/dialog_component.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../provider/auth_provider.dart';

class CertificateDetail extends StatefulWidget {
  @override
  _CertificateDetailState createState() => _CertificateDetailState();
}

class _CertificateDetailState extends State<CertificateDetail> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  late double screenWidth;
  late double screenHeight;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.loadCertificates();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _viewProfilePhoto() async {
    if (_selectedImage != null) {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Foto de Perfil'),
            content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.file(_selectedImage!),
                    SizedBox(height: 10),
                    Text(
                      'This is your uploaded profile photo.',
                      style: TextStyle(
                        fontSize: FontSize.scale(context, 14),
                        color: AppColors.blackColor,
                      ),
                    ),
                  ],
                );
              },
            ),
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
      await showDialog(
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

  void _openBottomSheet(
      {Certificate? certificate, int? index, required bool isUpdate}) {
    final TextEditingController jobTitleController = TextEditingController(
      text: certificate != null ? certificate.jobTitle : '',
    );
    final TextEditingController companyController = TextEditingController(
      text: certificate != null ? certificate.company : '',
    );
    final TextEditingController descriptionController = TextEditingController(
      text: certificate != null ? certificate.description : '',
    );

    DateTime? fromDate = certificate != null
        ? DateFormat('yyyy-MM-dd').parse(certificate.fromDate)
        : null;
    DateTime? toDate = certificate != null
        ? DateFormat('yyyy-MM-dd').parse(certificate.toDate)
        : null;

    final TextEditingController employmentTypeController =
        TextEditingController(
      text: certificate != null ? certificate.employmentType : '',
    );
    final TextEditingController companyTypeController = TextEditingController(
      text: certificate != null ? certificate.companyType : '',
    );

    File? _selectedImage = isUpdate && certificate?.imagePath != null
        ? File(certificate!.imagePath!)
        : null;

    Future<void> _selectDate(BuildContext context, DateTime? initialDate,
        Function(DateTime) onDateSelected, StateSetter setModalState) async {
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
        setModalState(() {});
      }
    }

    Future<void> _showPhotoActionSheet(StateSetter setModalState) async {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setModalState(() {
          _selectedImage = File(pickedFile.path);
        });
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
                          'Detalle de Certificados',
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
                                SizedBox(height: 15),
                                Row(
                                  children: [
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
                                          width: 45,
                                          height: 45,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.rectangle,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            image: DecorationImage(
                                              image: _selectedImage != null
                                                  ? FileImage(_selectedImage!)
                                                  : AssetImage(AppImages
                                                          .placeHolderImage)
                                                      as ImageProvider,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
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
                                              onTap: () {
                                                _showPhotoActionSheet(
                                                    setModalState);
                                              },
                                              child: CircleAvatar(
                                                radius: 12,
                                                backgroundColor:
                                                    AppColors.primaryGreen,
                                                child: Icon(Icons.add,
                                                    size: 16,
                                                    color:
                                                        AppColors.whiteColor),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(width: 18),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Subir foto del certificado',
                                            style: TextStyle(
                                              color: AppColors.blackColor,
                                              fontSize:
                                                  FontSize.scale(context, 13),
                                              fontFamily: 'SF-Pro-Text',
                                              fontWeight: FontWeight.w400,
                                              fontStyle: FontStyle.normal,
                                            ),
                                          ),
                                          Text(
                                            'Asegúrese de que el tamaño de su archivo no supere los 15 MB.',
                                            style: TextStyle(
                                              color: AppColors.greyColor,
                                              fontSize:
                                                  FontSize.scale(context, 12),
                                              fontFamily: 'SF-Pro-Text',
                                              fontWeight: FontWeight.w400,
                                              fontStyle: FontStyle.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 15),
                                Divider(
                                  color: AppColors.dividerColor,
                                  height: 0,
                                  thickness: 1.5,
                                  indent: 2,
                                  endIndent: 2,
                                ),
                                SizedBox(height: 10),
                                TextField(
                                  cursorColor: AppColors.blackColor,
                                  controller: jobTitleController,
                                  decoration: InputDecoration(
                                    labelText: 'Título del Certificado',
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
                                  controller: companyController,
                                  decoration: InputDecoration(
                                    labelText: 'Universidad o Instituto',
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
                                  onTap: () => _selectDate(context, fromDate,
                                      (selectedDate) {
                                    setModalState(() {
                                      fromDate = selectedDate;
                                    });
                                  }, setModalState),
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
                                  }, setModalState),
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
                                TextField(
                                  cursorColor: AppColors.blackColor,
                                  controller: descriptionController,
                                  maxLines: 5,
                                  decoration: InputDecoration(
                                    labelText: 'Descripcion',
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
                                    if (jobTitleController.text.isNotEmpty &&
                                        companyController.text.isNotEmpty &&
                                        fromDate != null &&
                                        toDate != null) {
                                      final Certificate certificateToSubmit =
                                          Certificate(
                                        id: certificate?.id ?? 0,
                                        imagePath: _selectedImage?.path,
                                        jobTitle: jobTitleController.text,
                                        company: companyController.text,
                                        employmentType:
                                            employmentTypeController.text,
                                        companyType: companyTypeController.text,
                                        description: descriptionController.text,
                                        fromDate: DateFormat('yyyy-MM-dd')
                                            .format(fromDate!),
                                        toDate: DateFormat('yyyy-MM-dd')
                                            .format(toDate!),
                                      );

                                      try {
                                        setState(() {
                                          _isLoading = true;
                                        });
                                        final authProvider =
                                            Provider.of<AuthProvider>(context,
                                                listen: false);
                                        final token = authProvider.token;

                                        if (token != null) {
                                          Map<String, dynamic> response;

                                          if (certificateToSubmit.id != 0) {
                                            response = await authProvider
                                                .updateCertificateToApi(
                                                    token, certificateToSubmit);
                                          } else {
                                            response = await authProvider
                                                .addCertificateToApi(
                                                    token, certificateToSubmit);
                                          }

                                          if (response['status'] == 200) {
                                            showCustomToast(
                                              context,
                                              response['message'],
                                              true,
                                            );
                                            setState(() {});
                                            Navigator.pop(context);
                                          } else {
                                            final errorMessages =
                                                response['errors']
                                                        ?.values
                                                        ?.join(', ') ??
                                                    'Unknown error occurred';
                                            showCustomToast(
                                              context,
                                              'Failed to process certificate: $errorMessages',
                                              false,
                                            );
                                          }
                                        }
                                      } catch (e) {
                                        showCustomToast(
                                          context,
                                          'An error occurred: $e',
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
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Guardar y Subir',
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
                                SizedBox(height: 20),
                                Text(
                                  'Haga clic en "Guardar y subir" para actualizar los detalles de su experiencia.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: FontSize.scale(context, 14),
                                    color: AppColors.greyColor.withOpacity(0.7),
                                    fontFamily: 'SF-Pro-Text',
                                    fontWeight: FontWeight.w400,
                                    fontStyle: FontStyle.normal,
                                  ),
                                ),
                                SizedBox(height: 10),
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (index >= 0 && index < authProvider.certificateList.length) {
      final certificateId = authProvider.certificateList[index].id;

      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return DialogComponent(
            onRemove: () async {
              if (token != null) {
                try {
                  final response =
                      await deleteCertification(token, certificateId);

                  if (response['status'] == 200) {
                    final message = response['message'] ??
                        'Certificate deleted successfully';

                    if (context.mounted) {
                      showCustomToast(context, message, true);
                    }

                    await authProvider.removeCertificate(index);
                  } else {
                    if (context.mounted) {
                      showCustomToast(
                        context,
                        "Failed to delete certificate: ${response['message']}",
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
            message:
                "You're going to remove this item.\n This cannot be undone",
          );
        },
      );
    } else {
      showCustomToast(
        context,
        "Invalid operation. Please try again.",
        false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
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
                'Certificados',
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
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return Column(
            children: [
              if (authProvider.certificateList.isEmpty)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          AppImages.emptyCertificate,
                          width: 80,
                          height: 80,
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
                  child: ListView.builder(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.0, vertical: 20.0),
                    itemCount: authProvider.certificateList.length,
                    itemBuilder: (context, index) {
                      final certificate = authProvider.certificateList[index];
                      DateTime issuedParsedDate =
                          DateTime.parse(certificate.fromDate);

                      String issuedFormattedDate =
                          DateFormat('MMM dd, yyyy').format(issuedParsedDate);

                      DateTime expiryParsedDate =
                          DateTime.parse(certificate.toDate);

                      String expiryFormattedDate =
                          DateFormat('MMM dd, yyyy').format(expiryParsedDate);

                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.whiteColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 70,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.rectangle,
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: certificate.imagePath != null
                                            ? FileImage(
                                                File(certificate.imagePath!))
                                            : AssetImage(
                                                    AppImages.placeHolderImage)
                                                as ImageProvider,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        certificate.company,
                                        style: TextStyle(
                                          fontSize: FontSize.scale(context, 16),
                                          color: AppColors.blackColor,
                                          fontFamily: 'SF-Pro-Text',
                                          fontWeight: FontWeight.w600,
                                          fontStyle: FontStyle.normal,
                                        ),
                                      ),
                                      Text(
                                        certificate.jobTitle,
                                        style: TextStyle(
                                          fontSize: FontSize.scale(context, 14),
                                          color: AppColors.greyColor,
                                          fontFamily: 'SF-Pro-Text',
                                          fontWeight: FontWeight.w400,
                                          fontStyle: FontStyle.normal,
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                              SizedBox(height: 14),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      SvgPicture.asset(
                                        AppImages.dateIcon,
                                        width: 12,
                                        height: 12,
                                      ),
                                      SizedBox(width: 6),
                                      RichText(
                                        text: TextSpan(
                                          text: issuedFormattedDate ?? "",
                                          style: TextStyle(
                                            fontFamily: 'SF-Pro-Text',
                                            fontWeight: FontWeight.w500,
                                            fontSize:
                                                FontSize.scale(context, 14),
                                            fontStyle: FontStyle.normal,
                                            color: AppColors.greyColor,
                                          ),
                                          children: <InlineSpan>[
                                            WidgetSpan(
                                                child: SizedBox(width: 5)),
                                            TextSpan(
                                              text: 'Issued',
                                              style: TextStyle(
                                                fontFamily: 'SF-Pro-Text',
                                                fontWeight: FontWeight.w400,
                                                fontSize:
                                                    FontSize.scale(context, 14),
                                                fontStyle: FontStyle.normal,
                                                color: AppColors.greyColor
                                                    .withOpacity(0.7),
                                              ),
                                            ),
                                            WidgetSpan(
                                                child: SizedBox(width: 20)),
                                          ],
                                        ),
                                      ),
                                      SvgPicture.asset(
                                        AppImages.dateIcon,
                                        width: 12,
                                        height: 12,
                                      ),
                                      SizedBox(width: 6),
                                      RichText(
                                        text: TextSpan(
                                          text: expiryFormattedDate ?? "",
                                          style: TextStyle(
                                              fontFamily: 'SF-Pro-Text',
                                              fontWeight: FontWeight.w500,
                                              fontSize:
                                                  FontSize.scale(context, 14),
                                              fontStyle: FontStyle.normal,
                                              color: AppColors.greyColor),
                                          children: <InlineSpan>[
                                            WidgetSpan(
                                                child: SizedBox(width: 5)),
                                            TextSpan(
                                              text: 'Expiry',
                                              style: TextStyle(
                                                fontFamily: 'SF-Pro-Text',
                                                fontWeight: FontWeight.w400,
                                                fontSize:
                                                    FontSize.scale(context, 14),
                                                fontStyle: FontStyle.normal,
                                                color: AppColors.greyColor
                                                    .withOpacity(0.7),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
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
                                          certificate: certificate,
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
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 60),
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
                                          EdgeInsets.symmetric(horizontal: 55),
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
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              if (authProvider.certificateList.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundColor,
                    border: Border(
                      top:
                          BorderSide(width: 1.0, color: AppColors.dividerColor),
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
          );
        },
      ),
    );
  }
}

class Certificate {
  final int id;
  final String jobTitle;
  final String company;
  final String employmentType;
  final String companyType;
  final String fromDate;
  final String toDate;
  final String description;
  final String? imagePath;

  Certificate({
    required this.id,
    required this.jobTitle,
    required this.company,
    required this.companyType,
    required this.employmentType,
    required this.fromDate,
    required this.toDate,
    required this.description,
    this.imagePath,
  });

  Certificate copyWith({
    int? id,
    String? jobTitle,
    String? company,
    String? employmentType,
    String? companyType,
    String? fromDate,
    String? toDate,
    String? description,
    String? imagePath,
  }) {
    return Certificate(
      id: id ?? this.id,
      jobTitle: jobTitle ?? this.jobTitle,
      company: company ?? this.company,
      employmentType: employmentType ?? this.employmentType,
      companyType: companyType ?? this.companyType,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': jobTitle,
      'institute_name': company,
      'employmentType': employmentType,
      'companyType': companyType,
      'issue_date': fromDate,
      'expiry_date': toDate,
      'description': description,
      'image': imagePath ?? '',
    };
  }

  factory Certificate.fromJson(Map<String, dynamic> json) {
    return Certificate(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']) ?? 0,
      jobTitle: json['title'],
      company: json['institute_name'],
      employmentType: json['employmentType'] ?? '',
      companyType: json['companyType'] ?? '',
      fromDate: json['issue_date'],
      toDate: json['expiry_date'],
      description: json['description'],
      imagePath: json['image'],
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
  Future.delayed(const Duration(seconds: 3), () {
    overlayEntry.remove();
  });
}
