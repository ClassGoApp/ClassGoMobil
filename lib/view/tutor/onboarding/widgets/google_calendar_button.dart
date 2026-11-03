import 'package:flutter/material.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/services/google_calendar_service.dart';
import 'package:provider/provider.dart';

class GoogleCalendarButton extends StatefulWidget {
  const GoogleCalendarButton({Key? key}) : super(key: key);

  @override
  State<GoogleCalendarButton> createState() => _GoogleCalendarButtonState();
}

class _GoogleCalendarButtonState extends State<GoogleCalendarButton>
    with WidgetsBindingObserver {
  final _calendar = GoogleCalendarService();
  bool _isConnecting = false;
  String? _pendingToken;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final token = _pendingToken;
    if (state == AppLifecycleState.resumed && token != null) {
      _pendingToken = null;
      _confirmConnection(token);
    }
  }

  Future<void> _connectGoogleCalendar() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) {
      _message('Inicia sesión para conectar Google Calendar.');
      return;
    }

    setState(() => _isConnecting = true);
    try {
      if (await _refreshStatus(auth, token) ||
          !mounted ||
          auth.token != token) {
        return;
      }
      setState(() => _pendingToken = token);
      await _calendar.openAuthorization(token: token);
    } catch (_) {
      _pendingToken = null;
      _message('No se pudo abrir la conexión con Google Calendar.');
    } finally {
      if (mounted && _pendingToken == null) {
        setState(() => _isConnecting = false);
      }
    }
  }

  void _verifyPendingConnection() {
    final token = _pendingToken;
    if (token == null) return;
    _pendingToken = null;
    _confirmConnection(token);
  }

  Future<void> _confirmConnection(String token) async {
    try {
      final auth = context.read<AuthProvider>();
      if (auth.token != token) return;
      final connected = await _refreshStatus(auth, token);
      _message(connected
          ? 'Google Calendar conectado.'
          : 'Google Calendar no confirmó la conexión.');
    } catch (_) {
      _message('No se pudo verificar la conexión con Google Calendar.');
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  Future<bool> _refreshStatus(AuthProvider auth, String token) async {
    final status = await _calendar.getConnectionStatus(token: token);
    if (!mounted || auth.token != token) return false;
    final connected = status['connected'] == true;
    await _saveStatus(auth, connected, status['calendar_info']);
    return connected;
  }

  Future<void> _saveStatus(
      AuthProvider auth, bool connected, Object? info) async {
    final data = auth.userData;
    final user = data?['user'];
    if (data == null || user is! Map<String, dynamic>) return;
    user['calendar_connected'] = connected;
    user['calendar_info'] = connected ? info : null;
    if (connected) {
      user.remove('calendar_disconnected_at');
    } else {
      user['calendar_disconnected_at'] = DateTime.now().toIso8601String();
    }
    await auth.setUserData(data);
  }

  Future<void> _disconnectGoogleCalendar() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null || _isConnecting) return;
    setState(() => _isConnecting = true);
    try {
      await _calendar.disconnect(token: token);
      if (!mounted || auth.token != token) return;
      await _saveStatus(auth, false, null);
      _message('Google Calendar desconectado.');
    } catch (_) {
      _message('No se pudo desconectar Google Calendar.');
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userData?['user'];

    final isConnected = user?['calendar_connected'] == true;
    final calendarInfo = user?['calendar_info'];
    final summary = calendarInfo is Map ? calendarInfo['summary'] : null;
    final calendarId = calendarInfo is Map ? calendarInfo['id'] : null;
    final connectedLabel = summary is String && summary.trim().isNotEmpty
        ? summary
        : calendarId is String && calendarId.trim().isNotEmpty
            ? calendarId
            : 'Conectado';

    // Obtener tema actual
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mainTextColor = isDark ? Colors.white : Colors.black;
    final innerBgColor =
        isDark ? const Color(0xFF1E222A) : const Color(0xFFF4F6F9);

    // Si está conectado: mostrar email con botón de desconexión (X)
    if (isConnected) {
      return Container(
        decoration: BoxDecoration(
            color: innerBgColor, borderRadius: BorderRadius.circular(20)),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
          leading: Icon(Icons.calendar_today_rounded,
              color: mainTextColor, size: 22),
          title: Text('Google Calendar',
              style: TextStyle(
                  fontFamily: 'outfit',
                  color: mainTextColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5)),
          subtitle: Text(
            connectedLabel,
            style: TextStyle(
              fontFamily: 'manrope',
              fontSize: 10,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Icon(Icons.close, color: Colors.grey[400], size: 20),
          onTap: _isConnecting ? null : _disconnectGoogleCalendar,
        ),
      );
    }

    // Si NO está conectado: mostrar botón de conexión con chevron
    return Container(
      decoration: BoxDecoration(
          color: innerBgColor, borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        leading:
            Icon(Icons.calendar_today_rounded, color: mainTextColor, size: 22),
        title: Text('Google Calendar',
            style: TextStyle(
                fontFamily: 'outfit',
                color: mainTextColor,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5)),
        subtitle: Text(
          _pendingToken != null
              ? 'Verificar conexión'
              : 'Conectar a Google Calendar',
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
        onTap: _pendingToken != null
            ? _verifyPendingConnection
            : (_isConnecting ? null : _connectGoogleCalendar),
      ),
    );
  }
}
