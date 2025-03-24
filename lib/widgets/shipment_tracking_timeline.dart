import 'package:flutter/material.dart';
import 'package:timeline_tile/timeline_tile.dart';
import '../theme.dart';

enum ShipmentStatus {
  enBodega,
  enRutaAeropuerto,
  enAduana,
  enPais,
  enRutaEntrega,
  entregado,
}

class ShipmentTrackingTimeline extends StatefulWidget {
  final ShipmentStatus currentStatus;
  final Function(ShipmentStatus)? onStatusTap;
  final bool isInteractive;
  final bool showLabels;
  final bool isHorizontal;

  const ShipmentTrackingTimeline({
    Key? key,
    required this.currentStatus,
    this.onStatusTap,
    this.isInteractive = false,
    this.showLabels = true,
    this.isHorizontal = true,
  }) : super(key: key);

  @override
  State<ShipmentTrackingTimeline> createState() => _ShipmentTrackingTimelineState();
}

class _ShipmentTrackingTimelineState extends State<ShipmentTrackingTimeline> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _updateProgressAnimation();
    _animationController.forward();
  }
  
  @override
  void didUpdateWidget(ShipmentTrackingTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStatus != widget.currentStatus) {
      _updateProgressAnimation();
      _animationController.forward(from: 0.0);
    }
  }
  
  void _updateProgressAnimation() {
    // Calcular el progreso basado en el estado actual
    final int totalSteps = ShipmentStatus.values.length;
    final int currentStep = widget.currentStatus.index + 1;
    final double targetProgress = currentStep / totalSteps;
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: targetProgress,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.isHorizontal 
        ? _buildHorizontalTimeline(context) 
        : _buildVerticalTimeline(context);
  }
  
  Widget _buildHorizontalTimeline(BuildContext context) {
    return Column(
      children: [
        // Barra de progreso animada
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _progressAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            );
          },
        ),
        
        const SizedBox(height: 16),
        
        // Iconos de estado
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatusIcon(
              ShipmentStatus.enBodega, 
              'En Bodega', 
              Icons.warehouse_outlined,
            ),
            _buildStatusIcon(
              ShipmentStatus.enRutaAeropuerto, 
              'Hacia Aeropuerto', 
              Icons.flight_takeoff_outlined,
            ),
            _buildStatusIcon(
              ShipmentStatus.enAduana, 
              'En Aduana', 
              Icons.security_outlined,
            ),
            _buildStatusIcon(
              ShipmentStatus.enPais, 
              'En País Destino', 
              Icons.flight_land_outlined,
            ),
            _buildStatusIcon(
              ShipmentStatus.enRutaEntrega, 
              'En Ruta Final', 
              Icons.local_shipping_outlined,
            ),
            _buildStatusIcon(
              ShipmentStatus.entregado, 
              'Entregado', 
              Icons.home_outlined,
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildVerticalTimeline(BuildContext context) {
    return Column(
      children: [
        _buildVerticalTimelineItem(
          ShipmentStatus.enBodega,
          'En Bodega',
          'Tu paquete ha sido recibido en nuestra bodega de origen',
          Icons.warehouse_outlined,
          isFirst: true,
        ),
        _buildVerticalTimelineItem(
          ShipmentStatus.enRutaAeropuerto,
          'En Camino al Aeropuerto',
          'Tu paquete está en ruta hacia el aeropuerto para su embarque',
          Icons.flight_takeoff_outlined,
        ),
        _buildVerticalTimelineItem(
          ShipmentStatus.enAduana,
          'Pasando Aduana',
          'Tu paquete está siendo procesado por aduanas',
          Icons.security_outlined,
        ),
        _buildVerticalTimelineItem(
          ShipmentStatus.enPais,
          'Llegó al País',
          'Tu paquete ha llegado al país de destino',
          Icons.flight_land_outlined,
        ),
        _buildVerticalTimelineItem(
          ShipmentStatus.enRutaEntrega,
          'En Ruta para Entrega',
          'Tu paquete está en camino para ser entregado',
          Icons.local_shipping_outlined,
        ),
        _buildVerticalTimelineItem(
          ShipmentStatus.entregado,
          'Entregado',
          'Tu paquete ha sido entregado con éxito',
          Icons.home_outlined,
          isLast: true,
        ),
      ],
    );
  }
  
  Widget _buildVerticalTimelineItem(
    ShipmentStatus status,
    String title,
    String description,
    IconData icon, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    final bool isActive = widget.currentStatus.index >= status.index;
    final bool isCurrent = widget.currentStatus == status;
    
    return TimelineTile(
      alignment: TimelineAlign.manual,
      lineXY: 0.2,
      isFirst: isFirst,
      isLast: isLast,
      indicatorStyle: IndicatorStyle(
        width: 40,
        height: 40,
        indicator: Container(
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryColor : Colors.grey.shade300,
            shape: BoxShape.circle,
            border: Border.all(
              color: isCurrent ? AppTheme.primaryColor : Colors.transparent,
              width: 3,
            ),
            boxShadow: isCurrent ? [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ] : null,
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.white : Colors.grey.shade600,
            size: 20,
          ),
        ),
        padding: const EdgeInsets.all(8),
      ),
      beforeLineStyle: LineStyle(
        color: isActive ? AppTheme.primaryColor : Colors.grey.shade300,
        thickness: 3,
      ),
      afterLineStyle: LineStyle(
        color: widget.currentStatus.index > status.index 
            ? AppTheme.primaryColor 
            : Colors.grey.shade300,
        thickness: 3,
      ),
      endChild: GestureDetector(
        onTap: widget.isInteractive 
            ? () => widget.onStatusTap?.call(status) 
            : null,
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isCurrent 
                ? AppTheme.primaryColor.withOpacity(0.1) 
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCurrent 
                  ? AppTheme.primaryColor 
                  : Colors.grey.shade200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isCurrent 
                      ? AppTheme.primaryColor 
                      : Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: isCurrent 
                      ? AppTheme.primaryColor.withOpacity(0.8) 
                      : AppTheme.mutedTextColor,
                  fontSize: 14,
                ),
              ),
              if (isCurrent) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8, 
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Estado Actual',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      startChild: widget.showLabels ? Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Text(
              _getStatusDate(status),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isActive ? Colors.black : Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ) : null,
    );
  }
  
  String _getStatusDate(ShipmentStatus status) {
    // En una implementación real, estas fechas vendrían de los datos del envío
    switch (status) {
      case ShipmentStatus.enBodega:
        return '15 Mar 2025';
      case ShipmentStatus.enRutaAeropuerto:
        return '16 Mar 2025';
      case ShipmentStatus.enAduana:
        return '17 Mar 2025';
      case ShipmentStatus.enPais:
        return '18 Mar 2025';
      case ShipmentStatus.enRutaEntrega:
        return '19 Mar 2025';
      case ShipmentStatus.entregado:
        return '20 Mar 2025';
    }
  }
  
  Widget _buildStatusIcon(ShipmentStatus status, String label, IconData icon) {
    final bool isActive = widget.currentStatus.index >= status.index;
    final bool isCurrent = widget.currentStatus == status;
    
    return Expanded(
      child: GestureDetector(
        onTap: widget.isInteractive 
            ? () => widget.onStatusTap?.call(status) 
            : null,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isCurrent ? 50 : 40,
              height: isCurrent ? 50 : 40,
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primaryColor : Colors.grey.shade300,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCurrent ? AppTheme.primaryColor : Colors.transparent,
                  width: 3,
                ),
                boxShadow: isCurrent ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ] : null,
              ),
              child: Icon(
                icon,
                color: isActive ? Colors.white : Colors.grey.shade600,
                size: isCurrent ? 24 : 20,
              ),
            ),
            if (widget.showLabels) ...[
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCurrent ? AppTheme.primaryColor : AppTheme.mutedTextColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

