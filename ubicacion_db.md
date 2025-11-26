# Ubicación de la Base de Datos en Windows

## Ruta de la Base de Datos

La base de datos se guarda en el directorio de documentos de la aplicación usando `getApplicationDocumentsDirectory()`.

### Ubicación estándar en Windows:

```
C:\Users\[TU_USUARIO]\AppData\Roaming\contabilidad.db
```

O también puede estar en:
```
%APPDATA%\contabilidad.db
```

### Nombre del archivo:
- **Base de datos principal**: `contabilidad.db`
- **Backups**: Se guardan en `%APPDATA%\backups\backup_[timestamp].db`

## Cómo encontrar la ubicación exacta:

### Opción 1: Desde PowerShell
```powershell
# Abrir PowerShell y ejecutar:
$env:APPDATA
# Luego buscar el archivo:
Get-ChildItem "$env:APPDATA\contabilidad.db"
```

### Opción 2: Desde el Explorador de Windows
1. Presiona `Win + R`
2. Escribe: `%APPDATA%`
3. Presiona Enter
4. Busca el archivo `contabilidad.db`

### Opción 3: Buscar en todo el sistema
```powershell
Get-ChildItem -Path C:\Users\$env:USERNAME -Filter "contabilidad.db" -Recurse -ErrorAction SilentlyContinue
```

## Si necesitas eliminar/reiniciar la base de datos:

1. Cierra la aplicación completamente
2. Ve a la ubicación indicada arriba
3. Elimina o renombra el archivo `contabilidad.db`
4. Al abrir la aplicación nuevamente, se creará una base de datos nueva

## Nota importante:
- La base de datos contiene todos tus datos (gastos, ingresos, categorías, presupuestos)
- Haz un backup antes de eliminar el archivo
- Los backups automáticos (si están configurados) están en la carpeta `backups` dentro del mismo directorio

