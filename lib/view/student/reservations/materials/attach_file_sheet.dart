import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/l10n/app_localizations.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/student/reservations/materials/material_utils.dart';

class AttachFileSheet extends StatefulWidget {
  final String token;
  final int bookingId;
  final AttachmentDisplay? existing;

  const AttachFileSheet({
    super.key,
    required this.token,
    required this.bookingId,
    this.existing,
  });

  @override
  State<AttachFileSheet> createState() => _AttachFileSheetState();
}

class _AttachFileSheetState extends State<AttachFileSheet> {
  static const allowedExtensions = [
    'pdf',
    'doc',
    'docx',
    'ods',
    'odt',
    'xls',
    'xlsx',
    'jpg',
    'jpeg',
    'png',
  ];
  static const maxBytes = 5 * 1024 * 1024;
  static const maxDescriptionChars = 500;

  File? _file;
  String? _fileName;
  int? _fileSize;
  final TextEditingController _descriptionController = TextEditingController();
  final GlobalKey<FormFieldState<String>> _descriptionKey =
      GlobalKey<FormFieldState<String>>();
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _descriptionController.text = widget.existing!.description ?? '';
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );
    if (result == null || result.files.isEmpty) return;

    final path = result.files.single.path;
    if (path == null) return;

    final file = File(path);
    final ext = (result.files.single.extension ?? '').toLowerCase();

    if (!allowedExtensions.contains(ext)) {
      setState(() => _error = AppLocalizations.of(context)!.fileNotAllowed);
      return;
    }

    final size = file.lengthSync();
    if (size > maxBytes) {
      setState(() => _error = AppLocalizations.of(context)!.fileTooLarge);
      return;
    }

    setState(() {
      _file = file;
      _fileName = result.files.single.name;
      _fileSize = size;
      _error = null;
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;

    final description = _descriptionController.text.trim();
    if (!_isEdit && _file == null) {
      setState(() => _error = l10n.noMaterialSelected);
      return;
    }
    if (description.length < 2 || description.length > maxDescriptionChars) {
      setState(() => _error = l10n.descriptionRequired);
      _descriptionKey.currentState?.validate();
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final Map<String, dynamic> result;
    if (_isEdit) {
      result = await updateAttachment(
        widget.token,
        widget.existing!.id,
        file: _file,
        description: description,
      );
    } else {
      result = await uploadBookingAttachment(
        widget.token,
        widget.bookingId,
        _file!,
        description,
      );
    }

    if (!mounted) return;

    if (result['success'] == true) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _saving = false;
        _error = result['message']?.toString() ?? l10n.descriptionRequired;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.studentCardWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.topBottomSheetDismissColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isEdit ? Icons.edit_rounded : Icons.attach_file_rounded,
                      color: AppColors.brandCyan,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEdit ? l10n.editMaterial : l10n.attachFile,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textLightPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isEdit
                              ? l10n.editMaterialDescription
                              : l10n.materialOptionalNote,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.3,
                            color: AppColors.textLightSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.textLightSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _saving ? null : _pickFile,
                borderRadius: BorderRadius.circular(18),
                child: Ink(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                  decoration: BoxDecoration(
                    color:
                        AppColors.studentBackgroundLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: CustomPaint(
                    painter: _DashedBorderPainter(
                      color: AppColors.brandCyan.withValues(alpha: 0.7),
                      radius: 18,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _file != null
                              ? Icons.description_rounded
                              : Icons.cloud_upload_rounded,
                          size: 44,
                          color: AppColors.brandCyan,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _fileName ?? l10n.selectFile,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppColors.textLightPrimary,
                          ),
                        ),
                        if (_file != null && _fileSize != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            MaterialFileUtils.formatSize(_fileSize),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textLightSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          l10n.maxSize5Mb,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textLightSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: _descriptionKey,
                controller: _descriptionController,
                maxLines: 3,
                maxLength: maxDescriptionChars,
                enabled: !_saving,
                decoration: InputDecoration(
                  labelText: l10n.materialDescriptionLabel,
                  hintText: l10n.materialDescriptionPlaceholder,
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  final v = (value ?? '').trim();
                  if (v.length < 2 || v.length > maxDescriptionChars) {
                    return l10n.descriptionRequired;
                  }
                  return null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.redColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.redColor.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 18, color: AppColors.redColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: AppColors.redColor,
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(
                          color: AppColors.dividerLight,
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        l10n.cancel,
                        style: const TextStyle(
                          color: AppColors.textLightSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandBlue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              l10n.save,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pinta un borde punteado sin dependencias externas.
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    const dash = 7.0;
    const gap = 5.0;

    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dash;
        canvas.drawPath(
          metric.extractPath(
              distance, next > metric.length ? metric.length : next),
          paint,
        );
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
