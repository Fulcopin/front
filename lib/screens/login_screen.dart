import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import './register_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _redirectionInProgress = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;
  String? _emailError;
  String? _passwordError;
  String? _loginError;
  bool _isLoading = false; // Add loading state
  static bool _hasRedirected = false; 

  @override
  void initState() {
    super.initState();
  
    
     _checkStoredCredentials();
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  // Add to LoginScreen class:

@override
void didChangeDependencies() {
  super.didChangeDependencies();
  
  final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
  if (args != null) {
    _emailController.text = args['email'] ?? '';
    _passwordController.text = args['password'] ?? '';
    
    if (args['autoLogin'] == true) {
      // Auto login after short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleLogin();
      });
    }
  }
}
  // Validar el formulario antes de navegar
  bool _validateForm() {
    bool isValid = true;
    
    // Validar email
    if (_emailController.text.isEmpty) {
      setState(() {
        _emailError = 'El correo electrónico es obligatorio';
      });
      isValid = false;
    } else if (!_emailController.text.contains('@')) {
      setState(() {
        _emailError = 'Ingrese un correo electrónico válido';
      });
      isValid = false;
    } else {
      setState(() {
        _emailError = null;
      });
    }
    
    // Validar contraseña
    if (_passwordController.text.isEmpty) {
      setState(() {
        _passwordError = 'La contraseña es obligatoria';
      });
      isValid = false;
    } else if (_passwordController.text.length < 6) {
      setState(() {
        _passwordError = 'La contraseña debe tener al menos 6 caracteres';
      });
      isValid = false;
    } else {
      setState(() {
        _passwordError = null;
      });
    }
    
    return isValid;
  }
 


 // Update the _handleLogin method

Future<void> _handleLogin() async {
  if (!_validateInputs()) return;
  
  setState(() {
    _isLoading = true;
    _loginError = null;
  });

  try {
    // Log login attempt details
    print('Attempting login with:');
    print('Email: ${_emailController.text}');
    print('Password length: ${_passwordController.text.length}');

    final result = await Provider.of<AuthService>(context, listen: false)
        .login(_emailController.text, _passwordController.text)
        .timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _loginError = 'Tiempo de espera agotado';
          });
        }
        return {'success': false};
      },
    );

    print('Login result: $result');

    if (mounted) {
      setState(() => _isLoading = false);
      
      if (result['success'] == true) {
        // Store credentials if "remember me" is checked
        if (_rememberMe) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('savedEmail', _emailController.text);
          // Don't store the password in plain text, just store a flag
          await prefs.setBool('hasCredentials', true);
        }

        // Check if user is admin and redirect accordingly
        if (result['isAdmin'] == true) {
          print('Navigating to admin dashboard');
          Navigator.pushReplacementNamed(context, '/admin-dashboard');
        } else {
          print('Navigating to client dashboard');
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      } else {
        setState(() => _loginError = result['message'] ?? 'Credenciales inválidas');
      }
    }
  } catch (e) {
    print('Login exception: $e');
    if (mounted) {
      setState(() {
        _isLoading = false;
        _loginError = 'Error de conexión: ${e.toString()}';
      });
    }
  }
}

// Update the _validateInputs method for better validation
bool _validateInputs() {
  bool isValid = true;
  
  // Reset previous errors
  setState(() {
    _emailError = null;
    _passwordError = null;
    _loginError = null;
  });
  
  // Validate email
  final email = _emailController.text.trim();
  if (email.isEmpty) {
    setState(() => _emailError = 'El correo electrónico es obligatorio');
    isValid = false;
  } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
    setState(() => _emailError = 'Ingrese un correo electrónico válido');
    isValid = false;
  }
  
  // Validate password
  if (_passwordController.text.isEmpty) {
    setState(() => _passwordError = 'La contraseña es obligatoria');
    isValid = false;
  } else if (_passwordController.text.length < 6) {
    setState(() => _passwordError = 'La contraseña debe tener al menos 6 caracteres');
    isValid = false;
  }
  
  return isValid;
}
// Add this at the top of your class, outside any methods
// Static flag to prevent multiple redirections across rebuilds




Future<void> _checkStoredCredentials() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('savedEmail');
    final hasCredentials = prefs.getBool('hasCredentials') ?? false;
    
    if (savedEmail != null && savedEmail.isNotEmpty) {
      setState(() {
        _emailController.text = savedEmail;
        _rememberMe = hasCredentials;
      });
    }
    
    // Check if user is already logged in
    final authService = Provider.of<AuthService>(context, listen: false);
    final isAuthenticated = await authService.checkAuthStatus();
    
    // Get the current route to prevent redirection loop
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final isComingFromAdminDashboard = currentRoute == '/admin-dashboard';
    
    if (isAuthenticated && mounted && !isComingFromAdminDashboard) {
      final isAdmin = await authService.isAdmin();
      if (isAdmin) {
        print('User already logged in as admin, redirecting');
        Navigator.of(context).pushReplacementNamed('/admin-dashboard');
      } else {
        print('User already logged in as client, redirecting');
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    }
  } catch (e) {
    print('Error checking stored credentials: $e');
  }
}

 
   



  @override
Widget build(BuildContext context) {
  
  if (_isLoading) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 800) {
              // Diseño para tablet/desktop
              return Row(
                children: [
                  Expanded(
                    child: _buildLoginForm(),
                  ),
                  Expanded(
                    child: _buildRightPanel(),
                  ),
                ],
              );
            } else {
              // Diseño para móvil
              return _buildLoginForm();
            }
          },
        ),
      ),
    );
  }
 
  Widget _buildLoginForm() {
    final authService = Provider.of<AuthService>(context);
    
    return Container(
      color: AppTheme.secondaryColor.withOpacity(0.2),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vacabox',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Spacer(),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Trae tus productos a menos precio',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Bienvenido Inicia Sesión',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 32),
                if (_loginError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _loginError!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  width: 400,
                  child: TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      errorText: _emailError,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (value) {
                      // Limpiar el error cuando el usuario comienza a escribir
                      if (_emailError != null) {
                        setState(() {
                          _emailError = null;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 400,
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      errorText: _passwordError,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    onChanged: (value) {
                      // Limpiar el error cuando el usuario comienza a escribir
                      if (_passwordError != null) {
                        setState(() {
                          _passwordError = null;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 400,
                  child: Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                        activeColor: AppTheme.primaryColor,
                      ),
                      const Text('Recordar mis datos'),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          // Lógica para recuperar contraseña
                        },
                        child: const Text('¿Olvidaste tu contraseña?'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 400,
                  child: ElevatedButton(
    onPressed: _isLoading ? null : _handleLogin,
    child: _isLoading 
      ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
      : const Text('Iniciar Sesión'),
  )
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 400,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Lógica para iniciar sesión con Gmail
                    },
                    icon: const Icon(Icons.mail_outline),
                    label: const Text('Iniciar sesión con Gmail'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 400,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('¿No tienes una cuenta?'),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/register');
                        },
                        child: const Text('Regístrate'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildRightPanel() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 24, right: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildNavItem('Home', true),
                _buildNavItem('About us', false),
                _buildNavItem('Blog', false),
                _buildNavItem('Pricing', false),
              ],
            ),
          ),
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Placeholder(
                    fallbackHeight: 200,
                    fallbackWidth: 200,
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Servicio de courier confiable y rápido',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      'Envía y recibe paquetes de manera segura con nuestro servicio premium de courier internacional.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.mutedTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(String title, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: TextStyle(
          color: isActive ? AppTheme.textColor : AppTheme.mutedTextColor,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          decoration: isActive ? TextDecoration.underline : TextDecoration.none,
          decorationThickness: 2,
          decorationColor: AppTheme.textColor,
        ),
      ),
    );
  }
}


