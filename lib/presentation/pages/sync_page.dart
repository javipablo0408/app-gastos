import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_contabilidad/core/providers/providers.dart';
import 'package:app_contabilidad/data/datasources/remote/sync_service.dart';
import 'package:app_contabilidad/core/widgets/loading_widget.dart';

/// Página de sincronización
class SyncPage extends ConsumerStatefulWidget {
  const SyncPage({super.key});

  @override
  ConsumerState<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends ConsumerState<SyncPage> {
  bool _isSyncing = false;
  String? _syncStatus;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final syncService = ref.read(syncServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sincronización'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Estado de conexión
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isSyncing
                            ? Icons.sync
                            : _syncStatus != null
                                ? Icons.check_circle
                                : Icons.cloud_off,
                        color: _isSyncing
                            ? Colors.blue
                            : _syncStatus != null
                                ? Colors.green
                                : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isSyncing
                            ? 'Sincronizando...'
                            : _syncStatus != null
                                ? 'Sincronizado'
                                : 'No sincronizado',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  if (_syncStatus != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _syncStatus!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.red,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Botón de sincronización
          ElevatedButton.icon(
            onPressed: _isSyncing ? null : () => _sync(syncService),
            icon: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            label: Text(_isSyncing ? 'Sincronizando...' : 'Sincronizar ahora'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 16),

          // Botón de autenticación
          FutureBuilder<bool>(
            future: syncService.isAuthenticated(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }

              final isAuthenticated = snapshot.data!;

              if (isAuthenticated) {
                return OutlinedButton.icon(
                  onPressed: () => _logout(syncService),
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar sesión'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                );
              } else {
                return ElevatedButton.icon(
                  onPressed: () => _authenticate(syncService),
                  icon: const Icon(Icons.login),
                  label: const Text('Iniciar sesión con OneDrive'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                );
              }
            },
          ),

          const SizedBox(height: 24),

          // Información
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'La sincronización permite mantener tus datos respaldados en OneDrive y acceder a ellos desde múltiples dispositivos.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sync(SyncService syncService) async {
    setState(() {
      _isSyncing = true;
      _error = null;
      _syncStatus = null;
    });

    final result = await syncService.sync();

    setState(() {
      _isSyncing = false;
    });

    result.fold(
      (failure) {
        setState(() {
          _error = failure.message;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${failure.message}'),
            backgroundColor: Colors.red,
          ),
        );
      },
      (_) {
        setState(() {
          _syncStatus = 'Última sincronización: ${DateTime.now().toString()}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sincronización completada'),
            backgroundColor: Colors.green,
          ),
        );
      },
    );
  }

  Future<void> _authenticate(SyncService syncService) async {
    // TODO: Implementar autenticación OAuth2 con navegador
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Autenticación: Implementar navegador OAuth2'),
      ),
    );
  }

  Future<void> _logout(SyncService syncService) async {
    await syncService.logout();
    setState(() {
      _syncStatus = null;
      _error = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sesión cerrada')),
    );
  }
}


