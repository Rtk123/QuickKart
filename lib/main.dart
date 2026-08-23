import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/env.dart';
import 'services/cart_service.dart';
import 'services/auth_service.dart';
import 'services/location_service.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/admin_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );
  // Saved theme/notification/language preferences app start hone se
  // pehle load kar lete hain, taaki pehli frame hi sahi theme mein bane.
  final settings = await SettingsService.load();
  final location = await LocationService.load();
  runApp(QuickKartApp(settings: settings, location: location));
}

class QuickKartApp extends StatelessWidget {
  const QuickKartApp({
    super.key,
    required this.settings,
    required this.location,
  });

  final SettingsService settings;
  final LocationService location;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: location),
        ChangeNotifierProvider(create: (_) => CartService()),
      ],
      child: Consumer<SettingsService>(
        builder: (context, s, _) => MaterialApp(
          title: 'QuickKart',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: s.themeMode,
          home: const AuthGate(),
        ),
      ),
    );
  }
}

/// Supabase Auth ke login/logout state ko sunta hai aur role ke hisaab se
/// sahi screen dikhata hai: logged out -> Login, customer -> Home,
/// admin -> Admin dashboard.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        final loggedIn = AuthService.isLoggedIn;
        if (!loggedIn) return const LoginScreen();

        return FutureBuilder(
          future: AuthService.fetchCurrentProfile(),
          builder: (context, profileSnap) {
            if (profileSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            final profile = profileSnap.data;
            if (profile != null && profile.role == UserRole.admin) {
              return const AdminScreen();
            }
            return const HomeScreen();
          },
        );
      },
    );
  }
}
