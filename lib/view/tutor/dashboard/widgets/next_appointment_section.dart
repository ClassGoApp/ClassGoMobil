import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/tutor/features/home/widgets/reservation_details_dialog.dart';
import 'package:flutter_projects/view/tutor/features/home/providers/tutor_home_provider.dart';
import 'package:flutter_projects/view/tutor/features/home/widgets/start_session_dialog.dart';
import 'package:provider/provider.dart';

const String _kTitleFont = 'outfit';
const String _kBodyFont = 'manrope';

class AppointmentModel {
  final int id;
  final String title;
  final String studentName;
  final String date;
  final String time;
  final String endTime;
  final String status;
  final String meetLink;

  AppointmentModel({
    required this.id,
    required this.title,
    required this.studentName,
    required this.date,
    required this.time,
    required this.endTime,
    required this.status,
    this.meetLink = '',
  });
}

class NextAppointmentSection extends StatefulWidget {
  // Se recibe una list si está vacia, mostramos el "empty state" 
  final List<AppointmentModel> appointments;

  const NextAppointmentSection({
    Key? key,
    required this.appointments,
  }) : super(key: key);

  @override
  State<NextAppointmentSection> createState() => _NextAppointmentSectionState();
}

class _NextAppointmentSectionState extends State<NextAppointmentSection> {
  final PageController _pageController = PageController(viewportFraction: 1.0);
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Tu Próxima Cita",
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 20,
                  fontFamily: _kTitleFont,
                  fontWeight: FontWeight.w900,
                  height: 1.4,
                ),
              ),
              if (widget.appointments.length > 1)
                Row(
                  children: List.generate(
                    widget.appointments.length,
                    (index) => _buildDot(index),
                  ),
                ),
            ],
          ),
        ),

        // EMPTY STATE
        SizedBox(
          height: 200,
          child: widget.appointments.isEmpty
              ? const _EmptyStateCard()
              : PageView.builder(
                  controller: _pageController,
                  itemCount: widget.appointments.length,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (int index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _AppointmentCard(
                        data: widget.appointments[index],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // Widget del puntito indicador
  Widget _buildDot(int index) {
    bool isActive = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(left: 6),
      height: 8,
      width: isActive ? 20 : 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.brandCyan : Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel data;

  const _AppointmentCard({Key? key, required this.data}) : super(key: key);

  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('pendiente')) return AppColors.brandOrange;
    if (s.contains('aceptad')) return AppColors.neonGreen; // Color brillante para Aceptado
    if (s.contains('cursando')) return AppColors.brandBlue;
    if (s.contains('completad')) return Colors.grey;
    return AppColors.brandCyan;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statusColor = _getStatusColor(data.status);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151A24) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: !isDark
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ]
            : [
                BoxShadow(
                  color: Colors.white.withOpacity(0.02),
                  spreadRadius: 1,
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // FILA SUPERIOR: Texto y Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.brandBlue,
                        fontSize: 24,
                        fontFamily: _kTitleFont,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Estudiante
                    Row(
                      // crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          size: 16,
                          color: isDark ? Colors.grey : Colors.grey[600],
                        ),
                        
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            "con ${data.studentName}",
                            style: TextStyle(
                              color: isDark ? Colors.grey : Colors.grey[700],
                              fontSize: 16,
                              fontFamily: _kBodyFont,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        // Capsula de Fecha
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : AppColors.brandBlue.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.brandCyan),
                              const SizedBox(width: 4),
                              Text(
                                data.date,
                                style: TextStyle(
                                  color: isDark ? Colors.white70 : AppColors.brandBlue,
                                  fontSize: 12,
                                  fontFamily: _kBodyFont,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),
                        // Cápsula de Rango de Horas

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : AppColors.brandBlue.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.access_time_rounded, size: 12, color: AppColors.brandOrange),
                              const SizedBox(width: 4),
                              Text(
                                "${data.time} - ${data.endTime}",
                                style: TextStyle(
                                  color: isDark ? Colors.white70 : AppColors.brandBlue,
                                  fontSize: 12,
                                  fontFamily: _kBodyFont,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              // BADGE "ESTADO"
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: statusColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      data.status.toLowerCase().contains('cursando')
                          ? Icons.play_circle_fill
                          : Icons.access_time_rounded,
                      size: 12,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      data.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontFamily: _kBodyFont,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),

          // FILA INFERIOR: Botones de Acción
          Builder(builder: (context) {
            final provider = Provider.of<TutorHomeProvider>(context, listen: false);
            final s = data.status.toLowerCase();
            final isCursando = s.contains('cursando');

            return Row(
              children: [
                // 1. BOTÓN BLANCO "DETALLES"
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => ReservationDetailsDialog(
                          subject: data.title,
                          studentName: data.studentName,
                          date: data.date,
                          time: data.time,
                          endTime: data.endTime,
                          message: "Hola, necesito ayuda con este tema. ¡Gracias!",
                        ),
                      );
                    },
                    icon: Icon(Icons.calendar_today_outlined,
                        size: 16,
                        color: isDark ? Colors.white : AppColors.brandBlue),
                    label: Text(
                      "Detalles",
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.brandBlue,
                        fontWeight: FontWeight.bold,
                        fontFamily: _kBodyFont,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isDark ? Colors.white24 : AppColors.brandBlue.withOpacity(0.2),
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // 2. BOTÓN DE ACCIÓN ("INICIAR" O "ENTRAR")
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (isCursando) {
                        if (data.meetLink.isNotEmpty) {
                          provider.openMeetLink(context, data.meetLink);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('El enlace de Meet aún no está disponible.', style: TextStyle(fontFamily: _kBodyFont)),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      } else {
                        showDialog(
                          context: context,
                          builder: (ctx) => StartSessionDialog(
                            studentName: data.studentName,
                            onConfirm: () async {
                              bool success = await provider.changeBookingStatusToCursando(context, data.id);
                              if (success) {
                                if (data.meetLink.isNotEmpty) {
                                  provider.openMeetLink(context, data.meetLink);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Reunión iniciada, esperando enlace...', style: TextStyle(fontFamily: _kBodyFont)),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        );
                      }
                    },
                    icon: Icon(
                      isCursando ? Icons.video_call_rounded : Icons.play_arrow_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                    label: Text(
                      isCursando ? "Entrar" : "Iniciar",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: _kBodyFont,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCursando ? Colors.redAccent : AppColors.brandOrange,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151A24) : Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.1),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.weekend_rounded,
              size: 40,
              color: isDark ? Colors.white24 : Colors.grey[300],
            ),
            const SizedBox(height: 12),
            Text(
              "¡Todo despejado!",
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.brandBlue,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: _kTitleFont,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "No tienes citas programadas para hoy.",
              style: TextStyle(
                color: isDark ? Colors.grey : Colors.grey[500],
                fontSize: 14,
                fontFamily: _kBodyFont,
              ),
            ),
          ],
        ),
      ),
    );
  }
}