import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/shipment_service.dart';
import '../services/payment_service.dart';
import '../services/user_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/product_service.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
class PagosYEnviosScreen extends StatefulWidget {
  const PagosYEnviosScreen({Key? key}) : super(key: key);

  @override
  _PagosYEnviosScreenState createState() => _PagosYEnviosScreenState();
}

class _PagosYEnviosScreenState extends State<PagosYEnviosScreen> with SingleTickerProviderStateMixin {
  // Controllers
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _trackingController = TextEditingController();
  final _originController = TextEditingController(text: 'Miami, FL');
  final _destinationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _refNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _productSearchController = TextEditingController();

  // Services
  final ShipmentService _shipmentService = ShipmentService();
  final PaymentService _paymentService = PaymentService();
  final UserService _userService = UserService();
  final ProductService _productService = ProductService();
  
  // State variables
  bool _isLoading = false;
  bool _loadingUsers = false;
  String _errorMessage = '';
  List<Map<String, dynamic>> _usersList = [];
  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> _shipments = [];
  String? _selectedUserId;
  String? _selectedPaymentId;
  DateTime _estimatedDeliveryDate = DateTime.now().add(Duration(days: 7));
  String _paymentMethod = 'Transferencia Bancaria';
  List<Map<String, dynamic>> _warehouseProducts = [];
List<String> _selectedProductIds = [];
bool _loadingWarehouseProducts = false;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUsers();
    _fetchPayments();
    _fetchShipments();
    _loadWarehouseProducts();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _trackingController.dispose();
    _originController.dispose();
    _destinationController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }
  // Update the _loadWarehouseProducts method
Future<void> _loadWarehouseProducts() async {
  if (_selectedUserId == null) {
    setState(() {
      _warehouseProducts = [];
      _loadingWarehouseProducts = false;
    });
    return;
  }
  
  setState(() {
    _loadingWarehouseProducts = true;
  });
  
  try {
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    
    if (token != null) {
      // Get warehouse products for the selected user
      final result = await _productService.getWarehouseProductsByUser(
        _selectedUserId!,
        token: token
      );
      
      setState(() {
        _warehouseProducts = result;
        _loadingWarehouseProducts = false;
      });
      
      print('Loaded ${result.length} warehouse products for user: $_selectedUserId');
    }
  } catch (e) {
    print('Error loading warehouse products: $e');
    setState(() {
      _loadingWarehouseProducts = false;
      _warehouseProducts = [];
    });
    
    // Show non-blocking error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('No se pudieron cargar los productos en bodega para este usuario'),
        backgroundColor: Colors.orange,
      )
    );
  }
}

String _generateTrackingNumber() {
  final random = Random();
  final prefix = 'VB-';
  final number = 90000000000 + random.nextInt(9999999);
  return '$prefix$number';
}
  Future<void> _loadUsers() async {
    setState(() {
      _loadingUsers = true;
    });
    
    try {
      final storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      
      if (token != null) {
        final users = await _userService.getAllUsers(token: token);
        
        setState(() {
          _usersList = users;
          _loadingUsers = false;
        });
      }
    } catch (e) {
      print('Error loading users: $e');
      setState(() {
        _loadingUsers = false;
        _errorMessage = 'Error al cargar usuarios: $e';
      });
    }
  }
  
  Future<void> _fetchPayments() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      
      if (token != null) {
        final result = await _paymentService.getAdminPayments(token: token);
        
        setState(() {
          _payments = result['payments'];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching payments: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al cargar pagos: $e';
      });
    }
  }
  
  Future<void> _fetchShipments() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      
      if (token != null) {
        final result = await _shipmentService.getAdminShipments(token: token);
        
        setState(() {
          _shipments = result['shipments'];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching shipments: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al cargar envíos: $e';
      });
    }
  }
  
  Future<void> _registerPayment() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final storage = FlutterSecureStorage();
        final token = await storage.read(key: 'token');
        
        if (token != null) {
          // Preparar datos del pago
          final paymentData = {
            'userId': _selectedUserId,
            'monto': double.parse(_amountController.text),
            'metodoPago': _paymentMethod,
            'descripcion': _descriptionController.text,
            'estado': 'Aprobado', // Marcarlo como aprobado directamente
          };
          
          // Registrar pago
          final result = await _paymentService.createPayment(
            token: token,
            paymentData: paymentData,
          );
          
          // Extraer el ID de pago de la respuesta
          final String pagoId = result['pagoId']?.toString() ?? '';
          
          if (pagoId.isNotEmpty) {
            // Ahora crear el envío asociado a este pago
            final shipmentData = {
              'userId': _selectedUserId,
              'origen': 'Miami, FL',
              'direccion': _destinationController.text.isNotEmpty ? 
                  _destinationController.text : 
                  await _getUserAddress(_selectedUserId!),
              'pagoId': pagoId,
              'estado': 'Procesando',
            };
            
            // Crear envío usando el ID de pago
            final shipmentResult = await _shipmentService.registerShipment(
              token: token,
              direccion: shipmentData['direccion'] as String,
              pagoId: pagoId,
              origen: shipmentData['origen'] as String,
            );
            
            setState(() {
              _isLoading = false;
            });
            
            // Refrescar listas después de crear
            _fetchPayments();
            _fetchShipments();
            
            // Mostrar mensaje de éxito
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Pago registrado y envío creado automáticamente'),
                backgroundColor: Colors.green,
              )
            );
            
            // Limpiar formulario
            _formKey.currentState?.reset();
            _amountController.clear();
            _descriptionController.clear();
            _destinationController.clear();
            setState(() {
              _selectedUserId = null;
              _paymentMethod = 'Transferencia Bancaria';
            });
          } else {
            throw Exception('No se obtuvo ID de pago desde el servidor');
          }
        }
      } catch (e) {
        print('Error registering payment and creating shipment: $e');
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar pago y crear envío: $e'),
            backgroundColor: Colors.red,
          )
        );
      }
    }
  }
  
  // Helper method to get user's address from their ID
  Future<String> _getUserAddress(String userId) async {
    try {
      final storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      
      if (token != null) {
        // Get user details from UserService
        final userData = await _userService.getUserDetails(userId, token: token);
        
        // Construct address from available fields
        final direccion = userData['direccion'] ?? '';
        final ciudad = userData['ciudad'] ?? '';
        final pais = userData['pais'] ?? '';
        
        final fullAddress = [direccion, ciudad, pais]
            .where((part) => part.isNotEmpty)
            .join(', ');
        
        return fullAddress.isNotEmpty ? fullAddress : 'Dirección no disponible';
      }
      return 'Dirección no disponible';
    } catch (e) {
      print('Error getting user address: $e');
      return 'Dirección no disponible';
    }
  }
  
  void _showPaymentDetails(Map<String, dynamic> payment) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Detalles del Pago'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('ID: ${payment['id']}'),
                SizedBox(height: 8),
                Text('Cliente: ${payment['usuario']['nombre']  ?? 'No disponible'}'),
                SizedBox(height: 8),
                Text('Monto: \$${payment['monto']?.toStringAsFixed(2) ?? '0.00'}'),
                SizedBox(height: 8),
                Text('Método: ${payment['metodo'] ?? 'No disponible'}'),
                SizedBox(height: 8),
                Text('Estado: ${payment['estado'] ?? 'Pendiente'}'),
                SizedBox(height: 8),
                Text('Fecha: ${_formatDate(payment['fecha'])}'),
                SizedBox(height: 16),
                Text('Descripción:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(payment['descripcion'] ?? 'Sin descripción'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cerrar'),
            ),
            ElevatedButton(
              onPressed: payment['estado'] == 'Pendiente' ? () {
                Navigator.pop(context);
                _approvePayment(payment['id']);
              } : null,
              child: Text('Aprobar Pago'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _createShipmentFromPayment(payment);
              },
              child: Text('Crear Envío'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _approvePayment(String paymentId) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      
      if (token != null) {
        // Llamar al método para aprobar pago
        await _paymentService.approvePayment(paymentId, token: token);
        
        // Refrescar lista de pagos
        await _fetchPayments();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pago aprobado correctamente'),
            backgroundColor: Colors.green,
          )
        );
      }
    } catch (e) {
      print('Error approving payment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al aprobar pago: $e'),
          backgroundColor: Colors.red,
        )
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _createShipmentFromPayment(Map<String, dynamic> payment) {
    // Pre-llenar la dirección si está disponible
    _destinationController.text = '';
    
    // Pre-seleccionar el usuario
    setState(() {
      _selectedUserId = payment['userId'];
      _selectedPaymentId = payment['id'];
    });
    
    // Cambiar a la pestaña de crear envío
    _tabController.animateTo(0);
    
    // Mostrar mensaje informativo
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Complete los detalles del envío'),
        duration: Duration(seconds: 3),
      )
    );
  }
  
  String _formatDate(dynamic date) {
    if (date == null) return 'Fecha no disponible';
    
    try {
      DateTime dateTime;
      
      if (date is String) {
        dateTime = DateTime.parse(date);
      } else if (date is int) {
        dateTime = DateTime.fromMillisecondsSinceEpoch(date * 1000);
      } else {
        return date.toString();
      }
      
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      return 'Fecha inválida';
    }
  }
  
  // Define color para el estado del pago
  Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'aprobado':
        return Colors.green;
      case 'pendiente':
        return Colors.orange;
      case 'rechazado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestión de Pagos y Envíos'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.payment), text: 'Pagos'),
            Tab(icon: Icon(Icons.local_shipping), text: 'Crear Envío'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPaymentsTab(),
          _buildCreateShipmentForm(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Refrescar datos
          _fetchPayments();
          _fetchShipments();
        },
        child: Icon(Icons.refresh),
        tooltip: 'Refrescar datos',
      ),
    );
  }
  
  Widget _buildPaymentsTab() {
    return RefreshIndicator(
      onRefresh: _fetchPayments,
      child: _isLoading 
          ? Center(child: CircularProgressIndicator())
          : _payments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.payment, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No hay pagos disponibles'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _payments.length,
                  itemBuilder: (context, index) {
                    final payment = _payments[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getPaymentStatusColor(payment['estado'] ?? 'Pendiente').withOpacity(0.2),
                          child: Icon(
                            Icons.payment,
                            color: _getPaymentStatusColor(payment['estado'] ?? 'Pendiente'),
                          ),
                        ),
                        title: Text(
                          payment['nombreUsuario'] ?? 'Cliente ${payment['usuario']['nombre']}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('\$${payment['monto']?.toStringAsFixed(2) ?? '0.00'} - ${payment['metodo'] ?? 'Método no especificado'}'),
                            SizedBox(height: 4),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getPaymentStatusColor(payment['estado'] ?? 'Pendiente').withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                payment['estado'] ?? 'Pendiente',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getPaymentStatusColor(payment['estado'] ?? 'Pendiente'),
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.visibility),
                          onPressed: () => _showPaymentDetails(payment),
                        ),
                        onTap: () => _showPaymentDetails(payment),
                      ),
                    );
                  },
                ),
    );
  }

// Actualiza el formulario para incluir selección de productos
Widget _buildCreateShipmentForm() {
  return SingleChildScrollView(
    padding: EdgeInsets.all(16),
    child: Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Registrar Pago y Envío',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 24),
              
              // Selección de cliente
              _loadingUsers
                  ? Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Cliente',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      value: _selectedUserId,
                      hint: Text('Seleccionar cliente'),
                      isExpanded: true,
                      items: _usersList.map((user) {
                        return DropdownMenuItem<String>(
                          value: user['id'],
                          child: Text('${user['nombre'] ?? ''} ${user['apellido'] ?? ''} (${user['email'] ?? ''})'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedUserId = value;
                           _selectedProductIds = []; 
                        });
                        _loadWarehouseProducts();
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor seleccione un cliente';
                        }
                        return null;
                      },
                    ),
              SizedBox(height: 24),
              
              // NUEVA SECCIÓN: Selección de productos en bodega
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.inventory_2, color: Colors.amber.shade700),
                        SizedBox(width: 8),
                        Text(
                          'Productos en Bodega',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    
                    // Buscador de productos
                    TextFormField(
                      controller: _productSearchController,
                      decoration: InputDecoration(
                        labelText: 'Buscar productos en bodega',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    // Lista de productos en bodega
                    _loadingWarehouseProducts
                        ? Center(child: CircularProgressIndicator())
                        : _warehouseProducts.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text('No hay productos en bodega disponibles'),
                                ),
                              )
                            : Container(
                                constraints: BoxConstraints(maxHeight: 250),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _warehouseProducts.length,
                                  itemBuilder: (context, index) {
                                    final product = _warehouseProducts[index];
                                    
                                    // Filtrar por búsqueda
                                    if (_productSearchController.text.isNotEmpty) {
                                      final searchTerm = _productSearchController.text.toLowerCase();
                                      final productName = (product['nombre'] ?? '').toLowerCase();
                                      final productDescription = (product['descripcion'] ?? '').toLowerCase();
                                      
                                      if (!productName.contains(searchTerm) && !productDescription.contains(searchTerm)) {
                                        return SizedBox.shrink();
                                      }
                                    }
                                    
                                    return CheckboxListTile(
                                      title: Text(product['nombre'] ?? 'Producto sin nombre'),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(product['descripcion'] ?? '', 
                                              maxLines: 1, overflow: TextOverflow.ellipsis),
                                          Text(
                                            'Recibido: ${_formatDate(product['fechaRecepcion'] ?? DateTime.now().toIso8601String())}',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                      secondary: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'En Bodega',
                                          style: TextStyle(fontSize: 12, color: Colors.green.shade800),
                                        ),
                                      ),
                                      value: _selectedProductIds.contains(product['id']),
                                      onChanged: (selected) {
                                        setState(() {
                                          if (selected!) {
                                            _selectedProductIds.add(product['id']);
                                            
                                            // Actualizar monto si está disponible
                                            if (product['precio'] != null) {
                                              double currentAmount = _amountController.text.isEmpty
                                                  ? 0
                                                  : double.parse(_amountController.text);
                                              _amountController.text = (currentAmount + double.parse(product['precio'].toString())).toStringAsFixed(2);
                                            }
                                          } else {
                                            _selectedProductIds.remove(product['id']);
                                            
                                            // Reducir monto si está disponible
                                            if (product['precio'] != null && _amountController.text.isNotEmpty) {
                                              double currentAmount = double.parse(_amountController.text);
                                              _amountController.text = (currentAmount - double.parse(product['precio'].toString())).toStringAsFixed(2);
                                            }
                                          }
                                        });
                                      },
                                      isThreeLine: true,
                                    );
                                  },
                                ),
                              ),
                    
                    SizedBox(height: 8),
                    if (_selectedProductIds.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          '${_selectedProductIds.length} productos seleccionados',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              
              // Información del pago - SIMPLIFICADO
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.payment, color: Colors.blue.shade700),
                        SizedBox(width: 8),
                        Text(
                          'Información de Pago',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    
                    // Monto
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'Monto Total',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El monto es requerido';
                        }
                        try {
                          double amount = double.parse(value);
                          if (amount <= 0) {
                            return 'El monto debe ser mayor a 0';
                          }
                        } catch (e) {
                          return 'Ingrese un monto válido';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Banco
                    TextFormField(
                      controller: _bankNameController,
                      decoration: InputDecoration(
                        labelText: 'Nombre del Banco',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.account_balance),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El nombre del banco es requerido';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Número de referencia
                    TextFormField(
                      controller: _refNumberController,
                      decoration: InputDecoration(
                        labelText: 'Número de Referencia',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.confirmation_number),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El número de referencia es requerido';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              
              // Información de envío
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.local_shipping, color: Colors.green.shade700),
                        SizedBox(width: 8),
                        Text(
                          'Información de Envío',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    
                    // Destino
                    TextFormField(
                      controller: _destinationController,
                      decoration: InputDecoration(
                        labelText: 'Dirección de Destino',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                        hintText: 'Si se deja en blanco, se usará la dirección del cliente',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'La dirección de destino es requerida';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              
              // Descripción
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Descripción u observaciones',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
              ),
              SizedBox(height: 24),
              
              // Botones de acción
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      // Limpiar formulario
                      _formKey.currentState?.reset();
                      _amountController.clear();
                      _descriptionController.clear();
                      _destinationController.clear();
                      _bankNameController.clear();
                      _refNumberController.clear();
                      setState(() {
                        _selectedUserId = null;
                        _selectedProductIds = [];
                      });
                    },
                    icon: Icon(Icons.clear),
                    label: Text('Limpiar'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _registerPaymentAndShipment,
                    icon: _isLoading 
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(Icons.save),
                    label: Text('Registrar Pago y Crear Envío'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// Reemplaza el método de registro de pago con esta versión actualizada
Future<void> _registerPaymentAndShipment() async {
  if (_formKey.currentState!.validate()) {
    if (_selectedProductIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Debe seleccionar al menos un producto en bodega'))
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      
      if (token != null) {
        // 1. Registrar el pago
        final now = DateTime.now();
        final paymentData = {
          'userId': _selectedUserId,
          'monto': double.parse(_amountController.text),
          'metodoPago': 'transferencia_bancaria',
          'estado': 'Aprobado',
          'descripcion': _descriptionController.text,
          'productos': _selectedProductIds,
          'fecha': now.toIso8601String(),
          'detalles': {
            'banco': _bankNameController.text,
            'numeroReferencia': _refNumberController.text,
            'fecha': now.toIso8601String(),
          }
        };
        
        final paymentResult = await _paymentService.createPayment(
          token: token,
          paymentData: paymentData,
        );
        
        final String pagoId = paymentResult['pagoId']?.toString() ?? '';
        
        if (pagoId.isEmpty) {
          throw Exception('No se pudo obtener el ID del pago');
        }
        
        // 2. Registrar el envío con seguimiento
        final trackingNumber = _generateTrackingNumber();
        final estimatedDelivery = now.add(Duration(days: 7)); // Fecha estimada a 7 días
        
        final inicialEvent = {
          'estado': 'En Bodega',
          'descripcion': 'Paquete registrado en el sistema',
          'ubicacion': 'Miami, FL',
          'fecha': now.toIso8601String(),
        };
        
        final shipmentData = {
          'userId': _selectedUserId,
          'direccion': _destinationController.text,
          'origen': 'Miami, FL',
          'estado': 'En bodega',
          'pagoId': pagoId,
          'productos': _selectedProductIds,
          'trackingNumber': trackingNumber,
          'fechaEstimada': estimatedDelivery.toIso8601String(),
          'fecha': now.toIso8601String(),
          'eventos': [inicialEvent],
        };
        
        // Registrar el envío
        final shipmentResult = await _shipmentService.createDetailedShipment(
          token: token,
          shipmentData: shipmentData,
        );
        final ProductService _productService = ProductService();
        bool allProductsUpdated = true;
for (String productId in _selectedProductIds) {
  final updated = await _productService.updateProductStatus(
    productId, 
    'Pagado',  
  );
  
  if (!updated) {
    allProductsUpdated = false;
    print('Failed to update status for product: $productId');
  }
}

if (!allProductsUpdated) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Algunos productos no pudieron actualizarse correctamente'),
      backgroundColor: Colors.orange,
    )
  );
  }
        
        setState(() {
          _isLoading = false;
        });
        
        // Refrescar datos
        _fetchPayments();
        _fetchShipments();
        _loadWarehouseProducts(); // Recargar productos en bodega
        
        // Mostrar mensaje de éxito con detalles del tracking
        _showSuccessDialog(trackingNumber);
        
        // Limpiar formulario
        _formKey.currentState?.reset();
        _amountController.clear();
        _descriptionController.clear();
        _destinationController.clear();
        _bankNameController.clear();
        _refNumberController.clear();
        setState(() {
          _selectedUserId = null;
          _selectedProductIds = [];
        });
        
      }
    } catch (e) {
      print('Error registering payment and shipment: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        )
      );
    }
  }
}

// Método para mostrar un diálogo de éxito con los detalles del envío
void _showSuccessDialog(String trackingNumber) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 28),
          SizedBox(width: 8),
          Text('¡Operación Exitosa!'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Se ha registrado el pago y creado el envío con éxito.'),
          SizedBox(height: 16),
          Text('Detalles del envío:', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Número de seguimiento:'),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      trackingNumber,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    IconButton(
                      icon: Icon(Icons.copy, size: 20),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: trackingNumber));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Número de seguimiento copiado'))
                        );
                      },
                      tooltip: 'Copiar al portapapeles',
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Text('Estado: En bodega', style: TextStyle(color: Colors.amber.shade800)),
          Text('Ubicación: Miami, FL'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cerrar'),
        ),
      ],
    ),
  );
}
Future<void> _updateProductStatus(String productId, String newStatus, String token) async {
  try {
    await http.put(
      Uri.parse('${ApiConfig.baseUrl}/admin/productos/$productId/estado'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
      body: json.encode({'estado': newStatus}),
    );
  } catch (e) {
    print('Error updating product status: $e');
  }

}
}
