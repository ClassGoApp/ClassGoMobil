# Flujo Completo de Reserva de Tutorías

## Descripción
Este documento describe el flujo completo de reserva de tutorías, desde la búsqueda hasta la confirmación exitosa.

## Flujos Disponibles

### 1. **Tutoría Instantánea** (Flujo Directo)
```
SearchTutorsScreen → InstantTutoringScreen → PaymentQRScreen → BookingSuccessScreen → HomeScreen
```

### 2. **Tutoría Agendada** (Flujo con Selección de Fecha)
```
SearchTutorsScreen → _BookingModal → InstantTutoringScreen → PaymentQRScreen → BookingSuccessScreen → HomeScreen
```

## Detalles del Flujo

### 🔍 **SearchTutorsScreen**
- **Ubicación**: `lib/view/tutor/search_tutors_screen.dart`
- **Funcionalidad**: Búsqueda y listado de tutores
- **Modos**: 
  - `agendar`: Muestra botón "Agendar"
  - `instantanea`: Muestra botón "Empezar tutoría"

### 📅 **_BookingModal** (Solo para modo "agendar")
- **Funcionalidad**: Selección de materia, fecha y hora
- **Parámetros**:
  - `tutorName`: Nombre del tutor
  - `tutorImage`: Imagen del tutor
  - `subjects`: Lista de materias disponibles
  - `tutorId`: ID del tutor
  - `subjectId`: ID de la materia seleccionada

### ⚡ **InstantTutoringScreen**
- **Ubicación**: `lib/view/tutor/instant_tutoring_screen.dart`
- **Funcionalidad**: Confirmación de detalles de la tutoría
- **Navegación**: Al completar → PaymentQRScreen

### 💳 **PaymentQRScreen**
- **Ubicación**: `lib/view/tutor/payment_qr_screen.dart`
- **Funcionalidad**: Proceso de pago y subida de comprobante
- **Navegación**: Al completar → BookingSuccessScreen

### ✅ **BookingSuccessScreen**
- **Ubicación**: `lib/view/tutor/booking_success_screen.dart`
- **Funcionalidad**: Pantalla de éxito con animaciones y sonido
- **Características**:
  - Checkmark animado con Lottie
  - Sonido de éxito automático
  - Cierre automático después de 4 segundos
  - Navegación a HomeScreen con loading

### 🔄 **HomeScreenWithLoading**
- **Funcionalidad**: Pantalla de carga mientras se recarga HomeScreen
- **Duración**: 2 segundos
- **Navegación**: Al completar → HomeScreen

## Implementación Técnica

### Modificaciones Realizadas

#### 1. **SearchTutorsScreen**
```dart
// Agregados imports
import 'package:flutter_projects/view/tutor/payment_qr_screen.dart';
import 'package:flutter_projects/view/tutor/booking_success_screen.dart';

// Modificado _BookingModal para recibir tutorId y subjectId
class _BookingModal extends StatefulWidget {
  final int tutorId;
  final int subjectId;
  // ... otros parámetros
}

// Modificado botón "Reservar" para navegar a InstantTutoringScreen
onPressed: () {
  Navigator.pop(context); // Cerrar modal de agendar
  showModalBottomSheet(
    context: context,
    builder: (context) => InstantTutoringScreen(
      tutorName: widget.tutorName,
      tutorImage: widget.tutorImage,
      subjects: widget.subjects,
      selectedSubject: selectedSubject,
      tutorId: widget.tutorId,
      subjectId: widget.subjectId,
    ),
  );
}
```

#### 2. **PaymentQRScreen**
```dart
// Modificado para navegar a BookingSuccessScreen
Navigator.of(context).pushReplacement(
  MaterialPageRoute(
    builder: (context) => BookingSuccessScreen(
      tutorName: widget.tutorName,
      tutorImage: widget.tutorImage,
      subjectName: widget.selectedSubject,
      sessionDuration: widget.sessionDuration,
      amount: widget.amount,
      sessionTime: DateTime.now(),
    ),
  ),
);
```

#### 3. **BookingSuccessScreen**
```dart
// Agregado cierre automático y navegación con loading
void _startAutoCloseTimer() {
  Future.delayed(Duration(seconds: 4), () {
    if (mounted) {
      _navigateToHomeWithReload();
    }
  });
}

void _navigateToHomeWithReload() {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => HomeScreenWithLoading()),
    (route) => false,
  );
}
```

## Parámetros Clave

### TutorId y SubjectId
- **TutorId**: Se obtiene de `tutor['id']` en SearchTutorsScreen
- **SubjectId**: Se obtiene del primer subject válido con `subject['id']`

### Validación de Subjects
```dart
final firstValidSubject = subjects
    .where((subject) =>
        subject['status'] == 'active' &&
        subject['deleted_at'] == null)
    .firstOrNull;
final subjectId = firstValidSubject?['id'] ?? 1;
```

## Experiencia de Usuario

### Flujo Agendado
1. **Búsqueda** → Usuario busca tutores
2. **Selección** → Usuario selecciona tutor y presiona "Agendar"
3. **Configuración** → Usuario selecciona materia, fecha y hora
4. **Confirmación** → Usuario presiona "Reservar"
5. **Instant** → Se abre vista de confirmación de tutoría
6. **Pago** → Usuario sube comprobante de pago
7. **Éxito** → Se muestra pantalla de éxito con animaciones
8. **Home** → Se recarga HomeScreen con loading

### Características
- **Sin interrupciones**: Flujo fluido entre pantallas
- **Validaciones**: Verificación de datos en cada paso
- **Feedback visual**: Animaciones y sonidos de confirmación
- **Recarga automática**: HomeScreen se actualiza con nueva información

## Notas Técnicas

- Todos los modales usan `isScrollControlled: true` para mejor UX
- Las navegaciones usan `pushReplacement` para evitar stack de pantallas
- El loading screen asegura que HomeScreen se recargue correctamente
- Los parámetros se pasan correctamente entre todas las pantallas