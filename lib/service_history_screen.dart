import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'service_record.dart';
import 'service_input_screen.dart';

/// ==========================================
/// SCREEN: SEMUA RIWAYAT SERVIS (TABEL)
/// ==========================================
class ServiceHistoryScreen extends StatefulWidget {
  const ServiceHistoryScreen({super.key});

  @override
  State<ServiceHistoryScreen> createState() => _ServiceHistoryScreenState();
}

class _ServiceHistoryScreenState extends State<ServiceHistoryScreen> {
  List<ServiceRecord> _records = [];
  bool _isLoading = true;

  static const Color _primary = Color(0xFF1E293B);
  static const Color _bg = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final records = await ServiceStorage.getAll();
    // Urutkan dari yang terbaru
    records.sort((a, b) => b.serviceDate.compareTo(a.serviceDate));
    setState(() {
      _records = records;
      _isLoading = false;
    });
  }

  Future<void> _deleteRecord(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Riwayat?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Data servis ini akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ServiceStorage.delete(id);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Data berhasil dihapus.'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _editRecord(ServiceRecord record) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ServiceInputScreen(existingRecord: record),
      ),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Semua Riwayat Servis',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : _records.isEmpty
              ? _buildEmptyState()
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── Summary Bar ──────────────────────────────────────
        Container(
          color: _primary,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Row(
            children: [
              _buildSummaryChip(
                '${_records.length} Total',
                Icons.list_alt,
                Colors.amber,
              ),
              const SizedBox(width: 12),
              _buildSummaryChip(
                '${_records.where((r) => r.nextServiceDate.isBefore(DateTime.now().add(const Duration(days: 30)))).length} Segera',
                Icons.warning_amber_rounded,
                Colors.orange,
              ),
            ],
          ),
        ),

        // ─── Tabel Header ────────────────────────────────────
        Container(
          color: const Color(0xFF334155),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              _buildHeaderCell('Tanggal', flex: 2),
              _buildHeaderCell('Servis', flex: 3),
              _buildHeaderCell('KM Last', flex: 2),
              _buildHeaderCell('Tgl Next', flex: 2),
              _buildHeaderCell('KM Next', flex: 2),
              _buildHeaderCell('Aksi', flex: 2),
            ],
          ),
        ),

        // ─── Tabel Body ───────────────────────────────────────
        Expanded(
          child: ListView.builder(
            itemCount: _records.length,
            itemBuilder: (context, index) => _buildTableRow(_records[index], index),
          ),
        ),
      ],
    );
  }

  Widget _buildTableRow(ServiceRecord r, int index) {
    final isNearDue = r.nextServiceDate
        .isBefore(DateTime.now().add(const Duration(days: 30)));
    final isOverdue = r.nextServiceDate.isBefore(DateTime.now());

    Color rowColor = index.isEven ? Colors.white : const Color(0xFFF8FAFC);
    Color? statusColor;
    if (isOverdue) statusColor = const Color(0xFFFEF2F2);
    if (isNearDue && !isOverdue) statusColor = const Color(0xFFFFFBEB);

    return Container(
      color: statusColor ?? rowColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // Tanggal Servis
          Expanded(
            flex: 2,
            child: Text(
              DateFormat('dd/MM/yy').format(r.serviceDate),
              style: const TextStyle(fontSize: 11, color: Color(0xFF1E293B)),
            ),
          ),
          // Komponen
          Expanded(
            flex: 3,
            child: Text(
              r.component,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // KM Last
          Expanded(
            flex: 2,
            child: Text(
              _formatKm(r.odometerKm),
              style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
            ),
          ),
          // Tanggal Next
          Expanded(
            flex: 2,
            child: Text(
              DateFormat('dd/MM/yy').format(r.nextServiceDate),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isOverdue
                    ? Colors.red
                    : isNearDue
                        ? Colors.orange
                        : const Color(0xFF10B981),
              ),
            ),
          ),
          // KM Next
          Expanded(
            flex: 2,
            child: Text(
              _formatKm(r.nextServiceKm),
              style: TextStyle(
                fontSize: 11,
                color: isOverdue ? Colors.red : const Color(0xFF475569),
              ),
            ),
          ),
          // Aksi
          Expanded(
            flex: 2,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _editRecord(r),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.edit, size: 14, color: Color(0xFF3B82F6)),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _deleteRecord(r.id),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.delete, size: 14, color: Color(0xFFEF4444)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
        ),
      ),
    );
  }

  Widget _buildSummaryChip(String text, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history, size: 40, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Belum Ada Riwayat Servis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primary),
            ),
            const SizedBox(height: 10),
            Text(
              'Mulai catat servis pertama kendaraanmu dari halaman utama.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  String _formatKm(int km) {
    return km.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]},',
        );
  }
}
