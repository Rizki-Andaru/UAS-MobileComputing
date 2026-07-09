import 'package:flutter/material.dart';

class DetailScreen extends StatefulWidget {
  final int initialTab;

  const DetailScreen({super.key, this.initialTab = 0});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  // State untuk Simulasi Kamera AI
  bool _isAnalyzing = false;
  double _analysisProgress = 0.0;
  bool _hasResult = false;
  String _detectedComponent = "";
  String _aiAdvice = "";
  double _aiConfidence = 0.0;
  String _aiStatus = "";
  Color _aiStatusColor = Colors.green;

  // Animasi Laser Scanner
  late AnimationController _scannerController;
  late Animation<double> _scannerAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2, 
      vsync: this, 
      initialIndex: widget.initialTab,
    );

    // Inisialisasi Animasi Laser Scanner
    _scannerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scannerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scannerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  // Menjalankan simulasi analisis kamera
  void _startAnalysis() {
    setState(() {
      _isAnalyzing = true;
      _analysisProgress = 0.0;
      _hasResult = false;
    });

    // Simulasikan progress counter bertahap
    const totalSteps = 10;
    const stepDuration = Duration(milliseconds: 250);
    
    int currentStep = 0;
    
    void updateStep() {
      Future.delayed(stepDuration, () {
        if (!mounted) return;
        currentStep++;
        setState(() {
          _analysisProgress = currentStep / totalSteps;
        });

        if (currentStep < totalSteps) {
          updateStep();
        } else {
          // Analisis selesai, hasilkan rekomendasi acak yang sangat realistis!
          final listDiagnostics = [
            {
              "component": "Aki (Battery) - Panasonic NS60",
              "status": "Lemah / Perlu Cas",
              "color": const Color(0xFFF59E0B),
              "confidence": 0.982,
              "advice": "1. Tegangan aki terdeteksi 11.8V (di bawah ideal 12.6V).\n2. Terlihat ada tumpukan garam sulfasi putih pada terminal positif.\n3. Bersihkan terminal aki dengan air hangat dan sikat kawat.\n4. Lakukan pengisian daya (charging) lambat, atau ganti aki baru jika sudah berumur > 2 tahun."
            },
            {
              "component": "Ban Depan Kanan (Tire) - Bridgestone Ecopia",
              "status": "Tekanan Kurang",
              "color": const Color(0xFFEF4444),
              "confidence": 0.947,
              "advice": "1. Profil ban terdeteksi sedikit kempis (sekitar 26 PSI, ideal 32 PSI).\n2. Kedalaman alur ban masih tebal (6.2 mm), aman dari keausan gundul.\n3. Segera isi angin ban ke bengkel terdekat atau SPBU terdekat.\n4. Cek apakah terdapat paku atau kebocoran halus pada permukaan ban."
            },
            {
              "component": "Ruang Mesin (Engine Block) - Honda i-VTEC",
              "status": "Sangat Baik (Aman)",
              "color": const Color(0xFF10B981),
              "confidence": 0.915,
              "advice": "1. Secara visual, tidak terdeteksi adanya kebocoran oli atau cairan pendingin aktif.\n2. Suara getaran katup normal tanpa bunyi mengetuk (knocking).\n3. Ketinggian oli mesin terperiksa pada dipstick berada di batas tengah (normal).\n4. Pertahankan kebersihan kap mesin agar tidak menyumbat sirkulasi udara."
            }
          ];

          // Ambil acak dari list
          final selected = (listDiagnostics..shuffle()).first;

          setState(() {
            _isAnalyzing = false;
            _hasResult = true;
            _detectedComponent = selected["component"] as String;
            _aiStatus = selected["status"] as String;
            _aiStatusColor = selected["color"] as Color;
            _aiConfidence = selected["confidence"] as double;
            _aiAdvice = selected["advice"] as String;
          });
        }
      });
    }

    updateStep();
  }

  void _resetScanner() {
    setState(() {
      _hasResult = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1E293B); 
    const Color backgroundColor = Color(0xFFF8FAFC); 

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Detail & Diagnostik AI',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amber,
          indicatorWeight: 3,
          tabs: const [
            Tab(
              icon: Icon(Icons.analytics_outlined),
              text: "Detail Perawatan",
            ),
            Tab(
              icon: Icon(Icons.photo_camera_outlined),
              text: "Kamera Diagnostik",
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: DETAIL PERAWATAN
          _buildDetailPerawatanTab(),

          // TAB 2: KAMERA DIAGNOSTIK AI
          _buildKameraTab(),
        ],
      ),
    );
  }

  // WIDGET TAB 1: DETAIL PERAWATAN
  Widget _buildDetailPerawatanTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ringkasan Status
            const Text(
              "Status Kesehatan Komponen",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 12),

            // Card Detail Aki
            _buildDeepHealthCard(
              title: "Aki (Battery)",
              status: "Perlu Cek (35%)",
              statusColor: const Color(0xFFF59E0B),
              progress: 0.35,
              details: "Tegangan terukur 11.8 Volt. Starter mesin terasa sedikit berat saat mesin dingin di pagi hari.",
              recommendations: [
                "Lakukan pengisian ulang (recharge/cas aki) secepatnya.",
                "Periksa kabel konektor terminal aki dari kerak putih / korosi.",
                "Disarankan ganti aki jika tegangan tidak naik setelah di-cas."
              ],
              icon: Icons.battery_alert,
            ),
            const SizedBox(height: 16),

            // Card Detail Rem
            _buildDeepHealthCard(
              title: "Sistem Rem (Brakes)",
              status: "Aman (85%)",
              statusColor: const Color(0xFF10B981),
              progress: 0.85,
              details: "Ketebalan kampas rem depan masih sekitar 8mm. Respons pengereman pakem dan tidak ada bunyi mencicit.",
              recommendations: [
                "Pertahankan kebersihan piringan cakram dari pasir/kerikil.",
                "Cek volume minyak rem di tabung reservoir setiap 5.000 KM."
              ],
              icon: Icons.sports_motorsports_outlined,
            ),
            const SizedBox(height: 16),

            // Card Detail Ban
            _buildDeepHealthCard(
              title: "Ban Kendaraan (Tires)",
              status: "Aman (70%)",
              statusColor: const Color(0xFF10B981),
              progress: 0.70,
              details: "Tekanan ban stabil di 32 PSI. Kedalaman alur ban masih di atas batas aman (TWI). Kembangan ban rata.",
              recommendations: [
                "Lakukan rotasi silang ban depan-belakang pada KM 70.000.",
                "Gunakan penutup pentil ban logam untuk mencegah kebocoran halus."
              ],
              icon: Icons.tire_repair,
            ),
            const SizedBox(height: 24),

            // Riwayat Timeline
            const Text(
              "Riwayat Pemeriksaan & Servis",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 12),
            _buildHistoryTimeline(),
          ],
        ),
      ),
    );
  }

  Widget _buildDeepHealthCard({
    required String title,
    required String status,
    required Color statusColor,
    required double progress,
    required String details,
    required List<String> recommendations,
    required IconData icon,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: statusColor, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              details,
              style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            const Text(
              "Tindakan Rekomendasi:",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 6),
            ...recommendations.map((rec) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("• ", style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 14)),
                  Expanded(
                    child: Text(
                      rec,
                      style: TextStyle(fontSize: 12.5, color: Colors.grey[700], height: 1.3),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTimeline() {
    final List<Map<String, String>> history = [
      {"date": "25 Mei 2026", "title": "Ganti Oli Mesin & Filter", "desc": "Menggunakan oli Shell Helix Ultra 5W-30 (4 Liter). Filter oli orisinal diganti. Kondisi mesin halus."},
      {"date": "10 Apr 2026", "title": "Pengecekan Rutin Berkala", "desc": "Pembersihan filter udara, pengisian air wiper, pemeriksaan rem (kampas tebal 9mm). Semua kelistrikan normal."},
      {"date": "15 Jan 2026", "title": "Penggantian Aki Baru", "desc": "Aki diganti tipe basah GS Astra. Tegangan awal 12.7V. Garansi 6 bulan berlaku."},
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kolom Garis Timeline
            Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: index == 0 ? Colors.amber : const Color(0xFF64748B),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                ),
                if (index != history.length - 1)
                  Container(
                    width: 2,
                    height: 100,
                    color: const Color(0xFFCBD5E1),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Kolom Konten
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item["date"]!,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item["title"]!,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item["desc"]!,
                      style: TextStyle(fontSize: 12.5, color: Colors.grey[600], height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // WIDGET TAB 2: KAMERA DIAGNOSTIK AI (SIMULATOR PENUH)
  Widget _buildKameraTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_hasResult && !_isAnalyzing) ...[
              // Tampilan Frame Viewfinder Kamera
              AspectRatio(
                aspectRatio: 4 / 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
                  ),
                  child: Stack(
                    children: [
                      // Background Berwarna Gradasi Gelap Mensimulasikan Kamera di Garasi/Mesin
                      Center(
                        child: Opacity(
                          opacity: 0.3,
                          child: Image.network(
                            'https://images.unsplash.com/photo-1486006920555-c77dce18193b?q=80&w=600&auto=format&fit=crop',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.directions_car, size: 100, color: Colors.white24);
                            },
                          ),
                        ),
                      ),
                      // Overlay Bingkai Pemindai (Reticle)
                      _buildCameraScannerOverlay(),
                      
                      // Petunjuk Teks di atas Viewfinder
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.info_outline, color: Colors.amber, size: 16),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Posisikan mesin/aki/ban di dalam kotak kuning",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Animasi Laser Bergerak Naik Turun
                      AnimatedBuilder(
                        animation: _scannerAnimation,
                        builder: (context, child) {
                          return Positioned(
                            top: 40 + (_scannerAnimation.value * 180),
                            left: 20,
                            right: 20,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber.withValues(alpha: 0.8),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Tombol Ambil Foto & Analisis
              const Text(
                "Pindai Komponen Mobil dengan AI",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 8),
              Text(
                "Gunakan kamera ponsel untuk mengambil foto mesin, ban, aki, atau bagian rem. AutoCare+ AI akan mengidentifikasi jenis komponen serta menganalisis tanda-tanda kerusakan secara otomatis.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
              ),
              const SizedBox(height: 30),

              Center(
                child: GestureDetector(
                  onTap: _startAnalysis,
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF1E293B), width: 4),
                      color: Colors.transparent,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.amber,
                        ),
                        child: const Icon(Icons.photo_camera, size: 36, color: Color(0xFF1E293B)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "TAP UNTUK PINDAI",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), letterSpacing: 1.5),
              ),
            ] else if (_isAnalyzing) ...[
              // Tampilan Animasi Loading Analisis AI
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                  child: Column(
                    children: [
                      const SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          strokeWidth: 6,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                          backgroundColor: Color(0xFFE2E8F0),
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        "Sedang Memindai & Menganalisis",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Mengekstrak fitur visual... ${(100 * _analysisProgress).round()}%",
                        style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _analysisProgress,
                          minHeight: 10,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "AutoCare+ AI sedang mencocokkan pola keausan komponen dengan database kerusakan otomotif kami.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (_hasResult) ...[
              // Tampilan Kartu Hasil Analisis AI
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Hasil
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E293B),
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.psychology, color: Colors.amber, size: 28),
                          SizedBox(width: 12),
                          Text(
                            "Hasil Diagnostik AI",
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    // Badan Konten Hasil
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Baris Komponen Terdeteksi
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Komponen Teridentifikasi:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    const SizedBox(height: 4),
                                    Text(_detectedComponent, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _aiStatusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _aiStatus.toUpperCase(),
                                  style: TextStyle(color: _aiStatusColor, fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Akurasi Analisis
                          Row(
                            children: [
                              const Icon(Icons.verified_user, color: Colors.blue, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                "Tingkat Keyakinan AI: ${(_aiConfidence * 100).toStringAsFixed(1)}%",
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blue),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 12),

                          // Saran AI
                          const Text(
                            "Rekomendasi Tindakan & Analisis:",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _aiAdvice,
                            style: TextStyle(fontSize: 13, color: Colors.grey[800], height: 1.5, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 24),

                          // Tombol Aksi
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFF1E293B), width: 1.5),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  icon: const Icon(Icons.refresh, color: Color(0xFF1E293B)),
                                  label: const Text("Pindai Ulang", style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
                                  onPressed: _resetScanner,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                    foregroundColor: const Color(0xFF1E293B),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    elevation: 2,
                                  ),
                                  icon: const Icon(Icons.bookmark_add),
                                  label: const Text("Simpan Hasil", style: TextStyle(fontWeight: FontWeight.bold)),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Hasil pemeriksaan AI disimpan ke dalam riwayat medis mobil Anda!"),
                                        backgroundColor: Color(0xFF10B981),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    _resetScanner();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Desain Frame Kotak Viewfinder
  Widget _buildCameraScannerOverlay() {
    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: CustomPaint(
          painter: ScannerOverlayPainter(),
        ),
      ),
    );
  }
}

// Custom Painter untuk Menggambar Bingkai Siku Kamera yang Estetik
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.amber
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    const cornerLength = 24.0;

    // Siku Kiri Atas
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLength, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, cornerLength), paint);

    // Siku Kanan Atas
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - cornerLength, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLength), paint);

    // Siku Kiri Bawah
    canvas.drawLine(Offset(0, size.height), Offset(cornerLength, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - cornerLength), paint);

    // Siku Kanan Bawah
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - cornerLength, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
