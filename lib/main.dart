import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/pets_provider.dart';
import 'providers/walks_provider.dart';
import 'providers/request_provider.dart';
import 'providers/activity_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PetsProvider()),
        ChangeNotifierProvider(create: (_) => WalksProvider()),
        ChangeNotifierProvider(create: (_) => RequestProvider()),
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
      ],
      child: const PawTrustApp(),
    ),
  );
}
