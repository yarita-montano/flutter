# 🐛 GUÍA DE DIAGNÓSTICO - Error 401 en Vehículos

## 🚨 El Problema

Tu app Flutter está recibiendo **error 401 (Unauthorized)** cuando intenta listar vehículos. El servidor dice que el token es inválido.

---

## ✅ Paso 1: Verifica que el Backend esté corriendo

```powershell
# Desde tu terminal en el backend
cd c:\Users\Isael Ortiz\Documents\yary\Backend
python main.py
# O si usas uvicorn directamente:
# uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

**✓ Debería ver**: `Uvicorn running on http://0.0.0.0:8000`

---

## ✅ Paso 2: Prueba el Endpoint Directamente (PowerShell)

```powershell
# 1. Login
$loginUri = "http://localhost:8000/usuarios/login"
$loginBody = @{ 
  email = "conductor@ejemplo.com"
  password = "cliente123!" 
} | ConvertTo-Json

$loginResp = Invoke-WebRequest -Uri $loginUri -Method POST `
  -Headers @{"Content-Type"="application/json"} `
  -Body $loginBody -UseBasicParsing

$token = ($loginResp.Content | ConvertFrom-Json).access_token
Write-Host "✅ Token obtenido: $token`n"

# 2. Prueba el endpoint de vehículos
$vehiculosUri = "http://localhost:8000/vehiculos/mis-autos"
$vehiculosResp = Invoke-WebRequest -Uri $vehiculosUri -Method GET `
  -Headers @{
    "Authorization"="Bearer $token"
    "Content-Type"="application/json"
  } -UseBasicParsing

$vehiculosResp.Content | ConvertFrom-Json | ConvertTo-Json
```

**Expected**: Array vacío `[]` o lista de vehículos
**Si ves error 401**: El backend rechaza el token (verifica token_type en tu modelo)

---

## ✅ Paso 3: Pantalla de Debug en Flutter

He creado una **pantalla de debugging integrada**. Úsala así:

### Opción A: Desde la App
1. Abre la aplicación y ve a "Mis Vehículos"
2. Agrega esta línea en la pantalla de Conductor Home para acceder al debug:

```dart
// En conductor_home.dart, agrega este botón temporal:
FloatingActionButton(
  onPressed: () => Navigator.pushNamed(context, '/debug-vehiculos'),
  child: Icon(Icons.bug_report),
  tooltip: 'DEBUG',
)
```

### Opción B: Directamente en Terminal
```bash
# Accede a través de deep link (si lo configuraste)
# O simplemente desde el código
Navigator.pushNamed(context, '/debug-vehiculos');
```

---

## 🔍 Interpretando los Logs

### Cuando ves ✅ OK
```
✅ INICIANDO LISTAR VEHÍCULOS
✅ Token encontrado
✅ Vehículos cargados exitosamente: 0 vehículos
```
**Significa**: Todo funciona, pero no tienes vehículos registrados. ¡Registra uno!

### Cuando ves ❌ ERROR 401
```
❌ INICIANDO LISTAR VEHÍCULOS
✅ Token encontrado
📥 Respuesta recibida:
  - Status: 401
  - Headers: {...}
❌ ERROR 401 - Unauthorized
   El servidor rechazó el token. Posibles causas:
   1. Token expirado
   2. Token inválido o corrupto
   3. Formato incorrecto en Authorization header
```

**Soluciones**:
1. **Cierra sesión y vuelve a iniciar**
2. **Verifica que el backend esté corriendo**
3. **Comprueba que usas `http://10.0.2.2:8000` en emulador** (NO `localhost`)

### Cuando ves ❌ Token es NULL
```
❌ FATAL: Token es NULL - no se puede hacer la petición
```

**Significa**: No iniciaste sesión correctamente.
**Solución**: 
- Login primero
- Verifica que `AuthService._saveUserData()` se ejecutó correctamente

---

## 🔧 Checklist de Debug

- [ ] Backend corre en `http://0.0.0.0:8000`
- [ ] Puedes hacer login y obtener token (PowerShell)
- [ ] El endpoint `/vehiculos/mis-autos` responde 200 cuando envías token válido
- [ ] App Flutter está configurada para Android Emulator (`10.0.2.2:8000`)
- [ ] AuthService está guardando el token en SharedPreferences
- [ ] VehiculoService puede leer el token de SharedPreferences
- [ ] Authorization header se envía con formato: `Bearer <token>`

---

## 📋 Qué Ver en los Logs

**En Android Studio Logcat:**
```
I/flutter: 🚗 === INICIANDO LISTAR VEHÍCULOS ===
I/flutter: ✅ Token encontrado
I/flutter: 📍 Endpoint: http://10.0.2.2:8000/vehiculos/mis-autos
I/flutter: 📤 Headers enviados:
I/flutter:   - Authorization: Bearer eyJhbGciOi...
I/flutter: 📥 Respuesta recibida:
I/flutter:   - Status: 200
I/flutter: ✅ Vehículos cargados exitosamente
```

**En VS Code Debug Console:**
```
flutter: 🚗 === INICIANDO LISTAR VEHÍCULOS ===
flutter: ✅ Token encontrado
flutter: 📍 Endpoint: http://10.0.2.2:8000/vehiculos/mis-autos
...
```

---

## 🚀 Pasos para Resolver

### Escenario 1: "Token es NULL"
```dart
// En tu login screen, agrega debug:
debugPrint('🔐 Login response: $resultado');

// Verifica que el backend devuelva 'access_token' en el response
// El JSON debe ser:
{
  "access_token": "eyJhbGciOi...",
  "token_type": "bearer",
  "usuario": { ... }
}
```

### Escenario 2: "ERROR 401"
```dart
// 1. Cierra y vuelve a abrir la app
// 2. Verifica token_type en tu backend
// 3. Prueba: Navigator.pushNamed(context, '/debug-vehiculos');
//    y presiona "Mostrar Preferencias (logs)"
```

### Escenario 3: "Connection Error"
```
❌ Excepción: Failed host lookup: '10.0.2.2'
```
**Solución**: No estás en emulador Android. Cambiar a `localhost` o IP real.

---

## 💡 Tips Finales

1. **Siempre limpia logs antes de probar**: Scroll al final del logcat
2. **Revisa el backend**: `python main.py` con `--reload`
3. **Reinicia la app**: A veces SharedPreferences se corrompe
4. **Verifica permisos**: La app necesita internet (AndroidManifest.xml)

---

## 📞 Si Aún Hay Problemas

Comparte en tu request:
```
1. Pantalla de Debug - Qué datos ves?
2. Logs de Flutter (copiar toda la salida)
3. Error exacto del servidor (si lo ves)
4. ¿Backend corre en puerto 8000?
```

**¡Buena suerte! 🚀**
