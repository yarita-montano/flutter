# ⚡ Quick Start - Login Setup

## 🚀 Inicio Rápido

### 1. Instalar dependencias
```bash
flutter pub get
```

### 2. Ejecutar la app
```bash
flutter run
```

### 3. Probar los logins

#### Opción A: Como Cliente (Conductor)
```
Email:    conductor@ejemplo.com
Password: miPassword123!
```

#### Opción B: Como Técnico (Mecánico)
```
Email:    tecnico.juan@taller.com
Password: password456!
```

---

## 📁 Archivos Creados

✅ `lib/services/auth_service.dart` - Servicio de autenticación  
✅ `lib/screens/login_screen.dart` - Pantalla de login  
✅ `lib/screens/conductor_home.dart` - Home del Cliente  
✅ `lib/screens/tecnico_home.dart` - Home del Técnico  
✅ `lib/main.dart` - Actualizado con routing  
✅ `pubspec.yaml` - Dependencias añadidas (http, shared_preferences)  

---

## 📊 Matriz de Rutas

| Ruta | Componente | Descripción |
|------|-----------|-------------|
| `/login` | LoginScreen | Pantalla de inicio de sesión |
| `/conductor-home` | ConductorHomeScreen | Home para Cliente (rol=1) |
| `/tecnico-home` | TecnicoHomeScreen | Home para Técnico (rol=3) |

---

## 🔑 Variables Almacenadas en SharedPreferences

```
access_token      → Token JWT del usuario
token_type        → Tipo de token (siempre "bearer")
user_id           → ID del usuario
user_rol          → Rol del usuario (1 o 3)
user_name         → Nombre del usuario
user_email        → Email del usuario
user_activo       → Estado del usuario (true/false)
login_time        → Timestamp del login
```

---

## 🌐 Endpoint del Backend

El backend debe estar corriendo en:
```
http://10.0.2.2:8000/usuarios/login  (para Android Emulator)
http://192.168.1.5:8000/usuarios/login  (para dispositivo físico - cambiar IP)
```

**Configurar la URL correcta en `lib/services/auth_service.dart`:**

```dart
// ✅ Opción automática (recomendada)
static const bool isEmulator = true; // Cambiar a false para dispositivo físico
static const String _emulatorUrl = 'http://10.0.2.2:8000';
static const String _deviceUrl = 'http://192.168.1.5:8000'; // Cambiar IP según tu red
static const String baseUrl = isEmulator ? _emulatorUrl : _deviceUrl;

// ❌ Así NO funciona en emulador Android
// static const String baseUrl = "http://localhost:8000";

// ✅ Esto funciona en emulador Android
// static const String baseUrl = "http://10.0.2.2:8000";

// ✅ Esto funciona en dispositivo físico
// static const String baseUrl = "http://192.168.1.5:8000";
```

---

## ✨ Características Principales

✅ Login con email y contraseña  
✅ Almacenamiento seguro de tokens  
✅ Enrutamiento automático según rol  
✅ Cierre de sesión seguro  
✅ Solicitudes autenticadas con Bearer token  
✅ Manejo de errores  
✅ Indicadores de carga  
✅ Interfaz responsiva  

---

## 🔐 Seguridad

- Token JWT persistente en `SharedPreferences`
- Headers `Authorization: Bearer {token}` en todas las solicitudes
- Logout limpia completamente los datos almacenados
- Token expira en 30 minutos (configurable en backend)

---

## 📝 Próximos Pasos

Después de verificar que el login funciona:

1. Implementar funcionalidades específicas de Cliente
   - Reportar emergencia
   - Ver incidentes
   
2. Implementar funcionalidades específicas de Técnico
   - Gestionar asignaciones
   - Actualizar estado

Más detalles en [README_LOGIN.md](README_LOGIN.md)

---

**¡Todo listo para comenzar! 🎉**
