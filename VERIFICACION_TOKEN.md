# 🔑 Verificación del Token - Guía Completa

## El Flujo Correcto

```
Login Screen
   ↓
AuthService.login(email, password)
   ↓
POST /usuarios/login → ✅ Recibe access_token
   ↓
AuthService._saveUserData() → Guarda en SharedPreferences
   ↓
key: 'access_token', value: 'eyJhbGciOi...'
   ↓
VehiculoService._getToken() → Lee de SharedPreferences
   ↓
Envía en header: Authorization: Bearer eyJhbGciOi...
   ↓
✅ Backend acepta el token → 200 OK
```

## 🚨 Dónde Puede Fallar

### ❌ Falla 1: El Login no Guarda el Token

**Síntoma**: Token es NULL en VehiculoService

**Código Correcto en AuthService:**
```dart
Future<void> _saveUserData(Map<String, dynamic> data) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('access_token', data['access_token'] ?? '');
  debugPrint('✅ Token guardado');
}
```

**Verificar**: En tu login_screen.dart, después del login:
```dart
final resultado = await authService.login(email, password);
if (resultado['success']) {
  // El token DEBE estar guardado ahora
  final token = await authService.getToken();
  debugPrint('🔑 Token después de login: $token');
}
```

### ❌ Falla 2: El Token se Guarda pero está Vacío

**Síntoma**: Token "" (string vacío)

**El servidor responde**:
```json
{
  "access_token": null,  // ❌ PROBLEMA
  "token_type": "bearer",
  ...
}
```

O el servidor omite `access_token` en el JSON.

**Verificar en Backend**:
```python
# main.py o routers/usuarios.py
@router.post("/login")
def login(credentials: LoginRequest, db: Session = Depends(get_db)):
    # ...
    return {
        "access_token": token,  # ✅ MUST BE INCLUDED
        "token_type": "bearer",
        "usuario": {...}
    }
```

### ❌ Falla 3: El Token se Envía Incorrectamente

**Síntoma**: Error 401 aunque el token existe

**❌ INCORRECTO**:
```dart
headers: {
  'Authorization': token,  // ❌ Falta "Bearer "
}
```

**✅ CORRECTO**:
```dart
headers: {
  'Authorization': 'Bearer $token',  // ✅ Debe incluir "Bearer "
}
```

### ❌ Falla 4: URL Backend Incorrecta

**Síntoma**: Conexión rechazada o timeout

**❌ INCORRECTO (para emulador Android)**:
```dart
static const String baseUrl = "http://localhost:8000";  // ❌ No funciona en emulador
```

**✅ CORRECTO (para emulador Android)**:
```dart
static const String baseUrl = "http://10.0.2.2:8000";  // ✅ Dirección especial del emulador
```

**Para dispositivo físico**:
```dart
static const String baseUrl = "http://192.168.1.5:8000";  // Cambiar por tu IP local
```

---

## ✅ Test Paso a Paso

### Test 1: ¿El Login guarda el Token?

```dart
// En login_screen.dart, después de login exitoso:

final resultado = await authService.login(email, password);

if (resultado['success']) {
  // Esperar a que todo se guarde
  await Future.delayed(Duration(milliseconds: 500));
  
  // Verificar que el token se guardó
  final token = await authService.getToken();
  final userId = await authService.getUserId();
  final userName = await authService.getUserName();
  
  debugPrint('✅ Token después de login:');
  debugPrint('  - Token: ${token != null ? token.substring(0, 30) : 'NULL'}');
  debugPrint('  - User ID: $userId');
  debugPrint('  - User Name: $userName');
  
  // Si alguno es NULL, el problema está en _saveUserData
}
```

### Test 2: ¿VehiculoService puede leer el Token?

```dart
// Desde cualquier pantalla:

final service = VehiculoService();
final token = await service._getToken();  // Necesita ser public o crear getter

if (token == null) {
  debugPrint('❌ Token es NULL - no se guardó en login');
} else {
  debugPrint('✅ Token encontrado: ${token.substring(0, 30)}...');
}
```

### Test 3: ¿El Endpoint Responde Correctamente?

```dart
// Usar el debug screen: Navigator.pushNamed(context, '/debug-vehiculos');
// Y presionar "Probar GET /vehiculos/mis-autos"

// Esperar el resultado en los logs:
// - Status: 200 = ✅ OK
// - Status: 401 = ❌ Token rechazado
// - Status: 500 = ❌ Error del servidor
```

---

## 🔍 Logs Esperados

### Logs de Login ✅

```
I/flutter: 🔐 Intentando login con: conductor@ejemplo.com
I/flutter: 📊 Response status: 200
I/flutter: ✅ Login exitoso
I/flutter: ✅ Datos guardados en SharedPreferences
```

### Logs de Vehículos ✅

```
I/flutter: 🚗 === INICIANDO LISTAR VEHÍCULOS ===
I/flutter: 🔑 Token obtenido: eyJhbGciOiJIUzI1NiIsIn...
I/flutter: ✅ Token encontrado
I/flutter: 📍 Endpoint: http://10.0.2.2:8000/vehiculos/mis-autos
I/flutter: 📤 Headers enviados:
I/flutter:   - Authorization: Bearer eyJhbGciOiJIUzI1NiIsIn...
I/flutter:   - Content-Type: application/json
I/flutter: 📥 Respuesta recibida:
I/flutter:   - Status: 200
I/flutter: ✅ Vehículos cargados exitosamente: 0 vehículos
```

### Logs de Error ❌

```
I/flutter: 🚗 === INICIANDO LISTAR VEHÍCULOS ===
I/flutter: ❌ FATAL: Token es NULL - no se puede hacer la petición

O bien:

I/flutter: 📥 Respuesta recibida:
I/flutter:   - Status: 401
I/flutter: ❌ ERROR 401 - Unauthorized
```

---

## 📱 Cómo Acceder al Debug Screen

### Opción 1: Agrega un Botón Temporal

En `conductor_home.dart`:

```dart
// En el AppBar actions:
actions: [
  // ... tu logout button ...
  IconButton(
    icon: Icon(Icons.bug_report),
    onPressed: () => Navigator.pushNamed(context, '/debug-vehiculos'),
    tooltip: 'Debug',
  ),
],
```

### Opción 2: Deep Link

```dart
// Desde cualquier lugar
Navigator.pushNamed(context, '/debug-vehiculos');
```

---

## 🎯 Resumen de la Solución

| Problema | Síntoma | Solución |
|----------|---------|----------|
| Token no se guarda | Token NULL | Revisar `_saveUserData()` en AuthService |
| Token vacío | Token "" | Verificar que backend devuelva `access_token` |
| Token no se envía | 401 sin detalles | Verificar formato `Bearer $token` |
| URL incorrecta | Connection refused | Usar `10.0.2.2` para emulador |
| Backend no corre | Connection timeout | `python main.py` en backend |
| Token expirado | 401 después de 30 min | Volver a iniciar sesión |

---

## ✅ Checklist Final

- [ ] Backend corre en `http://0.0.0.0:8000`
- [ ] Endpoint `/usuarios/login` devuelve `access_token`
- [ ] `AuthService._saveUserData()` guarda el token
- [ ] `VehiculoService._getToken()` puede leerlo
- [ ] Header tiene formato: `Authorization: Bearer eyJ...`
- [ ] App se conecta a `http://10.0.2.2:8000` (emulador)
- [ ] Logs muestran "✅ Token encontrado"

Si todo esto está OK → **Debería funcionar perfectamente** ✅

---

**Próximo paso**: Usar el Debug Screen para verificar cada punto 🚀
