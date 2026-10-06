/// Generates time slots for a schedule grid.
///
/// Returns a list of (startTime, endTime) pairs in "HH:mm:ss" format,
/// evenly spaced from [openTime] to [closeTime] with [slotMinutes] duration.
List<TimeSlot> generateTimeSlots({
  required String openTime,
  required String closeTime,
  required int slotMinutes,
}) {
  final startMinutes = _parseMinutes(openTime);
  final endMinutes = _parseMinutes(closeTime);

  if (endMinutes <= startMinutes || slotMinutes <= 0) return [];

  final slots = <TimeSlot>[];
  int current = startMinutes;

  while (current + slotMinutes <= endMinutes) {
    final sH = current ~/ 60;
    final sM = current % 60;
    final eH = (current + slotMinutes) ~/ 60;
    final eM = (current + slotMinutes) % 60;

    slots.add(TimeSlot(
      start:
          '${sH.toString().padLeft(2, '0')}:${sM.toString().padLeft(2, '0')}:00',
      end:
          '${eH.toString().padLeft(2, '0')}:${eM.toString().padLeft(2, '0')}:00',
    ));

    current += slotMinutes;
  }

  return slots;
}

/// Parses "HH:mm:ss" or "HH:mm" to total minutes since midnight.
int _parseMinutes(String time) {
  final parts = time.split(':');
  if (parts.length < 2) return 0;
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

class TimeSlot {
  final String start;
  final String end;

  const TimeSlot({required this.start, required this.end});
}
