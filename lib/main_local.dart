import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';
import 'core/network/api_client.dart';
import 'core/storage/secure_storage_service.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/will_creation/data/repositories/will_repository_impl.dart';
import 'features/will_creation/presentation/bloc/will_bloc.dart';
import 'features/digital_vault/data/repositories/vault_repository_impl.dart';
import 'features/digital_vault/presentation/cubit/vault_cubit.dart';
import 'core/config/environment_config.dart';

void main() {
  // Set LOCAL environment with debug pre-fill enabled
  EnvironmentConfig.setEnvironment(Environment.local);
  
  // Initialize API client with LOCAL base URL
  ApiClient().initialize();
  
  // Debug logging
  print('🟣 LOCAL Environment initialized');
  print('🌐 API Base URL: ${EnvironmentConfig.baseUrl}');
  print('✍️ Debug Pre-fill: ${EnvironmentConfig.useDebugPrefill}');

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const DigitalWillApp());
}

class DigitalWillApp extends StatelessWidget {
  const DigitalWillApp({super.key});

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
          )..add(const AuthCheckRequested()),
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
          title: 'Will Cloud LOCAL',
          debugShowCheckedModeBanner: true,
          theme: AppTheme.lightTheme,
          routerConfig: AppRouter.router,
        ),
      ),
    );
  }
}
