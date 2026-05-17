import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'core/theme.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_state.dart';
import 'screens/landing_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/otp_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/productos_screen.dart';
import 'screens/categorias_screen.dart';
import 'screens/movimientos_screen.dart';
import 'screens/historial_screen.dart';
import 'screens/reportes_screen.dart';
import 'screens/usuarios_screen.dart';
import 'screens/auditoria_screen.dart';
import 'core/go_router_refresh_stream.dart';

const String routeLanding = '/';
const String routeLogin = '/login';
const String routeRegister = '/register';
const String routeOtp = '/otp';
const String routeResetPassword = '/reset-password';
const String routeDashboard = '/dashboard';
const String routeProductos = '/productos';
const String routeCategorias = '/categorias';
const String routeMovimientos = '/movimientos';
const String routeHistorial = '/historial';
const String routeReportes = '/reportes';
const String routeUsuarios = '/usuarios';
const String routeAuditoria = '/auditoria';

GoRouter _createRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: routeLanding,
    refreshListenable:
        GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final isAuthenticated = authBloc.state is AuthAuthenticated;
      final isPublicRoute = [routeLanding, routeLogin, routeRegister,
          routeOtp, routeResetPassword].contains(state.matchedLocation);

      if (!isAuthenticated && !isPublicRoute) {
        return routeLogin;
      }

      if ((state.matchedLocation == routeLanding ||
          state.matchedLocation == routeLogin) && isAuthenticated) {
        return routeDashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: routeLanding,
        builder: (context, state) => const LandingScreen(),
      ),
      GoRoute(
        path: routeLogin,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: routeRegister,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: routeOtp,
        builder: (context, state) => const OTPScreen(),
      ),
      GoRoute(
        path: routeResetPassword,
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: routeDashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: routeProductos,
        builder: (context, state) => const ProductosScreen(),
      ),
      GoRoute(
        path: routeCategorias,
        builder: (context, state) => const CategoriasScreen(),
      ),
      GoRoute(
        path: routeMovimientos,
        builder: (context, state) => const MovimientosScreen(),
      ),
      GoRoute(
        path: routeHistorial,
        builder: (context, state) => const HistorialScreen(),
      ),
      GoRoute(
        path: routeReportes,
        builder: (context, state) => const ReportesScreen(),
      ),
      GoRoute(
        path: routeUsuarios,
        builder: (context, state) => const UsuariosScreen(),
      ),
      GoRoute(
        path: routeAuditoria,
        builder: (context, state) => const AuditoriaScreen(),
      ),
    ],
  );
}

class InvProApp extends StatelessWidget {
  const InvProApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authBloc = GetIt.I<AuthBloc>();

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
      ],
      child: MaterialApp.router(
        title: 'InvPro',
        theme: AppTheme.lightTheme,
        routerConfig: _createRouter(authBloc),
      ),
    );
  }
}
