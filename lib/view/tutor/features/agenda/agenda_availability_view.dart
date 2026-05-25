import 'package:flutter/material.dart';
import 'package:flutter_projects/base_components/custom_snack_bar.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/view/tutor/dashboard/sheets/add_schedule_sheet.dart';
import 'package:flutter_projects/view/tutor/features/agenda/widgets/agenda_schedule_modal.dart';
import 'package:intl/intl.dart';

import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/tutor/features/agenda/providers/tutor_agenda_provider.dart';
import 'package:provider/provider.dart';

enum AvailabilityViewType { daily, monthly }

class AgendaAvailabilityView extends StatefulWidget {
  final DateTime selectedDate;

  const AgendaAvailabilityView({Key? key, required this.selectedDate}) : super(key: key);

  @override
  State<AgendaAvailabilityView> createState() => _AgendaAvailabilityViewState();
}

class _AgendaAvailabilityViewState extends State<AgendaAvailabilityView> {
  AvailabilityViewType _viewType = AvailabilityViewType.daily;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final agendaProvider = Provider.of<TutorAgendaProvider>(context, listen: false);
      
      final user = authProvider.userData?['user'];
      final String token = authProvider.token ?? '';
      final String userId = user != null ? (user['id']?.toString() ?? '') : '';

      if (token.isNotEmpty && userId.isNotEmpty) {
        agendaProvider.loadAvailableSlots(
          token, 
          userId, 
          year: widget.selectedDate.year, 
          month: widget.selectedDate.month,
          forceRefresh: false
        );
      }
    });
  }

  List<Map<String, dynamic>> _getMonthlyBlocks(Map<DateTime, List<Map<String, dynamic>>> allData) {
    final List<Map<String, dynamic>> monthlyList = [];
    allData.forEach((date, slots) {
      if (date.year == widget.selectedDate.year && date.month == widget.selectedDate.month) {
        for (var slot in slots) {
          monthlyList.add({
            'id': slot['id'],
            'start': slot['start'],
            'end': slot['end'],
            'status': slot['status'],
            'date': date,
          });
        }
      }
    });
    monthlyList.sort((a, b) {
      int dateComp = (a['date'] as DateTime).compareTo(b['date'] as DateTime);
      if (dateComp != 0) return dateComp;
      return (a['start'] as String).compareTo(b['start'] as String);
    });
    return monthlyList;
  }

  void _openAddScheduleSheet(String token, String userId, TutorAgendaProvider provider) async {
    List<DateTime> targetDays = [widget.selectedDate];
    await showDialog(
      context: context,
      builder: (context) => AddScheduleSheet(selectedDays: targetDays, onSave: (startTime, endTime) async { 
        final List<Map<String, String>> newSlots = [
          {'start': startTime, 'end': endTime}
        ];
        final success = await provider.saveSlotsForDays(
          token: token,
          userId: userId,
          days: targetDays,
          newSlots: newSlots,
        );
        if (!mounted) return;

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Horario de trabajo configurado correctamente"),
              backgroundColor: AppColors.brandCyan,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("No se pudo guardar el horario. Inténtalo de nuevo."),
              backgroundColor: Colors.redAccent,
            ),
          );
        } 
      },),
    );
  }

  void _processDelete(String token, String slotId, String userId, DateTime date, TutorAgendaProvider provider) async {
    final success = await provider.deleteSlot(token, slotId, userId, date);
    if (!mounted) return;

    if (!success) {
      CustomToast.show(
        context,
        "Error al eliminar el horario. Verifica tu conexión.",
        isSuccess: false,
      );
    } else {
      CustomToast.show(
        context,
        "Horario eliminado correctamente",
        isSuccess: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final agendaProvider = context.watch<TutorAgendaProvider>();

    final user = authProvider.userData?['user'];
    final String token = authProvider.token ?? '';
    final String userId = user != null ? (user['id']?.toString() ?? '') : '';
    
    final List<Map<String, dynamic>> blocks = _viewType == AvailabilityViewType.daily
        ? agendaProvider.getSlotsForDay(widget.selectedDate)
        : _getMonthlyBlocks(agendaProvider.freeTimesByDay);

    final bool showLoader = agendaProvider.isLoadingSlots || agendaProvider.isMutating;
    
    return Column(
      children: [
        _buildTopToolbar(isDark, token, userId, agendaProvider),
        
        Expanded(
          child: showLoader
              ? const Center(child: CircularProgressIndicator(color: AppColors.brandCyan))
              : blocks.isEmpty
                  ? _buildEmptyState(isDark)
                  : ListView.builder(
                      padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 120),
                      physics: const BouncingScrollPhysics(),
                      itemCount: blocks.length,
                      itemBuilder: (context, index) {
                        final block = blocks[index];
                        final DateTime blockDate = block['date'] ?? widget.selectedDate;
                        
                        return _AvailabilityBlockCard(
                          startTime: block['start'] ?? '--:--',
                          endTime: block['end'] ?? '--:--',
                          date: blockDate,
                          showFullDate: _viewType == AvailabilityViewType.monthly,
                          isDark: isDark,
                          onDelete: () => _processDelete(token, block['id'].toString(), userId, blockDate, agendaProvider),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildTopToolbar(bool isDark, String token, String userId, TutorAgendaProvider provider) {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final isPastDay = widget.selectedDate.isBefore(normalizedToday);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E222A) : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildSegmentButton("DÍA", AvailabilityViewType.daily, isDark),
                _buildSegmentButton("MES", AvailabilityViewType.monthly, isDark),
              ],
            ),
          ),

          GestureDetector(
            onTap: isPastDay ? null : () => _openAddScheduleSheet(token, userId, provider),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isPastDay 
                    ? (isDark ? Colors.white10 : Colors.grey[300]) 
                    : AppColors.brandCyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isPastDay 
                      ? Colors.transparent 
                      : AppColors.brandCyan.withOpacity(0.2)
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.add_rounded, 
                      color: isPastDay ? Colors.grey[500] : AppColors.brandCyan, 
                      size: 16),
                  const SizedBox(width: 4),
                  Text(
                    "AÑADIR",
                    style: TextStyle(
                      fontFamily: 'outfit',
                      fontWeight: FontWeight.w900,
                      color: isPastDay ? Colors.grey[500] : AppColors.brandCyan,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(String title, AvailabilityViewType type, bool isDark) {
    final isSelected = _viewType == type;
    return GestureDetector(
      onTap: () => setState(() => _viewType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? const Color(0xFF2A2F3A) : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected && !isDark
              ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
              : [],
        ),
        child: Text(
          title,
          style: TextStyle(
            fontFamily: 'outfit',
            fontWeight: FontWeight.w900,
            fontSize: 11,
            color: isSelected ? (isDark ? Colors.white : const Color(0xFF1A1D1E)) : Colors.grey[500],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 120),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy_rounded, size: 48, color: isDark ? Colors.white24 : Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              _viewType == AvailabilityViewType.daily ? "SIN HORARIOS HOY" : "SIN HORARIOS ESTE MES",
              style: TextStyle(fontFamily: 'outfit', fontWeight: FontWeight.w900, fontSize: 16, color: isDark ? Colors.white70 : Colors.grey[800]),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvailabilityBlockCard extends StatelessWidget {
  final String startTime;
  final String endTime;
  final DateTime date;
  final bool showFullDate;
  final bool isDark;
  final VoidCallback onDelete;

  const _AvailabilityBlockCard({
    required this.startTime,
    required this.endTime,
    required this.date,
    required this.showFullDate,
    required this.isDark,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDarkNeo : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandBlue.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: AppColors.brandCyan.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(DateFormat("dd").format(date), style: const TextStyle(fontFamily: 'outfit', fontWeight: FontWeight.w900, color: AppColors.brandCyan, fontSize: 16, height: 1.0)),
                Text(DateFormat("MMM", "es").format(date).toUpperCase(), style: const TextStyle(fontFamily: 'outfit', fontWeight: FontWeight.bold, color: AppColors.brandCyan, fontSize: 9, height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  showFullDate ? DateFormat("EEEE, d 'de' MMMM", "es").format(date).toUpperCase() : "HORARIO",
                  style: TextStyle(fontFamily: 'manrope', fontWeight: FontWeight.bold, fontSize: 10, color: showFullDate ? AppColors.textLightPrimary : (isDark ? Colors.white54 : Colors.grey[500])),
                ),
                const SizedBox(height: 2),
                Text("$startTime - $endTime", style: TextStyle(fontFamily: 'outfit', fontWeight: FontWeight.w900, fontSize: 16, color: isDark ? Colors.white : AppColors.brandBlue)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.stateUrgent.withOpacity(0.08), shape: BoxShape.circle),
              child: const Icon(Icons.delete_outline_rounded, color: AppColors.stateUrgent, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}