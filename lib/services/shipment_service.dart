import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/shipment_tracking_timeline.dart';
import '../models/tracking_event_model.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';
import './image_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:math';
class ApiConfig {
  static const String baseUrl = 'https://api-mpxltf6i3a-uc.a.run.app'; 
}
class ShipmentService {
  final _storage = FlutterSecureStorage();
  final List<Map<String, dynamic>> _mockShipments = [
    {
      'id': '1',
      'trackingNumber': 'VB-12345678',
      'date': '2025-03-14',
      'status': 'En tránsito',
      'origin': 'Miami, FL',
      'destination': 'Ciudad de México, MX',
      'products': 3,
      'customer': 'Juan Pérez',
      'estimatedDelivery': '2025-03-17',
      'currentStatus': ShipmentStatus.enPais,
      'events': [
        {
          'date': '2025-03-14 09:15',
          'location': 'Miami, FL',
          'description': 'Paquete recibido en centro de distribución',
          'status': ShipmentStatus.enBodega,
        },
        {
          'date': '2025-03-14 14:30',
          'location': 'Miami, FL',
          'description': 'Paquete procesado y listo para envío',
          'status': ShipmentStatus.enBodega,
        },
        {
          'date': '2025-03-15 08:45',
          'location': 'Miami International Airport',
          'description': 'Paquete en ruta hacia el aeropuerto',
          'status': ShipmentStatus.enRutaAeropuerto,
        },
        {
          'date': '2025-03-15 12:30',
          'location': 'Miami International Airport',
          'description': 'Paquete en proceso de embarque',
          'status': ShipmentStatus.enRutaAeropuerto,
        },
        {
          'date': '2025-03-16 09:15',
          'location': 'Aduana Internacional',
          'description': 'Paquete en revisión aduanal',
          'status': ShipmentStatus.enAduana,
        },
        {
          'date': '2025-03-17 10:45',
          'location': 'Aeropuerto Internacional de la Ciudad de México',
          'description': 'Paquete llegó al país de destino',
          'status': ShipmentStatus.enPais,
        },
      ],
      'productsList': [
        {
          'name': 'Smartphone XYZ',
          'quantity': 1,
          'price': 899.99,
        },
        {
          'name': 'Auriculares Bluetooth',
          'quantity': 2,
          'price': 149.99,
        },
      ],
    },
    {
      'id': '2',
      'trackingNumber': 'VB-87654321',
      'date': '2025-03-10',
      'status': 'Entregado',
      'origin': 'Los Angeles, CA',
      'destination': 'Guadalajara, MX',
      'products': 1,
      'customer': 'María González',
      'estimatedDelivery': '2025-03-13',
      'currentStatus': ShipmentStatus.entregado,
      'events': [
        {
          'date': '2025-03-10 10:30',
          'location': 'Los Angeles, CA',
          'description': 'Paquete recibido en centro de distribución',
          'status': ShipmentStatus.enBodega,
        },
        {
          'date': '2025-03-10 15:45',
          'location': 'Los Angeles, CA',
          'description': 'Paquete procesado y listo para envío',
          'status': ShipmentStatus.enBodega,
        },
        {
          'date': '2025-03-11 08:15',
          'location': 'Los Angeles International Airport',
          'description': 'Paquete en ruta hacia el aeropuerto',
          'status': ShipmentStatus.enRutaAeropuerto,
        },
        {
          'date': '2025-03-11 11:30',
          'location': 'Los Angeles International Airport',
          'description': 'Paquete en proceso de embarque',
          'status': ShipmentStatus.enRutaAeropuerto,
        },
        {
          'date': '2025-03-11 18:45',
          'location': 'Aduana Internacional',
          'description': 'Paquete en revisión aduanal',
          'status': ShipmentStatus.enAduana,
        },
        {
          'date': '2025-03-12 09:30',
          'location': 'Aeropuerto Internacional de Guadalajara',
          'description': 'Paquete llegó al país de destino',
          'status': ShipmentStatus.enPais,
        },
        {
          'date': '2025-03-12 14:15',
          'location': 'Centro de Distribución Guadalajara',
          'description': 'Paquete en ruta para entrega final',
          'status': ShipmentStatus.enRutaEntrega,
        },
        {
          'date': '2025-03-13 11:30',
          'location': 'Guadalajara, MX',
          'description': 'Paquete entregado al destinatario',
          'status': ShipmentStatus.entregado,
        },
      ],
      'productsList': [
        {
          'name': 'Laptop ABC',
          'quantity': 1,
          'price': 1299.99,
        },
      ],
    },
    {
      'id': '3',
      'trackingNumber': 'VB-23456789',
      'date': '2025-03-05',
      'status': 'Procesando',
      'origin': 'New York, NY',
      'destination': 'Monterrey, MX',
      'products': 2,
      'customer': 'Carlos Rodríguez',
      'estimatedDelivery': '2025-03-10',
      'currentStatus': ShipmentStatus.enBodega,
      'events': [
        {
          'date': '2025-03-05 11:45',
          'location': 'New York, NY',
          'description': 'Paquete recibido en centro de distribución',
          'status': ShipmentStatus.enBodega,
        },
        {
          'date': '2025-03-05 16:30',
          'location': 'New York, NY',
          'description': 'Paquete en proceso de verificación',
          'status': ShipmentStatus.enBodega,
        },
      ],
      'productsList': [
        {
          'name': 'Tablet Pro',
          'quantity': 1,
          'price': 599.99,
        },
        {
          'name': 'Funda protectora',
          'quantity': 1,
          'price': 49.99,
        },
      ],
    },
  ];

  // Método para obtener todos los envíos
 

  // Método para obtener un envío por ID
  Future<Map<String, dynamic>?> getShipmentById(String id) async {
    // Simular retraso de red
    await Future.delayed(const Duration(seconds: 1));
    
    try {
      return _mockShipments.firstWhere((shipment) => shipment['id'] == id);
    } catch (e) {
      return null;
    }
  }

  // Método para crear un nuevo envío
  Future<Map<String, dynamic>> createShipment(Map<String, dynamic> shipment) async {
    // Simular retraso de red
    await Future.delayed(const Duration(seconds: 1));
    
    final newShipment = {
      ...shipment,
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'trackingNumber': 'VB-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
      'date': DateTime.now().toString().substring(0, 10),
      'status': 'Procesando',
      'currentStatus': ShipmentStatus.enBodega,
      'events': [
        {
          'date': DateTime.now().toString().substring(0, 16).replaceAll('T', ' '),
          'location': shipment['origin'],
          'description': 'Paquete registrado en el sistema',
          'status': ShipmentStatus.enBodega,
        },
      ],
    };
    
    _mockShipments.add(newShipment);
    return newShipment;
  }

  // Método para obtener los eventos de seguimiento de un envío
  Future<List<TrackingEvent>> getTrackingEvents(String shipmentId) async {
    // Simular retraso de red
    await Future.delayed(const Duration(seconds: 1));
    
    try {
      final shipment = _mockShipments.firstWhere((s) => s['id'] == shipmentId);
      final events = shipment['events'] as List<dynamic>;
      
      return events.map((event) {
        final status = event['status'] as ShipmentStatus;
        
        IconData icon;
        switch (status) {
          case ShipmentStatus.enBodega:
            icon = Icons.warehouse_outlined;
            break;
          case ShipmentStatus.enRutaAeropuerto:
            icon = Icons.flight_takeoff_outlined;
            break;
          case ShipmentStatus.enAduana:
            icon = Icons.security_outlined;
            break;
          case ShipmentStatus.enPais:
            icon = Icons.flight_land_outlined;
            break;
          case ShipmentStatus.enRutaEntrega:
            icon = Icons.local_shipping_outlined;
            break;
          case ShipmentStatus.entregado:
            icon = Icons.home_outlined;
            break;
        }
        
        return TrackingEvent(
          id: '${shipmentId}_${events.indexOf(event)}',
          status: status,
          timestamp: DateTime.parse(event['date'].replaceAll(' ', 'T')),
          location: event['location'],
          description: event['description'],
          icon: icon,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }
  // Añade este método a tu ShipmentService
Future<Map<String, dynamic>> createDetailedShipment({
  required String token,
  required Map<String, dynamic> shipmentData,
}) async {
  try {
    print('Creating detailed shipment: $shipmentData');
    
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/admin/envios/detallado'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
      body: json.encode(shipmentData),
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      // Intento con ruta alternativa
      final fallbackResponse = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/admin/envios'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
        body: json.encode(shipmentData),
      );
      
      if (fallbackResponse.statusCode == 200 || fallbackResponse.statusCode == 201) {
        return json.decode(fallbackResponse.body);
      }
      
      print('Error creating shipment: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Error al crear envío: ${response.statusCode}');
    }
  } catch (e) {
    print('Error in createDetailedShipment: $e');
    throw Exception('Error al crear envío: $e');
  }
}
 Future<Map<String, dynamic>> getAdminShipments({
  required String token,
  int page = 1,
  int limit = 10,
}) async {
  try {
    print('Fetching admin shipments with token, page: $page, limit: $limit');
    
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/admin/MostrarEnvios?page=$page&limit=$limit'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    print('Admin shipments response: ${response.statusCode}');
    print('Response URL: ${response.request?.url}');
    
    if (response.statusCode == 200) {
      // Parse the response
      final responseBody = jsonDecode(response.body);
      
      // Check if the response has the expected structure
      if (responseBody['success'] == true && responseBody['data'] != null) {
        // Extract shipments data and pagination info
        final List<dynamic> shipmentsData = responseBody['data'];
        final Map<String, dynamic> pagination = responseBody['pagination'] ?? {};
        
        // Convert to proper format
        final List<Map<String, dynamic>> shipments = 
            shipmentsData.map((item) => item as Map<String, dynamic>).toList();
        
        // Return both shipments and pagination info
        return {
          'shipments': shipments,
          'pagination': pagination,
          'total': pagination['total'] ?? 0,
          'pages': pagination['pages'] ?? 1,
          'currentPage': pagination['page'] ?? 1,
        };
      } else {
        print('Unexpected response format: $responseBody');
        throw Exception('Formato de respuesta inesperado');
      }
    } else {
      print('Error fetching shipments: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Error al obtener envíos: ${response.statusCode}');
    }
  } catch (e) {
    print('Exception in getAdminShipments: $e');
    throw Exception('Error al obtener envíos: $e');
  }
}
/*
  // Método para actualizar el estado de un envío
  Future<bool> updateShipmentStatus(String shipmentId, ShipmentStatus newStatus) async {
    // Simular retraso de red
    await Future.delayed(const Duration(seconds: 1));
    
    try {
      final index = _mockShipments.indexWhere((s) => s['id'] == shipmentId);
      if (index == -1) return false;
      
      _mockShipments[index]['currentStatus'] = newStatus;
      
      // Actualizar el estado general del envío
      String statusText;
      switch (newStatus) {
        case ShipmentStatus.enBodega:
          statusText = 'Procesando';
          break;
        case ShipmentStatus.enRutaAeropuerto:
        case ShipmentStatus.enAduana:
        case ShipmentStatus.enPais:
        case ShipmentStatus.enRutaEntrega:
          statusText = 'En tránsito';
          break;
        case ShipmentStatus.entregado:
          statusText = 'Entregado';
          break;
      }
      
      _mockShipments[index]['status'] = statusText;
      
      // Agregar un nuevo evento de seguimiento
      String description;
      String location;
      
      switch (newStatus) {
        case ShipmentStatus.enBodega:
          description = 'Paquete recibido en bodega';
          location = _mockShipments[index]['origin'];
          break;
        case ShipmentStatus.enRutaAeropuerto:
          description = 'Paquete en camino al aeropuerto';
          location = '${_mockShipments[index]['origin']} Airport';
          break;
        case ShipmentStatus.enAduana:
          description = 'Paquete en proceso de aduana';
          location = 'Aduana Internacional';
          break;
        case ShipmentStatus.enPais:
          description = 'Paquete llegó al país de destino';
          location = 'Aeropuerto de ${_mockShipments[index]['destination']}';
          break;
        case ShipmentStatus.enRutaEntrega:
          description = 'Paquete en ruta para entrega final';
          location = 'Centro de Distribución ${_mockShipments[index]['destination']}';
          break;
        case ShipmentStatus.entregado:
          description = 'Paquete entregado al destinatario';
          location = _mockShipments[index]['destination'];
          break;
      }
      
      final newEvent = {
        'date': DateTime.now().toString().substring(0, 16).replaceAll('T', ' '),
        'location': location,
        'description': description,
        'status': newStatus,
      };
      
      (_mockShipments[index]['events'] as List).add(newEvent);
      
      return true;
    } catch (e) {
      return false;
    }
  }
*/
Future<Map<String, dynamic>> registerShipment({
  required String direccion,
  required String pagoId,
  required String token,
  String origen = "Miami, FL",
  List<String>? productIds, 
}) async {
  final url = '${ApiConfig.baseUrl}/user/RegistrarEnvio';
  
  try {
    print('Registrando envío en: $url');
    print('Datos: direccion=$direccion, pagoId=$pagoId, origen=$origen');
    print('Productos asociados: ${productIds?.join(', ') ?? 'ninguno'}');
    
    final authHeader = token;
    print('Token usado: $authHeader');
    
    // Create request body with all necessary fields
    final Map<String, dynamic> requestBody = {
      'direccion': direccion ?? "guaya",
      'pagoId': pagoId,
      'origen': origen,
      'fechaEstimada': DateTime.now().add(const Duration(days: 25)).toIso8601String(),
      'productos':productIds,
    };
    
    
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': authHeader,
      },
      body: jsonEncode(requestBody),
    );

    print('Respuesta registro envío: ${response.statusCode}');
    print('Respuesta cuerpo: ${response.body}');
    print('Request body enviado: ${jsonEncode(requestBody)}');  // Debug the exact request sent

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      
      // Crear un objeto de envío con los datos de la respuesta
      final newShipment = {
        'id': responseData['id'],
        'trackingNumber': responseData['trackingNumber'],
        'date': DateTime.now().toString().substring(0, 10),
        'status': responseData['estado'] ?? 'Procesando',
        'origin': origen,
        'destination': direccion,
        'customer': 'Cliente',
        'productos': productIds,
        'estimatedDelivery': responseData['fechaEstimada'] != null 
            ? DateTime.parse(responseData['fechaEstimada'].toString()).toString().substring(0, 10)
            : DateTime.now().add(const Duration(days: 7)).toString().substring(0, 10),
      };
      
      return {
        'success': true,
        'data': newShipment,
        'message': responseData['message'] ?? 'Envío creado exitosamente',
      };
    } else {
      // Log error details
      print('Error en registro de envío: ${response.statusCode}');
      print('Detalles del error: ${response.body}');
      print('Headers de respuesta: ${response.headers}');
      
      Map<String, dynamic> errorBody = {};
      try {
        errorBody = jsonDecode(response.body);
      } catch (e) {
        // If not valid JSON, use empty map
      }
      
      throw Exception('Error al registrar envío: ${errorBody['message'] ?? response.reasonPhrase}');
    }
  } catch (e) {
    print('Excepción capturada: $e');
    print('Stack trace: ${StackTrace.current}');
    throw Exception('Error al registrar envío: $e');
  }
}
Future<List<Map<String, dynamic>>> getShipments({String? token}) async {
  try {
    // Get token if not provided
    String? authHeader = token;
    
    if (authHeader == null || authHeader.isEmpty) {
      authHeader = await _storage.read(key: 'token');
      print('Token obtenido de secure storage en getShipments: ${authHeader != null}');
    }
    
    // Call getUserShipmentsFromApi with the token
    return getUserShipmentsFromApi(token: authHeader);
  } catch (e) {
    print('Error en getShipments: $e');
    return List.from(_mockShipments);
  }
}


Future<List<Map<String, dynamic>>> getUserShipmentsFromApi({String? token}) async {
  try {
    // If no token provided, try to get it from secure storage
    String? authHeader = token;
    
    if (authHeader == null || authHeader.isEmpty) {
      authHeader = await _storage.read(key: 'token');
      print('Token obtenido de secure storage: ${authHeader != null}');
    }
    
    if (authHeader == null || authHeader.isEmpty) {
      print('No se encontró token válido');
      // Si no hay token, devolver datos simulados
      await Future.delayed(const Duration(seconds: 1));
      return List.from(_mockShipments);
    }
    
    // Use token as-is without adding Bearer prefix
    print('Token usado: $authHeader');
    
    final url = '${ApiConfig.baseUrl}/user/MisEnvios'; // Removed /user prefix
    print('Consultando envíos en: $url');
    
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': authHeader, // Use token as-is
        'Content-Type': 'application/json',
      },
    );

    print('Respuesta obtener envíos: ${response.statusCode}');
    print('Headers enviados: ${{'Authorization': 'REDACTED', 'Content-Type': 'application/json'}}');
    
    if (response.statusCode == 200) {
      final List<dynamic> responseData = jsonDecode(response.body);
      print('Envíos obtenidos: ${responseData.length}');
      
      if (responseData.isEmpty) {
        return [];
      }
      return responseData.map((data) {
        // Función auxiliar para manejar cualquier tipo de dato y convertirlo a String
        String safeString(dynamic value, String defaultValue) {
          if (value == null) return defaultValue;
          if (value is String) return value;
          if (value is Map || value is List) return json.encode(value);
          return value.toString();
        }
        String safeDate(dynamic dateValue, {bool addDays = false}) {
          try {
            if (dateValue == null) {
              final date = addDays 
                ? DateTime.now().add(Duration(days: 7)) 
                : DateTime.now();
              return date.toString().substring(0, 10);
            }
            
            if (dateValue is String) {
              return DateTime.parse(dateValue).toString().substring(0, 10);
            } 
            
            if (dateValue is Map) {
              return DateTime.now().toString().substring(0, 10);
            }
            
            return DateTime.now().toString().substring(0, 10);
          } catch (e) {
            print('Error al parsear fecha: $e');
            return DateTime.now().toString().substring(0, 10);
          }
        }
         // Mapear la respuesta del backend al formato que la UI espera
        final shipmentStatus = _getShipmentStatus(safeString(data['estado'], 'Procesando'));
        
        return {
          'id': safeString(data['id'], ''),
          'trackingNumber': safeString(data['trackingNumber'], 'Sin tracking'),
          'date': safeDate(data['fecha']),
          'status': safeString(data['estado'], 'Procesando'),
          'origin': safeString(data['origen'], 'Miami, FL'),
          'destination': safeString(data['direccion'], 'Destino'),
          'customer': 'Cliente',
          'estimatedDelivery': safeDate(data['fechaEstimada'], addDays: true),
          'events': _mapEventsFromBackend(data['eventos'] ?? []),
          'productsList': getProductsByIds( data['productos'] ??[]),
          
        };
      }).toList();
       
      } else {
        print('Error al obtener envíos: ${response.statusCode}');
        throw Exception('Error al obtener envíos: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error al obtener envíos: $e');
      // En caso de error, devolver datos simulados o lanzar excepción según necesites
      return List.from(_mockShipments);
    }
  }
  // Add these methods to your ShipmentService class


// Add or update this method in your ShipmentService class

Future<bool> updateShipmentStatus({
  required String shipmentId,
  required String newStatus,
  required String token,
}) async {
  try {
    print('Updating shipment status: ID=$shipmentId, newStatus=$newStatus');
    
    // Get status description based on status code
    final String statusDescription = _getStatusDescription(newStatus);
    final String location = "Miami, FL"; // Default location
    
    // Fix URL construction
    final baseUrl = ApiConfig.baseUrl;
    final url = Uri.parse(
      baseUrl + (baseUrl.endsWith('/') ? '' : '/') + 'admin/ActualizarEnvio'
    );
    
    print('Request URL: $url');
    
    // Create a new event for the timeline
    final Map<String, dynamic> newEvent = {
      'descripcion': statusDescription,
      'estado': newStatus,
      'fecha': DateTime.now().toIso8601String(),
      'ubicacion': location
    };
    
    // Send request with both status update and new timeline event
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'id': shipmentId,
        'estado': newStatus,
        'nuevoEvento': newEvent,
        'actualizarTimeline': true // Flag to indicate timeline should be updated
      }),
    );
    
    print('Update status response: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return responseData['success'] == true;
    } else {
      print('Error updating shipment status: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Error al actualizar el estado del envío: ${response.statusCode}');
    }
  } catch (e) {
    print('Exception in updateShipmentStatus: $e');
    throw Exception('Error al actualizar el estado del envío: $e');
  }
}

// Helper method to get a descriptive message for each status
String _getStatusDescription(String status) {
  switch (status) {
    case 'Procesando':
      return 'Paquete registrado y en procesamiento inicial';
    case 'En tránsito':
      return 'Paquete en tránsito hacia destino';
    case 'En bodega':
      return 'Paquete recibido en bodega';
    case 'Preparando entrega':
      return 'Preparando paquete para entrega final';
    case 'En reparto':
      return 'Paquete en ruta de entrega';
    case 'Entregado':
      return 'Paquete entregado al destinatario';
    case 'Cancelado':
      return 'Envío cancelado';
    default:
      return 'Estado actualizado a $status';
  }
}

Future<Map<String, dynamic>> getShipmentDetails({
  required String shipmentId,
  required String token
}) async {
  try {
    print('Fetching shipment details, ID: $shipmentId');
    
    // Use the same endpoint as defined in your backend
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/user/shipments/$shipmentId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
    );
    
    print('API response status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      // Your backend already formats the data properly with these field names:
      // id, trackingNumber, status, origin, destination, date, estimatedDelivery, trackingHistory, productsList
      final data = jsonDecode(response.body);
      print('Successfully fetched shipment data with fields: ${data.keys.join(", ")}');
      
      // Check if productsList contains IDs that need to be expanded
      if (data['productsList'] != null && data['productsList'] is List && data['productsList'].isNotEmpty) {
        // Check if the first item is just an ID (string) or already a complete object
        final firstItem = data['productsList'][0];
        if (firstItem is String || (firstItem is Map && !firstItem.containsKey('nombre'))) {
          try {
            print('Product list contains IDs, fetching detailed products');
            final productIds = data['productsList'];
            final products = await getProductsByIds(productIds, token: token);
            data['productsList'] = products;
            print('Successfully fetched ${products.length} detailed products');
          } catch (e) {
            print('Error fetching detailed product info: $e');
          }
        } else {
          print('Product list already contains detailed information');
        }
      }
      
      // Check if we have tracking history, generate it if missing
      if (data['trackingHistory'] == null || 
          (data['trackingHistory'] is List && data['trackingHistory'].isEmpty)) {
        print('No tracking history in response, generating events');
        
        // Generate tracking events based on shipment status
        final status = data['status'] ?? 'Procesando';
        DateTime creationDate;
        
        try {
          creationDate = data['date'] != null 
              ? (data['date'] is String ? DateTime.parse(data['date']) : DateTime.fromMillisecondsSinceEpoch(data['date'] * 1000))
              : DateTime.now().subtract(Duration(days: 3));
        } catch (e) {
          print('Error parsing date, using default: $e');
          creationDate = DateTime.now().subtract(Duration(days: 3));
        }
        
        // Create tracking events based on status
        List<Map<String, dynamic>> events = [
          {
            'estado': 'enBodega',
            'descripcion': 'Paquete registrado en el sistema',
            'fecha': creationDate.toIso8601String(),
            'ubicacion': data['origin'] ?? 'Miami, FL'
          }
        ];
        
        // Add appropriate events based on status
        if (status.toLowerCase() != 'procesando' && status.toLowerCase() != 'en proceso') {
          events.add({
            'estado': 'enRutaAeropuerto',
            'descripcion': 'Paquete en tránsito al aeropuerto',
            'fecha': creationDate.add(Duration(days: 1)).toIso8601String(),
            'ubicacion': 'Miami International Airport'
          });
          
          if (status.toLowerCase().contains('destino') || 
              status.toLowerCase().contains('entrega')) {
            events.add({
              'estado': 'enAduana',
              'descripcion': 'Paquete en proceso aduanero',
              'fecha': creationDate.add(Duration(days: 2)).toIso8601String(),
              'ubicacion': 'Aduana Internacional Ecuador'
            });
            
            events.add({
              'estado': 'enPais',
              'descripcion': 'Paquete llegó al país destino',
              'fecha': creationDate.add(Duration(days: 3)).toIso8601String(),
              'ubicacion': 'Ecuador'
            });
          }
          
          if (status.toLowerCase().contains('entregado')) {
            events.add({
              'estado': 'enRutaEntrega',
              'descripcion': 'Paquete en ruta para entrega final',
              'fecha': creationDate.add(Duration(days: 4)).toIso8601String(),
              'ubicacion': data['destination'] ?? 'Dirección de entrega'
            });
            
            events.add({
              'estado': 'entregado',
              'descripcion': 'Paquete entregado al destinatario',
              'fecha': creationDate.add(Duration(days: 5)).toIso8601String(),
              'ubicacion': data['destination'] ?? 'Dirección de entrega'
            });
          }
        }
        
        data['trackingHistory'] = events;
        print('Added ${events.length} tracking events');
      }
      
      return data;
    } else if (response.statusCode == 404) {
      // If direct endpoint fails, fall back to MisEnvios
      print('Shipment not found directly, trying MisEnvios...');
      
      final shipmentsResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/user/MisEnvios'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );
      
      if (shipmentsResponse.statusCode == 200) {
        final List<dynamic> shipments = jsonDecode(shipmentsResponse.body);
        print('Found ${shipments.length} shipments in MisEnvios');
        
        final matchingShipment = shipments.firstWhere(
          (s) => s['id'] == shipmentId,
          orElse: () => <String, dynamic>{},
        );
        
        if (matchingShipment.isNotEmpty) {
          print('Found matching shipment in MisEnvios!');
          
          // Convert the MisEnvios format to match the /shipments/:id format
          // Update the code where you create the normalizedShipment

// Convert the MisEnvios format to match the /shipments/:id format
final normalizedShipment = {
  'id': matchingShipment['id'],
  'trackingNumber': matchingShipment['trackingNumber'] ?? matchingShipment['TrackingNumber'] ?? 'Sin número',
  'status': matchingShipment['estado'] ?? matchingShipment['Estado'] ?? 'Procesando',
  'origin': matchingShipment['origen'] ?? matchingShipment['Origen'] ?? 'Miami, FL',
  'destination': matchingShipment['direccion'] ?? matchingShipment['Direccion'] ?? 'No disponible',
  'productsList': [],
  'trackingHistory': []
};

// Process date fields
try {
  // Handle creation date
  var dateValue = matchingShipment['fecha'] ?? matchingShipment['Fecha'];
  if (dateValue != null) {
    // If it's a timestamp object with seconds/nanoseconds
    if (dateValue is Map && (dateValue['_seconds'] != null || dateValue['seconds'] != null)) {
      final seconds = dateValue['_seconds'] ?? dateValue['seconds'];
      final dateTime = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      normalizedShipment['date'] = dateTime.toIso8601String();
    } else {
      // Keep as is if it's already a string or other format
      normalizedShipment['date'] = dateValue;
    }
  } else {
    normalizedShipment['date'] = DateTime.now().subtract(Duration(days: 3)).toIso8601String();
  }
  
  // Handle estimated delivery date
  var estimatedDeliveryValue = matchingShipment['fechaEstimada'] ?? matchingShipment['FechaEstimada'];
  if (estimatedDeliveryValue != null) {
    // If it's a timestamp object with seconds/nanoseconds
    if (estimatedDeliveryValue is Map && (estimatedDeliveryValue['_seconds'] != null || estimatedDeliveryValue['seconds'] != null)) {
      final seconds = estimatedDeliveryValue['_seconds'] ?? estimatedDeliveryValue['seconds'];
      final dateTime = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      normalizedShipment['estimatedDelivery'] = dateTime.toIso8601String();
    } else {
      // Keep as is if it's already a string or other format
      normalizedShipment['estimatedDelivery'] = estimatedDeliveryValue;
    }
  } else {
    normalizedShipment['estimatedDelivery'] = DateTime.now().add(Duration(days: 7)).toIso8601String();
  }
} catch (e) {
  print('Error processing date fields: $e');
  // Set fallback dates
  normalizedShipment['date'] = DateTime.now().subtract(Duration(days: 3)).toIso8601String();
  normalizedShipment['estimatedDelivery'] = DateTime.now().add(Duration(days: 7)).toIso8601String();
}
          // Process products if present
          if (matchingShipment['productos'] != null && matchingShipment['productos'] is List) {
            try {
              final productIds = matchingShipment['productos'];
              print('Fetching details for products: $productIds');
              final products = await getProductsByIds(productIds, token: token);
              normalizedShipment['productsList'] = products;
              print('Successfully fetched ${products.length} products');
            } catch (e) {
              print('Error fetching product details: $e');
            }
          }
          
          // Generate tracking events if missing
          if (matchingShipment['eventos'] == null || 
              (matchingShipment['eventos'] is List && matchingShipment['eventos'].isEmpty)) {
            print('Generating tracking events for MisEnvios data');
            
            final status = normalizedShipment['status'];
            final creationDate = DateTime.now().subtract(Duration(days: 3));
            
            List<Map<String, dynamic>> events = [
              {
                'estado': 'enBodega',
                'descripcion': 'Paquete registrado en el sistema',
                'fecha': creationDate.toIso8601String(),
                'ubicacion': normalizedShipment['origin']
              }
            ];
            
            // Add more events based on status (same logic as above)
            if (status.toLowerCase() != 'procesando' && status.toLowerCase() != 'en proceso') {
              events.add({
                'estado': 'enRutaAeropuerto',
                'descripcion': 'Paquete en tránsito al aeropuerto',
                'fecha': creationDate.add(Duration(days: 1)).toIso8601String(),
                'ubicacion': 'Miami International Airport'
              });
              
              // Add more events based on status...
              if (status.toLowerCase().contains('destino') || 
                  status.toLowerCase().contains('entrega')) {
                events.add({
                  'estado': 'enAduana',
                  'descripcion': 'Paquete en proceso aduanero',
                  'fecha': creationDate.add(Duration(days: 2)).toIso8601String(),
                  'ubicacion': 'Aduana Internacional Ecuador'
                });
                
                events.add({
                  'estado': 'enPais',
                  'descripcion': 'Paquete llegó al país destino',
                  'fecha': creationDate.add(Duration(days: 3)).toIso8601String(),
                  'ubicacion': 'Ecuador'
                });
              }
            }
            
            normalizedShipment['trackingHistory'] = events;
          } else {
            normalizedShipment['trackingHistory'] = matchingShipment['eventos'];
          }
          
          return normalizedShipment;
        } else {
          print('Shipment not found in any source');
          throw Exception('El envío no existe o no tiene permiso para verlo.');
        }
      } else {
        print('Failed to fetch MisEnvios: ${shipmentsResponse.statusCode}');
        throw Exception('Error al obtener lista de envíos: ${shipmentsResponse.statusCode}');
      }
    } else {
      // Handle other error codes
      print('API error: ${response.statusCode}, ${response.body}');
      throw Exception('Error al obtener datos del envío: ${response.statusCode}');
    }
  } catch (e) {
    print('Exception in getShipmentDetails: $e');
    rethrow;
  }
}
// Add a mock data helper method for development
Map<String, dynamic> _getMockShipmentDetail(String shipmentId) {
  return {
    'id': shipmentId,
    'trackingNumber': 'VB-${shipmentId.substring(0, 6)}',
    'status': 'En proceso',
    'origin': 'Miami, FL',
    'destination': '10 de agosto, jipijapa, Ecuador',
    'date': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
    'estimatedDelivery': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
    'eventos': [
      {
        'estado': 'enBodega',
        'descripcion': 'Paquete registrado en el sistema',
        'fecha': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
        'ubicacion': 'Miami, FL'
      },
      {
        'estado': 'enRutaAeropuerto',
        'descripcion': 'Paquete en tránsito al aeropuerto',
        'fecha': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        'ubicacion': 'Miami International Airport'
      }
    ],
    'productos': [
      {
        'nombre': 'Producto de ejemplo',
        'descripcion': 'Descripción del producto',
        'cantidad': 1
      }
    ]
  };
}
  List<Map<String, dynamic>> _mapEventsFromBackend(List<dynamic> events) {
  try {
    return events.map((event) {
      String safeString(dynamic value, String defaultValue) {
        if (value == null) return defaultValue;
        if (value is String) return value;
        return value.toString();
      }
      
      String safeDate(dynamic dateValue) {
        try {
          if (dateValue == null) {
            return DateTime.now().toString().substring(0, 16).replaceAll('T', ' ');
          }
          
          if (dateValue is String) {
            return DateTime.parse(dateValue).toString().substring(0, 16).replaceAll('T', ' ');
          }
          
          return DateTime.now().toString().substring(0, 16).replaceAll('T', ' ');
        } catch (e) {
          return DateTime.now().toString().substring(0, 16).replaceAll('T', ' ');
        }
      }
       return {
        'date': safeDate(event['fecha']),
        'location': safeString(event['ubicacion'], ''),
        'description': safeString(event['descripcion'], ''),
        'status': _getShipmentStatusFromString(safeString(event['estado'], 'enBodega')),
      };
    }).toList();
  } catch (e) {
    print('Error al mapear eventos: $e');
    return [];
  }
}

  List<Map<String, dynamic>> _mapProductsFromBackend(List<dynamic> products) {
  return products.map((product) {
    // Convertir cantidad a int
    dynamic cantidad = product['cantidad'] ?? product['Cantidad'] ?? 1;
    int quantity = cantidad is int ? cantidad : 
                  (cantidad is String ? int.tryParse(cantidad) ?? 1 : 1);
    
    // Convertir precio a double
    dynamic precio = product['precio'] ?? product['Precio'] ?? 0.0;
    double price = precio is double ? precio : 
                  (precio is int ? precio.toDouble() : 
                  (precio is String ? double.tryParse(precio) ?? 0.0 : 0.0));
    
    return {
      'name': product['nombre'] ?? product['Nombre'] ?? 'Producto',
      'quantity': quantity,
      'price': price,
    };
  }).toList();
}
Future<List<Map<String, dynamic>>> getProductsByIds(List<dynamic> productIds, {String? token}) async {
  try {
    // Convertir los IDs a strings si vienen en otro formato
    final ids = productIds.map((id) => id.toString()).toList();

    final authHeader = token ?? await _storage.read(key: 'token');
    
    if (authHeader == null || authHeader.isEmpty) {
      throw Exception('Token no disponible');
    }

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/user/ObtenerProductosPorIds'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': authHeader,
      },
      body: jsonEncode({'ids': ids}),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      
      // Asegurarse que data es una List
      final productsData = (responseData['data'] as List?) ?? [];
      
      return productsData.map<Map<String, dynamic>>((product) {
        return {
          'id': product['id']?.toString() ?? '',
          'name': product['nombre']?.toString() ?? 'Producto sin nombre',
          'description': product['descripcion']?.toString() ?? 'Sin descripción',
          'quantity': _safeParseInt(product['cantidad']),
          'price': _safeParseDouble(product['precio']),
          'weight': _safeParseDouble(product['peso']),
          'imageUrl': product['imagenUrl']?.toString() ?? '',
          'status': product['estado']?.toString() ?? 'No llegado',
          'user': (product['usuario'] as Map?) ?? {},
        };
      }).toList();
    } else {
      throw Exception('Error al obtener productos: ${response.statusCode}');
    }
  } catch (e) {
    print('Error en getProductsByIds: $e');
    rethrow;
  }
}

// Helper para parsear enteros
int _safeParseInt(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  if (value is double) return value.toInt();
  return 0;
}

// Helper para parsear doubles
double _safeParseDouble(dynamic value) {
  if (value is double) return value;
  if (value is String) return double.tryParse(value) ?? 0.0;
  if (value is int) return value.toDouble();
  return 0.0;
}

  // Helper para convertir estado a ShipmentStatus enum
  ShipmentStatus _getShipmentStatus(String status) {
    switch (status.toLowerCase()) {
      case 'procesando':
        return ShipmentStatus.enBodega;
      case 'en aduana':
        return ShipmentStatus.enAduana;
      case 'en país':
        return ShipmentStatus.enPais;
      case 'en ruta':
        return ShipmentStatus.enRutaEntrega;
      case 'entregado':
        return ShipmentStatus.entregado;
      default:
        return ShipmentStatus.enBodega;
    }
  }

  // Helper para convertir string a ShipmentStatus enum
  ShipmentStatus _getShipmentStatusFromString(String status) {
    switch (status) {
      case 'enBodega': return ShipmentStatus.enBodega;
      case 'enRutaAeropuerto': return ShipmentStatus.enRutaAeropuerto;
      case 'enAduana': return ShipmentStatus.enAduana;
      case 'enPais': return ShipmentStatus.enPais;
      case 'enRutaEntrega': return ShipmentStatus.enRutaEntrega;
      case 'entregado': return ShipmentStatus.entregado;
      default: return ShipmentStatus.enBodega;
    }
  }


  }

