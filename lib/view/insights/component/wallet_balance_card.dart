import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/base_components/custom_snack_bar.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class WalletBalanceCard extends StatefulWidget {
  final double? walletBalance;
  final bool areAllPayoutMethodsActive;
  final bool isWalletBalanceAvailable;
  final String token;
  final Function(double)? onBalanceUpdated;

  const WalletBalanceCard({
    Key? key,
    required this.walletBalance,
    required this.areAllPayoutMethodsActive,
    required this.isWalletBalanceAvailable,
    required this.token,
    this.onBalanceUpdated,
  }) : super(key: key);

  @override
  _WalletBalanceCardState createState() => _WalletBalanceCardState();
}

class _WalletBalanceCardState extends State<WalletBalanceCard> {
  final TextEditingController _amountController = TextEditingController();
  bool _isLoading = false;
  String _message = '';
  int? _responseStatus;
  double? _currentWalletBalance;

  @override
  void initState() {
    super.initState();
    _currentWalletBalance = widget.walletBalance;
  }

  @override
  void didUpdateWidget(covariant WalletBalanceCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.walletBalance != oldWidget.walletBalance) {
      setState(() {
        _currentWalletBalance = widget.walletBalance;
      });
    }
  }


  Future<void> _withdrawNow() async {
    final inputAmount = _amountController.text.trim();

    if (inputAmount.isEmpty) {
      setState(() {
        _message = "Please enter an amount.";
      });
      return;
    }

    final double? enteredAmount = double.tryParse(inputAmount);
    if (enteredAmount == null || enteredAmount <= 0) {
      setState(() {
        _message = "Please enter a valid amount.";
      });
      return;
    }

    if (enteredAmount > widget.walletBalance!) {
      setState(() {
        _message = "Amount exceeds wallet balance.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    final data = {
      'amount': enteredAmount.toString(),
    };

    final response = await userWithdrawal(widget.token, data);

    setState(() {
      _isLoading = false;

      if (response['status'] == 200) {
        final updatedBalance = widget.walletBalance! - enteredAmount;
        Provider.of<AuthProvider>(context, listen: false).updateBalance(updatedBalance);

        _message = response['message'];
        _responseStatus = response['status'];

        if (widget.onBalanceUpdated != null) {
          widget.onBalanceUpdated!(updatedBalance);
        }
      } else {
        final errorDetails = response['errors'];
        if (errorDetails != null &&
            errorDetails is Map &&
            errorDetails.containsKey('amount')) {
          _message = errorDetails['amount'];
        } else {
          _message = response['message'] ?? 'Something went wrong';
        }
      }
    });

    if (response['status'] == 200) {
      showCustomToast(context, response['message'], true);
    } else {
      showCustomToast(context, _message, false);
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
    return Container(
      decoration: BoxDecoration(
        border:
            Border(top: BorderSide(color: AppColors.dividerColor, width: 1)),
        color: AppColors.whiteColor,
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SvgPicture.asset(
                    AppImages.walletIcon,
                    width: 20,
                    height: 20,
                    color: AppColors.greyColor,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Wallet Balance',
                    style: TextStyle(
                      fontSize: FontSize.scale(context, 16),
                      color: AppColors.greyColor,
                      fontFamily: 'SF-Pro-Text',
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.normal,
                    ),
                  ),
                ],
              ),
              Text(
                '\$${_currentWalletBalance?.toStringAsFixed(0) ?? '0'}',
                style: TextStyle(
                  fontSize: FontSize.scale(context, 18),
                  color:  AppColors.blackColor,
                  fontFamily: 'SF-Pro-Text',
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.normal,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: AppColors.fadeColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                width: 1,
                color: AppColors.dividerColor,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                  child: SvgPicture.asset(
                    AppImages.dollarIcon,
                    width: 20,
                    height: 20,
                    color: AppColors.greyColor,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: 'Enter amount to withdraw',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        fontSize: FontSize.scale(context, 16),
                        color: AppColors.greyColor,
                        fontFamily: 'SF-Pro-Text',
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: widget.areAllPayoutMethodsActive &&
                          widget.isWalletBalanceAvailable &&
                          !_isLoading
                      ? _withdrawNow
                      : null,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 20, horizontal: 20.0),
                    decoration: BoxDecoration(
                      color: widget.areAllPayoutMethodsActive &&
                              widget.isWalletBalanceAvailable
                          ? AppColors.primaryGreen
                          : AppColors.dividerColor,
                      borderRadius: BorderRadius.only(
                          topRight: Radius.circular(10.0),
                          bottomRight: Radius.circular(10.0)),
                    ),
                    child: Icon(
                      Icons.arrow_forward,
                      color: widget.areAllPayoutMethodsActive &&
                              widget.isWalletBalanceAvailable
                          ? AppColors.whiteColor
                          : AppColors.fadeColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          if (_message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(
                _message,
                style: TextStyle(
                  color: _responseStatus == 200
                      ? AppColors.primaryGreen
                      : AppColors.redColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
