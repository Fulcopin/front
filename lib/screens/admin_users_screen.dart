import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/user_service.dart';
import '../theme.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({Key? key}) : super(key: key);

  @override
  _AdminUsersScreenState createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final UserService _userService = UserService();
  final storage = FlutterSecureStorage();
  
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = false;
  String _searchQuery = "";
  
  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });
    final token = await storage.read(key: 'token');
    try {
      final users = await _userService.getAllUsers(token: token!);
      setState(() {
        _users = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar usuarios: $e')),
      );
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredUsers = _users;
      } else {
        _filteredUsers = _users.where((user) {
          final nombre = user['nombre']?.toString().toLowerCase() ?? '';
          final apellido = user['apellido']?.toString().toLowerCase() ?? '';
          final email = user['email']?.toString().toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          
          return nombre.contains(searchLower) || 
                apellido.contains(searchLower) || 
                email.contains(searchLower);
        }).toList();
      }
    });
  }

  Future<void> _showUserProductsDialog(Map<String, dynamic> user) async {
    setState(() {
      _isLoading = true;
    });
    
    final token = await storage.read(key: 'token');
    try {
      final products = await _userService.getUserWarehouseProducts(
        token: token!,
        userId: user['id'],
      );
      
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Productos en bodega de ${user['nombre']} ${user['apellido']}'),
          content: SizedBox(
            width: double.maxFinite,
            child: products.isEmpty 
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text('No hay productos en bodega para este usuario'),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ListTile(
                      title: Text(product['nombre'] ?? 'Sin nombre'),
                      subtitle: Text(product['descripcion'] ?? 'Sin descripción'),
                      trailing: Text('${product['peso']} lb'),
                    );
                  },
                ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar productos: $e')),
      );
    }
  }
  
  void _showEditUserDialog(Map<String, dynamic> user) {
    final nombreController = TextEditingController(text: user['nombre']);
    final apellidoController = TextEditingController(text: user['apellido']);
    final emailController = TextEditingController(text: user['email']);
    final telefonoController = TextEditingController(text: user['telefono']);
    final direccionController = TextEditingController(text: user['direccion']);
    final ciudadController = TextEditingController(text: user['ciudad']);
    final paisController = TextEditingController(text: user['pais']);
    final passwordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Usuario'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: apellidoController,
                decoration: const InputDecoration(labelText: 'Apellido'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: telefonoController,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: direccionController,
                decoration: const InputDecoration(labelText: 'Dirección'),
              ),
              TextField(
                controller: ciudadController,
                decoration: const InputDecoration(labelText: 'Ciudad'),
              ),
              TextField(
                controller: paisController,
                decoration: const InputDecoration(labelText: 'País'),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Nueva Contraseña (dejar en blanco para no cambiar)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Nueva Contraseña'),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Update user information
              final updatedUserData = {
                'nombre': nombreController.text,
                'apellido': apellidoController.text,
                'email': emailController.text,
                'telefono': telefonoController.text,
                'direccion': direccionController.text,
                'ciudad': ciudadController.text,
                'pais': paisController.text,
              };
              
              Navigator.of(context).pop();
              
              setState(() {
                _isLoading = true;
              });
              
              final token = await storage.read(key: 'token');
              try {
                // Update user data
                await _userService.updateUser(
                  token: token!,
                  userId: user['id'],
                  userData: updatedUserData,
                );
                
                // Update password if provided
                if (passwordController.text.isNotEmpty) {
                  await _userService.updateUserPassword(
                    token: token,
                    userId: user['id'],
                    newPassword: passwordController.text,
                  );
                }
                
                // Refresh the user list
                await _loadUsers();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Usuario actualizado correctamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                setState(() {
                  _isLoading = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al actualizar usuario: $e')),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administración de Usuarios'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _filterUsers,
              decoration: InputDecoration(
                hintText: 'Buscar usuarios...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              ),
            ),
          ),
          
          // Loading indicator or user count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Total: ${_filteredUsers.length} usuarios',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                const Spacer(),
                if (_searchQuery.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _filteredUsers = _users;
                      });
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Limpiar'),
                  ),
              ],
            ),
          ),
          
          // User list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? const Center(
                        child: Text('No se encontraron usuarios'),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadUsers,
                        child: ListView.builder(
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = _filteredUsers[index];
                            
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text(
                                    (user['nombre']?.toString().substring(0, 1) ?? '').toUpperCase(),
                                  ),
                                ),
                                title: Text(
                                  '${user['nombre'] ?? ''} ${user['apellido'] ?? ''}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(user['email'] ?? 'No email'),
                                    if (user['telefono'] != null) 
                                      Text('Tel: ${user['telefono']}'),
                                    if (user['direccion'] != null || user['ciudad'] != null)
                                      Text(
                                        [
                                          user['direccion'], 
                                          user['ciudad'], 
                                          user['pais']
                                        ].where((s) => s != null && s.isNotEmpty).join(', ')
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _showEditUserDialog(user),
                                      tooltip: 'Editar usuario',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.inventory, color: Colors.orange),
                                      onPressed: () => _showUserProductsDialog(user),
                                      tooltip: 'Ver productos en bodega',
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadUsers,
        tooltip: 'Refrescar',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}