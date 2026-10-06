import 'package:flutter_test/flutter_test.dart';

import 'package:gym_pro/domain/entities/private_training_session.dart';
import 'package:gym_pro/domain/entities/private_training_schedule.dart';
import 'package:gym_pro/domain/entities/trainer_trainee.dart';
import 'package:gym_pro/data/models/private_training_session_model.dart';
import 'package:gym_pro/data/models/private_training_schedule_model.dart';
import 'package:gym_pro/data/models/trainer_trainee_model.dart';
import 'package:gym_pro/core/constants/enums.dart';
import 'package:gym_pro/core/utils/day_of_week_helper.dart';

void main() {
  group('PrivateTrainingSession Entity', () {
    test('creates instance with all fields', () {
      final session = PrivateTrainingSession(
        id: 1,
        slotId: 10,
        trainerTraineeId: 5,
        sessionDate: DateTime(2024, 1, 15, 14, 30),
        status: PrivateSessionStatus.scheduled,
        recordedBy: 'user-123',
        createdAt: DateTime(2024, 1, 10),
        trainerName: 'أحمد محمد',
        traineeName: 'سارة أحمد',
      );

      expect(session.id, 1);
      expect(session.slotId, 10);
      expect(session.trainerTraineeId, 5);
      expect(session.sessionDate, DateTime(2024, 1, 15, 14, 30));
      expect(session.status, PrivateSessionStatus.scheduled);
      expect(session.recordedBy, 'user-123');
      expect(session.trainerName, 'أحمد محمد');
      expect(session.traineeName, 'سارة أحمد');
    });

    test('props includes all fields for equality', () {
      final session1 = PrivateTrainingSession(
        id: 1,
        trainerTraineeId: 5,
        sessionDate: DateTime(2024, 1, 15),
        status: PrivateSessionStatus.scheduled,
        recordedBy: 'user-123',
        createdAt: DateTime(2024, 1, 10),
        trainerName: 'أحمد',
        traineeName: 'سارة',
      );

      final session2 = PrivateTrainingSession(
        id: 1,
        trainerTraineeId: 5,
        sessionDate: DateTime(2024, 1, 15),
        status: PrivateSessionStatus.scheduled,
        recordedBy: 'user-123',
        createdAt: DateTime(2024, 1, 10),
        trainerName: 'أحمد',
        traineeName: 'سارة',
      );

      expect(session1, equals(session2));
      expect(session1.props, session2.props);
    });
  });

  group('PrivateTrainingSessionModel', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'id': 1,
        'slot_id': 10,
        'trainer_trainee_id': 5,
        'session_date': '2024-01-15T14:30:00.000Z',
        'status': 'scheduled',
        'recorded_by': 'user-123',
        'created_at': '2024-01-10T10:00:00.000Z',
        'trainer': {'name': 'أحمد محمد'},
        'trainee': {'name': 'سارة أحمد'},
      };

      final model = PrivateTrainingSessionModel.fromJson(json);

      expect(model.id, 1);
      expect(model.slotId, 10);
      expect(model.trainerTraineeId, 5);
      expect(model.sessionDate, DateTime.parse('2024-01-15T14:30:00.000Z'));
      expect(model.status, PrivateSessionStatus.scheduled);
      expect(model.recordedBy, 'user-123');
      expect(model.trainerName, 'أحمد محمد');
      expect(model.traineeName, 'سارة أحمد');
    });

    test('fromJson handles cancelled status', () {
      final json = {
        'id': 2,
        'trainer_trainee_id': 5,
        'session_date': '2024-01-15T14:30:00.000Z',
        'status': 'cancelled',
        'recorded_by': 'user-123',
        'created_at': '2024-01-10T10:00:00.000Z',
      };

      final model = PrivateTrainingSessionModel.fromJson(json);
      expect(model.status, PrivateSessionStatus.cancelled);
    });

    test('fromJson handles completed status', () {
      final json = {
        'id': 3,
        'trainer_trainee_id': 5,
        'session_date': '2024-01-15T14:30:00.000Z',
        'status': 'completed',
        'recorded_by': 'user-123',
        'created_at': '2024-01-10T10:00:00.000Z',
      };

      final model = PrivateTrainingSessionModel.fromJson(json);
      expect(model.status, PrivateSessionStatus.completed);
    });

    test('fromJson handles missing trainer/trainee names', () {
      final json = {
        'id': 4,
        'trainer_trainee_id': 5,
        'session_date': '2024-01-15T14:30:00.000Z',
        'status': 'scheduled',
        'recorded_by': 'user-123',
        'created_at': '2024-01-10T10:00:00.000Z',
        'trainer': null,
        'trainee': null,
      };

      final model = PrivateTrainingSessionModel.fromJson(json);
      expect(model.trainerName, isNull);
      expect(model.traineeName, isNull);
    });

    test('toJson serializes all fields', () {
      final model = PrivateTrainingSessionModel(
        id: 1,
        slotId: 10,
        trainerTraineeId: 5,
        sessionDate: DateTime(2024, 1, 15, 14, 30),
        status: PrivateSessionStatus.scheduled,
        recordedBy: 'user-123',
        createdAt: DateTime(2024, 1, 10),
        trainerName: 'أحمد',
        traineeName: 'سارة',
      );

      final json = model.toJson();

      expect(json['id'], 1);
      expect(json['slot_id'], 10);
      expect(json['trainer_trainee_id'], 5);
      expect(json['session_date'], '2024-01-15T14:30:00.000');
      expect(json['status'], 'scheduled');
      expect(json['recorded_by'], 'user-123');
      expect(json['created_at'], '2024-01-10T00:00:00.000');
      expect(json['trainer_name'], 'أحمد');
      expect(json['trainee_name'], 'سارة');
    });

    test('toInsertJson excludes id and created_at', () {
      final model = PrivateTrainingSessionModel(
        id: 1,
        trainerTraineeId: 5,
        sessionDate: DateTime(2024, 1, 15, 14, 30),
        status: PrivateSessionStatus.scheduled,
        recordedBy: 'user-123',
        createdAt: DateTime(2024, 1, 10),
      );

      final json = model.toInsertJson();

      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('created_at'), isFalse);
      expect(json['trainer_trainee_id'], 5);
    });

    test('fromEntity and toEntity roundtrip', () {
      final entity = PrivateTrainingSession(
        id: 1,
        trainerTraineeId: 5,
        sessionDate: DateTime(2024, 1, 15, 14, 30),
        status: PrivateSessionStatus.scheduled,
        recordedBy: 'user-123',
        createdAt: DateTime(2024, 1, 10),
        trainerName: 'أحمد',
        traineeName: 'سارة',
      );

      final model = PrivateTrainingSessionModel.fromEntity(entity);
      final backToEntity = model.toEntity();

      expect(backToEntity, equals(entity));
    });
  });

  group('PrivateTrainingSchedule Entity', () {
    test('creates instance with all fields', () {
      final schedule = PrivateTrainingSchedule(
        id: 1,
        trainerTraineeId: 5,
        dayOfWeek: 1,
        startTime: '14:00',
        endTime: '15:00',
        isActive: true,
        createdBy: 'user-123',
        createdAt: DateTime(2024, 1, 10),
        trainerName: 'أحمد محمد',
        traineeName: 'سارة أحمد',
      );

      expect(schedule.id, 1);
      expect(schedule.dayOfWeek, 1);
      expect(schedule.startTime, '14:00');
      expect(schedule.endTime, '15:00');
      expect(schedule.isActive, true);
      expect(schedule.trainerName, 'أحمد محمد');
      expect(schedule.traineeName, 'سارة أحمد');
    });
  });

  group('PrivateTrainingScheduleModel', () {
    test('fromJson parses all fields with names', () {
      final json = {
        'id': 1,
        'trainer_trainee_id': 5,
        'day_of_week': 1,
        'start_time': '14:00:00',
        'end_time': '15:00:00',
        'is_active': true,
        'created_by': 'user-123',
        'created_at': '2024-01-10T10:00:00.000Z',
        'trainer': {'name': 'أحمد محمد'},
        'trainee': {'name': 'سارة أحمد'},
      };

      final model = PrivateTrainingScheduleModel.fromJson(json);

      expect(model.id, 1);
      expect(model.dayOfWeek, 1);
      expect(model.startTime, '14:00:00');
      expect(model.endTime, '15:00:00');
      expect(model.isActive, true);
      expect(model.trainerName, 'أحمد محمد');
      expect(model.traineeName, 'سارة أحمد');
    });

    test('fromJson handles missing names', () {
      final json = {
        'id': 2,
        'trainer_trainee_id': 5,
        'day_of_week': 2,
        'start_time': '10:00:00',
        'end_time': '11:00:00',
        'is_active': true,
        'created_by': 'user-123',
        'created_at': '2024-01-10T10:00:00.000Z',
      };

      final model = PrivateTrainingScheduleModel.fromJson(json);
      expect(model.trainerName, isNull);
      expect(model.traineeName, isNull);
    });

    test('toJson serializes correctly', () {
      final model = PrivateTrainingScheduleModel(
        id: 1,
        trainerTraineeId: 5,
        dayOfWeek: 1,
        startTime: '14:00:00',
        endTime: '15:00:00',
        isActive: true,
        createdBy: 'user-123',
        createdAt: DateTime(2024, 1, 10),
        trainerName: 'أحمد',
        traineeName: 'سارة',
      );

      final json = model.toJson();

      expect(json['id'], 1);
      expect(json['trainer_trainee_id'], 5);
      expect(json['day_of_week'], 1);
      expect(json['start_time'], '14:00:00');
      expect(json['end_time'], '15:00:00');
      expect(json['is_active'], true);
      expect(json['trainer_name'], 'أحمد');
      expect(json['trainee_name'], 'سارة');
    });

    test('toInsertJson excludes id and created_at', () {
      final model = PrivateTrainingScheduleModel(
        id: 1,
        trainerTraineeId: 5,
        dayOfWeek: 1,
        startTime: '14:00:00',
        endTime: '15:00:00',
        isActive: true,
        createdBy: 'user-123',
        createdAt: DateTime(2024, 1, 10),
      );

      final json = model.toInsertJson();

      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('created_at'), isFalse);
      expect(json['trainer_trainee_id'], 5);
      expect(json['day_of_week'], 1);
    });
  });

  group('TrainerTrainee Entity', () {
    test('creates instance with names', () {
      final relation = TrainerTrainee(
        id: 1,
        trainerId: 'trainer-123',
        traineeId: 'trainee-456',
        status: TrainerTraineeStatus.active,
        assignedAt: DateTime(2024, 1, 1),
        assignedBy: 'admin-1',
        trainerName: 'أحمد محمد',
        traineeName: 'سارة أحمد',
      );

      expect(relation.id, 1);
      expect(relation.trainerId, 'trainer-123');
      expect(relation.traineeId, 'trainee-456');
      expect(relation.status, TrainerTraineeStatus.active);
      expect(relation.trainerName, 'أحمد محمد');
      expect(relation.traineeName, 'سارة أحمد');
    });
  });

  group('TrainerTraineeModel', () {
    test('fromJson parses names from nested objects', () {
      final json = {
        'id': 1,
        'trainer_id': 'trainer-123',
        'trainee_id': 'trainee-456',
        'status': 'active',
        'assigned_at': '2024-01-01T10:00:00.000Z',
        'assigned_by': 'admin-1',
        'trainer': {'name': 'أحمد محمد'},
        'trainee': {'name': 'سارة أحمد'},
      };

      final model = TrainerTraineeModel.fromJson(json);

      expect(model.id, 1);
      expect(model.trainerId, 'trainer-123');
      expect(model.traineeId, 'trainee-456');
      expect(model.status, TrainerTraineeStatus.active);
      expect(model.trainerName, 'أحمد محمد');
      expect(model.traineeName, 'سارة أحمد');
    });

    test('fromJson handles missing names', () {
      final json = {
        'id': 2,
        'trainer_id': 'trainer-123',
        'trainee_id': 'trainee-456',
        'status': 'active',
        'assigned_at': '2024-01-01T10:00:00.000Z',
        'assigned_by': 'admin-1',
      };

      final model = TrainerTraineeModel.fromJson(json);
      expect(model.trainerName, isNull);
      expect(model.traineeName, isNull);
    });

    test('fromEntity and toEntity roundtrip with names', () {
      final entity = TrainerTrainee(
        id: 1,
        trainerId: 'trainer-123',
        traineeId: 'trainee-456',
        status: TrainerTraineeStatus.active,
        assignedAt: DateTime(2024, 1, 1),
        assignedBy: 'admin-1',
        trainerName: 'أحمد',
        traineeName: 'سارة',
      );

      final model = TrainerTraineeModel.fromEntity(entity);
      final backToEntity = model.toEntity();

      expect(backToEntity, equals(entity));
      expect(backToEntity.trainerName, 'أحمد');
      expect(backToEntity.traineeName, 'سارة');
    });
  });

  group('DayOfWeekHelper', () {
    test('returns correct Arabic names for 0-6', () {
      expect(DayOfWeekHelper.name(0), 'السبت');
      expect(DayOfWeekHelper.name(1), 'الأحد');
      expect(DayOfWeekHelper.name(2), 'الاثنين');
      expect(DayOfWeekHelper.name(3), 'الثلاثاء');
      expect(DayOfWeekHelper.name(4), 'الأربعاء');
      expect(DayOfWeekHelper.name(5), 'الخميس');
      expect(DayOfWeekHelper.name(6), 'الجمعة');
    });

    test('legacy 1-7 support', () {
      expect(DayOfWeekHelper.name(7), 'السبت');
    });

    test('entries has 7 items', () {
      expect(DayOfWeekHelper.entries.length, 7);
    });
  });

  group('AccessType Enum', () {
    test('nameAr returns correct Arabic', () {
      expect(AccessType.mixed.nameAr, 'مختلط');
      expect(AccessType.women.nameAr, 'سيدات');
      expect(AccessType.maintenance.nameAr, 'صيانة');
      expect(AccessType.courseReserved.nameAr, 'محجوز لدورة');
    });

    test('toDbString returns correct string', () {
      expect(AccessType.mixed.toDbString(), 'mixed');
      expect(AccessType.women.toDbString(), 'women');
      expect(AccessType.maintenance.toDbString(), 'maintenance');
      expect(AccessType.courseReserved.toDbString(), 'course_reserved');
    });
  });

  group('UserRole Enum', () {
    test('nameAr returns correct Arabic', () {
      expect(UserRole.admin.nameAr, 'أدمن');
      expect(UserRole.reception.nameAr, 'استقبال');
      expect(UserRole.trainer.nameAr, 'مدرب');
      expect(UserRole.trainee.nameAr, 'متدرب');
    });
  });
}