// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────
// MODEL: Vehicle
// ─────────────────────────────────────────
class Vehicle {
  final String id;
  final String name;
  final String plateNumber;
  final int odometerKm;
  final String type; // 'Mobil' | 'Motor'

  Vehicle({
    required this.id,
    required this.name,
    required this.plateNumber,
    required this.odometerKm,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'plateNumber': plateNumber,
        'odometerKm': odometerKm,
        'type': type,
      };

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        plateNumber: json['plateNumber'] ?? '',
        odometerKm: json['odometerKm'] ?? 0,
        type: json['type'] ?? 'Mobil',
      );
}

// ─────────────────────────────────────────
// STORAGE: VehicleStorage
// ─────────────────────────────────────────
class VehicleStorage {
  static const String _listKey = 'registered_vehicles';
  static const String _activeKey = 'active_vehicle_id';

  // Ambil semua kendaraan terdaftar
  static Future<List<Vehicle>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_listKey);
    if (jsonString == null) {
      // Inisialisasi data demo awal jika kosong
      final demoVehicles = [
        Vehicle(
          id: 'demo_1',
          name: 'Honda Vario 125',
          plateNumber: 'D 1234 ABC',
          odometerKm: 15000,
          type: 'Motor',
        )
      ];
      await saveAll(demoVehicles);
      await setActiveId('demo_1');
      return demoVehicles;
    }
    final List<dynamic> decoded = jsonDecode(jsonString);
    return decoded.map((e) => Vehicle.fromJson(e)).toList();
  }

  // Simpan seluruh list kendaraan
  static Future<void> saveAll(List<Vehicle> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_listKey, jsonEncode(list.map((v) => v.toJson()).toList()));
  }

  // Tambah kendaraan baru
  static Future<void> add(Vehicle vehicle) async {
    final list = await getAll();
    list.add(vehicle);
    await saveAll(list);
  }

  // Hapus kendaraan
  static Future<void> delete(String id) async {
    final list = await getAll();
    list.removeWhere((v) => v.id == id);
    await saveAll(list);

    // Jika kendaraan yang dihapus adalah kendaraan aktif, set yang pertama sebagai aktif
    final activeId = await getActiveId();
    if (activeId == id && list.isNotEmpty) {
      await setActiveId(list.first.id);
    }
  }

  // Ambil ID kendaraan aktif
  static Future<String?> getActiveId() async {
    final prefs = await SharedPreferences.getInstance();
    String? activeId = prefs.getString(_activeKey);
    if (activeId == null) {
      final list = await getAll();
      if (list.isNotEmpty) {
        activeId = list.first.id;
        await prefs.setString(_activeKey, activeId);
      }
    }
    return activeId;
  }

  // Set ID kendaraan aktif
  static Future<void> setActiveId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeKey, id);
  }

  // Ambil data kendaraan aktif lengkap
  static Future<Vehicle?> getActiveVehicle() async {
    final list = await getAll();
    final activeId = await getActiveId();
    if (list.isEmpty) return null;
    final active = list.firstWhere((v) => v.id == activeId, orElse: () => list.first);
    return active;
  }
}

// ─────────────────────────────────────────
// UI SCREEN: VehicleManagementScreen
// ─────────────────────────────────────────
class VehicleManagementScreen extends StatefulWidget {
  final VoidCallback? onVehicleChanged;

  const VehicleManagementScreen({super.key, this.onVehicleChanged});

  @override
  State<VehicleManagementScreen> createState() => _VehicleManagementScreenState();
}

class _VehicleManagementScreenState extends State<VehicleManagementScreen> {
  List<Vehicle> _vehicles = [];
  String? _activeVehicleId;
  bool _isLoading = true;

  // Form State
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _plateController = TextEditingController();
  final _odometerController = TextEditingController();
  String _selectedType = 'Mobil';

  static const Color _primary = Color(0xFF1E293B);
  static const Color _accent = Color(0xFFF59E0B);
  static const Color _bg = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _plateController.dispose();
    _odometerController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final vehicles = await VehicleStorage.getAll();
    final activeId = await VehicleStorage.getActiveId();
    setState(() {
      _vehicles = vehicles;
      _activeVehicleId = activeId;
      _isLoading = false;
    });
  }

  Future<void> _toggleActive(String id) async {
    await VehicleStorage.setActiveId(id);
    if (!mounted) return;
    setState(() {
      _activeVehicleId = id;
    });
    if (widget.onVehicleChanged != null) {
      widget.onVehicleChanged!();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kendaraan aktif berhasil diubah.'),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _addVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    final odometer = int.tryParse(_odometerController.text.replaceAll(',', '').replaceAll('.', '')) ?? 0;
    final newVehicle = Vehicle(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      plateNumber: _plateController.text.trim().toUpperCase(),
      odometerKm: odometer,
      type: _selectedType,
    );

    await VehicleStorage.add(newVehicle);
    
    // Set langsung menjadi aktif jika ini satu-satunya atau pilihan pengguna
    await VehicleStorage.setActiveId(newVehicle.id);

    if (!mounted) return;

    // Reset Form
    _nameController.clear();
    _plateController.clear();
    _odometerController.clear();
    setState(() {
      _selectedType = 'Mobil';
    });

    Navigator.pop(context); // Tutup BottomSheet/Dialog
    await _loadData();
    
    if (!mounted) return;
    
    if (widget.onVehicleChanged != null) {
      widget.onVehicleChanged!();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kendaraan baru berhasil ditambahkan!'),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _deleteVehicle(String id, String name) async {
    if (_vehicles.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimal harus menyisakan 1 kendaraan.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Kendaraan?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Kendaraan "$name" akan dihapus dari daftar Anda secara permanen.'),
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
      await VehicleStorage.delete(id);
      await _loadData();
      if (widget.onVehicleChanged != null) {
        widget.onVehicleChanged!();
      }
    }
  }

  void _showAddVehicleSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tambah Kendaraan Baru',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primary),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          )
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 10),

                      // Tipe Kendaraan (Radio)
                      const Text(
                        'Tipe Kendaraan',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _primary),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Mobil'),
                              value: 'Mobil',
                              groupValue: _selectedType,
                              activeColor: _accent,
                              onChanged: (val) => setSheetState(() => _selectedType = val!),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Motor'),
                              value: 'Motor',
                              groupValue: _selectedType,
                              activeColor: _accent,
                              onChanged: (val) => setSheetState(() => _selectedType = val!),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Nama Kendaraan
                      TextFormField(
                        controller: _nameController,
                        decoration: _inputDecoration('Merek & Tipe Kendaraan (e.g. Honda Civic)', Icons.directions_car),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama kendaraan wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),

                      // Plat Nomor
                      TextFormField(
                        controller: _plateController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: _inputDecoration('Plat Nomor (e.g. B 1234 CD)', Icons.credit_card_outlined),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Plat nomor wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),

                      // Odometer
                      TextFormField(
                        controller: _odometerController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('Odometer Saat Ini (KM)', Icons.speed_outlined),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Odometer wajib diisi';
                          final val = int.tryParse(v);
                          if (val == null || val < 0) return 'Masukkan angka KM yang valid';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Tombol Simpan
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _addVehicle,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: _primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                          child: const Text('TAMBAH KENDARAAN', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
      prefixIcon: Icon(icon, color: _primary, size: 18),
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        automaticallyImplyLeading: false, // Menghilangkan back button bawaan karena ini tab utama
        title: const Text(
          'Manajemen Kendaraan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Header
                Container(
                  color: _primary,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kelola Garasi Anda',
                        style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pilih kendaraan aktif untuk mencatat servis dan menghitung jadwal perawatan yang sesuai.',
                        style: TextStyle(fontSize: 12.5, color: Colors.grey[300], height: 1.4),
                      ),
                    ],
                  ),
                ),

                // Daftar Kendaraan
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _vehicles.length,
                    itemBuilder: (context, index) {
                      final v = _vehicles[index];
                      final isActive = v.id == _activeVehicleId;
                      return _buildVehicleCard(v, isActive);
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddVehicleSheet,
        backgroundColor: _accent,
        foregroundColor: _primary,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Kendaraan', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildVehicleCard(Vehicle v, bool isActive) {
    final isMotor = v.type == 'Motor';
    return Card(
      elevation: isActive ? 4 : 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isActive ? _accent : Colors.transparent,
          width: 2,
        ),
      ),
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _toggleActive(v.id),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Icon Tipe
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: isActive ? _accent.withValues(alpha: 0.15) : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isMotor ? Icons.motorcycle : Icons.directions_car,
                  color: isActive ? _accent : _primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),

              // Detail Teks
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          v.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _primary),
                        ),
                        const SizedBox(width: 8),
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'AKTIF',
                              style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          )
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      v.plateNumber,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.speed, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${v.odometerKm.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')} KM',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    )
                  ],
                ),
              ),

              // Hapus
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => _deleteVehicle(v.id, v.name),
              )
            ],
          ),
        ),
      ),
    );
  }
}
