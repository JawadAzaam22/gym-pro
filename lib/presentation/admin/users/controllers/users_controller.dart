import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/providers.dart';
import '../../../../domain/entities/user.dart';

/// Controller مسؤول عن قائمة المستخدمين (List<User>) - ليس مستخدم واحد.
/// يستخدم AsyncNotifier<List<User>> لذلك state هو List، وليس User مفرد.
/// للوصول لمستخدم واحد استخدم userByIdProvider أو filteredUsersProvider.

class UsersController extends AsyncNotifier<List<User>> {
  @override
  Future<List<User>> build() async {
    final repo = ref.read(userRepositoryProvider);
    // ملاحظة: نجلب هنا كل المستخدمين بمن فيهم الموقوفين (is_active = false)
    // لأن هذه الشاشة هي شاشة إدارة الأعضاء الخاصة بالأدمن. لو استخدمنا
    // getAllUsers() (النشطين فقط) فإن أي عضو يتم "إيقافه/حظره" سيختفي من
    // القائمة فورًا، فيبدو الأمر وكأن الإيقاف قام بحذفه فعليًا.
    final res = await repo.getAllUsersIncludingInactive();
    return res.fold((l) => throw Exception(l.message), (r) => r);
  }

  /// يجلب جميع المستخدمين بما فيهم غير النشطين (للأدمن فقط)
  Future<List<User>> getAllUsersIncludingInactive() async {
    final repo = ref.read(userRepositoryProvider);
    final res = await repo.getAllUsersIncludingInactive();
    return res.fold((l) => throw Exception(l.message), (r) => r);
  }

  /// إنشاء مستخدم جديد - يضيف للـ List الحالية
  Future<bool> createUser(User user, String password) async {
    final repo = ref.read(userRepositoryProvider);
    final res = await repo.createUser(user, password);
    return res.fold(
      (l) {
        state = AsyncValue.error(l.message, StackTrace.current);
        return false;
      },
      (newUser) {
        // state.value هو List<User> - نضيف له العنصر الجديد
        final List<User> current = state.value ?? [];
        state = AsyncValue.data([...current, newUser]);
        return true;
      },
    );
  }

  /// تحديث مستخدم موجود - يستبدل العنصر في الـ List حسب id
  /// ملاحظة: بعد Update على profiles.role يحتاج المستخدم المعني
  /// استدعاء refreshSession() (أو خروج/دخول) ليأخذ الـ JWT الجديد مفعوله.
  Future<bool> updateUser(User user) async {
    final repo = ref.read(userRepositoryProvider);
    final res = await repo.updateUser(user);
    return res.fold(
      (l) {
        state = AsyncValue.error(l.message, StackTrace.current);
        return false;
      },
      (updated) {
        final List<User> list = [...?state.value];
        final idx = list.indexWhere((e) => e.id == updated.id);
        if (idx != -1) list[idx] = updated;
        state = AsyncValue.data(list);
        return true;
      },
    );
  }

  /// تعطيل مستخدم (isActive = false) - يحدث العنصر في الـ List
  Future<bool> deactivate(String id) async {
    return setActive(id, false);
  }

  Future<bool> setActive(String id, bool isActive) async {
    final repo = ref.read(userRepositoryProvider);
    final user = (state.value ?? []).where((item) => item.id == id).firstOrNull;
    if (user == null) return false;
    final res = await repo.updateUser(User(
      id: user.id,
      name: user.name,
      phone: user.phone,
      email: user.email,
      role: user.role,
      gender: user.gender,
      isActive: isActive,
      createdAt: user.createdAt,
    ));
    return res.fold(
      (l) {
        state = AsyncValue.error(l.message, StackTrace.current);
        return false;
      },
      (_) {
        final List<User> list = (state.value ?? <User>[]).map((u) {
          if (u.id == id) {
            return User(
                id: u.id,
                name: u.name,
                phone: u.phone,
                email: u.email,
                role: u.role,
                gender: u.gender,
                isActive: isActive,
                createdAt: u.createdAt);
          }
          return u;
        }).toList();
        state = AsyncValue.data(list);
        return true;
      },
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(userRepositoryProvider);
      // نفس ملاحظة build(): نجلب الجميع بمن فيهم الموقوفين حتى يبقوا ظاهرين
      // في شاشة إدارة الأعضاء بعد الإيقاف/الحظر.
      final res = await repo.getAllUsersIncludingInactive();
      return res.fold((l) => throw Exception(l.message), (r) => r);
    });
  }

  /// حذف مستخدم نهائيًا. cascade=false (افتراضي، آمن): يفشل برسالة واضحة
  /// إن وُجدت سجلات مرتبطة. cascade=true: يؤرشف كل شيء في
  /// deleted_users_archive أولاً (يبقى محفوظًا دائمًا) ثم يحذف سجلات
  /// المستخدم الشخصية ويُفرغ إسناده في السجلات المشتركة (تقارير/حصص/مدفوعات
  /// تخص أشخاصًا آخرين) بدل حذفها، حفاظًا على تاريخ التقارير لبقية المستخدمين.
  Future<bool> deleteUser(String id, {bool cascade = false}) async {
    final repo = ref.read(userRepositoryProvider);
    final res = await repo.deleteUser(id, cascade: cascade);
    return res.fold(
      (l) {
        state = AsyncValue.error(l.message, StackTrace.current);
        return false;
      },
      (_) {
        // إزالة المستخدم من القائمة المحلية
        final List<User> list = (state.value ?? <User>[]).where((u) => u.id != id).toList();
        state = AsyncValue.data(list);
        return true;
      },
    );
  }
}

/// Provider للقائمة الكاملة
final usersControllerProvider =
    AsyncNotifierProvider<UsersController, List<User>>(UsersController.new);

/// Provider لمستخدم واحد حسب id - يسهل الربط مع شاشة التفاصيل/التعديل
final userByIdProvider = Provider.family<User?, String>((ref, id) {
  final users = ref.watch(usersControllerProvider).value ?? [];
  try {
    return users.firstWhere((u) => u.id == id);
  } catch (_) {
    return null;
  }
});

/// تفاصيل مستخدم للتحرير: ينتظر تحميل القائمة أولاً ثم يبحث فيها،
/// ويرجع لجلب فردي من الخادم عند غياب المستخدم عن القائمة.
/// يضمن عمل رابط التعديل بعد تحديث الصفحة (F5) حيث يكون extra == null.
final userDetailProvider =
    FutureProvider.family<User?, String>((ref, id) async {
  final users = await ref.watch(usersControllerProvider.future);
  try {
    return users.firstWhere((u) => u.id == id);
  } catch (_) {
    final res = await ref.read(userRepositoryProvider).getUserById(id);
    return res.fold((l) => throw Exception(l.message), (r) => r);
  }
});

// Search & filter providers
final userSearchQueryProvider = StateProvider<String>((ref) => '');
final userRoleFilterProvider = StateProvider<String>((ref) => 'الكل');

final filteredUsersProvider = Provider<List<User>>((ref) {
  final users = ref.watch(usersControllerProvider).value ?? [];
  final query = ref.watch(userSearchQueryProvider).toLowerCase();
  final roleFilter = ref.watch(userRoleFilterProvider);
  return users.where((u) {
    final matchesQuery = query.isEmpty ||
        u.name.toLowerCase().contains(query) ||
        u.phone.contains(query) ||
        u.email.toLowerCase().contains(query);
    final matchesRole =
        roleFilter == 'الكل' || u.role.name == _roleToEn(roleFilter);
    return matchesQuery && matchesRole;
  }).toList();
});

String _roleToEn(String ar) {
  switch (ar) {
    case 'أدمن':
      return 'admin';
    case 'استقبال':
      return 'reception';
    case 'مدرب':
      return 'trainer';
    case 'متدرب':
      return 'trainee';
    default:
      return ar;
  }
}
