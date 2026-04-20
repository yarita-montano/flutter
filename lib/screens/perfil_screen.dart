import 'package:flutter/material.dart';
import '../services/usuario_service.dart';
import 'editar_perfil_screen.dart';

class PerfilScreen extends StatefulWidget {
  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final usuarioService = UsuarioService();
  
  Map<String, dynamic>? usuario;
  bool cargando = true;
  String? error;
  
  @override
  void initState() {
    super.initState();
    cargarPerfil();
  }
  
  void cargarPerfil() async {
    setState(() => cargando = true);
    
    final resultado = await usuarioService.obtenerPerfil();
    
    if (!mounted) return;
    
    if (resultado['success']) {
      setState(() {
        usuario = resultado['usuario'];
        error = null;
      });
    } else {
      setState(() => error = resultado['error']);
      
      if (resultado['code'] == 'AUTH_EXPIRED') {
        Future.delayed(Duration(seconds: 2), () {
          Navigator.of(context).pushReplacementNamed('/login');
        });
      }
    }
    
    setState(() => cargando = false);
  }
  
  void irEditar() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditarPerfilScreen(usuarioInicial: usuario!),
      ),
    );
    
    if (resultado != null) {
      setState(() => usuario = resultado);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mi Perfil'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: !cargando && usuario != null ? irEditar : null,
            tooltip: 'Editar s perfil',
          ),
        ],
      ),
      body: cargando
          ? Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(error!),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: cargarPerfil,
                        child: Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.blue.shade100,
                        child: Text(
                          usuario!['nombre'][0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      
                      // Nombre
                      Text(
                        usuario!['nombre'],
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      // Rol
                      Text(
                        _getRolNombre(usuario!['id_rol']),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 32),
                      
                      // Información
                      _buildInfoCard(
                        icon: Icons.email,
                        label: 'Email',
                        valor: usuario!['email'],
                        color: Colors.blue,
                      ),
                      SizedBox(height: 16),
                      
                      _buildInfoCard(
                        icon: Icons.phone,
                        label: 'Teléfono',
                        valor: usuario!['telefono'] ?? 'No registrado',
                        color: Colors.green,
                      ),
                      SizedBox(height: 16),
                      
                      _buildInfoCard(
                        icon: Icons.calendar_today,
                        label: 'Miembro desde',
                        valor: _formatoFecha(usuario!['created_at']),
                        color: Colors.orange,
                      ),
                      SizedBox(height: 32),
                      
                      // Status
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: usuario!['activo'] ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: usuario!['activo'] ? Colors.green : Colors.red,
                          ),
                        ),
                        child: Text(
                          usuario!['activo'] ? '✅ Cuenta Activa' : '❌ Cuenta Inactiva',
                          style: TextStyle(
                            color: usuario!['activo'] ? Colors.green.shade700 : Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
  
  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String valor,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  valor,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _getRolNombre(int idRol) {
    const roles = {
      1: 'Cliente / Conductor',
      2: 'Gerente Taller',
      3: 'Técnico',
      4: 'Administrador',
    };
    return roles[idRol] ?? 'Desconocido';
  }
  
  String _formatoFecha(String fecha) {
    final dt = DateTime.parse(fecha);
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
