import 'package:flutter/material.dart';
import '../../services/google_calendar_service.dart';
import '../../provider/auth_provider.dart';
import 'package:provider/provider.dart';

class CalendarConnectionWidget extends StatefulWidget {
  @override
  _CalendarConnectionWidgetState createState() => _CalendarConnectionWidgetState();
}

class _CalendarConnectionWidgetState extends State<CalendarConnectionWidget> {
  final GoogleCalendarService _calendarService = GoogleCalendarService();
  bool _isLoading = false;

  Future<void> _connectCalendar() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _calendarService.connectCalendar();
      // Mostrar instrucciones
      _showConnectionInstructions();
      
      // Recargar el perfil del usuario para obtener el estado actualizado
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.loadCompleteUserProfile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al conectar: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _disconnectCalendar() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _calendarService.disconnectCalendar();
      
      // Recargar el perfil del usuario para obtener el estado actualizado
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.loadCompleteUserProfile();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Calendar desconectado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al desconectar: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showConnectionInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conectar Google Calendar'),
        content: const Text(
          'Se abrirá tu navegador para autorizar el acceso a Google Calendar.\n\n'
          'Pasos:\n'
          '1. Autoriza el acceso en el navegador\n'
          '2. Regresa a la app\n'
          '3. Toca "Verificar" para confirmar la conexión',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final isConnected = authProvider.userData?['user']?['calendar_connected'] ?? false;
        
        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFF4285F4)),
                    const SizedBox(width: 8),
                    const Text(
                      'Google Calendar',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    if (_isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(
                        isConnected ? Icons.check_circle : Icons.cancel,
                        color: isConnected ? Colors.green : Colors.red,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isConnected 
                    ? 'Google Calendar está conectado'
                    : 'Conecta tu Google Calendar para sincronizar eventos',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                if (!isConnected)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _connectCalendar,
                      icon: const Icon(Icons.link),
                      label: const Text('Conectar Calendar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4285F4),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : () async {
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            await authProvider.loadCompleteUserProfile();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Verificar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[600],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _disconnectCalendar,
                          icon: const Icon(Icons.link_off),
                          label: const Text('Desconectar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

