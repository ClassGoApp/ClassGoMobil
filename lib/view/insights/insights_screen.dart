import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/base_components/textfield.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/insights/component/custom_field.dart';
import 'package:flutter_projects/view/insights/component/payout_method.dart';
import 'package:flutter_projects/view/insights/component/wallet_balance_card.dart';
import 'package:flutter_projects/view/insights/skeleton/insight_screen_skeleton.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../base_components/custom_snack_bar.dart';
import '../../provider/auth_provider.dart';

class InsightScreen extends StatefulWidget {
  InsightScreen({
    Key? key,
  }) : super(key: key);

  @override
  _InsightScreenState createState() => _InsightScreenState();
}

class _InsightScreenState extends State<InsightScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController numberController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController routingController = TextEditingController();
  final TextEditingController ibanController = TextEditingController();
  final TextEditingController swiftController = TextEditingController();

  late double screenWidth;
  late double screenHeight;
  int? _selectedCardIndex;
  Map<String, dynamic>? _payoutStatus;

  IconData _appBarIcon = Icons.arrow_back_ios;
  bool _isLoading = true;

  Map<String, dynamic> _earningDetails = {
    'earned_amount': 0,
    'wallet_balance': 0,
    'pending_withdrawals': 0,
    'completed_withdrawals': 0,
    'pending_balance': 0
  };

  TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  bool _isEmailValid = true;
  String _errorMessage = '';

  String getFormattedAmount(dynamic value) {
    return value != null ? '\$${value.toStringAsFixed(2)}' : '\$0.00';
  }

  @override
  void initState() {
    super.initState();
    _fetchEarningDetails();
    _fetchPayoutStatus();
    _fetchGraphData();
  }

  List<ChartData> graphData = [];
  double yAxisMax = 0.0;
  double yAxisInterval = 20.0;

  Future<void> _fetchGraphData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token != null) {
      try {
        setState(() {
          _isLoading = true;
        });

        final response = await getEarningDetails(token);
        graphData.clear();
        final earnings = response['data']?['earnings'];

        if (earnings is Map<String, dynamic> && earnings.isNotEmpty) {
          double maxValue = 0;

          earnings.forEach((day, value) {
            double earningsValue = (value as num).toDouble();
            if (earningsValue > 0) {
              int dayInt = int.parse(day);
              graphData.add(ChartData(dayInt, earningsValue));
              maxValue = earningsValue > maxValue ? earningsValue : maxValue;
            }
          });

          yAxisMax = (maxValue + 39) ~/ 40 * 40.0;

          if (maxValue <= 50) {
            yAxisInterval = 10;
          } else if (maxValue > 50 && maxValue <= 100) {
            yAxisInterval = 20;
          } else if (maxValue > 100 && maxValue <= 150) {
            yAxisInterval = 30;
          } else if (maxValue > 150) {
            yAxisInterval = 100;
          }
        } else {
          yAxisMax = 50;
          yAxisInterval = 10;
        }
      } catch (e) {
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchEarningDetails() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final userId = authProvider.userId;

    if (token != null && userId != null) {
      try {
        final response = await getMyEarnings(token, userId);

        setState(() {
          _earningDetails = response['data'];
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

  Future<void> _fetchPayoutStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token != null) {
      try {
        final response = await getPayoutStatus(token);
        setState(() {
          _payoutStatus = response['data'];
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

  String _getButtonTitle(String payoutMethod) {
    if (_payoutStatus != null && _payoutStatus![payoutMethod] != null) {
      return 'Remove Account';
    }
    return 'Setup Account';
  }

  Future<void> _deletePayoutMethod(int index, String method) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await deletePayoutMethod(token, method);

        if (response['status'] == 200) {
          showCustomToast(
            context,
            response['message'],
            true,
          );

          setState(() {
            _payoutStatus![method] = null;
          });
        } else {
          showCustomToast(
            context,
            'Failed to delete payout method: ${response['message']}',
            false,
          );
        }
      } catch (error) {
        showCustomToast(
          context,
          'Error occurred while deleting payout method: $error',
          false,
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {}
  }

  void showDeleteConfirmation(BuildContext context, int index, String method) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.whiteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.trashBgColor,
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(
                  AppImages.trashIcon,
                  height: 30,
                  color: AppColors.redColor,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Are you sure?',
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  color: AppColors.blackColor,
                  fontSize: FontSize.scale(context, 20),
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.normal,
                  fontFamily: "SF Pro Text",
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'You\'re going to remove this method.\nThis cannot be undone.',
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    color: AppColors.greyColor,
                    fontSize: FontSize.scale(context, 14),
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.normal,
                    fontFamily: "SF Pro Text",
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        side:
                            BorderSide(color: AppColors.dividerColor, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                            fontSize: FontSize.scale(context, 16),
                            color: AppColors.greyColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await _deletePayoutMethod(index, method);
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.redBackgroundColor,
                      side: BorderSide(
                        color: AppColors.redBorderColor,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 60, vertical: 15),
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
              SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _onButtonTap(int index, String buttonTitle) {
    final method = index == 0
        ? 'paypal'
        : index == 1
            ? 'payoneer'
            : 'bank';

    if (buttonTitle == 'Remove Account') {
      showDeleteConfirmation(context, index, method);
    } else if (method == 'bank') {
      _bankAccountBottomSheet(index, buttonTitle);
    } else {
      showModalBottomSheet(
        isScrollControlled: true,
        backgroundColor: AppColors.sheetBackgroundColor,
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.4,
                minChildSize: 0.3,
                maxChildSize: 0.9,
                builder: (context, scrollController) {
                  return SingleChildScrollView(
                    controller: scrollController,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.whiteColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10.0),
                          topRight: Radius.circular(10.0),
                        ),
                      ),
                      height: MediaQuery.of(context).size.height * 0.5,
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          SizedBox(height: 10),
                          Text(
                            'Setup Account',
                            style: TextStyle(
                              fontSize: FontSize.scale(context, 18),
                              color: AppColors.blackColor,
                              fontFamily: 'SF-Pro-Text',
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.normal,
                            ),
                          ),
                          SizedBox(height: 16),
                          Expanded(
                            child: ListView(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              controller: scrollController,
                              children: [
                                CustomTextField(
                                  hint: 'Enter your email',
                                  obscureText: false,
                                  controller: _emailController,
                                  focusNode: _emailFocusNode,
                                  hasError: !_isEmailValid,
                                  mandatory: true,
                                ),
                                if (_errorMessage.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      _errorMessage,
                                      style:
                                          TextStyle(color: AppColors.redColor),
                                    ),
                                  ),
                                SizedBox(height: 16),
                                _isLoading
                                    ? Center(
                                        child: SizedBox(
                                        width: 20.0,
                                        height: 20.0,
                                        child: CircularProgressIndicator(
                                          color: AppColors.primaryGreen,
                                          strokeWidth: 2.0,
                                        ),
                                      ))
                                    : ElevatedButton(
                                        onPressed: () async {
                                          final accountEmail =
                                              _emailController.text;

                                          if (accountEmail.isEmpty) {
                                            setState(() {
                                              _errorMessage =
                                                  'The email field is required.';
                                            });
                                            return;
                                          }

                                          setState(() {
                                            _errorMessage = '';
                                            _isLoading = true;
                                          });

                                          final payoutData = {
                                            'email': accountEmail,
                                            'current_method': method,
                                          };

                                          final authProvider =
                                              Provider.of<AuthProvider>(context,
                                                  listen: false);
                                          final token = authProvider.token;

                                          if (token != null) {
                                            final response = await payoutMethod(
                                                token, payoutData);

                                            if (response['status'] == 200) {
                                              showCustomToast(
                                                context,
                                                response['message'],
                                                true,
                                              );

                                              await _fetchEarningDetails();
                                              await _fetchPayoutStatus();

                                              Navigator.pop(context);
                                              _emailController.clear();
                                            } else {
                                              showCustomToast(
                                                context,
                                                response['message'],
                                                false,
                                              );
                                            }
                                          }

                                          setState(() {
                                            _isLoading = false;
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppColors.primaryGreen,
                                          minimumSize:
                                              Size(double.infinity, 50),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                          ),
                                        ),
                                        child: Text(
                                          'Save & Update',
                                          style: TextStyle(
                                            fontSize:
                                                FontSize.scale(context, 16),
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
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      );
    }
  }

  void _bankAccountBottomSheet(int index, String buttonTitle) {
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
    Map<String, String> _errorMessages = {};

    if (buttonTitle == 'Setup Account') {
      showModalBottomSheet(
        backgroundColor: AppColors.sheetBackgroundColor,
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.6,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                builder: (context, scrollController) {
                  return SingleChildScrollView(
                      controller: scrollController,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.sheetBackgroundColor,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10.0),
                            topRight: Radius.circular(10.0),
                          ),
                        ),
                        padding: EdgeInsets.all(16.0),
                        child: Form(
                          key: _formKey,
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
                              SizedBox(height: 10),
                              Text(
                                'Setup Bank Account',
                                style: TextStyle(
                                  fontSize: FontSize.scale(context, 18),
                                  color: AppColors.blackColor,
                                  fontFamily: 'SF-Pro-Text',
                                  fontWeight: FontWeight.w500,
                                  fontStyle: FontStyle.normal,
                                ),
                              ),
                              SizedBox(height: 16),
                              Container(
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
                                    CustomField(
                                      controller: titleController,
                                      labelText: 'Enter bank account title',
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'This field is required';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: 10),
                                    CustomField(
                                      controller: numberController,
                                      labelText: 'Enter bank account number',
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (_errorMessages['accountNumber'] !=
                                            null) {
                                          return _errorMessages[
                                              'accountNumber'];
                                        }
                                        if (value == null || value.isEmpty) {
                                          return 'This field is required';
                                        }
                                        if (value.length < 8 ||
                                            value.length > 20) {
                                          return 'The account number must be between 8 and 20 digits.';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: 10),
                                    CustomField(
                                      controller: nameController,
                                      labelText: 'Enter bank account name',
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'This field is required';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: 10),
                                    CustomField(
                                      controller: routingController,
                                      labelText: 'Enter bank routing number',
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (_errorMessages[
                                                'bankRoutingNumber'] !=
                                            null) {
                                          return _errorMessages[
                                              'bankRoutingNumber'];
                                        }
                                        if (value == null || value.isEmpty) {
                                          return 'This field is required';
                                        }
                                        if (value.length != 9) {
                                          return 'The bank routing number must be exactly 9 digits.';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: 10),
                                    CustomField(
                                      controller: ibanController,
                                      labelText: 'Enter bank IBAN',
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'This field is required';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: 10),
                                    CustomField(
                                      controller: swiftController,
                                      labelText: 'Enter bank BIC/SWIFT',
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'This field is required';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: 10),
                                    _isLoading
                                        ? Center(
                                            child: CircularProgressIndicator(
                                            color: AppColors.primaryGreen,
                                          ))
                                        : ElevatedButton(
                                            onPressed: () async {
                                              if (_formKey.currentState!
                                                  .validate()) {
                                                setState(() {
                                                  _isLoading = true;
                                                });

                                                final Map<String, dynamic>
                                                    payoutData = {
                                                  'title': titleController.text,
                                                  'bankName':
                                                      nameController.text,
                                                  'bankRoutingNumber':
                                                      routingController.text,
                                                  'bankIban':
                                                      ibanController.text,
                                                  'bankBtc':
                                                      swiftController.text,
                                                  'current_method': 'bank',
                                                  'accountNumber':
                                                      numberController.text,
                                                };

                                                final authProvider =
                                                    Provider.of<AuthProvider>(
                                                        context,
                                                        listen: false);
                                                final token =
                                                    authProvider.token;

                                                if (token != null) {
                                                  final response =
                                                      await payoutMethod(
                                                          token, payoutData);

                                                  if (response['status'] ==
                                                      200) {
                                                    showCustomToast(
                                                      context,
                                                      response['message'],
                                                      true,
                                                    );

                                                    await _fetchEarningDetails();
                                                    await _fetchPayoutStatus();

                                                    Navigator.pop(context);
                                                  } else if (response[
                                                              'status'] ==
                                                          400 &&
                                                      response['errors'] !=
                                                          null) {
                                                    setState(() {
                                                      _errorMessages =
                                                          response['errors'];
                                                    });
                                                  } else {
                                                    showCustomToast(
                                                      context,
                                                      'Failed to update bank details: ${response['message']}',
                                                      false,
                                                    );
                                                  }
                                                }
                                                setState(() {
                                                  _isLoading = false;
                                                });
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.primaryGreen,
                                              minimumSize:
                                                  Size(double.infinity, 50),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                              ),
                                            ),
                                            child: Text(
                                              'Save & Update',
                                              style: TextStyle(
                                                fontSize:
                                                    FontSize.scale(context, 16),
                                                color: AppColors.whiteColor,
                                                fontFamily: 'SF-Pro-Text',
                                                fontWeight: FontWeight.w500,
                                                fontStyle: FontStyle.normal,
                                              ),
                                            ),
                                          ),
                                    SizedBox(height: 20),
                                    Text(
                                      'Click "Save & Update" to update your bank details',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: FontSize.scale(context, 14),
                                        color: AppColors.greyColor
                                            .withOpacity(0.7),
                                        fontFamily: 'SF-Pro-Text',
                                        fontWeight: FontWeight.w400,
                                        fontStyle: FontStyle.normal,
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                  ],
                                ),
                              ),
                              SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ));
                },
              ),
            );
          });
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

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    bool areAllPayoutMethodsActive =
        _payoutStatus?['payoneer']?['status'] == 'active' ||
            _payoutStatus?['bank']?['status'] == 'active' ||
            _payoutStatus?['paypal']?['status'] == 'active';

    bool isWalletBalanceAvailable =
        _earningDetails.containsKey('wallet_balance') &&
            _earningDetails['wallet_balance'] != null;

    double? walletBalance = _earningDetails['wallet_balance'] != null
        ? (_earningDetails['wallet_balance'] is int
            ? (_earningDetails['wallet_balance'] as int).toDouble()
            : _earningDetails['wallet_balance'] as double?)
        : 0.00;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    return WillPopScope(
      onWillPop: () async {
        return !_isLoading;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: AppColors.backgroundColor,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(80.0),
          child: Container(
            color: AppColors.whiteColor,
            child: Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: AppBar(
                backgroundColor: AppColors.whiteColor,
                forceMaterialTransparency: true,
                leading: IconButton(
                  icon: Icon(
                    _appBarIcon,
                    color: AppColors.blackColor,
                    size: 20,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                centerTitle: false,
                elevation: 0,
                titleSpacing: 0,
                title: Text(
                  'My Earning',
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    color: AppColors.blackColor,
                    fontSize: FontSize.scale(context, 20),
                    fontFamily: 'SF-Pro-Text',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
        body: _isLoading
            ? InsightScreenSkeleton()
            : Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: screenHeight * 0.23,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 5,
                            itemBuilder: (context, index) {
                              String amount;
                              String title;
                              String backgroundImage;
                              String iconPath;

                              if (index == 0) {
                                amount = getFormattedAmount(
                                    _earningDetails['earned_amount']);
                                title = 'Earned Income';
                                backgroundImage = AppImages.insightsBg;
                                iconPath = AppImages.insightsIcon;
                              } else if (index == 1) {
                                amount = getFormattedAmount(
                                    _earningDetails['wallet_balance']);
                                title = 'Wallet Balance';
                                backgroundImage = AppImages.walletBalanceBg;
                                iconPath = AppImages.walletBalanceIcon;
                              } else if (index == 2) {
                                amount = getFormattedAmount(
                                    _earningDetails['pending_balance']);
                                title = 'Pending Amount';
                                backgroundImage = AppImages.pendingAmountBg;
                                iconPath = AppImages.clockInsightIcon;
                              } else if (index == 3) {
                                amount = getFormattedAmount(
                                    _earningDetails['completed_withdrawals']);
                                title = 'Wallet Funds';
                                backgroundImage = AppImages.walletFundsBg;
                                iconPath = AppImages.dollarInsightIcon;
                              } else {
                                amount = getFormattedAmount(
                                    _earningDetails['pending_withdrawals']);
                                title = 'Pending Withdraw';
                                backgroundImage = AppImages.withdrawBg;
                                iconPath = AppImages.pendingWithDrawIcon;
                              }

                              return earningCard(
                                backgroundImage: backgroundImage,
                                iconPath: iconPath,
                                title: title,
                                amount: amount,
                              );
                            },
                          ),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Text(
                          'Earning details',
                          textScaler: TextScaler.noScaling,
                          style: TextStyle(
                            color: AppColors.greyColor,
                            fontSize: FontSize.scale(context, 16),
                            fontFamily: 'SF-Pro-Text',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Container(
                          height: 300,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.greyColor.withOpacity(0.1),
                                spreadRadius: 2,
                                blurRadius: 5,
                              ),
                            ],
                            borderRadius: BorderRadius.circular(12.0),
                            color: AppColors.whiteColor,
                          ),
                          padding: EdgeInsets.only(
                            top: 20,
                            left: 8,
                            right: 8,
                            bottom: 12,
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Container(
                              padding:
                                  EdgeInsets.only(left: 2, top: 10, right: 20),
                              width: MediaQuery.of(context).size.width * 2,
                              child: LineChart(
                                LineChartData(
                                  minX: 1,
                                  maxX: 31,
                                  minY: 0,
                                  maxY: yAxisMax,
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 40,
                                        interval: yAxisInterval,
                                        getTitlesWidget: (value, meta) {
                                          if (value % yAxisInterval == 0) {
                                            return Text(
                                              value.toInt().toString(),
                                              style: TextStyle(
                                                color: AppColors.greyColor,
                                                fontSize:
                                                    FontSize.scale(context, 14),
                                                fontFamily: 'SF-Pro-Text',
                                                fontWeight: FontWeight.w400,
                                              ),
                                            );
                                          } else {
                                            return SizedBox.shrink();
                                          }
                                        },
                                      ),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        interval: 1,
                                        getTitlesWidget: (value, meta) {
                                          return Text(
                                            value.toInt().toString(),
                                            style: TextStyle(
                                              color: AppColors.greyColor,
                                              fontSize:
                                                  FontSize.scale(context, 12),
                                              fontFamily: 'SF-Pro-Text',
                                              fontWeight: FontWeight.w400,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    topTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                  ),
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: true,
                                    getDrawingHorizontalLine: (value) => FlLine(
                                      color: AppColors.dividerColor,
                                      strokeWidth: 1,
                                      dashArray: [5, 5],
                                    ),
                                    getDrawingVerticalLine: (value) => FlLine(
                                      color: AppColors.dividerColor,
                                      strokeWidth: 1,
                                      dashArray: [5, 5],
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: graphData
                                          .map((data) => FlSpot(
                                              data.x.toDouble(),
                                              data.y.toDouble()))
                                          .toList(),
                                      isCurved: true,
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.primaryGreen,
                                          AppColors.primaryGreen
                                              .withOpacity(0.8),
                                        ],
                                      ),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.primaryGreen
                                                .withOpacity(0.3),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                      dotData: FlDotData(
                                        show: true,
                                        getDotPainter:
                                            (spot, percent, barData, index) =>
                                                FlDotCirclePainter(
                                          radius: 4,
                                          color: AppColors.primaryGreen,
                                          strokeWidth: 2,
                                          strokeColor: AppColors.whiteColor,
                                        ),
                                      ),
                                      barWidth: 2,
                                    ),
                                  ],
                                  lineTouchData: LineTouchData(
                                    touchTooltipData: LineTouchTooltipData(
                                      tooltipRoundedRadius: 8,
                                      tooltipPadding: EdgeInsets.all(8),
                                      tooltipMargin: 8,
                                      fitInsideHorizontally: true,
                                      fitInsideVertically: true,
                                      getTooltipItems: (touchedSpots) {
                                        return touchedSpots
                                            .map((LineBarSpot touchedSpot) {
                                          return LineTooltipItem(
                                            '\$${touchedSpot.y.round()}',
                                            TextStyle(
                                              color: AppColors.whiteColor,
                                              fontSize:
                                                  FontSize.scale(context, 12),
                                              backgroundColor:
                                                  AppColors.blackColor,
                                            ),
                                          );
                                        }).toList();
                                      },
                                    ),
                                    handleBuiltInTouches: true,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Text(
                          'Setup payouts methods',
                          textScaler: TextScaler.noScaling,
                          style: TextStyle(
                              color: AppColors.greyColor,
                              fontSize: FontSize.scale(context, 16),
                              fontFamily: 'SF-Pro-Text',
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.normal),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              PayoutMethodCard(
                                index: 0,
                                imagePath: AppImages.paypal,
                                title: 'PayPal Balance',
                                amount: _payoutStatus != null &&
                                        _payoutStatus!['balance']?['paypal'] !=
                                            null
                                    ? '\$${_payoutStatus!['balance']!['paypal'].toString()}'
                                    : '\$0',
                                buttonTitle: _getButtonTitle('paypal'),
                                onButtonTap: _onButtonTap,
                                onCardTap: (index) {
                                  setState(() {
                                    _selectedCardIndex = index;
                                  });
                                },
                                selectedCardIndex: _selectedCardIndex,
                                isActive: _payoutStatus != null &&
                                    _payoutStatus!['paypal']?['status'] ==
                                        'active',
                              ),
                              SizedBox(width: 16),
                              PayoutMethodCard(
                                index: 1,
                                imagePath: AppImages.payoneer,
                                title: 'Payoneer Balance',
                                amount: _payoutStatus != null &&
                                        _payoutStatus!['balance']
                                                ?['payoneer'] !=
                                            null
                                    ? '\$${_payoutStatus!['balance']!['payoneer'].toString()}'
                                    : '\$0',
                                buttonTitle: _getButtonTitle('payoneer'),
                                onButtonTap: _onButtonTap,
                                onCardTap: (index) {
                                  setState(() {
                                    _selectedCardIndex = index;
                                  });
                                },
                                selectedCardIndex: _selectedCardIndex,
                                isActive: _payoutStatus != null &&
                                    _payoutStatus!['payoneer']?['status'] ==
                                        'active',
                              ),
                              SizedBox(width: 16),
                              PayoutMethodCard(
                                index: 2,
                                imagePath: AppImages.bankTransfer,
                                title: 'Bank Transfer',
                                amount: _payoutStatus != null &&
                                        _payoutStatus!['balance']?['bank'] !=
                                            null
                                    ? '\$${_payoutStatus!['balance']!['bank'].toString()}'
                                    : '\$0',
                                buttonTitle: _getButtonTitle('bank'),
                                onButtonTap: _onButtonTap,
                                onCardTap: (index) {
                                  setState(() {
                                    _selectedCardIndex = index;
                                  });
                                },
                                selectedCardIndex: _selectedCardIndex,
                                isActive: _payoutStatus != null &&
                                    _payoutStatus!['bank']?['status'] ==
                                        'active',
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 170,
                        )
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: WalletBalanceCard(
                      walletBalance: walletBalance,
                      areAllPayoutMethodsActive: areAllPayoutMethodsActive,
                      isWalletBalanceAvailable: isWalletBalanceAvailable,
                      token: token!,
                      onBalanceUpdated: (double updatedBalance) {
                        setState(() {
                          walletBalance = updatedBalance;
                        });
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget earningCard({
    required String backgroundImage,
    required String iconPath,
    required String title,
    required String amount,
  }) {
    return Container(
      width: screenWidth * 0.36,
      margin: EdgeInsets.only(right: 16),
      padding: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        image: DecorationImage(
          image: AssetImage(backgroundImage),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.whiteColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SvgPicture.asset(
                iconPath,
                width: 20,
                height: 20,
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            amount,
            style: TextStyle(
              color: AppColors.whiteColor,
              fontSize: FontSize.scale(context, 15),
              fontFamily: 'SF-Pro-Text',
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.normal,
            ),
          ),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: AppColors.whiteColor,
              fontSize: FontSize.scale(context, 12),
              fontFamily: 'SF-Pro-Text',
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }
}
