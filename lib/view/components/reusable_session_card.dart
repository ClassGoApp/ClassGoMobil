import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/base_components/custom_snack_bar.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/bookSession/component/order_summary_bottom_sheet.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../provider/auth_provider.dart';
import '../detailPage/session_detail.dart';

class SessionCard extends StatefulWidget {
  final int slotsLeft;
  final int totalSlots;
  final int bookedSlots;
  final Color borderColor;
  final String description;
  final String sessionDate;
  final Map<String, dynamic> sessionData;
  final Map<String, dynamic> tutorProfile;
  final Function() onSessionUpdated;

  const SessionCard({
    Key? key,
    required this.slotsLeft,
    required this.totalSlots,
    required this.bookedSlots,
    required this.borderColor,
    required this.description,
    required this.sessionDate,
    required this.sessionData,
    required this.tutorProfile,
    required this.onSessionUpdated,
  }) : super(key: key);

  @override
  State<SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<SessionCard> {
  bool isBooking = false;

  Future<void> _bookSession(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final String sessionId = widget.sessionData['id'].toString();
    print(sessionId);

    if (token != null) {
      try {
        setState(() {
          isBooking = true;
        });

        final Map<String, dynamic> data = {
          'slot_id': sessionId,
        };

        final response = await bookSessionCart(token, data, sessionId);
        if (response['status'] == 200) {
          showCustomToast(context,
              response['message'] ?? 'Session booked successfully', true);
          await Future.delayed(Duration(milliseconds: 500));
          await _fetchBookingCart(context);
        } else {
          showCustomToast(
              context, response['message'] ?? 'Failed to book session', false);
        }
      } catch (e) {
        showCustomToast(context, 'Failed to book session', false);
      } finally {
        setState(() {
          isBooking = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Authentication token is missing')),
      );
    }
  }

  Future<void> _fetchBookingCart(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token != null) {
      try {
        final response = await getBookingCart(token);
        final sessions =
            List<Map<String, dynamic>>.from(response['data']['cartItems']);

        await showModalBottomSheet(
          backgroundColor: AppColors.sheetBackgroundColor,
          context: context,
          isScrollControlled: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(16),
            ),
          ),
          builder: (context) => OrderSummaryBottomSheet(
            sessionData: widget.sessionData,
            profileDta: widget.tutorProfile,
            cartData: sessions,
          ),
        );

        widget.onSessionUpdated();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch booking cart')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Authentication token is missing')),
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

    if (mounted) {
      Overlay.of(context).insert(overlayEntry);
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        overlayEntry.remove();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('dd MMM, yyyy')
        .format(DateFormat('dd MMM yyyy').parse(widget.sessionDate));

    return Padding(
      padding: EdgeInsets.all(10),
      child: Card(
        color: AppColors.whiteColor.withOpacity(0.9),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.sessionData['group'] ?? 'Grupo no disponible' ,
                style: TextStyle(
                  color: AppColors.greyColor,
                  fontSize: FontSize.scale(context, 14),
                  fontFamily: 'SF-Pro-Text',
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.normal,
                ),
              ),
              SizedBox(height: 4),
              Text(
                widget.sessionData['subject'] ?? 'Materia no disponible' ,
                style: TextStyle(
                  color: AppColors.blackColor,
                  fontSize: FontSize.scale(context, 16),
                  fontFamily: 'SF-Pro-Text',
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.normal,
                ),
              ),
              SizedBox(height: 15),
              Row(
                children: [
                  SvgPicture.asset(
                    AppImages.clockInsightIcon,
                    width: 14,
                    height: 14,
                    color: AppColors.greyColor,
                  ),
                  SizedBox(width: 4),
                  Text(
                    widget.sessionData['formatted_time_range'] ?? '',
                    style: TextStyle(
                      color: AppColors.greyColor,
                      fontSize: FontSize.scale(context, 14),
                      fontFamily: 'SF-Pro-Text',
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.normal,
                    ),
                  ),
                  SizedBox(width: 30),
                  SvgPicture.asset(
                    AppImages.sessionCart,
                    width: 14,
                    height: 14,
                    color: AppColors.greyColor,
                  ),
                  SizedBox(width: 5),
                  Text(
                    '\$${widget.sessionData['session_fee'] ?? ''}/session',
                    style: TextStyle(
                      color: AppColors.greyColor,
                      fontSize: FontSize.scale(context, 14),
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
                    AppImages.userIcon,
                    width: 14,
                    height: 14,
                    color: AppColors.greyColor,
                  ),
                  SizedBox(width: 5),
                  Text(
                    widget.slotsLeft > 0
                        ? '${widget.slotsLeft}/${widget.totalSlots} slots left'
                        : '${widget.bookedSlots}/${widget.totalSlots} slots booked',
                    style: TextStyle(
                      color: AppColors.greyColor,
                      fontSize: FontSize.scale(context, 14),
                      fontFamily: 'SF-Pro-Text',
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.normal,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (isBooking || widget.slotsLeft <= 0)
                          ? null
                          : () => _bookSession(context),
                      style: ButtonStyle(
                        backgroundColor:
                            WidgetStateProperty.resolveWith<Color>(
                                (Set<WidgetState> states) {
                          if (states.contains(WidgetState.disabled)) {
                            return AppColors.fadeColor;
                          }
                          return AppColors.navbar;
                        }),
                        shape:
                            WidgetStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      child: isBooking
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: AppColors.primaryGreen,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Agendar Sesión',
                              style: TextStyle(
                                color: widget.slotsLeft > 0
                                    ? AppColors.whiteColor
                                    : AppColors.greyColor.withOpacity(0.5),
                                fontSize: FontSize.scale(context, 14),
                                fontFamily: 'SF-Pro-Text',
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.normal,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(width: 8),
                  // Expanded(
                  //   child: OutlinedButton(
                  //     onPressed: () {
                  //       Navigator.push(
                  //         context,
                  //         MaterialPageRoute(
                  //             builder: (context) => SessionScreen(
                  //                 slotsLeft: widget.slotsLeft,
                  //                 totalSlots: widget.totalSlots,
                  //                 description: widget.description,
                  //                 sessionDate: formattedDate,
                  //                 sessionData: widget.sessionData,
                  //                 tutorProfileData: widget.tutorProfile)),
                  //       );
                  //     },
                  //     style: OutlinedButton.styleFrom(
                  //       side: BorderSide(
                  //         color: AppColors.dividerColor,
                  //         width: 1,
                  //       ),
                  //       shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(6.0),
                  //       ),
                  //       padding: EdgeInsets.symmetric(vertical: 6.0),
                  //     ),
                  //     child: Text(
                  //       'Ver Detalles',
                  //       style: TextStyle(
                  //         color: AppColors.greyColor,
                  //         fontSize: FontSize.scale(context, 14),
                  //         fontFamily: 'SF-Pro-Text',
                  //         fontWeight: FontWeight.w500,
                  //         fontStyle: FontStyle.normal,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
