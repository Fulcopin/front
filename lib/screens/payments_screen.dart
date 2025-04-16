import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';
import '../services/product_service.dart';
import '../models/product_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart'; // Para Clipboard
import 'dart:async';
import 'dart:math';
import '../screens/my_shipments_screen.dart';
import '../services/shipment_service.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'package:synchronized/synchronized.dart';
class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({Key? key}) : super(key: key);

  @override
  _PaymentsScreenState createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final ProductService _productService = ProductService();
  final storage = FlutterSecureStorage();
  bool _isTransactionProcessed = false;
final _processingLock = Lock();
  double _subtotal = 0.0;
  bool _includeHomeDelivery = false;
  final double _homeDeliveryCharge = 6.0;
double _iva = 0.0;
 Timer? _timer;
 bool _isPaymentVerificationActive = false;
String _lastProcessedTransactionId = '';
  bool _isShowingSuccessMessage = false;
  String? _clientTransactionId;
  Timer? _paymentCheckTimer;
  List<Product> _products = [];
  Set<String> _selectedProductIds = {};
  double _totalAmount = 0.0;
  bool _isLoadingProducts = true;
  String _paymentMethod = 'card'; // 'card' o 'transfer'
  bool _isProcessingPayment = false;
  File? _receiptImage;
  String? _paymentUrl;
  double _total_iva=0.0;
  double _totalWithDelivery=0.0;

  @override
  void initState() {
    super.initState();
    _isShowingSuccessMessage = false;
    _isPaymentVerificationActive = false;
    _loadPendingTransaction();
   
    _loadProducts();
  }
  // Agregar esta función para generar IDs de transacción
String generateTransactionId() {
  final random = Random();
  final randomPart = random.nextInt(10000).toString().padLeft(4, '0');
  final timestampPart = DateTime.now().millisecondsSinceEpoch % 10000000;
  return 'TX${timestampPart}${randomPart}';
}
  Future<void> _loadProducts() async {
    setState(() {
      _isLoadingProducts = true;
    });

    try {
      final products = await _productService.getProducts();
      
      // Diagnóstico
      print("===== DIAGNÓSTICO DE PRODUCTOS =====");
      print("Total de productos: ${products.length}");
      
      // Filtrar productos en bodega
      final productsInWarehouse = products.where((p) {
        if (p.estado == null) return false;
        final estadoLower = p.estado!.toLowerCase();
        return estadoLower == 'en bodega' || estadoLower == 'enbodega';
      }).toList();
      
      print("Productos en bodega: ${productsInWarehouse.length}");
      print("===================================");
      
      setState(() {
        _products = productsInWarehouse;
        _isLoadingProducts = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingProducts = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar productos: $e'))
      );
    }
  }
 Future<void> _createShipmentAfterPayment(String transactionId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final String shipmentKey = 'shipment_created_for_$transactionId';
    
    // Double-check with shared preferences
    if (prefs.getBool(shipmentKey) == true) {
      print('🔄 Envío ya registrado para transacción $transactionId. Evitando duplicado.');
      return;
    }
    
    // Mark as being processed immediately to prevent duplicates
    await prefs.setBool(shipmentKey, true);
    
    // Get payment ID from preferences or use transaction ID
    String? pagoId = prefs.getString('lastPaymentId');
    if (pagoId == null || pagoId.isEmpty) {
      pagoId = transactionId;
    }
    
    print('📦 Creando envío con ID de pago: $pagoId');
    // Get product IDs - IMPORTANT: This is what was missing
    final List<String> productIds = _selectedProductIds.toList();
    print('Productos a incluir en el envío: $productIds');
    
    if (productIds.isEmpty) {
      throw Exception('No hay productos seleccionados para el envío');
    }
    
    
    // Get token and address
    final storage = FlutterSecureStorage();
    String? token = await storage.read(key: 'token');
    String? direccion = prefs.getString('userAddress');
    String? ciudad = prefs.getString('userCity');
    String? pais = prefs.getString('userCountry');
    if (token == null || token.isEmpty) {
      token = await prefs.getString('token');
    }
    
    // Ensure we have an address
    if (direccion == null || direccion.isEmpty) {
      direccion = "10 de agosto, jipijapa, Ecuador"; // Default fallback
    }
    // Format address based on delivery option
      String direccionFinal;
      if (_includeHomeDelivery) {
        // Format: direccion - ciudad - envio a domicilio
        direccionFinal = "$direccion - ${ciudad ?? ''} - envio a domicilio";
      } else {
        // Just use the original address
        direccionFinal = ciudad?? '';
      }
    
    
    // Create shipment with proper error handling
    final shipmentService = ShipmentService();
    final shipmentResult = await shipmentService.registerShipment(
      direccion: direccionFinal,
      pagoId: pagoId,
      token: token ?? '',
      origen: "Miami, FL",
      productIds: productIds, 
    );
    
    print('Resultado de creación de envío: $shipmentResult');
    
    if (shipmentResult['success'] != true) {
      throw Exception('Error al crear envío: ${shipmentResult['message'] ?? "Error desconocido"}');
    }
    
    print('✅ Envío creado correctamente');
  } catch (e) {
    print('❌ ERROR al crear envío: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error al crear envío: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  // Add this method to your _PaymentsScreenState class
 // Add this method to your _PaymentsScreenState class
Future<void> _debugTokenAndAddress() async {
  try {
    print('=== DIAGNÓSTICO DE DATOS DE USUARIO ===');
    
    // Check token in FlutterSecureStorage
    final secureStorage = FlutterSecureStorage();
    final secureToken = await secureStorage.read(key: 'token');
    print('Token en SecureStorage: ${secureToken != null ? 'ENCONTRADO' : 'NO ENCONTRADO'}');
    if (secureToken != null) {
      print('  - Longitud: ${secureToken.length}');
      print('  - Primeros 10 caracteres: ${secureToken.substring(0, math.min(10, secureToken.length))}...');
    }
    
    // Check all keys in SecureStorage
    final allKeys = await secureStorage.readAll();
    print('Claves en SecureStorage: ${allKeys.keys}');
    
    // Check token in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final prefsToken = prefs.getString('token');
    print('Token en SharedPreferences: ${prefsToken != null ? 'ENCONTRADO' : 'NO ENCONTRADO'}');
    
    // Check address in SharedPreferences
    final address = prefs.getString('userAddress');
    print('Dirección en SharedPreferences: ${address != null ? 'ENCONTRADO' : 'NO ENCONTRADO'}');
    if (address != null) {
      print('  - Valor: "$address"');
    }
    
    // Check alternative address keys
    final alternatives = ['direccion', 'userDireccion', 'direccionUsuario'];
    for (final key in alternatives) {
      final value = prefs.getString(key);
      print('$key en SharedPreferences: ${value != null ? 'ENCONTRADO' : 'NO ENCONTRADO'}');
    }
    
    // Check user profile JSON
    final userProfile = prefs.getString('userProfile');
    print('userProfile en SharedPreferences: ${userProfile != null ? 'ENCONTRADO' : 'NO ENCONTRADO'}');
    if (userProfile != null) {
      try {
        final profileData = json.decode(userProfile);
        print('  - Dirección en perfil: ${profileData['direccion'] ?? 'NO ENCONTRADO'}');
        print('  - Ciudad en perfil: ${profileData['ciudad'] ?? 'NO ENCONTRADO'}');
      } catch (e) {
        print('  - Error al parsear userProfile: $e');
      }
    }
    
    print('======================================');
  } catch (e) {
    print('Error en diagnóstico: $e');
  }
}
// Add these fields to your class


// Replace your _startPaymentStatusCheck method with this improved version
void _startPaymentStatusCheck(String transactionId) {
  print('Iniciando verificación de pago para transactionId: $transactionId');
  
  // Don't start a new verification if one is already running
  if (_isPaymentVerificationActive) {
    print('Ya hay una verificación en progreso. Ignorando solicitud adicional.');
    return;
  }
  
  setState(() {
    _isPaymentVerificationActive = true;
  });
  
  // Create transaction processed key for this specific transaction
  final String processedKey = 'transaction_processed_$transactionId';
  
  // Crear un timer que verifica el estado del pago cada 3 segundos
  _timer = Timer.periodic(Duration(seconds: 3), (timer) async {
    try {
      // Check if already processed first - most efficient check
      if (_isTransactionProcessed) {
        print('Transacción ya procesada en memoria. Cancelando verificación.');
        timer.cancel();
        setState(() {
          _isPaymentVerificationActive = false;
        });
        return;
      }
      
      // Check in persistent storage
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(processedKey) == true) {
        print('Transacción ya procesada según SharedPreferences. Cancelando verificación.');
        _isTransactionProcessed = true;
        timer.cancel();
        setState(() {
          _isPaymentVerificationActive = false;
        });
        return;
      }
      
      // Verificar que transactionId no esté vacío
      if (transactionId == null || transactionId.isEmpty) {
        print('ERROR: TransactionId es nulo o vacío');
        timer.cancel();
        setState(() {
          _isPaymentVerificationActive = false;
        });
        return;
      }
      
      print('Llamando a checkPaymentStatus con ID: $transactionId (Intento ${timer.tick})');
      Map<String, dynamic> response = await ProductService().checkPaymentStatus(transactionId);
      
      // Verificar si el pago fue exitoso basado en la respuesta
      bool success = false;
      
      if (response.containsKey('transactionStatus')) {
        success = response['transactionStatus'] == 'Approved';
      } else if (response.containsKey('success')) {
        success = response['success'] == true;
      }
      
      if (success) {
        // Use synchronization to ensure only one thread processes this transaction
        bool shouldProcess = false;
        
        await _processingLock.synchronized(() async {
  // Double-check if processed
            if (!_isTransactionProcessed && prefs.getBool(processedKey) != true) {
              // Mark as processed immediately in both memory and storage
              _isTransactionProcessed = true;
              await prefs.setBool(processedKey, true);
              shouldProcess = true;
            }
          });
        
        if (!shouldProcess) {
          print('Transacción marcada como procesada durante sincronización. Cancelando procesamiento adicional.');
          timer.cancel();
          setState(() {
            _isPaymentVerificationActive = false;
          });
          return;
        }
        
        // Cancel timer first to prevent more verification attempts
        timer.cancel();
        
        print('✅ Pago confirmado como exitoso. Iniciando procesamiento...');
        _lastProcessedTransactionId = transactionId;
        
        // Update UI state
        setState(() {
          _isPaymentVerificationActive = false;
        });
        
        // Process the payment - only once
        await _processSuccessfulPayment(transactionId, response);
      } else if (timer.tick > 100) { // Reduced from 200 to 100 (5 minutes max)
        timer.cancel();
        setState(() {
          _isPaymentVerificationActive = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo verificar el pago después de varios intentos. Intente nuevamente.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('ERROR al verificar pago: $e');
      
      if (timer.tick > 5) {
        timer.cancel();
        setState(() {
          _isPaymentVerificationActive = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error verificando pago: $e')),
        );
      }
    }
  });
}

// New method to centralize successful payment processing
Future<void> _processSuccessfulPayment(String transactionId, Map<String, dynamic> paymentData) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final processedKey = 'transaction_processed_$transactionId';
    
    // Extra safety check - don't process if already done
    if (prefs.getBool(processedKey) != true) {
      print('⚠️ ERROR: Intento de procesar transacción sin marcarla primero');
      await prefs.setBool(processedKey, true);
    }
    
    // 1. Mark products as paid
    final List<String> productIds = _selectedProductIds.toList();
    print('Productos a marcar como pagados: $productIds');
    
    if (productIds.isEmpty) {
      print('⚠️ ERROR: No hay productos seleccionados para procesar');
      return;
    }
    
    // 2. Mark products as paid in the backend
    final markSuccess = await _productService.markProductsAsPaidAsUser(productIds);
    if (!markSuccess) {
      throw Exception('No se pudo marcar los productos como pagados');
    }
    
    // 3. Register the payment in the backend - this should return the payment ID
    final paymentResult = await _productService.registerPayment(
      transactionId,
      _totalWithDelivery,
      productIds,
      paymentData,
    );
    
    print('Resultado de registro de pago: $paymentResult');
    
    // 4. Create the shipment using the payment ID from the backend response
    final shipmentKey = 'shipment_created_for_$transactionId';
    if (prefs.getBool(shipmentKey) != true) {
      await _createShipmentAfterPayment(transactionId);
      await prefs.setBool(shipmentKey, true);
    }
    
    // 5. Show success message and navigate
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pago procesado correctamente. Redirigiendo...'),
        backgroundColor: Colors.green,
      ),
    );
    
    // Small delay before navigating
    await Future.delayed(Duration(seconds: 1));
    
    // 6. Navigate to shipments screen
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => MyShipmentsScreen()),
      (route) => false
    );
  } catch (e) {
    print('ERROR al procesar pago exitoso: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error al procesar el pago: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
  void _updateSelectedProducts(String productId, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedProductIds.add(productId);
      } else {
        _selectedProductIds.remove(productId);
      }
      _calculateTotal();
    });
  }

  void _calculateTotal() {
  // Calcular subtotal (suma de productos)
  
   double pesoTotal = 0.0;
  for (final product in _products) {
    if (_selectedProductIds.contains(product.id)) {
      pesoTotal += product.peso;
    }
  }
  double subtotal = 0.0;
  if (pesoTotal < 1.0 && pesoTotal > 0) {
    subtotal = 5.5;
  } else {
    // Si es 1 libra o más, cobrar $5.5 por libra
    subtotal = pesoTotal * 5.5;
  }
  // Calcular IVA (15%)
  double iva = subtotal * 0.15;
  
  // Calcular total con IVA
  double totalConIva = subtotal + iva;
  
  // Redondear a 2 decimales
  final subtotalRedondeado = double.parse(subtotal.toStringAsFixed(2));
  final ivaRedondeado = double.parse(iva.toStringAsFixed(2));
  final totalRedondeado = double.parse(totalConIva.toStringAsFixed(2));
  
  setState(() {
    _subtotal = subtotalRedondeado;  // Guarda el subtotal para usarlo en la UI si es necesario
    _iva = ivaRedondeado;           // Guarda el IVA para usarlo en la UI si es necesario
    _totalAmount = subtotalRedondeado;
    _total_iva= _totalAmount+_iva; // Actualiza el total con IVA
  });
  
  
}

 
Future<void> _processCardPayment() async {
  if (_selectedProductIds.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Selecciona al menos un producto para pagar'))
    );
    return;
  }
  // Calculate the total including delivery if selected
  final double _total_iva = _totalAmount * 1.15;
  final double totalWithDelivery = _total_iva + (_includeHomeDelivery ? _homeDeliveryCharge : 0);
  // Asegurar que el monto tenga 2 decimales
  final exactAmount = double.parse(totalWithDelivery.toStringAsFixed(2));
  final finul=totalWithDelivery-(_totalAmount * 0.15);
  // Generar y guardar el ID de transacción
  final clientTransactionId = generateTransactionId();
  setState(() {
    _clientTransactionId = clientTransactionId;
  });
  _startPaymentStatusCheck(clientTransactionId);
  
  // Guardar en almacenamiento persistente
  await storage.write(key: 'current_transaction_id', value: clientTransactionId);
  
  print('ID de transacción generado: $clientTransactionId');
  
  setState(() {
    _isProcessingPayment = true;
  });

  try {
    print('Enviando monto para pago: $exactAmount');
    
    // Enviar ID generado a la API
    final result = await _productService.generateCardPayment(
      subtotal: finul,
      clientTransactionId: clientTransactionId  
    );
    
    setState(() {
      _isProcessingPayment = false;
    });

    if (result['success'] == true) {
      // Obtener URL de pago
      final String paymentUrl = result['paymentUrl'] ?? result['response'];
      
      if (paymentUrl != null && paymentUrl.isNotEmpty) {
        setState(() {
          _paymentUrl = paymentUrl;
        });
        
        // Iniciar verificación del pago
        _startPaymentStatusCheck(clientTransactionId);
        
        // Abrir URL de pago
        _openPaymentUrl(paymentUrl);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se recibió un enlace de pago válido')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${result['message'] ?? "Error desconocido"}')),
      );
    }
  } catch (e) {
    setState(() {
      _isProcessingPayment = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al procesar el pago: $e')),
    );
  }
}
// Método para verificar el estado del pago con respaldo manual

// Método para mostrar confirmación manual
void _showManualConfirmation() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text('¿Has completado el pago?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Si ya realizaste el pago en la página externa, puedes continuar.'),
          SizedBox(height: 10),
          Text('De lo contrario, vuelve a intentarlo más tarde.'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Todavía no'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            _showPaymentSuccessMessage();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          child: Text('Sí, completé el pago'),
        ),
      ],
    ),
  );
}
// Método para abrir URL y comenzar verificación periódica
Future<void> _openPaymentUrl(String paymentUrl) async {
  try {
    final uri = Uri.parse(paymentUrl);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    final String clientTransactionId = _clientTransactionId ?? "1233";
    if (launched) {
      // Comenzar a verificar periódicamente el estado del pago
      _startPaymentStatusCheck(clientTransactionId);
      
      // Mostrar mensaje informativo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verificando estado del pago...'))
      );
    } else {
      // Si falló el lanzamiento automático, mostrar Snackbar con la URL
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('No se pudo abrir automáticamente el enlace de pago.'),
              SizedBox(height: 4),
              SelectableText(paymentUrl, style: TextStyle(color: Colors.white)),
            ],
          ),
          duration: Duration(seconds: 15),
          action: SnackBarAction(
            label: 'Copiar',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: paymentUrl));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Enlace copiado al portapapeles'))
              );
            },
          ),
        ),
      );
    }
  } catch (e) {
    // Código para manejo de errores...
  }
}


void _showPaymentSuccessMessage() {
  // Evitamos múltiples navegaciones o mensajes
  if (_isShowingSuccessMessage) return;
  _isShowingSuccessMessage = true;
  
  // Mostrar el diálogo con los detalles
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Colors.green,
            size: 80,
          ),
          SizedBox(height: 16),
          Text(
            '¡Pago Exitoso!',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Tu pago ha sido procesado correctamente.',
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          // Detalles del pago con desglose
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Subtotal:'),
                    Text(
                      '\$${_subtotal.toStringAsFixed(2)} USD',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('IVA (15%):'),
                    Text(
                      '\$${_iva.toStringAsFixed(2)} USD',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total pagado:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '\$${_totalAmount.toStringAsFixed(2)} USD',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Container(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Crear el envío después de cerrar el diálogo
            
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text('Continuar a Envíos'),
          ),
        ),
      ],
    ),
  );
  
  // Después de 3 segundos, navegamos a la pantalla de envíos
  Future.delayed(Duration(seconds: 3), () {
    _isShowingSuccessMessage = false;
  });
}
  Future<void> _loadPendingTransaction() async {
  final storage = FlutterSecureStorage();
  String? transactionId = await storage.read(key: 'pendingTransactionId');
  
  // Solo verificar si hay un transactionId pendiente y no se ha verificado antes
  if (transactionId != null && transactionId.isNotEmpty && 
      transactionId != _lastProcessedTransactionId && 
      !_isPaymentVerificationActive) {
    
    setState(() {
      _isPaymentVerificationActive = true;
    });
    
    _startPaymentStatusCheck(transactionId);
  }
}


Future<void> _processTransferPayment() async {
  if (_selectedProductIds.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Selecciona al menos un producto para pagar'))
    );
    return;
  }

  if (_receiptImage == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Debes subir un comprobante de la transferencia'))
    );
    return;
  }

  setState(() {
    _isProcessingPayment = true;
  });

  try {
    // Simulación de subida y procesamiento
    await Future.delayed(const Duration(seconds: 2)); // Simula el tiempo de carga
    
    print('Transferencia simulada:');
    print('- Productos seleccionados: ${_selectedProductIds.length}');
    print('- Total: \$${_totalAmount.toStringAsFixed(2)}');
    print('- Imagen seleccionada: ${_receiptImage?.path}');
    
    setState(() {
      _isProcessingPayment = false;
    });
    
    // Mensaje de éxito
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Simulación de pago registrada correctamente'),
        backgroundColor: Colors.green,
      )
    );
    
    // Limpiar selección
    setState(() {
      _selectedProductIds.clear();
      _receiptImage = null;
      _calculateTotal();
    });
  } catch (e) {
    setState(() {
      _isProcessingPayment = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al procesar el pago: $e'))
    );
  }
}


  // Método para seleccionar imagen
  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        setState(() {
          _receiptImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e'))
      );
    }
  }
  
  @override
void dispose() {
  if (_timer != null && _timer!.isActive) {
    _timer!.cancel();
  }
  if (_paymentCheckTimer != null && _paymentCheckTimer!.isActive) {
    _paymentCheckTimer!.cancel();
  }
  super.dispose();
}
  @override
  Widget build(BuildContext context) {
    // First, make sure these variables are declared in your class
   
    
    final double _total_iva = _totalAmount * 1.15;
    final double totalWithDelivery = _total_iva + (_includeHomeDelivery ? _homeDeliveryCharge : 0);
    _totalWithDelivery=totalWithDelivery ;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagos'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Existing heading and description...
            
            // Lista de productos para seleccionar
            _buildProductsList(),
            
            const SizedBox(height: 16),
            
            // Add Home Delivery Option Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Opciones de Entrega',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      title: const Text('Envío a domicilio'),
                      subtitle: Text('Costo adicional: \$${_homeDeliveryCharge.toStringAsFixed(2)}'),
                      value: _includeHomeDelivery,
                      activeColor: AppTheme.primaryColor,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) {
                        setState(() {
                          _includeHomeDelivery = value ?? false;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Resumen de pago (updated)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resumen del Pago',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal'),
                        Text('\$${_totalAmount.toStringAsFixed(2)}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('IVA (15%)'),
                        Text('\$${(_totalAmount * 0.15).toStringAsFixed(2)}'),
                      ],
                    ),
                    // Add delivery charge row if selected
                    if (_includeHomeDelivery) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Envío a domicilio'),
                          Text('\$${_homeDeliveryCharge.toStringAsFixed(2)}'),
                        ],
                      ),
                    ],
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\$${totalWithDelivery.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            
            // Métodos de pago
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Método de Pago',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Selector de método de pago
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: Row(
                              children: const [
                                Icon(Icons.credit_card),
                                SizedBox(width: 8),
                                Text('Tarjeta'),
                              ],
                            ),
                            value: 'card',
                            groupValue: _paymentMethod,
                            onChanged: (value) => setState(() => _paymentMethod = value!),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: Row(
                              children: const [
                                Icon(Icons.account_balance),
                                SizedBox(width: 8),
                                Text('Transferencia'),
                              ],
                            ),
                            value: 'transfer',
                            groupValue: _paymentMethod,
                            onChanged: (value) => setState(() => _paymentMethod = value!),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Contenido específico del método de pago
                    if (_paymentMethod == 'card') ...[
                      const Text(
                        'El pago con tarjeta se procesará a través de un servicio externo. Al continuar, serás redirigido a la plataforma de pago.',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      if (_paymentUrl != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: InkWell(
                            onTap: () async {
                              final uri = Uri.parse(_paymentUrl!);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            },
                            child: Text(
                              'Volver a abrir enlace de pago',
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                     SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    onPressed: _selectedProductIds.isEmpty || _isProcessingPayment
        ? null
        : _processCardPayment,
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.all(16),
    ),
    child: _isProcessingPayment
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 8),
              Text('Procesando...'),
            ],
          )
        : Text('Pagar con Tarjeta \$${totalWithDelivery.toStringAsFixed(2)}'),
  ),
),
] else if (_paymentMethod == 'transfer') ...[
  _buildTransferPaymentInstructions(),
  const SizedBox(height: 16),
  SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: _selectedProductIds.isEmpty || _isProcessingPayment
          ? null
          : () {
              // Show confirmation dialog and handle transfer payment
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirmar pago por transferencia'),
                  content: const Text(
                    'Al confirmar esta opción, se registrará su pedido y deberá enviar el comprobante de transferencia al número indicado para completar el proceso.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _processTransferPayment();
                      },
                      child: const Text('Confirmar'),
                    ),
                  ],
                ),
              );
            },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(16),
      ),
      child: _isProcessingPayment
          ? const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 8),
                Text('Procesando...'),
              ],
            )
          : const Text('Confirmar Pago por Transferencia'),
    ),
  ),
],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // Add this method to your _PaymentsScreenState class

Widget _buildTransferDetailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(
              fontSize: 15,
            ),
          ),
        ),
      ],
    ),
  );
}
  Widget _buildTransferPaymentInstructions() {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.blue.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.blue.shade200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.account_balance, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            Text(
              'Información para Transferencia Bancaria',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
          ],
        ),
        const Divider(height: 24),
        _buildTransferDetailRow('Banco:', 'Guayaquil'),
        _buildTransferDetailRow('Número de cuenta:', '0016099966'),
        _buildTransferDetailRow('Tipo de cuenta:', 'AHORRO'),
        _buildTransferDetailRow('Nombre:', 'VACA GARCIA WILSON RICARDO'),
        _buildTransferDetailRow('Cédula:', '0956746382'),
        _buildTransferDetailRow('Email:', 'wilsonvaca16@gmail.com'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Instrucciones importantes:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Una vez realizada la transferencia, envíe su comprobante al número de teléfono +593962579977.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                'En un plazo de 1 a 2 días hábiles se creará su envío.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
  Widget _buildProductsList() {
    if (_isLoadingProducts) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Filtrar solo productos con estado "En bodega"
    final productsInWarehouse = _products.where((p) {
      if (p.estado == null) return false;
      
      final estadoLower = p.estado!.toLowerCase();
      return estadoLower == 'en bodega' || estadoLower == 'enbodega';
    }).toList();

    if (productsInWarehouse.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No tienes productos listos para pago (en bodega)',
            style: TextStyle(
              color: AppTheme.mutedTextColor,
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Productos En Bodega - Listos para Pago',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _selectedProductIds.isEmpty 
                    ? null 
                    : () {
                        setState(() {
                          _selectedProductIds.clear();
                          _calculateTotal();
                        });
                      },
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Limpiar Selección'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: productsInWarehouse.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final product = productsInWarehouse[index];
                final isSelected = _selectedProductIds.contains(product.id);
                
                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (value) {
                    _updateSelectedProducts(product.id, value ?? false);
                  },
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'En bodega',
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.descripcion),
                      const SizedBox(height: 4),
                      
                    ],
                  ),
                  secondary: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'PESO: ${(product.peso ).toStringAsFixed(2)} lb',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  activeColor: AppTheme.primaryColor,
                  checkColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isSelected 
                        ? AppTheme.primaryColor 
                        : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  tileColor: isSelected 
                    ? AppTheme.primaryColor.withOpacity(0.05) 
                    : null,
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Productos seleccionados: ${_selectedProductIds.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Total: \$${_totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}