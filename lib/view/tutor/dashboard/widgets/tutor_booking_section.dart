import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/tutor/dashboard/widgets/tutor_booking_card.dart';

class TutorBookingsSection extends StatelessWidget {
  final bool isLoading;
  final List<Map<String, dynamic>> bookings;
  final bool isAvailable;
  
  // Callbacks: El dashboard padre nos pasa las funciones para ejecutar
  final Function(int id) onStartSession;
  final Function(String link) onOpenMeet;

  const TutorBookingsSection({
    Key? key,
    required this.isLoading,
    required this.bookings,
    required this.isAvailable,
    required this.onStartSession,
    required this.onOpenMeet,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 150,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.darkBlue.withOpacity(0.3),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.lightBlueColor),
          ),
        ),
      );
    }

    if (bookings.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        // Mapeamos cada reserva a una tarjeta con lógica inyectada
        ...bookings.map((booking) => _buildCardWithAction(booking)).toList(),
      ],
    );
  }

  Widget _buildCardWithAction(Map<String, dynamic> booking) {
    final status = (booking['status'] ?? '').toString().toLowerCase().trim();
    final bookingId = booking['id'];
    final meetLink = booking['meeting_link'] ?? '';
    
    Widget actionButton;

    // LÓGICA DE BOTONES (Traída de tu dashboard original)
    if (status == 'aceptado' || status == 'aceptada') {
      // Estado: Confirmada -> Acción: Iniciar
      actionButton = ElevatedButton.icon(
        onPressed: () => onStartSession(bookingId),
        icon: const Icon(Icons.play_circle_fill_rounded, size: 16, color: Colors.white),
        label: const Text('Iniciar', style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: AppColors.primaryGreen.withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: const Size(0, 36),
        ),
      );
    } else if (status == 'cursando') {
      // Estado: En Curso -> Acción: Entrar a Meet
      if (meetLink.toString().isNotEmpty) {
         actionButton = ElevatedButton.icon(
          onPressed: () => onOpenMeet(meetLink),
          icon: const Icon(Icons.video_call_rounded, size: 16, color: Colors.white),
          label: const Text('Entrar', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: Colors.redAccent.withOpacity(0.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            minimumSize: const Size(0, 36),
          ),
        );
      } else {
        actionButton = Container(
           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
           decoration: BoxDecoration(
             color: Colors.white.withOpacity(0.1), 
             borderRadius: BorderRadius.circular(8)
           ),
           child: const Text('Creando enlace...', style: TextStyle(color: Colors.white54, fontSize: 12))
        );
      }
    } else {
       // Estado: Otro (Pendiente, Completada, etc) -> Acción: Ver
       actionButton = OutlinedButton(
          onPressed: () {}, 
          style: OutlinedButton.styleFrom(
             side: BorderSide(color: AppColors.lightBlueColor.withOpacity(0.5)),
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
             minimumSize: const Size(0, 36),
          ),
          child: const Text('Detalles', style: TextStyle(color: AppColors.lightBlueColor, fontSize: 12)),
       );
    }

    return TutorBookingCard(
      booking: booking,
      actionButton: actionButton, // Inyectamos el botón decidido
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.lightBlueColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.class_, color: AppColors.lightBlueColor, size: 20),
        ),
        const SizedBox(width: 12),
        const Text(
          'Mis Tutorías',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.lightBlueColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.lightBlueColor.withOpacity(0.2))
          ),
          child: Text(
            '${bookings.length}', 
            style: const TextStyle(color: AppColors.lightBlueColor, fontWeight: FontWeight.bold, fontSize: 14)
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
     return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: AppColors.darkBlue.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isAvailable ? AppColors.lightBlueColor.withOpacity(0.1) : AppColors.orangeprimary.withOpacity(0.1),
            width: 1
          )
        ),
        child: Column(
          children: [
             Icon(
               isAvailable ? Icons.check_circle_outline_rounded : Icons.offline_bolt_rounded,
               color: isAvailable ? AppColors.lightBlueColor : AppColors.orangeprimary,
               size: 40
             ),
             const SizedBox(height: 16),
             Text(
               isAvailable ? 'Estás Activo' : 'Modo Offline',
               style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
               textAlign: TextAlign.center,
             ),
             const SizedBox(height: 8),
             Text(
                isAvailable 
                  ? 'Tu perfil es visible para los estudiantes.' 
                  : 'Activa tu disponibilidad para recibir nuevas clases.',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
                textAlign: TextAlign.center,
             )
          ],
        ),
     );
  }
}