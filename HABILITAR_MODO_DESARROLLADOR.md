# 🔧 Habilitar Modo de Desarrollador en Windows

## ⚠️ Problema

Flutter necesita crear enlaces simbólicos (symlinks) para compilar plugins en Windows, lo cual requiere el **Modo de Desarrollador**.

## ✅ Solución Rápida

### Opción 1: Desde PowerShell (Recomendado)

Ejecuta este comando para abrir la configuración:

```powershell
start ms-settings:developers
```

Luego:
1. Activa el interruptor **"Modo de desarrollador"**
2. Acepta el aviso de seguridad
3. Espera a que se configure (puede tardar unos segundos)

### Opción 2: Manualmente

1. Abre **Configuración** de Windows (Win + I)
2. Ve a **Privacidad y seguridad** → **Para desarrolladores**
3. Activa **"Modo de desarrollador"**
4. Acepta el aviso

## 🚀 Después de Habilitar

Una vez habilitado, ejecuta nuevamente:

```bash
flutter build windows --release
```

## 📝 Nota

- El Modo de Desarrollador es seguro y necesario para desarrollo
- Puedes desactivarlo después si lo deseas
- Es requerido por Flutter para compilar aplicaciones con plugins

## 🔄 Alternativa: Modo Debug

Si no quieres habilitar el Modo de Desarrollador ahora, puedes ejecutar en modo debug:

```bash
flutter run -d windows
```

El modo debug funciona sin symlinks pero genera un ejecutable más grande y lento.

