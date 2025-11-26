# 🪟 Guía de Build para Windows

## Requisitos Previos

1. **Flutter SDK** instalado y configurado
   - Descargar desde: https://flutter.dev/docs/get-started/install/windows
   - Agregar Flutter al PATH del sistema

2. **Visual Studio** (para compilación nativa)
   - Visual Studio 2022 con componentes:
     - Desktop development with C++
     - Windows 10/11 SDK

3. **Git** (opcional pero recomendado)

## 🚀 Opción 1: Build Automático (Recomendado)

### Usar el script batch incluido:

```bash
# Para compilar y generar ejecutable
build_windows.bat

# Para ejecutar directamente (modo desarrollo)
run_windows.bat
```

## 🛠️ Opción 2: Build Manual

### Paso 1: Verificar Flutter
```bash
flutter doctor
```

Asegúrate de que Windows Desktop esté habilitado. Si no lo está:
```bash
flutter config --enable-windows-desktop
```

### Paso 2: Obtener Dependencias
```bash
flutter pub get
```

### Paso 3: Generar Código
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Paso 4: Compilar para Windows (Release)
```bash
flutter build windows --release
```

El ejecutable estará en:
```
build\windows\runner\Release\app_contabilidad.exe
```

### Paso 5: Ejecutar (Modo Desarrollo)
```bash
flutter run -d windows
```

## 📦 Estructura del Build

Después de compilar, encontrarás:

```
build/windows/
├── runner/
│   └── Release/
│       ├── app_contabilidad.exe  ← Ejecutable principal
│       ├── flutter_windows.dll
│       └── data/                 ← Assets y recursos
└── ...
```

## 🔧 Solución de Problemas

### Error: "Flutter no está en el PATH"
1. Descarga Flutter desde https://flutter.dev
2. Extrae en una ubicación (ej: `C:\src\flutter`)
3. Agrega `C:\src\flutter\bin` al PATH del sistema
4. Reinicia la terminal

### Error: "Windows desktop development not available"
```bash
flutter config --enable-windows-desktop
flutter doctor
```

### Error: "Visual Studio not found"
1. Instala Visual Studio 2022
2. Selecciona "Desktop development with C++"
3. Incluye Windows 10/11 SDK

### Error: "build_runner failed"
```bash
flutter clean
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Error: "database.g.dart not found"
Ejecuta el paso 3 (Generar Código) nuevamente.

## 📝 Notas Importantes

- **Primera vez**: El build puede tardar varios minutos
- **Release**: El ejecutable será más grande pero más rápido
- **Debug**: Usa `flutter run -d windows` para desarrollo con hot reload

## 🎯 Comandos Rápidos

```bash
# Desarrollo con hot reload
flutter run -d windows

# Build release
flutter build windows --release

# Limpiar build anterior
flutter clean

# Verificar configuración
flutter doctor -v
```

## ✅ Verificación del Build

Después de compilar, verifica que:
1. El archivo `.exe` existe en `build\windows\runner\Release\`
2. Puedes ejecutarlo haciendo doble clic
3. La aplicación se abre correctamente
4. Las funcionalidades básicas funcionan

## 🚀 Distribución

Para distribuir la aplicación:
1. Copia toda la carpeta `build\windows\runner\Release\`
2. Incluye todos los archivos `.dll` y la carpeta `data\`
3. Comprime en un ZIP o crea un instalador

¡Listo para probar en Windows! 🎉


