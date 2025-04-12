import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/products_screen.dart';
import 'screens/payments_screen.dart';
import 'screens/my_shipments_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/shipment_detail_screen.dart';
import 'screens/admin_shipement.dart';
import 'services/auth_service.dart';
import 'widgets/authguard.dart';
import  'screens/admin_dashboard_screen.dart';
import 'screens/pagosyenvios_screen.dart'; 
void main()  async  {
   WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize secure storage and load credentials
  final authService = AuthService();
  await authService.initializeSession();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
      ],
      child: const CourierApp(),
    ),
  );
}

class CourierApp extends StatelessWidget {
  const CourierApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vacabox Courier',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGuard(child: LoginScreen()),
         '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const AuthGuard(child: DashboardScreen()),
        '/products': (context) => const ProductsScreen(),
        '/payments': (context) => const PaymentsScreen(),
        '/admin-dashboard': (context) => const AuthGuard(child: AdminDashboardScreen()),
        '/my-shipments': (context) => const MyShipmentsScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/login': (context) => const LoginScreen(),
         '/admin/shipments': (context) => const AdminShipmentScreen(),
          '/admin/pagos-envios': (context) => PagosYEnviosScreen(), // Add this route
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/shipment-detail') {
          final shipmentId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => ShipmentDetailScreen(shipmentId: shipmentId),
          );
        }
        return null;
      },
    );
  }
}
