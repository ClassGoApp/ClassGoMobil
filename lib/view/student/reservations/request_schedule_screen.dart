import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/view/components/success_animation_dialog.dart';

class RequestScheduleScreen extends StatefulWidget {
  final int? tutorId;
  final String? tutorName;
  final String? tutorImage;
  final List<Map<String, dynamic>> subjects;
  final Map<String, dynamic>? selectedSubject;

  const RequestScheduleScreen({
    Key? key,
    this.tutorId,
    this.tutorName,
    this.tutorImage,
    this.subjects = const [],
    this.selectedSubject,
  }) : super(key: key);

  @override
  State<RequestScheduleScreen> createState() => _RequestScheduleScreenState();
}

class _RequestScheduleScreenState extends State<RequestScheduleScreen> {
  Map<String, dynamic>? _selectedSubject;
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  int _selectedDurationMinutes = 60;
  final TextEditingController _messageController = TextEditingController();
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _durationOptions = const [
    {'value': 20, 'label': '20 minutos'},
    {'value': 40, 'label': '40 minutos'},
    {'value': 60, 'label': '60 minutos (1h)'},
    {'value': 80, 'label': '80 minutos (1h 20m)'},
    {'value': 100, 'label': '100 minutos (1h 40m)'},
    {'value': 120, 'label': '120 minutos (2h)'},
  ];

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

  @override
  void initState() {
    super.initState();
    if (widget.selectedSubject != null) {
      // Find matching subject in the list
      _selectedSubject = widget.subjects.firstWhere(
        (s) => s['id'] == widget.selectedSubject!['id'],
        orElse: () => widget.selectedSubject!,
      );
    } else if (widget.subjects.isNotEmpty) {
      _selectedSubject = widget.subjects.first;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  String _displaySubjectName(Map<String, dynamic>? subject) {
    if (subject == null) return '';
    return (subject['name'] ?? '').toString();
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
            primary: AppColors.lightBlueColor,
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
            primary: AppColors.lightBlueColor,
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

  void _submitRequest() async {
    if (_selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona una materia.')),
      );
      return;
    }
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
                'La hora sugerida de inicio no puede ser anterior a la hora actual.'),
          ),
        );
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo autenticar la sesión.')),
        );
      }
      return;
    }

    final int subjectId = _selectedSubject!['id'] is int
        ? _selectedSubject!['id']
        : int.tryParse(_selectedSubject!['id'].toString()) ?? 0;

    final String preferredDate =
        DateFormat('yyyy-MM-dd').format(_selectedDate!);

    final String start12 = _formatTime12h(_startTime!);
    final String end12 = _formatTime12h(_getEndTime()!);
    final String preferredTime = '$start12 - $end12';

    final result = await solicitarTutor(
      token,
      subjectId: subjectId,
      preferredDate: preferredDate,
      preferredTime: preferredTime,
      note: _messageController.text,
      tutorId: widget.tutorId,
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (result['success'] == true) {
      // Mostrar diálogo de éxito del proyecto
      showSuccessDialog(
        context: context,
        title: '¡Solicitud Enviada!',
        message: widget.tutorName != null && widget.tutorName!.isNotEmpty
            ? 'Le hemos enviado tu propuesta de horario a ${widget.tutorName}. Te notificaremos cuando responda.'
            : 'Hemos enviado tu propuesta de horario a los tutores disponibles de la materia. Te notificaremos cuando respondan.',
        buttonText: 'Entendido',
        autoCloseDuration: const Duration(seconds: 6),
        onContinue: () {
          Navigator.pop(context); // Volver al screen anterior
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(result['message'] ?? 'Error al enviar la solicitud.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate = _selectedDate == null
        ? 'Selecciona una fecha'
        : DateFormat('EEEE, d \'de\' MMMM', 'es').format(_selectedDate!);

    final String startTimeText =
        _startTime == null ? 'Selecciona hora' : _startTime!.format(context);

    final TimeOfDay? endTime = _getEndTime();
    final String endTimeText = endTime == null ? '' : endTime.format(context);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Solicitar Horario',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: AppFonts.heading,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tutor / Subject Card Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.darkBlue,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: (widget.tutorImage != null &&
                              widget.tutorImage!.isNotEmpty)
                          ? Colors.transparent
                          : AppColors.lightBlueColor.withOpacity(0.2),
                      backgroundImage: (widget.tutorImage != null &&
                              widget.tutorImage!.isNotEmpty)
                          ? NetworkImage(widget.tutorImage!)
                          : null,
                      child: (widget.tutorImage == null ||
                              widget.tutorImage!.isEmpty)
                          ? const Icon(Icons.school_rounded,
                              color: AppColors.lightBlueColor, size: 28)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.tutorName != null &&
                                    widget.tutorName!.isNotEmpty
                                ? widget.tutorName!
                                : (_displaySubjectName(_selectedSubject)
                                        .isNotEmpty
                                    ? 'Tutores de ${_displaySubjectName(_selectedSubject)}'
                                    : 'Solicitud de Horario'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              fontFamily: AppFonts.heading,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.tutorName != null &&
                                    widget.tutorName!.isNotEmpty
                                ? 'Propón tu horario ideal y el tutor evaluará la propuesta.'
                                : 'Propón tu horario ideal y los tutores de esta materia evaluarán tu propuesta.',
                            style: const TextStyle(
                              color: Colors.white70,
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
              const SizedBox(height: 24),

              // Materia Dropdown
              const Text(
                'Materia',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFamily: AppFonts.heading,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.darkBlue,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Map<String, dynamic>>(
                    isExpanded: true,
                    value: _selectedSubject,
                    dropdownColor: AppColors.darkBlue,
                    borderRadius: BorderRadius.circular(12),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppFonts.body,
                    ),
                    items: (widget.subjects.isNotEmpty
                            ? widget.subjects
                            : (_selectedSubject != null
                                ? [_selectedSubject!]
                                : <Map<String, dynamic>>[]))
                        .map((subject) {
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: subject,
                        child: Text(
                          _displaySubjectName(subject),
                          style: const TextStyle(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedSubject = value);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Date Selection
              const Text(
                'Fecha Sugerida',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFamily: AppFonts.heading,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.darkBlue,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedDate != null
                          ? AppColors.lightBlueColor
                          : Colors.white12,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month,
                          color: AppColors.lightBlueColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          formattedDate,
                          style: TextStyle(
                            color: _selectedDate != null
                                ? Colors.white
                                : Colors.white54,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            fontFamily: AppFonts.body,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios,
                          color: Colors.white30, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Time & Duration Selection Side-by-Side
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hora de inicio
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hora de Inicio',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            fontFamily: AppFonts.heading,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _selectStartTime,
                          child: Container(
                            height: 56,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: AppColors.darkBlue,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _startTime != null
                                    ? AppColors.lightBlueColor
                                    : Colors.white12,
                              ),
                            ),
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                const Icon(Icons.access_time,
                                    color: AppColors.lightBlueColor, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    startTimeText,
                                    style: TextStyle(
                                      color: _startTime != null
                                          ? Colors.white
                                          : Colors.white54,
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
                  // Duración
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Duración',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            fontFamily: AppFonts.heading,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.darkBlue,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white12),
                          ),
                          alignment: Alignment.center,
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              isExpanded: true,
                              value: _selectedDurationMinutes,
                              dropdownColor: AppColors.darkBlue,
                              borderRadius: BorderRadius.circular(12),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontFamily: AppFonts.body,
                                fontSize: 14,
                              ),
                              items: _durationOptions.map((opt) {
                                return DropdownMenuItem<int>(
                                  value: opt['value'] as int,
                                  child: Text(
                                    opt['label'] as String,
                                    style: const TextStyle(color: Colors.white),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlueColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.lightBlueColor.withOpacity(0.25),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: AppColors.lightBlueColor, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'El bloque de tutoría finalizará a las: $endTimeText',
                          style: const TextStyle(
                            color: Colors.white,
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
              const SizedBox(height: 24),

              // Additional message
              const Text(
                'Nota / Comentarios Adicionales',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFamily: AppFonts.heading,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _messageController,
                maxLines: 4,
                style: const TextStyle(
                    color: Colors.white, fontFamily: AppFonts.body),
                decoration: InputDecoration(
                  hintText:
                      'Ej. Me gustaría pasar clases lunes o miércoles por la tarde, de preferencia en el horario seleccionado.',
                  hintStyle:
                      const TextStyle(color: Colors.white38, fontSize: 13),
                  fillColor: AppColors.darkBlue,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.lightBlueColor),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lightBlueColor,
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
                          'Enviar Solicitud',
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
    );
  }
}
