# 👤 Editar Perfil - Implementado

## ✅ Lo que se creó

### Archivos Nuevos

1. **`lib/services/usuario_service.dart`**
   - `obtenerPerfil()` - GET /usuarios/perfil
   - `actualizarPerfil()` - PUT /usuarios/perfil
   - Manejo de errores 401 con limpieza automática de token
   - Actualización de SharedPreferences

2. **`lib/screens/perfil_screen.dart`**
   - Pantalla de visualización del perfil
   - Botón de edición pequeño en la esquina superior derecha (AppBar)
   - Muestra: Nombre, Email, Teléfono, Rol, Fecha de creación
   - Avatar con inicial del nombre

3. **`lib/screens/editar_perfil_screen.dart`**
   - Formulario de edición con validaciones
   - Campos: Nombre, Email, Teléfono (opcional)
   - Botones Cancelar/Guardar Cambios
   - Manejo de errores

### Cambios en Archivos Existentes

1. **`lib/main.dart`**
   - Importación de nuevas pantallas
   - Nueva ruta: `/perfil` → PerfilScreen

2. **`lib/screens/conductor_home.dart`**
   - Icono de perfil agregado en AppBar (esquina superior derecha)
   - Navega a `/perfil` cuando se toca

---

## 🎯 Diseño del Botón

```
┌─────────────────────────────────────┐
│ Emergencias Vehiculares  [👤] [🚪] │
└─────────────────────────────────────┘
    ↑ Botón perfil pequeño en esquina superior derecha
```

### Características:
- ✅ Pequeño (tamaño de icono)
- ✅ En la esquina superior derecha del AppBar
- ✅ Antes del botón de logout
- ✅ Icono: `Icons.person`
- ✅ Tooltip: "Mi Perfil"

---

## 📱 Flujo de Uso

### 1. Ver Perfil
```
ConductorHomeScreen
    ↓ (toca icono 👤)
PerfilScreen
```

### 2. Editar Perfil
```
PerfilScreen
    ↓ (toca icono 🖊️ en AppBar)
EditarPerfilScreen
    ↓ (edita y guarda)
PerfilScreen (actualizado)
```

---

## 🔌 API Endpoints

### GET /usuarios/perfil
```dart
Respuesta:
{
  "id_usuario": 1,
  "id_rol": 1,
  "nombre": "Juan Conductor",
  "email": "conductor@ejemplo.com",
  "telefono": "+57 3001234567",
  "activo": true,
  "created_at": "2026-04-19T01:30:00"
}
```

### PUT /usuarios/perfil
```dart
Body:
{
  "nombre": "Juan Pérez",
  "email": "juan@nuevo.com",
  "telefono": "+57 3009999999"
}

Respuesta:
{
  "id_usuario": 1,
  "nombre": "Juan Pérez",
  "email": "juan@nuevo.com",
  ...actualizado...
}
```

---

## ✨ Características Implementadas

✅ **Visualización de Perfil**
- Avatar circular con inicial del nombre
- Información organizada en tarjetas
- Estado de actividad (activo/inactivo)
- Rol del usuario

✅ **Edición de Perfil**
- Validación de campos en cliente
- Nombre: mínimo 3 caracteres
- Email: validación de formato
- Teléfono: opcional, mínimo 7 caracteres

✅ **Manejo de Errores**
- Error 401: Limpia token y redirige a login
- Error 400: Muestra error del servidor (ej: email duplicado)
- Error de conexión: Notifica al usuario

✅ **Actualización Automática**
- Después de editar, la pantalla se actualiza
- SharedPreferences también se actualiza
- ConductorHomeScreen muestra nombre actualizado

✅ **UX/UI**
- Botón de perfil pequeño y discreto
- Icono en lugar de texto
- Tooltip descriptivo
- Animaciones de carga
- Notificaciones visuales

---

## 🚀 Cómo Usar

### Acceder al Perfil
1. Toca el icono 👤 en la esquina superior derecha
2. Ve tu perfil completo

### Editar Perfil
1. En PerfilScreen, toca el icono 🖊️ (edit)
2. Modifica los datos
3. Toca "Guardar Cambios"
4. Se actualizará automáticamente

---

## 📝 Notas

- El token se valida automáticamente
- Si expira, la app redirige a login
- Los cambios se guardan en backend y local
- El email debe ser único en el sistema

---

## ✅ Status

✅ **IMPLEMENTADO Y LISTO PARA USAR**

**Próximo paso**: Prueba desde la app Flutter 🎉
