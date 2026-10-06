import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/app_colors.dart';
import 'screens/splash_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Edge-to-edge: el fondo de la app se extiende detrás de la barra de
  // navegación del sistema, en vez de dejarla negra por defecto.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // Barra de estado y de navegación translúcidas con iconos claros (dark mode).
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DogBiometría',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bgDeep,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.turquoise,
          secondary: AppColors.purple,
          surface: AppColors.surface,
          error: AppColors.error,
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: AppColors.turquoise,
          selectionHandleColor: AppColors.turquoise,
        ),
      ),
      home: const SplashPage(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],
      locale: const Locale('es', 'ES'),
    );
  }
}
