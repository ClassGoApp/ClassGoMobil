import 'package:flutter/material.dart';
import 'package:flutter_projects/l10n/app_localizations.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/student/reservations/materials/material_utils.dart';

/// Tarjeta de un archivo adjunto dentro de la sesión de tutoría.
///
/// Muestra icono por tipo, nombre, estado y descripción de contexto.
/// Si [canEdit] es true se muestran los botones Editar/Eliminar.
class AttachmentTile extends StatelessWidget {
  final AttachmentDisplay attachment;
  final bool canEdit;
  final VoidCallback onDownload;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const AttachmentTile({
    super.key,
    required this.attachment,
    required this.canEdit,
    required this.onDownload,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (icon, color) = MaterialFileUtils.iconFor(attachment);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.studentCardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.dividerLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attachment.originalName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textLightPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                AppColors.stateSuccess.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            l10n.savedStatus,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.stateSuccess,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            MaterialFileUtils.formatSize(attachment.size),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textLightSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDownload,
                tooltip: l10n.downloadOrShare,
                icon: const Icon(Icons.download_rounded,
                    color: AppColors.brandCyan),
              ),
            ],
          ),
          if (attachment.description != null &&
              attachment.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.lightBlue.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                attachment.description!,
                style:
                    const TextStyle(fontSize: 13, color: AppColors.greyColor),
              ),
            ),
          ],
          if (canEdit) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _ActionButton(
                  onPressed: onEdit,
                  icon: Icons.edit_rounded,
                  label: l10n.editMaterial,
                  background: AppColors.lightBlue.withValues(alpha: 0.45),
                  foreground: AppColors.brandCyan,
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  onPressed: onDelete,
                  icon: Icons.delete_rounded,
                  label: l10n.deleteMaterial,
                  background: AppColors.redColor.withValues(alpha: 0.12),
                  foreground: AppColors.redColor,
                ),
              ],
            ),
          ],
        ],
      ),
      ),
    );
  }
}

/// Botón tonal redondeado para las acciones de la tarjeta de adjunto.
class _ActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  const _ActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
