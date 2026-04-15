import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/network/dio_client.dart';
import 'core/storage/secure_storage_service.dart';

import 'data/repositories/auth_repository.dart';
import 'data/repositories/emergency_report_repository.dart';
import 'data/repositories/officer_location_repository.dart';

import 'data/services/auth_api_service.dart';
import 'data/services/emergency_report_api_service.dart';
import 'data/services/officer_location_api_service.dart';

import 'features/auth/controller/auth_controller.dart';
import 'features/report/controller/emergency_report_controller.dart';
import 'features/officer/controller/officer_location_controller.dart';

import 'data/repositories/officer_dispatch_repository.dart';
import 'data/services/officer_dispatch_api_service.dart';
import 'features/officer/controller/officer_dispatch_controller.dart';

import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  final secureStorageService = SecureStorageService();
  final dioClient = DioClient(secureStorageService: secureStorageService);

  final authApiService = AuthApiService(dioClient: dioClient);
  final authRepository = AuthRepository(
    authApiService: authApiService,
    secureStorageService: secureStorageService,
  );

  final emergencyReportApiService =
      EmergencyReportApiService(dioClient: dioClient);
  final emergencyReportRepository = EmergencyReportRepository(
    emergencyReportApiService: emergencyReportApiService,
  );

  final officerLocationApiService =
      OfficerLocationApiService(dioClient: dioClient);
  final officerLocationRepository = OfficerLocationRepository(
    officerLocationApiService: officerLocationApiService,
  );

  final officerDispatchApiService =
      OfficerDispatchApiService(dioClient: dioClient);
  final officerDispatchRepository = OfficerDispatchRepository(
    officerDispatchApiService: officerDispatchApiService,
  );

  runApp(
    MyApp(
      authRepository: authRepository,
      emergencyReportRepository: emergencyReportRepository,
      officerLocationRepository: officerLocationRepository,
      officerDispatchRepository: officerDispatchRepository,
    ),
  );
}

class MyApp extends StatelessWidget {
  final AuthRepository authRepository;
  final EmergencyReportRepository emergencyReportRepository;
  final OfficerLocationRepository officerLocationRepository;
  final OfficerDispatchRepository officerDispatchRepository;

  const MyApp({
    super.key,
    required this.authRepository,
    required this.emergencyReportRepository,
    required this.officerLocationRepository,
    required this.officerDispatchRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthController(authRepository: authRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => EmergencyReportController(
            emergencyReportRepository: emergencyReportRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => OfficerLocationController(
            officerLocationRepository: officerLocationRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => OfficerDispatchController(
            officerDispatchRepository: officerDispatchRepository,
          ),
        ),
      ],
      child: MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateRoute: AppPages.onGenerateRoute,
      initialRoute: AppRoutes.login, 
      ),
    );
  }
}
