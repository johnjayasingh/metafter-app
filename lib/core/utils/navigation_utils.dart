import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/will_creation/presentation/bloc/will_bloc.dart';
import '../../features/will_creation/presentation/bloc/will_event.dart';
import '../routes/app_router.dart';

/// Navigation utilities for the app
class NavigationUtils {
  /// Navigate to home screen and refresh the wills list
  /// Use this instead of context.go('/home') when exiting from will creation flow
  static void goToHomeAndRefresh(BuildContext context) {
    // Trigger refresh before navigating
    context.read<WillBloc>().add(const RefreshWillsEvent());
    // Navigate to home
    context.go(AppRouter.home);
  }
}
