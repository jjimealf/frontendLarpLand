// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:larpland/service/login.dart';
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

  // TextForm Controller
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  // Form Validation
  bool _validateAndSave() {
    final form = _formKey.currentState;
    if (form!.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  Future<void> _validateAndSubmit() async {
    if (_validateAndSave()) {
      try {
        final futureResult = await login(emailController.text, passwordController.text);
        if (!mounted) return;
        if (futureResult.rol == 0) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen(userId: futureResult.userId)),
          );
        } else if (futureResult.rol == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdminHome()),
          );
        } else {
          // Login failed, show error message
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Login Fallido'),
              content: const Text(
                  'Por favor, verifique su correo electrónico y contraseña'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        // Show error message
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(e.toString()),
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
    return WillPopScope(
      onWillPop: () {
        return Future.value(false);
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Login'),
        ),
        body: Container(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Por favor, ingrese su correo electrónico';
                    }
                    return null;
                  },
                  onSaved: (value) => emailController.text = value!,
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Por favor, ingrese su contraseña';
                    }
                    return null;
                  },
                  onSaved: (value) => passwordController.text = value!,
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: _validateAndSubmit,
                  child: const Text('Logearse'),
                ),
                const SizedBox(height: 16.0),
                Center(
                  child: GestureDetector(
                    onTap: _navigateToRegisterScreen,
                    child: RichText(
                      text: const TextSpan(
                        text: '¿No tienes una cuenta?',
                        style: TextStyle(color: Colors.black),
                        children: <TextSpan>[
                          TextSpan(
                            text: 'Regístrate',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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
