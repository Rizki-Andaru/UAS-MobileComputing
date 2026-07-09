// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'service_record.dart';
import 'service_result_screen.dart';
import 'vehicle_management_screen.dart';

/// ==========================================
/// SCREEN: INPUT SERVIS TERAKHIR (FORM)
/// ==========================================
class ServiceInputScreen extends StatefulWidget {
  /// Jika diisi, berarti mode EDIT (pre-fill form)
  final ServiceRecord? existingRecord;

  const ServiceInputScreen({super.key, this.existingRecord});

  @override
  State<ServiceInputScreen> createState() => _ServiceInputScreenState();
}

class _ServiceInputScreenState extends State<ServiceInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleController = TextEditingController();
  final _odometerController = TextEditingController();

  String _selectedComponent = serviceComponents.first;
  DateTime _selectedDate = DateTime.now();
  bool _isEditMode = false;

  static const Color _primary = Color(0xFF1E293B);
  static const Color _accent = Color(0xFFF59E0B);
  static const Color _bg = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    if (widget.existingRecord != null) {
      _isEditMode = true;
      final r = widget.existingRecord!;
      _vehicleController.text = r.vehicleName;
      _odometerController.text = r.odometerKm.toString();
      _selectedComponent = r.component;
      _selectedDate = r.serviceDate;
    } else {
      _loadActiveVehicle();
    }
  }

  Future<void> _loadActiveVehicle() async {
    final activeVehicle = await VehicleStorage.getActiveVehicle();
    if (activeVehicle != null) {
      setState(() {
        _vehicleController.text = activeVehicle.name;
        _odometerController.text = activeVehicle.odometerKm.toString();
      });
    }
  }

  @override
  void dispose() {
    _vehicleController.dispose();
    _odometerController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primary,
              onPrimary: Colors.white,
              onSurface: _primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _simpanDanHitung() {
    if (!_formKey.currentState!.validate()) return;

    final odometer = int.tryParse(_odometerController.text.replaceAll(',', '').replaceAll('.', '')) ?? 0;

    final record = calculateNextService(
      vehicleName: _vehicleController.text.trim(),
      component: _selectedComponent,
      serviceDate: _selectedDate,
      odometerKm: odometer,
    );

    // Jika mode edit, gunakan id yang lama
    final finalRecord = _isEditMode
        ? ServiceRecord(
            id: widget.existingRecord!.id,
            vehicleName: record.vehicleName,
            component: record.component,
            serviceDate: record.serviceDate,
            odometerKm: record.odometerKm,
            nextServiceDate: record.nextServiceDate,
            nextServiceKm: record.nextServiceKm,
          )
        : record;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ServiceResultScreen(
          record: finalRecord,
          isEditMode: _isEditMode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _isEditMode ? 'Edit Servis' : 'Input Servis Terakhir',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Judul section
              const Text(
                'Detail Servis',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Masukkan informasi servis terakhir kendaraan Anda.',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // ─── Vehicle Name ───────────────────────────────────
              _buildLabel('Nama Kendaraan'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _vehicleController,
                decoration: _inputDecoration('Contoh: Honda Vario 125', Icons.directions_car_outlined),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama kendaraan wajib diisi' : null,
              ),
              const SizedBox(height: 20),

              // ─── Component Dropdown ───────────────────────────
              _buildLabel('Komponen / Servis'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedComponent,
                decoration: _inputDecoration('Pilih komponen', Icons.build_outlined),
                items: serviceComponents.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => _selectedComponent = val!),
                style: const TextStyle(color: _primary, fontSize: 14),
                dropdownColor: Colors.white,
              ),
              const SizedBox(height: 20),

              // ─── Interval Info ──────────────────────────────────
              _buildIntervalInfo(),
              const SizedBox(height: 20),

              // ─── Date Picker ────────────────────────────────────
              _buildLabel('Tanggal Servis'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, color: _primary, size: 18),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('dd MMMM yyyy', 'id').format(_selectedDate),
                        style: const TextStyle(fontSize: 14, color: _primary),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ─── Odometer ───────────────────────────────────────
              _buildLabel('Odometer Saat Servis (KM)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _odometerController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('Contoh: 15000', Icons.speed_outlined),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Odometer wajib diisi';
                  final val = int.tryParse(v.replaceAll(',', '').replaceAll('.', ''));
                  if (val == null || val < 0) return 'Masukkan angka yang valid';
                  return null;
                },
              ),
              const SizedBox(height: 36),

              // ─── Submit Button ──────────────────────────────────
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _simpanDanHitung,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: _primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.calculate_outlined, size: 20),
                  label: const Text(
                    'SIMPAN & HITUNG',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _primary,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
      prefixIcon: Icon(icon, color: _primary, size: 18),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  Widget _buildIntervalInfo() {
    final interval = serviceIntervals[_selectedComponent];
    if (interval == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF0284C7), size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Interval: setiap ${interval.kmInterval ~/ 1000 < 10 ? interval.kmInterval : "${interval.kmInterval ~/ 1000}K"} KM atau ${interval.monthInterval} bulan',
              style: const TextStyle(fontSize: 12, color: Color(0xFF0369A1)),
            ),
          ),
        ],
      ),
    );
  }
}
