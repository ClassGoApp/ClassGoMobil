import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/l10n/app_localizations.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/student/reservations/materials/attach_file_sheet.dart';
import 'package:flutter_projects/view/student/reservations/materials/attachment_tile.dart';
import 'package:flutter_projects/view/student/reservations/materials/material_utils.dart';
import 'package:flutter_projects/base_components/custom_snack_bar.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Bottom Sheet 1: detalle de una tutoría con sus archivos adjuntos.
///
/// Reutilizable por rol: [canUpload]/[canEdit] controlan los botones de
/// adjuntar/editar/eliminar (estudiante). Si son false (tutor) solo se
/// muestra la lista y la descarga.
class TutoringDetailsSheet extends StatefulWidget {
  final int bookingId;
  final String title;
  final String subtitle;
  final bool canUpload;
  final bool canEdit;
  final DateTime? date;
  final String startTime;
  final String endTime;
  final String? status;
  final String meetingLink;

  const TutoringDetailsSheet({
    super.key,
    required this.bookingId,
    required this.title,
    required this.subtitle,
    this.canUpload = true,
    this.canEdit = true,
    this.date,
    this.startTime = '',
    this.endTime = '',
    this.status,
    this.meetingLink = '',
  });

  @override
  State<TutoringDetailsSheet> createState() => _TutoringDetailsSheetState();
}

class _TutoringDetailsSheetState extends State<TutoringDetailsSheet> {
  List<AttachmentDisplay>? _attachments;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token == null) return;

    final result = await getBookingAttachments(token, widget.bookingId);
    final data = result['data'] is List ? result['data'] as List : <dynamic>[];
    final parsed = data
        .whereType<Map<String, dynamic>>()
        .map(AttachmentDisplay.fromMap)
        .toList();

    if (!mounted) return;
    setState(() {
      _attachments = parsed;
      _loading = false;
    });
  }

  Future<void> _openAttachSheet({AttachmentDisplay? existing}) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token == null) return;

    final uploaded = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AttachFileSheet(
        token: token,
        bookingId: widget.bookingId,
        existing: existing,
      ),
    );

    if (uploaded == true && mounted) {
      CustomToast.show(context, AppLocalizations.of(context)!.materialSaved, isSuccess: true);
      _load();
    }
  }

Future<void> _download(AttachmentDisplay att) async {
    final l10n = AppLocalizations.of(context)!;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token == null) return;

    final prefs = await SharedPreferences.getInstance();
    final downloadedMap =
        prefs.getStringList('downloaded_materials') ?? [];
    final key = '${att.id}';

    // Buscar si ya existe el archivo descargado
    String? existingPath;
    for (final entry in downloadedMap) {
      final parts = entry.split(':');
      if (parts[0] == key && parts.length >= 3) {
        final path = parts[2];
        if (await File(path).exists()) {
          existingPath = path;
          break;
        }
      }
    }

    // Si ya existe, abrir directamente
    if (existingPath != null) {
      CustomToast.show(context, l10n.alreadyDownloaded, isSuccess: true, isWarning: true);
      
      final result = await OpenFilex.open(existingPath);
      if (result.type != ResultType.done && mounted) {
        CustomToast.show(context, l10n.noAppToOpenFile, isSuccess: false);
      }
      return;
    }

    // Descargar el archivo
    CustomToast.show(context, l10n.downloadingFile, isSuccess: true, isWarning: true);

    final downloadResult = await downloadAttachment(token, att.id, att.originalName);
    if (!mounted) return;

    if (downloadResult['success'] == true) {
      try {
        final bytes = downloadResult['bytes'] as Uint8List;
        final fileName = downloadResult['fileName'] as String;

        // Guardar en el directorio de la app (gestión automática de caché)
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(bytes);

        // Registrar la descarga con la ruta del archivo
        final newMap = [...downloadedMap, '$key:$fileName:$filePath'];
        await prefs.setStringList('downloaded_materials', newMap);

        if (!mounted) return;
        CustomToast.show(context, l10n.downloadedFile, isSuccess: true);

        // Abrir automáticamente con el selector del sistema
        final result = await OpenFilex.open(filePath);
        if (result.type != ResultType.done && mounted) {
          CustomToast.show(context, l10n.noAppToOpenFile, isSuccess: false);
        }
      } catch (e) {
        if (!mounted) return;
        CustomToast.show(context, 'Error: $e', isSuccess: false);
      }
    } else {
      CustomToast.show(context, downloadResult['message']?.toString() ?? 'Error', isSuccess: false);
    }
}

  Future<void> _openAttachment(AttachmentDisplay att) async {
    final l10n = AppLocalizations.of(context)!;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token == null) return;

    final prefs = await SharedPreferences.getInstance();
    final downloadedMap =
        prefs.getStringList('downloaded_materials') ?? [];
    final key = '${att.id}';

    String? existingPath;
    for (final entry in downloadedMap) {
      final parts = entry.split(':');
      if (parts[0] == key && parts.length >= 3) {
        final path = parts[2];
        if (await File(path).exists()) {
          existingPath = path;
          break;
        }
      }
    }

    if (existingPath != null) {
      final result = await OpenFilex.open(existingPath);
      if (result.type != ResultType.done && mounted) {
        CustomToast.show(context, l10n.noAppToOpenFile, isSuccess: false);
      }
      return;
    }

    CustomToast.show(context, l10n.downloadingFile, isSuccess: true, isWarning: true);

    final downloadResult = await downloadAttachment(token, att.id, att.originalName);
    if (!mounted) return;

    if (downloadResult['success'] == true) {
      try {
        final bytes = downloadResult['bytes'] as Uint8List;
        final fileName = downloadResult['fileName'] as String;

        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(bytes);

        final newMap = [...downloadedMap, '$key:$fileName:$filePath'];
        await prefs.setStringList('downloaded_materials', newMap);

        if (!mounted) return;
        CustomToast.show(context, l10n.downloadedFile, isSuccess: true);

        final result = await OpenFilex.open(filePath);
        if (result.type != ResultType.done && mounted) {
          CustomToast.show(context, l10n.noAppToOpenFile, isSuccess: false);
        }
      } catch (e) {
        if (!mounted) return;
        CustomToast.show(context, 'Error: $e', isSuccess: false);
      }
    } else {
      CustomToast.show(context, downloadResult['message']?.toString() ?? 'Error', isSuccess: false);
    }
  }

  Future<void> _delete(AttachmentDisplay att) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          decoration: BoxDecoration(
            color: AppColors.studentCardWhite,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.redColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_rounded,
                    color: AppColors.redColor, size: 34),
              ),
              const SizedBox(height: 18),
              Text(
                l10n.deleteMaterialConfirm,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLightPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.deleteMaterialDescription,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.textLightSecondary,
                ),
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.redColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(l10n.deleteMaterial),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token == null) return;

    setState(() => _busy = true);
    final result = await deleteAttachment(token, att.id);
    if (!mounted) return;

    setState(() => _busy = false);
    if (result['success'] == true) {
      CustomToast.show(context, l10n.materialDeleted, isSuccess: true);
      _load();
    }
  }

  String _formatDateLine(AppLocalizations l10n) {
    final parts = <String>[];
    final date = widget.date;
    if (date != null) {
      parts.add(
        DateFormat("EEEE, d 'de' MMMM", l10n.localeName == 'es' ? 'es' : 'en')
            .format(date),
      );
    }
    if (widget.startTime.isNotEmpty) {
      parts.add(
        widget.endTime.isNotEmpty
            ? '${widget.startTime} ${l10n.timeConnector} ${widget.endTime}'
            : widget.startTime,
      );
    }
    return parts.join(' • ');
  }

  /// La sesión ya terminó: no se permite subir/editar/borrar archivos.
  bool get _isPastSession {
    final date = widget.date;
    if (date == null) return false;
    try {
      final parts = widget.startTime.split(':');
      final hour = parts.isNotEmpty ? int.parse(parts[0]) : 0;
      final minute = parts.length > 1 ? int.parse(parts[1]) : 0;
      final sessionEnd = DateTime(date.year, date.month, date.day, hour, minute)
          .add(const Duration(minutes: 20));
      return sessionEnd.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  Future<void> _openMeetLink() async {
    var url = widget.meetingLink.trim();
    if (url.isEmpty) return;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      CustomToast.show(context, AppLocalizations.of(context)!.meetLinkNotAvailable, isSuccess: false);
    }
  }

  void _copyMeetLink(AppLocalizations l10n) {
    Clipboard.setData(ClipboardData(text: widget.meetingLink.trim()));
    CustomToast.show(context, l10n.linkCopied, isSuccess: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateLine = _formatDateLine(l10n);

    return FractionallySizedBox(
      heightFactor: 0.72,
      child: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          color: Colors.white,
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Stack(
            children: [
              Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.topBottomSheetDismissColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 20, right: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.tutoringDetails,
                                style: const TextStyle(
                                  fontFamily: AppFonts.body,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: AppColors.cardAccentPurple,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                widget.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  height: 1.2,
                                  color: AppColors.textLightPrimary,
                                ),
                              ),
                              if (dateLine.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  dateLine,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textLightSecondary,
                                  ),
                                ),
                              ],
                              if (widget.subtitle.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  widget.subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textLightSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                          color: AppColors.textLightSecondary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_busy)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  Expanded(child: _buildBody(l10n)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final atts = _attachments ?? [];
    final past = _isPastSession;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        if (widget.meetingLink.trim().isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.dashedDivider, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppColors.neonGreen.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.videocam_rounded,
                      color: AppColors.neonGreen, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _openMeetLink,
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.meetingLinkLabel,
                          style: const TextStyle(
                            fontFamily: AppFonts.heading,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: AppColors.textLightSecondary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.meetingLink.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 13,
                            color: AppColors.textLightPrimary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded,
                      color: AppColors.chevronGrey, size: 20),
                  onPressed: () => _copyMeetLink(l10n),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (widget.canUpload && !past) ...[
          Material(
            color: AppColors.cardAccentPurple,
            borderRadius: BorderRadius.circular(16),
            elevation: 3,
            shadowColor: AppColors.cardAccentPurple.withValues(alpha: 0.3),
            child: InkWell(
              onTap: _busy ? null : () => _openAttachSheet(),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_rounded, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      l10n.attachMaterial,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          l10n.attachmentsForSession,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textLightPrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (atts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                const Icon(Icons.folder_off_rounded,
                    size: 48, color: AppColors.greyColor),
                const SizedBox(height: 12),
                Text(
                  l10n.noAttachedMaterial,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.greyColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
        else
          ...atts.map((att) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AttachmentTile(
                  attachment: att,
                  canEdit: widget.canEdit && !past,
                  onTap: () => _openAttachment(att),
                  onDownload: () => _download(att),
                  onEdit: widget.canEdit && !past
                      ? () => _openAttachSheet(existing: att)
                      : null,
                  onDelete: widget.canEdit && !past ? () => _delete(att) : null,
                ),
              )),
      ],
    );
  }
}
