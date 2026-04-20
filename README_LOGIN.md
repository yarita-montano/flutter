# 🔐 Login Implementation - Flutter App

## 📋 Descripción General

Se ha implementado un sistema de autenticación completo para la aplicación Flutter de **Emergencias Vehiculares**, con soporte para dos roles específicos:

- **👤 Cliente (Conductor)** - id_rol=1
- **🔧 Técnico (Mecánico)** - id_rol=3

---

## 📁 Estructura de Archivos

```
lib/
├── main.dart                    # Punto de entrada con routing
├── services/
│   └── auth_service.dart       # Servicio de autenticación
└── screens/
    ├── login_screen.dart       # Pantalla de login
    ├── conductor_home.dart     # Home para Cliente (Conductor)
    └── tecnico_home.dart       # Home para Técnico (Mecánico)
```

---

## 🔧 Componentes Principales

### 1. **AuthService** (`lib/services/auth_service.dart`)

Servicio centralizado que maneja toda la lógica de autenticación.

#### Métodos Principales:

```dart
// Login con credenciales
Future<Map<String, dynamic>> login(String email, String password)

// Obtener datos del usuario
Future<String?> getToken()
Future<String?> getUserId()
Future<String?> getUserRole()
Future<String?> getUserName()
Future<String?> getUserEmail()

// Verificar autenticación
Future<bool> isAuthenticated()

// Cerrar sesión
Future<void> logout()

// Realizar solicitudes autenticadas
Future<http.Response> authenticatedRequest(
  String method,
  String endpoint,
  {Map<String, dynamic>? body}
)
```

#### Almacenamiento:
- Usa `SharedPreferences` para guardar datos localmente
- Token JWT con duración de **30 minutos**

---

### 2. **LoginScreen** (`lib/screens/login_screen.dart`)

Pantalla de inicio de sesión con:
- ✅ Campos de email y contraseña
- ✅ Validación de campos
- ✅ Indicador de carga
- ✅ Manejo de errores
- ✅ Toggle para mostrar/ocultar contraseña
- ✅ Información de credenciales de prueba

#### Flujo:
1. Usuario ingresa email y contraseña
2. Se validan los campos
3. Se llama al endpoint `/usuarios/login`
4. Si es exitoso, se guarda el token y datos del usuario
5. Se redirige según el rol (Cliente → ConductorHomeScreen, Técnico → TecnicoHomeScreen)

---

### 3. **ConductorHomeScreen** (`lib/screens/conductor_home.dart`)

Pantalla principal para clientes (conductores) con:
- 📱 Perfil del usuario
- ⚠️ Botón para reportar emergencia
- 📜 Ver historial de incidentes
- ✏️ Editar perfil
- 🚪 Cerrar sesión

---

### 4. **TecnicoHomeScreen** (`lib/screens/tecnico_home.dart`)

Pantalla principal para técnicos (mecánicos) con:
- 👷 Perfil del técnico
- 📊 Estadísticas (Pendientes, En Progreso, Completados)
- 📋 Ver asignaciones pendientes
- 🔄 Actualizar estado de asignaciones
- 📜 Ver historial de trabajos
- ✏️ Editar perfil
- 🚪 Cerrar sesión

---

## 🚀 Flujo de Autenticación

```
┌─────────────────────────────────────────────┐
│  Arranque de la App                         │
└────────────────┬────────────────────────────┘
                 │
                 ▼
      ¿Token válido en SharedPreferences?
                 │
        ┌────────┴────────┐
        │                 │
       SÍ                NO
        │                 │
        ▼                 ▼
 ¿Obtenemos el rol?    LoginScreen
        │
   ┌────┴────────────────┐
   │                     │
  rol=1            rol=3 (o sin rol)
   │                     │
   ▼                     ▼
ConductorHome      TecnicoHome
Screen            Screen
```

---

## 🧪 Credenciales de Prueba

### Cliente (Conductor) - id_rol=1
```
Email:    conductor@ejemplo.com
Password: miPassword123!
```

### Técnico (Mecánico) - id_rol=3
```
Email:    tecnico.juan@taller.com
Password: password456!
```

---

## 📲 Uso de la Aplicación

### 1. **Instalar Dependencias**

```bash
flutter pub get
```

### 2. **Ejecutar la Aplicación**

```bash
flutter run
```

### 3. **Primer Inicio**

La app detectará que no hay token guardado y mostrará la pantalla de login.

### 4. **Login**

1. Ingresa el email de prueba
2. Ingresa la contraseña
3. Toca "Iniciar Sesión"
4. Serás redirigido a tu pantalla principal según tu rol

### 5. **Acciones Disponibles**

#### Como Cliente (Conductor):
- ✅ Ver perfil
- ✅ Reportar emergencia
- ✅ Ver mis incidentes
- ✅ Editar perfil
- ✅ Cerrar sesión

#### Como Técnico:
- ✅ Ver perfil
- ✅ Ver asignaciones pendientes
- ✅ Actualizar estado
- ✅ Ver historial
- ✅ Editar perfil
- ✅ Cerrar sesión

---

## 🔐 Seguridad

### Medidas Implementadas:

1. **Token JWT**: Las credenciales se autenticas y devuelven un JWT
2. **Headers Seguros**: Todas las solicitudes incluyen `Authorization: Bearer {token}`
3. **Almacenamiento Local**: `SharedPreferences` cifra automáticamente en dispositivos Android
4. **Expiración de Token**: 30 minutos (configurable en backend)
5. **Logout**: Limpia todos los datos al cerrar sesión

### Headers en Solicitudes Autenticadas:
```json
{
  "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "Content-Type": "application/json"
}
```

---

## 📝 Manejo de Errores

### Errores Comunes:

| Error | Causa | Solución |
|-------|-------|----------|
| "Email o contraseña incorrectos" | Las credenciales no coinciden | Verifica email y password |
| "El usuario ha sido desactivado" | Usuario inactivo en BD | Contacta al admin |
| "No se pudieron validar las credenciales" | Token expirado | Haz login nuevamente |
| "Error de conexión" | No hay conexión al servidor | Verifica la URL de la API |

---

## 🔌 Integración con Backend

### Endpoint de Login:
```
POST /usuarios/login
Content-Type: application/json
Body: {
  "email": "conductor@ejemplo.com",
  "password": "miPassword123!"
}
```

### Response Exitoso (200):
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "usuario": {
    "id_usuario": 5,
    "id_rol": 1,
    "nombre": "Juan Conductor",
    "email": "conductor@ejemplo.com",
    "activo": true,
    "created_at": "2026-04-15T10:30:00"
  }
}
```

---

## 📚 Próximas Funcionalidades

Las siguientes funcionalidades están disponibles como placeholders y deben implementarse:

### Cliente (Conductor):
- [ ] Reportar emergencia (POST /incidencias)
- [ ] Ver mis incidentes (GET /incidencias/mis-incidentes)
- [ ] Editar perfil (PUT /usuarios/perfil)

### Técnico:
- [ ] Ver asignaciones pendientes (GET /asignaciones/pendientes)
- [ ] Actualizar estado de asignación (PUT /asignaciones/{id}/status)
- [ ] Completar asignación (POST /asignaciones/{id}/completar)
- [ ] Ver historial de trabajos

---

## ⚙️ Configuración

### URL de la API

Modifica la URL base en `lib/services/auth_service.dart`:

```dart
static const String baseUrl = "http://localhost:8000";
```

#### Para diferentes ambientes:
```dart
// Desarrollo
static const String baseUrl = "http://localhost:8000";

// Producción
static const String baseUrl = "https://api.emergencias.com";
```

### Duración del Token

La duración del token se configura en el backend (`.env`):
```
TOKEN_EXPIRY_MINUTES=30
```

---

## 🐛 Resolución de Problemas

### Problema: "Failed to initialize plugin"
**Solución:** Ejecuta `flutter pub get` nuevamente

### Problema: Pantalla en blanco después de login
**Solución:** Asegúrate que el servidor backend está corriendo en `localhost:8000`

### Problema: Token siempre expira
**Solución:** Verifica que el token tiene al menos 5 minutos de duración en el backend

### Problema: No se guardan los datos después del login
**Solución:** En Android, asegúrate de agregar permisos en `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET" />
```

---

## 📞 Contacto y Soporte

Para dudas o problemas con la implementación, revisa:
- [`LOGIN_POR_ROLES.md`](../guias/LOGIN_POR_ROLES.md) - Guía completa de roles y endpoints
- Documentación oficial de Flutter
- Documentación oficial de SharedPreferences

---

**¡Listo para usar! 🎉**
