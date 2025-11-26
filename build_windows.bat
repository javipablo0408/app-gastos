@echo off
echo ========================================
echo Build App Contabilidad para Windows
echo ========================================
echo.

REM Verificar que Flutter esté instalado
where flutter >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Flutter no está instalado o no está en el PATH
    echo Por favor instala Flutter desde https://flutter.dev
    pause
    exit /b 1
)

echo [1/5] Verificando configuración de Flutter...
flutter doctor
echo.

echo [2/5] Obteniendo dependencias...
flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Error al obtener dependencias
    pause
    exit /b 1
)
echo.

echo [3/5] Generando código (Drift, Riverpod, etc.)...
flutter pub run build_runner build --delete-conflicting-outputs
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Error al generar código
    pause
    exit /b 1
)
echo.

echo [4/5] Verificando que Windows esté habilitado...
flutter config --enable-windows-desktop
echo.

echo [5/5] Compilando para Windows...
flutter build windows --release
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Error al compilar
    pause
    exit /b 1
)
echo.

echo ========================================
echo Build completado exitosamente!
echo ========================================
echo.
echo La aplicación está en: build\windows\runner\Release\app_contabilidad.exe
echo.
pause


