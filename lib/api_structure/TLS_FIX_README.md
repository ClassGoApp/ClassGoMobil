# Solución para Error TLS WRONG_VERSION_NUMBER

## Problema
El error `HandshakeException: Handshake error in client (OS Error: WRONG_VERSION_NUMBER)` ocurre cuando hay problemas con la conexión TLS/SSL entre la aplicación Flutter y el servidor.

## Solución Final Implementada

### 1. Cambio a HTTP Directo
- **Cambio principal**: La aplicación ahora usa `http://classgoapp.com/api` en lugar de `https://classgoapp.com/api`
- Esto evita completamente los problemas TLS/SSL
- El servidor debe soportar conexiones HTTP

### 2. Configuración Simplificada
- Removido el HttpClient personalizado complejo
- Uso directo del cliente HTTP estándar de Flutter
- Configuración más simple y confiable

## Uso

### Para Login
```dart
// La función loginUser ahora usa automáticamente la configuración mejorada
final response = await loginUser(email, password);
```

### Para Otras Peticiones
```dart
// Usar NetworkConfig para otras peticiones
final response = await NetworkConfig.makeRequestWithRetry(
  'https://classgoapp.com/api/endpoint',
  headers,
  body,
);
```

## Configuración de Producción

⚠️ **IMPORTANTE**: En producción, debes:

1. **Remover el callback de certificados inválidos**:
```dart
// Comentar o remover esta línea en producción
client.badCertificateCallback = (X509Certificate cert, String host, int port) {
  return true; // NO usar en producción
};
```

2. **Asegurar que el servidor tenga certificados SSL válidos**
3. **Configurar el servidor para usar TLS 1.2 o superior**

## Debugging

Los logs incluyen información detallada sobre:
- Intentos de conexión
- Errores de certificados
- Respuestas del servidor
- Retry attempts

## Verificación

Para verificar que la solución funciona:
1. Ejecuta la aplicación
2. Intenta hacer login
3. Revisa los logs para ver si se resuelve el error TLS
4. Si persiste, verifica la configuración del servidor
