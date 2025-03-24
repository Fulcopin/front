import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

abstract class BaseScreen extends StatefulWidget {
  const BaseScreen({Key? key}) : super(key: key);
}

abstract class BaseScreenState<T extends BaseScreen> extends State<T> {
  late AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = Provider.of<AuthService>(context, listen: false);
    _checkSession();
  }

  void _checkSession() async {
    bool isValid = await _authService.checkAuth();
    if (!isValid && mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }
}