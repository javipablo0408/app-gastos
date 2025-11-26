# 📍 Ubicación del Ejecutable

## 🎯 Ruta Completa

Después de compilar, el ejecutable estará en:

```
C:\Users\javier\Downloads\app contabilidad\build\windows\runner\Release\app_contabilidad.exe
```

## 📂 Estructura de Carpetas

```
app contabilidad/                    ← Tu carpeta del proyecto
└── build/                          ← Se crea al compilar
    └── windows/                    ← Build específico de Windows
        └── runner/                 ← Carpeta del ejecutable
            └── Release/            ← Versión release (optimizada)
                ├── app_contabilidad.exe  ← ⭐ AQUÍ ESTÁ EL EJECUTABLE
                ├── flutter_windows.dll
                ├── data/           ← Assets y recursos
                └── ... (otros archivos .dll necesarios)
```

## 🚀 Cómo Llegar Allí

### Opción 1: Desde el Explorador de Archivos
1. Abre el Explorador de Windows
2. Ve a: `C:\Users\javier\Downloads\app contabilidad`
3. Navega a: `build\windows\runner\Release`
4. Ahí encontrarás `app_contabilidad.exe`

### Opción 2: Desde PowerShell/CMD
```bash
cd "C:\Users\javier\Downloads\app contabilidad\build\windows\runner\Release"
dir
```

### Opción 3: Abrir directamente
```bash
# Desde la carpeta del proyecto
start build\windows\runner\Release\app_contabilidad.exe
```

## ⚠️ Importante

**La carpeta `build` solo se crea DESPUÉS de compilar.**

Para compilar, ejecuta:
```bash
.\build_windows.bat
```

O manualmente:
```bash
flutter build windows --release
```

## 📦 Para Distribuir la App

Si quieres compartir la aplicación, copia **TODA** la carpeta `Release`:
- `app_contabilidad.exe`
- Todos los archivos `.dll`
- La carpeta `data\`

O comprime la carpeta `Release` completa en un ZIP.

## 🔍 Verificar si Existe

Ejecuta en PowerShell:
```powershell
Test-Path "build\windows\runner\Release\app_contabilidad.exe"
```

- `True` = El ejecutable existe ✅
- `False` = Necesitas compilar primero ⚠️

