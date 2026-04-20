# 🚨 Troubleshooting - App Abre y Se Cierra

## Problema
La aplicación se abre en el emulador pero se cierra inmediatamente sin mostrar errores claros.

---

## ✅ Soluciones Progresivas

### 1️⃣ **Limpiar y Reconstruir**

```bash
# Limpiar completamente
flutter clean

# Obtener dependencias nuevamente
flutter pub get

# Ejecutar con logs detallados
flutter run -v
```

### 2️⃣ **Ejecutar con Debugging**

```bash
# Ver todos los logs
flutter logs

# En otra terminal
flutter run
```

Los logs te mostrarán exactamente dónde está fallando. Busca líneas que comiencen con:
- ✅ (éxito)
- ❌ (error)
- 🔍 (información)

---

## 📋 Errores Comunes y Soluciones

### Error: "MissingPluginException"
**Causa:** SharedPreferences o http no están correctamente instalados

**Solución:**
```bash
flutter pub get
flutter clean
flutter pub get
flutter run
```

---

### Error: "E/android: Unknown class 'androidx.lifecycle...'"
**Causa:** Incompatibilidad de dependencias en Android

**Solución:**
```bash
cd android
./gradlew clean
cd ..
flutter pub get
flutter run
```

---

### Error: "FATAL EXCEPTION" en logs
**Causa:** Excepción no capturada durante inicialización

**Solución:**
Revisa los logs con:
```bash
flutter logs | grep "FATAL"
flutter logs | grep "ERROR"
```

---

## 🔧 Verificar Dependencias

### Asegúrate que el `pubspec.yaml` tiene:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  http: ^1.1.0
  shared_preferences: ^2.2.2
```

Si falta algo, agregalo y corre:
```bash
flutter pub get
```

---

## 🧹 Resetear SharedPreferences

Si el problema es con datos guardados anteriormente:

```bash
# En Android Studio:
# Device File Explorer → data → data → com.example.app_emergencias → shared_prefs
# Eliminar el archivo "flutter.xml"

# O ejecutar en la app (cuando funcione):
import 'package:app_emergencias/utils/debug_helper.dart';
DebugHelper.clearAllData();
```

---

## 🚀 Debugging Paso a Paso

### 1. Verifica en `main.dart`:
El código ahora tiene `debugPrint` statements que mostrarán:
- ✅ Inicialización de SharedPreferences
- 🔍 Verificación de autenticación
- 📍 Ruta seleccionada

### 2. Busca en los logs:
```
flutter run -v 2>&1 | grep "✅\|❌\|🔍\|📍"
```

---

## 💾 Restaurar a Versión Simple

Si nada funciona, usa esta versión minimal:

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emergencias Vehiculares',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
      ),
      home: const LoginScreen(),
    );
  }
}
```

Esto es la versión más simple. Si esto funciona, el problema está en la lógica de autenticación inicial.

---

## 📞 Pasos Finales

1. **Ejecuta:** `flutter clean && flutter pub get`
2. **Luego:** `flutter run -v`
3. **Copia los logs** donde ves "❌" o "ERROR"
4. **Comparte esos logs** para debugging más preciso

---

## 🎯 Qué Debería Ver

Cuando se ejecute correctamente en los logs:

```
✅ SharedPreferences inicializado correctamente
🚀 Iniciando aplicación...
🔍 Verificando autenticación...
📋 ¿Autenticado?: false
✅ Ruta: Login Screen
```

Si vez esto, ¡la app debe mostrar la pantalla de login correctamente! ✨

---

**¿Aún no funciona? Comparte los logs exactos con "❌" o "ERROR"**
