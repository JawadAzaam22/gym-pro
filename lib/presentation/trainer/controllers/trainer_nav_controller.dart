import 'package:flutter_riverpod/flutter_riverpod.dart';
enum TrainerSection { dashboard, trainees, programs, diets, schedule }
final trainerNavProvider = StateProvider<TrainerSection>((ref) => TrainerSection.dashboard);
