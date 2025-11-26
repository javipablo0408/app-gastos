import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_contabilidad/core/theme/app_theme.dart';
import 'package:app_contabilidad/core/router/app_router.dart';
import 'package:app_contabilidad/core/providers/theme_provider.dart';
import 'package:app_contabilidad/core/services/background_task_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar workmanager para tareas en segundo plano
  await BackgroundTaskService.initialize();
  await BackgroundTaskService.scheduleRecurringTransactions();
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'SynkBudget',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}

