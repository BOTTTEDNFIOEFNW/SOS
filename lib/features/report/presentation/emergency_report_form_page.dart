import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../controller/emergency_report_controller.dart';

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class EmergencyReportFormPage extends StatefulWidget {
  final String? serviceId;
  final String? initialEmergencyType;

  const EmergencyReportFormPage({
    super.key,
    this.serviceId,
    this.initialEmergencyType,
  });

  @override
  State<EmergencyReportFormPage> createState() =>
      _EmergencyReportFormPageState();
}

class _EmergencyReportFormPageState extends State<EmergencyReportFormPage> {
  final _formKey = GlobalKey<FormState>();

  final descriptionController = TextEditingController();
  final addressController = TextEditingController();
  final latitudeController = TextEditingController(text: '-6.200000');
  final longitudeController = TextEditingController(text: '106.816666');

  String selectedEmergencyType = 'AMBULANCE';

  final ImagePicker _imagePicker = ImagePicker();
  File? selectedPhoto;
  DateTime? photoCapturedAt;
  Timer? _liveClockTimer;
  DateTime _liveNow = DateTime.now();

  final List<Map<String, dynamic>> emergencyTypes = const [
    {
      'label': 'Ambulans',
      'value': 'AMBULANCE',
      'icon': Icons.local_hospital_rounded,
      'color': Color(0xFF3B82F6),
    },
    {
      'label': 'Kebakaran',
      'value': 'FIRE',
      'icon': Icons.local_fire_department_rounded,
      'color': Color(0xFFFF6B2D),
    },
    {
      'label': 'Kriminal',
      'value': 'CRIME',
      'icon': Icons.shield_outlined,
      'color': Color(0xFFEF4444),
    },
    {
      'label': 'SOS',
      'value': 'SOS',
      'icon': Icons.sos,
      'color': Color(0xFFDC2626),
    },
  ];

  @override
  void initState() {
    super.initState();

    if (widget.initialEmergencyType != null &&
        widget.initialEmergencyType!.trim().isNotEmpty) {
      selectedEmergencyType = widget.initialEmergencyType!;
    }

    _liveClockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _liveNow = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    descriptionController.dispose();
    addressController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    _liveClockTimer?.cancel();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (picked == null) return;

    setState(() {
      selectedPhoto = File(picked.path);
      photoCapturedAt = DateTime.now();
    });
  }

  Future<void> _showPhotoSourcePicker() async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Pilih Sumber Foto',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 18),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Kamera'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImage(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Galeri'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedPhoto == null || photoCapturedAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Foto bukti wajib diambil'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.danger,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
      return;
    }

    final controller = context.read<EmergencyReportController>();

    final success = await controller.submitReport(
      serviceId: widget.serviceId,
      emergencyType: selectedEmergencyType,
      description: descriptionController.text.trim(),
      latitude: latitudeController.text.trim(),
      longitude: longitudeController.text.trim(),
      addressSnapshot: addressController.text.trim(),
      photoCapturedAt: photoCapturedAt!,
      photo: selectedPhoto!,
    );

    if (!mounted) return;

    if (success) {
      showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Laporan Terkirim',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'Laporan darurat berhasil dikirim. Petugas akan segera memproses laporan Anda.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage ?? 'Gagal mengirim laporan'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.danger,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }
  }

  Future<void> _fillCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Location service is disabled'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Location permission denied'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Location permission permanently denied. Please enable it in settings.',
            ),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      latitudeController.text = position.latitude.toStringAsFixed(6);
      longitudeController.text = position.longitude.toStringAsFixed(6);

      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final p = placemarks.first;

          final addressParts = [
            p.street,
            p.subLocality,
            p.locality,
            p.administrativeArea,
            p.postalCode,
            p.country,
          ]
              .where((e) => e != null && e.trim().isNotEmpty)
              .map((e) => e!.trim())
              .toList();

          addressController.text = addressParts.join(', ');
        } else {
          addressController.text =
              '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        }
      } catch (_) {
        addressController.text =
            '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      }

      if (!mounted) return;

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lokasi saat ini berhasil diambil'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Gagal mengambil lokasi saat ini'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }
  }

  void _fillMockLocation() {
    setState(() {
      addressController.text = 'Jl. Persatuan Raya No. 12, Jakarta Selatan';
      latitudeController.text = '-6.214620';
      longitudeController.text = '106.845130';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Lokasi contoh berhasil diisi'),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportController = context.watch<EmergencyReportController>();

    final selectedType = emergencyTypes.firstWhere(
      (item) => item['value'] == selectedEmergencyType,
      orElse: () => emergencyTypes.first,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text(
          'Laporan Darurat',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _SelectedEmergencyBanner(
                  label: selectedType['label'] as String,
                  icon: selectedType['icon'] as IconData,
                  color: selectedType['color'] as Color,
                ),
                const SizedBox(height: 20),
                // _SectionCard(
                //   title: 'Jenis Kejadian',
                //   child: Wrap(
                //     spacing: 10,
                //     runSpacing: 10,
                //     children: emergencyTypes.map((item) {
                //       final isSelected = selectedEmergencyType == item['value'];

                //       return GestureDetector(
                //         onTap: () {
                //           setState(() {
                //             selectedEmergencyType = item['value'] as String;
                //           });
                //         },
                //         child: _EmergencyTypeChoice(
                //           label: item['label'] as String,
                //           icon: item['icon'] as IconData,
                //           color: item['color'] as Color,
                //           isSelected: isSelected,
                //         ),
                //       );
                //     }).toList(),
                //   ),
                // ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Detail Laporan',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FieldLabel('Deskripsi Kejadian'),
                      TextFormField(
                        controller: descriptionController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          hintText:
                              'Jelaskan kondisi darurat yang sedang terjadi...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                          ),
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) {
                            return 'Deskripsi kejadian wajib diisi';
                          }
                          if (text.length < 5) {
                            return 'Deskripsi minimal 5 karakter';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Lokasi Kejadian',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _fillCurrentLocation,
                          icon: const Icon(Icons.my_location_rounded),
                          label: const Text('Gunakan Lokasi Saat Ini'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _FieldLabel('Alamat'),
                      TextFormField(
                        controller: addressController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Alamat lokasi kejadian',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                          ),
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(bottom: 52),
                            child: Icon(Icons.location_on_outlined),
                          ),
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) {
                            return 'Alamat wajib diisi';
                          }
                          if (text.length < 5) {
                            return 'Alamat minimal 5 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      const Row(
                        children: [
                          Expanded(child: _FieldLabel('Latitude')),
                          SizedBox(width: 12),
                          Expanded(child: _FieldLabel('Longitude')),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: latitudeController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                signed: true,
                                decimal: true,
                              ),
                              decoration: const InputDecoration(
                                hintText: '-6.200000',
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(16)),
                                ),
                              ),
                              validator: (value) {
                                final text = value?.trim() ?? '';
                                if (text.isEmpty) return 'Latitude wajib diisi';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: longitudeController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                signed: true,
                                decimal: true,
                              ),
                              decoration: const InputDecoration(
                                hintText: '106.816666',
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(16)),
                                ),
                              ),
                              validator: (value) {
                                final text = value?.trim() ?? '';
                                if (text.isEmpty)
                                  return 'Longitude wajib diisi';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Foto Bukti',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (selectedPhoto == null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppColors.border,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.camera_alt_outlined,
                                size: 42,
                                color: AppColors.textSecondary,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Belum ada foto dipilih',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Ambil foto langsung atau pilih dari galeri',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.file(
                            selectedPhoto!,
                            width: double.infinity,
                            height: 220,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Timestamp Capture',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd MMM yyyy • HH:mm:ss')
                                    .format(photoCapturedAt ?? _liveNow),
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _showPhotoSourcePicker,
                          icon: const Icon(Icons.add_a_photo_outlined),
                          label: Text(
                            selectedPhoto == null
                                ? 'Ambil / Pilih Foto'
                                : 'Ganti Foto',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Waktu live sekarang: ${DateFormat('dd MMM yyyy • HH:mm:ss').format(_liveNow)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.danger,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Pastikan informasi yang Anda kirim akurat. Laporan palsu dapat mengganggu proses penanganan darurat.',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: reportController.isSubmitting ? null : _submit,
                    icon: reportController.isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(
                      reportController.isSubmitting
                          ? 'Mengirim...'
                          : 'Kirim Laporan',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedEmergencyBanner extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _SelectedEmergencyBanner({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color,
            color.withValues(alpha: 0.82),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Jenis Laporan Dipilih',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _EmergencyTypeChoice extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;

  const _EmergencyTypeChoice({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 145,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSelected ? color.withValues(alpha: 0.12) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected ? color : AppColors.border,
          width: isSelected ? 1.6 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? color : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
