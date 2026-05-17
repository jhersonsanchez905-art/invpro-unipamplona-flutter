import 'package:get_it/get_it.dart';
import '../core/api_client.dart';
import '../repositories/auth_repository.dart';
import '../blocs/auth/auth_bloc.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // Core
  getIt.registerSingleton<ApiClient>(ApiClient()..initialize());

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(apiClient: getIt<ApiClient>()),
  );

  // BLoCs — AuthBloc as singleton
  getIt.registerSingleton<AuthBloc>(
    AuthBloc(repository: getIt<AuthRepository>()),
  );
}
