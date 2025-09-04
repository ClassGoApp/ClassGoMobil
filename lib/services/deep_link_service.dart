import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter_projects/helpers/simple_deep_link_handler.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  bool _isInitialized = false;
  StreamSubscription<Uri>? _linkSub;
  AppLinks? _appLinks;

  /// Inicializa el servicio de deep links
  Future<void> initialize(BuildContext context) async {
    if (_isInitialized) return;
    _isInitialized = true;
    try {
      _appLinks = AppLinks();
      // Manejo en frío (app cerrada)
      final initialUri = await _appLinks!.getInitialAppLink();
      if (initialUri != null) {
        print('DeepLinkService: initialUri detectado: $initialUri');
        await SimpleDeepLinkHandler.handleVerificationLink(
            context, initialUri.toString());
      }
      // Manejo en caliente (app abierta)
      _linkSub = _appLinks!.uriLinkStream.listen((Uri? uri) async {
        if (uri != null) {
          print('DeepLinkService: uriLinkStream detectado: $uri');
          await SimpleDeepLinkHandler.handleVerificationLink(
              context, uri.toString());
        }
      }, onError: (err) {
        print('DeepLinkService: error en uriLinkStream: $err');
      });
      print('Deep link service inicializado y escuchando links (app_links)');
    } catch (e) {
      print('Error al inicializar deep link service: $e');
    }
  }

  /// Maneja un deep link manualmente
  Future<void> handleDeepLink(BuildContext context, String link) async {
    try {
      await SimpleDeepLinkHandler.handleVerificationLink(context, link);
    } catch (e) {
      print('Error al manejar deep link: $e');
    }
  }

  /// Dispone el servicio
  void dispose() {
    _isInitialized = false;
    _linkSub?.cancel();
  }
}
