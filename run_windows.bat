@echo off
echo ========================================
echo Ejecutar App Contabilidad en Windows
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

echo [1/3] Obteniendo dependencias...
flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Error al obtener dependencias
    pause
    exit /b 1
)
echo.

echo [2/3] Generando código (Drift, Riverpod, etc.)...
flutter pub run build_runner build --delete-conflicting-outputs
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Error al generar código
    pause
    exit /b 1
)
echo.

echo [3/3] Ejecutando aplicación...
flutter run -d windows
echo.

pause


