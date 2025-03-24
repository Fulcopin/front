import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import '../services/shipment_service.dart';
import '../widgets/shipment_tracking_timeline.dart';
import '../models/tracking_event_model.dart';

class ShipmentDetailScreen extends StatefulWidget {
  final String shipmentId;

  const ShipmentDetailScreen({
    Key? key,
    required this.shipmentId,
  }) : super(key: key);

  @override
  State<ShipmentDetailScreen> createState() => _ShipmentDetailScreenState();
}

class _ShipmentDetailScreenState extends State<ShipmentDetailScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = true;
  Map<String, dynamic>? _shipment;
  List<TrackingEvent> _trackingEvents = [];
  final ShipmentService _shipmentService = ShipmentService();
  
  late TabController _tabController;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadShipmentDetails();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadShipmentDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final shipment = await _shipmentService.getShipmentById(widget.shipmentId);
      final events = await _shipmentService.getTrackingEvents(widget.shipmentId);
      
      setState(() {
        _shipment = shipment;
        _trackingEvents = events;
        _isLoading = false;
      });
      
      // Verificar si el usuario es administrador
      final authService = Provider.of<AuthService>(context, listen: false);
      _isAdmin = authService.isAdmin;
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar detalles: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateShipmentStatus(ShipmentStatus newStatus) async {
    if (!_isAdmin) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final success = await _shipmentService.updateShipmentStatus(
        widget.shipmentId, 
        newStatus,
      );
      
      if (success) {
        await _loadShipmentDetails();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Estado actualizado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al actualizar estado'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Envío ${_shipment?['trackingNumber'] ?? ''}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            onPressed: () {
              // Imprimir detalles
            },
            tooltip: 'Imprimir',
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              // Compartir detalles
            },
            tooltip: 'Compartir',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Resumen'),
            Tab(text: 'Seguimiento'),
            Tab(text: 'Productos'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _shipment == null
              ? const Center(
                  child: Text('No se encontró el envío'),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSummaryTab(),
                    _buildTrackingTab(),
                    _buildProductsTab(),
                  ],
                ),
    );
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusBanner(),
          const SizedBox(height: 24),
          _buildShipmentDetails(),
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildTrackingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Estado del Envío',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Barra de progreso horizontal
                  ShipmentTrackingTimeline(
                    currentStatus: _shipment!['currentStatus'],
                    isInteractive: _isAdmin,
                    onStatusTap: _isAdmin ? _updateShipmentStatus : null,
                  ),
                  
                  if (_isAdmin) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Como administrador, puedes actualizar el estado haciendo clic en los iconos',
                      style: TextStyle(
                        color: AppTheme.mutedTextColor,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          const Text(
            'Historial Detallado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Timeline vertical detallado
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ShipmentTrackingTimeline(
                currentStatus: _shipment!['currentStatus'],
                isHorizontal: false,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Lista de eventos de seguimiento
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Eventos de Seguimiento',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _trackingEvents.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final event = _trackingEvents[index];
                      final isLatest = index == 0;
                      
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isLatest 
                                ? AppTheme.primaryColor.withOpacity(0.1) 
                                : Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            event.icon,
                            color: isLatest 
                                ? AppTheme.primaryColor 
                                : Colors.grey.shade600,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          event.description,
                          style: TextStyle(
                            fontWeight: isLatest ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          '${DateFormat('dd MMM yyyy, HH:mm').format(event.timestamp)} - ${event.location}',
                          style: TextStyle(
                            color: isLatest 
                                ? AppTheme.primaryColor 
                                : AppTheme.mutedTextColor,
                          ),
                        ),
                        trailing: isLatest 
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8, 
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Último',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ) 
                            : null,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    final products = _shipment!['productsList'] as List<dynamic>;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Productos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: products.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.inventory_2_outlined,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        title: Text(
                          product['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Cantidad: ${product['quantity']}',
                        ),
                        trailing: Text(
                          '\$${product['price'].toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const Divider(),
                  const SizedBox(height: 8),
                  
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
                        '\$${_calculateTotal().toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    final currentStatus = _shipment!['currentStatus'] as ShipmentStatus;
    
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(currentStatus),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _getStatusText(currentStatus),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Actualizado: ${_trackingEvents.isNotEmpty ? DateFormat('dd MMM yyyy, HH:mm').format(_trackingEvents.first.timestamp) : 'N/A'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Barra de progreso interactiva
            ShipmentTrackingTimeline(
              currentStatus: currentStatus,
              isInteractive: _isAdmin,
              onStatusTap: _isAdmin ? _updateShipmentStatus : null,
            ),
            
            const SizedBox(height: 16),
            
            Text(
              _getStatusDescription(currentStatus),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShipmentDetails() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detalles del Envío',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Origen',
                        style: TextStyle(
                          color: AppTheme.mutedTextColor,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _shipment!['origin'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fecha de envío: ${_shipment!['date']}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Destino',
                        style: TextStyle(
                          color: AppTheme.mutedTextColor,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _shipment!['destination'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Entrega estimada: ${_shipment!['estimatedDelivery']}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cliente',
                        style: TextStyle(
                          color: AppTheme.mutedTextColor,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _shipment!['customer'],
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
                        'Tracking',
                        style: TextStyle(
                          color: AppTheme.mutedTextColor,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _shipment!['trackingNumber'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
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

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // Contactar soporte
            },
            icon: const Icon(Icons.message_outlined),
            label: const Text('Contactar'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // Reportar problema
            },
            icon: const Icon(Icons.report_problem_outlined),
            label: const Text('Reportar problema'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              foregroundColor: AppTheme.primaryColor,
              side: const BorderSide(color: AppTheme.primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _calculateTotal() {
    double total = 0;
    for (var product in _shipment!['productsList']) {
      total += product['price'] * product['quantity'];
    }
    return total;
  }
  
  Color _getStatusColor(ShipmentStatus status) {
    switch (status) {
      case ShipmentStatus.enBodega:
        return Colors.blue;
      case ShipmentStatus.enRutaAeropuerto:
        return Colors.orange;
      case ShipmentStatus.enAduana:
        return Colors.purple;
      case ShipmentStatus.enPais:
        return Colors.teal;
      case ShipmentStatus.enRutaEntrega:
        return Colors.amber.shade800;
      case ShipmentStatus.entregado:
        return Colors.green;
    }
  }
  
  String _getStatusText(ShipmentStatus status) {
    switch (status) {
      case ShipmentStatus.enBodega:
        return 'En Bodega';
      case ShipmentStatus.enRutaAeropuerto:
        return 'Hacia Aeropuerto';
      case ShipmentStatus.enAduana:
        return 'En Aduana';
      case ShipmentStatus.enPais:
        return 'En País Destino';
      case ShipmentStatus.enRutaEntrega:
        return 'En Ruta Final';
      case ShipmentStatus.entregado:
        return 'Entregado';
    }
  }
  
  String _getStatusDescription(ShipmentStatus status) {
    switch (status) {
      case ShipmentStatus.enBodega:
        return 'Su paquete ha sido recibido en nuestra bodega y está siendo procesado para su envío.';
      case ShipmentStatus.enRutaAeropuerto:
        return 'Su paquete está en camino al aeropuerto para ser embarcado hacia su destino.';
      case ShipmentStatus.enAduana:
        return 'Su paquete está siendo procesado por aduanas. Este proceso puede tomar entre 1-3 días.';
      case ShipmentStatus.enPais:
        return 'Su paquete ha llegado al país de destino y pronto será enviado para entrega final.';
      case ShipmentStatus.enRutaEntrega:
        return 'Su paquete está en ruta para ser entregado en su dirección. Llegará en aproximadamente 1-2 días.';
      case ShipmentStatus.entregado:
        return 'Su paquete ha sido entregado con éxito. ¡Gracias por confiar en nosotros!';
    }
  }
}

