
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/shipment_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Add this import at the top of your file:
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
class AdminShipmentScreen extends StatefulWidget {
  const AdminShipmentScreen({Key? key}) : super(key: key);

  @override
  _AdminShipmentScreenState createState() => _AdminShipmentScreenState();
}

class _AdminShipmentScreenState extends State<AdminShipmentScreen> {
  List<Map<String, dynamic>> _shipments = [];
  bool _loadingShipments = true;
  bool _authError = false;
  String _errorMessage = '';
  ShipmentService _shipmentService = ShipmentService();
    int _currentPage = 1;
  int _pageSize = 10;
  int _totalShipments = 0;
  int _totalPages = 1;  

  @override
  void initState() {
    super.initState();
    _fetchShipments();
  }
Future<void> _fetchShipments() async {
  setState(() {
    _loadingShipments = true;
    _errorMessage = '';
  });
  
  try {
    // Get the admin token
    final adminToken = await _getUserToken();
    
    if (adminToken != null) {
      try {
        final result = await _shipmentService.getAdminShipments(
          token: adminToken,
          page: _currentPage,
          limit: _pageSize,
        );
        
        setState(() {
          _shipments = result['shipments'];
          _totalShipments = result['total'];
          _totalPages = result['pages'];
          _loadingShipments = false;
        });
        
        print('Loaded ${_shipments.length} shipments of $_totalShipments total');
      } catch (e) {
        print('API error: $e');
        setState(() {
          _loadingShipments = false;
          _errorMessage = 'Error al cargar envíos: $e';
        });
      }
    } else {
      setState(() {
        _loadingShipments = false;
      });
    }
  } catch (e) {
    print('Error fetching shipments: $e');
    setState(() {
      _loadingShipments = false;
      _errorMessage = 'Error: $e';
    });
  }
}
Future<String?> _getUserToken() async {
  try {
    const storage = FlutterSecureStorage();
    // Use 'token' instead of 'admin_token'
    final token = await storage.read(key: 'token');
    
    if (token == null) {
      setState(() {
        _errorMessage = 'No se encontró token de autenticación. Por favor inicie sesión nuevamente.';
        _authError = true;
      });
      return null;
    }
    
    // Check if user is admin (optional but recommended)
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('userRole') ?? await storage.read(key: 'role');
    if (role != 'ADMIN') {
      setState(() {
        _errorMessage = 'No tienes permisos de administrador.';
        _authError = true;
      });
      return null;
    }
    
    return token;
  } catch (e) {
    print('Error getting admin token: $e');
    setState(() {
      _errorMessage = 'Error al obtener el token: $e';
      _authError = true;
    });
    return null;
  }
}
// Update the _updateShipmentStatus method to include WhatsApp notification
Future<void> _updateShipmentStatus(String shipmentId, String newStatus) async {
  try {
    final adminToken = await _getUserToken();
    
    if (adminToken != null) {
      await _shipmentService.updateShipmentStatus(
        shipmentId: shipmentId,
        newStatus: newStatus,
        token: adminToken,
      );
      
      // Get the updated shipment to access latest data
       final updatedShipment = await _shipmentService.getShipmentById(shipmentId);
      // Refresh the shipments list
      _fetchShipments();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Estado actualizado con éxito'),
          duration: Duration(seconds: 2),
        ),
      );
      
      // Show WhatsApp notification dialog
     if (updatedShipment != null) {
        _showWhatsAppNotificationDialog(updatedShipment);
      }
    }
  } catch (e) {
    print('Error updating shipment status: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error al actualizar el estado: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

void _showWhatsAppNotificationDialog(Map<String, dynamic> shipment) async {
  // Get client name from shipment
  final clientName = shipment['userName'] ?? 'Cliente';
  final trackingNumber = shipment['trackingNumber'] ?? '';
  final status = shipment['status'] ?? '';
  
  // Get phone number from SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final phoneNumber = prefs.getString('telefono') ?? '';
  
  // If we couldn't get the phone number, show an error
  if (phoneNumber.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No se encontró un número de teléfono para notificar'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.chat, color: Color(0xFF25D366), size: 28),
          const SizedBox(width: 10),
          const Text('Notificar por WhatsApp'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('¿Desea notificar a $clientName sobre el cambio de estado?'),
          const SizedBox(height: 10),
          Text('Número: $phoneNumber', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('Tracking: $trackingNumber', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('Nuevo estado: ${_getStatusDisplayName(status)}', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          icon: Icon(Icons.chat, color: Colors.white),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366), // WhatsApp green color
            foregroundColor: Colors.white,
          ),
          label: const Text('Enviar mensaje'),
          onPressed: () {
            Navigator.pop(context);
            _sendWhatsAppNotification(
              phoneNumber,
              trackingNumber,
              status,
              clientName,
            );
          },
        ),
        ElevatedButton.icon(
          icon: Icon(Icons.chat, color: Colors.white),
          label: Text('Notificar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
            _showWhatsAppNotificationDialog(shipment);
          },

        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _showStatusChangeDialog(
              shipment['id'],
              shipment['status'] ?? 
              shipment['Estado'] ?? 
              shipment['estado'] ?? 
              'Procesando'
            );
          },
          child: Text('Cambiar Estado'),
        ),
        
      ],
    ),
  );
}
// Send WhatsApp notification
void _sendWhatsAppNotification(String phoneNumber, String trackingNumber, String status, String clientName) {
  // Format the phone number (remove any non-digit characters and ensure it has Ecuador country code)
  String formattedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
  if (!formattedNumber.startsWith('+')) {
    // Add Ecuador country code if missing
    formattedNumber = '+593$formattedNumber';
  }
  
  // Create the message
  final statusName = _getStatusDisplayName(status);
  final message = 'Hola $clientName, su pedido con número de tracking $trackingNumber ha sido actualizado a estado: $statusName. Por favor revise su estado en la aplicación.';
  
  // URL encode the message
  final encodedMessage = Uri.encodeComponent(message);
  
  // Create the WhatsApp URL
  final whatsappUrl = 'https://wa.me/$formattedNumber?text=$encodedMessage';
  
  // Launch the URL
  launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication).then((success) {
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir WhatsApp. Verifique que esté instalado.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  });
}

// Helper method to get a user-friendly status name
String _getStatusDisplayName(String status) {
  switch (status.toUpperCase()) {
    case 'RECEIVED':
      return 'Recibido';
    case 'IN_TRANSIT':
      return 'En tránsito';
    case 'CUSTOMS':
      return 'En aduana';
    case 'READY_FOR_PICKUP':
      return 'Listo para recoger';
    case 'DELIVERED':
      return 'Entregado';
    default:
      return status;
  }
}

// Add this button to your UI where you display shipment information
Widget _buildWhatsAppButton(Map<String, dynamic> shipment) {
  return ElevatedButton.icon(
    icon: const Icon(Icons.chat, color: Colors.white),
    label: const Text('Notificar'),
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF25D366), // WhatsApp green color
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    onPressed: () => _showWhatsAppNotificationDialog(shipment),
  );
}
void _showShipmentDetails(Map<String, dynamic> shipment) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Detalles del Envío'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Shipment ID
            _detailRow('ID:', shipment['id']),
            _divider(),
            
            // Tracking Number
            _detailRow('Tracking:', 
              shipment['trackingNumber'] ?? 
              shipment['TrackingNumber'] ?? 
              'No disponible'),
            _divider(),
            
            // Client Info
            _detailRow('Cliente:', 
              shipment['userName'] ?? 
              shipment['nombreUsuario'] ?? 
              'No disponible'),
            _divider(),
              
            // Status
            Row(
              children: [
                Text('Estado:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      shipment['status'] ?? 
                      shipment['Estado'] ?? 
                      shipment['estado'] ?? 
                      'Procesando'
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    shipment['status'] ??
                    shipment['Estado'] ?? 
                    shipment['estado'] ?? 
                    'Procesando',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            _divider(),
            
            // Dates
            _detailRow('Fecha:', 
              _formatDate(shipment['fecha'] ?? shipment['Fecha'] ?? DateTime.now())),
              
            if (shipment['fechaEstimada'] != null || shipment['FechaEstimada'] != null)
              _detailRow('Entrega estimada:', 
                _formatDate(shipment['fechaEstimada'] ?? shipment['FechaEstimada'])),
            _divider(),
            
            // Origin and Destination
            _detailRow('Origen:', 
              shipment['origin'] ?? shipment['Origen'] ?? 'No disponible'),
              
            _detailRow('Destino:', 
              shipment['destination'] ?? shipment['Direccion'] ?? 'No disponible'),
            _divider(),
            
            // Shipment History/Timeline
            if (shipment['eventos'] != null || shipment['Eventos'] != null) 
              ...[
                Text('Historial de eventos:', 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 8),
                _buildEventsList(shipment),
              ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cerrar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _showStatusChangeDialog(
              shipment['id'],
              shipment['status'] ?? 
              shipment['Estado'] ?? 
              shipment['estado'] ?? 
              'Procesando'
            );
          },
          child: Text('Cambiar Estado'),
        ),
      ],
    ),
  );
}

// Helper methods for the shipment details dialog
Widget _detailRow(String label, String value) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(width: 8),
        Expanded(child: Text(value ?? 'No disponible')),
      ],
    ),
  );
}

Widget _divider() {
  return Divider(height: 16);
}

Widget _buildEventsList(Map<String, dynamic> shipment) {
  final eventos = shipment['eventos'] ?? shipment['Eventos'] ?? [];
  
  if (eventos is! List || eventos.isEmpty) {
    return Text('No hay eventos registrados');
  }
  
  return Column(
    children: List.generate(eventos.length, (index) {
      final evento = eventos[index];
      if (evento is! Map) return SizedBox();
      
      return Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                if (index < eventos.length - 1)
                  Container(
                    width: 2,
                    height: 24,
                    color: Colors.grey.shade300,
                  ),
              ],
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    evento['descripcion'] ?? 'Actualización de estado',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${_formatDate(evento['fecha'])} - ${evento['ubicacion'] ?? 'N/A'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }),
  );
}
void _showStatusChangeDialog(String shipmentId, String currentStatus) {
  String selectedStatus = currentStatus;
  
  // List of possible statuses
  final statusOptions = [
    'Procesando',
    'En tránsito',
    'En bodega',
    'Preparando entrega',
    'En reparto',
    'Entregado',
    'Cancelado',
  ];

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Cambiar estado del envío'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: statusOptions.map((status) {
                  return RadioListTile<String>(
                    title: Text(status),
                    value: status,
                    groupValue: selectedStatus,
                    onChanged: (value) {
                      setState(() {
                        selectedStatus = value!;
                      });
                    },
                  );
                }).toList(),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (selectedStatus != currentStatus) {
                _updateShipmentStatus(shipmentId, selectedStatus);
              }
            },
            child: Text('Actualizar'),
          ),
        ],
      );
    },
  );
}
Widget _buildShipmentsSection() {
  return Card(
    elevation: 4,
    margin: EdgeInsets.all(16),
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gestión de Envíos',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: _fetchShipments,
                tooltip: 'Refrescar',
              ),
            ],
          ),
          SizedBox(height: 16),
          _loadingShipments
              ? Center(child: CircularProgressIndicator())
              : _shipments.isEmpty
                  ? Center(child: Text('No hay envíos disponibles'))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: [
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Tracking')),
                          DataColumn(label: Text('Cliente')),
                          DataColumn(label: Text('Origen')),
                          DataColumn(label: Text('Destino')),
                          DataColumn(label: Text('Fecha')), // This column needs a cell
                          DataColumn(label: Text('Estado')),
                          DataColumn(label: Text('Acciones')),
                        ],
                        rows: _shipments.map((shipment) {
                          return DataRow(
                            cells: [
                              // Cell 1: ID
                              DataCell(
                                Text(
                                  shipment['id'] ?? '',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                              // Cell 2: Tracking
                              DataCell(
                              Container(
                                
                                child: Tooltip(
                                  message: shipment['numeroSeguimiento'] ?? 'Sin tracking',
                                  child: SelectableText(
                                    shipment['numeroSeguimiento'] ?? 'Sin tracking',
                                    style: TextStyle(overflow: TextOverflow.ellipsis),
                                  ),
                                ),
                              ),
                            ),
                              // Cell 3: Cliente
                              DataCell(
                                Text(
                                  shipment['usuario']['nombre'] ?? 
                                  shipment['nombreUsuario'] ?? 
                                  'Usuario',
                                ),
                              ),
                              // Cell 4: Origen
                              DataCell(
                                Text(
                                  shipment['origin'] ?? 
                                  shipment['Origen'] ?? 
                                  'Miami, FL',
                                ),
                              ),
                              // Cell 5: Destino
                              DataCell(
                                Text(
                                  shipment['destination'] ?? 
                                  shipment['direccion'] ?? 
                                  'No disponible',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Cell 6: Fecha (was missing)
                              DataCell(
                                Text(
                                  _formatDate(
                                    shipment['fecha'] ?? 
                                    shipment['Fecha'] ?? 
                                    DateTime.now()
                                  ),
                                ),
                              ),
                              // Cell 7: Estado
                              DataCell(
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      shipment['status'] ?? 
                                      shipment['Estado'] ?? 
                                      shipment['estado'] ?? 
                                      'Procesando'
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    shipment['status'] ??
                                    shipment['Estado'] ?? 
                                    shipment['estado'] ?? 
                                    'Procesando',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                              // Cell 8: Acciones (keep the PopupMenuButton here)
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.visibility, size: 20),
                                      onPressed: () {
                                        _showShipmentDetails(shipment);
                                      },
                                      tooltip: 'Ver detalles',
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (String value) {
                                        _updateShipmentStatus(shipment['id'], value);
                                      },
                                      itemBuilder: (BuildContext context) => [
                                        PopupMenuItem(
                                          value: 'Procesando',
                                          child: Text('Procesando'),
                                        ),
                                        PopupMenuItem(
                                          value: 'En bodega',
                                          child: Text('En bodega'),
                                        ),
                                        PopupMenuItem(
                                          value: 'En tránsito',
                                          child: Text('En tránsito Miami'),
                                        ),
                                        PopupMenuItem(
                                          value: 'En aduana',
                                          child: Text('En aduana ecuador'),
                                        ),
                                        PopupMenuItem(
                                          value: 'En país destino',
                                          child: Text('En Ecuador'),
                                        ),
                                        PopupMenuItem(
                                          value: 'En ruta entrega',
                                          child: Text('En ruta entrega'),
                                        ),
                                        PopupMenuItem(
                                          value: 'Entregado',
                                          child: Text('Entregado'),
                                        ),
                                      ],
                                      icon: Icon(Icons.edit, size: 20),
                                      tooltip: 'Cambiar estado',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
          // Add pagination controls if you have them
        ],
      ),
    ),
  );
}

// Helper method to format dates
String _formatDate(dynamic date) {
  try {
    DateTime dateTime;
    if (date is DateTime) {
      dateTime = date;
    } else if (date is String) {
      dateTime = DateTime.parse(date);
    } else if (date is Map && date['_seconds'] != null) {
      // Handle Firestore timestamp
      dateTime = DateTime.fromMillisecondsSinceEpoch(date['_seconds'] * 1000);
    } else {
      return 'Fecha no disponible';
    }
    
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  } catch (e) {
    return 'Fecha no disponible';
  }
}

// Helper method to get color based on status
Color _getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'procesando':
      return Colors.blue.shade100;
    case 'en tránsito':
    case 'en transito':
      return Colors.orange.shade100;
    case 'en bodega':
      return Colors.green.shade100;
    case 'en aduana':
      return Colors.purple.shade100;
    case 'en país destino':
    case 'en pais destino':
      return Colors.indigo.shade100;
    case 'en ruta entrega':
      return Colors.amber.shade100;
    case 'entregado':
      return Colors.teal.shade100;
    default:
      return Colors.grey.shade100;
  }
}

String _formatShipmentDate(dynamic date) {
  if (date == null) return 'No disponible';
  
  try {
    DateTime dateTime;
    
    if (date is String) {
      dateTime = DateTime.parse(date);
    } else if (date is Map) {
      if (date['_seconds'] != null) {
        final seconds = date['_seconds'];
        dateTime = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      } else if (date['seconds'] != null) {
        final seconds = date['seconds'];
        dateTime = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      } else {
        return 'Fecha inválida';
      }
    } else {
      return date.toString();
    }
    
    return DateFormat('dd/MM/yyyy').format(dateTime);
  } catch (e) {
    return 'Fecha inválida';
  }
}
// Add this method at the end of your _AdminShipmentScreenState class

@override
Widget build(BuildContext context) {
  if (_authError) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestión de Envíos'),
      ),
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
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/admin/login');
              },
              child: Text('Volver a iniciar sesión'),
            ),
          ],
        ),
      ),
    );
  }

  return Scaffold(
    appBar: AppBar(
      title: Text('Gestión de Envíos'),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh),
          onPressed: _fetchShipments,
          tooltip: 'Refrescar',
        ),
      ],
    ),
    body: _buildShipmentsSection(),
  );
}
}