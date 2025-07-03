import 'package:flutter/material.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

class PusherService extends ChangeNotifier {
  static final PusherService _instance = PusherService._internal();
  factory PusherService() => _instance;
  PusherService._internal();

  PusherChannelsFlutter? _pusher;
  bool _initialized = false;
  Function(dynamic)? _onSlotBookingStatusChanged;

  Future<void> init({
    required Function(dynamic) onSlotBookingStatusChanged,
  }) async {
    _onSlotBookingStatusChanged = onSlotBookingStatusChanged;
    if (_initialized) return;
    _pusher = PusherChannelsFlutter.getInstance();
    await _pusher!.init(
      apiKey: '534047a6538015013c28',
      cluster: 'mt1',
      onConnectionStateChange: (currentState, previousState) =>
          print("Conexión Pusher: $currentState (antes: $previousState)"),
      onError: (message, code, exception) =>
          print("Error Pusher: $message, code: $code, exception: $exception"),
      onEvent: (event) {
        print('Evento recibido: \\${event.eventName} - \\${event.data}');
        if (event.eventName == 'SlotBookingStatusChanged') {
          if (_onSlotBookingStatusChanged != null) {
            _onSlotBookingStatusChanged!(event.data);
            notifyListeners();
          }
        }
      },
    );
    await _pusher!.subscribe(channelName: 'slot-bookings');
    await _pusher!.connect();
    _initialized = true;
  }

  void disposePusher() {
    _pusher?.unsubscribe(channelName: 'slot-bookings');
    _initialized = false;
    super.dispose();
  }
}
