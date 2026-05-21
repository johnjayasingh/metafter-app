import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';
import 'core/network/api_client.dart';
import 'core/storage/secure_storage_service.dart';
import 'core/config/environment_config.dart';
import 'core/config/payment_config.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/will_creation/data/repositories/will_repository_impl.dart';
import 'features/will_creation/presentation/bloc/will_bloc.dart';
import 'features/digital_vault/data/repositories/vault_repository_impl.dart';
import 'features/digital_vault/presentation/cubit/vault_cubit.dart';

// Global navigator key for accessing navigation from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set environment to UAT
  EnvironmentConfig.setEnvironment(Environment.uat);
  
  // Initialize API client with UAT environment
  ApiClient().initialize();
  
  // Initialize payment configuration
  await PaymentConfig.initialize();
  
  // Set up session timeout callback
  ApiClient().onSessionTimeout = _handleSessionTimeout;
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const WillcloudApp());
}

void _handleSessionTimeout() {
  print('🚨 _handleSessionTimeout called');
  
  final context = navigatorKey.currentContext;
  if (context == null) {
    print('❌ Navigator context is null');
    return;
  }

  print('✅ Session expired — showing toast and logging out');
  
  // Show a toast message
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
    SnackBar(
      content: const Row(
        children: [
          Icon(Icons.logout, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Session expired. Please sign in again.',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );

  // Clear auth state and navigate to sign in
  try {
    context.read<AuthBloc>().add(const AuthSessionCleared());
  } catch (e) {
    print('❌ Error clearing auth: $e');
  }
  context.go(AppRouter.signIn);
}

class WillcloudApp extends StatelessWidget {
  const WillcloudApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthBloc(
            authRepository: AuthRepositoryImpl(
              apiClient: ApiClient(),
              storage: SecureStorageService(),
            ),
          )..add(const AuthCheckRequested()), // Check auth status on app start
        ),
        BlocProvider(
          create: (context) => WillBloc(
            repository: WillRepositoryImpl(
              apiClient: ApiClient(),
            ),
          ),
        ),
        BlocProvider(
          create: (context) => VaultCubit(
            repository: VaultRepositoryImpl(
              apiClient: ApiClient(),
            ),
          ),
        ),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (previous, current) =>
            previous.status != AuthStatus.unauthenticated &&
            current.status == AuthStatus.unauthenticated,
        listener: (context, state) {
          AppRouter.router.go(AppRouter.signIn);
        },
        child: MaterialApp.router(
          title: 'Will Cloud [UAT]',
          debugShowCheckedModeBanner: true,
          theme: AppTheme.lightTheme,
          routerConfig: AppRouter.router,
        ),
      ),
    );
  }
}
