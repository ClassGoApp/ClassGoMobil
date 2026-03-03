import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/base_components/custom_snack_bar.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/bookSession/payment_methods.dart';
import 'package:provider/provider.dart';
import '../../../provider/auth_provider.dart';

class OrderSummaryBottomSheet extends StatefulWidget {
  final Map<String, dynamic> sessionData;
  final Map<String, dynamic> profileDta;
  final List<Map<String, dynamic>> cartData;

  const OrderSummaryBottomSheet({
    Key? key,
    required this.sessionData,
    required this.profileDta,
    required this.cartData,
  }) : super(key: key);

  @override
  _OrderSummaryBottomSheetState createState() =>
      _OrderSummaryBottomSheetState();
}

class _OrderSummaryBottomSheetState extends State<OrderSummaryBottomSheet> {
  List<Map<String, dynamic>> _sessions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _sessions = widget.cartData;
  }

  double _calculateSubtotal() {
    return _sessions.fold(0, (sum, session) {
      double price = extractNumber(session['price'].toString()).toDouble() ?? 0.0;
      return sum + price;
    });
  }

  double _calculateGrandTotal() {
    return _calculateSubtotal();
  }

  Future<void> _removeSessionDirectly(int index) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final int sessionId = _sessions[index]['id'];

    if (token != null) {
      try {
        final response = await deleteBookingCart(token, sessionId);

        if (response['status'] == 200) {
          setState(() {
            _sessions.removeAt(index);
          });
          showCustomToast(context,
              response['message'] ?? 'Session removed successfully', true);
        } else {
          showCustomToast(context,
              response['message'] ?? 'Failed to remove session', false);
        }
      } catch (e) {
        showCustomToast(context, 'Error occurred: $e', false);
      }
    } else {
      showCustomToast(context, 'Authentication token is missing', false);
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

    if (mounted) {
      Overlay.of(context).insert(overlayEntry);
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        overlayEntry.remove();
      }
    });
  }
  int extractNumber(String price) {
    RegExp regExp = RegExp(r'(\d+)');
    var match = regExp.firstMatch(price);
    return match != null ? int.parse(match.group(0)!) : 0;
  }



  @override
  Widget build(BuildContext context) {
    double subtotal = _calculateSubtotal();
    double grandTotal = _calculateGrandTotal();
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Resumen de Sesiones',
                  style: TextStyle(
                    fontSize: FontSize.scale(context, 18),
                    color: AppColors.blackColor,
                    fontFamily: 'SF-Pro-Text',
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.normal,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
          Divider(color: AppColors.dividerColor, thickness: 2, height: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  if (_sessions.isEmpty)
                    Center(
                      child: Text(
                        'Tu carrito está vacío 😔',
                        style: TextStyle(
                          fontSize: FontSize.scale(context, 14),
                          fontWeight: FontWeight.w500,
                          fontFamily: 'SF-Pro-Text',
                          color: AppColors.greyColor,
                        ),
                      ),
                    )
                  else
                    ..._sessions.asMap().entries.map((entry) {
                      int index = entry.key;
                      Map<String, dynamic> session = entry.value;
                      Map<String, dynamic> itemCart = session;
                      print(session.toString());

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                itemCart['session_time'] ?? 'N/A',
                                style: TextStyle(
                                  fontSize: FontSize.scale(context, 14),
                                  fontFamily: 'SF-Pro-Text',
                                  color: AppColors.greyColor,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              Text(
                                '${itemCart['currency_symbol'] ?? '\$'}${extractNumber(session['price'].toString())} /session',
                                style: TextStyle(
                                  fontSize: FontSize.scale(context, 16),
                                  fontFamily: 'SF-Pro-Text',
                                  color: AppColors.blackColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  itemCart['subject_name'] ?? 'Unknown Subject',
                                  style: TextStyle(
                                    fontSize: FontSize.scale(context, 16),
                                    fontFamily: 'SF-Pro-Text',
                                    color: AppColors.blackColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => _removeSessionDirectly(index),
                                child: Text(
                                  'Eliminar',
                                  style: TextStyle(
                                    fontSize: FontSize.scale(context, 14),
                                    color: AppColors.redColor,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            itemCart['subject_group'] ?? 'Unknown Grade',
                            style: TextStyle(
                              fontSize: FontSize.scale(context, 14),
                              fontFamily: 'SF-Pro-Text',
                              color: AppColors.greyColor,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          SizedBox(height: 2),
                          if (index != _sessions.length - 1)
                            Divider(
                              color: AppColors.dividerColor,
                              thickness: 1,
                            ),
                        ],
                      );
                    }).toList(),
                  SizedBox(height: 15),
                  Divider(
                      color: AppColors.dividerColor, thickness: 2, height: 1),
                  SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subtotal',
                        style: TextStyle(
                          fontSize: FontSize.scale(context, 14),
                          fontFamily: 'SF-Pro-Text',
                          color: AppColors.greyColor,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        '\$${subtotal.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: FontSize.scale(context, 14),
                          fontFamily: 'SF-Pro-Text',
                          color: AppColors.greyColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  Divider(
                      color: AppColors.dividerColor, thickness: 2, height: 1),
                  SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          fontSize: FontSize.scale(context, 16),
                          fontWeight: FontWeight.w500,
                          fontFamily: 'SF-Pro-Text',
                          color: AppColors.greyColor,
                        ),
                      ),
                      Text(
                        '\$${grandTotal.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: FontSize.scale(context, 18),
                          fontFamily: 'SF-Pro-Text',
                          color: AppColors.blackColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => PaymentScreen(
                            cartData: _sessions,
                            sessionData: widget.sessionData,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                    ),
                    child: Text(
                      'Continuar con la Reserva',
                      style: TextStyle(
                        fontSize: FontSize.scale(context, 16),
                        color: AppColors.whiteColor,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'SF-Pro-Text',
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.lock_outline, size: 20, color: Colors.grey),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Estás a sólo un paso de asegurar tu sesión. Continúe con nuestras opciones de pago seguro para confirmar su reserva. Su privacidad y seguridad son nuestra principal prioridad.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: FontSize.scale(context, 14),
                            color: AppColors.greyColor.withOpacity(0.7),
                            fontFamily: 'SF-Pro-Text',
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
