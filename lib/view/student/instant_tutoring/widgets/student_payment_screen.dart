import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/student/instant_tutoring/logic/payment_controller.dart';

// Modelos y Controladores
import 'tutor_model.dart';
import 'booking_success_screen.dart';

const String _kTitleFont = 'outfit';
const String _kBodyFont = 'manrope';

class StudentPaymentScreen extends StatefulWidget {
  final TutorResponse tutor;
  final String subjectName;
  final String companyQrUrl;
  final int bookingId;

  const StudentPaymentScreen({
    Key? key,
    required this.tutor,
    required this.subjectName,
    required this.bookingId,
    this.companyQrUrl = 'assets/images/cobro.jpeg',
  }) : super(key: key);

  @override
  State<StudentPaymentScreen> createState() => _StudentPaymentScreenState();
}

class _StudentPaymentScreenState extends State<StudentPaymentScreen> {
  late PaymentController _logicController;
  
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _logicController = PaymentController();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _logicController.dispose(); // Cancela los timers automáticamente
    super.dispose();
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
                      child: _buildSafeImage(widget.companyQrUrl),
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _logicController,
      builder: (context, _) {
        if (_logicController.isWaitingForTutor) {
          return const Scaffold(
            backgroundColor: AppColors.backgroundLight,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.brandBlue, strokeWidth: 4),
                  SizedBox(height: 24),
                  Text("Comprobante enviado ✅", style: TextStyle(fontFamily: _kTitleFont, fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryColor)),
                  SizedBox(height: 12),
                  Text("Esperando a que el tutor inicie el aula...", style: TextStyle(fontFamily: _kBodyFont, fontSize: 16, color: AppColors.brandOrange)),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Finalizar Proceso', style: TextStyle(fontFamily: _kTitleFont, color: AppColors.brandBlue, fontWeight: FontWeight.bold)),
            centerTitle: true,
            iconTheme: const IconThemeData(color: AppColors.brandBlue),
          ),
          body: Column(
            children: [
              _buildHeaderSteps(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  children: [
                    _buildQRPage(),      // Página 1
                    _buildReceiptPage(), // Página 2
                  ],
                ),
              ),
              _buildBottomButton(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQRPage() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
      ),
      child: Column(
        children: [
          const Text("Escanea el QR de pago", style: TextStyle(fontFamily: _kTitleFont, fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.blackColor)),
          const SizedBox(height: 8),
          const Text("Realiza la transferencia por el monto exacto", style: TextStyle(fontFamily: _kBodyFont, fontSize: 14, color: AppColors.greyColor)),
          const Spacer(),
          GestureDetector(
            onTap: _showFullscreenQr,
            child: Hero(
              tag: 'companyQrHero',
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(border: Border.all(color: AppColors.dividerColor), borderRadius: BorderRadius.circular(20)),
                child: SizedBox(width: 200, height: 200, child: _buildSafeImage(widget.companyQrUrl)),
              ),
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut),
            icon: const Icon(Icons.arrow_forward, color: AppColors.brandCyan),
            label: const Text("Ya realicé el pago", style: TextStyle(color: AppColors.brandCyan, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildReceiptPage() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
      ),
      child: Column(
        children: [
          const Text("Sube tu comprobante", style: TextStyle(fontFamily: _kTitleFont, fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.blackColor)),
          const SizedBox(height: 20),
          Expanded(
            child: GestureDetector(
              onTap: () => _logicController.pickImage((error) => _showToast(error, isError: true)),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.fadeColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.brandCyan.withOpacity(0.3), width: 2, style: BorderStyle.solid),
                ),
                child: _logicController.receiptImage == null 
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add_a_photo_rounded, size: 40, color: AppColors.brandCyan),
                        SizedBox(height: 12),
                        Text("Toca para seleccionar captura", style: TextStyle(color: AppColors.brandBlue, fontWeight: FontWeight.bold)),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.file(_logicController.receiptImage!, fit: BoxFit.cover),
                    ),
              ),
            ),
          ),
          if (_logicController.receiptImage != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TextButton(
                onPressed: _logicController.removeImage,
                child: const Text("Cambiar imagen", style: TextStyle(color: Colors.redAccent)),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildHeaderSteps() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _stepIcon(0, Icons.qr_code_2_rounded),
          Container(width: 40, height: 2, color: AppColors.dividerColor),
          _stepIcon(1, Icons.file_upload_outlined),
        ],
      ),
    );
  }

  Widget _stepIcon(int index, IconData icon) {
    bool isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isActive ? AppColors.brandCyan : AppColors.whiteColor,
        shape: BoxShape.circle,
        border: Border.all(color: isActive ? AppColors.brandCyan : AppColors.dividerColor),
      ),
      child: Icon(icon, color: isActive ? Colors.white : AppColors.greyColor, size: 20),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: const BoxDecoration(color: AppColors.backgroundLight),
      child: SafeArea(
        top: false,
        child: ElevatedButton(
          // Si está enviando o no hay imagen, bloqueamos el botón
          onPressed: _logicController.isSubmitting || _logicController.receiptImage == null 
            ? null 
            : () {
                _logicController.submitPayment(
                  bookingId: widget.bookingId,
                  // ÉXITO: El tutor aprobó y nos dio el Link
                  onTutorAccepted: (meetLink) {
                    if (mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookingSuccessScreen(
                            tutor: widget.tutor,
                            subjectName: widget.subjectName,
                            meetingLink: meetLink,
                          ),
                        ),
                      );
                    }
                  },
                  // RECHAZO: Expiró el tiempo o el tutor lo canceló
                  onTutorRejected: () {
                    if (mounted) {
                      _showToast("La tutoría fue cancelada o expiró el tiempo.", isError: true);
                      Navigator.pop(context);
                    }
                  },
                  // ERROR DE RED
                  onError: (error) {
                    _showToast(error, isError: true);
                  }
                );
              },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandBlue,
            disabledBackgroundColor: AppColors.brandBlue.withOpacity(0.5),
            padding: const EdgeInsets.symmetric(vertical: 18),
            elevation: 0,
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: _logicController.isSubmitting
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: AppColors.whiteColor, strokeWidth: 3))
              : const Text("Confirmar Pago", style: TextStyle(fontFamily: _kBodyFont, color: AppColors.whiteColor, fontSize: 17, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}