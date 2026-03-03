import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CalendarSelectionController extends ChangeNotifier {
  bool _isRangeMode = false;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  Set<DateTime> _selectedDays = {};

  bool get isRangeMode => _isRangeMode;
  Set<DateTime> get selectedDays => _selectedDays;
  int get selectedCount => _selectedDays.length;

  void startSelection(DateTime day) {
    _isRangeMode = true;
    _rangeStart = day;
    _rangeEnd = null;
    
    final normalized = DateUtils.dateOnly(day);
    _selectedDays = {normalized};
    
    HapticFeedback.selectionClick();
    notifyListeners(); 
  }

  bool handleDayTap(DateTime day) {
    if (!_isRangeMode) {
      return true; 
    }

    if (_rangeEnd == null) {
      if (day.isBefore(_rangeStart!)) {
        _rangeEnd = _rangeStart;
        _rangeStart = day;
      } else {
        _rangeEnd = day;
      }
      _calculateDaysInRange();
    } else {
      final normalized = DateUtils.dateOnly(day);
      if (_selectedDays.contains(normalized)) {
        _selectedDays.remove(normalized);
      } else {
        _selectedDays.add(normalized);
      }
    }
    
    notifyListeners(); // ¡Actualizar UI!
    return false;
  }

  void _calculateDaysInRange() {
    if (_rangeStart == null || _rangeEnd == null) return;

    final newSet = <DateTime>{};
    DateTime current = DateUtils.dateOnly(_rangeStart!);
    final end = DateUtils.dateOnly(_rangeEnd!);

    while (current.isBefore(end) || DateUtils.isSameDay(current, end)) {
      newSet.add(current);
      current = current.add(const Duration(days: 1));
    }
    
    _selectedDays = newSet;
    notifyListeners();
  }

  void clearSelection() {
    _isRangeMode = false;
    _rangeStart = null;
    _rangeEnd = null;
    _selectedDays.clear();
    notifyListeners();
  }
}