
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/shipment_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_service.dart';
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
// Función mejorada para enviar notificación de WhatsApp con datos completos del usuario
Future<void> _sendWhatsAppNotificationWithUserData(Map<String, dynamic> shipment) async {
  try {
    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Obteniendo datos del cliente...'),
        content: SizedBox(
          height: 100,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
    
    // Extraer el ID del usuario del envío - ESTA ES LA PARTE CRÍTICA
    String? userId;
    
    // Verificar todas las posibles ubicaciones del ID de usuario en el objeto de envío
    if (shipment['usuario'] != null) {
      if (shipment['usuario'] is Map) {
        userId = shipment['usuario']['id']?.toString();
        print('ID de usuario encontrado en shipment.usuario.id: $userId');
      } else if (shipment['usuario'] is String) {
        userId = shipment['usuario'].toString();
        print('ID de usuario encontrado en shipment.usuario (string): $userId');
      }
    }
    
    // Si no lo encontramos arriba, buscar en otras posibles ubicaciones
    if (userId == null || userId.isEmpty) {
      userId = shipment['userId']?.toString() ?? 
               shipment['idUsuario']?.toString() ?? 
               shipment['user_id']?.toString() ??
               shipment['id_usuario']?.toString();
      
      print('ID de usuario encontrado en otra propiedad: $userId');
    }
    
    // Imprimir todo el objeto shipment para diagnóstico
    print('Objeto shipment completo: ${shipment.toString()}');
    
    // Si no hemos encontrado el ID aún, intentar extraerlo de un campo específico o referencia
    if (userId == null || userId.isEmpty) {
      // Buscar en campos de referencia que puedan contener el ID del usuario
      final possibleRefs = [
        'usuarioRef', 'clienteRef', 'userRef', 'referencia_usuario',
        'cliente', 'cliente_id', 'user', 'customer'
      ];
      
      for (final field in possibleRefs) {
        if (shipment[field] != null) {
          print('Posible referencia encontrada en campo $field: ${shipment[field]}');
          if (shipment[field] is String) {
            userId = shipment[field].toString();
            print('Usando referencia como ID: $userId');
            break;
          } else if (shipment[field] is Map && shipment[field]['id'] != null) {
            userId = shipment[field]['id'].toString();
            print('Usando ID de objeto referenciado: $userId');
            break;
          }
        }
      }
    }
    
    // Si aún no encontramos un ID, usar un ID específico para pruebas
    if (userId == null || userId.isEmpty) {
      userId = 'nulo'; // ID específico para pruebas
      print('No se encontró ID de usuario en el envío, usando ID de prueba: $userId');
    }
    
    // Obtener datos completos del usuario
    final userData = await _getUserDataById(userId);
    
    // Cerrar diálogo de carga
    Navigator.pop(context);
    
    if (userData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudieron obtener los datos del cliente'))
      );
      return;
    }
    
    // Extraer información del envío
    final trackingNumber = shipment['numeroSeguimiento']?.toString() ?? 
                         shipment['tracking']?.toString() ??
                         shipment['id']?.toString() ?? 
                         'No disponible';
                         
    final status = shipment['status']?.toString() ?? 
                shipment['Estado']?.toString() ?? 
                shipment['estado']?.toString() ?? 
                'Procesando';
    
    // Extraer información del usuario
    final nombre = userData['nombre']?.toString() ?? '';
    final apellido = userData['apellido']?.toString() ?? '';
    final telefono = userData['telefono']?.toString() ?? '';
    final direccion = userData['direccion']?.toString() ?? '';
    final ciudad = userData['ciudad']?.toString() ?? '';
    final pais = userData['pais']?.toString() ?? '';
    
    // Formatear nombre completo
    final clientName = [nombre, apellido].where((part) => part != null && part.isNotEmpty).join(' ');
    
    // Verificar si tenemos un número de teléfono
    if (telefono.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El cliente no tiene un número de teléfono registrado'))
      );
      return;
    }
    
    // Formatear dirección completa
    final addressParts = [direccion, ciudad, pais]
        .where((part) => part != null && part.isNotEmpty)
        .toList();
    final fullAddress = addressParts.join(', ');
    
    // Mostrar diálogo de confirmación
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
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ID del usuario (para verificación)
              Text('ID Usuario: $userId', style: TextStyle(fontSize: 12, color: Colors.grey)),
              SizedBox(height: 8),
              
              // Datos del cliente
              Text('Cliente:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(clientName),
              SizedBox(height: 8),
              
              // Teléfono
              Text('Teléfono:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(telefono),
              SizedBox(height: 8),
              
              // Dirección
              Text('Dirección:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(fullAddress),
              SizedBox(height: 12),
              
              Divider(),
              SizedBox(height: 8),
              
              // Información del envío
              Text('Detalles del envío:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('Tracking: $trackingNumber'),
              Text('Estado: ${_getStatusDisplayName(status)}', style: TextStyle(color: Colors.green)),
              SizedBox(height: 12),
              
              Text('¿Desea enviar una notificación a este cliente sobre el estado de su envío?'),
            ],
          ),
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
            label: const Text('Enviar notificación'),
            onPressed: () {
              Navigator.pop(context);
              
              // Enviar notificación WhatsApp con toda la información
              _sendWhatsAppMessage(
                telefono: telefono,
                clientName: clientName.isNotEmpty ? clientName : 'Cliente',
                trackingNumber: trackingNumber,
                status: status,
                address: fullAddress,
                shipmentId: shipment['id']?.toString() ?? '',
                 userId: userId ?? '',   // Incluir ID de usuario para registro
              );
            },
          ),
        ],
      ),
    );
  } catch (e) {
    // Cerrar diálogo de carga si hay error
    Navigator.pop(context);
    
    print('Error en notificación WhatsApp: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e'))
    );
  }
}
// Función para enviar mensaje de WhatsApp con información completa del usuario y envío
Future<void> _sendWhatsAppMessage({
  required String telefono,
  required String clientName,
  required String trackingNumber,
  required String status,
  required String address,
  required String shipmentId,
  required String userId,
}) async {
  try {
    // Formatear el número de teléfono
    String formattedPhone = _formatPhoneNumber(telefono);
    
    print('Enviando WhatsApp a: $formattedPhone');
    print('Cliente: $clientName');
    print('Tracking: $trackingNumber');
    print('Estado: $status');
    
    // Crear el mensaje personalizado
    String message = '¡Hola $clientName! Tu envío con tracking: $trackingNumber ha sido actualizado a estado: *${_getStatusDisplayName(status)}*. ';
    
    // Añadir información de dirección si está disponible
    if (address.isNotEmpty) {
      message += 'Dirección de entrega: $address. ';
    }
    
    // Agregar mensaje final
    message += 'Gracias por usar nuestros servicios de VACABOX.';
    
    // Codificar el mensaje para URL
    String encodedMessage = Uri.encodeComponent(message);
    
    // Crear URL de WhatsApp
    String whatsappUrl = 'https://wa.me/$formattedPhone?text=$encodedMessage';
    
    print('URL de WhatsApp: $whatsappUrl');
    
    // Abrir WhatsApp
    final Uri url = Uri.parse(whatsappUrl);
    
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('No se pudo abrir WhatsApp');
    }
    
    // Registrar que se envió la notificación
    await _logNotificationSent(shipmentId, formattedPhone, status, clientName);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Abriendo WhatsApp para enviar notificación...'))
    );
  } catch (e) {
    print('Error enviando mensaje de WhatsApp: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al enviar notificación: $e'))
    );
  }
}
// Función para obtener los datos completos del usuario usando el servicio existente
Future<Map<String, dynamic>?> _getUserDataById(String userId) async {
  try {
    print('Obteniendo datos del usuario con ID: $userId');
    
    // Obtener el token de autenticación
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    
    if (token == null) {
      print('Error: No se encontró token de autenticación');
      return null;
    }
    
    // Usar el servicio existente para obtener los detalles del usuario
    UserService userService = UserService();
    final userData = await userService.getUserDetails(userId, token: token);
    
    if (userData != null && userData['success'] == true && userData['usuario'] != null) {
      print('Datos del usuario obtenidos correctamente');
      return userData['usuario'];
    } else {
      print('No se encontraron datos del usuario');
      return null;
    }
  } catch (e) {
    print('Error obteniendo datos del usuario: $e');
    return null;
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

  // Fix 1: Remove one of the duplicate buttons
// Fix 2: Add proper implementation of _sendWhatsAppNotification with string parameters

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
          _sendWhatsAppNotificationSimple(
            phoneNumber,
            trackingNumber,
            status,
            clientName,
            shipmentId: shipment['id']?.toString() ?? '',
          );
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

// Add this new method to handle direct string parameters
Future<void> _sendWhatsAppNotificationSimple(
  String phoneNumber,
  String trackingNumber,
  String status,
  String clientName,
  {required String shipmentId}
) async {
  try {
    // Formatear el número de teléfono
    String formattedPhone = _formatPhoneNumber(phoneNumber);
    
    // Crear el mensaje personalizado
    String message = '¡Hola $clientName! Tu envío con tracking: $trackingNumber ha sido actualizado a estado: *$status*. ';
    
    // Agregar mensaje final
    message += 'Gracias por usar nuestros servicios de VACABOX.';
    
    // Codificar el mensaje para URL
    String encodedMessage = Uri.encodeComponent(message);
    
    // Crear URL de WhatsApp
    String whatsappUrl = 'https://wa.me/$formattedPhone?text=$encodedMessage';
    
    // Abrir WhatsApp
    final Uri url = Uri.parse(whatsappUrl);
    
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('No se pudo abrir WhatsApp');
    }
    
    // Registrar que se envió la notificación
    await _logNotificationSent(shipmentId, formattedPhone, status, clientName);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Abriendo WhatsApp para enviar notificación...'))
    );
  } catch (e) {
    print('Error enviando notificación WhatsApp: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al enviar notificación: $e'))
    );
  }
}

// Add helper method for status display names if it doesn't exist
String _getStatusDisplayName(String status) {
  switch (status.toLowerCase()) {
    case 'procesando':
      return 'Procesando';
    case 'en tránsito':
    case 'en transito':
      return 'En tránsito';
    case 'en bodega':
      return 'En bodega';
    case 'en aduana':
      return 'En aduana';
    case 'en país destino':
    case 'en pais destino':
      return 'En país destino';
    case 'en ruta entrega':
      return 'En ruta para entrega';
    case 'entregado':
      return 'Entregado';
    default:
      return status;
  }
}

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

// Función mejorada para enviar mensaje de WhatsApp
Future<void> _sendWhatsAppNotification(Map<String, dynamic> shipment, String newStatus) async {
  try {
    // Obtener ID del envío
    String shipmentId = shipment['id']?.toString() ?? 
                      shipment['Id']?.toString() ?? 
                      shipment['ID']?.toString() ?? 
                      'No disponible';
    
    // Obtener el ID del usuario asociado al envío
    String? userId = shipment['userId']?.toString() ?? 
                   shipment['idUsuario']?.toString() ?? 
                   shipment['user_id']?.toString();
                   
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontró ID de usuario para este envío'))
      );
      return;
    }
    
    // Obtener los datos del usuario desde SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    
    // Estos son los datos que están guardados en SharedPreferences según tu código
    String nombre = prefs.getString('name') ?? '';
    String apellido = prefs.getString('apellido') ?? '';
    String? telefonoRaw = prefs.getString('telefono');
    String telefono = telefonoRaw ?? '';
    String direccion = shipment['direccion']?.toString() ?? 
                      prefs.getString('userAddress') ?? 
                      'Dirección no disponible';
    String ciudad = prefs.getString('userCity') ?? '';
    String pais = prefs.getString('userCountry') ?? '';
    
    // Verificar si tenemos el número de teléfono
    if (telefono.isEmpty) {
      // Si no tenemos el teléfono, intentar buscarlo en el objeto shipment
      telefono = shipment['telefono']?.toString() ?? 
                shipment['phone']?.toString() ?? 
                '';
      
      if (telefono.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró número de teléfono para este cliente'))
        );
        return;
      }
    }
    
    // Formatear el nombre completo del cliente
    String fullName = '';
    if (nombre.isNotEmpty) {
      fullName = nombre;
      if (apellido.isNotEmpty) {
        fullName += ' $apellido';
      }
    } else {
      fullName = 'Cliente';
    }
    
    // Formatear el número de teléfono
    String formattedPhone = _formatPhoneNumber(telefono);
    
    // Crear el mensaje personalizado
    String message = '¡Hola $fullName! Tu envío con ID: $shipmentId ha sido actualizado a estado: *$newStatus*. ';
    
    // Añadir dirección de entrega si está disponible
    if (direccion.isNotEmpty) {
      final addressParts = <String>[];
      if (direccion.isNotEmpty) addressParts.add(direccion);
      if (ciudad.isNotEmpty) addressParts.add(ciudad);
      if (pais.isNotEmpty) addressParts.add(pais);
      
      String fullAddress = addressParts.join(', ');
          
      if (fullAddress.isNotEmpty) {
        message += 'Dirección de entrega: $fullAddress. ';
      }
    }
    
    message += 'Gracias por usar nuestros servicios de VACABOX.';
    
    // Codificar el mensaje para URL
    String encodedMessage = Uri.encodeComponent(message);
    
    // Crear URL de WhatsApp
    String whatsappUrl = 'https://wa.me/$formattedPhone?text=$encodedMessage';
    
    // Abrir WhatsApp
    final Uri url = Uri.parse(whatsappUrl);
    
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('No se pudo abrir WhatsApp');
    }
    
    // Registrar que se envió la notificación
    await _logNotificationSent(shipmentId, formattedPhone, newStatus, fullName);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Abriendo WhatsApp para enviar notificación...'))
    );
  } catch (e) {
    print('Error enviando notificación WhatsApp: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al enviar notificación: $e'))
    );
  }
}

// Función para formatear el número de teléfono para WhatsApp
String _formatPhoneNumber(String phone) {
  // Eliminar caracteres no numéricos
  String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
  
  // Si el teléfono está vacío, devolver valor por defecto
  if (cleanPhone.isEmpty) {
    return '593999999999'; // Número predeterminado para evitar errores
  }
  
  // Asegurar que tenga código de país (Ecuador = 593)
  if (cleanPhone.length == 10 && cleanPhone.startsWith('0')) {
    // Número ecuatoriano que comienza con 0, reemplazar con 593
    return '593' + cleanPhone.substring(1);
  } else if (cleanPhone.length == 10 && !cleanPhone.startsWith('0')) {
    // Número sin código de país, añadir 593
    return '593' + cleanPhone;
  } else if (cleanPhone.length == 9) {
    // Número ecuatoriano sin el 0 inicial, añadir 593
    return '593' + cleanPhone;
  }
  
  // Si ya tiene código de país u otro formato, devolverlo tal cual
  return cleanPhone;
}

// Función para registrar que se envió una notificación
Future<void> _logNotificationSent(
  String shipmentId, 
  String phone, 
  String status, 
  String clientName
) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final notificationsKey = 'whatsapp_notifications';
    
    // Obtener historial existente o crear uno nuevo
    List<String> notifications = prefs.getStringList(notificationsKey) ?? [];
    
    // Crear registro con formato timestamp|shipmentId|phone|status|clientName
    String timestamp = DateTime.now().toIso8601String();
    String logEntry = '$timestamp|$shipmentId|$phone|$status|$clientName';
    
    // Agregar al historial
    notifications.add(logEntry);
    
    // Limitar tamaño del historial si es muy grande
    if (notifications.length > 100) {
      notifications = notifications.sublist(notifications.length - 100);
    }
    
    // Guardar historial actualizado
    await prefs.setStringList(notificationsKey, notifications);
    
    print('Notificación registrada: $logEntry');
  } catch (e) {
    print('Error registrando notificación: $e');
  }
}

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
    DataColumn(label: Text('Fecha')),
    DataColumn(label: Text('Estado')),
    DataColumn(label: Text('Notificar')), // Nueva columna para notificación
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
        // Nueva celda 8: Botón de notificación de WhatsApp
       // Nueva celda 8: Botón de notificación de WhatsApp
        DataCell(
          IconButton(
            icon: Icon(Icons.chat, color: Color(0xFF25D366), size: 20),
            tooltip: 'Notificar por WhatsApp',
            onPressed: () {
              _sendWhatsAppNotificationWithUserData(shipment);
            },
          ),
        ),
        // Cell 9: Acciones (administración)
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
                    child: Text('En aduana Ecuador'),
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