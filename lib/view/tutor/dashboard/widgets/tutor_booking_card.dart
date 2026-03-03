import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:intl/intl.dart';

class TutorBookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final VoidCallback? onTap;
  /// El botón de acción se inyecta desde fuera para separar la lógica del diseño
  final Widget? actionButton; 

  const TutorBookingCard({
    Key? key,
    required this.booking,
    this.onTap,
    this.actionButton,
  }) : super(key: key);

  Color _getStatusColor(String status) {
    status = status.trim().toLowerCase();
    if (status.contains('vivo') || status == 'cursando') return Colors.redAccent;
    if (status == 'aceptada' || status == 'aceptado') return AppColors.lightBlueColor;
    if (status == 'completada' || status == 'completado') return AppColors.primaryGreen;
    if (status == 'pendiente' || status == 'solicitada') return AppColors.orangeprimary;
    return Colors.grey;
  }

  String _getStatusText(String status) {
    status = status.trim().toLowerCase();
    if (status == 'aceptada' || status == 'aceptado') return 'Confirmada';
    if (status == 'cursando') return 'En Curso';
    return status.isNotEmpty 
      ? status[0].toUpperCase() + status.substring(1) 
      : 'Desconocido';
  }

  @override
  Widget build(BuildContext context) {
    // Parsing seguro de fechas para evitar crashes
    final now = DateTime.now();
    final start = DateTime.tryParse(booking['start_time'] ?? '') ?? now;
    final end = DateTime.tryParse(booking['end_time'] ?? '') ?? now;
    
    // Datos básicos
    String statusRaw = (booking['status'] ?? 'Pendiente').toString();
    final subject = booking['subject_name'] ?? 'Tutoría';
    final student = booking['student_name'] ?? 'Estudiante';
    
    // Lógica visual: Si está en tiempo real y aceptada, visualmente es "En Vivo"
    final isLiveTime = now.isAfter(start) && now.isBefore(end);
    final isConfirmed = statusRaw.toLowerCase().contains('aceptad');
    
    final String displayStatus = (isConfirmed && isLiveTime) ? "En Vivo Ahora" : _getStatusText(statusRaw);
    final Color statusColor = _getStatusColor(statusRaw == 'cursando' ? 'cursando' : (isConfirmed && isLiveTime ? 'en vivo' : statusRaw));

    // Formateo de fecha y hora
    // Nota: Asegúrate de tener inicializado el locale en tu main.dart si usas 'es'
    final dateStr = '${start.day}/${start.month}/${start.year}';
    final timeStr = '${DateFormat('HH:mm').format(start)} - ${DateFormat('HH:mm').format(end)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.darkBlue, // Fondo sólido oscuro para minimalismo
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.lightBlueColor.withOpacity(0.15), 
          width: 1
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Cabecera: Estado y Fecha
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: statusColor.withOpacity(0.5), width: 1)
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 8, color: statusColor),
                          const SizedBox(width: 6),
                          Text(
                            displayStatus.toUpperCase(),
                            style: TextStyle(
                              color: statusColor, 
                              fontSize: 10, 
                              fontWeight: FontWeight.bold, 
                              letterSpacing: 0.5
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 14, color: Colors.white.withOpacity(0.5)),
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // 2. Cuerpo: Icono materia + Textos
                Row(
                  children: [
                    Container(
                      height: 50, width: 50,
                      decoration: BoxDecoration(
                        color: AppColors.lightBlueColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.class_outlined, color: AppColors.lightBlueColor, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject,
                            style: const TextStyle(
                              color: Colors.white, 
                              fontSize: 18, 
                              fontWeight: FontWeight.bold
                            ),
                            maxLines: 1, 
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.person_outline_rounded, size: 14, color: Colors.white60),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  student, 
                                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                Divider(color: Colors.white.withOpacity(0.1), height: 1),
                const SizedBox(height: 12),

                // 3. Footer: Hora y Botón de Acción (LÓGICA INYECTADA)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, color: AppColors.lightBlueColor, size: 16),
                        const SizedBox(width: 6),
                        Text(timeStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ],
                    ),

                    // Si se pasó un botón específico, úsalo. Si no, muestra botón por defecto.
                    actionButton ?? OutlinedButton(
                      onPressed: onTap,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: const Size(0, 36)
                      ),
                      child: const Text("Ver detalles", style: TextStyle(color: Colors.white70, fontSize: 12)),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}