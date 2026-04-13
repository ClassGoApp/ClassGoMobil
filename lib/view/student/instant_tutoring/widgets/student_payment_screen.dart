import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/view/student/instant_tutoring/widgets/waiting_room_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Importa tus modelos
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
  File? _receiptImage;
  bool _isSubmitting = false;
  final ImagePicker _picker = ImagePicker();

  late PageController _pageController;
  int _currentPage = 0;

  bool _isWaitingForTutor = false;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }

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
    if (_receiptImage == null) return;

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final miToken = prefs.getString('token') ?? '';
      
      if (miToken.isEmpty) {
        throw Exception("No tienes una sesión activa. Vuelve a iniciar sesión.");
      }

      final uploadResponse = await subirComprobante(
        widget.bookingId, 
        _receiptImage!.path, 
        miToken
      );

      if (uploadResponse['ok'] == true || uploadResponse['success'] == true) {
        
        setState(() {
          _isSubmitting = false; 
          _isWaitingForTutor = true; 
        });

        // Radar para espiar al tutor
        _iniciarPolling(miToken);

      } else {
        throw Exception(uploadResponse['message'] ?? 'Error al subir el comprobante');
      }

    } catch (e) {
      print("Error al procesar el pago: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      if (mounted) setState(() => _isSubmitting = false);
    } 
  }

  // EL RADAR QUE PREGUNTA POR EL ESTADO
  void _iniciarPolling(String token) {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        // Función suelta de tu api_service.dart
        final estado = await consultarEstadoReserva(widget.bookingId, token);

        if (estado['ok'] == true || estado['success'] == true) {
          String uiState = estado['ui_state'];

          if (uiState == 'accepted') {
            timer.cancel(); 
            
            String linkGenerado = estado['booking']?['meeting_link'] ?? 'https://meet.google.com/';

            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => BookingSuccessScreen(
                    tutor: widget.tutor,
                    subjectName: widget.subjectName,
                    meetingLink: linkGenerado,
                  ),
                ),
              );
            }
          } else if (uiState == 'rejected' || uiState == 'expired') {
            timer.cancel();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("La tutoría fue cancelada o expiró el tiempo."),
                  backgroundColor: Colors.redAccent,
                ),
              );
              Navigator.pop(context); 
            }
          }
        }
      } catch (e) {
        print("Error en el radar (polling): $e");
      }
    });
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
    if (_isWaitingForTutor) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.brandBlue, strokeWidth: 4),
              SizedBox(height: 24),
              Text(
                "Comprobante enviado ✅", 
                style: TextStyle(fontFamily: _kTitleFont, fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryColor)
              ),
              SizedBox(height: 12),
              Text(
                "Esperando a que el tutor inicie el aula...", 
                style: TextStyle(fontFamily: _kBodyFont, fontSize: 16, color: AppColors.brandOrange)
              ),
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
        title: const Text('Finalizar Proceso', 
          style: TextStyle(fontFamily: _kTitleFont, color: AppColors.brandBlue, fontWeight: FontWeight.bold)),
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
          const Text("Escanea el QR de pago", 
            style: TextStyle(fontFamily: _kTitleFont, fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.blackColor)),
          const SizedBox(height: 8),
          const Text("Realiza la transferencia por el monto exacto", 
            style: TextStyle(fontFamily: _kBodyFont, fontSize: 14, color: AppColors.greyColor)),
          const Spacer(),
          GestureDetector(
            onTap: _showFullscreenQr,
            child: Hero(
              tag: 'companyQrHero',
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.dividerColor),
                  borderRadius: BorderRadius.circular(20)
                ),
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
          const Text("Sube tu comprobante", 
            style: TextStyle(fontFamily: _kTitleFont, fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.blackColor)),
          const SizedBox(height: 20),
          Expanded(
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.fadeColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.brandCyan.withOpacity(0.3), width: 2, style: BorderStyle.solid),
                ),
                child: _receiptImage == null 
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
                      child: Image.file(_receiptImage!, fit: BoxFit.cover),
                    ),
              ),
            ),
          ),
          if (_receiptImage != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TextButton(
                onPressed: () => setState(() => _receiptImage = null),
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