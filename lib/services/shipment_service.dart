import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/shipment_tracking_timeline.dart';
import '../models/tracking_event_model.dart';

class ShipmentService {
  // Datos simulados para envíos
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
  Future<List<Map<String, dynamic>>> getShipments() async {
    // Simular retraso de red
    await Future.delayed(const Duration(seconds: 1));
    return List.from(_mockShipments);
  }

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
}

