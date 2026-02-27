import 'package:flutter/material.dart';
import 'package:larpland/service/login.dart';
import 'package:larpland/util/error_message.dart';
import 'package:larpland/view/admin/adminhome.dart';
import 'package:larpland/view/home/home_screen.dart';
import 'package:larpland/view/register/register.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _validateAndSave() {
    final form = _formKey.currentState;
    if (form != null && form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  Future<void> _validateAndSubmit() async {
    if (_validateAndSave()) {
      try {
        final futureResult =
            await login(emailController.text, passwordController.text);
        if (!mounted) return;
        if (futureResult.rol == 0) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(userId: futureResult.userId),
            ),
          );
        } else if (futureResult.rol == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminHome(userId: futureResult.userId),
            ),
          );
        } else {
          throw Exception('Rol de usuario no valido.');
        }
      } catch (e) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(uiErrorMessage(e)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      fillColor: const Color(0xFFF3EBD4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: const Color(0xFF5C3F2D).withValues(alpha: 0.24),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: const Color(0xFF5C3F2D).withValues(alpha: 0.24),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFC9953E),
          width: 1.4,
        ),
      ),
    );
  }

  Widget _buildBackdrop() {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E1411), Color(0xFF4A3025), Color(0xFF7A5534)],
            ),
          ),
        ),
        Positioned(
          left: -110,
          top: -90,
          child: _AtmosphericPatch(
            size: 260,
            color: const Color(0xFFC9953E).withValues(alpha: 0.22),
          ),
        ),
        Positioned(
          right: -100,
          bottom: -10,
          child: _AtmosphericPatch(
            size: 300,
            color: const Color(0xFF8C3C2F).withValues(alpha: 0.2),
          ),
        ),
        Positioned(
          right: 60,
          top: 120,
          child: _AtmosphericPatch(
            size: 120,
            color: const Color(0xFFD3A963).withValues(alpha: 0.16),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            _buildBackdrop(),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 470),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E1F19).withValues(alpha: 0.74),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFC9953E).withValues(alpha: 0.32),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                color: Color(0xFFF0D6A5),
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Gremio de Aventureros de LarpLand',
                                  style: TextStyle(
                                    color: Color(0xFFF8F2DE),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F2DE).withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: const Color(0xFF5C3F2D).withValues(alpha: 0.3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.28),
                                blurRadius: 26,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                const Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: Color(0xFF2C4432),
                                      child: Icon(
                                        Icons.shield_moon_outlined,
                                        color: Color(0xFFF8F2DE),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Bienvenido de vuelta',
                                            style: TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w700,
                                              height: 1.05,
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            'Accede para continuar tu campana.',
                                            style: TextStyle(
                                              color: Color(0xFF5A4A41),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                TextFormField(
                                  controller: emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  decoration: _fieldDecoration(
                                    label: 'Email',
                                    icon: Icons.alternate_email_rounded,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor, ingrese su correo electronico';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) => emailController.text = value!,
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: passwordController,
                                  obscureText: _obscurePassword,
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  decoration: _fieldDecoration(
                                    label: 'Contrasena',
                                    icon: Icons.lock_outline_rounded,
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor, ingrese su contrasena';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) => passwordController.text = value!,
                                ),
                                const SizedBox(height: 20),
                                FilledButton.icon(
                                  onPressed: _validateAndSubmit,
                                  icon: const Icon(Icons.login_rounded),
                                  label: const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Text('Entrar al gremio'),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'No tienes una cuenta?',
                                      style: TextStyle(color: Color(0xFF4B403A)),
                                    ),
                                    const SizedBox(width: 6),
                                    TextButton(
                                      onPressed: _navigateToRegisterScreen,
                                      style: TextButton.styleFrom(
                                        foregroundColor: const Color(0xFF8C3C2F),
                                        padding: EdgeInsets.zero,
                                        minimumSize: const Size(0, 0),
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text(
                                        'Registrate',
                                        style: TextStyle(fontWeight: FontWeight.w700),
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
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToRegisterScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }
}

class _AtmosphericPatch extends StatelessWidget {
  final double size;
  final Color color;

  const _AtmosphericPatch({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
