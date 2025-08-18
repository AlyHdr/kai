import 'package:flutter/material.dart';

class WeekProgressBar extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const WeekProgressBar({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final startOfWeek = today.subtract(
      Duration(days: today.weekday - 1),
    ); // Monday
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (index) {
        final dayDate = startOfWeek.add(Duration(days: index));
        final isSelected =
            selectedDate.day == dayDate.day &&
            selectedDate.month == dayDate.month &&
            selectedDate.year == dayDate.year;

        return GestureDetector(
          onTap: () => onDateSelected(dayDate),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Colors.greenAccent : Colors.transparent,
                  border: isSelected ? null : Border.all(color: Colors.grey),
                ),
                alignment: Alignment.center,
                child: Text(
                  days[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dayDate.day.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.greenAccent : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
