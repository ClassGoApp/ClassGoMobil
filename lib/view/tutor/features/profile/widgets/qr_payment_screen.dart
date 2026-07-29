import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/config/app_config.dart';
import 'package:flutter_projects/base_components/custom_snack_bar.dart';
import 'package:flutter_projects/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/provider/auth_provider.dart';

const String _kTitleFont = 'outfit';
const String _kBodyFont = 'manrope';

class QrPaymentScreen extends StatefulWidget {
  final String? initialQrUrl;

  const QrPaymentScreen({Key? key, this.initialQrUrl}) : super(key: key);

  @override
  State<QrPaymentScreen> createState() => _QrPaymentScreenState();
}

class _QrPaymentScreenState extends State<QrPaymentScreen> {
  File? _selectedImage;
  String? _currentQrUrl;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _currentQrUrl = widget.initialQrUrl;
    if (_currentQrUrl == null) {
      _fetchQrFromServer();
    }
  }

  String _normalizeUrl(String rawUrl) {
    if (rawUrl.isEmpty || rawUrl.startsWith('http')) return rawUrl;

    String baseStorage = AppConfig.mediaBaseUrl;
    if (!baseStorage.endsWith('/')) baseStorage += '/';
    if (rawUrl.startsWith('/')) rawUrl = rawUrl.substring(1);

    return '$baseStorage$rawUrl';
  }

  Future<void> _fetchQrFromServer() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final userId = authProvider.userId;

    if (token == null || userId == null) return;

    setState(() => _isLoading = true);

    try {
      final response = await getTutorQrMethod(token, userId);

      if (response['data'] != null && (response['data'] as List).isNotEmpty) {
        final rawUrl = response['data'][0]['img_qr_url'] ??
            response['data'][0]['img_qr'] ??
            '';

        if (rawUrl.isNotEmpty) {
          setState(() {
            _currentQrUrl = _normalizeUrl(rawUrl);
          });
        }
      }
    } catch (e) {
      debugPrint("Error al descargar QR: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image != null) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final token = authProvider.token;
        final userId = authProvider.userId;

        if (token == null || userId == null) {
          CustomToast.show(context, AppLocalizations.of(context)!.noActiveSession, isSuccess: false);
          return;
        }

        setState(() {
          _selectedImage = File(image.path);
          _isLoading = true;
        });

        final response =
            await uploadTutorQrMethod(token, userId, _selectedImage!);

        if (response['status'] == 200 ||
            response['status'] == 201 ||
            response['success'] == true) {
          CustomToast.show(context, AppLocalizations.of(context)!.qrUploadedSuccessfully, isSuccess: true);

          if (response['data'] != null) {
            final rawUrl = response['data']['img_qr_url'] ??
                response['data']['img_qr'] ??
                '';
            if (rawUrl.isNotEmpty) {
              _currentQrUrl = _normalizeUrl(rawUrl);
            }
          }
        } else {
          CustomToast.show(context, response['message'] ?? 'Error al subir la imagen',
              isSuccess: false);
          setState(() => _selectedImage = null);
        }
      }
    } catch (e) {
      CustomToast.show(context, AppLocalizations.of(context)!.errorSelectingImage, isSuccess: false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeQr() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final userId = authProvider.userId;

    if (token == null || userId == null) return;

    setState(() => _isLoading = true);

    try {
      await deleteTutorQrMethod(token, userId);

      setState(() {
        _selectedImage = null;
        _currentQrUrl = null;
      });
      CustomToast.show(context, AppLocalizations.of(context)!.qrDeletedSuccessfully, isSuccess: true);
    } catch (e) {
      CustomToast.show(context, AppLocalizations.of(context)!.deleteQRCode, isSuccess: false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showFullscreenQr(BuildContext context) {
    late ImageProvider imageProvider;
    if (_selectedImage != null) {
      imageProvider = FileImage(_selectedImage!);
    } else {
      imageProvider = CachedNetworkImageProvider(_currentQrUrl!);
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: AppLocalizations.of(context)!.closeQRViewer,
      barrierColor: Colors.black.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Hero(
                  tag: 'qrImageHero',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      color: Colors.white,
                      width: double.infinity,
                      child: Image(
                        image: imageProvider,
                        fit: BoxFit.fitWidth,
                        gaplessPlayback: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasQr = _selectedImage != null ||
        (_currentQrUrl != null && _currentQrUrl!.isNotEmpty);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.brandBlue),
        title: Text(
          AppLocalizations.of(context)!.configureQR,
          style: const TextStyle(
            fontFamily: _kTitleFont,
            color: AppColors.brandBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              AppLocalizations.of(context)!.speedUpPayments,
              style: const TextStyle(
                fontFamily: _kTitleFont,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.brandBlue,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.qrDescription,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: _kBodyFont,
                fontSize: 15,
                height: 1.5,
                color: AppColors.textLightPrimary,
              ),
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: _currentQrUrl != null || _selectedImage != null
                  ? () => _showFullscreenQr(context)
                  : null,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: AppColors.brandBlue.withOpacity(0.2), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: _buildQrContent(hasQr),
                ),
              ),
            ),
            const SizedBox(height: 40),
            if (hasQr) ...[
              _buildActionButton(
                title: AppLocalizations.of(context)!.changeQRCode,
                icon: Icons.sync_rounded,
                color: AppColors.primaryGreen,
                onTap: _isLoading ? () {} : _pickImage,
              ),
              const SizedBox(height: 16),
              _buildActionButton(
                title: AppLocalizations.of(context)!.deleteQRCode,
                icon: Icons.delete_outline_rounded,
                color: Colors.redAccent,
                isOutlined: true,
                onTap: _isLoading
                    ? () {}
                    : () => _showDeleteConfirmationDialog(context),
              ),
            ] else ...[
              _buildActionButton(
                title: AppLocalizations.of(context)!.uploadQRCode,
                icon: Icons.upload_rounded,
                color: AppColors.brandBlue,
                onTap: _isLoading ? () {} : _pickImage,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQrContent(bool hasQr) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.brandBlue),
      );
    }

    if (!hasQr) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_2_rounded,
              size: 80, color: AppColors.brandBlue.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.noQRCode,
            style: TextStyle(
              fontFamily: _kBodyFont,
              color: AppColors.brandBlue.withOpacity(0.5),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    if (_selectedImage != null) {
      return Hero(
        tag: 'qrImageHero',
        child: Image.file(_selectedImage!, fit: BoxFit.cover),
      );
    }

    return Hero(
      tag: 'qrImageHero',
      child: CachedNetworkImage(
          imageUrl: _currentQrUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) =>
              const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.broken_image, color: Colors.grey, size: 40),
                const SizedBox(height: 8),
                Text(AppLocalizations.of(context)!.errorLoadingQR,
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            );
          }),
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isOutlined = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: isOutlined
          ? OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, color: color),
              label: Text(
                title,
                style: TextStyle(
                    fontFamily: _kTitleFont,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color, width: 2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            )
          : ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, color: Colors.white),
              label: Text(
                title,
                style: const TextStyle(
                    fontFamily: _kTitleFont,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx)!.deleteQRConfirmTitle,
            style: const TextStyle(
                fontFamily: _kTitleFont, fontWeight: FontWeight.bold)),
        content: Text(
            AppLocalizations.of(ctx)!.deleteQRConfirmMessage,
            style: const TextStyle(fontFamily: _kBodyFont)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx)!.cancelButton, style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _removeQr();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child:
                Text(AppLocalizations.of(ctx)!.deleteButton, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
