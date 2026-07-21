import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/view/components/success_animation_dialog.dart';
import 'package:flutter_projects/view/student/reservations/paymentQR/payment_qr_screen.dart';

class ScheduleRequestDetailScreen extends StatefulWidget {
  final String token;

  const ScheduleRequestDetailScreen({
    Key? key,
    required this.token,
  }) : super(key: key);

  @override
  State<ScheduleRequestDetailScreen> createState() =>
      _ScheduleRequestDetailScreenState();
}

class _ScheduleRequestDetailScreenState
    extends State<ScheduleRequestDetailScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _negotiationData;

  @override
  void initState() {
    super.initState();
    _loadRequestDetails();
  }

  Future<void> _loadRequestDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await getNegotiationDetail(widget.token);
      if (result['success'] == true) {
        setState(() {
          _negotiationData = result['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Error al cargar los detalles.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión: $e';
        _isLoading = false;
      });
    }
  }

  void _acceptProposal() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await acceptNegotiation(widget.token);
      if (result['success'] == true) {
        showSuccessDialog(
          context: context,
          title: '¡Propuesta Aceptada!',
          message:
              'Has aceptado el horario propuesto. El estudiante procederá al pago.',
          buttonText: 'Entendido',
          onContinue: () {
            Navigator.pop(context);
          },
        );
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(result['message'] ?? 'Error al aceptar la propuesta.')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _rejectProposal() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkBlue,
        title: const Text('Rechazar Propuesta',
            style:
                TextStyle(color: Colors.white, fontFamily: AppFonts.heading)),
        content: const Text(
          '¿Estás seguro de que deseas rechazar esta solicitud de tutoría? Esta acción finalizará el proceso de negociación.',
          style: TextStyle(color: Colors.white70, fontFamily: AppFonts.body),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.redColor),
            child: const Text('Rechazar',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await rejectNegotiation(widget.token);
      if (result['success'] == true) {
        showSuccessDialog(
          context: context,
          title: 'Solicitud Rechazada',
          message: 'Has rechazado la propuesta de tutoría.',
          buttonText: 'Aceptar',
          onContinue: () {
            Navigator.pop(context);
          },
        );
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(result['message'] ?? 'Error al rechazar la propuesta.')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showCounterOfferModal() {
    final String role =
        (_negotiationData?['role'] ?? 'tutor').toString().toLowerCase();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CounterOfferBottomSheet(
        token: widget.token,
        tutorName: _negotiationData?['tutor']?['name'] ?? 'Tutor',
        role: role,
        currentDate: _negotiationData?['request']?['current_date']?.toString(),
        currentTime: _negotiationData?['request']?['current_time']?.toString(),
        currentDuration:
            _negotiationData?['request']?['current_duration']?.toString(),
        onSuccess: () {
          Navigator.pop(context); // Close bottom sheet
          Navigator.pop(this.context); // Close details page
        },
      ),
    );
  }

  void _navigateToPayment() {
    try {
      final String durStr =
          (_negotiationData?['request']?['current_duration'] ?? '60')
              .toString()
              .toLowerCase();
      int mins = 60;
      if (durStr.contains('min')) {
        final match = RegExp(r'(\d+)\s*min').firstMatch(durStr);
        if (match != null) {
          mins = int.tryParse(match.group(1) ?? '') ?? 60;
        }
      } else if (durStr.contains('h') || durStr.contains('hora')) {
        final hourMatch = RegExp(r'(\d+)\s*(h|hora)').firstMatch(durStr);
        final minMatch = RegExp(r'(\d+)\s*(m|min)').firstMatch(durStr);
        int h = 0;
        if (hourMatch != null) {
          h = int.tryParse(hourMatch.group(1) ?? '0') ?? 0;
        }
        int m = 0;
        if (minMatch != null) {
          m = int.tryParse(minMatch.group(1) ?? '0') ?? 0;
        }
        mins = h * 60 + m;
      }

      final double basePrice20Min = double.tryParse(
              _negotiationData?['tutor']?['price']?.toString() ??
              _negotiationData?['request']?['price']?.toString() ??
              '20') ??
          20.0;
      final double totalAmount = basePrice20Min * (mins / 20.0);
      final String amountStr = "${totalAmount.toInt()} Bs";

      DateTime? scheduledDate;
      try {
        scheduledDate =
            DateTime.parse(_negotiationData?['request']?['current_date']);
      } catch (_) {
        scheduledDate = DateTime.now();
      }

      final tutorName = _negotiationData?['tutor']?['full_name'] ??
          _negotiationData?['tutor']?['name'] ??
          'Tutor';
      final tutorImage = _negotiationData?['tutor']?['profile_image_url'] ?? '';
      final selectedSubject =
          _negotiationData?['subject']?['name'] ?? 'Materia';
      final tutorId =
          int.tryParse(_negotiationData?['tutor']?['id']?.toString() ?? '') ??
              0;
      final subjectId =
          int.tryParse(_negotiationData?['subject']?['id']?.toString() ?? '') ??
              0;

      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          barrierColor: Colors.black.withOpacity(0.6),
          barrierDismissible: true,
          pageBuilder: (context, animation, secondaryAnimation) {
            return PaymentQRScreen(
              tutorName: tutorName,
              tutorImage: tutorImage,
              selectedSubject: selectedSubject,
              amount: amountStr,
              sessionDuration: "$mins min",
              tutorId: tutorId,
              subjectId: subjectId,
              scheduledDate: scheduledDate,
              scheduledTime:
                  _negotiationData?['request']?['current_time']?.toString() ?? '',
              isScheduledBooking: true,
              isScheduleRequest: true,
              slotId: null, // Custom negotiated slot
              onCancel: () {
                Navigator.of(context).pop();
              },
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al iniciar el proceso de pago: $e')),
      );
    }
  }

  Widget _buildStatusBadge(String status) {
    String label = '';
    Color color = Colors.grey;
    Color textColor = Colors.white;

    switch (status.toLowerCase()) {
      case 'pending':
        label = 'Pendiente de Respuesta';
        color = Colors.amber.withOpacity(0.15);
        textColor = Colors.amber;
        break;
      case 'countered_by_tutor':
        label = 'Contraoferta del Tutor';
        color = AppColors.brandCyan.withOpacity(0.15);
        textColor = AppColors.brandCyan;
        break;
      case 'countered_by_student':
        label = 'Contraoferta del Estudiante';
        color = Colors.purple.withOpacity(0.15);
        textColor = Colors.purple;
        break;
      case 'accepted':
        label = 'Propuesta Aceptada';
        color = Colors.green.withOpacity(0.15);
        textColor = Colors.green;
        break;
      case 'paid':
        label = 'Tutoría Pagada y Reservada';
        color = AppColors.completeStatusColor;
        textColor = AppColors.completeStatusTextColor;
        break;
      case 'rejected':
        label = 'Rechazada / Cancelada';
        color = AppColors.redBackgroundColor;
        textColor = AppColors.redColor;
        break;
      default:
        label = status.toUpperCase();
        color = Colors.grey.withOpacity(0.2);
        textColor = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          fontFamily: AppFonts.body,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor =
        isDark ? AppColors.darkBackground : AppColors.softWhiteBg;
    final Color cardColor = isDark ? const Color(0xFF151A24) : Colors.white;
    final Color titleColor = isDark ? Colors.white : AppColors.brandBlue;
    final Color subtitleColor = isDark ? Colors.white70 : Colors.black87;

    final String role =
        (_negotiationData?['role'] ?? 'tutor').toString().toLowerCase();
    final String status = (_negotiationData?['request']?['status'] ?? 'pending')
        .toString()
        .toLowerCase();

    final bool isViewerTutor = role == 'tutor';
    final bool canInteract = isViewerTutor
        ? (status == 'pending' || status == 'countered_by_student')
        : (status == 'countered_by_tutor');

    final bool isFinalized = status == 'rejected' || status == 'paid';

    final bool isWaitingForOther = isViewerTutor
        ? (status == 'countered_by_tutor' || status == 'accepted')
        : (status == 'pending' ||
            status == 'countered_by_student' ||
            status == 'accepted');

    final Map<String, dynamic>? counterParty = isViewerTutor
        ? (_negotiationData?['student'] as Map<String, dynamic>?)
        : (_negotiationData?['tutor'] as Map<String, dynamic>?);
    final String counterPartyRoleLabel = isViewerTutor ? 'Estudiante' : 'Tutor';
    final String counterPartyName = counterParty?['full_name'] ??
        counterParty?['name'] ??
        counterPartyRoleLabel;
    final String counterPartyEmail = counterParty?['email'] ?? '';
    final String counterPartyInitial =
        (counterPartyName.isNotEmpty ? counterPartyName[0] : 'U').toUpperCase();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? Colors.white : AppColors.brandBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detalle de Propuesta',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.brandBlue,
            fontWeight: FontWeight.bold,
            fontFamily: AppFonts.heading,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.brandCyan))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 54, color: AppColors.redColor),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black87,
                              fontSize: 15),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadRequestDetails,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brandCyan),
                          child: const Text('Reintentar',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),
                )
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Estado de negociación:',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.grey[600],
                                  fontSize: 13,
                                  fontFamily: AppFonts.body,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusBadge(_negotiationData?['request']
                                    ?['status'] ??
                                'pending'),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Conflict Warning
                        if (_negotiationData?['isSlotBooked'] == true) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.redBackgroundColor,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: AppColors.redBorderColor),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded,
                                    color: AppColors.redColor, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '¡Atención! Tienes otro bloque de clase reservado que se cruza con este horario. Te sugerimos realizar una contraoferta.',
                                    style: TextStyle(
                                      color: Colors.red[900],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: AppFonts.body,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],

                        // Counter Party Info Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: isDark
                                    ? Colors.white10
                                    : Colors.grey[200]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withOpacity(isDark ? 0.2 : 0.03),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              )
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor:
                                    AppColors.brandCyan.withOpacity(0.15),
                                radius: 24,
                                child: Text(
                                  counterPartyInitial,
                                  style: const TextStyle(
                                    color: AppColors.brandCyan,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    fontFamily: AppFonts.heading,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      counterPartyRoleLabel,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.grey[600],
                                        fontSize: 11,
                                        fontFamily: AppFonts.body,
                                      ),
                                    ),
                                    Text(
                                      counterPartyName,
                                      style: TextStyle(
                                        color: titleColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        fontFamily: AppFonts.heading,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      counterPartyEmail,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white38
                                            : Colors.grey[500],
                                        fontSize: 12,
                                        fontFamily: AppFonts.body,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Proposal Details Block
                        const Text(
                          'Detalles de la Tutoría',
                          style: TextStyle(
                            color: AppColors.brandCyan,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            fontFamily: AppFonts.heading,
                          ),
                        ),
                        const SizedBox(height: 10),

                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: isDark
                                    ? Colors.white10
                                    : Colors.grey[200]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withOpacity(isDark ? 0.2 : 0.03),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow(
                                isDark,
                                icon: Icons.book_outlined,
                                label: 'Materia',
                                value: _negotiationData?['subject']?['name'] ??
                                    'Materia',
                              ),
                              const Divider(height: 24, color: Colors.white10),
                              _buildDetailRow(
                                isDark,
                                icon: Icons.calendar_today_outlined,
                                label: 'Fecha Propuesta',
                                value: _negotiationData?['formattedDate'] ??
                                    _negotiationData?['request']
                                        ?['current_date'] ??
                                    '',
                              ),
                              const Divider(height: 24, color: Colors.white10),
                              _buildDetailRow(
                                isDark,
                                icon: Icons.access_time_outlined,
                                label: 'Horario',
                                value: _negotiationData?['request']
                                        ?['current_time'] ??
                                    '',
                              ),
                              const Divider(height: 24, color: Colors.white10),
                              _buildDetailRow(
                                isDark,
                                icon: Icons.timer_outlined,
                                label: 'Duración',
                                value: _negotiationData?['request']
                                        ?['current_duration'] ??
                                    '',
                              ),
                              if (_negotiationData?['request']?['note'] !=
                                      null &&
                                  (_negotiationData?['request']?['note']
                                          as String)
                                      .isNotEmpty) ...[
                                const Divider(
                                    height: 24, color: Colors.white10),
                                _buildDetailRow(
                                  isDark,
                                  icon: Icons.notes_outlined,
                                  label: 'Mensaje del Estudiante',
                                  value: _negotiationData?['request']
                                          ?['note'] ??
                                      '',
                                  valueStyle: TextStyle(
                                    color: subtitleColor,
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                    fontFamily: AppFonts.body,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Action Buttons
                        if (canInteract) ...[
                          Column(
                            children: [
                              // Aceptar Propuesta (Primary button)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _acceptProposal,
                                  icon: const Icon(Icons.check_circle_outline,
                                      color: Colors.white),
                                  label: const Text(
                                    'Aceptar Propuesta',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        fontFamily: AppFonts.heading),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Row of Counter-offer and Reject
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _showCounterOfferModal,
                                      icon: const Icon(Icons.compare_arrows,
                                          color: AppColors.brandCyan),
                                      label: const Text(
                                        'Contraofertar',
                                        style: TextStyle(
                                            color: AppColors.brandCyan,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: AppFonts.heading),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                            color: AppColors.brandCyan,
                                            width: 1.5),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14)),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _rejectProposal,
                                      icon: const Icon(Icons.cancel_outlined,
                                          color: AppColors.redColor),
                                      label: const Text(
                                        'Rechazar',
                                        style: TextStyle(
                                            color: AppColors.redColor,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: AppFonts.heading),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                            color: AppColors.redColor,
                                            width: 1.5),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14)),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ] else if (isFinalized) ...[
                          Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 20.0),
                              child: Text(
                                'Esta negociación ha finalizado.',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.grey[500],
                                  fontWeight: FontWeight.bold,
                                  fontFamily: AppFonts.body,
                                ),
                              ),
                            ),
                          )
                        ] else if (isWaitingForOther) ...[
                          Column(
                            children: [
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 20.0),
                                  child: Text(
                                    isViewerTutor
                                        ? (status == 'countered_by_tutor'
                                            ? 'Esperando respuesta del estudiante.'
                                            : 'Propuesta aceptada. Esperando a que el estudiante realice el pago.')
                                        : (status == 'accepted'
                                            ? 'Propuesta aceptada. Procede con el pago para confirmar la tutoría.'
                                            : 'Esperando respuesta del tutor.'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.grey[600],
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FontStyle.italic,
                                      fontFamily: AppFonts.body,
                                    ),
                                  ),
                                ),
                              ),
                              if (!isViewerTutor && status == 'accepted') ...[
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _navigateToPayment,
                                    icon: const Icon(Icons.payment_outlined,
                                        color: Colors.white),
                                    label: const Text(
                                      'Proceder al Pago',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          fontFamily: AppFonts.heading),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.brandCyan,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14)),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildDetailRow(
    bool isDark, {
    required IconData icon,
    required String label,
    required String value,
    TextStyle? valueStyle,
  }) {
    final Color titleColor = isDark ? Colors.white : AppColors.brandBlue;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.brandCyan, size: 20),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.grey[500],
                  fontSize: 11,
                  fontFamily: AppFonts.body,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: valueStyle ??
                    TextStyle(
                      color: titleColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppFonts.body,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CounterOfferBottomSheet extends StatefulWidget {
  final String token;
  final String tutorName;
  final String role;
  final String? currentDate;
  final String? currentTime;
  final String? currentDuration;
  final VoidCallback onSuccess;

  const _CounterOfferBottomSheet({
    Key? key,
    required this.token,
    required this.tutorName,
    required this.role,
    this.currentDate,
    this.currentTime,
    this.currentDuration,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<_CounterOfferBottomSheet> createState() =>
      _CounterOfferBottomSheetState();
}

class _CounterOfferBottomSheetState extends State<_CounterOfferBottomSheet> {
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  int _selectedDurationMinutes = 60;
  final TextEditingController _noteController = TextEditingController();
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _durationOptions = const [
    {'value': 20, 'label': '20 minutos'},
    {'value': 30, 'label': '30 minutos'},
    {'value': 40, 'label': '40 minutos'},
    {'value': 60, 'label': '60 minutos (1h)'},
    {'value': 80, 'label': '80 minutos (1h 20m)'},
    {'value': 100, 'label': '100 minutos (1h 40m)'},
    {'value': 120, 'label': '120 minutos (2h)'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    try {
      if (widget.currentDate != null) {
        _selectedDate = DateTime.tryParse(widget.currentDate!);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        if (_selectedDate != null && _selectedDate!.isBefore(today)) {
          _selectedDate = today;
        }
      }

      if (widget.currentTime != null) {
        final parts = widget.currentTime!.split(' - ');
        if (parts.isNotEmpty) {
          final startTimeStr = parts[0].trim();
          final timeParts = startTimeStr.split(' ');
          if (timeParts.length == 2) {
            final hhMm = timeParts[0].split(':');
            final amPm = timeParts[1].toUpperCase();
            if (hhMm.length == 2) {
              int hour = int.tryParse(hhMm[0]) ?? 12;
              final int minute = int.tryParse(hhMm[1]) ?? 0;
              if (amPm == 'PM' && hour < 12) {
                hour += 12;
              } else if (amPm == 'AM' && hour == 12) {
                hour = 0;
              }
              _startTime = TimeOfDay(hour: hour, minute: minute);
            }
          }
        }
      }

      if (widget.currentDuration != null) {
        final durationStr = widget.currentDuration!.toLowerCase();
        int? foundMinutes;

        for (final opt in _durationOptions) {
          final label = (opt['label'] as String).toLowerCase();
          if (durationStr.contains(label) || label.contains(durationStr)) {
            foundMinutes = opt['value'] as int;
            break;
          }
        }

        if (foundMinutes == null) {
          if (durationStr.contains('h') || durationStr.contains('hora')) {
            final RegExp hourRegex = RegExp(r'(\d+)\s*(h|hora)');
            final RegExp minRegex = RegExp(r'(\d+)\s*(m|min)');
            final hourMatch = hourRegex.firstMatch(durationStr);
            final minMatch = minRegex.firstMatch(durationStr);

            int mins = 0;
            if (hourMatch != null) {
              mins += (int.tryParse(hourMatch.group(1) ?? '0') ?? 0) * 60;
            }
            if (minMatch != null) {
              mins += int.tryParse(minMatch.group(1) ?? '0') ?? 0;
            }
            if (mins > 0) foundMinutes = mins;
          } else {
            final RegExp numberRegex = RegExp(r'\d+');
            final match = numberRegex.firstMatch(durationStr);
            if (match != null) {
              foundMinutes = int.tryParse(match.group(0)!) ?? 60;
            }
          }
        }

        if (foundMinutes != null) {
          if (_durationOptions.any((opt) => opt['value'] == foundMinutes)) {
            _selectedDurationMinutes = foundMinutes;
          } else {
            int closestValue = _durationOptions.first['value'] as int;
            int minDifference = (foundMinutes - closestValue).abs();
            for (final opt in _durationOptions) {
              final val = opt['value'] as int;
              final diff = (foundMinutes - val).abs();
              if (diff < minDifference) {
                minDifference = diff;
                closestValue = val;
              }
            }
            _selectedDurationMinutes = closestValue;
          }
        }
      }
    } catch (e) {
      print('Error al pre-poblar los campos de contraoferta: $e');
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  TimeOfDay? _getEndTime() {
    if (_startTime == null) return null;
    final now = DateTime.now();
    final startDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _startTime!.hour,
      _startTime!.minute,
    );
    final endDateTime =
        startDateTime.add(Duration(minutes: _selectedDurationMinutes));
    return TimeOfDay.fromDateTime(endDateTime);
  }

  String _formatTime12h(TimeOfDay t) {
    final hour = t.hour == 0
        ? 12
        : t.hour > 12
            ? t.hour - 12
            : t.hour;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Future<void> _selectDate() async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = DateTime(now.year, now.month, now.day);
    final DateTime lastDate = now.add(const Duration(days: 90));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          dialogBackgroundColor: AppColors.darkBlue,
          colorScheme: const ColorScheme.dark(
            primary: AppColors.brandCyan,
            onPrimary: Colors.white,
            surface: AppColors.darkBlue,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectStartTime() async {
    final TimeOfDay initial = _startTime ?? TimeOfDay.now();

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          dialogBackgroundColor: AppColors.darkBlue,
          colorScheme: const ColorScheme.dark(
            primary: AppColors.brandCyan,
            onPrimary: Colors.white,
            surface: AppColors.darkBlue,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  void _submitCounterOffer() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor, selecciona una fecha sugerida.')),
      );
      return;
    }
    if (_startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor, selecciona una hora de inicio.')),
      );
      return;
    }

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime selectedDateOnly =
        DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);

    if (selectedDateOnly.isAtSameMomentAs(today)) {
      final int startMinutes = _startTime!.hour * 60 + _startTime!.minute;
      final int currentMinutes = now.hour * 60 + now.minute;

      if (startMinutes < currentMinutes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'La hora de inicio no puede ser anterior a la hora actual.')),
        );
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    final String counterDateStr =
        DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final String start12 = _formatTime12h(_startTime!);
    final String end12 = _formatTime12h(_getEndTime()!);
    final String counterTimeStr = '$start12 - $end12';

    // Se asocia el label de la duración correspondiente
    final String durationLabel = _durationOptions.firstWhere(
      (opt) => opt['value'] == _selectedDurationMinutes,
      orElse: () => {'label': '$_selectedDurationMinutes min'},
    )['label'] as String;

    final result = await counterNegotiation(
      widget.token,
      {
        'counter_date': counterDateStr,
        'counter_time': counterTimeStr,
        'counter_duration': durationLabel,
        'note': _noteController.text,
      },
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (result['success'] == true) {
      showSuccessDialog(
        context: context,
        title: '¡Contraoferta Enviada!',
        message: widget.role == 'tutor'
            ? 'Tu nueva propuesta de horario ha sido enviada al estudiante con éxito.'
            : 'Tu nueva propuesta de horario ha sido enviada al tutor con éxito.',
        buttonText: 'Aceptar',
        autoCloseDuration: const Duration(seconds: 6),
        onContinue: widget.onSuccess,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(result['message'] ?? 'Error al enviar la contraoferta.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String formattedDate = _selectedDate == null
        ? 'Selecciona una fecha'
        : DateFormat('EEEE, d \'de\' MMMM', 'es').format(_selectedDate!);

    final String startTimeText =
        _startTime == null ? 'Selecciona hora' : _startTime!.format(context);
    final TimeOfDay? endTime = _getEndTime();
    final String endTimeText = endTime == null ? '' : endTime.format(context);

    final Color hintTextColor = isDark ? Colors.white38 : Colors.black38;
    final Color selectedTextColor = isDark ? Colors.white : Colors.black87;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBlue : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pull Bar & Header
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Contraofertar Horario',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.brandBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        fontFamily: AppFonts.heading,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close,
                          color: isDark ? Colors.white70 : Colors.black54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Date Selection
                const Text(
                  'Fecha Sugerida',
                  style: TextStyle(
                      color: AppColors.brandCyan,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      fontFamily: AppFonts.heading),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBackground
                          : AppColors.softWhiteBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _selectedDate != null
                              ? AppColors.brandCyan
                              : Colors.white12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month,
                            color: AppColors.brandCyan),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            formattedDate,
                            style: TextStyle(
                              color: _selectedDate != null
                                  ? selectedTextColor
                                  : hintTextColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              fontFamily: AppFonts.body,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Time & Duration Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hora de Inicio',
                            style: TextStyle(
                                color: AppColors.brandCyan,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                fontFamily: AppFonts.heading),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _selectStartTime,
                            child: Container(
                              height: 56,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkBackground
                                    : AppColors.softWhiteBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: _startTime != null
                                        ? AppColors.brandCyan
                                        : Colors.white12),
                              ),
                              alignment: Alignment.centerLeft,
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time,
                                      color: AppColors.brandCyan, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      startTimeText,
                                      style: TextStyle(
                                        color: _startTime != null
                                            ? selectedTextColor
                                            : hintTextColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        fontFamily: AppFonts.body,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Duración',
                            style: TextStyle(
                                color: AppColors.brandCyan,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                fontFamily: AppFonts.heading),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 56,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkBackground
                                  : AppColors.softWhiteBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.grey[200]!),
                            ),
                            alignment: Alignment.center,
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                isExpanded: true,
                                value: _selectedDurationMinutes,
                                dropdownColor:
                                    isDark ? AppColors.darkBlue : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: AppFonts.body,
                                  fontSize: 14,
                                ),
                                items: _durationOptions.map((opt) {
                                  return DropdownMenuItem<int>(
                                    value: opt['value'] as int,
                                    child: Text(
                                      opt['label'] as String,
                                      style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(
                                        () => _selectedDurationMinutes = value);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // End Time Display Info Block
                if (_startTime != null) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.brandCyan.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.brandCyan.withOpacity(0.25),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: AppColors.brandCyan, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'El bloque sugerido finalizará a las: $endTimeText',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: AppFonts.body,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // Message field
                const Text(
                  'Nota / Mensaje para el Estudiante',
                  style: TextStyle(
                      color: AppColors.brandCyan,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      fontFamily: AppFonts.heading),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  maxLines: 3,
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontFamily: AppFonts.body),
                  decoration: InputDecoration(
                    hintText: 'Explica el porqué de la contraoferta...',
                    hintStyle: TextStyle(color: hintTextColor, fontSize: 13),
                    fillColor: isDark
                        ? AppColors.darkBackground
                        : AppColors.softWhiteBg,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: isDark ? Colors.white10 : Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: isDark ? Colors.white10 : Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.brandCyan),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitCounterOffer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandCyan,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Enviar Contraoferta',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              fontFamily: AppFonts.heading,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
