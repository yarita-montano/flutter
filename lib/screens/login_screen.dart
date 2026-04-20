import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor completa todos los campos';
        _isLoading = false;
      });
      return;
    }

    final result = await _authService.login(email, password);

    if (!mounted) return;

    if (result['success']) {
      final userData = result['data']['usuario'];
      final userRole = userData['id_rol'].toString();

      // Route based on user role
      if (userRole == '1') {
        // Cliente (Conductor)
        Navigator.of(context).pushReplacementNamed('/conductor-home');
      } else if (userRole == '3') {
        // Técnico
        Navigator.of(context).pushReplacementNamed('/tecnico-home');
      } else {
        setState(() {
          _errorMessage = 'Rol no autorizado para esta aplicación';
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _errorMessage = result['error'];
        _isLoading = false;
      });
    }
  }

  // Auto-login para pruebas: Cliente (Conductor)
  Future<void> _autoLoginConductor() async {
    await _handleLoginWithCredentials(
      'conductor@ejemplo.com',
      'cliente123!',
    );
  }

  // Auto-login para pruebas: Técnico
  Future<void> _autoLoginTecnico() async {
    await _handleLoginWithCredentials(
      'tecnico.juan@taller.com',
      'tecnico123!',
    );
  }

  // Método auxiliar para login con credenciales específicas
  Future<void> _handleLoginWithCredentials(String email, String password) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _emailController.text = email;
      _passwordController.text = password;
    });

    final result = await _authService.login(email, password);

    if (!mounted) return;

    if (result['success']) {
      final userData = result['data']['usuario'];
      final userRole = userData['id_rol'].toString();

      if (userRole == '1') {
        Navigator.of(context).pushReplacementNamed('/conductor-home');
      } else if (userRole == '3') {
        Navigator.of(context).pushReplacementNamed('/tecnico-home');
      }
    } else {
      setState(() {
        _errorMessage = result['error'];
        _isLoading = false;
      });
    }
  }

  // Limpiar datos de prueba
  Future<void> _clearAllData() async {
    try {
      await _authService.logout();
      setState(() {
        _emailController.clear();
        _passwordController.clear();
        _errorMessage = 'Datos limpios ✅';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al limpiar: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                // Logo / Title
                Icon(
                  Icons.emergency_share,
                  size: 80,
                  color: Colors.red.shade600,
                ),
                const SizedBox(height: 20),
                Text(
                  'Emergencias Vehiculares',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Asistencia en la carretera',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
                const SizedBox(height: 60),

                // Email Field
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Correo Electrónico',
                    hintText: 'ejemplo@correo.com',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Password Field
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Error Message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade600,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_errorMessage != null) const SizedBox(height: 16),

                // Login Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.red.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Iniciar Sesión',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
                const SizedBox(height: 24),

                // Demo Credentials Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Credenciales de Prueba',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '👤 Cliente (Conductor):',
                        style: TextStyle(
                          color: Colors.blue.shade600,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'conductor@ejemplo.com',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        'cliente123!',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '🔧 Técnico (Mecánico):',
                        style: TextStyle(
                          color: Colors.blue.shade600,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'tecnico.juan@taller.com',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        'tecnico123!',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 🚀 Botones de autorrelleno e inicio automático
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Inicio Rápido de Prueba',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Botones grandes - Login automático
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _autoLoginConductor,
                              icon: const Icon(Icons.person),
                              label: const Text('👤 Cliente'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade600,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _autoLoginTecnico,
                              icon: const Icon(Icons.build),
                              label: const Text('🔧 Técnico'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade600,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Botones pequeños - Solo autorrelleno
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        _emailController.text = 'conductor@ejemplo.com';
                                        _passwordController.text = 'cliente123!';
                                        _errorMessage = 'Campos autorrellenos ✅';
                                      });
                                    },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              child: const Text(
                                'Rellenar: Cliente',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        _emailController.text = 'tecnico.juan@taller.com';
                                        _passwordController.text = 'tecnico123!';
                                        _errorMessage = 'Campos autorrellenos ✅';
                                      });
                                    },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              child: const Text(
                                'Rellenar: Técnico',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      // Botón flotante para opciones de desarrollo - Menú popup simple
      floatingActionButton: PopupMenuButton<String>(
        onSelected: (value) async {
          switch (value) {
            case 'conductor':
              await _autoLoginConductor();
              break;
            case 'tecnico':
              await _autoLoginTecnico();
              break;
            case 'fill_conductor':
              setState(() {
                _emailController.text = 'conductor@ejemplo.com';
                _passwordController.text = 'cliente123!';
              });
              break;
            case 'fill_tecnico':
              setState(() {
                _emailController.text = 'tecnico.juan@taller.com';
                _passwordController.text = 'tecnico123!';
              });
              break;
            case 'clear':
              await _clearAllData();
              break;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'conductor',
            child: Row(
              children: [
                Icon(Icons.person),
                SizedBox(width: 12),
                Text('👤 Login: Cliente'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'tecnico',
            child: Row(
              children: [
                Icon(Icons.build),
                SizedBox(width: 12),
                Text('🔧 Login: Técnico'),
              ],
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'fill_conductor',
            child: Row(
              children: [
                Icon(Icons.edit),
                SizedBox(width: 12),
                Text('✏️ Llenar: Cliente'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'fill_tecnico',
            child: Row(
              children: [
                Icon(Icons.edit),
                SizedBox(width: 12),
                Text('✏️ Llenar: Técnico'),
              ],
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'clear',
            child: Row(
              children: [
                Icon(Icons.delete_sweep),
                SizedBox(width: 12),
                Text('🧹 Limpiar Datos'),
              ],
            ),
          ),
        ],
        tooltip: 'Opciones de Prueba',
        icon: const Icon(Icons.build),
      ),
    );
  }
}
