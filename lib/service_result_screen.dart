import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'service_record.dart';
import 'vehicle_management_screen.dart';
import 'main_navigation.dart';

/// ==========================================
/// SCREEN: HASIL PERHITUNGAN JADWAL BERIKUTNYA
/// ==========================================
class ServiceResultScreen extends StatelessWidget {
  final ServiceRecord record;
  final bool isEditMode;

  const ServiceResultScreen({
    super.key,
    required this.record,
    this.isEditMode = false,
  });

  static const Color _primary = Color(0xFF1E293B);
  static const Color _accent = Color(0xFFF59E0B);
  static const Color _bg = Color(0xFFF8FAFC);

  Future<void> _masukkanKeHistori(BuildContext context) async {
    if (isEditMode) {
      await ServiceStorage.update(record);
    } else {
      await ServiceStorage.save(record);
    }

    // Update odometer kendaraan aktif jika namanya cocok dan odometer servis lebih besar
    final activeVehicle = await VehicleStorage.getActiveVehicle();
    if (activeVehicle != null && activeVehicle.name == record.vehicleName) {
      if (record.odometerKm > activeVehicle.odometerKm) {
        final updatedVehicle = Vehicle(
          id: activeVehicle.id,
          name: activeVehicle.name,
          plateNumber: activeVehicle.plateNumber,
          odometerKm: record.odometerKm,
          type: activeVehicle.type,
        );
        final allVehicles = await VehicleStorage.getAll();
        final idx = allVehicles.indexWhere((v) => v.id == activeVehicle.id);
        if (idx != -1) {
          allVehicles[idx] = updatedVehicle;
          await VehicleStorage.saveAll(allVehicles);
        }
      }
    }

    if (!context.mounted) return;

    // Tampilkan snackbar konfirmasi
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isEditMode ? 'Data berhasil diperbarui!' : 'Berhasil disimpan ke riwayat!'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    // Kembali ke root navigator lokal (Dashboard atau History)
    Navigator.of(context).popUntil((route) => route.isFirst);
    
    // Pindah ke Tab 2 (Jadwal Servis) pada navigasi utama
    context.findAncestorStateOfType<MainNavigationScreenState>()?.setTabIndex(2);
  }

  @override
  Widget build(BuildContext context) {
    final interval = serviceIntervals[record.component] ??
        const ServiceInterval(kmInterval: 10000, monthInterval: 6);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Jadwal Servis Berikutnya',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Header Konfirmasi ─────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF334155)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.amber,
                    radius: 24,
                    child: Icon(Icons.check, color: Color(0xFF1E293B), size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Perhitungan Selesai!',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          record.vehicleName,
                          style: TextStyle(color: Colors.grey[400], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── Kartu Servis Terakhir ─────────────────────────
            const Text(
              'JADWAL SERVIS BERIKUTNYA',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),

            _buildResultCard(
              component: record.component,
              nextKm: record.nextServiceKm,
              nextDate: record.nextServiceDate,
              lastKm: record.odometerKm,
              lastDate: record.serviceDate,
              intervalKm: interval.kmInterval,
              intervalMonth: interval.monthInterval,
            ),
            const SizedBox(height: 32),

            // ─── Ringkasan Input ───────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ringkasan Data Input',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Kendaraan', record.vehicleName, Icons.directions_car_outlined),
                  _buildInfoRow('Komponen', record.component, Icons.build_outlined),
                  _buildInfoRow(
                    'Tgl Servis',
                    DateFormat('dd MMM yyyy', 'id').format(record.serviceDate),
                    Icons.calendar_today_outlined,
                  ),
                  _buildInfoRow(
                    'Odometer',
                    '${record.odometerKm.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')} KM',
                    Icons.speed_outlined,
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ─── Tombol Masukkan ke Histori ────────────────────
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => _masukkanKeHistori(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: _primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.save_outlined, size: 20),
                label: Text(
                  isEditMode ? 'PERBARUI HISTORI' : 'MASUKKAN KE HISTORI',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ─── Tombol Kembali ────────────────────────────────
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primary,
                  side: const BorderSide(color: Color(0xFF94A3B8)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit Data', style: TextStyle(fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard({
    required String component,
    required int nextKm,
    required DateTime nextDate,
    required int lastKm,
    required DateTime lastDate,
    required int intervalKm,
    required int intervalMonth,
  }) {
    final isUrgent = nextDate.difference(DateTime.now()).inDays < 30 ||
        nextKm - lastKm < 1000;

    final cardColor = isUrgent
        ? const Color(0xFFFEF2F2)
        : const Color(0xFFF0FDF4);
    final borderColor = isUrgent
        ? const Color(0xFFFCA5A5)
        : const Color(0xFF86EFAC);
    final accentColor = isUrgent
        ? const Color(0xFFEF4444)
        : const Color(0xFF10B981);
    final icon = isUrgent ? Icons.warning_amber_rounded : Icons.check_circle_outline;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  component.toUpperCase(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
              // Edit icon
              Icon(Icons.edit_note, color: accentColor.withAlpha(120), size: 20),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Rekomendasi berikutnya:',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildPill(
                Icons.speed,
                '${nextKm.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')} KM',
                accentColor,
              ),
              const SizedBox(width: 10),
              const Text('atau', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              const SizedBox(width: 10),
              _buildPill(
                Icons.calendar_month,
                DateFormat('dd MMM yyyy', 'id').format(nextDate),
                accentColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: borderColor),
          const SizedBox(height: 12),
          Text(
            'Interval: setiap ${intervalKm >= 1000 ? "${intervalKm ~/ 1000}K" : intervalKm} KM atau $intervalMonth bulan',
            style: TextStyle(fontSize: 11, color: accentColor.withAlpha(180)),
          ),
        ],
      ),
    );
  }

  Widget _buildPill(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.grey[500]),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _primary),
          ),
        ],
      ),
    );
  }
}
