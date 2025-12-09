# 🧹 Workflow de Limpieza Automática

Este workflow automatiza la limpieza del repositorio, incluyendo:

## Funcionalidades

- **🗑️ Limpiar Historial de Actions**: Elimina todas las ejecuciones de workflows anteriores
- **🔒 Cerrar Pull Requests**: Cierra automáticamente todos los PRs abiertos
- **🔒 Cerrar Issues**: Cierra automáticamente todos los issues abiertos

## Uso

### Ejecución Manual

1. Ve a la pestaña **Actions** en GitHub
2. Selecciona el workflow **🧹 Cleanup - Actions History, PRs & Issues**
3. Haz clic en **Run workflow**
4. Selecciona las opciones que deseas ejecutar:
   - ✅ **Clean workflow runs history**: Limpiar historial de workflows
   - ✅ **Close all open pull requests**: Cerrar todos los PRs
   - ✅ **Close all open issues**: Cerrar todos los issues
5. Haz clic en **Run workflow** para ejecutar

### Requisitos

Este workflow requiere que el secret `TEST` esté configurado en el repositorio con un token de GitHub que tenga los siguientes permisos:

- `repo` (acceso completo a repositorios)
- `workflow` (actualizar workflows de GitHub Actions)

### Configuración del Token

1. Ve a **Settings** → **Secrets and variables** → **Actions**
2. Verifica que el secret `TEST` exista
3. Si no existe, créalo con un Personal Access Token que tenga los permisos necesarios

### Precauciones

⚠️ **ADVERTENCIA**: Este workflow realiza acciones destructivas:

- La eliminación del historial de workflows es **permanente**
- El cierre de PRs e issues es **permanente** (aunque se pueden reabrir manualmente)
- Asegúrate de que realmente quieres ejecutar estas acciones antes de proceder

### Permisos del Workflow

El workflow tiene los siguientes permisos configurados:

```yaml
permissions:
  actions: write        # Para eliminar workflow runs
  contents: write       # Para acceder al contenido del repositorio
  issues: write         # Para cerrar issues
  pull-requests: write  # Para cerrar pull requests
```

## Personalización

Puedes modificar el workflow para:

- Agregar filtros para cerrar solo ciertos PRs o issues
- Agregar etiquetas antes de cerrar
- Cambiar los mensajes de cierre
- Agregar notificaciones adicionales

## Solución de Problemas

Si el workflow falla:

1. Verifica que el secret `TEST` esté correctamente configurado
2. Asegúrate de que el token tenga los permisos necesarios
3. Revisa los logs del workflow para ver el error específico
4. Verifica que no haya límites de rate limiting de la API de GitHub

## Licencia

Este workflow es parte del proyecto UN1CA-v2 y está sujeto a la misma licencia del proyecto.
