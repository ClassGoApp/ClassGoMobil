import 'package:flutter/material.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_projects/provider/auth_provider.dart';

class PusherService extends ChangeNotifier {
  static final PusherService _instance = PusherService._internal();
  factory PusherService() => _instance;
  PusherService._internal();

  PusherChannelsFlutter? _pusher;
  bool _initialized = false;
  Function(dynamic)? _onSlotBookingStatusChanged;
  String? _currentUserId;
  String? _currentToken;

  Future<void> init({
    required Function(dynamic) onSlotBookingStatusChanged,
    required BuildContext context,
  }) async {
    _onSlotBookingStatusChanged = onSlotBookingStatusChanged;
    if (_initialized) return;

    // Obtener el AuthProvider para acceder al token y userId
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _currentToken = authProvider.token;
    _currentUserId = authProvider.userId?.toString();

    if (_currentToken == null || _currentUserId == null) {
      print('ERROR: No se pudo obtener token o userId para Pusher');
      return;
    }

    print('DEBUG: Configurando Pusher con userId: $_currentUserId');

    _pusher = PusherChannelsFlutter.getInstance();
    await _pusher!.init(
      apiKey: '984d9784cd4fd28ab52f',
      cluster: 'mt1',
      onConnectionStateChange: (currentState, previousState) async {
        print("🔌 CONEXIÓN PUSHER: $currentState (antes: $previousState)");
        if (currentState == 'CONNECTED') {
          print('✅ Pusher conectado exitosamente');
          try {
            final socketId = await _pusher!.getSocketId();
            print('🆔 Socket ID actual: $socketId');
          } catch (e) {
            print('❌ Error obteniendo socket ID: $e');
          }
        } else if (currentState == 'DISCONNECTED') {
          print('❌ Pusher desconectado');
        }
      },
      onError: (message, code, exception) =>
          print("❌ Error Pusher: $message, code: $code, exception: $exception"),
      onEvent: (event) async {
        print('🔔 EVENTO PUSHER RECIBIDO:');
        print('   - Canal: ${event.channelName}');
        print('   - Evento: ${event.eventName}');
        print('   - Data: ${event.data}');
        print('   - UserId: ${event.userId}');

        if (event.eventName == 'pusher_internal:subscription_succeeded') {
          print('🎉 Suscripción exitosa al canal: ${event.channelName}');
        } else if (event.eventName == 'pusher_internal:subscription_error') {
          print('❌ Error de suscripción al canal: ${event.channelName}');
          print('   - Data: ${event.data}');
        }

        if (event.eventName == 'SlotBookingStatusChanged') {
          print('✅ Evento SlotBookingStatusChanged detectado');
          print('📦 Procesando data: ${event.data}');
          if (_onSlotBookingStatusChanged != null) {
            try {
              _onSlotBookingStatusChanged!(event.data);
              print('✅ Callback ejecutado exitosamente');
              notifyListeners();
            } catch (e) {
              print('❌ Error en callback: $e');
            }
          } else {
            print('❌ Callback no está configurado');
          }
        } else if (!event.eventName.startsWith('pusher_internal:')) {
          print('⚠️ Evento no reconocido: ${event.eventName}');
        }
      },
    );

    // Suscribirse solo al canal público
    String channelName = 'public-slot-bookings';
    print('🔗 SUSCRIPCIÓN PUSHER:');
    print('   - Canal: $channelName');
    try {
      await _pusher!.subscribe(channelName: channelName);
      print('✅ Suscripción exitosa al canal: $channelName');
    } catch (e) {
      print('❌ Error al suscribirse al canal: $e');
    }

    await _pusher!.connect();
    _initialized = true;
    print('🚀 Pusher inicializado y conectado');
  }

  void disposePusher() {
    // Solo desuscribirse del canal público
    _pusher?.unsubscribe(channelName: 'public-slot-bookings');
    print('🔌 Desuscrito del canal público: public-slot-bookings');
    _initialized = false;
    super.dispose();
  }

  // Método para actualizar credenciales si cambian
  Future<void> updateCredentials(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    String? newToken = authProvider.token;
    String? newUserId = authProvider.userId?.toString();

    if (newToken != _currentToken || newUserId != _currentUserId) {
      print('DEBUG: Credenciales cambiaron, reiniciando Pusher');
      disposePusher();
      _currentToken = newToken;
      _currentUserId = newUserId;
      _initialized = false;
      // Reinicializar con las nuevas credenciales
      if (_onSlotBookingStatusChanged != null) {
        await init(
          onSlotBookingStatusChanged: _onSlotBookingStatusChanged!,
          context: context,
        );
      }
    }
  }

  // Método para verificar el estado de la suscripción
  void checkSubscriptionStatus() {
    if (_pusher != null && _currentUserId != null) {
      String channelName = 'private-user.$_currentUserId';
      print('🔍 VERIFICANDO SUSCRIPCIÓN:');
      print('   - Canal: $channelName');
      print('   - Inicializado: $_initialized');
      print('   - Pusher: ${_pusher != null ? "Disponible" : "No disponible"}');
      print(
          '   - Callback configurado: ${_onSlotBookingStatusChanged != null ? "SÍ" : "NO"}');
    } else {
      print('❌ No se puede verificar suscripción - Pusher no inicializado');
    }
  }

  // Método para forzar reconexión
  Future<void> forceReconnect(BuildContext context) async {
    print('🔄 Forzando reconexión de Pusher...');
    disposePusher();
    _initialized = false;
    if (_onSlotBookingStatusChanged != null) {
      await init(
        onSlotBookingStatusChanged: _onSlotBookingStatusChanged!,
        context: context,
      );
    }
  }
}
