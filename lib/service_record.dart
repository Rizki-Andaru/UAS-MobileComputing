import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────
// MODEL: ServiceRecord
// ─────────────────────────────────────────
class ServiceRecord {
  final String id;
  final String vehicleName;
  final String component;
  final DateTime serviceDate;
  final int odometerKm;
  final DateTime nextServiceDate;
  final int nextServiceKm;

  ServiceRecord({
    required this.id,
    required this.vehicleName,
    required this.component,
    required this.serviceDate,
    required this.odometerKm,
    required this.nextServiceDate,
    required this.nextServiceKm,
  });

  // Konversi ke/dari JSON untuk disimpan di SharedPreferences
  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicleName': vehicleName,
        'component': component,
        'serviceDate': serviceDate.toIso8601String(),
        'odometerKm': odometerKm,
        'nextServiceDate': nextServiceDate.toIso8601String(),
        'nextServiceKm': nextServiceKm,
      };

  factory ServiceRecord.fromJson(Map<String, dynamic> json) => ServiceRecord(
        id: json['id'],
        vehicleName: json['vehicleName'],
        component: json['component'],
        serviceDate: DateTime.parse(json['serviceDate']),
        odometerKm: json['odometerKm'],
        nextServiceDate: DateTime.parse(json['nextServiceDate']),
        nextServiceKm: json['nextServiceKm'],
      );

  // Buat salinan dengan field yang diubah (untuk edit)
  ServiceRecord copyWith({
    String? vehicleName,
    String? component,
    DateTime? serviceDate,
    int? odometerKm,
    DateTime? nextServiceDate,
    int? nextServiceKm,
  }) {
    return ServiceRecord(
      id: id,
      vehicleName: vehicleName ?? this.vehicleName,
      component: component ?? this.component,
      serviceDate: serviceDate ?? this.serviceDate,
      odometerKm: odometerKm ?? this.odometerKm,
      nextServiceDate: nextServiceDate ?? this.nextServiceDate,
      nextServiceKm: nextServiceKm ?? this.nextServiceKm,
    );
  }
}

// ─────────────────────────────────────────
// KONFIGURASI INTERVAL SERVIS PER KOMPONEN
// ─────────────────────────────────────────
class ServiceInterval {
  final int kmInterval;
  final int monthInterval;

  const ServiceInterval({required this.kmInterval, required this.monthInterval});
}

const Map<String, ServiceInterval> serviceIntervals = {
  'Ganti Oli Mesin': ServiceInterval(kmInterval: 5000, monthInterval: 3),
  'Servis Rutin': ServiceInterval(kmInterval: 7000, monthInterval: 6),
  'Servis Rem': ServiceInterval(kmInterval: 20000, monthInterval: 12),
  'Cek Aki': ServiceInterval(kmInterval: 15000, monthInterval: 12),
  'Ganti Ban': ServiceInterval(kmInterval: 40000, monthInterval: 24),
  'Ganti Filter Udara': ServiceInterval(kmInterval: 15000, monthInterval: 12),
  'Tune Up Mesin': ServiceInterval(kmInterval: 10000, monthInterval: 6),
  'Kuras Radiator': ServiceInterval(kmInterval: 20000, monthInterval: 12),
  'Lainnya': ServiceInterval(kmInterval: 10000, monthInterval: 6),
};

// List nama komponen untuk dropdown
final List<String> serviceComponents = serviceIntervals.keys.toList();

// Hitung jadwal servis berikutnya berdasarkan komponen
ServiceRecord calculateNextService({
  required String vehicleName,
  required String component,
  required DateTime serviceDate,
  required int odometerKm,
}) {
  final interval = serviceIntervals[component] ??
      const ServiceInterval(kmInterval: 10000, monthInterval: 6);

  final nextKm = odometerKm + interval.kmInterval;
  final nextDate = DateTime(
    serviceDate.year,
    serviceDate.month + interval.monthInterval,
    serviceDate.day,
  );

  return ServiceRecord(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    vehicleName: vehicleName,
    component: component,
    serviceDate: serviceDate,
    odometerKm: odometerKm,
    nextServiceDate: nextDate,
    nextServiceKm: nextKm,
  );
}

// ─────────────────────────────────────────
// STORAGE: Simpan & baca data dari SharedPreferences
// ─────────────────────────────────────────
class ServiceStorage {
  static const String _key = 'service_records';

  // Ambil semua riwayat servis
  static Future<List<ServiceRecord>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return [];
    final List<dynamic> decoded = jsonDecode(jsonString);
    return decoded.map((e) => ServiceRecord.fromJson(e)).toList();
  }

  // Simpan satu record baru
  static Future<void> save(ServiceRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getAll();
    records.add(record);
    await prefs.setString(_key, jsonEncode(records.map((r) => r.toJson()).toList()));
  }

  // Update record yang sudah ada (berdasarkan id)
  static Future<void> update(ServiceRecord updated) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getAll();
    final index = records.indexWhere((r) => r.id == updated.id);
    if (index != -1) records[index] = updated;
    await prefs.setString(_key, jsonEncode(records.map((r) => r.toJson()).toList()));
  }

  // Hapus record berdasarkan id
  static Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getAll();
    records.removeWhere((r) => r.id == id);
    await prefs.setString(_key, jsonEncode(records.map((r) => r.toJson()).toList()));
  }
}
