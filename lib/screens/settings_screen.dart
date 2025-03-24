import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _darkMode = false;
  bool _notifications = true;
  bool _emailAlerts = true;
  String _language = 'Español';
  final List<String> _languages = ['Español', 'English', 'Português', 'Français'];

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isAdmin = authService.isAdmin;
    
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vacabox',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    authService.currentUser?.name ?? 'Usuario',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    authService.currentUser?.email ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  if (isAdmin)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Admin',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/dashboard');
              },
            ),
            if (isAdmin) ...[
              ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: const Text('Envíos'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/shipments');
                },
              ),
              ListTile(
                leading: const Icon(Icons.local_shipping_outlined),
                title: const Text('Seguimiento'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/tracking');
                },
              ),
              ListTile(
                leading: const Icon(Icons.inventory_outlined),
                title: const Text('Almacén'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/warehouse');
                },
              ),
              ListTile(
                leading: const Icon(Icons.people_outline),
                title: const Text('Clientes'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/customers');
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: const Text('Facturación'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/billing');
                },
              ),
              ListTile(
                leading: const Icon(Icons.bar_chart_outlined),
                title: const Text('Reportes'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/reports');
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.shopping_cart_outlined),
                title: const Text('Mis Productos'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/products');
                },
              ),
              ListTile(
                leading: const Icon(Icons.credit_card_outlined),
                title: const Text('Realizar Pago'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/payments');
                },
              ),
              ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: const Text('Mis Envíos'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/my-shipments');
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Mi Perfil'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/profile');
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Configuración'),
              selected: true,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: () {
                authService.logout();
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Apariencia'),
          _buildSettingCard(
            title: 'Modo oscuro',
            description: 'Cambiar entre modo claro y oscuro',
            trailing: Switch(
              value: _darkMode,
              onChanged: (value) {
                setState(() {
                  _darkMode = value;
                });
              },
              activeColor: AppTheme.primaryColor,
            ),
          ),
          _buildSettingCard(
            title: 'Idioma',
            description: 'Seleccionar el idioma de la aplicación',
            trailing: DropdownButton<String>(
              value: _language,
              onChanged: (String? newValue) {
                setState(() {
                  _language = newValue!;
                });
              },
              items: _languages.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              underline: Container(),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('Notificaciones'),
          _buildSettingCard(
            title: 'Notificaciones push',
            description: 'Recibir notificaciones en el dispositivo',
            trailing: Switch(
              value: _notifications,
              onChanged: (value) {
                setState(() {
                  _notifications = value;
                });
              },
              activeColor: AppTheme.primaryColor,
            ),
          ),
          _buildSettingCard(
            title: 'Alertas por correo',
            description: 'Recibir alertas por correo electrónico',
            trailing: Switch(
              value: _emailAlerts,
              onChanged: (value) {
                setState(() {
                  _emailAlerts = value;
                });
              },
              activeColor: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('Cuenta'),
          _buildSettingCard(
            title: 'Información personal',
            description: 'Actualizar datos de perfil',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
          _buildSettingCard(
            title: 'Cambiar contraseña',
            description: 'Actualizar contraseña de acceso',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navegar a la pantalla de cambio de contraseña
            },
          ),
          _buildSettingCard(
            title: 'Preferencias de privacidad',
            description: 'Gestionar configuración de privacidad',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navegar a la pantalla de preferencias de privacidad
            },
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('Información'),
          _buildSettingCard(
            title: 'Acerca de',
            description: 'Información sobre la aplicación',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showAboutDialog();
            },
          ),
          _buildSettingCard(
            title: 'Términos y condiciones',
            description: 'Leer términos de uso del servicio',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Mostrar términos y condiciones
            },
          ),
          _buildSettingCard(
            title: 'Política de privacidad',
            description: 'Leer política de privacidad',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Mostrar política de privacidad
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _showLogoutConfirmation();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String description,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(description),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Acerca de Vacabox'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Vacabox Courier App'),
              SizedBox(height: 8),
              Text('Versión: 1.0.0'),
              SizedBox(height: 8),
              Text('© 2025 Vacabox. Todos los derechos reservados.'),
              SizedBox(height: 16),
              Text(
                'Aplicación de gestión para servicios de courier y paquetería internacional.',
                style: TextStyle(
                  color: AppTheme.mutedTextColor,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text('¿Está seguro que desea cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Provider.of<AuthService>(context, listen: false).logout();
                Navigator.pushReplacementNamed(context, '/');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );
  }
}

