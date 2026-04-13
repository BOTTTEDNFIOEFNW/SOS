import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/storage/secure_storage_service.dart';
import 'core/network/dio_client.dart';
import 'data/repositories/auth_repository.dart';
import 'data/services/auth_api_service.dart';
import 'features/auth/controller/auth_controller.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

void main() {
  final secureStorageService = SecureStorageService();
  final dioClient = DioClient(secureStorageService: secureStorageService);
  final authApiService = AuthApiService(dioClient: dioClient);
  final authRepository = AuthRepository(
    authApiService: authApiService,
    secureStorageService: secureStorageService,
  );

  runApp(MyApp(authRepository: authRepository));
}

class MyApp extends StatelessWidget {
  final AuthRepository authRepository;

  const MyApp({
    super.key,
    required this.authRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthController(authRepository: authRepository),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Alerta',
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppPages.onGenerateRoute,
      ),
    );
  }
}
