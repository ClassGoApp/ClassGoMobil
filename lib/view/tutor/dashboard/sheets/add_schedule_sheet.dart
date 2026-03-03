import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_projects/styles/app_styles.dart';

class AddScheduleSheet extends StatefulWidget {
  final List<DateTime> selectedDays;
  final Function(String startTime, String endTime) onSave;

  const AddScheduleSheet({
    Key? key,
    required this.selectedDays,
    required this.onSave,
  }) : super(key: key);

  @override
  State<AddScheduleSheet> createState() => _AddScheduleSheetState();
}

class _AddScheduleSheetState extends State<AddScheduleSheet> {
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  
  int _activeFieldIndex = 0; 

  // Controladores del Rodillo
  late FixedExtentScrollController _hourWheelCtrl;
  late FixedExtentScrollController _minWheelCtrl;

  @override
  void initState() {
    super.initState();
    final now = TimeOfDay.now();
    _startTime = TimeOfDay(hour: now.hour == 23 ? 22 : now.hour + 1, minute: 0);
    _endTime = TimeOfDay(hour: _startTime.hour + 1, minute: 0);

    // Inicializamos los rodillos en la hora de INICIO
    _hourWheelCtrl = FixedExtentScrollController(initialItem: 1000 * 24 + _startTime.hour);
    _minWheelCtrl = FixedExtentScrollController(initialItem: 1000 * 60 + _startTime.minute);
  }

  @override
  void dispose() {
    _hourWheelCtrl.dispose();
    _minWheelCtrl.dispose();
    super.dispose();
  }

  String _getDaysDisplayText() {
    if (widget.selectedDays.isEmpty) return "SIN FECHA";
    final days = List<DateTime>.from(widget.selectedDays)..sort();
    if (days.length == 1) return DateFormat('MMM dd', 'es').format(days.first).toUpperCase();
    
    final first = DateFormat('MMM dd', 'es').format(days.first).toUpperCase();
    final last = DateFormat('MMM dd', 'es').format(days.last).toUpperCase();
    return "$first - $last";
  }

  // Se llama cuando el usuario gira el rodillo
  void _onWheelChanged(int hourIndex, int minuteIndex) {
    final h = hourIndex % 24;
    final m = minuteIndex % 60;
    
    setState(() {
      if (_activeFieldIndex == 0) {
        _startTime = TimeOfDay(hour: h, minute: m);
      } else {
        _endTime = TimeOfDay(hour: h, minute: m);
      }
    });
  }

  // Cambia la pestaña entre INICIA y FINALIZA
  void _setActiveField(int index) {
    setState(() {
      _activeFieldIndex = index;
      final target = index == 0 ? _startTime : _endTime;
      // Movemos el rodillo para que coincida con la hora de la pestaña seleccionada
      _hourWheelCtrl.jumpToItem(1000 * 24 + target.hour);
      _minWheelCtrl.jumpToItem(1000 * 60 + target.minute);
    });
  }

  void _handleConfirm() {
    final startDouble = _startTime.hour + _startTime.minute / 60.0;
    final endDouble = _endTime.hour + _endTime.minute / 60.0;

    if (startDouble >= endDouble) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("La hora de fin debe ser mayor a la de inicio"), backgroundColor: Colors.redAccent)
      );
      return;
    }

    final sTime = "${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}";
    final eTime = "${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}";
    
    widget.onSave(sTime, eTime);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF151A24) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.brandBlue;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      elevation: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340), 
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))]
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, 
            children: [
              // Botón Cerrar (X)
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close_rounded, color: Colors.grey, size: 24),
                ),
              ),
              
              // Icono central
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.brandCyan.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.access_time_rounded, color: AppColors.brandCyan, size: 28),
              ),
              const SizedBox(height: 16),

              Text("Horario de Trabajo", style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'outfit')),
              const SizedBox(height: 4),
              Text("Define el rango para los días seleccionados", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              
              const SizedBox(height: 24),

              // Píldora de Rango
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.brandCyan.withOpacity(0.3), width: 1.5),
                  color: isDark ? Colors.white.withOpacity(0.02) : Colors.transparent,
                ),
                child: Text(_getDaysDisplayText(), style: const TextStyle(color: AppColors.brandCyan, fontWeight: FontWeight.bold, fontSize: 12)),
              ),

              const SizedBox(height: 24),

              // PESTAÑAS (INICIA / FINALIZA)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(child: _buildTab("INICIA", _startTime, 0, isDark)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTab("FINALIZA", _endTime, 1, isDark)),
                ],
              ),

              const SizedBox(height: 24),

              // RODILLOS MÁGICOS (WHEEL PICKER)
              _buildWheelPicker(isDark),

              const SizedBox(height: 32),

              // Botón Confirmar
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _handleConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.brandCyan : AppColors.brandBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: const Text("CONFIRMAR HORARIO", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET PESTAÑAS ---
  Widget _buildTab(String label, TimeOfDay time, int index, bool isDark) {
    final isActive = _activeFieldIndex == index;
    final activeColor = AppColors.brandCyan;
    final inactiveColor = isDark ? Colors.white10 : Colors.black12;
    final textColor = isDark ? Colors.white : AppColors.brandBlue;

    return GestureDetector(
      onTap: () => _setActiveField(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.1) : Colors.transparent,
          border: Border.all(color: isActive ? activeColor : inactiveColor, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: isActive ? activeColor : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}",
              style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET RODILLO INTERNO ---
  Widget _buildWheelPicker(bool isDark) {
    return SizedBox(
      height: 100, 
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Fondo que resalta la selección del medio
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : AppColors.brandCyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildInfiniteWheel(
                controller: _hourWheelCtrl, 
                count: 24, 
                isDark: isDark, 
                onChanged: (val) => _onWheelChanged(val, _minWheelCtrl.selectedItem)
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(":", style: TextStyle(color: isDark ? Colors.white : AppColors.brandBlue, fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              _buildInfiniteWheel(
                controller: _minWheelCtrl, 
                count: 60, 
                isDark: isDark, 
                onChanged: (val) => _onWheelChanged(_hourWheelCtrl.selectedItem, val)
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfiniteWheel({required FixedExtentScrollController controller, required int count, required bool isDark, required Function(int) onChanged}) {
    return SizedBox(
      width: 60,
      child: ListWheelScrollView.useDelegate(
        controller: controller, 
        itemExtent: 40, 
        physics: const FixedExtentScrollPhysics(), 
        onSelectedItemChanged: onChanged, 
        perspective: 0.005, 
        diameterRatio: 1.2, 
        useMagnifier: true, 
        magnification: 1.2,
        childDelegate: ListWheelChildBuilderDelegate(
          builder: (context, index) {
            return Center(
              child: Text(
                (index % count).toString().padLeft(2, '0'), 
                style: TextStyle(fontSize: 20, color: isDark ? Colors.white : AppColors.brandBlue, fontWeight: FontWeight.w600)
              )
            );
          },
        ),
      ),
    );
  }
}