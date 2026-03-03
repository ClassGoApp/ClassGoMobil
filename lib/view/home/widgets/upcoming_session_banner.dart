import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vibration/vibration.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

import '../../../styles/app_styles.dart';
import '../../components/tutoring_status_cards.dart';

class UpcomingSessionBanner extends StatefulWidget {
  final List<Map<String, dynamic>> bookings;
  const UpcomingSessionBanner({Key? key, required this.bookings})
      : super(key: key);

  @override
  State<UpcomingSessionBanner> createState() => _UpcomingSessionBannerState();

  static bool _areBookingsEqual(
      List<Map<String, dynamic>> a, List<Map<String, dynamic>> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i]['id'] != b[i]['id'] || a[i]['status'] != b[i]['status']) {
        return false;
      }
    }
    return true;
  }

  static int _getBookingsHash(List<Map<String, dynamic>> bookings) {
    return bookings.fold(0,
        (hash, booking) => Object.hash(hash, booking['id'], booking['status']));
  }
}

class _UpcomingSessionBannerState extends State<UpcomingSessionBanner>
    with AutomaticKeepAliveClientMixin {
  late List<Map<String, dynamic>> _bookings;
  int _lastBookingsHash = 0;

  @override
  void initState() {
    super.initState();
    _bookings = widget.bookings;
    _lastBookingsHash = UpcomingSessionBanner._getBookingsHash(_bookings);
  }

  @override
  void didUpdateWidget(covariant UpcomingSessionBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!UpcomingSessionBanner._areBookingsEqual(widget.bookings, _bookings)) {
      setState(() {
        _bookings = widget.bookings;
        _lastBookingsHash = UpcomingSessionBanner._getBookingsHash(_bookings);
      });
    }
  }

  @override
  bool get wantKeepAlive => true;

  void _onJoinSession(Map<String, dynamic> booking) async {
    final url = booking['meeting_url'];
    if (url != null && url is String && url.isNotEmpty) {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el enlace de la sesión')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_bookings.isEmpty) {
      return SizedBox.shrink();
    }

    final booking = _bookings.first;
    final tutor = booking['tutor'] ?? {};
    final subject = booking['subject'] ?? {};

    return Card(
      color: AppColors.lightBlueColor,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundImage: tutor['profile_image'] != null
                  ? CachedNetworkImageProvider(tutor['profile_image'])
                  : null,
              backgroundColor: Colors.white,
              child: tutor['profile_image'] == null
                  ? Icon(Icons.person, color: AppColors.lightBlueColor, size: 32)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Próxima sesión',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tutor['name'] ?? 'Tutor',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subject['name'] ?? '',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        booking['start_time'] ?? '',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.lightBlueColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: () => _onJoinSession(booking),
              icon: Icon(Icons.video_call),
              label: Text('Unirse'),
            ),
          ],
        ),
      ),
    );
  }
}