import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/socket_service.dart';
import '../../../data/models/report/emergency_report_model.dart';
import '../../../data/models/report/officer_location_model.dart';
import '../../auth/controller/auth_controller.dart';
import '../controller/emergency_report_controller.dart';

class TrackingPage extends StatefulWidget {
  final String reportId;

  const TrackingPage({
    super.key,
    required this.reportId,
  });

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  final MapController _mapController = MapController();
  final SocketService _socketService = SocketService();
  final Distance _distance = const Distance();

  Timer? _pollingTimer;

  List<LatLng> _routePoints = [];
  String _etaText = 'Menghitung...';
  String _distanceText = '-';

  bool _hasMovedInitially = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();

    _socketService.leaveReport(widget.reportId);
    _socketService.off('connect');
    _socketService.off('connect_error');
    _socketService.off('officer:location_updated');
    _socketService.off('dispatch:status_updated');
    _socketService.off('report:status_updated');
    _socketService.disconnect();

    context.read<EmergencyReportController>().clearSelectedReport();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _refreshTrackingData(initialMove: true);
    _setupSocket();
    _startPollingFallback();
  }

  void _setupSocket() {
    final authController = context.read<AuthController>();
    final token = authController.accessToken;

    if (token == null || token.isEmpty) {
      debugPrint('Socket skipped: access token not found');
      return;
    }

    _socketService.connect(
      baseUrl: ApiConstants.socketBaseUrl,
      token: token,
    );

    _socketService.on('connect', (_) {
      debugPrint('Socket connected');
      _socketService.joinReport(widget.reportId);
    });

    _socketService.on('connect_error', (error) {
      debugPrint('Socket connect error: $error');
    });

    _socketService.on('officer:location_updated', (data) async {
      debugPrint('Socket officer:location_updated => $data');

      final reportId = data is Map ? data['reportId']?.toString() : null;
      if (reportId != widget.reportId) return;

      await _refreshTrackingData();
    });

    _socketService.on('dispatch:status_updated', (data) async {
      debugPrint('Socket dispatch:status_updated => $data');

      final reportId = data is Map ? data['reportId']?.toString() : null;
      if (reportId != widget.reportId) return;

      await _refreshTrackingData();
    });

    _socketService.on('report:status_updated', (data) async {
      debugPrint('Socket report:status_updated => $data');

      final reportId = data is Map ? data['reportId']?.toString() : null;
      if (reportId != widget.reportId) return;

      await _refreshTrackingData();
    });
  }

  void _startPollingFallback() {
    _pollingTimer?.cancel();

    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      await _refreshTrackingData();
    });
  }

  Future<void> _refreshTrackingData({bool initialMove = false}) async {
    if (_isRefreshing) return;

    _isRefreshing = true;

    try {
      final controller = context.read<EmergencyReportController>();

      await controller.fetchReportDetail(
        widget.reportId,
        showLoading: !_hasMovedInitially && initialMove,
      );
      await controller.fetchDispatchByReport(
        widget.reportId,
        showLoading: false,
      );
      await controller.fetchLatestOfficerLocation(
        widget.reportId,
        showLoading: false,
      );

      if (!mounted) return;

      final report = controller.selectedReport;
      if (report == null) return;

      final userLocation = _getUserLocation(report);
      final officerLocation = _getOfficerLocation(
        controller.latestOfficerLocation,
      );

      if (officerLocation != null) {
        await _loadRealRoute(
          from: officerLocation,
          to: userLocation,
        );
      } else {
        if (!mounted) return;
        setState(() {
          _routePoints = [];
          _etaText = 'Menunggu lokasi petugas';
          _distanceText = '-';
        });
      }

      if (!mounted) return;

      if (!_hasMovedInitially || initialMove) {
        _mapController.move(userLocation, 14);
        _hasMovedInitially = true;
      } else if (officerLocation != null) {
        _fitMarkers(officerLocation, userLocation);
      }
    } finally {
      _isRefreshing = false;
    }
  }

  void _fitMarkers(LatLng a, LatLng b) {
    final bounds = LatLngBounds.fromPoints([a, b]);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(60),
      ),
    );
  }

  Future<void> _loadRealRoute({
    required LatLng from,
    required LatLng to,
  }) async {
    try {
      debugPrint('ROUTE FROM: ${from.latitude}, ${from.longitude}');
      debugPrint('ROUTE TO: ${to.latitude}, ${to.longitude}');

      final dio = Dio();

      final url = 'https://router.project-osrm.org/route/v1/driving/'
          '${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
          '?overview=full&geometries=geojson';

      debugPrint('ROUTE URL: $url');

      final response = await dio.get(url);
      final routes = response.data['routes'] as List? ?? [];

      debugPrint('ROUTE COUNT: ${routes.length}');

      if (routes.isEmpty) {
        _applyFallbackEta(from, to);
        return;
      }

      final firstRoute = Map<String, dynamic>.from(routes.first as Map);
      final geometry = Map<String, dynamic>.from(firstRoute['geometry'] as Map);
      final coordinates = geometry['coordinates'] as List? ?? [];

      final points = coordinates.map((item) {
        final c = item as List;
        return LatLng(
          (c[1] as num).toDouble(),
          (c[0] as num).toDouble(),
        );
      }).toList();

      final durationSeconds = (firstRoute['duration'] as num?)?.toDouble() ?? 0;
      final distanceMeters = (firstRoute['distance'] as num?)?.toDouble() ?? 0;

      if (!mounted) return;
      setState(() {
        _routePoints = points;
        _etaText = _formatDuration(durationSeconds);
        _distanceText = _formatDistance(distanceMeters);
      });
    } catch (error, stackTrace) {
      debugPrint('ROUTE ERROR: $error');
      debugPrint('ROUTE STACK: $stackTrace');

      _applyFallbackEta(from, to);
    }
  }

  void _applyFallbackEta(LatLng from, LatLng to) {
    final meters = _distance.as(LengthUnit.Meter, from, to);
    final estimatedMinutes = ((meters / 1000) / 30 * 60).round();

    if (!mounted) return;
    setState(() {
      _routePoints = [from, to];
      _etaText = estimatedMinutes <= 0 ? '1 menit' : '$estimatedMinutes menit';
      _distanceText = _formatDistance(meters);
    });
  }

  String _formatDuration(double seconds) {
    if (seconds <= 0) return 'ETA tidak tersedia';

    final minutes = (seconds / 60).round();
    if (minutes < 60) return '$minutes menit';

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '$hours jam $remainingMinutes menit';
  }

  String _formatDistance(double meters) {
    if (meters <= 0) return '-';
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  LatLng _getUserLocation(EmergencyReportModel report) {
    debugPrint('REPORT LAT: ${report.latitude}');
    debugPrint('REPORT LNG: ${report.longitude}');

    final lat = double.tryParse(report.latitude ?? '') ?? -6.200000;
    final lng = double.tryParse(report.longitude ?? '') ?? 106.816666;

    debugPrint('PARSED USER LATLNG: $lat, $lng');

    return LatLng(lat, lng);
  }

  LatLng? _getOfficerLocation(OfficerLocationModel? latestOfficerLocation) {
    if (latestOfficerLocation == null) return null;
    if (latestOfficerLocation.latitude == 0 ||
        latestOfficerLocation.longitude == 0) {
      return null;
    }

    return LatLng(
      latestOfficerLocation.latitude,
      latestOfficerLocation.longitude,
    );
  }

  ({Color bg, Color text}) _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'REPORTED':
        return (bg: const Color(0xFFF3E8FF), text: const Color(0xFF9333EA));
      case 'ASSIGNED':
        return (bg: const Color(0xFFFFEDD5), text: const Color(0xFFEA580C));
      case 'ACCEPTED':
        return (bg: const Color(0xFFE0F2FE), text: const Color(0xFF0284C7));
      case 'ON_THE_WAY':
        return (bg: const Color(0xFFDBEAFE), text: const Color(0xFF2563EB));
      case 'ARRIVED':
        return (bg: const Color(0xFFDCFCE7), text: const Color(0xFF16A34A));
      case 'HANDLING':
        return (bg: const Color(0xFFFEF3C7), text: const Color(0xFFD97706));
      case 'COMPLETED':
        return (bg: const Color(0xFFE2E8F0), text: const Color(0xFF334155));
      case 'CANCELLED':
        return (bg: const Color(0xFFFEE2E2), text: const Color(0xFFDC2626));
      default:
        return (bg: const Color(0xFFE2E8F0), text: const Color(0xFF475569));
    }
  }

  Future<void> _openGoogleMaps(LatLng destination) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${destination.latitude},${destination.longitude}&travelmode=driving',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openWaze(LatLng destination) async {
    final wazeUri = Uri.parse(
      'waze://?ll=${destination.latitude},${destination.longitude}&navigate=yes',
    );
    final fallbackUri = Uri.parse(
      'https://waze.com/ul?ll=${destination.latitude},${destination.longitude}&navigate=yes',
    );

    if (await canLaunchUrl(wazeUri)) {
      await launchUrl(wazeUri, mode: LaunchMode.externalApplication);
      return;
    }

    if (await canLaunchUrl(fallbackUri)) {
      await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EmergencyReportController>();
    final report = controller.selectedReport;
    final dispatch =
        controller.dispatches.isNotEmpty ? controller.dispatches.first : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Builder(
          builder: (context) {
            if (controller.isLoadingDetail && report == null) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (controller.errorMessage != null && report == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    controller.errorMessage!,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (report == null) {
              return const Center(
                child: Text('Data tracking tidak ditemukan'),
              );
            }

            final userLocation = _getUserLocation(report);
            final officerLocation =
                _getOfficerLocation(controller.latestOfficerLocation);

            final dispatchStyle = _statusColor(
              dispatch?.dispatchStatus ?? report.status,
            );

            final officerName = dispatch?.officer?['fullName']?.toString() ??
                'Petugas belum ditentukan';
            final officerRole =
                dispatch?.officer?['role']?.toString() ?? 'Petugas';
            final ambulanceLabel = dispatch?.ambulance?['name']?.toString() ??
                dispatch?.ambulance?['code']?.toString() ??
                dispatch?.ambulance?['plateNumber']?.toString() ??
                'Ambulans belum ditentukan';

            final lastLocationTime =
                controller.latestOfficerLocation?.recordedAt;

            return Stack(
              children: [
                Positioned.fill(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: userLocation,
                      initialZoom: 14,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.alerta.app',
                      ),
                      if (_routePoints.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _routePoints,
                              strokeWidth: 5,
                              color: AppColors.primary.withValues(alpha: 0.75),
                            ),
                          ],
                        ),
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: userLocation,
                            radius: 34,
                            color: AppColors.primary.withValues(alpha: 0.18),
                            borderStrokeWidth: 0,
                          ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          if (officerLocation != null)
                            Marker(
                              point: officerLocation,
                              width: 54,
                              height: 54,
                              child: const _AmbulanceMarker(),
                            ),
                          Marker(
                            point: userLocation,
                            width: 64,
                            height: 64,
                            child: const _UserMarker(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      _TopCircleButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Tracking Bantuan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      _TopCircleButton(
                        icon: Icons.my_location_rounded,
                        onTap: () {
                          if (officerLocation != null) {
                            _fitMarkers(officerLocation, userLocation);
                          } else {
                            _mapController.move(userLocation, 14);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                DraggableScrollableSheet(
                  initialChildSize: 0.38,
                  minChildSize: 0.22,
                  maxChildSize: 0.78,
                  builder: (context, scrollController) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 38,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppColors.border,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF2563EB),
                                      Color(0xFF1D4ED8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Estimasi Tiba',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _etaText,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 32,
                                              fontWeight: FontWeight.bold,
                                              height: 1,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Jarak $_distanceText',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 58,
                                      height: 58,
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.16),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.access_time_rounded,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              _InfoCard(
                                leading: const _SquareIcon(
                                  icon: Icons.local_hospital_rounded,
                                  bgColor: Color(0xFFE0F2FE),
                                  iconColor: Color(0xFF2563EB),
                                ),
                                title: ambulanceLabel,
                                subtitle: lastLocationTime != null
                                    ? 'Update lokasi terbaru tersedia'
                                    : 'Menunggu lokasi petugas',
                                trailing: _StatusPill(
                                  text: (dispatch?.dispatchStatus ??
                                          report.status)
                                      .replaceAll('_', ' '),
                                  bgColor: dispatchStyle.bg,
                                  textColor: dispatchStyle.text,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _InfoCard(
                                leading: const _SquareIcon(
                                  icon: Icons.person_outline_rounded,
                                  bgColor: Color(0xFFF1F5F9),
                                  iconColor: Color(0xFF64748B),
                                ),
                                title: officerName,
                                subtitle: officerRole.replaceAll('_', ' '),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Lokasi Kejadian',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      report.addressSnapshot?.isNotEmpty == true
                                          ? report.addressSnapshot!
                                          : '-',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () =>
                                          _openGoogleMaps(userLocation),
                                      icon: const Icon(Icons.map_outlined),
                                      label: const Text(
                                        'Google Maps',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size.fromHeight(54),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(18),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _openWaze(userLocation),
                                      icon:
                                          const Icon(Icons.navigation_outlined),
                                      label: const Text(
                                        'Waze',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.textPrimary,
                                        side: const BorderSide(
                                          color: AppColors.border,
                                        ),
                                        minimumSize: const Size.fromHeight(54),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(18),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TopCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopCircleButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _AmbulanceMarker extends StatelessWidget {
  const _AmbulanceMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: const Text(
        '🚑',
        style: TextStyle(fontSize: 28),
      ),
    );
  }
}

class _UserMarker extends StatelessWidget {
  const _UserMarker();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 12,
              spreadRadius: 6,
            ),
          ],
        ),
      ),
    );
  }
}

class _SquareIcon extends StatelessWidget {
  final IconData icon;
  final Color bgColor;
  final Color iconColor;

  const _SquareIcon({
    required this.icon,
    required this.bgColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: iconColor),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _InfoCard({
    required this.leading,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color bgColor;
  final Color textColor;

  const _StatusPill({
    required this.text,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
