// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:larpland/model/user.dart';
import 'package:larpland/service/register.dart';
import 'package:larpland/util/error_message.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // server response
  late Future<User> futureRegister;

  // Form Key
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  // TextForm Controller
  TextEditingController nameController = TextEditingController();
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
        futureRegister = register(
          nameController.text,
          emailController.text,
          passwordController.text,
        );
        await futureRegister;
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Registro exitoso'),
            content: const Text('Ahora puedes iniciar sesion'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
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
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2C4432), Color(0xFF8C3C2F), Color(0xFFD3BE8A)],
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
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back),
                            ),
                          ),
                          const Icon(
                            Icons.person_add_alt_1_outlined,
                            size: 48,
                            color: Color(0xFF2C4432),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Crea tu cuenta',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2C4432),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Registrate para empezar',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: nameController,
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
                              labelText: 'Nombre',
                              prefixIcon: const Icon(Icons.person_outline),
                              filled: true,
                              fillColor: const Color(0xFFF3EBD4),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, ingrese su nombre';
                              }
                              return null;
                            },
                            onSaved: (value) => nameController.text = value ?? '',
                          ),
                          const SizedBox(height: 14),
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
                              fillColor: const Color(0xFFF3EBD4),
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
                            onSaved: (value) => emailController.text = value ?? '',
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
                              fillColor: const Color(0xFFF3EBD4),
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
                            onSaved: (value) =>
                                passwordController.text = value ?? '',
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _validateAndSubmit,
                            icon: const Icon(Icons.app_registration),
                            label: const Text('Registrarme'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2C4432),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
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
    );
  }
}

