# Configuración de Workmanager

Workmanager está configurado para ejecutar transacciones recurrentes automáticamente. Para que funcione correctamente, se requiere configuración adicional según la plataforma.

## ✅ Ya Configurado

- ✅ `BackgroundTaskService` creado
- ✅ Callback `callbackDispatcher` implementado
- ✅ Inicialización en `main.dart`
- ✅ Tarea periódica programada

## 📱 Configuración por Plataforma

### Android

1. **Agregar permisos en `android/app/src/main/AndroidManifest.xml`:**

```xml
<manifest>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.WAKE_LOCK"/>
    
    <application>
        <!-- ... otras configuraciones ... -->
    </application>
</manifest>
```

2. **Para Android 12+ (API 31+), agregar en `android/app/build.gradle`:**

```gradle
android {
    defaultConfig {
        // ... otras configuraciones ...
        minSdkVersion 21
    }
}
```

### iOS

1. **Agregar en `ios/Runner/Info.plist`:**

```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>processing</string>
</array>
```

2. **Agregar en `ios/Runner/AppDelegate.swift` (si existe):**

```swift
import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### Windows

Workmanager no está soportado en Windows. La ejecución automática de recurrentes se puede hacer de otras formas:

1. **Ejecutar al iniciar la app** (ya implementado en `main.dart`)
2. **Usar un servicio de Windows** (requiere código nativo)
3. **Ejecutar manualmente desde la UI** (opción disponible)

## 🔧 Verificación

Para verificar que workmanager está funcionando:

1. Ejecuta la app en Android/iOS
2. Revisa los logs para ver mensajes de `BackgroundTaskService`
3. Las transacciones recurrentes se ejecutarán automáticamente cada 24 horas

## 📝 Notas

- En Windows, la ejecución automática no está disponible con workmanager
- La app ejecutará recurrentes al iniciar en todas las plataformas
- Los permisos de notificaciones también son necesarios para recordatorios

