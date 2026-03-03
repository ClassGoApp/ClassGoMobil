import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../styles/app_styles.dart';

class BookingDetailModal extends StatelessWidget {
  final Map<String, dynamic> booking;
  final Map<int, String> highResTutorImages;
  const BookingDetailModal(
      {Key? key, required this.booking, required this.highResTutorImages})
      : super(key: key);

  Future<Map<String, dynamic>?> fetchSlotDetail(int slotId) async {
    final url = Uri.parse('https://classgoapp.com/api/slot-detail/$slotId');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 200 && data['data'] != null) {
        return data['data'];
      }
    }
    return null;
  }

  Future<String?> fetchTutorHDImage(int tutorId) async {
    try {
      final url = Uri.parse(
          'https://classgoapp.com/api/verified-tutors-photos?tutor_id=$tutorId');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] is List && data['data'].isNotEmpty) {
          final item = data['data'].firstWhere(
            (e) => e['id'] == tutorId && e['profile_image'] != null,
            orElse: () => null,
          );
          if (item != null && item['profile_image'] != null) {
            return item['profile_image'] as String;
          }
        }
      }
    } catch (e) {
      // Ignorar error, usar fallback
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final slotId = booking['id'] is int
        ? booking['id']
        : int.tryParse(booking['id'].toString() ?? '');
    return FutureBuilder<Map<String, dynamic>?>(
      future: fetchSlotDetail(slotId ?? 0),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SafeArea(
            child: Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 32,
                bottom: 24 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 24,
                    offset: Offset(0, -8),
                  ),
                ],
              ),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF00B4D8)),
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return SafeArea(
            child: Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 32,
                bottom: 24 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 24,
                    offset: Offset(0, -8),
                  ),
                ],
              ),
              child: Center(
                child: Text('No se pudo cargar el detalle de la tutoría',
                    style: TextStyle(color: Colors.red)),
              ),
            ),
          );
        }
        final data = snapshot.data!;
        final tutor = data['tutor'] ?? {};
        final subject = data['subject']?['name'] ?? 'Materia desconocida';
        final tutorName = tutor['full_name'] ?? 'Tutor desconocido';
        final tutorUserId = tutor['user_id'] is int
            ? tutor['user_id']
            : int.tryParse(tutor['user_id']?.toString() ?? '');
        final status = (data['status'] ?? '').toString();
        final startHour = data['start_time'] ?? '';
        return FutureBuilder<String?>(
          future: tutorUserId != null
              ? fetchTutorHDImage(tutorUserId)
              : Future.value(null),
          builder: (context, hdSnapshot) {
            final hdImage = hdSnapshot.data;
            print('DEBUG: Mostrando imagen HD de tutor en modal: $hdImage');
            return SafeArea(
              child: Container(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 32,
                  bottom: 24 + MediaQuery.of(context).padding.bottom,
                ),
                decoration: BoxDecoration(
                  color: AppColors.darkBlue,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.lightBlueColor.withOpacity(0.18),
                      blurRadius: 24,
                      offset: Offset(0, -8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        margin: EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 38,
                            backgroundColor:
                                AppColors.lightBlueColor.withOpacity(0.18),
                            backgroundImage:
                                (hdImage != null && hdImage.isNotEmpty)
                                    ? NetworkImage(hdImage)
                                    : null,
                            child: (hdImage == null || hdImage.isEmpty)
                                ? Icon(Icons.person,
                                    size: 38, color: AppColors.lightBlueColor)
                                : null,
                          ),
                          SizedBox(height: 10),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.lightBlueColor.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_user,
                                    color: AppColors.lightBlueColor, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'Tutor',
                                  style: TextStyle(
                                    color: AppColors.lightBlueColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            tutorName,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 18),
                    Row(
                      children: [
                        Icon(Icons.book, color: AppColors.lightBlueColor),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            subject,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            color: AppColors.lightBlueColor),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            startHour.isNotEmpty
                                ? 'Hora de inicio: $startHour'
                                : 'Horario no disponible',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: AppColors.lightBlueColor),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Estado: $status',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 28),
                    Center(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.lightBlueColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 32, vertical: 14),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: Colors.white),
                        label: Text('Cerrar',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
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
}