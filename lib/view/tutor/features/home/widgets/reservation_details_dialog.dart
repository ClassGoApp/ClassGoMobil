import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/student/reservations/services/reservations_service.dart';
import 'package:url_launcher/url_launcher.dart';

const String _kTitleFont = 'outfit';
const String _kBodyFont = 'manrope';

class ReservationDetailsDialog extends StatelessWidget {
  final ReservationItem data;

  const ReservationDetailsDialog({
    Key? key,
    required this.data,
  }) : super(key: key);

  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('pendiente')) return AppColors.brandOrange;
    if (s.contains('aceptad')) return AppColors.neonGreen;
    if (s.contains('cursando')) return AppColors.brandCyan;
    if (s.contains('completad')) return Colors.grey;
    return AppColors.brandCyan;
  }

  Future<void> _openMeetLink(BuildContext context, String link) async {
    var url = link.trim();
    if (url.isEmpty) return;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
      await launchUrl(uri);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace', style: TextStyle(fontFamily: _kBodyFont))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.whiteColor;
    final textColor = isDark ? Colors.white : AppColors.brandBlue;
    final statusColor = _getStatusColor(data.status);

    final neutralCardBg = isDark ? AppColors.cardDarkNeo : Colors.grey.withOpacity(0.05);
    final iconBgColor = isDark ? Colors.white.withOpacity(0.05) : AppColors.brandBlue.withOpacity(0.05);

    final String dateStr = data.start != null ? DateFormat('dd MMM yyyy', 'es').format(data.start!) : 'Sin fecha';
    final String timeStr = data.start != null ? DateFormat('HH:mm').format(data.start!) : '--:--';
    final String endTimeStr = data.end != null ? DateFormat('HH:mm').format(data.end!) : '--:--';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 30,
              offset: const Offset(0, 15)
            )
          ]
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min, 
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.subjectName,
                          style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.w900, fontFamily: _kTitleFont, height: 1.2),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              "ID: #${data.id}",
                              style: const TextStyle(color: AppColors.greyText, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: _kBodyFont),
                            ),
                            const SizedBox(width: 8),
                            Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.greyText, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                data.status.toUpperCase(),
                                style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900, fontFamily: _kTitleFont, letterSpacing: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : AppColors.unfocusedColor, 
                        shape: BoxShape.circle
                      ),
                      child: Icon(Icons.close_rounded, color: isDark ? Colors.white70 : AppColors.greyColor, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: neutralCardBg, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_outline_rounded, color: AppColors.brandBlue, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data.studentName, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15, fontFamily: _kBodyFont)),
                          const SizedBox(height: 2),
                          const Text("Estudiante", style: TextStyle(color: AppColors.greyText, fontSize: 12, fontFamily: _kBodyFont)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: neutralCardBg, borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, color: AppColors.brandCyan, size: 14),
                              const SizedBox(width: 6),
                              Text("FECHA", style: TextStyle(color: isDark ? Colors.white70 : AppColors.textLightSecondary, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: _kTitleFont)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(dateStr, style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 14, fontFamily: _kBodyFont)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: neutralCardBg, borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded, color: AppColors.brandOrange, size: 14),
                              const SizedBox(width: 6),
                              Text("HORA", style: TextStyle(color: isDark ? Colors.white70 : AppColors.textLightSecondary, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: _kTitleFont)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text("$timeStr - $endTimeStr", style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 14, fontFamily: _kBodyFont)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (data.meetingLink.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: neutralCardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? AppColors.dividerDark : AppColors.dividerLight, width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.neonGreen.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.videocam_rounded, color: AppColors.neonGreen, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _openMeetLink(context, data.meetingLink),
                          behavior: HitTestBehavior.opaque,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Enlace de Reunión", style: TextStyle(color: AppColors.textLightSecondary, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: _kTitleFont)),
                              const SizedBox(height: 4),
                              Text(
                                data.meetingLink,
                                style: TextStyle(color: textColor, fontSize: 13, decoration: TextDecoration.underline, fontFamily: _kBodyFont),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        height: 30,
                        width: 1,
                        color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, color: AppColors.greyText, size: 20),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: data.meetingLink));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Enlace copiado', style: TextStyle(fontFamily: _kBodyFont))),
                          );
                        },
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              if (data.meetingLink.isEmpty) const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: isDark ? AppColors.dividerDark : AppColors.dividerLight, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text("Cerrar", style: TextStyle(color: isDark ? Colors.white70 : AppColors.greyColor, fontWeight: FontWeight.bold, fontFamily: _kTitleFont, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}