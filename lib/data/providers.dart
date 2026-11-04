import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/supabase_client.dart';
import 'datasources/supabase_auth_datasource.dart';
import 'datasources/supabase_user_datasource.dart';
import 'datasources/supabase_hall_datasource.dart';
import 'datasources/supabase_membership_datasource.dart';
import 'datasources/supabase_session_datasource.dart';
import 'datasources/supabase_booking_datasource.dart';
import 'datasources/supabase_attendance_datasource.dart';
import 'datasources/supabase_program_datasource.dart';
import 'datasources/supabase_diet_datasource.dart';
import 'datasources/supabase_payment_datasource.dart';
import 'datasources/supabase_report_datasource.dart';
import 'datasources/supabase_notification_datasource.dart';
import 'repositories_impl/auth_repository_impl.dart';
import 'repositories_impl/user_repository_impl.dart';
import 'repositories_impl/hall_repository_impl.dart';
import 'repositories_impl/membership_repository_impl.dart';
import 'repositories_impl/session_repository_impl.dart';
import 'repositories_impl/booking_repository_impl.dart';
import 'repositories_impl/attendance_repository_impl.dart';
import 'repositories_impl/program_repository_impl.dart';
import 'repositories_impl/diet_repository_impl.dart';
import 'repositories_impl/payment_repository_impl.dart';
import 'repositories_impl/report_repository_impl.dart';
import 'repositories_impl/notification_repository_impl.dart';
import '../domain/repositories/i_notification_repository.dart';
import '../domain/usecases/notification_use_cases.dart';
import '../domain/usecases/membership_use_cases.dart';
import '../domain/usecases/trainer_assignment_use_cases.dart';
import '../domain/usecases/attendance_use_cases.dart';
import '../domain/usecases/qr_code_use_cases.dart';
import '../domain/usecases/booking_use_cases.dart';
import '../domain/usecases/program_content_use_cases.dart';
import '../domain/usecases/diet_content_use_cases.dart';
import '../domain/usecases/attendance/get_attendance_history_uc.dart';
import '../domain/usecases/attendance/record_attendance_uc.dart';
import '../domain/usecases/auth/get_current_user_uc.dart';
import '../domain/usecases/auth/login_uc.dart';
import '../domain/usecases/auth/logout_uc.dart';
import '../domain/usecases/diet/create_diet_plan_uc.dart';
import '../domain/usecases/diet/get_trainee_diets_uc.dart';
import '../domain/usecases/membership/check_membership_status_uc.dart';
import '../domain/usecases/membership/create_membership_uc.dart';
import '../domain/usecases/membership/renew_membership_uc.dart';
import '../domain/usecases/payment/get_payments_uc.dart';
import '../domain/usecases/payment/record_payment_uc.dart';
import '../domain/usecases/program/create_training_program_uc.dart';
import '../domain/usecases/program/get_trainee_programs_uc.dart';
import '../domain/usecases/report/generate_report_uc.dart';
import '../domain/usecases/session/book_session_uc.dart';
import '../domain/usecases/session/cancel_booking_uc.dart';
import '../domain/usecases/session/create_session_uc.dart';
import '../domain/usecases/user_use_cases.dart';
import '../domain/usecases/hall_use_cases.dart';
import '../domain/usecases/session_use_cases.dart';
import '../domain/usecases/payment_use_cases.dart';
import '../domain/usecases/report_use_cases.dart';
import '../domain/usecases/repository_query_use_cases.dart';

// Datasources
final authDatasourceProvider =
    Provider((ref) => SupabaseAuthDatasource(ref.read(supabaseClientProvider)));
final userDatasourceProvider =
    Provider((ref) => SupabaseUserDatasource(ref.read(supabaseClientProvider)));
final hallDatasourceProvider =
    Provider((ref) => SupabaseHallDatasource(ref.read(supabaseClientProvider)));
final membershipDatasourceProvider = Provider(
    (ref) => SupabaseMembershipDatasource(ref.read(supabaseClientProvider)));
final sessionDatasourceProvider = Provider(
    (ref) => SupabaseSessionDatasource(ref.read(supabaseClientProvider)));
final bookingDatasourceProvider = Provider(
    (ref) => SupabaseBookingDatasource(ref.read(supabaseClientProvider)));
final attendanceDatasourceProvider = Provider(
    (ref) => SupabaseAttendanceDatasource(ref.read(supabaseClientProvider)));
final programDatasourceProvider = Provider(
    (ref) => SupabaseProgramDatasource(ref.read(supabaseClientProvider)));
final dietDatasourceProvider =
    Provider((ref) => SupabaseDietDatasource(ref.read(supabaseClientProvider)));
final paymentDatasourceProvider = Provider(
    (ref) => SupabasePaymentDatasource(ref.read(supabaseClientProvider)));
final reportDatasourceProvider = Provider(
    (ref) => SupabaseReportDatasource(ref.read(supabaseClientProvider)));
final notificationDatasourceProvider = Provider(
    (ref) => SupabaseNotificationDatasource(ref.read(supabaseClientProvider)));

// Repositories
final authRepositoryProvider =
    Provider((ref) => AuthRepositoryImpl(ref.read(authDatasourceProvider)));
final userRepositoryProvider =
    Provider((ref) => UserRepositoryImpl(ref.read(userDatasourceProvider)));
final hallRepositoryProvider =
    Provider((ref) => HallRepositoryImpl(ref.read(hallDatasourceProvider)));
final membershipRepositoryProvider = Provider(
    (ref) => MembershipRepositoryImpl(ref.read(membershipDatasourceProvider)));
final sessionRepositoryProvider = Provider(
    (ref) => SessionRepositoryImpl(ref.read(sessionDatasourceProvider)));
final bookingRepositoryProvider = Provider(
    (ref) => BookingRepositoryImpl(ref.read(bookingDatasourceProvider)));
final attendanceRepositoryProvider = Provider(
    (ref) => AttendanceRepositoryImpl(ref.read(attendanceDatasourceProvider)));
final programRepositoryProvider = Provider(
    (ref) => ProgramRepositoryImpl(ref.read(programDatasourceProvider)));
final dietRepositoryProvider =
    Provider((ref) => DietRepositoryImpl(ref.read(dietDatasourceProvider)));
final paymentRepositoryProvider = Provider(
    (ref) => PaymentRepositoryImpl(ref.read(paymentDatasourceProvider)));
final reportRepositoryProvider =
    Provider((ref) => ReportRepositoryImpl(ref.read(reportDatasourceProvider)));
final notificationRepositoryProvider = Provider<INotificationRepository>(
    (ref) =>
        NotificationRepositoryImpl(ref.read(notificationDatasourceProvider)));

// Notification use cases
final getMyNotificationsProvider = Provider<GetMyNotifications>(
    (ref) => GetMyNotifications(ref.read(notificationRepositoryProvider)));
final watchMyNotificationsProvider = Provider<WatchMyNotifications>(
    (ref) => WatchMyNotifications(ref.read(notificationRepositoryProvider)));
final markNotificationAsReadProvider = Provider<MarkNotificationAsRead>(
    (ref) => MarkNotificationAsRead(ref.read(notificationRepositoryProvider)));
final markAllNotificationsAsReadProvider = Provider<MarkAllNotificationsAsRead>(
    (ref) =>
        MarkAllNotificationsAsRead(ref.read(notificationRepositoryProvider)));
final deleteNotificationProvider = Provider<DeleteNotification>(
    (ref) => DeleteNotification(ref.read(notificationRepositoryProvider)));

// Membership use cases
final createMembershipProvider = Provider<CreateMembership>(
    (ref) => CreateMembership(ref.read(membershipRepositoryProvider)));
final renewMembershipProvider = Provider<RenewMembership>(
    (ref) => RenewMembership(ref.read(membershipRepositoryProvider)));
final deleteMembershipProvider = Provider<DeleteMembership>(
    (ref) => DeleteMembership(ref.read(membershipRepositoryProvider)));
final membershipUseCasesProvider = Provider<MembershipQueries>(
    (ref) => MembershipQueries(ref.read(membershipRepositoryProvider)));

// Trainer assignment use cases
final assignTrainerProvider = Provider<AssignTrainer>(
    (ref) => AssignTrainer(ref.read(bookingRepositoryProvider)));
final changeTrainerAssignmentProvider = Provider<ChangeTrainerAssignment>(
    (ref) => ChangeTrainerAssignment(ref.read(bookingRepositoryProvider)));
final deactivateTrainerAssignmentProvider =
    Provider<DeactivateTrainerAssignment>((ref) =>
        DeactivateTrainerAssignment(ref.read(bookingRepositoryProvider)));

// Attendance and QR use cases
final recordAttendanceProvider = Provider<RecordAttendance>(
    (ref) => RecordAttendance(ref.read(attendanceRepositoryProvider)));
final getAttendanceForTraineeProvider = Provider<GetAttendanceForTrainee>(
    (ref) => GetAttendanceForTrainee(ref.read(attendanceRepositoryProvider)));
final getAllAttendanceProvider = Provider<GetAllAttendance>(
    (ref) => GetAllAttendance(ref.read(attendanceRepositoryProvider)));
final checkInByQrCodeProvider = Provider<CheckInByQrCode>(
    (ref) => CheckInByQrCode(ref.read(attendanceRepositoryProvider)));
final resolveTraineeQrCodeProvider = Provider<ResolveTraineeQrCode>(
    (ref) => ResolveTraineeQrCode(ref.read(userRepositoryProvider)));
final issueTraineeQrCodeProvider = Provider<IssueTraineeQrCode>(
    (ref) => IssueTraineeQrCode(ref.read(userRepositoryProvider)));
final getTrainerTraineesProvider = Provider<GetTrainerTrainees>(
    (ref) => GetTrainerTrainees(ref.read(bookingRepositoryProvider)));
final getPrivateTrainingSessionsProvider = Provider<GetPrivateTrainingSessions>(
    (ref) => GetPrivateTrainingSessions(ref.read(bookingRepositoryProvider)));
final getPrivateScheduleForRelationProvider =
    Provider<GetPrivateScheduleForRelation>((ref) =>
        GetPrivateScheduleForRelation(ref.read(bookingRepositoryProvider)));
final getPrivateScheduleForTrainerProvider =
    Provider<GetPrivateScheduleForTrainer>((ref) =>
        GetPrivateScheduleForTrainer(ref.read(bookingRepositoryProvider)));
final getPrivateScheduleForTraineeProvider =
    Provider<GetPrivateScheduleForTrainee>((ref) =>
        GetPrivateScheduleForTrainee(ref.read(bookingRepositoryProvider)));
final deletePrivateScheduleSlotProvider = Provider<DeletePrivateScheduleSlot>(
    (ref) => DeletePrivateScheduleSlot(ref.read(bookingRepositoryProvider)));
final programContentUseCasesProvider = Provider<ProgramContentUseCases>(
    (ref) => ProgramContentUseCases(ref.read(programRepositoryProvider)));
final dietContentUseCasesProvider = Provider<DietContentUseCases>(
    (ref) => DietContentUseCases(ref.read(dietRepositoryProvider)));
final userUseCasesProvider = Provider<UserUseCases>(
    (ref) => UserUseCases(ref.read(userRepositoryProvider)));
final hallUseCasesProvider = Provider<HallUseCases>(
    (ref) => HallUseCases(ref.read(hallRepositoryProvider)));
final sessionUseCasesProvider = Provider<SessionUseCases>(
    (ref) => SessionUseCases(ref.read(sessionRepositoryProvider)));
final paymentUseCasesProvider = Provider<PaymentUseCases>(
    (ref) => PaymentUseCases(ref.read(paymentRepositoryProvider)));
final reportUseCasesProvider = Provider<ReportUseCases>(
    (ref) => ReportUseCases(ref.read(reportRepositoryProvider)));
final attendanceUseCasesProvider = Provider<AttendanceUseCases>(
    (ref) => AttendanceUseCases(ref.read(attendanceRepositoryProvider)));
final bookingUseCasesProvider = Provider<BookingUseCases>(
    (ref) => BookingUseCases(ref.read(bookingRepositoryProvider)));
final programUseCasesProvider = Provider<ProgramUseCases>(
    (ref) => ProgramUseCases(ref.read(programRepositoryProvider)));
final dietUseCasesProvider = Provider<DietUseCases>(
    (ref) => DietUseCases(ref.read(dietRepositoryProvider)));

// Existing feature use cases
final getCurrentUserUcProvider = Provider<GetCurrentUserUc>(
    (ref) => GetCurrentUserUc(ref.read(authRepositoryProvider)));
final loginUcProvider =
    Provider<LoginUc>((ref) => LoginUc(ref.read(authRepositoryProvider)));
final logoutUcProvider =
    Provider<LogoutUc>((ref) => LogoutUc(ref.read(authRepositoryProvider)));
final recordAttendanceUcProvider = Provider<RecordAttendanceUc>(
    (ref) => RecordAttendanceUc(ref.read(attendanceRepositoryProvider)));
final getAttendanceHistoryUcProvider = Provider<GetAttendanceHistoryUc>(
    (ref) => GetAttendanceHistoryUc(ref.read(attendanceRepositoryProvider)));
final checkMembershipStatusUcProvider = Provider<CheckMembershipStatusUc>(
    (ref) => CheckMembershipStatusUc(ref.read(membershipRepositoryProvider)));
final createMembershipUcProvider = Provider<CreateMembershipUc>(
    (ref) => CreateMembershipUc(ref.read(membershipRepositoryProvider)));
final renewMembershipUcProvider = Provider<RenewMembershipUc>(
    (ref) => RenewMembershipUc(ref.read(membershipRepositoryProvider)));
final createDietPlanUcProvider = Provider<CreateDietPlanUc>(
    (ref) => CreateDietPlanUc(ref.read(dietRepositoryProvider)));
final getTraineeDietsUcProvider = Provider<GetTraineeDietsUc>(
    (ref) => GetTraineeDietsUc(ref.read(dietRepositoryProvider)));
final createTrainingProgramUcProvider = Provider<CreateTrainingProgramUc>(
    (ref) => CreateTrainingProgramUc(ref.read(programRepositoryProvider)));
final getTraineeProgramsUcProvider = Provider<GetTraineeProgramsUc>(
    (ref) => GetTraineeProgramsUc(ref.read(programRepositoryProvider)));
final getPaymentsUcProvider = Provider<GetPaymentsUc>(
    (ref) => GetPaymentsUc(ref.read(paymentRepositoryProvider)));
final recordPaymentUcProvider = Provider<RecordPaymentUc>(
    (ref) => RecordPaymentUc(ref.read(paymentRepositoryProvider)));
final generateReportUcProvider = Provider<GenerateReportUc>(
    (ref) => GenerateReportUc(ref.read(reportRepositoryProvider)));
final bookSessionUcProvider = Provider<BookSessionUc>(
    (ref) => BookSessionUc(ref.read(bookingRepositoryProvider)));
final cancelBookingUcProvider = Provider<CancelBookingUc>(
    (ref) => CancelBookingUc(ref.read(bookingRepositoryProvider)));
final createSessionUcProvider = Provider<CreateSessionUc>(
    (ref) => CreateSessionUc(ref.read(sessionRepositoryProvider)));
