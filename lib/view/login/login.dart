// ignore_for_file: use_build_context_synchronously, deprecated_member_use

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
  // Form Key
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  // TextForm Controller
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  // Form Validation
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
        // Show error message
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1D3557), Color(0xFF457B9D), Color(0xFFA8DADC)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            const Icon(
                              Icons.shield_moon_outlined,
                              size: 48,
                              color: Color(0xFF1D3557),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Bienvenido de vuelta',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1D3557),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Inicia sesion para continuar',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              enabled: true,
                              readOnly: false,
                              autocorrect: false,
                              enableSuggestions: false,
                              enableInteractiveSelection: true,
                              showCursor: true,
                              cursorOpacityAnimates: false,
                              canRequestFocus: true,
                              scrollPhysics: const ClampingScrollPhysics(),
                              maxLines: 1,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon: const Icon(Icons.alternate_email),
                                filled: true,
                                fillColor: const Color(0xFFF1F5F9),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
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
                              enabled: true,
                              readOnly: false,
                              obscureText: _obscurePassword,
                              autocorrect: false,
                              enableSuggestions: false,
                              enableInteractiveSelection: true,
                              showCursor: true,
                              cursorOpacityAnimates: false,
                              canRequestFocus: true,
                              scrollPhysics: const ClampingScrollPhysics(),
                              maxLines: 1,
                              decoration: InputDecoration(
                                labelText: 'Contrasena',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF1F5F9),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
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
                            ElevatedButton.icon(
                              onPressed: _validateAndSubmit,
                              icon: const Icon(Icons.login),
                              label: const Text('Entrar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1D3557),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text(
                                  'No tienes una cuenta? ',
                                  style: TextStyle(color: Colors.black87),
                                ),
                                GestureDetector(
                                  onTap: _navigateToRegisterScreen,
                                  child: const Text(
                                    'Registrate',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1D3557),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Goto RegisterScreen Page
  void _navigateToRegisterScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }
}
