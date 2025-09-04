# Sistema de Tarjetas de Estado de Tutorías

## Descripción
Este sistema proporciona tarjetas visuales mejoradas para diferentes estados de tutorías, con animaciones y diseños específicos para cada estado.

## Archivo Principal
- **Ubicación**: `lib/view/components/tutoring_status_cards.dart`
- **Clase**: `TutoringStatusCards`

## Estados Soportados

### 1. **PENDIENTE** (`pendiente`)
- **Diseño**: Tarjeta con barras de progreso (1ra completa, 2da animada)
- **Color**: Naranja
- **Mensaje**: "Enseguida se validará tu pago"
- **Icono**: Reloj de arena con animación
- **Características**:
  - Primera barra de progreso rellena
  - Segunda barra con animación de carga
  - Tercera barra gris

### 2. **ACEPTADA** (`aceptada`)
- **Diseño**: Tarjeta con barras de progreso (2 primeras completas)
- **Color**: Verde
- **Mensajes dinámicos**:
  - En hora: "Tu tutor se está preparando..." (con icono rotando)
  - Próxima: "Prepárate para tu tutoría, está muy pronto"
  - Confirmada: "Tutoría confirmada"
- **Características**:
  - Dos primeras barras rellenas
  - Tercera barra con animación si está en hora
  - Icono animado de preparación

### 3. **RECHAZADA** (`rechazada`)
- **Diseño**: Tarjeta con todas las barras grises
- **Color**: Rojo
- **Mensaje**: "Hubo un problema con tu tutoría"
- **Botón**: "Contactar Soporte" (abre WhatsApp)
- **Características**:
  - Todas las barras de progreso grises
  - Información del tutor atenuada
  - Botón de contacto directo

### 4. **CURSANDO** (`cursando`)
- **Diseño**: Tarjeta especial con indicador LIVE
- **Color**: Rojo con borde rojo
- **Mensaje**: "¡La tutoría está en curso!"
- **Características**:
  - Indicador "LIVE" con punto rojo pulsante
  - Botón "Unirse a la reunión" con animaciones
  - Avatar del tutor con animación de pulso
  - Mensaje "¡El tutor te está esperando!"

## Uso en HomeScreen

### Integración
```dart
// En home_screen.dart
import 'package:flutter_projects/view/components/tutoring_status_cards.dart';

// En la función build del UpcomingSessionBanner
return TutoringStatusCards.buildStatusCard(
  booking,
  start,
  subject,
  status,
  tutorName,
  tutorImage,
  _openTutoringLink,
  (booking) {
    // Función para mostrar detalles del booking
  },
);
```

### Parámetros Requeridos
- `booking`: Datos de la reserva
- `start`: Fecha/hora de inicio
- `subject`: Nombre de la materia
- `status`: Estado de la tutoría (pendiente, aceptada, rechazada, cursando)
- `tutorName`: Nombre del tutor
- `tutorImage`: URL de la imagen del tutor
- `onOpenTutoringLink`: Función para abrir link de tutoría
- `onShowBookingDetail`: Función para mostrar detalles

## Características Técnicas

### Animaciones Implementadas
- **Pulse**: Escalado suave para elementos importantes
- **Rotation**: Rotación continua para iconos de carga
- **Scale**: Animaciones de entrada y salida
- **Bounce**: Efectos de rebote para llamadas a la acción

### Barras de Progreso
- **Estado Pendiente**: 1/3 completado
- **Estado Aceptada**: 2/3 completado
- **Estado Cursando**: 3/3 completado
- **Estado Rechazada**: 0/3 (todas grises)

### Colores y Temas
- **Pendiente**: Naranja (#FF9800)
- **Aceptada**: Verde (#4CAF50)
- **Rechazada**: Rojo (#F44336)
- **Cursando**: Rojo (#E53935) con borde rojo

## Funcionalidades Especiales

### WhatsApp Integration
```dart
static void _openWhatsAppSupport() async {
  const phoneNumber = '+1234567890'; // Cambiar por número real
  const message = 'Hola, necesito ayuda con mi tutoría.';
  final url = 'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}';
  
  if (await canLaunch(url)) {
    await launch(url);
  }
}
```

### Animaciones de Estado
- **Pendiente**: Reloj de arena animado
- **Aceptada**: Icono de preparación con rotación
- **Cursando**: Múltiples animaciones (pulse, bounce, scale)
- **Rechazada**: Icono estático de error

## Personalización

### Modificar Colores
```dart
// En _buildPendingCard, _buildAcceptedCard, etc.
color: Colors.orange.withOpacity(0.1), // Cambiar color de fondo
color: Colors.orange, // Cambiar color de texto
```

### Modificar Mensajes
```dart
// En cada función de construcción
Text(
  'Tu mensaje personalizado aquí',
  style: TextStyle(
    color: Colors.orange,
    fontWeight: FontWeight.w600,
    fontSize: 14,
  ),
),
```

### Modificar Animaciones
```dart
// Cambiar duración de animaciones
duration: Duration(milliseconds: 1500), // Ajustar velocidad
tween: Tween(begin: 0.8, end: 1.2), // Ajustar rango
```

## Dependencias Requeridas
```yaml
dependencies:
  url_launcher: ^6.1.14
  cached_network_image: ^3.3.0
```

## Notas de Implementación

### Migración desde HomeScreen
1. **Eliminar** la función `_buildLiveSessionCard` del home_screen.dart
2. **Importar** el nuevo archivo de tarjetas
3. **Reemplazar** la lógica de construcción de tarjetas
4. **Mantener** las funciones de callback existentes

### Optimización
- Las tarjetas se construyen de forma estática para mejor rendimiento
- Las animaciones se optimizan para no afectar el rendimiento
- Las imágenes se cachean automáticamente

### Extensibilidad
- Fácil agregar nuevos estados
- Configuración centralizada de colores y mensajes
- Sistema modular para futuras mejoras