import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';

/// Utilidades compartidas para los materiales de apoyo.
class MaterialFileUtils {
  /// Icono y color según la extensión del archivo.
  static (IconData, Color) iconFor(AttachmentDisplay att) {
    final ext = att.extension.toLowerCase();
    if (ext == 'pdf') return (Icons.picture_as_pdf, AppColors.redColor);
    if (['doc', 'docx', 'odt'].contains(ext)) {
      return (Icons.description, AppColors.blueColor);
    }
    if (['xls', 'xlsx', 'ods'].contains(ext)) {
      return (Icons.table_chart_rounded, AppColors.stateSuccess);
    }
    if (['jpg', 'jpeg', 'png'].contains(ext)) {
      return (Icons.image_rounded, AppColors.brandCyan);
    }
    return (Icons.insert_drive_file_rounded, AppColors.greyColor);
  }

  /// Formatea el tamaño en bytes a KB/MB legible.
  static String formatSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '0 KB';
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }
}

/// Modelo ligero para mostrar un archivo adjunto en la UI.
class AttachmentDisplay {
  final int id;
  final String originalName;
  final String extension;
  final String? description;
  final int? size;
  final String? createdAt;

  const AttachmentDisplay({
    required this.id,
    required this.originalName,
    required this.extension,
    this.description,
    this.size,
    this.createdAt,
  });

  factory AttachmentDisplay.fromMap(Map<String, dynamic> map) {
    return AttachmentDisplay(
      id: (map['id'] is int)
          ? map['id'] as int
          : int.tryParse(map['id']?.toString() ?? '') ?? 0,
      originalName: map['original_name']?.toString() ?? 'archivo',
      extension: map['extension']?.toString() ?? '',
      description: map['description']?.toString(),
      size: map['size'] is num ? (map['size'] as num).toInt() : null,
      createdAt: map['created_at']?.toString(),
    );
  }
}
