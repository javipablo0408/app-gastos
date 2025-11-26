# Arquitectura de la Aplicación

## 🏗️ Clean Architecture

La aplicación sigue los principios de Clean Architecture con separación clara de responsabilidades:

### Capas

#### 1. **Domain Layer** (Lógica de Negocio)
- **Entities**: Objetos de dominio puros (Category, Expense, Income, Budget, ChangeLog)
- **Repositories**: Interfaces que definen contratos de acceso a datos
- **Use Cases**: Lógica de negocio específica (opcional, puede estar en ViewModels)

#### 2. **Data Layer** (Acceso a Datos)
- **Models**: Modelos de datos (Drift tables, mappers)
- **DataSources**: 
  - Local: DatabaseService, FileService
  - Remote: SyncService (OneDrive)
- **Repositories**: Implementaciones concretas de los repositorios

#### 3. **Presentation Layer** (UI)
- **Pages**: Pantallas de la aplicación
- **ViewModels**: Lógica de presentación con Riverpod/StateNotifier
- **Widgets**: Componentes reutilizables de UI

#### 4. **Core Layer** (Infraestructura)
- **Errors**: Manejo de errores (Failures)
- **Utils**: Utilidades (logger, constants, result)
- **Theme**: Configuración de temas
- **Providers**: Configuración de inyección de dependencias

## 🔄 Flujo de Datos

```
UI (Widget) 
  → ViewModel (StateNotifier)
    → Repository/Service
      → DataSource (Local/Remote)
        → Database/API
```

## 📊 Patrón MVVM

### ViewModel (StateNotifier)
- Gestiona el estado de la UI
- Expone métodos para acciones del usuario
- Se comunica con servicios/repositorios
- Actualiza el estado reactivamente

### Estado
- Clases inmutables que representan el estado
- Método `copyWith` para actualizaciones
- Estados: Loading, Success, Error, Empty

## 🔐 Seguridad

### Base de Datos
- Semáforos (Mutex) para acceso concurrente
- Transacciones para operaciones críticas
- Soft delete para mantener historial

### Sincronización
- OAuth2 PKCE para autenticación segura
- Tokens con refresh automático
- Merge bidireccional con resolución de conflictos
- Hash/timestamps para detección de cambios

## 🗄️ Base de Datos

### Tablas

1. **Categories**
   - id, name, icon, color, type
   - createdAt, updatedAt, isDeleted, syncId

2. **Expenses**
   - id, amount, description, categoryId
   - date, receiptImagePath
   - createdAt, updatedAt, isDeleted, syncId, version

3. **Incomes**
   - id, amount, description, categoryId
   - date
   - createdAt, updatedAt, isDeleted, syncId, version

4. **Budgets**
   - id, categoryId, amount
   - startDate, endDate
   - createdAt, updatedAt, isDeleted, syncId

5. **ChangeLogs**
   - id, type, entityType, entityId, action
   - timestamp, synced, data (JSON)

### Índices
- `idx_expenses_date`: Optimiza búsquedas por fecha
- `idx_expenses_category`: Optimiza filtros por categoría
- `idx_changelog_synced`: Optimiza sincronización

## 🔄 Sincronización Bidireccional

### Estrategia Offline-First
1. Todos los cambios se guardan localmente primero
2. Se registran en ChangeLog
3. Sincronización periódica o manual
4. Merge inteligente basado en timestamps y versiones

### Proceso de Sincronización
1. **Descargar** datos remotos de OneDrive
2. **Cargar** datos locales de SQLite
3. **Merge** bidireccional:
   - Última actualización gana (por defecto)
   - Resolución de conflictos por versión
   - Preservar cambios locales no sincronizados
4. **Subir** cambios pendientes
5. **Marcar** logs como sincronizados

## 📱 Gestión de Archivos

### Imágenes de Tickets
- Almacenamiento local en directorio de la app
- Compresión automática (JPEG, calidad 85%)
- Redimensionamiento si > 1MB
- Limpieza automática de archivos antiguos (>30 días)

## 📄 Generación de Reportes

### PDF
- Usa el paquete `pdf`
- Incluye resumen, gastos e ingresos
- Formato profesional con tablas

### Excel
- Usa el paquete `excel`
- Múltiples hojas (Resumen, Gastos, Ingresos)
- Formato estructurado para análisis

## 🎨 Sistema de Diseño

### Temas
- Tema claro y oscuro
- ColorScheme basado en Material 3
- Tipografía: Google Fonts (Inter)

### Componentes Base
- LoadingWidget
- ErrorWidget
- Cards, Buttons, Inputs (Material 3)

## 🧪 Testing (Pendiente)

### Unit Tests
- ViewModels
- Servicios
- Utilidades

### Integration Tests
- Flujos completos
- Sincronización
- Base de datos

### Widget Tests
- Componentes UI
- Páginas principales

