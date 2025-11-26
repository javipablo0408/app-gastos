# Guía de Configuración - App Contabilidad

## 📋 Resumen del Proyecto

Se ha creado una aplicación Flutter completa para control de gastos con las siguientes características:

### ✅ Completado

1. **Arquitectura Clean Architecture**
   - Separación en capas: Core, Data, Domain, Presentation
   - Patrón MVVM con Riverpod/StateNotifier
   - Inyección de dependencias con Riverpod

2. **Base de Datos SQLite con Drift**
   - Tablas: Categories, Expenses, Incomes, Budgets, ChangeLogs
   - Migraciones configuradas
   - Semáforos (Mutex) para acceso concurrente seguro
   - Índices optimizados

3. **Servicios Principales**
   - `DatabaseService`: Gestión completa de BD con semáforos
   - `FileService`: Manejo de imágenes (galería/cámara), compresión
   - `ChangeLogService`: Registro de cambios para sincronización
   - `SyncService`: Sincronización bidireccional con OneDrive (Microsoft Graph REST)
   - `ReportService`: Generación de PDFs y Excel

4. **Entidades y Modelos**
   - Category, Expense, Income, Budget, ChangeLog
   - Mappers entre entidades y modelos de BD
   - Validaciones y tipos seguros

5. **UI/UX Base**
   - Sistema de temas claro/oscuro
   - Tipografías Google Fonts (Inter)
   - Widgets reutilizables (Loading, Error)
   - Página principal básica

6. **ViewModels**
   - ExpensesViewModel
   - CategoriesViewModel
   - Estados reactivos con Riverpod

## 🚀 Pasos para Configurar

### 1. Instalar Dependencias

```bash
flutter pub get
```

### 2. Generar Código (Drift y otros)

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Configurar OneDrive (Microsoft Graph)

1. Ve a [Azure Portal](https://portal.azure.com)
2. Crea una nueva aplicación de Azure AD
3. Configura los redirect URIs:
   - Android: `msauth://com.yourapp.contabilidad/auth`
   - iOS: `msauth://com.yourapp.contabilidad/auth`
4. Obtén el Client ID
5. Actualiza `lib/core/utils/constants.dart`:
   ```dart
   static const String clientId = 'TU_CLIENT_ID_AQUI';
   ```

### 4. Configurar Permisos (Android)

En `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.CAMERA"/>
```

### 5. Configurar Permisos (iOS)

En `ios/Runner/Info.plist`:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Necesitamos acceso a tus fotos para adjuntar tickets</string>
<key>NSCameraUsageDescription</key>
<string>Necesitamos acceso a la cámara para tomar fotos de tickets</string>
```

## 📁 Estructura del Proyecto

```
lib/
├── core/
│   ├── errors/          # Failures y manejo de errores
│   ├── providers/        # Providers de Riverpod
│   ├── theme/           # Temas claro/oscuro
│   ├── utils/           # Utilidades (logger, constants, result)
│   └── widgets/         # Widgets reutilizables
├── data/
│   ├── datasources/
│   │   ├── local/       # DatabaseService, FileService, etc.
│   │   └── remote/      # SyncService (OneDrive)
│   └── models/          # Modelos de Drift y mappers
├── domain/
│   └── entities/        # Entidades de dominio
└── presentation/
    ├── pages/           # Pantallas
    ├── viewmodels/      # ViewModels con Riverpod
    └── widgets/         # Widgets específicos de UI
```

## 🔧 Próximos Pasos Sugeridos

### UI/UX Completa
1. Dashboard con gráficos (fl_chart)
2. Pantalla de lista de gastos/ingresos
3. Formulario de creación/edición
4. Pantalla de categorías
5. Pantalla de presupuestos
6. Pantalla de configuración
7. Pantalla de sincronización

### Funcionalidades Adicionales
1. Navegación con go_router
2. Búsqueda y filtros avanzados
3. Notificaciones de presupuestos
4. Exportación mejorada
5. Estadísticas y análisis
6. Modo offline mejorado

### Optimizaciones
1. Tests unitarios
2. Tests de integración
3. Optimización de queries
4. Caché de imágenes
5. Lazy loading

## 📝 Notas Importantes

- La sincronización con OneDrive requiere autenticación OAuth2 PKCE
- Los archivos de sincronización se guardan en formato JSON
- Las imágenes se comprimen automáticamente al guardar
- La base de datos usa soft delete (isDeleted)
- Los cambios se registran en ChangeLog para sincronización

## 🐛 Solución de Problemas

### Error: "database.g.dart not found"
Ejecuta: `flutter pub run build_runner build --delete-conflicting-outputs`

### Error: "OneDrive authentication failed"
Verifica que el Client ID esté correcto en constants.dart

### Error: "Permission denied"
Verifica los permisos en AndroidManifest.xml o Info.plist

## 📚 Recursos

- [Drift Documentation](https://drift.simonbinder.eu/)
- [Riverpod Documentation](https://riverpod.dev/)
- [Microsoft Graph API](https://docs.microsoft.com/en-us/graph/overview)
- [Flutter Documentation](https://flutter.dev/docs)

