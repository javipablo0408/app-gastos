# 🪟 Instrucciones para Build en Windows

## ⚡ Inicio Rápido

### Si tienes Flutter instalado:

1. **Abre PowerShell o CMD en esta carpeta**

2. **Ejecuta el script automático:**
   ```bash
   .\run_windows.bat
   ```
   
   O para compilar release:
   ```bash
   .\build_windows.bat
   ```

### Si NO tienes Flutter instalado:

1. **Instala Flutter:**
   - Descarga desde: https://docs.flutter.dev/get-started/install/windows
   - Extrae en `C:\src\flutter` (o donde prefieras)
   - Agrega `C:\src\flutter\bin` al PATH del sistema

2. **Instala Visual Studio 2022:**
   - Descarga desde: https://visualstudio.microsoft.com/
   - Durante la instalación, selecciona:
     - ✅ Desktop development with C++
     - ✅ Windows 10/11 SDK

3. **Verifica la instalación:**
   ```bash
   flutter doctor
   ```

4. **Habilita Windows Desktop:**
   ```bash
   flutter config --enable-windows-desktop
   ```

5. **Ejecuta el build:**
   ```bash
   .\run_windows.bat
   ```

## 📋 Pasos Manuales (Si prefieres hacerlo paso a paso)

### 1. Obtener dependencias
```bash
flutter pub get
```

### 2. Generar código (Drift, Riverpod)
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Ejecutar en modo desarrollo
```bash
flutter run -d windows
```

### 4. Compilar release (ejecutable)
```bash
flutter build windows --release
```

El ejecutable estará en: `build\windows\runner\Release\app_contabilidad.exe`

## 🔍 Verificar que Flutter está instalado

Abre PowerShell y ejecuta:
```bash
flutter --version
```

Si no funciona, Flutter no está en el PATH.

## 🐛 Problemas Comunes

### "Flutter no se reconoce como comando"
- Flutter no está instalado o no está en el PATH
- Solución: Instala Flutter y agrégalo al PATH

### "Windows desktop development not available"
```bash
flutter config --enable-windows-desktop
flutter doctor
```

### "Visual Studio not found"
- Instala Visual Studio 2022 con componentes de C++

### "build_runner failed"
```bash
flutter clean
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

## ✅ Checklist antes de compilar

- [ ] Flutter instalado y en PATH
- [ ] Visual Studio 2022 instalado
- [ ] Windows Desktop habilitado (`flutter config --enable-windows-desktop`)
- [ ] Dependencias obtenidas (`flutter pub get`)
- [ ] Código generado (`build_runner`)

## 🎯 Resultado Esperado

Después de compilar exitosamente:
- ✅ La aplicación se abre en una ventana de Windows
- ✅ Puedes ver el dashboard
- ✅ Puedes crear gastos e ingresos
- ✅ Todas las funcionalidades están disponibles

## 📦 Distribuir la App

Para compartir la aplicación compilada:
1. Ve a `build\windows\runner\Release\`
2. Copia toda la carpeta
3. Comprime en ZIP
4. Comparte el ZIP

**Importante:** Incluye todos los archivos `.dll` y la carpeta `data\`

## 🚀 Comandos Útiles

```bash
# Ver dispositivos disponibles
flutter devices

# Limpiar build anterior
flutter clean

# Ver información detallada
flutter doctor -v

# Ejecutar con hot reload (desarrollo)
flutter run -d windows

# Build release
flutter build windows --release
```

¡Listo para compilar! 🎉


