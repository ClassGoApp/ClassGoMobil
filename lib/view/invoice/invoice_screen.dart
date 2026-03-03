import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/invoice/skeleton/invoices_screen_skeleton.dart';
import 'package:provider/provider.dart';
import '../../provider/auth_provider.dart';

class InvoicesScreen extends StatefulWidget {
  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  late double screenWidth;
  late double screenHeight;
  List<Map<String, dynamic>> invoices = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchInvoices();
  }

  Future<void> _fetchInvoices() async {
    setState(() {
      isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final response = await getInvoices(token!);

      if (response['status'] == 200) {
        setState(() {
          invoices = List<Map<String, dynamic>>.from(response['data']['list']);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70.0),
        child: Container(
          color: AppColors.whiteColor,
          child: Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: AppBar(
              forceMaterialTransparency: true,
              centerTitle: false,
              backgroundColor: AppColors.whiteColor,
              elevation: 0,
              titleSpacing: 0,
              title: Text(
                'Facturas',
                style: TextStyle(
                  color: AppColors.blackColor,
                  fontSize: FontSize.scale(context, 20),
                  fontFamily: 'SF-Pro-Text',
                  fontWeight: FontWeight.w600,
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
            ),
          ),
        ),
      ),
      body: isLoading
          ? InvoicesScreenSkeleton()
          : invoices.isEmpty
              ? Center(
                  child: Text(
                    'Sin facturas',
                    style: TextStyle(
                      fontSize: FontSize.scale(context, 16),
                      fontFamily: 'SF-Pro-Text',
                      fontWeight: FontWeight.w500,
                      color: AppColors.greyColor,
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: invoices.length,
                        itemBuilder: (context, index) {
                          return InvoiceCard(invoice: invoices[index]);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

class InvoiceCard extends StatelessWidget {
  final Map<String, dynamic> invoice;

  const InvoiceCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    Color statusTextColor;

    final status = invoice['status'] ?? '';
    final formattedStatus =
        status.isNotEmpty ? status[0].toUpperCase() + status.substring(1) : '';

    switch (status) {
      case 'complete':
        statusColor = AppColors.completeStatusColor;
        statusTextColor = AppColors.completeStatusTextColor;
        break;
      case 'processed':
        statusColor = AppColors.redBorderColor;
        statusTextColor = AppColors.redColor;
        break;
      case 'pending':
        statusColor = AppColors.pendingStatusColor;
        statusTextColor = AppColors.blueColor;
        break;
      default:
        statusColor = AppColors.greyColor;
        statusTextColor = AppColors.greyColor;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Order# ',
                            style: TextStyle(
                                color: AppColors.greyColor,
                                fontSize: FontSize.scale(context, 14),
                                fontFamily: 'SF-Pro-Text',
                                fontWeight: FontWeight.w400),
                          ),
                          TextSpan(
                            text: '${invoice['order_id']}',
                            style: TextStyle(
                                color: AppColors.blackColor,
                                fontSize: FontSize.scale(context, 14),
                                fontFamily: 'SF-Pro-Text',
                                fontWeight: FontWeight.w400),
                          ),
                          TextSpan(
                            text: '  ',
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '/  ${invoice['created_at'] ?? ''}',
                      style: TextStyle(
                          color: AppColors.greyColor,
                          fontSize: FontSize.scale(context, 13),
                          fontFamily: 'SF-Pro-Text',
                          fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    formattedStatus,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: statusTextColor,
                      fontSize: FontSize.scale(context, 12),
                      fontFamily: 'SF-Pro-Text',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Text(
                  'Transaction Id   ',
                  style: TextStyle(
                    color: AppColors.greyColor,
                    fontSize: FontSize.scale(context, 14),
                    fontFamily: 'SF-Pro-Text',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Flexible(
                  child: Text(
                    '${invoice['transaction_id'] ?? 'pi_3PqysmlnN7de3xLMIJeIUTSl'}',
                    style: TextStyle(
                      color: AppColors.blackColor,
                      fontSize: FontSize.scale(context, 14),
                      fontFamily: 'SF-Pro-Text',
                      fontWeight: FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Tutor:  ',
                          style: TextStyle(
                              color: AppColors.greyColor,
                              fontSize: FontSize.scale(context, 14),
                              fontFamily: 'SF-Pro-Text',
                              fontWeight: FontWeight.w400),
                        ),
                        TextSpan(
                          text: '${invoice['tutor_name']}',
                          style: TextStyle(
                              color: AppColors.blackColor,
                              fontSize: FontSize.scale(context, 14),
                              fontFamily: 'SF-Pro-Text',
                              fontWeight: FontWeight.w400),
                        ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 10),
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Subject:  ',
                          style: TextStyle(
                              color: AppColors.greyColor,
                              fontSize: FontSize.scale(context, 14),
                              fontFamily: 'SF-Pro-Text',
                              fontWeight: FontWeight.w400),
                        ),
                        TextSpan(
                          text: '${invoice['subject']}',
                          style: TextStyle(
                              color: AppColors.blackColor,
                              fontSize: FontSize.scale(context, 14),
                              fontFamily: 'SF-Pro-Text',
                              fontWeight: FontWeight.w400),
                        ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Amount:  ',
                    style: TextStyle(
                        color: AppColors.greyColor,
                        fontSize: FontSize.scale(context, 14),
                        fontFamily: 'SF-Pro-Text',
                        fontWeight: FontWeight.w400),
                  ),
                  TextSpan(
                    text: '${invoice['price']}',
                    style: TextStyle(
                        color: AppColors.blackColor,
                        fontSize: FontSize.scale(context, 14),
                        fontFamily: 'SF-Pro-Text',
                        fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
