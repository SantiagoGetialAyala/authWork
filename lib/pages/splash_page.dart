import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  // Inicializa Supabase
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _redirect();
  }

  /// 🔄 Redirige a la página principal si hay sesión, o a login si no la hay.
  Future<void> _redirect() async {
    // Espera a que el widget se renderice
    await Future.delayed(Duration.zero);
    
    // Si la sesión no es nula, navega a la página principal ('/')
    if (supabase.auth.currentUser != null) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } 
    // Si la sesión es nula, navega a la página de login ('/login')
    else {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Muestra una pantalla de carga mientras verifica la sesión
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}