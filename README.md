# App Contabilidad - Control de Gastos Premium

Aplicación Flutter profesional para control de gastos e ingresos con sincronización bidireccional con OneDrive.

## 🏗️ Arquitectura

- **Clean Architecture** con separación de capas
- **MVVM** con Riverpod/StateNotifier
- **Offline-first** con SQLite (Drift)
- **Sincronización bidireccional** con Microsoft Graph REST API

## 📦 Características

- ✅ Registro de gastos e ingresos
- ✅ Categorías personalizables
- ✅ Presupuestos con alertas
- ✅ Dashboard con gráficos interactivos
- ✅ Adjuntar fotos de tickets
- ✅ Exportación a PDF y Excel
- ✅ Sincronización bidireccional con OneDrive
- ✅ Modo offline completo
- ✅ Tema claro/oscuro
- ✅ Responsive (móvil/tablet/desktop)

## 🚀 Inicio Rápido

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

## 📱 Plataformas Soportadas

- Android
- iOS
- Windows
- Web

## 🔐 Seguridad

- Semáforos (Mutex) para acceso concurrente a BD
- Cifrado opcional de datos sensibles
- Autenticación OAuth2 PKCE para OneDrive

