import 'package:flutter/services.dart';

/// Reglas de validación compartidas entre la app móvil y la web (ClassGo).
///
/// La web es la fuente de verdad: estos rangos y expresiones deben coincidir
/// con las validaciones del backend (ProfileController / PersonalDetails) para
/// evitar que un dato pase en un lado y sea rechazado en el otro.
class InputValidators {
  InputValidators._();

  // ─────────────────────────── Nombre / Apellido ───────────────────────────

  /// Solo letras (incluye tildes, ñ y ü). Se permite un guion, apóstrofe o
  /// espacio simple entre palabras (ej. "María-José", "O'Connor", "De la Cruz").
  /// No permite números ni otros caracteres especiales.
  static final RegExp nameRegExp = RegExp(
    r"^[A-Za-zÀ-ÖØ-öø-ÿ]+(?:[ '\-][A-Za-zÀ-ÖØ-öø-ÿ]+)*$",
  );

  /// Caracteres que se permiten mientras se escribe un nombre.
  static final RegExp nameAllowedChars =
      RegExp(r"[A-Za-zÀ-ÖØ-öø-ÿ '\-]");

  static const int nameMaxLength = 100;

  // ─────────────────────────────── Celular ─────────────────────────────────

  /// Solo dígitos, entre 7 y 15 (igual que `updateUserProfile` de la web).
  static final RegExp phoneRegExp = RegExp(r'^[0-9]{7,15}$');

  static const int phoneMaxLength = 15;

  /// Celular permitido en el **registro**: idéntico a `RegisterUserRequest`
  /// del backend (acepta un prefijo opcional de país y luego dígitos,
  /// espacios o guiones). Debe coincidir para que la app no envíe algo que
  /// la API rechace.
  static final RegExp phoneRegisterRegExp =
      RegExp(r'^(\+?\(?\d{1,4}\)?)?[\d\s\-]{7,15}$');

  // ─────────────────────────── Precio por tutoría ──────────────────────────

  /// Monto en Bs por 20 min. Igual que la web: requerido, numérico,
  /// entre 0 y 999999.99, con máximo 2 decimales.
  static const double priceMin = 0;
  static const double priceMax = 999999.99;
  static const int priceMaxDecimals = 2;

  /// Caracteres permitidos mientras se escribe el precio (dígitos y punto).
  static final RegExp priceAllowedChars = RegExp(r'[0-9.]');

  /// Valida un nombre o apellido. Devuelve el mensaje de error o `null`.
  static String? validateName(
    String? value, {
    required String emptyMessage,
    required String invalidMessage,
  }) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return emptyMessage;
    if (v.length > nameMaxLength) return invalidMessage;
    if (!nameRegExp.hasMatch(v)) return invalidMessage;
    return null;
  }

  /// Valida un número de celular (solo dígitos, 7 a 15). Devuelve `null` si es válido.
  static String? validatePhone(
    String? value, {
    required String emptyMessage,
    required String invalidMessage,
  }) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return emptyMessage;
    if (!phoneRegExp.hasMatch(v)) return invalidMessage;
    return null;
  }

  /// Valida el celular del registro con la misma regla que el backend.
  /// Devuelve `null` si es válido.
  static String? validateRegisterPhone(
    String? value, {
    required String emptyMessage,
    required String invalidMessage,
  }) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return emptyMessage;
    if (!phoneRegisterRegExp.hasMatch(v)) return invalidMessage;
    return null;
  }

  /// Valida el precio por tutoría. Devuelve `null` si es válido.
  static String? validatePrice(
    String? value, {
    required String emptyMessage,
    required String invalidMessage,
  }) {
    final v = (value ?? '').trim().replaceAll(',', '.');
    if (v.isEmpty) return emptyMessage;

    final parsed = double.tryParse(v);
    if (parsed == null) return invalidMessage;
    if (parsed < priceMin || parsed > priceMax) return invalidMessage;

    final parts = v.split('.');
    if (parts.length == 2 && parts[1].length > priceMaxDecimals) {
      return invalidMessage;
    }

    return null;
  }
}

/// Formateador para campos de precio: permite solo dígitos, **un** único punto
/// decimal y como máximo [decimalRange] decimales. Evita que se escriban cosas
/// como `1.2.3` o `..` directamente en el input.
class DecimalTextInputFormatter extends TextInputFormatter {
  DecimalTextInputFormatter({
    this.decimalRange = 2,
    this.maxIntegerDigits = 6,
  });

  final int decimalRange;
  final int maxIntegerDigits;

  static final RegExp _structure = RegExp(r'^\d*(\.\d*)?$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    // Permitir borrar todo.
    if (text.isEmpty) return newValue;

    // No permitir un punto como único contenido ("." o ".5" ya se maneja abajo).
    if (text == '.') return oldValue;

    if (!_structure.hasMatch(text)) return oldValue;

    final parts = text.split('.');
    if (parts[0].length > maxIntegerDigits) return oldValue;
    if (parts.length == 2 && parts[1].length > decimalRange) return oldValue;

    return newValue;
  }
}
