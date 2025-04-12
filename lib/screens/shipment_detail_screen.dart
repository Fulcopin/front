import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import '../services/shipment_service.dart';
import '../widgets/shipment_tracking_timeline.dart';
import '../models/tracking_event_model.dart';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/shipment_service.dart';
import '../widgets/shipment_tracking_timeline.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../theme.dart';
import '../services/shipment_service.dart';
import '../widgets/shipment_tracking_timeline.dart';
class ShipmentDetailScreen extends StatefulWidget {
    final String shipmentId;
    const ShipmentDetailScreen({Key? key, required this.shipmentId}) : super(key: key);
  
  @override
  State<ShipmentDetailScreen> createState() => _ShipmentDetailScreenState();
}

class _ShipmentDetailScreenState extends State<ShipmentDetailScreen> {
  final ShipmentService _shipmentService = ShipmentService();
  bool _isLoading = true;
  Map<String, dynamic> _shipmentDetails = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Fetch details is called after the widget is inserted in the tree
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchShipmentDetails();
    });
  }

Future<void> _fetchShipmentDetails() async {
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    // Get token from secure storage
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    
    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'No se encontró token de autenticación';
      });
      return;
    }
    
    print('Fetching details for shipment: ${widget.shipmentId}');
    
    final details = await _shipmentService.getShipmentDetails(
      shipmentId: widget.shipmentId,
      token: token,
    );
    
    print('Received data from API: ${details.keys.join(", ")}');
    
    // The response is already normalized to match the frontend field names
    setState(() {
      _shipmentDetails = details;
      _isLoading = false;
    });
  } catch (e) {
    print('Error fetching shipment details: $e');
    setState(() {
      _isLoading = false;
      _errorMessage = 'Error al cargar detalles: $e';
    });
  }
}
// Helper method to format dates
String _formatDate(dynamic date) {
  if (date == null) return 'No disponible';
  
  try {
    // Check if it's a Firestore timestamp object with toDate method
    if (date.runtimeType.toString().contains('Timestamp')) {
      try {
        // This works for actual Firestore Timestamp objects
        final dateTime = date.toDate();
        return DateFormat('dd/MM/yyyy').format(dateTime);
      } catch (e) {
        print('Error calling toDate on Timestamp: $e');
      }
    }
    
    // Handle Firestore timestamp as Map representation
    if (date is Map) {
      // Check various timestamp formats
      if (date['_seconds'] != null) {
        // Standard Firestore JSON timestamp format
        final seconds = date['_seconds'];
        final dateTime = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
        return DateFormat('dd/MM/yyyy').format(dateTime);
      } else if (date['seconds'] != null) {
        // Alternative timestamp format
        final seconds = date['seconds'];
        final dateTime = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
        return DateFormat('dd/MM/yyyy').format(dateTime);
      } else if (date['toDate'] != null) {
        // If toDate exists as a key but is not callable,
        // we should handle the value at that key
        return _formatDate(date['toDate']);
      } else if (date['value'] != null) {
        // Sometimes timestamps are wrapped with a value field
        return _formatDate(date['value']);
      } else if (date.toString().contains('Timestamp')) {
        // Last resort parsing for Timestamp string representation
        final regex = RegExp(r'seconds=(\d+)');
        final match = regex.firstMatch(date.toString());
        if (match != null && match.groupCount >= 1) {
          final seconds = int.parse(match.group(1)!);
          final dateTime = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
          return DateFormat('dd/MM/yyyy').format(dateTime);
        }
      }
    } else if (date is String) {
      // Try parsing string formats
      try {
        final dateTime = DateTime.parse(date);
        return DateFormat('dd/MM/yyyy').format(dateTime);
      } catch (e) {
        // Check if it's a Spanish format date
        if (date.contains('de ') && date.contains(',')) {
          try {
            final months = {
              'enero': 1, 'febrero': 2, 'marzo': 3, 'abril': 4, 'mayo': 5, 'junio': 6,
              'julio': 7, 'agosto': 8, 'septiembre': 9, 'octubre': 10, 'noviembre': 11, 'diciembre': 12
            };
            
            final dateParts = date.split(',')[0].trim().split(' de ');
            final day = int.parse(dateParts[0]);
            final month = months[dateParts[1].toLowerCase()] ?? 1;
            final year = int.parse(dateParts[2]);
            
            final dateTime = DateTime(year, month, day);
            return DateFormat('dd/MM/yyyy').format(dateTime);
          } catch (e) {
            print('Error parsing Spanish date: $e');
            return date;
          }
        }
        return date;
      }
    } else if (date is DateTime) {
      return DateFormat('dd/MM/yyyy').format(date);
    }
    
    // If we get here, just return the string representation
    return date.toString();
  } catch (e) {
    print('Error formatting date: $e');
    return date?.toString() ?? 'Fecha inválida';
  }
}
  ShipmentStatus _convertStringToShipmentStatus(String status) {
    switch (status.toLowerCase()) {
      case 'en proceso':
      case 'procesando':
        return ShipmentStatus.enBodega;
      case 'enviado':
      case 'en tránsito':
        return ShipmentStatus.enRutaAeropuerto;
      case 'en aduana':
        return ShipmentStatus.enAduana;
      case 'en destino':
      case 'llegó a destino':
        return ShipmentStatus.enPais;
      case 'en ruta entrega':
      case 'en ruta final':
        return ShipmentStatus.enRutaEntrega;
      case 'entregado':
      case 'completado':
        return ShipmentStatus.entregado;
      default:
        return ShipmentStatus.enBodega;
    }
  }

  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    IconData badgeIcon;
    
    switch (status.toLowerCase()) {
      case 'en proceso':
      case 'procesando':
        badgeColor = Colors.blue;
        badgeIcon = Icons.inventory_2_outlined;
        break;
      case 'enviado':
      case 'en tránsito':
        badgeColor = Colors.orange;
        badgeIcon = Icons.local_shipping_outlined;
        break;
      case 'en destino':
      case 'llegó a destino':
        badgeColor = Colors.purple;
        badgeIcon = Icons.home_outlined;
        break;
      case 'entregado':
      case 'completado':
        badgeColor = Colors.green;
        badgeIcon = Icons.check_circle_outline;
        break;
      default:
        badgeColor = Colors.grey;
        badgeIcon = Icons.help_outline;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 16, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Envío'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchShipmentDetails,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _fetchShipmentDetails,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shipment header card
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _shipmentDetails['trackingNumber']?.toString() ?? 'Sin número',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              _buildStatusBadge(_shipmentDetails['status']?.toString() ?? 'Procesando'),
                            ],
                          ),
                          const SizedBox(height: 24),
                          ShipmentTrackingTimeline(
                            currentStatus: _convertStringToShipmentStatus(
                              _shipmentDetails['status']?.toString() ?? 'Procesando'
                            ),
                            showLabels: true,
                            isHorizontal: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Route information
                  const Text(
                    'Información de Ruta',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildInfoRow(
                            'Origen', 
                            _shipmentDetails['origin']?.toString() ?? 'No disponible',
                            Icons.flight_takeoff
                          ),
                          const Divider(),
                          _buildInfoRow(
                            'Destino', 
                            _shipmentDetails['destination']?.toString() ?? 'No disponible',
                            Icons.flight_land
                          ),
                          const Divider(),
                          _buildInfoRow(
                            'Fecha de creación', 
                            _shipmentDetails['date']?.toString() ?? 'No disponible',
                            Icons.calendar_today
                          ),
                          const Divider(),
                          _buildInfoRow(
                            'Entrega estimada', 
                            _shipmentDetails['estimatedDelivery']?.toString() ?? 'Pendiente',
                            Icons.access_time
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Shipment items
                  const Text(
                    'Productos del Envío',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildProductsList(),
                  
                  const SizedBox(height: 24),
                  
                  // Tracking history
                  const Text(
                    'Historial de Seguimiento',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTrackingHistory(),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.mutedTextColor,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

 Widget _buildProductsList() {
  final products = _shipmentDetails['productsList'];
  
  if (products == null || (products is List && products.isEmpty)) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            'No hay productos en este envío',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      ),
    );
  }
  
  List<dynamic> productList = [];
  
  if (products is String) {
    try {
      productList = json.decode(products);
    } catch (e) {
      print('Error decoding products string: $e');
      productList = [];
    }
  } else if (products is List) {
    productList = products;
  }
  
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: ListView.separated(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: productList.length,
        separatorBuilder: (context, index) => Divider(),
        itemBuilder: (context, index) {
          final product = productList[index];
          
          // Handle different field naming conventions
          final name = product['name'] ?? product['nombre'] ?? 'Producto sin nombre';
          final quantity = product['quantity'] ?? product['cantidad'] ?? 1;
          final price = product['price'] ?? product['precio'] ?? 0.0;
          final imageUrl = product['imageUrl'] ?? product['imagenUrl'] ?? '';
          
          return ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                image: imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                        onError: (error, stackTrace) {
                          print('Error loading image: $error');
                        },
                      )
                    : null,
              ),
              child: imageUrl.isEmpty
                  ? Icon(Icons.inventory_2, color: Colors.grey[400])
                  : null,
            ),
            title: Text(
              name.toString(),
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Cantidad: $quantity'),
            trailing: price != null && price != 0
                ? Text(
                    '\$${_formatPrice(price)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  )
                : null,
          );
        },
      ),
    ),
  );
}

String _formatPrice(dynamic price) {
  if (price == null) return '0.00';
  
  try {
    double value;
    if (price is int) {
      value = price.toDouble();
    } else if (price is double) {
      value = price;
    } else if (price is String) {
      value = double.tryParse(price) ?? 0.0;
    } else {
      return '0.00';
    }
    
    return value.toStringAsFixed(2);
  } catch (e) {
    return '0.00';
  }
}
// Replace the _buildTrackingHistory method with this implementation

Widget _buildTrackingHistory() {
  // If there are no tracking events, show a message
  if (_shipmentDetails['trackingHistory'] == null || 
      (_shipmentDetails['trackingHistory'] is List && _shipmentDetails['trackingHistory'].isEmpty)) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.timeline_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No hay eventos de seguimiento disponibles',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Get the current status from shipment details
  final currentStatus = _convertStringToShipmentStatus(
    _shipmentDetails['status']?.toString() ?? 'Procesando'
  );
  
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // First add the vertical timeline component
          ShipmentTrackingTimeline(
            currentStatus: currentStatus,
            showLabels: true,
            isHorizontal: false, // Use vertical layout
          ),
          
          // Add a divider
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(),
          ),
          
          // Then show the detailed events from the API
          _buildDetailedTrackingEvents(),
        ],
      ),
    ),
  );
}

// Add a new method to show the detailed events
Widget _buildDetailedTrackingEvents() {
  final List<dynamic> events = _shipmentDetails['trackingHistory'] ?? [];
  
  // If no events, return empty container
  if (events.isEmpty) {
    return Container();
  }
  
  // Sort events by date if possible (newest first)
  try {
    events.sort((a, b) {
      final dateA = a['fecha'] ?? '';
      final dateB = b['fecha'] ?? '';
      return dateB.toString().compareTo(dateA.toString());
    });
  } catch (e) {
    print('Error sorting events: $e');
  }
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Detalles de eventos',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 12),
      ...events.map((event) {
        // Get event data
        final status = event['estado'] ?? 'desconocido';
        final description = event['descripcion'] ?? '';
        final date = _formatEventDate(event['fecha'] ?? '');
        final location = event['ubicacion'] ?? '';
        
        // Determine event icon and color
        IconData eventIcon;
        Color eventColor;
        
        switch (status.toLowerCase()) {
          case 'enbodega':
            eventIcon = Icons.warehouse_outlined;
            eventColor = Colors.blue;
            break;
          case 'enrutaaeropuerto':
            eventIcon = Icons.flight_takeoff_outlined;
            eventColor = Colors.orange;
            break;
          case 'enaduana':
            eventIcon = Icons.security_outlined;
            eventColor = Colors.purple;
            break;
          case 'enpais':
            eventIcon = Icons.flight_land_outlined;
            eventColor = Colors.indigo;
            break;
          case 'enrutaentrega':
            eventIcon = Icons.local_shipping_outlined;
            eventColor = Colors.amber;
            break;
          case 'entregado':
            eventIcon = Icons.check_circle_outline;
            eventColor = Colors.green;
            break;
          default:
            eventIcon = Icons.info_outline;
            eventColor = Colors.grey;
        }
        
        // Build event card
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: eventColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: eventColor),
                ),
                child: Icon(
                  eventIcon,
                  color: eventColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _translateStatus(status),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          date,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    if (location.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          location,
                          style: TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ),
                    if (description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    ],
  );
}

// Add a helper method to format event dates
String _formatEventDate(dynamic date) {
  if (date == null) return '';
  
  try {
    DateTime dateTime;
    
    if (date is String) {
      if (date.contains('T')) {
        dateTime = DateTime.parse(date);
      } else {
        return date;
      }
    } else if (date is Map) {
      if (date['_seconds'] != null) {
        final seconds = date['_seconds'];
        dateTime = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      } else if (date['seconds'] != null) {
        final seconds = date['seconds'];
        dateTime = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      } else {
        return date.toString();
      }
    } else {
      return date.toString();
    }
    
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  } catch (e) {
    print('Error formatting event date: $e');
    return date.toString();
  }
}

// Translate status codes to human-readable text
String _translateStatus(String status) {
  switch (status.toLowerCase()) {
    case 'enbodega':
      return 'En bodega';
    case 'enrutaaeropuerto':
      return 'En ruta al aeropuerto';
    case 'enaduana':
      return 'En aduana';
    case 'enpais':
      return 'En país destino';
    case 'enrutaentrega':
      return 'En ruta para entrega';
    case 'entregado':
      return 'Entregado';
    default:
      return status;
  }
}
}