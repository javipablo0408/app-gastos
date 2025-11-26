# Implementación de Nuevas Funcionalidades

Este documento describe todas las funcionalidades que se están implementando.

## Estado de Implementación

### ✅ Completado
1. **Base de datos actualizada** - Tablas agregadas: Tags, ExpenseTags, IncomeTags, SharedExpenses, Bills
2. **Entidad Bill** - Creada en `lib/domain/entities/bill.dart`
3. **Servicio RecurringExecutorService** - Para ejecutar transacciones recurrentes
4. **BackgroundTaskService** - Para workmanager

### 🔄 En Progreso
1. Ejecutor automático de gastos/ingresos recurrentes
2. UI completa para etiquetas/tags
3. UI de gastos compartidos
4. Exportación a CSV/JSON
5. Sistema de facturas con recordatorios
6. Análisis de deudas
7. Proyecciones financieras
8. Comparación de períodos mejorada
9. Widgets para home screen
10. Sugerencias inteligentes
11. Personalización del dashboard

## Archivos Necesarios

### Servicios a Crear
- `lib/data/services/tags_service.dart`
- `lib/data/services/bills_service.dart`
- `lib/data/services/shared_expenses_service.dart`
- `lib/data/services/export_service.dart` (CSV/JSON)
- `lib/data/services/intelligent_suggestions_service.dart`
- `lib/data/services/financial_projection_service.dart`
- `lib/data/services/debt_analysis_service.dart`

### ViewModels a Crear
- `lib/presentation/viewmodels/tags_viewmodel.dart`
- `lib/presentation/viewmodels/bills_viewmodel.dart`
- `lib/presentation/viewmodels/shared_expenses_viewmodel.dart`
- `lib/presentation/viewmodels/financial_projection_viewmodel.dart`
- `lib/presentation/viewmodels/debt_analysis_viewmodel.dart`
- `lib/presentation/viewmodels/dashboard_customization_viewmodel.dart`

### Páginas UI a Crear
- `lib/presentation/pages/tags_page.dart`
- `lib/presentation/pages/bills_page.dart`
- `lib/presentation/pages/shared_expenses_page.dart`
- `lib/presentation/pages/financial_projection_page.dart`
- `lib/presentation/pages/debt_analysis_page.dart`

### Modelos a Crear
- `lib/data/models/tag_model.dart`
- `lib/data/models/bill_model.dart`
- `lib/data/models/shared_expense_model.dart`

## Próximos Pasos

1. Crear modelos de datos para Tags, Bills, SharedExpenses
2. Agregar métodos CRUD en DatabaseService
3. Crear servicios
4. Crear ViewModels
5. Crear páginas UI
6. Agregar rutas al router
7. Integrar workmanager en main.dart
8. Agregar providers

