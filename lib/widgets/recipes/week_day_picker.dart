import 'package:flutter/material.dart';

class WeekDayPicker extends StatelessWidget {
  const WeekDayPicker({
    super.key,
    required this.days,
    required this.selectedDate,
    required this.isFilled,
    required this.onDateSelected,
  });

  final List<DateTime> days;
  final DateTime selectedDate;
  final bool Function(DateTime date) isFilled;
  final ValueChanged<DateTime> onDateSelected;

  String _initialFor(DateTime date) {
    const initials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return initials[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days.map((date) {
        final isSelected =
            date.year == selectedDate.year &&
            date.month == selectedDate.month &&
            date.day == selectedDate.day;
        final filled = isFilled(date);
        final accentColor = Colors.greenAccent;
        final showAccent = isSelected || filled;
        final textColor = isSelected
            ? Colors.white
            : (filled ? accentColor : Colors.grey);
        final borderColor = filled && !isSelected ? accentColor : Colors.grey;

        return GestureDetector(
          onTap: () => onDateSelected(date),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? accentColor : Colors.transparent,
                      border: Border.all(color: borderColor),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _initialFor(date),
                      style: TextStyle(
                        color: textColor,
                        fontWeight: showAccent
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (filled)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                date.day.toString(),
                style: TextStyle(
                  color: showAccent ? accentColor : Colors.grey,
                  fontWeight: showAccent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
