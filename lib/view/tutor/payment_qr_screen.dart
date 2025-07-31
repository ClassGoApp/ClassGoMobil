import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/base_components/custom_snack_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';
import '../../provider/auth_provider.dart';
import 'booking_success_screen.dart';

class PaymentQRScreen extends StatefulWidget {
  final String tutorName;
  final String tutorImage;
  final String selectedSubject;
  final String amount;
  final String sessionDuration;
  final int tutorId;
  final int subjectId;

  const PaymentQRScreen({
    Key? key,
    required this.tutorName,
    required this.tutorImage,
    required this.selectedSubject,
    required this.amount,
    required this.sessionDuration,
    required this.tutorId,
    required this.subjectId,
  }) : super(key: key);

  @override
  _PaymentQRScreenState createState() => _PaymentQRScreenState();
}

class _PaymentQRScreenState extends State<PaymentQRScreen>
    with TickerProviderStateMixin {
  File? _receiptImage;
  final ImagePicker _picker = ImagePicker();
  final DraggableScrollableController _scrollController =
      DraggableScrollableController();
  final PageController _pageController = PageController();
  late AnimationController _slideAnimationController;
  late AnimationController _qrAnimationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _qrScaleAnimation;
  int _currentPage = 0;

  // Datos del pago (actualizados)
  final String _qrData = "https://classgo.com/pay/session_12345";
  bool _isPaymentCompleted = false;

  @override
  void initState() {
    super.initState();

    _slideAnimationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _qrAnimationController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(1.0, 0.0), // Empieza desde la derecha
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _qrScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _qrAnimationController,
      curve: Curves.elasticOut,
    ));

    _scrollController.addListener(() {
      if (_scrollController.size <= 0.62) {
        Navigator.of(context).pop();
      }
    });

    // Iniciar animaciones
    _slideAnimationController.forward();
    _qrAnimationController.forward();
  }

  @override
  void dispose() {
    _slideAnimationController.dispose();
    _qrAnimationController.dispose();
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _pickReceiptImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _receiptImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar la imagen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showReceiptSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkBlue.withOpacity(0.95),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '¿Cómo quieres añadir el comprobante?',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ),
              Divider(color: Colors.white.withOpacity(0.2)),
              ListTile(
                leading: Icon(Icons.camera_alt, color: Colors.white),
                title:
                    Text('Tomar foto', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickReceiptImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: Colors.white),
                title: Text('Seleccionar de galería',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickReceiptImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _downloadQR() async {
    try {
      // Solicitar permisos
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Se necesitan permisos para descargar el QR')),
          );
          return;
        }
      }

      // Obtener directorio de descargas
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo acceder al almacenamiento')),
        );
        return;
      }

      // Crear nombre de archivo único
      final fileName =
          'classgo_payment_qr_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '${directory.path}/$fileName';

      // Aquí normalmente generarías y guardarías el QR
      await Future.delayed(Duration(seconds: 1)); // Simulación

      // Notificación moderna que ahora usa el CONTEXTO LOCAL
      showSimpleNotification(
        Text("¡QR guardado en tu galería!",
            style: TextStyle(color: Colors.white)),
        leading: Icon(Icons.download_done, color: Colors.white),
        background: AppColors.lightBlueColor,
        duration: Duration(seconds: 4),
      );
    } catch (e) {
      showSimpleNotification(
        Text("Error al descargar el QR", style: TextStyle(color: Colors.white)),
        leading: Icon(Icons.error_outline, color: Colors.white),
        background: Colors.redAccent,
        duration: Duration(seconds: 4),
      );
    }
  }

  void _submitPayment() async {
    if (_receiptImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor, sube el comprobante de pago'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isPaymentCompleted = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final userData = authProvider.userData;

      if (token == null) {
        showCustomToast(context, 'No estás autenticado', false);
        setState(() {
          _isPaymentCompleted = false;
        });
        return;
      }

      // Obtener el ID del estudiante del userData
      final studentId = userData?['user']?['id'];
      if (studentId == null) {
        showCustomToast(
            context, 'No se pudo obtener la información del usuario', false);
        setState(() {
          _isPaymentCompleted = false;
        });
        return;
      }

      // 1. Crear el slot booking
      final now = DateTime.now();
      final startTime = now;
      final endTime = now.add(Duration(minutes: 20));

      final slotBookingData = {
        'student_id': studentId,
        'tutor_id': widget.tutorId,
        'user_subject_slot_id': null,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'session_fee': 15.0,
        'booked_at': now.toIso8601String(),
        'calendar_event_id': 'instant_${DateTime.now().millisecondsSinceEpoch}',
        'meeting_link': '',
        'status': 2,
        'meta_data': {'comentario': 'Tutoría instantánea'},
        'subject_id': widget.subjectId,
      };

      final slotBookingResponse =
          await createSlotBooking(token, slotBookingData);
      print('Respuesta al crear tutoría (slot booking): $slotBookingResponse');

      final slotBookingId =
          slotBookingResponse['data']?['id'] ?? slotBookingResponse['id'];
      if (slotBookingId == null) {
        String errorMsg =
            slotBookingResponse['message'] ?? 'Error al crear la tutoría';
        if (slotBookingResponse['errors'] != null) {
          errorMsg += '\n' + slotBookingResponse['errors'].toString();
        }
        showCustomToast(context, errorMsg, false);
        setState(() {
          _isPaymentCompleted = false;
        });
        return;
      }

      // 2. Subir el comprobante de pago usando el nuevo endpoint
      final uploadResponse =
          await uploadPaymentReceipt(token, _receiptImage!, slotBookingId);
      print('Respuesta al subir comprobante: $uploadResponse');
      final comprobanteId = uploadResponse['id'];
      if (comprobanteId == null) {
        String errorMsg =
            uploadResponse['message'] ?? 'Error al subir el comprobante';
        if (uploadResponse['errors'] != null) {
          errorMsg += '\n' + uploadResponse['errors'].toString();
        }
        showCustomToast(context, errorMsg, false);
        setState(() {
          _isPaymentCompleted = false;
        });
        return;
      }

      // Éxito - mostrar mensaje y navegar
      showCustomToast(context,
          '¡Pago procesado exitosamente! La tutoría ha sido creada.', true);

      // Esperar un momento y luego navegar
      await Future.delayed(Duration(seconds: 2));

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => BookingSuccessScreen(
              tutorName: widget.tutorName,
              tutorImage: widget.tutorImage,
              subjectName: widget.selectedSubject,
              sessionDuration: widget.sessionDuration,
              amount: widget.amount,
              sessionTime: DateTime.now(), // Para tutorías instantáneas
            ),
          ),
        );
      }
    } catch (e) {
      print('Error inesperado en _submitPayment: $e');
      showCustomToast(context, 'Error inesperado: $e', false);
      setState(() {
        _isPaymentCompleted = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: makeDismissible(
        context: context,
        child: SlideTransition(
          position: _slideAnimation,
          child: DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.6,
            maxChildSize: 0.9,
            expand: false,
            controller: _scrollController,
            builder: (context, scrollController) {
              // Se envuelve el contenido en OverlaySupport.local para que
              // las notificaciones se muestren DENTRO de este modal.
              return OverlaySupport.local(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.darkBlue,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Handle para arrastrar
                      Container(
                        width: 40,
                        height: 5,
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      // Contenido principal que es desplazable
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header con información del tutor
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundImage:
                                        NetworkImage(widget.tutorImage),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.tutorName,
                                          style: AppTextStyles.heading2
                                              .copyWith(color: Colors.white),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          widget.selectedSubject,
                                          style: AppTextStyles.body
                                              .copyWith(color: Colors.white70),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 30),

                              // Información del pago
                              Container(
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.1)),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Monto a pagar:',
                                            style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 16)),
                                        Text('15 Bs',
                                            style: TextStyle(
                                                color: AppColors.lightBlueColor,
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Duración:',
                                            style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 16)),
                                        Text('20 min',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 30),

                              // Scroll Horizontal para QR y Comprobante
                              Container(
                                height: 350,
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: PageView(
                                        controller: _pageController,
                                        onPageChanged: (index) {
                                          setState(() {
                                            _currentPage = index;
                                          });
                                        },
                                        children: [
                                          // Página 1: QR Code (Compacto)
                                          _buildQRPage(),
                                          // Página 2: Subir comprobante (Con Scroll)
                                          _buildReceiptPage(),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    // Barra de indicadores
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        GestureDetector(
                                          onTap: () =>
                                              _pageController.animateToPage(0,
                                                  duration: Duration(
                                                      milliseconds: 300),
                                                  curve: Curves.easeInOut),
                                          child: _HorizontalStepBar(
                                              isActive: _currentPage == 0,
                                              label: 'QR'),
                                        ),
                                        SizedBox(width: 20),
                                        GestureDetector(
                                          onTap: () =>
                                              _pageController.animateToPage(1,
                                                  duration: Duration(
                                                      milliseconds: 300),
                                                  curve: Curves.easeInOut),
                                          child: _HorizontalStepBar(
                                              isActive: _currentPage == 1,
                                              label: 'Comprobante'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ),
                      // Contenido fijo en la parte inferior (Botón de pago y Stepper)
                      _buildBottomBar(),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Widget para la página del QR
  Widget _buildQRPage() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('💳 Escanea para pagar',
              style: TextStyle(
                  color: AppColors.darkBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Expanded(
            child: ScaleTransition(
              scale: _qrScaleAnimation,
              child: QrImageView(
                  data: _qrData,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.darkBlue),
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _downloadQR,
            icon: Icon(Icons.download, color: AppColors.darkBlue),
            label: Text('Descargar QR',
                style: TextStyle(color: AppColors.darkBlue)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              side: BorderSide(color: AppColors.darkBlue),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25)),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // Widget para la página de subir comprobante
  Widget _buildReceiptPage() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: SingleChildScrollView(
        // <-- Soluciona el overflow
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long,
                    color: AppColors.lightBlueColor, size: 20),
                SizedBox(width: 8),
                Text('📸 Sube el comprobante',
                    style: AppTextStyles.heading2.copyWith(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 12),
            Text(
                'Una vez realizado el pago, sube una captura del comprobante para verificar la transacción.',
                style: TextStyle(
                    color: Colors.white70, fontSize: 14, height: 1.4)),
            SizedBox(height: 20),
            if (_receiptImage != null)
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                          image: FileImage(_receiptImage!), fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _receiptImage = null),
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            shape: BoxShape.circle),
                        child: Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              )
            else
              GestureDetector(
                onTap: _showReceiptSourceDialog,
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        style: BorderStyle.solid),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo,
                          color: AppColors.lightBlueColor, size: 32),
                      SizedBox(height: 8),
                      Text('Toca para subir comprobante',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 14)),
                      SizedBox(height: 4),
                      Text('Cámara o Galería',
                          style:
                              TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            if (_receiptImage != null) ...[
              SizedBox(height: 12),
              Text('✅ Comprobante subido correctamente',
                  style: TextStyle(
                      color: AppColors.lightBlueColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ],
          ],
        ),
      ),
    );
  }

  // Widget para la barra inferior
  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: (_receiptImage != null && !_isPaymentCompleted)
                ? _submitPayment
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: (_receiptImage != null && !_isPaymentCompleted)
                  ? AppColors.lightBlueColor
                  : Colors.grey,
              disabledBackgroundColor: Colors.grey,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
              padding: EdgeInsets.symmetric(vertical: 16),
              minimumSize: Size(double.infinity, 50),
            ),
            child: _isPaymentCompleted
                ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white))),
                    SizedBox(width: 12),
                    Text('Procesando pago...',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ])
                : Text(
                    _receiptImage != null
                        ? 'Confirmar Pago'
                        : 'Sube el comprobante primero',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
          ),
          SizedBox(height: 16),
          Text(
              'La sesión comenzará automáticamente una vez confirmado el pago.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          Padding(
            padding: const EdgeInsets.only(bottom: 0, top: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StepBar(isActive: false),
                SizedBox(width: 12),
                _StepBar(isActive: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget makeDismissible(
      {required Widget child, required BuildContext context}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: GestureDetector(onTap: () {}, child: child),
    );
  }
}

void showCustomToast(BuildContext context, String message, bool isSuccess) {
  final overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: 1.0,
      left: 16.0,
      right: 16.0,
      child: CustomToast(
        message: message,
        isSuccess: isSuccess,
      ),
    ),
  );

  Overlay.of(context).insert(overlayEntry);
  Future.delayed(const Duration(seconds: 3), () {
    overlayEntry.remove();
  });
}

class _StepBar extends StatelessWidget {
  final bool isActive;
  const _StepBar({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      width: 60,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.lightBlueColor
            : Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _HorizontalStepBar extends StatelessWidget {
  final bool isActive;
  final String label;

  const _HorizontalStepBar({
    required this.isActive,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          width: isActive ? 80 : 60,
          height: 6,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.lightBlueColor
                : Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(6),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.lightBlueColor.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive ? AppColors.lightBlueColor : Colors.white54,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
