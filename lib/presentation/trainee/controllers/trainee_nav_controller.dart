import 'package:flutter_riverpod/flutter_riverpod.dart';
enum TraineeSection { dashboard, qr, bookings, program, diet, trainer }
final traineeNavProvider = StateProvider<TraineeSection>((ref) => TraineeSection.dashboard);
