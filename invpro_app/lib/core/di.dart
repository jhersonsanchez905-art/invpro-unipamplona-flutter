import 'package:get_it/get_it.dart';
import '../core/api_client.dart';
import '../repositories/auth_repository.dart';
import '../repositories/categoria_repository.dart';
import '../repositories/producto_repository.dart';
import '../repositories/movimiento_repository.dart';
import '../repositories/dashboard_repository.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/categoria/categoria_bloc.dart';
import '../blocs/producto/producto_bloc.dart';
import '../blocs/movimiento/movimiento_bloc.dart';
import '../blocs/dashboard/dashboard_bloc.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // Core
  getIt.registerSingleton<ApiClient>(ApiClient()..initialize());

  // Repositories — LazySingletons
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<CategoriaRepository>(
    () => CategoriaRepository(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<ProductoRepository>(
    () => ProductoRepository(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<MovimientoRepository>(
    () => MovimientoRepository(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<DashboardRepository>(
    () => DashboardRepository(apiClient: getIt<ApiClient>()),
  );

  // BLoCs — AuthBloc as singleton, others as factories
  getIt.registerSingleton<AuthBloc>(
    AuthBloc(repository: getIt<AuthRepository>()),
  );

  getIt.registerFactory<CategoriaBloc>(
    () => CategoriaBloc(repository: getIt<CategoriaRepository>()),
  );
  getIt.registerFactory<ProductoBloc>(
    () => ProductoBloc(repository: getIt<ProductoRepository>()),
  );
  getIt.registerFactory<MovimientoBloc>(
    () => MovimientoBloc(repository: getIt<MovimientoRepository>()),
  );
  getIt.registerFactory<DashboardBloc>(
    () => DashboardBloc(repository: getIt<DashboardRepository>()),
  );
}
