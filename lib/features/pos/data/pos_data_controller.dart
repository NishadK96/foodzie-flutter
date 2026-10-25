import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import 'pos_api_repository.dart';

final posApiRepositoryProvider = Provider<PosApiRepository>(
  (ref) => PosApiRepository(ref.watch(apiClientProvider)),
);

final posDataControllerProvider =
    AsyncNotifierProvider<PosDataController, PosBootstrap>(
      PosDataController.new,
    );

class PosDataController extends AsyncNotifier<PosBootstrap> {
  @override
  Future<PosBootstrap> build() =>
      ref.read(posApiRepositoryProvider).bootstrap();

  Future<void> refresh() async {
    state = const AsyncLoading<PosBootstrap>();
    state = await AsyncValue.guard(
      () => ref.read(posApiRepositoryProvider).bootstrap(),
    );
  }
}
