import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../officer/controller/officer_location_controller.dart';

class OfficerLiveTrackingDemoPage extends StatelessWidget {
  final String reportId;

  const OfficerLiveTrackingDemoPage({
    super.key,
    required this.reportId,
  });

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OfficerLocationController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Officer Live Tracking'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dispatch Tracking',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Report ID: $reportId',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    controller.isSharingLocation
                        ? 'Status: Sharing location'
                        : 'Status: Not sharing',
                    style: TextStyle(
                      color: controller.isSharingLocation
                          ? AppColors.success
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (controller.errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      controller.errorMessage!,
                      style: const TextStyle(
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: controller.isSharingLocation
                    ? null
                    : () async {
                        await context
                            .read<OfficerLocationController>()
                            .startLiveTracking(
                              reportId: reportId,
                              interval: const Duration(seconds: 10),
                            );
                      },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text(
                  'Start Live Tracking',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                onPressed: !controller.isSharingLocation
                    ? null
                    : () async {
                        await context
                            .read<OfficerLocationController>()
                            .stopLiveTracking();
                      },
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text(
                  'Stop Live Tracking',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final success = await context
                      .read<OfficerLocationController>()
                      .sendCurrentLocation(reportId: reportId);

                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Current location sent successfully'
                            : (controller.errorMessage ??
                                'Failed to send location'),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.my_location_rounded),
                label: const Text(
                  'Send Current Location Once',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
