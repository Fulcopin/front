import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';
import '../models/product_model.dart';
import '../services/product_service.dart';
import '../services/user_service.dart';
import '../services/image_service.dart';
import '../theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AdminAlertsScreen extends StatefulWidget {
  const AdminAlertsScreen({Key? key}) : super(key: key);

  @override
  State<AdminAlertsScreen> createState() => _AdminAlertsScreenState();
}

class _AdminAlertsScreenState extends State<AdminAlertsScreen> {
  final _storage = const FlutterSecureStorage();
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for form fields
  final _tiendaController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _trackingController = TextEditingController();
  final _precioController = TextEditingController();
  final _pesoController = TextEditingController();
  final ProductService _productService = ProductService();
  final UserService _userService = UserService();
  final CloudinaryService _imageService = CloudinaryService();
  
  // Status options
  final List<String> _statusOptions = [
    'Pendiente',
    'En proceso',
    'Recibido',
    'En bodega',
    'Listo para envío',
    'Enviado',
    'Entregado',
    'Cancelado'
  ];
  
  String _selectedStatus = 'Pendiente'; // Default status
  
  bool _isLoading = true;
  String? _errorMessage;
  
  File? _facturaImage;
  final _picker = ImagePicker();
  
  // Default image URL to use if no image is provided
  final String _defaultImageUrl = 'https://media.istockphoto.com/id/1186665850/es/vector/cami%C3%B3n-de-entrega-de-env%C3%ADo-r%C3%A1pido-dise%C3%B1o-de-icono-de-l%C3%ADnea-ilustraci%C3%B3n-vectorial-para.jpg?s=612x612&w=0&k=20&c=4IODuEWsnMLEgriQF7rOu3mN3CXtXVmQPVgJngit0jE=';
  
  // List of users and selected user ID
  List<Map<String, dynamic>> _users = [];
  String? _selectedUserId;
  
  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    _loadUsers();
  }
  
  @override
  void dispose() {
    _tiendaController.dispose();
    _descripcionController.dispose();
    _trackingController.dispose();
    _precioController.dispose();
    
    super.dispose();
  }
 // Update your _checkAuthentication method
Future<void> _checkAuthentication() async {
  final userId = await _storage.read(key: 'userId');
  final token = await _storage.read(key: 'token');
  
  // Check all possible admin flags
  final isAdmin = await _storage.read(key: 'isAdmin');
  final role = await _storage.read(key: 'role');
  final userRole = await _storage.read(key: 'userRole');
  
  print('Auth check: userId=$userId, token=${token != null}, isAdmin=$isAdmin, role=$role, userRole=$userRole');
  
  // Check multiple possible admin indicators with case-insensitive comparison
  bool hasAdminAccess = isAdmin == 'true' || 
                        role?.toLowerCase() == 'admin' || 
                        userRole?.toLowerCase() == 'admin';
  
  if (userId == null || token == null || !hasAdminAccess) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Acceso restringido. Redirigiendo...'))
      );
      Navigator.of(context).pushReplacementNamed('/login');
    }
  } else {
    print('Authentication successful - user is admin with role: $role');
    // Continue loading data
  }
}
  Future<void> _loadUsers() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      final token = await _storage.read(key: 'token');
      
      if (token != null) {
        final users = await _userService.getAllUsers(token: token);
        
        setState(() {
          _users = users;
          _isLoading = false;
        });
      } else {
        throw Exception('Token no encontrado');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error cargando usuarios: ${e.toString()}';
        _isLoading = false;
      });
      print('Error loading users: $e');
    }
  }
  
  // Implement your pick image method
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _facturaImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      setState(() {
        _errorMessage = 'Error al cargar la imagen: $e';
      });
    }
  }
  
  // Add the submit form method
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedUserId == null) {
        setState(() {
          _errorMessage = 'Por favor selecciona un cliente';
        });
        return;
      }
      
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final adminId = await _storage.read(key: 'userId');
        final token = await _storage.read(key: 'token');
        
        if (adminId == null || token == null) {
          throw Exception('Sesión expirada. Por favor inicia sesión nuevamente.');
        }

        // Get selected user's email
        final selectedUser = _users.firstWhere((user) => user['_id'] == _selectedUserId || user['id'] == _selectedUserId);
        
        // Validate and parse values
        double precio = _precioController.text.isEmpty ? 0 : double.parse(_precioController.text.trim());
        double peso = 0; // Default to 0
        try {
          if (_pesoController.text.isNotEmpty) {
            peso = double.parse(_pesoController.text.trim());
          }
        } catch (e) {
          print('Error parsing peso: ${_pesoController.text}');
        }
        int cantidad = 1; // Default to 1

        // Upload image if available
        String? facturaUrl;
        try {
          if (_facturaImage != null) {
            facturaUrl = await CloudinaryService.uploadImage(_facturaImage!);
            print('Imagen subida: $facturaUrl');
          }
        } catch (e) {
          print('Error subiendo imagen: $e');
          // Continue with default image if upload fails
        }

        // Create product with the alert details
        final newAlert = Product(
          id:'',  // Empty for new product
          id_user: _selectedUserId!, // Use selected user ID
          nombre: _tiendaController.text,
          descripcion: _descripcionController.text,
          peso: peso,
          precio: precio,
          cantidad: cantidad,
          link: _trackingController.text,
          // Use default image if no image was uploaded
          imagenUrl: facturaUrl ?? _defaultImageUrl,
          facturaUrl: facturaUrl,
          fechaCreacion: DateTime.now(),
         // status: _selectedStatus, // Same as estado
        );
        
        print('Enviando alerta al servidor...');
        final addedProduct = await _productService.addProductAdmin(newAlert);
        print('Alerta guardada con ID: ${addedProduct.id}');
        
        // Send email notification
        await _productService.sendEmailNotification(
                email: selectedUser['email'],
                productName: _tiendaController.text,
                status: _selectedStatus,
                additionalMessage: 'Mensaje adicional sobre el producto si es necesario.'
              );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Alerta registrada y notificación enviada exitosamente'))
          );
          
          Navigator.pop(context);
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Error: ${e.toString()}';
          _isLoading = false;
        });
        print('Error final: $_errorMessage');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Alerta para Cliente'),
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading && _users.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 16),
                      color: Colors.red.shade100,
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  
                  // User selection dropdown
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Seleccionar Cliente',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                      hintText: 'Selecciona un cliente',
                    ),
                    value: _selectedUserId,
                    items: _users.map((user) {
                      return DropdownMenuItem<String>(
                        value: user['_id'] ?? user['id'] ?? '',
                        child: Text('${user['nombre'] ?? 'Unknown'} (${user['email'] ?? ''})'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedUserId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor selecciona un cliente';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  
                  // Status dropdown
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Estado del producto',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.inventory_2),
                    ),
                    value: _selectedStatus,
                    items: _statusOptions.map((status) {
                      return DropdownMenuItem<String>(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value!;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor selecciona un estado';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  
                  // Rest of your form fields
                  TextFormField(
                    controller: _tiendaController,
                    decoration: InputDecoration(
                      labelText: 'Título de la Alerta',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.warning),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa un título para la alerta';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _descripcionController,
                    decoration: InputDecoration(
                      labelText: 'Descripción de la Alerta',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa una descripción';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _trackingController,
                    decoration: InputDecoration(
                      labelText: 'Tracking relacionado (opcional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.local_shipping),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
  controller: _precioController,
  decoration: InputDecoration(
    labelText: 'Precio del producto',
    border: OutlineInputBorder(),
    prefixIcon: Icon(Icons.attach_money),
    prefixText: '\$',
  ),
  keyboardType: const TextInputType.numberWithOptions(decimal: true),
  inputFormatters: [
    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
  ],
  validator: (value) {
    if (value != null && value.isNotEmpty) {
      try {
        double.parse(value);
      } catch (e) {
        return 'Ingrese un valor numérico válido';
      }
    }
    return null;
  },
),
SizedBox(height: 16),
TextFormField(
  controller: _pesoController,
  decoration: InputDecoration(
    labelText: 'Peso del producto (libras)',
    border: OutlineInputBorder(),
    prefixIcon: Icon(Icons.scale),
    suffixText: 'lb',
  ),
  keyboardType: const TextInputType.numberWithOptions(decimal: true),
  inputFormatters: [
    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
  ],
  validator: (value) {
    if (value != null && value.isNotEmpty) {
      try {
        double.parse(value);
      } catch (e) {
        return 'Ingrese un valor numérico válido';
      }
    }
    return null;
  },
),
SizedBox(height: 16),
                  TextFormField(
                    controller: _precioController,
                    decoration: InputDecoration(
                      labelText: 'Monto de la Alerta (opcional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                      prefixText: '\$',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                  ),
                  SizedBox(height: 16),
                  
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Imagen adjunta:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Esta imagen es opcional. Si no se proporciona, se usará una imagen por defecto.',
                        style: TextStyle(color: AppTheme.mutedTextColor, fontSize: 14),
                      ),
                      SizedBox(height: 12),
                      
                      InkWell(
                        onTap: _pickImage,
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _facturaImage != null 
                                  ? AppTheme.primaryColor 
                                  : Colors.grey,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _facturaImage != null
                              ? kIsWeb
                                  ? Image.network(_facturaImage!.path, fit: BoxFit.cover)
                                  : Image.file(_facturaImage!, fit: BoxFit.cover)
                              : Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text('Toca para agregar imagen'),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 32),
                  
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.primaryColor,
                    ),
                    child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Enviar Alerta al Cliente',
                          style: TextStyle(fontSize: 16),
                        ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}