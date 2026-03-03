import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TutoringStatusCards {
  // Función principal para construir la tarjeta según el estado
  static Widget buildStatusCard(
    Map<String, dynamic> booking,
    DateTime start,
    String subject,
    String status,
    String tutorName,
    String? tutorImage,
    Function(Map<String, dynamic>) onOpenTutoringLink,
    Function(Map<String, dynamic>) onShowBookingDetail,
  ) {
    print('🎨 === TUTORING_STATUS_CARDS DEBUG ===');
    print('🎨 Status recibido: $status');
    print('🎨 Status tipo: ${status.runtimeType}');
    print('🎨 Status longitud: ${status.length}');
    print('🎨 Status bytes: ${status.codeUnits}');
    print('🎨 TutorName recibido: $tutorName');
    print('🎨 Subject recibido: $subject');
    print('🎨 Booking ID: ${booking['id']}');

    switch (status) {
      case 'pendiente':
        print('✅ CASO PENDIENTE EJECUTADO');
        return _buildPendingCard(
            booking, start, subject, tutorName, tutorImage);
      case 'aceptada':
      case 'aceptado':
        print('✅ CASO ACEPTADA EJECUTADO');
        return _buildAcceptedCard(
            booking, start, subject, tutorName, tutorImage);
      case 'rechazada':
      case 'rechazado':
        print('✅ CASO RECHAZADA EJECUTADO');
        return _buildRejectedCard(
            booking, start, subject, tutorName, tutorImage);
      case 'cursando':
        print('✅ CASO CURSANDO EJECUTADO');
        return _buildLiveCard(booking, start, subject, tutorName, tutorImage,
            onOpenTutoringLink, onShowBookingDetail);
      default:
        print('❌ CASO DEFAULT EJECUTADO - Status no reconocido: "$status"');
        return _buildDefaultCard(
            booking, start, subject, tutorName, tutorImage);
    }
  }

  // Tarjeta para estado PENDIENTE
  static Widget _buildPendingCard(
    Map<String, dynamic> booking,
    DateTime start,
    String subject,
    String tutorName,
    String? tutorImage,
  ) {
    print('🟡 === CONSTRUYENDO TARJETA PENDIENTE ===');
    print('🟡 TutorName: $tutorName');
    print('🟡 Subject: $subject');
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFF2C3E50),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Barra de progreso elegante
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.lightBlueColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.lightBlueColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.lightBlueColor),
                    ),
                  ),
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.lightBlueColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Contenido principal
            Row(
              children: [
                // Avatar del tutor con borde elegante
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: AppColors.lightBlueColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.lightBlueColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: tutorImage != null
                        ? Image.network(
                            tutorImage,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 30),
                          )
                        : Icon(Icons.person, color: Colors.white, size: 30),
                  ),
                ),
                SizedBox(width: 12),

                // Información del tutor
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tutorName,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        subject,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Inicia a las ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: AppColors.lightBlueColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Imagen personalizada de estado
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.lightBlueColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.lightBlueColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/images/pendienteA.png',
                      fit: BoxFit.contain,
                      width: 24,
                      height: 24,
                      errorBuilder: (context, error, stackTrace) {
                        print('❌ Error cargando imagen pendienteA.png: $error');
                        return Icon(
                          Icons.pending_actions,
                          color: AppColors.lightBlueColor,
                          size: 24,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Mensaje de estado elegante
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.lightBlueColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.lightBlueColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.hourglass_empty,
                    color: AppColors.lightBlueColor,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Enseguida se validará tu pago',
                      style: TextStyle(
                        color: AppColors.lightBlueColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tarjeta para estado ACEPTADA
  static Widget _buildAcceptedCard(
    Map<String, dynamic> booking,
    DateTime start,
    String subject,
    String tutorName,
    String? tutorImage,
  ) {
    print('🟢 === CONSTRUYENDO TARJETA ACEPTADA ===');
    print('🟢 TutorName: $tutorName');
    print('🟢 Subject: $subject');

    final now = DateTime.now();
    final isInTime = now.isAfter(start.subtract(Duration(minutes: 15))) &&
        now.isBefore(start.add(Duration(minutes: 30)));
    final isSoon = start.difference(now).inMinutes <= 30 &&
        start.difference(now).inMinutes > 0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFF2C3E50),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Barra de progreso elegante
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.lightBlueColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.lightBlueColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.lightBlueColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: isInTime
                        ? LinearProgressIndicator(
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.lightBlueColor),
                          )
                        : null,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Contenido principal
            Row(
              children: [
                // Avatar del tutor con borde elegante
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: AppColors.lightBlueColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.lightBlueColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: tutorImage != null
                        ? Image.network(
                            tutorImage,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 30),
                          )
                        : Icon(Icons.person, color: Colors.white, size: 30),
                  ),
                ),
                SizedBox(width: 12),

                // Información del tutor
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tutorName,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        subject,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Inicia a las ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: AppColors.lightBlueColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Imagen personalizada de estado
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.lightBlueColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.lightBlueColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/images/aceptadaA.png',
                      fit: BoxFit.contain,
                      width: 24,
                      height: 24,
                      errorBuilder: (context, error, stackTrace) {
                        print('❌ Error cargando imagen aceptadaA.png: $error');
                        return Icon(
                          Icons.check_circle,
                          color: AppColors.lightBlueColor,
                          size: 24,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Mensaje de estado elegante
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.lightBlueColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.lightBlueColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isInTime ? Icons.sync : Icons.schedule,
                    color: AppColors.lightBlueColor,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isInTime
                          ? 'Tu tutor se está preparando...'
                          : isSoon
                              ? 'Prepárate para tu tutoría, está muy pronto'
                              : 'Tutoría confirmada',
                      style: TextStyle(
                        color: AppColors.lightBlueColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tarjeta para estado RECHAZADA
  static Widget _buildRejectedCard(
    Map<String, dynamic> booking,
    DateTime start,
    String subject,
    String tutorName,
    String? tutorImage,
  ) {
    print('🔴 === CONSTRUYENDO TARJETA RECHAZADA ===');
    print('🔴 TutorName: $tutorName');
    print('🔴 Subject: $subject');

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFF2C3E50),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Barra de progreso elegante (todas en gris)
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Contenido principal
            Row(
              children: [
                // Avatar del tutor con borde elegante
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: AppColors.lightBlueColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.lightBlueColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: tutorImage != null
                        ? Image.network(
                            tutorImage,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 30),
                          )
                        : Icon(Icons.person, color: Colors.white, size: 30),
                  ),
                ),
                SizedBox(width: 12),

                // Información del tutor
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tutorName,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        subject,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Inicia a las ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: AppColors.lightBlueColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Imagen personalizada de estado
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.lightBlueColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.lightBlueColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/images/rechazada.png',
                      fit: BoxFit.contain,
                      width: 24,
                      height: 24,
                      errorBuilder: (context, error, stackTrace) {
                        print('❌ Error cargando imagen rechazada.png: $error');
                        return Icon(
                          Icons.cancel,
                          color: AppColors.lightBlueColor,
                          size: 24,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Mensaje de estado elegante
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.lightBlueColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.lightBlueColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.lightBlueColor,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hubo un problema, contáctanos para solucionarlo',
                      style: TextStyle(
                        color: AppColors.lightBlueColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _openWhatsAppSupport(),
                    icon: Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.white,
                      size: 16,
                    ),
                    label: Text(
                      'Soporte',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lightBlueColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tarjeta para estado CURSANDO (implementación completa)
  static Widget _buildLiveCard(
    Map<String, dynamic> booking,
    DateTime start,
    String subject,
    String tutorName,
    String? tutorImage,
    Function(Map<String, dynamic>) onOpenTutoringLink,
    Function(Map<String, dynamic>) onShowBookingDetail,
  ) {
    final startTime =
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: () => onShowBookingDetail(booking),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.8, end: 1.0),
        duration: Duration(milliseconds: 300),
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF2C3E50),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fila superior: Información del tutor y hora de inicio
                  Row(
                    children: [
                      // Foto del tutor con animación de pulso
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.9, end: 1.1),
                        duration: Duration(milliseconds: 1500),
                        builder: (context, pulseValue, child) {
                          return Transform.scale(
                            scale: pulseValue,
                            child: CircleAvatar(
                              radius: 20,
                              backgroundImage:
                                  tutorImage != null && tutorImage.isNotEmpty
                                      ? CachedNetworkImageProvider(tutorImage)
                                      : null,
                              child: tutorImage == null || tutorImage.isEmpty
                                  ? Icon(Icons.person,
                                      color: Colors.white, size: 18)
                                  : null,
                            ),
                          );
                        },
                      ),
                      SizedBox(width: 12),
                      // Nombre del tutor
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tutorName,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            // Tag de tutor
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Color(0xFF4a90e2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.school,
                                      color: Colors.white, size: 12),
                                  SizedBox(width: 4),
                                  Text(
                                    'Tutor',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Hora de inicio con animación
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.8, end: 1.0),
                        duration: Duration(milliseconds: 800),
                        builder: (context, animValue, child) {
                          return Transform.scale(
                            scale: animValue,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Color(0xFF4a90e2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Inició a las $startTime',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Indicador LIVE con animación
                  Row(
                    children: [
                      // Punto rojo pulsante
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.5, end: 1.0),
                        duration: Duration(milliseconds: 1000),
                        builder: (context, pulseValue, child) {
                          return Transform.scale(
                            scale: pulseValue,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(width: 6),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),

                  // Mensaje de estado con animación de pulso
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.95, end: 1.05),
                    duration: Duration(milliseconds: 2000),
                    builder: (context, pulseValue, child) {
                      return Transform.scale(
                        scale: pulseValue,
                        child: Text(
                          '¡La tutoría está en curso!',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 8),

                  // Mensaje instructivo con icono animado
                  Row(
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.8, end: 1.2),
                        duration: Duration(milliseconds: 1200),
                        builder: (context, bounceValue, child) {
                          return Transform.scale(
                            scale: bounceValue,
                            child: Icon(
                              Icons.notifications_active,
                              color: Colors.orange,
                              size: 16,
                            ),
                          );
                        },
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '¡El tutor te está esperando!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),

                  // Materia
                  Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Color(0xFF4a90e2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(Icons.book, color: Colors.white, size: 12),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          subject,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Botón de unirse a la reunión con animación mejorada
                  GestureDetector(
                    onTap: () => onOpenTutoringLink(booking),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.95, end: 1.0),
                      duration: Duration(milliseconds: 800),
                      builder: (context, animValue, child) {
                        return Transform.scale(
                          scale: animValue,
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                                vertical: 14, horizontal: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.red.shade600,
                                  Colors.red.shade500,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Icono con animación de pulso
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.8, end: 1.2),
                                  duration: Duration(milliseconds: 1200),
                                  builder: (context, pulseValue, child) {
                                    return Transform.scale(
                                      scale: pulseValue,
                                      child: Icon(
                                        Icons.videocam,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    );
                                  },
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Unirse a la reunión',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(width: 10),
                                // Flecha indicativa
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Tarjeta por defecto para estados no reconocidos
  static Widget _buildDefaultCard(
    Map<String, dynamic> booking,
    DateTime start,
    String subject,
    String tutorName,
    String? tutorImage,
  ) {
    print('🔵 === CONSTRUYENDO TARJETA DEFAULT ===');
    print('🔵 TutorName: $tutorName');
    print('🔵 Subject: $subject');

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[700]!,
            Colors.grey[600]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Barra de progreso (todas grises)
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Contenido principal
            Row(
              children: [
                // Foto del tutor
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.grey.withOpacity(0.5), width: 2),
                  ),
                  child: ClipOval(
                    child: tutorImage != null && tutorImage.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: tutorImage,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 30),
                          )
                        : Icon(Icons.person, color: Colors.white, size: 30),
                  ),
                ),
                SizedBox(width: 12),

                // Información del tutor
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tutorName,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subject,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                // Icono de estado
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.help_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Mensaje de estado
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Estado no reconocido: ${booking['status']}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Función para abrir WhatsApp
  static void _openWhatsAppSupport() async {
    const phoneNumber = '+59177573997'; // Número de soporte actualizado
    const message = 'Hola, necesito ayuda con mi tutoría.';
    final url =
        'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}';

    try {
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        print('No se pudo abrir WhatsApp');
      }
    } catch (e) {
      print('Error al abrir WhatsApp: $e');
    }
  }
}
