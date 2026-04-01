import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_projects/styles/app_styles.dart';

// Importa tus modelos
import 'tutor_model.dart';
import 'booking_success_screen.dart';

const String _kTitleFont = 'outfit';
const String _kBodyFont = 'manrope';

class StudentPaymentScreen extends StatefulWidget {
  final TutorResponse tutor;
  final String subjectName;
  final String companyQrUrl; // Puede ser 'http...' o 'assets/...'

  const StudentPaymentScreen({
    Key? key,
    required this.tutor,
    required this.subjectName,
    this.companyQrUrl = 'assets/images/descarga.png',
  }) : super(key: key);

  @override
  State<StudentPaymentScreen> createState() => _StudentPaymentScreenState();
}

class _StudentPaymentScreenState extends State<StudentPaymentScreen> {
  File? _receiptImage;
  bool _isSubmitting = false;
  final ImagePicker _picker = ImagePicker();

  // ==========================================
  // ⚙️ LÓGICA: SELECCIÓN Y SUBIDA
  // ==========================================
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (image != null) {
        setState(() => _receiptImage = File(image.path));
      }
    } catch (e) {
      _showToast('Error al abrir la galería', isError: true);
    }
  }

  Future<void> _submitPayment() async {
    if (_receiptImage == null) {
      _showToast('Por favor, adjunta tu comprobante primero', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    // TODO: 🌐 LLAMADA A TU API AQUÍ
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => BookingSuccessScreen(
          tutor: widget.tutor,
          subjectName: widget.subjectName,
        ),
      ),
    );
  }

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontFamily: _kBodyFont, fontWeight: FontWeight.bold)),
        backgroundColor: isError ? Colors.redAccent : AppColors.brandCyan,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // 🚀 FUNCIÓN INTELIGENTE PARA EL QR (Evita crasheos locales vs web)
  Widget _buildSafeImage(String path) {
    if (path.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: path,
        fit: BoxFit.contain,
        placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: AppColors.brandBlue)),
        errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey, size: 40),
      );
    } else {
      return Image.asset(
        path,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey, size: 40),
      );
    }
  }

  // ==========================================
  // 🔍 LÓGICA: EXPANDIR QR
  // ==========================================
  void _showFullscreenQr() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar QR',
      barrierColor: Colors.black.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Hero(
                  tag: 'companyQrHero',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      color: Colors.white,
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      child: _buildSafeImage(widget.companyQrUrl), // Usa la función segura
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
          child: ScaleTransition(scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack), child: child),
        );
      },
    );
  }

  // ==========================================
  // 🎨 CONSTRUCCIÓN DE LA VISTA
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.brandBlue),
        title: const Text('Completar Reserva', style: TextStyle(fontFamily: _kTitleFont, color: AppColors.brandBlue, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildPaymentCard(), // El diseño de Ticket
                    const SizedBox(height: 32),
                    _buildUploadSection(),
                  ],
                ),
              ),
            ),
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  // 🧩 Módulo 1: Diseño "Ticket" (Perfil + Monto + QR)
  Widget _buildPaymentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: AppColors.blackColor.withOpacity(0.04), blurRadius: 25, offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        children: [
          // 1. Perfil del Tutor (Con CachedNetworkImage)
          Row(
            children: [
              ClipOval(
                child: CachedNetworkImage(
                  imageUrl: widget.tutor.avatarUrl,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: AppColors.fadeColor, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                  errorWidget: (context, url, error) => Container(color: AppColors.fadeColor, child: const Icon(Icons.person, color: Colors.grey)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.tutor.name,
                      style: const TextStyle(fontFamily: _kTitleFont, fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.blackColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      "Tutor asignado",
                      style: TextStyle(fontFamily: _kBodyFont, fontSize: 13, color: AppColors.greyColor),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Divider(height: 1, color: AppColors.dividerColor),
          ),

          // 2. Monto a Pagar
          const Text("Total a transferir", style: TextStyle(fontFamily: _kBodyFont, color: AppColors.greyColor, fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            widget.tutor.pricePerHour, 
            style: const TextStyle(fontFamily: _kTitleFont, fontSize: 44, fontWeight: FontWeight.w800, color: AppColors.brandBlue),
          ),

          const SizedBox(height: 28),

          // 3. Código QR Integrado (Inteligente)
          GestureDetector(
            onTap: _showFullscreenQr,
            child: Hero(
              tag: 'companyQrHero',
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.whiteColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.dividerColor, width: 1.5),
                ),
                padding: const EdgeInsets.all(16),
                child: _buildSafeImage(widget.companyQrUrl), // Usa la función segura
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.touch_app_rounded, color: AppColors.brandCyan, size: 18),
              SizedBox(width: 8),
              Text(
                "Toca el código para ampliarlo", 
                style: TextStyle(fontFamily: _kBodyFont, color: AppColors.brandCyan, fontSize: 13, fontWeight: FontWeight.bold)
              ),
            ],
          )
        ],
      ),
    );
  }

  // 🧩 Módulo 2: Subida del Comprobante
  Widget _buildUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8, bottom: 12),
          child: Text("Comprobante de pago", style: TextStyle(fontFamily: _kTitleFont, fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.blackColor)),
        ),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            height: _receiptImage == null ? 140 : 250,
            decoration: BoxDecoration(
              color: AppColors.fadeColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _receiptImage == null ? AppColors.dividerColor : Colors.transparent, 
                width: 2,
              ),
            ),
            child: _receiptImage == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppColors.whiteColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.blackColor.withOpacity(0.04), blurRadius: 10)]),
                        child: const Icon(Icons.cloud_upload_rounded, color: AppColors.brandCyan, size: 30),
                      ),
                      const SizedBox(height: 16),
                      const Text("Toca para subir tu captura", style: TextStyle(fontFamily: _kBodyFont, color: AppColors.brandBlue, fontSize: 15, fontWeight: FontWeight.w700)),
                    ],
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.file(_receiptImage!, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: GestureDetector(
                          onTap: () => setState(() => _receiptImage = null),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                            child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      )
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  // 🧩 Módulo 3: Botón de Confirmación
  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: const BoxDecoration(
        color: AppColors.backgroundLight,
      ),
      child: SafeArea(
        top: false,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submitPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandBlue,
            disabledBackgroundColor: AppColors.brandBlue.withOpacity(0.5),
            padding: const EdgeInsets.symmetric(vertical: 18),
            elevation: 0,
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: _isSubmitting
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: AppColors.whiteColor, strokeWidth: 3))
              : const Text("Confirmar Pago", style: TextStyle(fontFamily: _kBodyFont, color: AppColors.whiteColor, fontSize: 17, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}