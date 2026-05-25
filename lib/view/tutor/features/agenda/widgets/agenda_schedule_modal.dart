import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/tutor/features/agenda/tutor_agenda_screen.dart' show AgendaMode;
import 'package:flutter_projects/view/tutor/features/agenda/widgets/agenda_calendar_modal.dart';

class AgendaScheduleModal extends StatefulWidget {
  final DateTime initialDate;

  const AgendaScheduleModal({Key? key, required this.initialDate}) : super(key: key);

  @override
  State<AgendaScheduleModal> createState() => AgendaScheduleModalState();
}

class AgendaScheduleModalState extends State<AgendaScheduleModal> {
  late List<DateTime> _targetDates;
  TimeOfDay _startTime = const TimeOfDay(hour: 11, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _targetDates = [widget.initialDate];
  }

  Future<void> _changeDatesViaCalendar() async {
    final List<DateTime>? result = await showDialog<List<DateTime>>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: AgendaCalendarModal(
            mode: AgendaMode.availability,
            initialDate: _targetDates.first,
          ),
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      setState(() => _targetDates = result);
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.brandCyan, // Acento
              surface: isDark ? const Color(0xFF1E222A) : Colors.white,
              onSurface: isDark ? Colors.white : Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) _startTime = picked;
        else _endTime = picked;
      });
    }
  }

  void _submitData() async {
    setState(() => _isSaving = true);
    try {
      await Future.delayed(const Duration(milliseconds: 800)); 
      if (mounted) Navigator.pop(context, true); 
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // 🎨 PALETA NEUTRA (Adiós al azul excesivo)
    final sheetBg = isDark ? const Color(0xFF151A24) : Colors.white;
    final cardBg = isDark ? const Color(0xFF1E222A) : Colors.grey[50]!;
    final borderColor = isDark ? Colors.white10 : Colors.grey[200]!;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1D1E); // Gris muy oscuro, no azul

    String dateLabel = _targetDates.length == 1
        ? DateFormat("EEEE, d 'de' MMMM", 'es').format(_targetDates.first).toUpperCase()
        : "${_targetDates.length} DÍAS SELECCIONADOS";

    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            "CONFIGURAR HORARIO",
            style: TextStyle(fontFamily: 'outfit', fontWeight: FontWeight.w900, fontSize: 18, color: textColor),
          ),
          const SizedBox(height: 20),

          // Tarjeta de Fechas
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 20, color: Colors.grey[500]),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("APLICAR A:", style: TextStyle(fontFamily: 'manrope', fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[500])),
                      const SizedBox(height: 2),
                      Text(dateLabel, style: TextStyle(fontFamily: 'outfit', fontSize: 14, fontWeight: FontWeight.w900, color: textColor)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _changeDatesViaCalendar,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: const Text("CAMBIAR", style: TextStyle(fontFamily: 'outfit', fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.brandCyan)),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tarjetas de Horas
          Row(
            children: [
              Expanded(child: _buildTimeSelectorBox("HORA INICIO", _startTime, () => _selectTime(context, true), cardBg, borderColor, textColor)),
              const SizedBox(width: 12),
              Expanded(child: _buildTimeSelectorBox("HORA FIN", _endTime, () => _selectTime(context, false), cardBg, borderColor, textColor)),
            ],
          ),
          const SizedBox(height: 28),

          // Botón Confirmar
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _submitData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandCyan, // Solo el botón principal tiene el color de acento
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Text(
                      _targetDates.length > 1 ? "CREAR EN RANGO DE DÍAS" : "GUARDAR DISPONIBILIDAD",
                      style: const TextStyle(fontFamily: 'outfit', fontWeight: FontWeight.w900, fontSize: 14, color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelectorBox(String label, TimeOfDay time, VoidCallback onTap, Color bg, Color border, Color textC) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontFamily: 'manrope', fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[500])),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("$hour:$minute", style: TextStyle(fontFamily: 'outfit', fontSize: 20, fontWeight: FontWeight.w900, color: textC)),
                Icon(Icons.access_time_rounded, size: 18, color: Colors.grey[400]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}