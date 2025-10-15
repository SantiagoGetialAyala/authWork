import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/student_docs_page.dart';
import 'pages/login_page.dart';
import 'pages/splash_page.dart'; // Mantener la importación por si se usa en otro lugar, aunque la lógica del StreamBuilder la reemplaza.

void main() async {
  // Asegura que Flutter esté inicializado antes de llamar a servicios nativos
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Supabase con tus credenciales
  await Supabase.initialize(
    // URL real
    url: 'https://jrjckwrvriuralokjgen.supabase.co',
    // Clave Anon pública real
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpyamNrd3J2cml1cmFsb2tqZ2VuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA1MzU0MzMsImV4cCI6MjA3NjExMTQzM30.QI7HdQdHEx6iWOKzqEgzkh0xAnZ4babzYMzrPgeg_8Y',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // El widget raíz que contendrá el Navigator
    return MaterialApp(
      title: 'Gestor de Documentos',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blueGrey,
      ),
      // Usamos 'home' para establecer el widget inicial que controlará la navegación
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          // 1. Manejar el estado de carga y error (incluye 'initialSession')
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Muestra una pantalla de carga mientras Supabase verifica la sesión inicial
            return const SplashPage();
          }

          // 2. Verificar si hay sesión activa
          final Session? session = snapshot.data?.session;

          if (session != null) {
            // Si hay sesión (usuario logueado), va a la página principal
            return const StudentDocsPage();
          } else {
            // Si no hay sesión (cerró sesión, expiró o nunca existió), va al login
            return const LoginPage();
          }
        },
      ),
      // Las rutas ya no son necesarias si la navegación es manejada por el StreamBuilder en 'home'.
      // Las eliminamos para simplificar.
      // routes: {
      //   '/': (context) => const StudentDocsPage(),
      //   '/login': (context) => const LoginPage(),
      // },
    );
  }
}
