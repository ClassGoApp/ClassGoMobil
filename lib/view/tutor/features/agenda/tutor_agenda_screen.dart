import 'package:flutter/material.dart';
import 'package:flutter_projects/base_components/custom_snack_bar.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/view/tutor/dashboard/sheets/add_schedule_sheet.dart';
import 'package:flutter_projects/view/tutor/features/agenda/providers/tutor_agenda_provider.dart';
import 'package:intl/intl.dart';

import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/tutor/features/widgets/tutor_header.dart';
import 'package:flutter_projects/view/tutor/features/agenda/agenda_availability_view.dart';
import 'package:flutter_projects/view/tutor/features/agenda/agenda_booking_view.dart';
import 'package:flutter_projects/view/tutor/features/agenda/widgets/agenda_calendar_modal.dart';
import 'package:provider/provider.dart';

enum AgendaMode { classes, availability }

class TutorAgendaScreen extends StatefulWidget {
  const TutorAgendaScreen({Key? key}) : super(key: key);

  @override
  State<TutorAgendaScreen> createState() => _TutorAgendaScreenState();
}

class _TutorAgendaScreenState extends State<TutorAgendaScreen> {
  AgendaMode _currentMode = AgendaMode.classes;
  DateTime _selectedDate = DateTime.now(); 
  List<DateTime> _selectedAvailabilityDates = [DateTime.now()];
@override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final agendaProvider = Provider.of<TutorAgendaProvider>(context, listen: false);
      
      final token = authProvider.token ?? '';
      
      final user = authProvider.userData?['user'];
      final String userIdStr = user != null ? (user['id']?.toString() ?? '') : '';
      final int userId = int.tryParse(userIdStr) ?? authProvider.userId ?? 0;

      if (token.isNotEmpty && userId > 0) {
        agendaProvider.loadReservations(token, userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.blackColor : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        top: false, 
        child: Column(
          children: [
            TutorHeader(
              title: "AGENDA",
              subtitle: _currentMode == AgendaMode.classes 
                  ? "MIS PRÓXIMAS CLASES" 
                  : "CONFIGURAR HORARIOS",
              actionIcon: Icons.today_rounded,
              onActionTap: () {
                final now = DateTime.now();
                setState(() {
                  _selectedDate = now;
                  _selectedAvailabilityDates = [now];
                });
              },
            ),
            const SizedBox(height: 15),

            _buildDateSelector(isDark),
            const SizedBox(height: 20),

            _buildModeToggle(isDark),
            const SizedBox(height: 15),

            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _currentMode == AgendaMode.classes
                    ? AgendaBookingView(selectedDate: _selectedDate)
                    : AgendaAvailabilityView(selectedDate: _selectedAvailabilityDates.first), 
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSmartCalendar() async {
    final List<DateTime>? result = await showDialog<List<DateTime>>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          elevation: 20,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: AgendaCalendarModal(
            mode: _currentMode,
            initialDate: _currentMode == AgendaMode.classes ? _selectedDate : _selectedAvailabilityDates.first,
          ),
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        if (_currentMode == AgendaMode.classes) {
          _selectedDate = result.first; 
        } else {
          _selectedAvailabilityDates = result; 
        }
      });
      if (_currentMode == AgendaMode.availability) {
        _openAddScheduleSheet(result);
      }
    }
  }

  void _openAddScheduleSheet(List<DateTime> targetDays) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final agendaProvider = Provider.of<TutorAgendaProvider>(context, listen: false);

    final user = authProvider.userData?['user'];
    final String token = authProvider.token ?? '';
    final String userId = user != null ? (user['id']?.toString() ?? '') : '';

    await showDialog(
      context: context,
      builder: (context) => AddScheduleSheet(
        selectedDays: targetDays,
        onSave: (startTime, endTime) async {
          final List<Map<String, String>> newSlots = [{'start': startTime, 'end': endTime}];
          final success = await agendaProvider.saveSlotsForDays(
            token: token, userId: userId, days: targetDays, newSlots: newSlots,
          );

          if (!mounted) return;

          if (success) {
            CustomToast.show(
              context,
              "Horario agregado exitosamente",
              isSuccess: true,
            );
          } else {
            CustomToast.show(
              context,
              "Error al guardar el horario",
              isSuccess: false,
            );
          }
        }
      )
    );
  }

  Widget _buildDateSelector(bool isDark) {
    String buttonText = _currentMode == AgendaMode.classes 
        ? DateFormat("dd 'de' MMMM, yyyy", 'es').format(_selectedDate)
        : (_selectedAvailabilityDates.length == 1 
            ? DateFormat("dd 'de' MMMM, yyyy", 'es').format(_selectedAvailabilityDates.first)
            : "${_selectedAvailabilityDates.length} Días seleccionados");

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildArrowButton(Icons.chevron_left_rounded, () {
            setState(() => _currentMode == AgendaMode.classes 
                ? _selectedDate = _selectedDate.subtract(const Duration(days: 1))
                : _selectedAvailabilityDates = [_selectedAvailabilityDates.first.subtract(const Duration(days: 1))]);
          }, isDark),
          
          Expanded(
            child: GestureDetector(
              onTap: _openSmartCalendar,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDarkNeo : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandBlue.withOpacity(isDark ? 0.3 : 0.06),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_month_rounded, size: 18, color: isDark ? AppColors.brandCyan : AppColors.brandBlue),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        buttonText.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'outfit', 
                          fontWeight: FontWeight.w900, 
                          color: isDark ? Colors.white : AppColors.brandBlue, 
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          _buildArrowButton(Icons.chevron_right_rounded, () {
            setState(() => _currentMode == AgendaMode.classes 
                ? _selectedDate = _selectedDate.add(const Duration(days: 1))
                : _selectedAvailabilityDates = [_selectedAvailabilityDates.first.add(const Duration(days: 1))]);
          }, isDark),
        ],
      ),
    );
  }

  Widget _buildModeToggle(bool isDark) {
    final containerBg = isDark ? const Color(0xFF151A24) : Colors.grey[200]!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
            blurStyle: BlurStyle.inner,
          )
        ],
      ),
      child: Row(
        children: [
          _buildToggleOption("MIS CLASES", AgendaMode.classes, isDark),
          _buildToggleOption("DISPONIBILIDAD", AgendaMode.availability, isDark),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String title, AgendaMode mode, bool isDark) {
    final isSelected = _currentMode == mode;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentMode = mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuint,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected 
                ? const LinearGradient(
                    colors: [AppColors.brandCyan, Color(0xFF1A85A0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
           
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'outfit',
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 0.5,
              color: isSelected 
                  ? Colors.white 
                  : (isDark ? Colors.grey[500] : AppColors.brandBlue.withOpacity(0.6)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArrowButton(IconData icon, VoidCallback onTap, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDarkNeo : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.brandBlue.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: isDark ? Colors.white70 : AppColors.brandBlue, size: 22),
        splashRadius: 24,
      ),
    );
  }
}