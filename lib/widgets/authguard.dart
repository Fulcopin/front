import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';
class AuthGuard extends StatefulWidget {
  final Widget child;
  const AuthGuard({Key? key, required this.child}) : super(key: key);

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    if (_checking) return;
    
    _checking = true;
    final authService = Provider.of<AuthService>(context, listen: false);
    final isAuthenticated = await authService.checkAuth();
    
    if (!isAuthenticated && widget.child is! LoginScreen && mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    } else if (isAuthenticated && widget.child is LoginScreen && mounted) {
      // Check for admin role
      final isAdmin = await authService.isAdmin();
      if (isAdmin) {
        Navigator.of(context).pushReplacementNamed('/admin-dashboard');
      } else {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    }
    _checking = false;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}