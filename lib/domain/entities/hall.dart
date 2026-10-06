import "package:equatable/equatable.dart";

class Hall extends Equatable {
  final int id;
  final String name;
  final int capacity;
  final bool isActive;
  final String openTime;
  final String closeTime;
  final int defaultSlotMinutes;

  const Hall({
    required this.id,
    required this.name,
    required this.capacity,
    required this.isActive,
    this.openTime = '08:00:00',
    this.closeTime = '22:00:00',
    this.defaultSlotMinutes = 60,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        capacity,
        isActive,
        openTime,
        closeTime,
        defaultSlotMinutes,
      ];
}
