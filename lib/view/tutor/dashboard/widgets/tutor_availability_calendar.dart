import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:intl/intl.dart';
import 'package:flutter_projects/view/tutor/dashboard/logic/calendar_selection_controller.dart';

class TutorAvailabilityCalendar extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Map<DateTime, List<Map<String, String>>> freeTimesByDay;
  
  final CalendarSelectionController selectionController;
  final Function(DateTime) onDayTap;

  final Function(DateTime) onPageChanged;
  final VoidCallback onAddSlot;
  final Function(Map<String, String>) onDeleteSlot;
  
  const TutorAvailabilityCalendar({
    Key? key,
    required this.focusedDay,
    required this.selectedDay,
    required this.freeTimesByDay,
    required this.selectionController,
    required this.onPageChanged,
    required this.onAddSlot,
    required this.onDeleteSlot,
    required this.onDayTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculamos si hay slots para el día seleccionado para mostrar feedback visual
    return AnimatedBuilder(
      animation: selectionController,
      builder: (context, _) {

      bool hasSlotsForSelected = selectedDay != null && 
        (freeTimesByDay[DateTime(selectedDay!.year, selectedDay!.month, selectedDay!.day)]?.isNotEmpty ?? false);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HEADER REDISEÑADO: Título + Botón de Acción
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Título con Icono
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.orangeprimary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.calendar_month_rounded, color: AppColors.orangeprimary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Mi Disponibilidad',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              
              // Botón "Añadir" (Subido aquí para acceso rápido)
              ElevatedButton.icon(
                onPressed: onAddSlot,
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                label: const Text("Añadir", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  minimumSize: const Size(0, 36), // Compacto
                ),
              )
            ],
          ),
      
          const SizedBox(height: 16),
      
          // 2. EL CALENDARIO (Contenedor principal)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.darkBlue.withOpacity(0.5), // Fondo más sutil
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              children: [
                _buildCalendarHeader(context),
                const SizedBox(height: 16),
                _buildDaysOfWeek(context),
                const SizedBox(height: 8),
                _buildCalendarGrid(context),
              ],
            ),
          ),
          
          // 3. DETALLE DEL DÍA (Solo aparece si hay día seleccionado)
          if (selectedDay != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkBlue, 
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasSlotsForSelected ? AppColors.primaryGreen.withOpacity(0.3) : Colors.white10
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Horarios para el ${DateFormat('d ' 'MMMM', 'es').format(selectedDay!)}",
                    style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  _buildSelectedDayDetail(context),
                ],
              ),
            ),
          ]
        ],
      );
     });
  }

  Widget _buildCalendarHeader(BuildContext context) {
    String title = DateFormat('MMMM yyyy', 'es').format(focusedDay);
    title = title[0].toUpperCase() + title.substring(1);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _CalendarNavButton(
          icon: Icons.chevron_left_rounded,
          onTap: () => onPageChanged(DateTime(focusedDay.year, focusedDay.month - 1)),
        ),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        _CalendarNavButton(
          icon: Icons.chevron_right_rounded,
          onTap: () => onPageChanged(DateTime(focusedDay.year, focusedDay.month + 1)),
        ),
      ],
    );
  }

  Widget _buildDaysOfWeek(BuildContext context) {
    const weekDays = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: weekDays.map((d) => Expanded(
        child: Center(
          child: Text(d, style: const TextStyle(color: Colors.white38, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      )).toList(),
    );
  }

  Widget _buildCalendarGrid(BuildContext context) {
  final daysInMonth = DateUtils.getDaysInMonth(focusedDay.year, focusedDay.month);
  final firstDayOfMonth = DateTime(focusedDay.year, focusedDay.month, 1);
  final int weekDayOffset = firstDayOfMonth.weekday - 1; 

  return GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 7,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1,
    ),
    itemCount: daysInMonth + weekDayOffset,
    itemBuilder: (context, index) {
      if (index < weekDayOffset) return const SizedBox.shrink();
      
      final day = DateTime(focusedDay.year, focusedDay.month, index - weekDayOffset + 1);
      final normalizedDay = DateUtils.dateOnly(day);
      
      // --- LÓGICA DE ESTADOS (ESTO ES LO NUEVO) ---
      final bool isSelectedSingle = selectedDay != null && DateUtils.isSameDay(selectedDay, day);
      final bool isInRange = selectionController.selectedDays.contains(normalizedDay);
      final bool hasSlots = freeTimesByDay.containsKey(normalizedDay) && freeTimesByDay[normalizedDay]!.isNotEmpty;
      final bool isToday = DateUtils.isSameDay(DateTime.now(), day);

      // Colores dinámicos
      Color bgColor = Colors.transparent;
      if (isInRange) bgColor = AppColors.primaryGreen.withOpacity(0.6); // Rango = Verde fuerte
      else if (isSelectedSingle) bgColor = AppColors.orangeprimary;     // Single = Naranja
      else if (hasSlots) bgColor = AppColors.primaryGreen.withOpacity(0.2); // Slot = Verde suave

      return GestureDetector(
        onTap: () => onDayTap(day), // Usamos el nuevo callback
        onLongPress: () => selectionController.startSelection(day), // Trigger del rango
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: (isToday && !isSelectedSingle && !isInRange) 
                ? Border.all(color: AppColors.orangeprimary, width: 1) 
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                '${day.day}',
                style: TextStyle(
                  color: (isSelectedSingle || isInRange || hasSlots) ? Colors.white : Colors.white38,
                  fontWeight: (isSelectedSingle || isToday || isInRange) ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13
                ),
              ),
              // Puntito si tiene slots (solo si no está seleccionado para no ensuciar)
              if (hasSlots && !isSelectedSingle && !isInRange)
                Positioned(
                  bottom: 6,
                  child: Container(
                    width: 4, height: 4,
                    decoration: const BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle),
                  ),
                )
            ],
          ),
        ),
      );
    },
  );
}
  
  Widget _buildSelectedDayDetail(BuildContext context) {
    final normalizedSelected = DateTime(selectedDay!.year, selectedDay!.month, selectedDay!.day);
    final slots = freeTimesByDay[normalizedSelected] ?? [];

    if (slots.isEmpty) {
       return Row(
         children: [
           Icon(Icons.event_busy, color: Colors.white24, size: 18),
           SizedBox(width: 8),
           Text(
             "Toca 'Añadir' arriba para abrir agenda",
             style: TextStyle(color: Colors.white24, fontStyle: FontStyle.italic, fontSize: 13),
           ),
         ],
       );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: slots.map((slot) => _TimeSlotChip(
        slot: slot,
        onDelete: () => onDeleteSlot(slot),
      )).toList(),
    );
  }
}

class _CalendarNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CalendarNavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
    );
  }
}

class _TimeSlotChip extends StatelessWidget {
  final Map<String, String> slot;
  final VoidCallback onDelete;

  const _TimeSlotChip({required this.slot, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20), // Más redondeado
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time_filled, size: 14, color: AppColors.primaryGreen),
          const SizedBox(width: 6),
          Text(
            '${slot['start']} - ${slot['end']}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
          ),
          const SizedBox(width: 8),
          // Separador vertical pequeño
          Container(height: 12, width: 1, color: Colors.white10),
          const SizedBox(width: 8),
          InkWell(
            onTap: onDelete,
            child: const Icon(Icons.close, size: 16, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}