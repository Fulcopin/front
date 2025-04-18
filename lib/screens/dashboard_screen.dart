import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/stats_card.dart';
import '../widgets/recent_shipments.dart';
import '../widgets/quick_actions.dart';
import '../widgets/shipment_chart.dart';
import '../widgets/client_stats_card.dart';
import '../widgets/client_quick_actions.dart';
import '../widgets/client_shipments_overview.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import '../services/product_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/user_stats_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final storage = const FlutterSecureStorage();
  final UserStatsService _statsService = UserStatsService();
  bool _isAdmin = false;
  int _selectedIndex = 0;
  int _totalProducts = 0;
  bool _isLoading = true;
    bool _isLoadingStats = true;
    Map<String, dynamic> _userStats = {
    'totalShipments': 0,
    'shipmentsInTransit': 0,
    'totalSpent': 0.0,
  };
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  void initState() {
    super.initState();
    _validateSession();
    _loadDashboardData();
      _loadUserStats();
  }
  
 Future<void> _loadUserStats() async {
  print('📊 Cargando estadísticas de usuario...');
  try {
    setState(() {
      _isLoadingStats = true;
    });
    
    // Obtener el ID del usuario desde SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('idUser');
    
    print('🔑 ID de usuario obtenido: $userId');
    
    if (userId == null) {
      throw Exception('No se encontró ID de usuario');
    }
    
    // Obtener el token para autorización
    final token = await storage.read(key: 'token');
    if (token == null) {
      throw Exception('No se encontró token de autenticación');
    }
    
    // Pasar el ID explícitamente al servicio
    final stats = await _statsService.getUserStats(token, userId);
    
    if (mounted) {
      setState(() {
        _userStats = stats;
        _isLoadingStats = false;
      });
    }
  } catch (e) {
    print('❌ Error cargando estadísticas: $e');
    
    // Usar datos temporales mientras se arregla
    if (mounted) {
      setState(() {
        _userStats = {
          'totalShipments': 3,
          'shipmentsInTransit': 1,
          'totalSpent': 350.0,
        };
        _isLoadingStats = false;
      });
    }
  }
}
   Future<void> _loadDashboardData() async {
    try {
      final products = await ProductService().getProducts();
      setState(() {
        _totalProducts = products.length;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() => _isLoading = false);
    }
  }
   @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isAdmin = authService.isAdmin;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text(
          'Vacabox',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                authService.logout();
                Navigator.pushReplacementNamed(context, '/');
              } else if (value == 'profile') {
                Navigator.pushNamed(context, '/profile');
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, size: 18),
                    const SizedBox(width: 8),
                    Text('Perfil (${authService.currentUser?.name ?? "Usuario"})'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18),
                    SizedBox(width: 8),
                    Text('Cerrar sesión'),
                  ],
                ),
              ),
            ],
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.secondaryColor,
                child: Icon(
                  Icons.person_outline,
                  color: AppTheme.textColor,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(_isAdmin),
      body: Row(
        children: [
          // Navegación lateral para pantallas grandes
          if (MediaQuery.of(context).size.width >= 1100)
            SizedBox(
              width: 250,
              child: _buildDrawerContents(_isAdmin),
            ),
          // Contenido principal - Mostrar la pantalla seleccionada
          Expanded(
            child:   _buildClientDashboard(),
          ),
        ],
      ),
    );
  }
   
   void _validateSession() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (!await authService.checkAuth()) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }
  Widget _buildDrawer(bool isAdmin) {
    return Drawer(
      child: _buildDrawerContents(isAdmin),
    );
  }
 Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
  Widget _buildDrawerContents(bool isAdmin) {
    final authService = Provider.of<AuthService>(context);
    
    return Column(
      children: [
        DrawerHeader(
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Vacabox',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                authService.currentUser?.name ?? 'Usuario',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (isAdmin)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
        _buildNavItem(0, 'Dashboard', Icons.home_outlined, '/dashboard'),
        
        // Client-specific navigation items
        if (!isAdmin) ...[
          _buildNavItem(1, 'Alerta Bodega', Icons.notifications_outlined, '/products'),
          _buildNavItem(2, 'Realizar Pago', Icons.credit_card_outlined, '/payments'),
          _buildNavItem(3, 'Mis Envíos', Icons.inventory_2_outlined, '/my-shipments'),
          _buildNavItem(4, 'Mi Perfil', Icons.person_outline, '/profile'),
          _buildNavItem(5, 'Mi Casillero', Icons.local_shipping_outlined, '/usa-shipping'),
        ],
        
        // Admin-specific navigation items
        if (isAdmin) ...[
          _buildNavItem(1, 'Envíos', Icons.inventory_2_outlined, '/shipments'),
          _buildNavItem(2, 'Seguimiento', Icons.local_shipping_outlined, '/tracking'),
          _buildNavItem(3, 'Almacén', Icons.inventory_outlined, '/warehouse'),
          _buildNavItem(4, 'Clientes', Icons.people_outline, '/customers'),
          _buildNavItem(5, 'Facturación', Icons.receipt_long_outlined, '/billing'),
          _buildNavItem(6, 'Reportes', Icons.bar_chart_outlined, '/reports'),
        ],
        
        // Common navigation items
        _buildNavItem(isAdmin ? 7 : 5, 'Configuración', Icons.settings_outlined, '/settings'),
        
        const Spacer(),
        
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () {
              authService.logout();
              Navigator.pushReplacementNamed(context, '/');
            },
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(int index, String title, IconData icon, String route) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppTheme.primaryColor : AppTheme.mutedTextColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppTheme.primaryColor : AppTheme.textColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        if (MediaQuery.of(context).size.width < 1100) {
          Navigator.pop(context);
        }
        Navigator.pushNamed(context, route);
      },
    );
  }


  // Widget para el contenido del dashboard de cliente
  Widget _buildClientDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         
          Text(
            'Trae tus productos a menos precio',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bienvenido Cliente',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mutedTextColor,
                ),
          ),
          const SizedBox(height: 24),
          _buildClientStatsGrid(context),
          const SizedBox(height: 24),
          _buildClientOverview(context),
          const SizedBox(height: 24),
          _buildHowItWorks(context),
        ],
      ),
    );
  }

  static Widget _buildStatsGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determinar cuántas tarjetas por fila según el ancho
        int crossAxisCount = 1;
        if (constraints.maxWidth > 600) crossAxisCount = 2;
        if (constraints.maxWidth > 900) crossAxisCount = 4;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            StatsCard(
              title: 'Total Envíos',
              value: '1,234',
              description: 'Último mes',
              icon: Icons.inventory_2_outlined,
              trend: '+12.5%',
              isPositive: true,
            ),
            StatsCard(
              title: 'En Tránsito',
              value: '256',
              description: 'Actualmente',
              icon: Icons.local_shipping_outlined,
              trend: '+3.2%',
              isPositive: true,
            ),
            StatsCard(
              title: 'Ingresos',
              value: '\$45,231',
              description: 'Último mes',
              icon: Icons.attach_money,
              trend: '+8.1%',
              isPositive: true,
            ),
            StatsCard(
              title: 'Clientes',
              value: '892',
              description: 'Total activos',
              icon: Icons.people_outline,
              trend: '+5.4%',
              isPositive: true,
            ),
          ],
        );
      },
    );
  }

  static Widget _buildShipmentsAndActions(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
          // Diseño de escritorio
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                flex: 3,
                child: RecentShipments(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: QuickActions(),
              ),
            ],
          );
        } else {
          // Diseño móvil
          return Column(
            children: const [
              RecentShipments(),
              SizedBox(height: 16),
              QuickActions(),
            ],
          );
        }
      },
    );
  }


Widget _buildClientStatsGrid(BuildContext context) {
  return Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Mis Estadísticas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserStats,
            tooltip: 'Actualizar estadísticas',
          ),
        ],
      ),
      const SizedBox(height: 16),
      LayoutBuilder(
        builder: (context, constraints) {
          // Determinar cuántas tarjetas por fila según el ancho
          int crossAxisCount = 1;
          if (constraints.maxWidth > 600) crossAxisCount = 2;
          if (constraints.maxWidth > 900) crossAxisCount = 4;

          return GridView.count(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              ClientStatsCard(
                title: 'Mis Alertas',
                value: _isLoading ? '...' : _totalProducts.toString(),
                description: 'Total registrados',
                icon: Icons.shopping_cart_outlined,
              ),
              ClientStatsCard(
                title: 'Mis Envíos',
                value: _isLoadingStats 
                    ? '...' 
                    : (_userStats['totalShipments']?.toString() ?? '0'),
                description: 'Total realizados',
                icon: Icons.inventory_2_outlined,
              ),
              ClientStatsCard(
                title: 'En Tránsito',
                value: _isLoadingStats 
                    ? '...' 
                    : (_userStats['shipmentsInTransit']?.toString() ?? '0'),
                description: 'Actualmente',
                icon: Icons.local_shipping_outlined,
                status: 'En camino',
              ),
              ClientStatsCard(
                title: 'Pagos',
                value: _isLoadingStats 
                    ? '...' 
                    : '\$${(_userStats['totalSpent'] ?? 0.0).toStringAsFixed(2)}',
                description: 'Total gastado',
                icon: Icons.credit_card_outlined,
              ),
            ],
          );
        },
      ),
    ],
  );
}
  Widget _buildClientOverview(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
  // Diseño de escritorio
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Expanded(
        child: ClientQuickActions(),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: ClientShipmentsOverview(
          onShipmentTap: (shipmentId) {
            // Navegar a la página de detalles del envío
            Navigator.pushNamed(
              context,
              '/shipment-details',
              arguments: {'id': shipmentId},
            );
          },
        ),
      ),
    ],
  );
} else {
  // Diseño móvil
  return Column(
    children: [
      const ClientQuickActions(),
      const SizedBox(height: 16),
      ClientShipmentsOverview(
        onShipmentTap: (shipmentId) {
          // Navegar a la página de detalles del envío
          Navigator.pushNamed(
            context,
            '/shipment-details',
            arguments: {'id': shipmentId},
          );
        },
      ),
    ],
  );
}
      },
    );
  }

  Widget _buildHowItWorks(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Cómo funciona Vacabox?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Sigue estos pasos para utilizar nuestro servicio',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  // Diseño de escritorio
                  return Row(
                    children: [
                      Expanded(child: _buildHowItWorksStep(context, 1, 'Registra tus productos', 'Agrega los productos que deseas enviar con sus detalles', Icons.shopping_cart_outlined)),
                      Expanded(child: _buildHowItWorksStep(context, 2, 'Realiza un pago', 'Paga el costo del envío mediante nuestros métodos disponibles', Icons.credit_card_outlined)),
                      Expanded(child: _buildHowItWorksStep(context, 3, 'Crea tu envío', 'Selecciona un pago y crea tu envío con la dirección de entrega', Icons.inventory_2_outlined)),
                    ],
                  );
                } else {
                  // Diseño móvil
                  return Column(
                    children: [
                      _buildHowItWorksStep(context, 1, 'Registra tus productos', 'Agrega los productos que deseas enviar con sus detalles', Icons.shopping_cart_outlined),
                      const SizedBox(height: 16),
                      _buildHowItWorksStep(context, 2, 'Realiza un pago', 'Paga el costo del envío mediante nuestros métodos disponibles', Icons.credit_card_outlined),
                      const SizedBox(height: 16),
                      _buildHowItWorksStep(context, 3, 'Crea tu envío', 'Selecciona un pago y crea tu envío con la dirección de entrega', Icons.inventory_2_outlined),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorksStep(BuildContext context, int step, String title, String description, IconData icon) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$step. $title',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

