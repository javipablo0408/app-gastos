import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_contabilidad/core/providers/providers.dart';
import 'package:app_contabilidad/core/providers/theme_provider.dart';
import 'package:app_contabilidad/data/datasources/local/report_service.dart';
import 'package:app_contabilidad/data/datasources/remote/sync_service.dart';
import 'package:app_contabilidad/data/services/export_service.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:app_contabilidad/presentation/widgets/bottom_navigation.dart';
import 'package:app_contabilidad/core/router/app_router.dart';

/// Página de configuración
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncService = ref.read(syncServiceProvider);
    final reportService = ref.read(reportServiceProvider);
    final themeMode = ref.watch(themeModeProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: ListView(
        children: [
          // Funcionalidades avanzadas
          _buildSectionHeader(context, 'Funcionalidades Avanzadas'),
          ListTile(
            leading: const Icon(Icons.label),
            title: const Text('Etiquetas'),
            subtitle: const Text('Gestionar etiquetas para organizar transacciones'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/tags'),
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Facturas'),
            subtitle: const Text('Gestionar facturas y recordatorios de pago'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/bills'),
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Gastos Compartidos'),
            subtitle: const Text('Dividir gastos entre varias personas'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/shared-expenses'),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: const Text('Análisis de Deudas'),
            subtitle: const Text('Ver quién debe a quién'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/debt-analysis'),
          ),
          ListTile(
            leading: const Icon(Icons.compare_arrows),
            title: const Text('Comparación de Períodos'),
            subtitle: const Text('Comparar gastos e ingresos entre períodos'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/period-comparison'),
          ),

          const Divider(),

          // Funcionalidades avanzadas (originales)
          _buildSectionHeader(context, 'Funcionalidades Avanzadas'),
          ListTile(
            leading: const Icon(Icons.repeat, color: Colors.red),
            title: const Text('Gastos Recurrentes'),
            subtitle: const Text('Configurar gastos automáticos'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/recurring-expenses'),
          ),
          ListTile(
            leading: const Icon(Icons.repeat, color: Colors.green),
            title: const Text('Ingresos Recurrentes'),
            subtitle: const Text('Configurar ingresos automáticos'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/recurring-incomes'),
          ),
          ListTile(
            leading: const Icon(Icons.savings),
            title: const Text('Objetivos de Ahorro'),
            subtitle: const Text('Metas y progreso'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/savings-goals'),
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Estadísticas Avanzadas'),
            subtitle: const Text('Análisis detallado'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/statistics'),
          ),

          const Divider(),

          // Sincronización
          _buildSectionHeader(context, 'Sincronización'),
          ListTile(
            leading: const Icon(Icons.cloud_sync),
            title: const Text('Sincronizar con OneDrive'),
            subtitle: const Text('Sincroniza tus datos con la nube'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/sync'),
          ),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Sincronización automática'),
            subtitle: const Text('Activar sincronización periódica'),
            trailing: Switch(
              value: false, // TODO: Implementar estado
              onChanged: (value) {},
            ),
          ),

          const Divider(),

          // Exportación
          _buildSectionHeader(context, 'Exportación'),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf),
            title: const Text('Exportar a PDF'),
            subtitle: const Text('Generar reporte en formato PDF'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _exportToPDF(context, reportService),
          ),
          ListTile(
            leading: const Icon(Icons.table_chart),
            title: const Text('Exportar a Excel'),
            subtitle: const Text('Generar reporte en formato Excel'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _exportToExcel(context, reportService),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Exportar a CSV'),
            subtitle: const Text('Generar reporte en formato CSV'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _exportToCSV(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Exportar a JSON'),
            subtitle: const Text('Generar reporte en formato JSON'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _exportToJSON(context, ref),
          ),

          const Divider(),

          // Apariencia
          _buildSectionHeader(context, 'Apariencia'),
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('Modo oscuro'),
            subtitle: Text(
              themeMode == ThemeMode.dark
                  ? 'Tema oscuro activo'
                  : themeMode == ThemeMode.light
                      ? 'Tema claro activo'
                      : 'Siguiendo tema del sistema',
            ),
            trailing: Switch(
              value: themeMode == ThemeMode.dark,
              onChanged: (value) {
                themeNotifier.setThemeMode(
                  value ? ThemeMode.dark : ThemeMode.light,
                );
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.brightness_auto),
            title: const Text('Seguir tema del sistema'),
            trailing: Switch(
              value: themeMode == ThemeMode.system,
              onChanged: (value) {
                themeNotifier.setThemeMode(
                  value ? ThemeMode.system : ThemeMode.light,
                );
              },
            ),
          ),

          const Divider(),

          // Información
          _buildSectionHeader(context, 'Información'),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Versión'),
            subtitle: const Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Acerca de'),
            subtitle: const Text('SynkBudget - Control de gastos y presupuestos'),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigation(currentIndex: 4),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Future<void> _exportToPDF(
    BuildContext context,
    ReportService reportService,
  ) async {
    final dateRange = await _selectDateRange(context);
    if (dateRange == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final result = await reportService.generatePdfReport(
      startDate: dateRange.$1,
      endDate: dateRange.$2,
    );

    if (context.mounted) {
      Navigator.pop(context);
    }

    result.fold(
      (failure) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.message)),
          );
        }
      },
      (filePath) async {
        if (context.mounted) {
          final dateRange = await _selectDateRange(context);
          if (dateRange == null) return;
          
          await Share.shareXFiles(
            [XFile(filePath)],
            text: 'Reporte PDF',
          );
        }
      },
    );
  }

  Future<void> _exportToExcel(
    BuildContext context,
    ReportService reportService,
  ) async {
    final dateRange = await _selectDateRange(context);
    if (dateRange == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final result = await reportService.generateExcelReport(
      startDate: dateRange.$1,
      endDate: dateRange.$2,
    );

    if (context.mounted) {
      Navigator.pop(context);
    }

    result.fold(
      (failure) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.message)),
          );
        }
      },
      (filePath) async {
        if (context.mounted) {
          await Share.shareXFiles(
            [XFile(filePath)],
            text: 'Reporte Excel',
          );
        }
      },
    );
  }

  Future<void> _exportToCSV(BuildContext context, WidgetRef ref) async {
    final dateRange = await _selectDateRange(context);
    if (dateRange == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final exportService = ref.read(exportServiceProvider);
    final result = await exportService.exportToCsv(
      startDate: dateRange.$1,
      endDate: dateRange.$2,
    );

    if (context.mounted) {
      Navigator.pop(context);
    }

    result.fold(
      (failure) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.message)),
          );
        }
      },
      (filePath) async {
        if (context.mounted) {
          await Share.shareXFiles(
            [XFile(filePath)],
            text: 'Reporte CSV',
          );
        }
      },
    );
  }

  Future<void> _exportToJSON(BuildContext context, WidgetRef ref) async {
    final dateRange = await _selectDateRange(context);
    if (dateRange == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final exportService = ref.read(exportServiceProvider);
    final result = await exportService.exportToJson(
      startDate: dateRange.$1,
      endDate: dateRange.$2,
    );

    if (context.mounted) {
      Navigator.pop(context);
    }

    result.fold(
      (failure) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.message)),
          );
        }
      },
      (filePath) async {
        if (context.mounted) {
          await Share.shareXFiles(
            [XFile(filePath)],
            text: 'Reporte JSON',
          );
        }
      },
    );
  }

  Future<(DateTime, DateTime)?> _selectDateRange(BuildContext context) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    return showDialog<(DateTime, DateTime)?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar período'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Este mes'),
              onTap: () {
                Navigator.pop(
                  context,
                  (startOfMonth, now),
                );
              },
            ),
            ListTile(
              title: const Text('Mes pasado'),
              onTap: () {
                final lastMonth = DateTime(now.year, now.month - 1, 1);
                final lastMonthEnd = DateTime(now.year, now.month, 0);
                Navigator.pop(
                  context,
                  (lastMonth, lastMonthEnd),
                );
              },
            ),
            ListTile(
              title: const Text('Personalizado'),
              onTap: () async {
                Navigator.pop(context);
                final customRange = await _selectCustomDateRange(context);
                if (customRange != null) {
                  Navigator.pop(context, customRange);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<MapEntry<DateTime, DateTime>?> _selectCustomDateRange(
    BuildContext context,
  ) async {
    DateTime? startDate;
    DateTime? endDate;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rango personalizado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Fecha inicio'),
              subtitle: Text(
                startDate != null
                    ? DateFormat('dd/MM/yyyy').format(startDate!)
                    : 'Seleccionar',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  startDate = date;
                }
              },
            ),
            ListTile(
              title: const Text('Fecha fin'),
              subtitle: Text(
                endDate != null
                    ? DateFormat('dd/MM/yyyy').format(endDate!)
                    : 'Seleccionar',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: endDate ?? DateTime.now(),
                  firstDate: startDate ?? DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  endDate = date;
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (startDate != null && endDate != null) {
                Navigator.pop(context);
              }
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );

    if (startDate != null && endDate != null) {
      return MapEntry(startDate!, endDate!);
    }
    return null;
  }
}

