class MaintenanceLogicEngine {
  // Batas Maksimal Penggunaan Komponen (KM)
  static const int maxUmurAki = 20000;
  static const int maxUmurOli = 5000;
  static const int maxUmurBan = 40000;

  static Map<String, dynamic> calculateHealth(int currentMileage, int lastServiceAki, int lastServiceOli, int lastServiceBan) {
    // Menghitung Sisa KM untuk setiap komponen
    int sisaAki = maxUmurAki - (currentMileage - lastServiceAki);
    int sisaOli = maxUmurOli - (currentMileage - lastServiceOli);
    int sisaBan = maxUmurBan - (currentMileage - lastServiceBan);

    // Menghitung Persentase RUL (Remaining Useful Life)
    double persenAki = (sisaAki / maxUmurAki).clamp(0.0, 1.0);
    double persenOli = (sisaOli / maxUmurOli).clamp(0.0, 1.0);
    double persenBan = (sisaBan / maxUmurBan).clamp(0.0, 1.0);

    // Status Alert (Threshold 20%)
    bool perluCekAki = persenAki <= 0.2;
    bool perluCekOli = persenOli <= 0.2;
    bool perluCekBan = persenBan <= 0.2;

    return {
      'aki': {'persen': persenAki, 'perluCek': perluCekAki},
      'oli': {'persen': persenOli, 'perluCek': perluCekOli},
      'ban': {'persen': persenBan, 'perluCek': perluCekBan},
      'statusKeseluruhan': (perluCekAki || perluCekOli || perluCekBan) ? 'Perlu Cek' : 'Aman',
    };
  }
}
