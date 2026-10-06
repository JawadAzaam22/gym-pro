import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/providers.dart';
import '../../../../domain/entities/session.dart';

class SessionsController extends AsyncNotifier<List<Session>> {
  @override
  Future<List<Session>> build() async {
    final res = await ref.read(sessionRepositoryProvider).getSessions();
    return res.fold((l) => throw Exception(l.message), (r) => r);
  }

  Future<bool> create(Session s) async {
    final res = await ref.read(sessionRepositoryProvider).createSession(s);
    return res.fold((l) {
      state = AsyncValue.error(l.message, StackTrace.current);
      return false;
    }, (r) {
      state = AsyncValue.data([...state.value ?? [], r]);
      return true;
    });
  }

  Future<bool> editSession(Session s) async {
    final res = await ref.read(sessionRepositoryProvider).updateSession(s);
    return res.fold((l) {
      state = AsyncValue.error(l.message, StackTrace.current);
      return false;
    }, (r) {
      final list = state.value ?? [];
      state = AsyncValue.data([for (final e in list) e.id == r.id ? r : e]);
      return true;
    });
  }

  Future<void> cancel(int id) async {
    final res = await ref.read(sessionRepositoryProvider).cancelSession(id);
    res.fold(
      (l) => state = AsyncValue.error(l.message, StackTrace.current),
      (_) => state = AsyncValue.data((state.value ?? []).where((e) => e.id != id).toList()),
    );
  }

  Future<bool> delete(int id) async {
    final res = await ref.read(sessionRepositoryProvider).deleteSession(id);
    return res.fold(
      (l) {
        state = AsyncValue.error(l.message, StackTrace.current);
        return false;
      },
      (_) {
        state = AsyncValue.data((state.value ?? []).where((e) => e.id != id).toList());
        return true;
      },
    );
  }
}

final sessionsControllerProvider = AsyncNotifierProvider<SessionsController, List<Session>>(SessionsController.new);
