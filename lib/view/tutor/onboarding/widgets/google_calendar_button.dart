import 'package:flutter/material.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/services/google_calendar_service.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:provider/provider.dart';

class GoogleCalendarButton extends StatefulWidget {
  const GoogleCalendarButton({Key? key}) : super(key: key);

  @override
  State<GoogleCalendarButton> createState() => _GoogleCalendarButtonState();
}

class _GoogleCalendarButtonState extends State<GoogleCalendarButton> {
  bool _isConnecting = false;

  Future<void> _connectGoogleCalendar() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final userId = authProvider.userId;
    
    if (token == null || userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debes estar autenticado para conectar Google Calendar'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }
    
    setState(() => _isConnecting = true);
    
    try {
      final calendarService = GoogleCalendarService();
      final success = await calendarService.connectWithGoogleCalendar(
        token: token,
        userId: userId,
      );
      
      if (success && mounted) {
        // Actualizar userData con los datos de Google Calendar
        if (authProvider.userData != null && authProvider.userData!['user'] != null) {
          authProvider.userData!['user']['calendar_connected'] = true;
          authProvider.userData!['user']['calendar_info'] = calendarService.calendarInfo;
          await authProvider.setUserData(authProvider.userData!);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Calendar conectado: ${calendarService.currentUserEmail}'),
            backgroundColor: AppColors.brandBlue,
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo conectar Google Calendar'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() => _isConnecting = false);
    }
  }

  Future<void> _disconnectGoogleCalendar() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: No hay token de autenticación'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }
    
    try {
      final calendarService = GoogleCalendarService();
      final success = await calendarService.disconnect(token: token);
      
      // Actualizar userData para desconectar Google Calendar
      if (authProvider.userData != null && authProvider.userData!['user'] != null) {
        authProvider.userData!['user']['calendar_connected'] = false;
        authProvider.userData!['user']['calendar_info'] = null;
        // Guardar timestamp de desconexión para evitar que el backend lo sobrescriba
        authProvider.userData!['user']['calendar_disconnected_at'] = DateTime.now().toIso8601String();
        await authProvider.setUserData(authProvider.userData!);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google Calendar desconectado'),
            backgroundColor: AppColors.primaryGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al desconectar: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userData?['user'];
    
    final calendarConnected = user?['calendar_connected'] == true;
    final calendarInfo = user?['calendar_info'];
    
    // Validación: si calendar_connected es true pero no hay calendar_info válida, mostrar como desconectado
    final hasValidCalendarInfo = calendarInfo != null && 
                                  (calendarInfo['id']?.isNotEmpty == true || 
                                   calendarInfo['summary']?.isNotEmpty == true);
    
    final isConnected = calendarConnected && hasValidCalendarInfo;
    final email = calendarInfo?['summary'] ?? calendarInfo?['id'] ?? '';

    // Obtener tema actual
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mainTextColor = isDark ? Colors.white : Colors.black;
    final innerBgColor = isDark ? const Color(0xFF1E222A) : const Color(0xFFF4F6F9);

    // Si está conectado: mostrar email con botón de desconexión (X)
    if (isConnected) {
      return Container(
        decoration: BoxDecoration(
            color: innerBgColor, borderRadius: BorderRadius.circular(20)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
          leading: Icon(Icons.calendar_today_rounded, color: mainTextColor, size: 22),
          title: Text('Google Calendar',
              style: TextStyle(
                  fontFamily: 'outfit',
                  color: mainTextColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5)),
          subtitle: Text(
            email,
            style: TextStyle(
              fontFamily: 'manrope',
              fontSize: 10,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Icon(Icons.close, color: Colors.grey[400], size: 20),
          onTap: _disconnectGoogleCalendar,
        ),
      );
    }

    // Si NO está conectado: mostrar botón de conexión con chevron
    return Container(
      decoration: BoxDecoration(
          color: innerBgColor, borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        leading: Icon(Icons.calendar_today_rounded, color: mainTextColor, size: 22),
        title: Text('Google Calendar',
            style: TextStyle(
                fontFamily: 'outfit',
                color: mainTextColor,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5)),
        subtitle: Text(
          'Conectar a Google Calendar',
          style: TextStyle(
            fontFamily: 'manrope',
            fontSize: 10,
            color: Colors.grey[600],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: _isConnecting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4285F4)),
                ),
              )
            : Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
        onTap: _isConnecting ? null : _connectGoogleCalendar,
      ),
    );
  }
}
