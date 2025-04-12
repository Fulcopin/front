import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import '../services/stats_service.dart';
import '../services/product_service.dart';
import '../services/notification_service.dart';
import '../widgets/admin_stats_overview.dart';
import '../widgets/admin_shipments_chart.dart';
import '../widgets/admin_products_table.dart';
import '../widgets/admin_notifications_panel.dart';
import '../widgets/admin_pending_payments.dart';
import '../models/notification_model.dart';
import '../models/product_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../screens/admin_shipement.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import './pagosyenvios_screen.dart'; 
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final StatsService _statsService = StatsService();
  final ProductService _productService = ProductService();
  final NotificationService _notificationService = NotificationService();
  int _currentPage = 1;
int _totalProducts = 0; 
int _pageLimit = 10;
  bool _isRedirecting = false;
Timer? _redirectionTimer;
  bool _initialized = false;
  bool _isLoadingStats = true;
  bool _isLoadingShipments = true;
  bool _isLoadingProducts = true;
  bool _isLoadingNotifications = true;
  bool _isLoadingPendingPayments = true;
  bool _isAuthenticating = false;
  Map<String, dynamic> _generalStats = {};
  List<Map<String, dynamic>> _shipmentsByMonth = [];
  List<Product> _products = [];
  List<NotificationModel> _notifications = [];
  List<Map<String, dynamic>> _pendingPayments = [];
  // Add these at the top of your class with other variables

bool _authError = false;
String _errorMessage = '';
Timer? _initTimeoutTimer;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
    prefs.setString('lastScreen', 'admin_dashboard');
  });
  _initTimeoutTimer = Timer(Duration(seconds: 10), () {
    if (mounted && !_initialized) {
      setState(() {
        _initialized = true;
        _authError = true;
        _errorMessage = 'Tiempo de espera agotado al verificar credenciales';
      });
    }
  });
  // Delay check to allow preferences to be set
  Future.delayed(Duration(milliseconds: 500), () {
    if (mounted) _verificarAutenticacionYCargarDatos();
  });
  }
  @override
void dispose() {
   _initTimeoutTimer?.cancel();
  _redirectionTimer?.cancel();
  super.dispose();
}
String _getDisplayStatus(String? status) {
  return status ?? 'En bodega';  // Default to "En bodega" if null
}
Future<void> _verificarAutenticacionYCargarDatos() async {
  // Prevent multiple checks
  if (_isRedirecting) return;
  
  try {
    _isRedirecting = true;
    final authService = Provider.of<AuthService>(context, listen: false);
    
    print('Verificando credenciales de administrador...');
    
    // Add a timeout to prevent indefinite waiting
    final token = await authService.getAuthToken().timeout(
      Duration(seconds: 5),
      onTimeout: () {
        print('Timeout getting token - forcing logout');
        return null;
      }
    );
    
    if (token == null) {
      print('No token found or timeout occurred - logging out');
      await authService.logout();
      
      if (mounted) {
       setState(() {
          _initialized = true;  // IMPORTANT: Set this to true
          _authError = true;
          _errorMessage = 'No se encontró token de autenticación';
        });
        Navigator.of(context).pushReplacementNamed('/login');
      }
      return;
    }
    
    // Add timeout to role check as well
    final role = await authService.getRole().timeout(
      Duration(seconds: 5),
      onTimeout: () {
        print('Timeout getting role - defaulting to non-admin');
        return 'USER';
      }
    );
    
    if (role != 'ADMIN') {
      print('User is not admin or role check timed out');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Acceso solo para administradores'))
        );
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
      return;
    }
    
    // Show loading status to user
    if (mounted) {
      setState(() {
        _isLoadingStats = true;
        _isLoadingProducts = true;
        _isLoadingNotifications = true;
        _isLoadingPendingPayments = true;
        
      });
    }
    
    // Load data with timeout
    try {
      await _loadData().timeout(
        Duration(seconds: 15),
        onTimeout: () {
          print('Timeout loading data - showing partial data');
          throw TimeoutException('Timeout loading data');
        }
      );
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Algunos datos no pudieron cargarse'))
        );
      }
    } finally {
      // Always update UI state when done, even if errors occurred
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
          _isLoadingProducts = false;
          _isLoadingNotifications = false;
          _isLoadingPendingPayments = false;
          _initialized = true;
        });
      }
    }
  } catch (e) {
    print('Error en verificación: $e');
    // Still update UI state when done
    if (mounted) {
      setState(() {
        _isLoadingStats = false;
        _isLoadingProducts = false;
        _isLoadingNotifications = false;
        _isLoadingPendingPayments = false;
      });
    }
  } finally {
    // Reset redirection flag after 3 seconds
    _redirectionTimer = Timer(Duration(seconds: 3), () {
      _isRedirecting = false;
    });
  }
}
void _resetRedirectFlag() {
  // Reset flag after delay to prevent immediate re-checks
  _redirectionTimer = Timer(Duration(seconds: 3), () {
    _isRedirecting = false;
  });
}
  Future<void> _loadData() async {
    if (!mounted) return;
    
    _loadGeneralStats();
    _loadShipmentsByMonth();
    _loadProducts();
    _loadNotifications();
    _loadPendingPayments();
  }

  Future<void> _loadGeneralStats() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingStats = true;
    });

    try {
      final stats = await _statsService.getGeneralStats();
      if (!mounted) return;
      
      setState(() {
        _generalStats = stats;
        _isLoadingStats = false;
      });
    } catch (e) {
      print('Error cargando estadísticas: $e');
      if (!mounted) return;
      
      setState(() {
        _isLoadingStats = false;
      });
      _showErrorSnackBar('Error al cargar estadísticas generales');
    }
  }

  Future<void> _loadShipmentsByMonth() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingShipments = true;
    });

    try {
      final shipments = await _statsService.getShipmentsByMonth();
      if (!mounted) return;
      
      setState(() {
        _shipmentsByMonth = shipments;
        _isLoadingShipments = false;
      });
    } catch (e) {
      print('Error cargando envíos: $e');
      if (!mounted) return;
      
      setState(() {
        _isLoadingShipments = false;
      });
      _showErrorSnackBar('Error al cargar datos de envíos por mes');
    }
  }

  Future<void> _loadProducts() async {
  if (!mounted) return;
  
  setState(() {
    _isLoadingProducts = true;
  });

  try {
    // Use the admin-specific method instead of getProducts()
    final productData = await _productService.getAdminProducts(
      page: _currentPage,
      limit: _pageLimit
    );
    
    if (!mounted) return;
    
    setState(() {
      _products = productData['products'];
      _totalProducts = productData['total'];
      _isLoadingProducts = false;
    });
    
    print('Admin products loaded: ${_products.length} of $_totalProducts total');
  } catch (e) {
    print('Error cargando productos: $e');
    if (!mounted) return;
    
    setState(() {
      _isLoadingProducts = false;
    });
    _showErrorSnackBar('Error al cargar productos');
  }
}
// Add this method to navigate between pages
void _changePage(int newPage) {
  if (newPage > 0 && newPage <= (_totalProducts / _pageLimit).ceil()) {
    setState(() {
      _currentPage = newPage;
    });
    _loadProducts();
  }
}
 
  Future<void> _loadNotifications() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingNotifications = true;
    });

    try {
      final notifications = await _notificationService.getNotifications();
      if (!mounted) return;
      
      setState(() {
        _notifications = notifications;
        _isLoadingNotifications = false;
      });
    } catch (e) {
      print('Error cargando notificaciones: $e');
      if (!mounted) return;
      
      setState(() {
        _isLoadingNotifications = false;
      });
      _showErrorSnackBar('Error al cargar notificaciones');
    }
  }

  Future<void> _loadPendingPayments() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingPendingPayments = true;
    });

    try {
      final pendingPayments = await _statsService.getPendingPaymentProducts();
      if (!mounted) return;
      
      setState(() {
        _pendingPayments = pendingPayments;
        _isLoadingPendingPayments = false;
      });
    } catch (e) {
      print('Error cargando pagos pendientes: $e');
      if (!mounted) return;
      
      setState(() {
        _isLoadingPendingPayments = false;
      });
      _showErrorSnackBar('Error al cargar pagos pendientes');
    }
  }

// Update _showProductDetails method

void _showProductDetails(Product product) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(product.nombre),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (product.imagenUrl != null)
                Center(
                  child: Image.network(
                    product.imagenUrl!,
                    height: 150,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => 
                      Icon(Icons.image_not_supported, size: 100),
                  ),
                ),
              SizedBox(height: 16),
              // Add status chip with color
              Row(
                 children: [
                  Text('Estado: '),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200, // Color neutral para cualquier estado
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(product.estado ?? 'Sin estado'),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text('Descripción: ${product.descripcion}'),
              Text('Precio: \$${product.precio.toStringAsFixed(2)}'),
              Text('Cantidad: ${product.cantidad}'),
              Text('Peso: ${product.peso}kg'),
              if (product.link != null) Text('Link: ${product.link}'),
              Text('Fecha: ${product.fechaCreacion.toString().substring(0, 10)}'),
              if (product.usuario != null) Divider(),
             if (product.usuario != null) 
                Text('Cliente: ${product.usuario!['nombre'] ?? ''} ${product.usuario!['apellido'] ?? ''}'),
              if (product.usuario != null) 
                Text('Email: ${product.usuario!['email'] ?? ''}'),
              if (product.usuario != null && product.usuario!['telefono'] != null) 
                Text('Teléfono: ${product.usuario!['telefono']}'),
            ],
          ),
        ),
        // ...existing code...
actions: [
  TextButton(
    onPressed: () => Navigator.pop(context),
    child: Text('Cerrar'),
  ),
  ElevatedButton(  // Cambiado de TextButton a ElevatedButton para mayor visibilidad
    onPressed: () {
      print("Botón CAMBIAR ESTADO presionado");
      Navigator.pop(context);
      
      // Intenta mostrar un SnackBar primero
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Abriendo diálogo de cambio de estado...')),
      );
      
      // Luego intentamos mostrar el diálogo
      Future.delayed(Duration(milliseconds: 500), () {
        _showStatusChangeDialog(product);
      });
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue,  // Color de fondo más visible
      foregroundColor: Colors.white, // Texto blanco
    ),
    child: Text('CAMBIAR ESTADO'),  // Texto en mayúsculas para destacar
  ),
],

      );
    },
  );
}
// Add these methods to your AdminDashboardScreen class

// Get color based on product status
// Add these methods if they don't exist already

// Get color based on product status
Color _getStatusColor(String status) {
  switch (status) {
    case 'No llegado':
      return Colors.orange.shade100;
    case 'En bodega':
      return Colors.blue.shade100;
    case 'Pagado':
      return Colors.green.shade100;
    default:
      return Colors.grey.shade100;
  }
}

// Show dialog to change product status
// Complete implementation of _showStatusChangeDialog

// Complete implementation of _showStatusChangeDialog


// Update your _showProductOptions method to include an Edit option
// Update _showProductOptions to include status change option

void _showProductOptions(Product product) {
  showModalBottomSheet(
    context: context,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.info),
              title: Text('Ver detalles'),
              onTap: () {
                Navigator.pop(context);
                _showProductDetails(product);
              },
            ),
            ListTile(
              leading: Icon(Icons.local_shipping),
              title: Text('Cambiar estado'),
              onTap: () {
                Navigator.pop(context);
                _showStatusChangeDialog(product);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('Eliminar producto'),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteProduct(product);
              },
            ),
          ],
        ),
      );
    },
  );
}
void _confirmDeleteProduct(Product product) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que deseas eliminar "${product.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteProduct(product.id);
            },
            child: Text('Eliminar'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      );
    },
  );
}

Future<void> _deleteProduct(String productId) async {
  // Implement product deletion logic
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Función de eliminación no implementada')),
  );
}
// Add this new method to your AdminDashboardScreen class

// Add this method to your AdminDashboardScreen class

void _showEditProductDialog(Product product) {
  // Initialize with current status
  String selectedStatus = product.estado;
  
  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Editar Producto'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product image if available
                  if (product.imagenUrl != null)
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          product.imagenUrl!,
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => 
                            Icon(Icons.image_not_supported, size: 100),
                        ),
                      ),
                    ),
                  SizedBox(height: 16),
                  
                  // Status selection section
                  Text('Estado del producto:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  
                  // Radio buttons for status in Spanish
                  RadioListTile<String>(
                    title: Row(
                      children: [
                        Text('No llegado a bodega'),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('No llegado', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    value: 'No llegado',
                    groupValue: selectedStatus,
                    onChanged: (value) {
                      setState(() {
                        selectedStatus = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: Row(
                      children: [
                        Text('En bodega'),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('En bodega', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    value: 'En bodega',
                    groupValue: selectedStatus,
                    onChanged: (value) {
                      setState(() {
                        selectedStatus = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: Row(
                      children: [
                        Text('Pagado'),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('Pagado', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    value: 'Pagado',
                    groupValue: selectedStatus,
                    onChanged: (value) {
                      setState(() {
                        selectedStatus = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  
                  // If status changed, update it
                  if (selectedStatus != product.estado) {
                    _updateProductStatus(product, selectedStatus);
                  }
                },
                child: Text('Guardar'),
              ),
            ],
          );
        },
      );
    },
  );
}
// Add this method to update the product status
// Add this method to update the product status
 // Update your _showStatusChangeDialog with additional logging
// ...existing code...
void _showStatusChangeDialog(Product product) {
  String? selectedStatus = product.estado;
  
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Cambiar estado del producto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text('No llegado'),
              value: 'No llegado',
              groupValue: selectedStatus,
              onChanged: (value) {
                setState(() {
                  selectedStatus = value;
                });
                Navigator.pop(context);
                _updateProductStatus(product, value!);
              },
            ),
            RadioListTile<String>(
              title: Text('En bodega'),
              value: 'En bodega',
              groupValue: selectedStatus,
              onChanged: (value) {
                setState(() {
                  selectedStatus = value;
                });
                Navigator.pop(context);
                _updateProductStatus(product, value!);
              },
            ),
            RadioListTile<String>(
              title: Text('Pagado'),
              value: 'Pagado',
              groupValue: selectedStatus,
              onChanged: (value) {
                setState(() {
                  selectedStatus = value;
                });
                Navigator.pop(context);
                _updateProductStatus(product, value!);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
        ],
      );
    },
  );
}
// ...existing code...

Future<void> _updateProductStatus(Product product, String newStatus) async {
  try {
    print("Starting status update process...");
    
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              height: 20, 
              width: 20, 
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
            ),
            SizedBox(width: 10),
            Text('Actualizando estado...'),
          ],
        ),
        duration: Duration(seconds: 15),
      ),
    );
    
    print("Calling ProductService.updateProductStatus...");
    final success = await _productService.updateProductStatus(product.id, newStatus);
    print("API call completed, success: $success");
    
    // Dismiss the loading snackbar
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estado actualizado a "$newStatus"'),
          backgroundColor: Colors.green,
        ),
      );
      
      // If product is now in warehouse, send notification to user
      if (newStatus == 'En bodega' && product.usuario != null) {
        print("Product now in warehouse, sending notification to user");
        _notifyUser(product);
      }
      
      // Reload products to show updated status
      print("Reloading products to show updated status");
      _loadProducts();
    }
  } catch (e) {
    // Dismiss the loading snackbar
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    print("Error updating product status: $e");
    _showErrorSnackBar('Error al actualizar estado: ${e.toString()}');
  }
}
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _notifyUser(Product product) {
    if (!mounted) return;
    
    _notificationService.createProductArrivalNotification(
      userId: '2', // ID de usuario simulado
      productId: product.id,
      productName: product.nombre,
    ).then((_) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notificación enviada al usuario'),
          backgroundColor: Colors.green,
        ),
      );
      _loadNotifications();
    }).catchError((error) {
      if (!mounted) return;
      _showErrorSnackBar('Error al enviar notificación');
    });
  }

  void _markNotificationAsRead(NotificationModel notification) {
    if (!mounted) return;
    
    _notificationService.markAsRead(notification.id).then((_) {
      if (!mounted) return;
      _loadNotifications();
    }).catchError((error) {
      if (!mounted) return;
      _showErrorSnackBar('Error al marcar notificación como leída');
    });
  }

  void _deleteNotification(NotificationModel notification) {
    if (!mounted) return;
    
    _notificationService.deleteNotification(notification.id).then((_) {
      if (!mounted) return;
      _loadNotifications();
    }).catchError((error) {
      if (!mounted) return;
      _showErrorSnackBar('Error al eliminar notificación');
    });
  }

  void _clearAllNotifications() {
    if (!mounted) return;
    
    _notificationService.clearAllNotifications().then((_) {
      if (!mounted) return;
      _loadNotifications();
    }).catchError((error) {
      if (!mounted) return;
      _showErrorSnackBar('Error al limpiar notificaciones');
    });
  }

  void _markAsPaid(Map<String, dynamic> payment) {
    if (!mounted) return;
    
    setState(() {
      _pendingPayments.removeWhere((p) => p['id'] == payment['id']);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Producto "${payment['name']}" marcado como pagado'),
        backgroundColor: Colors.green,
      ),
    );
  }
  Widget _buildProductsSection() {
  return Card(
    margin: const EdgeInsets.all(16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Productos', style: Theme.of(context).textTheme.titleLarge),
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: _loadProducts,
                tooltip: 'Refrescar productos',
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingProducts)
            const Center(child: CircularProgressIndicator())
          else if (_products.isEmpty)
            const Center(child: Text('No se encontraron productos'))
          else
            Column(
              children: [
       // Update the product list item to properly handle the edit icon

ListView.builder(
  shrinkWrap: true,
  physics: NeverScrollableScrollPhysics(),
  itemCount: _products.length,
  itemBuilder: (context, index) {
    final product = _products[index];
    final usuario = product.usuario;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: product.imagenUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                product.imagenUrl!,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => 
                  Icon(Icons.image_not_supported, size: 50),
              ),
            )
          : Icon(Icons.inventory, size: 40),
        title: Row(
          children: [
            Expanded(child: Text(product.nombre)),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(_getDisplayStatus(product.estado)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getDisplayStatus(product.estado),
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('\$${product.precio.toStringAsFixed(2)} - ${product.cantidad} unidades'),
            if (usuario != null)
              Text('Cliente: ${usuario['nombre']} ${usuario['apellido']}'),
          ],
        ),
        isThreeLine: true,
        trailing: TextButton(
  child: Text("Editar", style: TextStyle(color: Colors.blue)),
  onPressed: () {
    print("BOTÓN PRESIONADO SIMPLE");
    
    // Intenta una navegación básica para probar el context
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text("Editar Producto")),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("ID: ${product.id}"),
                Text("Nombre: ${product.nombre}"),
                Text("Estado: ${product.estado ?? 'No definido'}"),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Volver"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  },
),
        onTap: () {
          // Optionally show product details on item tap
          _showProductDetails(product);
        },
      ),
    );
  },
),
                // Pagination
                if (_totalProducts > _pageLimit)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.navigate_before),
                          onPressed: _currentPage > 1 
                            ? () => _changePage(_currentPage - 1) 
                            : null,
                        ),
                        Text('Página $_currentPage de ${(_totalProducts / _pageLimit).ceil()}'),
                        IconButton(
                          icon: Icon(Icons.navigate_next),
                          onPressed: _currentPage < (_totalProducts / _pageLimit).ceil() 
                            ? () => _changePage(_currentPage + 1) 
                            : null,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    // Si no está inicializado, mostrar pantalla de carga
    if (!_initialized) {
      return Scaffold(
       body: RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           
            _buildProductsSection(), // Add this line
             
            
          ],
        ),
      ),
    ),
        
      );
    }
    
    if (_authError) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            SizedBox(height: 20),
            Text('Error de autenticación', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(_errorMessage, textAlign: TextAlign.center),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
              child: Text('Volver al login'),
            ),
          ],
        ),
      ),
    );
  }
    final authService = Provider.of<AuthService>(context);
    
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Dashboard Administrativo'),
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Recargar',
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  // Mostrar panel de notificaciones
                },
                tooltip: 'Notificaciones',
              ),
              if (_notifications.where((n) => !n.isRead).isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _notifications.where((n) => !n.isRead).length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white,
            child: Text(
              authService.currentUser?.name.substring(0, 1) ?? 'A',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
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
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Dashboard'),
              selected: true,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('Envíos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/shipments');
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('Usuarios'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/users');
              },
            ),
            // In the drawer ListView inside the build method, add this ListTile:

            ListTile(
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: const Text('Gestión de Envíos'),
                  onTap: () async {
                    // Get the token before navigation
                    final storage = FlutterSecureStorage();
                    final token = await storage.read(key: 'token');
                    
                    if (token != null) {
                      // Store it where needed or pass it directly
                      Navigator.pop(context); // Close the drawer
                      Navigator.pushNamed(
                        context, 
                        '/admin/shipments',
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error de autenticación. Inicie sesión nuevamente.'))
                      );
                    }
                  },
                ),
                
                ElevatedButton.icon(
                  icon: Icon(Icons.payments),
                  label: Text('Gestionar Pagos y Envíos'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/admin/pagos-envios');
                  },
                ),
            ListTile(
              leading: const Icon(Icons.shopping_cart_outlined),
              title: const Text('Productos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/products');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: () async {
                await authService.logout();
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard Administrativo',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bienvenido, ${authService.currentUser?.name ?? 'Administrador'}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.mutedTextColor,
                    ),
              ),
              const SizedBox(height: 24),
              
              // Estadísticas generales
              AdminStatsOverview(
                stats: _generalStats,
                isLoading: _isLoadingStats,
              ),
              const SizedBox(height: 24),
              
              // Gráfico de envíos por mes - CORREGIDO
              AdminShipmentsChart(
  data: _shipmentsByMonth, // Corregido: cambiado de shipmentsByMonth a data
  isLoading: _isLoadingShipments,
),
              const SizedBox(height: 24),
              
              // Productos
             AdminProductsTable(
                      products: _products,
                      isLoading: _isLoadingProducts,
                      onViewProduct: _showProductDetails,
                      onEditProduct: (product, newStatus) {
                        if (newStatus != null) {
                          _updateProductStatus(product, newStatus);
                        }
                      },
                      onDeleteProduct: _confirmDeleteProduct,
                      onNotifyUser: _notifyUser,
                      onDataUpdated: () {
                        // Recargar datos después de actualización
                        setState(() {
                          _isLoadingProducts = true;
                        });
                        _loadProducts();
                      },
                    ),
              
              const SizedBox(height: 24),
              
              // Notificaciones
              AdminNotificationsPanel(
                notifications: _notifications,
                isLoading: _isLoadingNotifications,
                onMarkAsRead: _markNotificationAsRead,
                onDelete: _deleteNotification,
                onClearAll: _clearAllNotifications,
              ),
              
              const SizedBox(height: 24),
              
              // Pagos pendientes
              AdminPendingPayments(
                pendingPayments: _pendingPayments,
                isLoading: _isLoadingPendingPayments,
                onMarkAsPaid: _markAsPaid,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
}