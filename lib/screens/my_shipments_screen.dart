import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import '../services/shipment_service.dart';
import '../widgets/shipment_tracking_timeline.dart';
import 'dart:convert';
import '../models/shipement_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
class MyShipmentsScreen extends StatefulWidget {
  const MyShipmentsScreen({Key? key}) : super(key: key);

  @override
  State<MyShipmentsScreen> createState() => _MyShipmentsScreenState();
}

class _MyShipmentsScreenState extends State<MyShipmentsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = true;
  List<Map<String, dynamic>> _shipments = [];
  final ShipmentService _shipmentService = ShipmentService();

  @override
  void initState() {
    super.initState();
    _loadShipments();
  }
String _getStatusString(String backendStatus) {
    switch (backendStatus.toLowerCase()) {
      case 'en proceso':
      case 'procesando':
        return 'processing';
      case 'enviado':
      case 'en tránsito':
        return 'shipped';
      case 'en destino':
      case 'llegó a destino':
        return 'outForDelivery';
      case 'entregado':
      case 'completado':
        return 'delivered';
      default:
        return 'processing';
    }
  }
  // Replace the "detalle" line with a method that shows shipping information
void showShippingDetails(Shipment shipment) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Detalles del Envío'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Número de seguimiento:', shipment.trackingNumber),
              _buildDetailRow('Estado:', shipment.status),
              _buildDetailRow('Fecha de envío:', shipment.shippingDate),
              _buildDetailRow('Fecha estimada de entrega:', shipment.estimatedDeliveryDate),
              _buildDetailRow('Dirección de entrega:', shipment.deliveryAddress),
              _buildDetailRow('Método de envío:', shipment.shippingMethod),
              _buildDetailRow('Compañía de transporte:', shipment.carrier),
              Divider(),
              Text('Productos:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...shipment.products.map((product) => 
                Padding(
                  padding: EdgeInsets.only(left: 8.0, top: 4.0),
                  child: Text('• ${product.name} (${product.quantity}x)'),
                )
              ).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cerrar'),
          ),
        ],
      );
    },
  );
}

Widget _buildDetailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(width: 4),
        Expanded(child: Text(value)),
      ],
    ),
  );
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
 Future<void> _loadShipments() async {
  setState(() {
    _isLoading = true;
  });
  
  try {
    // Obtener los envíos del servicio
    final shipments = await _shipmentService.getShipments();
    
    // Procesar los envíos para manejar correctamente los tipos
    final processedShipments = shipments.map((shipment) {
      // Esta función asegura que los valores sean strings
      String ensureString(dynamic value, String defaultValue) {
        if (value == null) return defaultValue;
        if (value is String) return value;
        if (value is Map || value is List) return json.encode(value);
        return value.toString();
      }
      
      // Usar el mismo mapeo que ya tienes, pero con seguridad de tipos
      return {
        'id': ensureString(shipment['id'], ''),
        'trackingNumber': ensureString(shipment['trackingNumber'], 'Sin número'),
        'status': ensureString(shipment['status'], 'Procesando'),
        'origin': ensureString(shipment['origin'], 'Miami, FL'),
        'destination': ensureString(shipment['destination'], 'No disponible'),
        'date': ensureString(shipment['date'], 'Fecha no disponible'),
        'currentStatus': shipment['currentStatus'],  // Mantener como está para la línea de tiempo
      };
    }).toList();
    
    setState(() {
      _shipments = processedShipments;
      _isLoading = false;
    });
  } catch (e) {
    print('Error al cargar envíos: $e');
    setState(() {
      _isLoading = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error al cargar envíos: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}


// 3. Implementa el método _buildStatusBadge
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
  void _showCreateShipmentModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Crear Nuevo Envío',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Selecciona un pago',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: '1',
                    child: const Text('Pago #1 - \$350.00 - 15/03/2025'),
                  ),
                  DropdownMenuItem(
                    value: '2',
                    child: const Text('Pago #2 - \$120.50 - 10/03/2025'),
                  ),
                ],
                onChanged: (value) {},
                hint: const Text('Selecciona un pago'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Dirección de entrega',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Ingresa la dirección completa',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      
                      // Crear un nuevo envío simulado
                      try {
                        setState(() {
                          _isLoading = true;
                        });
                        
                        await _shipmentService.createShipment({
                          'origin': 'Miami, FL',
                          'destination': 'Ciudad de México, MX',
                          'customer': 'Juan Pérez',
                          'estimatedDelivery': '2025-03-25',
                          'products': 2,
                          'productsList': [
                            {
                              'name': 'Nuevo Producto',
                              'quantity': 1,
                              'price': 299.99,
                            },
                          ],
                        });
                        
                        await _loadShipments();
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Envío creado correctamente'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        setState(() {
                          _isLoading = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error al crear envío: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Crear Envío'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Mis Envíos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadShipments,
            tooltip: 'Recargar',
          ),
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
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/dashboard');
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Mis Alertas'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/products');
              },
            ),
             ListTile(
              leading: const Icon(Icons.local_shipping_outlined),
              title: const Text('Mi Casillero'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/usa-shipping');
              },
            ),
            ListTile(
              leading: const Icon(Icons.credit_card_outlined),
              title: const Text('Realizar Pago'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/payments');
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('Mis Envíos'),
              selected: true,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Mi Perfil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Configuración'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/settings');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: () {
                authService.logout();
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _shipments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.local_shipping_outlined,
                        size: 64,
                        color: AppTheme.mutedTextColor,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No tienes envíos registrados',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Crea un envío para comenzar a utilizar nuestro servicio',
                        style: TextStyle(
                          color: AppTheme.mutedTextColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _showCreateShipmentModal,
                        icon: const Icon(Icons.add),
                        label: const Text('Crear Envío'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadShipments,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _shipments.length,
                    itemBuilder: (context, index) {
                      final shipment = _shipments[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Cabecera del envío
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    shipment['trackingNumber']?.toString() ?? 'Sin número',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                   _buildStatusBadge(shipment['status']?.toString() ?? ''),
                                ],
                              ),
                            ),
                            
                            // Barra de progreso
                            Padding(
                            padding: const EdgeInsets.all(16),
                            child: ShipmentTrackingTimeline(
                            currentStatus: _convertStringToShipmentStatus(shipment['status']?.toString() ?? ''),
                            showLabels: true,
                            isHorizontal: true,
                          ),
                        ),
                            
                            // Detalles del envío
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Origen',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.mutedTextColor,
                                          ),
                                        ),
                                        Text(
                                          shipment['origin']?.toString() ?? 'No disponible',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward,
                                    color: AppTheme.mutedTextColor,
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Destino',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.mutedTextColor,
                                          ),
                                        ),
                                        Text(
                                         shipment['destination']?.toString() ?? 'No disponible',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Fecha',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.mutedTextColor,
                                          ),
                                        ),
                                        Text(
                                         shipment['date']?.toString() ?? 'No disponible',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Botones de acción
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/shipment-detail',
                                        arguments: shipment['id'],
                                      );
                                    },
                                    icon: const Icon(Icons.visibility_outlined),
                                    label: const Text('Ver detalles'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.primaryColor,
                                      side: const BorderSide(color: AppTheme.primaryColor),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateShipmentModal,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add),
        label: const Text('NUEVO ENVÍO'),
      ),
    );
  }
  
int _getStatusLevel(String status) {
  switch (status.toLowerCase()) {
    case 'en proceso':
    case 'procesando':
      return 0;
    case 'enviado':
    case 'en tránsito':
      return 1;
    case 'en destino':
    case 'llegó a destino':
      return 2;
    case 'entregado':
    case 'completado':
      return 3;
    default:
      return 0;
  }
}
Widget _buildSimpleTrackingTimeline(int currentStep) {
  return Container(
    height: 70,
    child: Row(
      children: [
        _buildTimelineStep(0, currentStep, 'Procesando'),
        _buildTimelineConnector(0 < currentStep),
        _buildTimelineStep(1, currentStep, 'Enviado'),
        _buildTimelineConnector(1 < currentStep),
        _buildTimelineStep(2, currentStep, 'En destino'),
        _buildTimelineConnector(2 < currentStep),
        _buildTimelineStep(3, currentStep, 'Entregado'),
      ],
    ),
  );
}
Widget _buildTimelineStep(int step, int currentStep, String label) {
  final isActive = step <= currentStep;
  final color = isActive ? Colors.green : Colors.grey;
  
  return Expanded(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isActive ? color : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color),
          ),
          child: Icon(
            step == currentStep ? Icons.location_on : Icons.check,
            color: step == currentStep ? Colors.white : color,
            size: 16,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Colors.black : Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
Widget _buildTimelineConnector(bool isActive) {
  return Container(
    width: 20,
    height: 2,
    color: isActive ? Colors.green : Colors.grey,
  );
}

}

