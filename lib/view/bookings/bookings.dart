import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/bookings/skeleton/booking_skeleton.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../provider/auth_provider.dart';
import '../../provider/connectivity_provider.dart';
import '../components/internet_alert.dart';

class BookingScreen extends StatefulWidget {
  final VoidCallback? onBackPressed;
  BookingScreen({this.onBackPressed});

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime selectedDate = DateTime.now();
  Map<String, dynamic> bookings = {};
  bool isLoading = true;

  final List<String> times = [
    '12:00 am',
    '01:00 am',
    '02:00 am',
    '03:00 am',
    '04:00 am',
    '05:00 am',
    '06:00 am',
    '07:00 am',
    '08:00 am',
    '09:00 am',
    '10:00 am',
    '11:00 am',
    '12:00 pm',
    '01:00 pm',
    '02:00 pm',
    '03:00 pm',
    '04:00 pm',
    '05:00 pm',
    '06:00 pm',
    '07:00 pm',
    '08:00 pm',
    '09:00 pm',
    '10:00 pm',
    '11:00 pm',
  ];

  final List<Color> availableColors = [
    AppColors.yellowColor,
    AppColors.blueColor,
    AppColors.lightGreenColor,
    AppColors.purpleColor,
    AppColors.greyColor,
  ];

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    try {
      setState(() {
        isLoading = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

      final data = await getBookings(token!, formattedDate, formattedDate);

      setState(() {
        bookings = data['data'] ?? {};
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData(
            primaryColor: AppColors.primaryGreen,
            dialogBackgroundColor: AppColors.whiteColor,
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryGreen,
              onPrimary: AppColors.whiteColor,
              onSurface: AppColors.blackColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
      });
      _fetchBookings();
    }
  }

  @override
  Widget build(BuildContext context) {
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
          if (isLoading) {
            return false;
          } else {
            return true;
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.primaryGreen,
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
                    'Mis Reservas',
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      color: AppColors.whiteColor,
                      fontSize: FontSize.scale(context, 20),
                      fontFamily: 'SF-Pro-Text',
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.normal,
                    ),
                  ),
                  leading: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.arrow_back_ios,
                      size: 20,
                      color: AppColors.whiteColor,
                    ),
                    onPressed: () {
                      if (widget.onBackPressed != null) {
                        widget.onBackPressed!();
                      }
                    },
                  ),
                  centerTitle: false,
                ),
              ),
            ),
          ),
          body: isLoading
              ? BookingScreenSkeleton()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),
                    _buildDateSelector(context),
                    SizedBox(height: 20),
                    Expanded(
                      child: _buildBookingTable(),
                    ),
                  ],
                ),
        ),
      );
    });
  }

  Widget _buildDateSelector(BuildContext context) {
    String formattedDate = DateFormat('MMMM dd, yyyy').format(selectedDate);
    bool isToday = DateTime.now().year == selectedDate.year &&
        DateTime.now().month == selectedDate.month &&
        DateTime.now().day == selectedDate.day;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            height: 40,
            decoration: ShapeDecoration(
              color: AppColors.lightBlueColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: AppColors.whiteColor,
                    size: 18,
                  ),
                  onPressed: () {
                    setState(() {
                      selectedDate = selectedDate.subtract(Duration(days: 1));
                    });
                    _fetchBookings();
                  },
                ),
                Text(
                  'Today',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isToday ? AppColors.whiteColor : AppColors.greyColor,
                    fontSize: FontSize.scale(context, 14),
                    fontFamily: 'SF-Pro-Text',
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.normal,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.whiteColor,
                    size: 18,
                  ),
                  onPressed: () {
                    setState(() {
                      selectedDate = selectedDate.add(Duration(days: 1));
                    });
                    _fetchBookings();
                  },
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              _selectDate(context);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
              height: 40,
              decoration: ShapeDecoration(
                color: AppColors.lightBlueColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    formattedDate,
                    style: TextStyle(
                      color: AppColors.whiteColor,
                      fontSize: FontSize.scale(context, 14),
                      fontFamily: 'SF-Pro-Text',
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.normal,
                    ),
                  ),
                  SizedBox(width: 10),
                  SvgPicture.asset(
                    AppImages.bookingCalender,
                    height: 20,
                    width: 20,
                    color: AppColors.whiteColor,
                  ),
                  SizedBox(width: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBookingDetails(BuildContext context, Map<String, dynamic> booking) {
    showModalBottomSheet(
      backgroundColor: AppColors.sheetBackgroundColor,
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final subjectName =
            booking['slot']['subjectGroupSubjects']['subject']['name'];
        final sessionFee = booking['slot']['session_fee'];
        final bookingDate = DateFormat('MMMM dd, yyyy')
            .format(DateTime.parse(booking['start_time']));
        final startTime =
            DateFormat('hh:mm a').format(DateTime.parse(booking['start_time']));
        final endTime =
            DateFormat('hh:mm a').format(DateTime.parse(booking['end_time']));
        final meetingLink = booking['slot']['meta_data']?['meeting_link'] ?? '';
        final subjectImageUrl =
            booking['slot']['subjectGroupSubjects']['image'];

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      subjectImageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subjectName,
                          style: TextStyle(
                            fontSize: 16.0,
                            fontFamily: 'SF-Pro-Text',
                            fontWeight: FontWeight.w600,
                            color: AppColors.blackColor,
                          ),
                        ),
                        SizedBox(height: 5),
                        Row(
                          children: [
                            SvgPicture.asset(
                              AppImages.clockIcon,
                              width: 16,
                              height: 16,
                              color: AppColors.greyColor,
                            ),
                            SizedBox(width: 5),
                            Text(
                              '$startTime - $endTime',
                              style: TextStyle(
                                fontSize: FontSize.scale(context, 12),
                                color: AppColors.greyColor,
                                fontFamily: 'SF-Pro-Text',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Divider(),
              _buildDetailRow('Session Fee', '\$$sessionFee'),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Total enrollment',
                      style: TextStyle(
                        color: AppColors.greyColor,
                        fontSize: FontSize.scale(context, 14),
                        fontWeight: FontWeight.w400,
                        fontFamily: 'SF-Pro-Text',
                      ),
                    ),
                  ),
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.transparent,
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: booking['slot']['students'][0]['image'],
                        placeholder: (context, url) =>
                            CircularProgressIndicator(
                          strokeWidth: 2.0,
                          color: AppColors.primaryGreen,
                        ),
                        errorWidget: (context, url, error) => Icon(Icons.error),
                        fit: BoxFit.cover,
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '${booking['slot']['students'].length} Students',
                    style: TextStyle(
                      color: AppColors.greyColor,
                      fontSize: FontSize.scale(context, 14),
                      fontWeight: FontWeight.w500,
                      fontFamily: 'SF-Pro-Text',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              _buildDetailRow('Date', bookingDate),
              SizedBox(height: 10),
              _buildDetailRow('Time', '$startTime - $endTime'),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _showFullDetailsBottomSheet(context, booking);
                    },
                    child: Text(
                      'View Full Details',
                      style: TextStyle(
                        fontSize: FontSize.scale(context, 16),
                        color: AppColors.blackColor,
                        fontFamily: 'SF-Pro-Text',
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryWhiteColor,
                      minimumSize: Size(50, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (meetingLink.isNotEmpty) {
                        final Uri zoomWebUrl = Uri.parse(meetingLink);
                        try {
                          if (await canLaunchUrl(zoomWebUrl)) {
                            await launchUrl(
                              zoomWebUrl,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        } catch (error) {}
                      }
                    },
                    child: Text(
                      'Join Session',
                      style: TextStyle(
                        fontSize: FontSize.scale(context, 16),
                        color: AppColors.whiteColor,
                        fontFamily: 'SF-Pro-Text',
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      minimumSize: Size(50, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.greyColor,
              fontSize: FontSize.scale(context, 14),
              fontWeight: FontWeight.w400,
              fontFamily: 'SF-Pro-Text',
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppColors.greyColor,
              fontSize: FontSize.scale(context, 14),
              fontWeight: FontWeight.w500,
              fontFamily: 'SF-Pro-Text',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingTable() {
    String formattedDate = DateFormat('MMMM dd, yyyy').format(selectedDate);

    final random = Random();
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.all(
            Radius.circular(10.0),
          ),
          border: Border(
            top: BorderSide(color: AppColors.dividerColor, width: 1),
            bottom: BorderSide(color: AppColors.dividerColor, width: 1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Tiempo',
                    style: TextStyle(
                      color: AppColors.primaryGreen,
                      fontSize: 14,
                      fontFamily: 'SF-Pro-Text',
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.normal,
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 12),
                    width: 1,
                    height: 50,
                  ),
                  Expanded(
                    child: Text(
                      formattedDate,
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontSize: 14,
                        fontFamily: 'SF-Pro-Text',
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.normal,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: AppColors.dividerColor,
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: times.length,
                itemBuilder: (context, index) {
                  final time = times[index];
                  final bookingsAtThisTime =
                      bookings[time] as List<dynamic>? ?? [];

                  final lineHeight = bookingsAtThisTime.isNotEmpty
                      ? bookingsAtThisTime.length * 65.0
                      : 60.0;

                  return Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 70,
                            height: lineHeight,
                            decoration: BoxDecoration(
                              color: bookingsAtThisTime.isNotEmpty
                                  ? AppColors.primaryGreen.withOpacity(0.7)
                                  : AppColors.primaryGreen.withOpacity(0.7),
                            ),
                            child: Center(
                              child: Text(
                                time,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.whiteColor,
                                  fontSize: 12,
                                  fontFamily: 'SF-Pro-Text',
                                  fontWeight: FontWeight.w500,
                                  fontStyle: FontStyle.normal,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: lineHeight,
                              color: bookingsAtThisTime.isNotEmpty
                                  ? AppColors.primaryGreen.withOpacity(0.7)
                                  : AppColors.primaryGreen.withOpacity(0.7),
                              padding: const EdgeInsets.only(left: 10),
                              child: bookingsAtThisTime.isNotEmpty
                                  ? SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(height: 8),
                                          ...bookingsAtThisTime
                                              .map<Widget>((booking) {
                                            return GestureDetector(
                                              onTap: () {
                                                _showBookingDetails(
                                                    context, booking);
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 12.0, right: 15.0),
                                                child: BookingItem(
                                                  time: time,
                                                  subject: booking['slot'][
                                                          'subjectGroupSubjects']
                                                      ['subject']['name'],
                                                  status: booking['status'],
                                                  image: booking['slot'][
                                                          'subjectGroupSubjects']
                                                      ['image'],
                                                  startTime:
                                                      booking['start_time'],
                                                  endTime: booking['end_time'],
                                                  color: availableColors[random
                                                      .nextInt(availableColors
                                                          .length)],
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                          SizedBox(height: lineHeight),
                                        ],
                                      ),
                                    )
                                  : SizedBox(height: lineHeight),
                            ),
                          ),
                        ],
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.whiteColor,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullDetailsBottomSheet(
      BuildContext context, Map<String, dynamic> booking) {
    showModalBottomSheet(
      backgroundColor: AppColors.sheetBackgroundColor,
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final subjectName =
            booking['slot']['subjectGroupSubjects']['subject']['name'];
        final subjectGroup =
            booking['slot']['subjectGroupSubjects']['subject_group']['name'];
        final sessionFee = booking['slot']['session_fee'];
        final type = booking['slot']['space_type'];
        final bookingDate = DateFormat('MMMM dd, yyyy')
            .format(DateTime.parse(booking['start_time']));
        final startTime =
            DateFormat('hh:mm a').format(DateTime.parse(booking['start_time']));
        final endTime =
            DateFormat('hh:mm a').format(DateTime.parse(booking['end_time']));
        final tutorName = booking['tutor']['full_name'];
        final overview =
            booking['slot']['description'] ?? 'No description available';
        final subjectImageUrl =
            booking['slot']['subjectGroupSubjects']['image'];
        final meetingLink = booking['slot']['meta_data']?['meeting_link'] ?? '';
        final leftTime = booking['left_time'];

        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.school, size: 16),
                            SizedBox(width: 8),
                            Text(
                              subjectGroup,
                              style: TextStyle(
                                color: AppColors.greyColor,
                                fontSize: FontSize.scale(context, 13),
                                fontWeight: FontWeight.w400,
                                fontFamily: 'SF-Pro-Text',
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.close,
                              color: AppColors.blackColor, size: 24),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 5),
                    Text(
                      subjectName,
                      style: TextStyle(
                          color: AppColors.blackColor,
                          fontSize: FontSize.scale(context, 20),
                          fontWeight: FontWeight.w600,
                          fontFamily: 'SF-Pro-Text',
                          fontStyle: FontStyle.normal),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.lightBlue,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: SvgPicture.asset(
                                AppImages.dateCalender,
                                width: 16,
                                height: 16,
                                color: AppColors.blue,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Date ',
                              style: TextStyle(
                                  color: AppColors.greyColor,
                                  fontSize: FontSize.scale(context, 14),
                                  fontWeight: FontWeight.w400,
                                  fontFamily: 'SF-Pro-Text',
                                  fontStyle: FontStyle.normal),
                            ),
                          ],
                        ),
                        Text(
                          '$bookingDate',
                          style: TextStyle(
                              color: AppColors.greyColor,
                              fontSize: FontSize.scale(context, 14),
                              fontWeight: FontWeight.w500,
                              fontFamily: 'SF-Pro-Text',
                              fontStyle: FontStyle.normal),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.purpleBorderColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: SvgPicture.asset(
                                AppImages.clockIcon,
                                width: 16,
                                height: 16,
                                color: AppColors.clockColor,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Time ',
                              style: TextStyle(
                                  color: AppColors.greyColor,
                                  fontSize: FontSize.scale(context, 14),
                                  fontWeight: FontWeight.w400,
                                  fontFamily: 'SF-Pro-Text',
                                  fontStyle: FontStyle.normal),
                            ),
                          ],
                        ),
                        Text(
                          '$startTime - $endTime',
                          style: TextStyle(
                              color: AppColors.greyColor,
                              fontSize: FontSize.scale(context, 14),
                              fontWeight: FontWeight.w500,
                              fontFamily: 'SF-Pro-Text',
                              fontStyle: FontStyle.normal),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.yellowBorderColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: SvgPicture.asset(
                                AppImages.userIcon,
                                width: 16,
                                height: 16,
                                color: AppColors.userIconColor,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Total enrollment',
                              style: TextStyle(
                                  color: AppColors.greyColor,
                                  fontSize: FontSize.scale(context, 14),
                                  fontWeight: FontWeight.w400,
                                  fontFamily: 'SF-Pro-Text',
                                  fontStyle: FontStyle.normal),
                            ),
                          ],
                        ),
                        Text(
                          '${booking['slot']['students'].length} ${booking['slot']['students'].length == 1 ? "Student" : "Students"}',
                          style: TextStyle(
                            color: AppColors.greyColor,
                            fontSize: FontSize.scale(context, 14),
                            fontWeight: FontWeight.w500,
                            fontFamily: 'SF-Pro-Text',
                            fontStyle: FontStyle.normal,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.typeBackgroundColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: SvgPicture.asset(
                                AppImages.type,
                                width: 16,
                                height: 16,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Type ',
                              style: TextStyle(
                                  color: AppColors.greyColor,
                                  fontSize: FontSize.scale(context, 14),
                                  fontWeight: FontWeight.w400,
                                  fontFamily: 'SF-Pro-Text',
                                  fontStyle: FontStyle.normal),
                            ),
                          ],
                        ),
                        Text(
                          '$type session',
                          style: TextStyle(
                              color: AppColors.greyColor,
                              fontSize: FontSize.scale(context, 14),
                              fontWeight: FontWeight.w500,
                              fontFamily: 'SF-Pro-Text',
                              fontStyle: FontStyle.normal),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.lightGreen,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: SvgPicture.asset(
                                AppImages.dollarIcon,
                                color: AppColors.darkGreen,
                                width: 16,
                                height: 16,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Session Fee ',
                              style: TextStyle(
                                  color: AppColors.greyColor,
                                  fontSize: FontSize.scale(context, 14),
                                  fontWeight: FontWeight.w400,
                                  fontFamily: 'SF-Pro-Text',
                                  fontStyle: FontStyle.normal),
                            ),
                          ],
                        ),
                        Text(
                          '\$$sessionFee / person ',
                          style: TextStyle(
                              color: AppColors.greyColor,
                              fontSize: FontSize.scale(context, 14),
                              fontWeight: FontWeight.w500,
                              fontFamily: 'SF-Pro-Text',
                              fontStyle: FontStyle.normal),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 5,
                            ),
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.transparent,
                              child: ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: booking['tutor']['image'],
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator(
                                    color: AppColors.primaryGreen,
                                    strokeWidth: 2.0,
                                  ),
                                  errorWidget: (context, url, error) =>
                                      SvgPicture.asset(
                                    AppImages.placeHolder,
                                    fit: BoxFit.cover,
                                    width: 60,
                                    height: 60,
                                    color: AppColors.greyColor,
                                  ),
                                  fit: BoxFit.cover,
                                  width: 32,
                                  height: 32,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Session Tutor ',
                              style: TextStyle(
                                  color: AppColors.greyColor,
                                  fontSize: FontSize.scale(context, 14),
                                  fontWeight: FontWeight.w400,
                                  fontFamily: 'SF-Pro-Text',
                                  fontStyle: FontStyle.normal),
                            ),
                          ],
                        ),
                        Text(
                          '$tutorName',
                          style: TextStyle(
                              color: AppColors.greyColor,
                              fontSize: FontSize.scale(context, 14),
                              fontWeight: FontWeight.w500,
                              fontFamily: 'SF-Pro-Text',
                              fontStyle: FontStyle.normal),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: Image.network(
                        subjectImageUrl,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(height: 20),
                    HtmlWidget(
                      overview,
                      textStyle: TextStyle(
                        fontSize: FontSize.scale(context, 14),
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.speakerBgColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: SvgPicture.asset(
                                AppImages.speaker,
                                color: AppColors.primaryGreen,
                                width: 20,
                                height: 20,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('Session will start in',
                                style: TextStyle(
                                  fontSize: FontSize.scale(context, 14),
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'SF-Pro-Text',
                                )),
                          ],
                        ),
                        Text('$leftTime',
                            style: TextStyle(
                                fontStyle: FontStyle.normal,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'SF-Pro-Text',
                                fontSize: FontSize.scale(context, 16),
                                color: AppColors.primaryGreen)),
                      ],
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        if (meetingLink.isNotEmpty) {
                          final Uri zoomWebUrl = Uri.parse(meetingLink);
                          try {
                            if (await canLaunchUrl(zoomWebUrl)) {
                              await launchUrl(
                                zoomWebUrl,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          } catch (error) {}
                        }
                      },
                      child: Text(
                        'Join Session',
                        style: TextStyle(
                          fontSize: FontSize.scale(context, 16),
                          color: AppColors.whiteColor,
                          fontFamily: 'SF-Pro-Text',
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.normal,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        minimumSize: Size(double.infinity, 40),
                        padding: EdgeInsets.symmetric(horizontal: 15.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class BookingItem extends StatelessWidget {
  final String time;
  final String? subject;
  final String? status;
  final String? image;
  final Color color;
  final String startTime;
  final String endTime;

  BookingItem({
    required this.time,
    this.subject,
    this.status,
    this.image,
    required this.color,
    required this.startTime,
    required this.endTime,
  });

  @override
  Widget build(BuildContext context) {
    return subject != null
        ? Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryWhiteColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 5,
                ),
              ],
              borderRadius: BorderRadius.circular(8),
              border: Border(
                left: BorderSide(color: color, width: 2),
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    image ?? '',
                    width: 30,
                    height: 30,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Flexible(
                            child: Text(
                              subject!,
                              style: TextStyle(
                                color: AppColors.blackColor,
                                fontSize: FontSize.scale(context, 12),
                                fontFamily: 'SF-Pro-Text',
                                fontWeight: FontWeight.w400,
                                fontStyle: FontStyle.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 10),
                          SvgPicture.asset(
                            AppImages.clockIcon,
                            width: 16,
                            height: 16,
                            color: AppColors.greyColor,
                          ),
                          SizedBox(width: 4),
                          Text(
                            _formatTimeRange(startTime, endTime),
                            style: TextStyle(
                              color: AppColors.greyColor,
                              fontSize: FontSize.scale(context, 12),
                              fontFamily: 'SF-Pro-Text',
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        : SizedBox.shrink();
  }

  String _formatTimeRange(String startTime, String endTime) {
    final startDateTime = DateTime.parse(startTime);
    final endDateTime = DateTime.parse(endTime);

    final formattedStartTime = DateFormat('hh:mm a').format(startDateTime);
    final formattedEndTime = DateFormat('hh:mm a').format(endDateTime);

    return '$formattedStartTime - $formattedEndTime';
  }
}

class StudentCalendarScreen extends StatefulWidget {
  const StudentCalendarScreen({Key? key}) : super(key: key);

  @override
  State<StudentCalendarScreen> createState() => _StudentCalendarScreenState();
}

class _StudentCalendarScreenState extends State<StudentCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  String _viewMode = 'month'; // 'month', 'week', 'day'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181F2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181F2A),
        elevation: 0,
        title: const Text('Mi Calendario',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          ToggleButtons(
            borderRadius: BorderRadius.circular(12),
            selectedColor: Colors.white,
            fillColor: Colors.blueAccent.withOpacity(0.2),
            color: Colors.white70,
            isSelected: [
              _viewMode == 'month',
              _viewMode == 'week',
              _viewMode == 'day',
            ],
            onPressed: (index) {
              setState(() {
                _viewMode = ['month', 'week', 'day'][index];
              });
            },
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.calendar_view_month),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.view_week),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.calendar_view_day),
              ),
            ],
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildCalendar(),
      ),
    );
  }

  Widget _buildCalendar() {
    if (_viewMode == 'month') {
      return _buildMonthView();
    } else if (_viewMode == 'week') {
      return _buildWeekView();
    } else {
      return _buildDayView();
    }
  }

  Widget _buildMonthView() {
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final daysInMonth =
        DateUtils.getDaysInMonth(_focusedDay.year, _focusedDay.month);
    final firstWeekday = firstDayOfMonth.weekday;
    final weekDays = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    final days = <DateTime>[];
    for (int i = 0; i < firstWeekday - 1; i++) {
      days.add(firstDayOfMonth.subtract(Duration(days: firstWeekday - 1 - i)));
    }
    for (int i = 0; i < daysInMonth; i++) {
      days.add(DateTime(_focusedDay.year, _focusedDay.month, i + 1));
    }
    while (days.length % 7 != 0) {
      days.add(days.last.add(const Duration(days: 1)));
    }
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white70),
              onPressed: () {
                setState(() {
                  _focusedDay =
                      DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
                });
              },
            ),
            Text(
              '${_monthName(_focusedDay.month)} ${_focusedDay.year}',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.white70),
              onPressed: () {
                setState(() {
                  _focusedDay =
                      DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekDays
              .map((d) => Expanded(
                    child: Center(
                        child: Text(d,
                            style: const TextStyle(
                                color: Colors.white54,
                                fontWeight: FontWeight.bold))),
                  ))
              .toList(),
        ),
        const SizedBox(height: 2),
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              childAspectRatio: 1.1,
            ),
            itemCount: days.length,
            itemBuilder: (context, i) {
              final day = days[i];
              final isToday = DateUtils.isSameDay(day, DateTime.now());
              final isCurrentMonth = day.month == _focusedDay.month;
              return GestureDetector(
                onTap: isCurrentMonth
                    ? () {
                        // Aquí se podría mostrar el detalle del día
                      }
                    : null,
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isToday
                        ? Colors.blueAccent.withOpacity(0.7)
                        : isCurrentMonth
                            ? Colors.white.withOpacity(0.04)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: isCurrentMonth ? Colors.white : Colors.white24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWeekView() {
    final weekDays = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    final today = _focusedDay;
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final days = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white70),
              onPressed: () {
                setState(() {
                  _focusedDay = _focusedDay.subtract(const Duration(days: 7));
                });
              },
            ),
            Text(
              'Semana de ${days.first.day} ${_monthName(days.first.month)}',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.white70),
              onPressed: () {
                setState(() {
                  _focusedDay = _focusedDay.add(const Duration(days: 7));
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekDays
              .map((d) => Expanded(
                    child: Center(
                        child: Text(d,
                            style: const TextStyle(
                                color: Colors.white54,
                                fontWeight: FontWeight.bold))),
                  ))
              .toList(),
        ),
        const SizedBox(height: 2),
        Expanded(
          child: Row(
            children: days
                .map((day) => Expanded(
                      child: GestureDetector(
                        onTap: () {},
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: DateUtils.isSameDay(day, DateTime.now())
                                ? Colors.blueAccent.withOpacity(0.7)
                                : Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(8),
                            border: DateUtils.isSameDay(day, DateTime.now())
                                ? Border.all(color: Colors.white, width: 2)
                                : null,
                          ),
                          height: double.infinity,
                          child: Center(
                            child: Text(
                              '${day.day}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDayView() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white70),
              onPressed: () {
                setState(() {
                  _focusedDay = _focusedDay.subtract(const Duration(days: 1));
                });
              },
            ),
            Text(
              '${_focusedDay.day} ${_monthName(_focusedDay.month)} ${_focusedDay.year}',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.white70),
              onPressed: () {
                setState(() {
                  _focusedDay = _focusedDay.add(const Duration(days: 1));
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Center(
            child: Text(
              'No hay tutorías para este día',
              style: const TextStyle(color: Colors.white54, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  String _monthName(int m) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    return months[m - 1];
  }
}
