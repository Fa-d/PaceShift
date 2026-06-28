import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/ai_repository.dart';
import '../../data/api/api_client.dart';
import '../../data/api/auth_models.dart';
import '../../data/api/auth_repository.dart';
import '../../data/api/cloud_sync_repository.dart';
import '../../data/api/genui_repository.dart';
import 'providers.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider)),
);

final cloudSyncRepositoryProvider = Provider<CloudSyncRepository>(
  (ref) => CloudSyncRepository(
      ref.watch(databaseProvider), ref.watch(apiClientProvider)),
);

final aiRepositoryProvider = Provider<AiRepository>(
  (ref) => AiRepository(ref.watch(apiClientProvider)),
);

final genUiRepositoryProvider = Provider<GenUiRepository>(
  (ref) => GenUiRepository(ref.watch(apiClientProvider)),
);

/// The signed-in user (null when signed out). Loads any existing session on
/// cold start; sign-in/up/out mutate it.
class AuthController extends AsyncNotifier<AuthUser?> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Future<AuthUser?> build() => _repo.currentUser();

  Future<void> register(String email, String password,
      {String? displayName}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => _repo.register(email, password, displayName: displayName));
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.login(email, password));
  }

  Future<void> oauth(String provider, String idToken) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.oauth(provider, idToken));
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AsyncData(null);
  }

  Future<void> deleteAccount() async {
    await _repo.deleteAccount();
    state = const AsyncData(null);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthUser?>(AuthController.new);

/// Convenience: the current user or null (ignores loading/error).
final currentUserProvider = Provider<AuthUser?>(
  (ref) => ref.watch(authControllerProvider).value,
);

/// Whether the user is signed in.
final isSignedInProvider =
    Provider<bool>((ref) => ref.watch(currentUserProvider) != null);
