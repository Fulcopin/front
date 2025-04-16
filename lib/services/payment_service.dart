import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';


class PaymentMethod {
  final String id;
  final String type;
  final String name;
  final String lastFourDigits;
  final bool isDefault;

  PaymentMethod({
    required this.id,
    required this.type,
    required this.name,
    required this.lastFourDigits, 
    this.isDefault = false,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'],
      type: json['type'],
      name: json['name'],
      lastFourDigits: json['lastFourDigits'],
      isDefault: json['isDefault'] ?? false,
    );
  }
}

class PaymentService {
  final String baseUrl = 'hhttps://proyect-currier.onrender.com';
  final _storage = const FlutterSecureStorage();
  
  // Stream controllers for reactive data
  final _paymentMethodsController = StreamController<List<PaymentMethod>>.broadcast();
  final _transactionsController = StreamController<List<Map<String, dynamic>>>.broadcast();
  
  Stream<List<PaymentMethod>> get paymentMethods => _paymentMethodsController.stream;
  Stream<List<Map<String, dynamic>>> get transactions => _transactionsController.stream;
  
  List<PaymentMethod> _paymentMethods = [];
  List<Map<String, dynamic>> _transactions = [];

  // Constructor
  PaymentService() {
    _loadSavedPaymentMethods();
    _loadTransactionHistory();
  }

  // Obtener todos los pagos del usuario actual
  Future<List<Map<String, dynamic>>> getUserPayments() async {
    try {
      print('Fetching user payments');
      
      final token = await _storage.read(key: 'token');
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/user/pagos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );

      print('User payments response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final payments = data.map((payment) => payment as Map<String, dynamic>).toList();
        
        // Actualizar el stream de transacciones
        _transactions = payments;
        _transactionsController.add(_transactions);
        
        return payments;
      } else {
        print('Error fetching payments: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Error al obtener pagos: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getUserPayments: $e');
      throw Exception('Error al obtener pagos: $e');
    }
  }
  // Obtener todos los pagos (para administradores)
  Future<Map<String, dynamic>> getAdminPayments({required String token}) async {
    try {
      print('Fetching all payments (admin view)');
      
      final response = await http.get(
        Uri.parse('$baseUrl/admin/pagos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );

      print('Admin payments response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        List<Map<String, dynamic>> payments = [];
        if (data is List) {
          payments = List<Map<String, dynamic>>.from(data);
        } else if (data['pagos'] != null && data['pagos'] is List) {
          payments = List<Map<String, dynamic>>.from(data['pagos']);
        }
        
        return {
          'payments': payments,
          'total': payments.length,
        };
      } else if (response.statusCode == 403) {
        throw Exception('No tienes permisos de administrador');
      } else {
        print('Error fetching admin payments: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Error al obtener pagos: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getAdminPayments: $e');
      throw Exception('Error al obtener pagos: $e');
    }
  }
  // Crear pago detallado (admin)
Future<Map<String, dynamic>> createDetailedPayment({
  required String token,
  required Map<String, dynamic> paymentData,
}) async {
  try {
    print('Creating detailed payment (admin): ${paymentData}');
    
    final response = await http.post(
      Uri.parse('$baseUrl/admin/pagos/detallado'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
      body: json.encode(paymentData),
    );

    print('Create detailed payment response: ${response.statusCode}');
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      // Intentar con la ruta alternativa
      final fallbackResponse = await http.post(
        Uri.parse('$baseUrl/admin/pagos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
        body: json.encode(paymentData),
      );
      
      if (fallbackResponse.statusCode == 200 || fallbackResponse.statusCode == 201) {
        return json.decode(fallbackResponse.body);
      }
      
      print('Error creating detailed payment: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Error al crear pago detallado: ${response.statusCode}');
    }
  } catch (e) {
    print('Error in createDetailedPayment: $e');
    throw Exception('Error al crear pago detallado: $e');
  }
}
  // Crear nuevo pago (admin)
  Future<Map<String, dynamic>> createPayment({
    required String token,
    required Map<String, dynamic> paymentData,
  }) async {
    try {
      print('Creating payment (admin): $paymentData');
      
      final response = await http.post(
        Uri.parse('$baseUrl/admin/pagos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
        body: json.encode(paymentData),
      );

      print('Create payment response: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        print('Error creating payment: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Error al crear pago: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in createPayment: $e');
      throw Exception('Error al crear pago: $e');
    }
  }

  // Aprobar un pago pendiente
  Future<bool> approvePayment(String paymentId, {required String token}) async {
    try {
      print('Approving payment: $paymentId');
      
      final response = await http.put(
        Uri.parse('$baseUrl/admin/pagos/$paymentId/aprobar'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );

      print('Approve payment response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return true;
      } else {
        print('Error approving payment: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error in approvePayment: $e');
      return false;
    }
  }
  // Obtener detalles de un pago específico
  Future<Map<String, dynamic>> getPaymentDetails(String paymentId) async {
    try {
      print('Fetching payment details, ID: $paymentId');
      
      final token = await _storage.read(key: 'token');
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/user/pagos/$paymentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error fetching payment details: ${response.statusCode}');
        throw Exception('Error al obtener detalles del pago: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getPaymentDetails: $e');
      throw Exception('Error al obtener detalles del pago: $e');
    }
  }

  // Crear un nuevo pago por transferencia bancaria
  Future<Map<String, dynamic>> createBankTransferPayment({
    required double amount,
    required List<String> productIds,
    required String bankName,
    required String accountNumber,
    required String referenceNumber,
    String? description,
  }) async {
    try {
      print('Creating bank transfer payment for ${productIds.length} products');
      
      final token = await _storage.read(key: 'token');
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      // Datos del pago por transferencia
      final paymentData = {
        'monto': amount,
        'metodo': 'transferencia_bancaria',
        'productos': productIds,
        'detalles': {
          'banco': bankName,
          'numeroCuenta': accountNumber,
          'numeroReferencia': referenceNumber,
          'descripcion': description ?? 'Pago por transferencia bancaria',
          'fecha': DateTime.now().toIso8601String(),
        }
      };

      print('Sending payment data: $paymentData');

      final response = await http.post(
        Uri.parse('$baseUrl/user/RegistrarPago'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
        body: json.encode(paymentData),
      );

      print('Create payment response: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        
        // Guardar ID del pago para referencia futura
        if (responseData['pagoId'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('lastPaymentId', responseData['pagoId'].toString());
          print('ID de pago guardado: ${responseData['pagoId']}');
        }
        
        // Actualizar historial de transacciones
        await getUserPayments();
        
        return {
          'success': true,
          'data': responseData,
          'pagoId': responseData['pagoId']
        };
      } else {
        print('Error creating payment: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Error al crear pago: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in createBankTransferPayment: $e');
      throw Exception('Error al crear pago: $e');
    }
  }

  // Asociar un pago a un envío
  Future<bool> linkPaymentToShipment({
    required String paymentId,
    required String shipmentId,
  }) async {
    try {
      print('Linking payment $paymentId to shipment $shipmentId');
      
      final token = await _storage.read(key: 'token');
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/user/VincularPagoEnvio'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
        body: json.encode({
          'pagoId': paymentId,
          'envioId': shipmentId,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['success'] == true;
      } else {
        print('Error linking payment to shipment: ${response.statusCode}');
        throw Exception('Error al vincular pago con envío: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in linkPaymentToShipment: $e');
      throw Exception('Error al vincular pago con envío: $e');
    }
  }

  // Subir comprobante de transferencia
  Future<Map<String, dynamic>> uploadTransferReceipt({
    required String paymentId,
    required String imagePath,
  }) async {
    try {
      print('Uploading transfer receipt for payment $paymentId');
      
      final token = await _storage.read(key: 'token');
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      // Crear una solicitud multipart para subir la imagen
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/user/SubirComprobante'),
      );
      
      // Agregar encabezados
      request.headers.addAll({
        'Authorization': token,
      });
      
      // Agregar campos
      request.fields['pagoId'] = paymentId;
      
      // Agregar archivo
      request.files.add(await http.MultipartFile.fromPath(
        'comprobante',
        imagePath,
      ));
      
      // Enviar solicitud
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Upload receipt response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error uploading receipt: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Error al subir comprobante: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in uploadTransferReceipt: $e');
      throw Exception('Error al subir comprobante: $e');
    }
  }

  // Verificar estado de un pago
  Future<Map<String, dynamic>> checkPaymentStatus(String paymentId) async {
    try {
      print('Checking payment status for $paymentId');
      
      final token = await _storage.read(key: 'token');
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/user/EstadoPago/$paymentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error checking payment status: ${response.statusCode}');
        throw Exception('Error al verificar estado del pago: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in checkPaymentStatus: $e');
      throw Exception('Error al verificar estado del pago: $e');
    }
  }

  // Obtener los últimos pagos pendientes
  Future<List<Map<String, dynamic>>> getPendingPayments() async {
    try {
      final payments = await getUserPayments();
      return payments.where((payment) => 
        payment['estado'] == 'Pendiente' || 
        payment['Estado'] == 'Pendiente'
      ).toList();
    } catch (e) {
      print('Error getting pending payments: $e');
      throw Exception('Error al obtener pagos pendientes: $e');
    }
  }

  // Métodos privados para cargar datos iniciales
  Future<void> _loadSavedPaymentMethods() async {
    // En una app real, cargarías desde almacenamiento seguro o una API
    _paymentMethods = [
      PaymentMethod(
        id: 'transferencia-bancaria',
        type: 'bank_transfer',
        name: 'Transferencia Bancaria',
        lastFourDigits: '0000',
        isDefault: true,
      ),
      PaymentMethod(
        id: 'default-card',
        type: 'credit_card',
        name: 'Visa terminada en 4242',
        lastFourDigits: '4242',
      ),
    ];
    _paymentMethodsController.add(_paymentMethods);
  }
  
  Future<void> _loadTransactionHistory() async {
    try {
      await getUserPayments();
    } catch (e) {
      print('Error loading transaction history: $e');
      _transactions = [];
      _transactionsController.add(_transactions);
    }
  }
  
  void dispose() {
    _paymentMethodsController.close();
    _transactionsController.close();
  }
}