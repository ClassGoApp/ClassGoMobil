import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_projects/styles/app_styles.dart';

class PaymentWebView extends StatelessWidget {
  final String url;
  final VoidCallback onPaymentSuccess;
  final Function(String) onPaymentCancelled;
  final String cancelMessage;

  PaymentWebView({
    required this.url,
    required this.onPaymentSuccess,
    required this.onPaymentCancelled,
    required this.cancelMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(url)),
        onLoadStop: (controller, url) async {
          if (url.toString().contains("payment_success_url") || url.toString().contains("success")) {
            onPaymentSuccess();
          } else if (url.toString().contains("payment_cancelled") || url.toString().contains("cancel")) {
            onPaymentCancelled(cancelMessage);
          }
        },
      ),
    );
  }
}
