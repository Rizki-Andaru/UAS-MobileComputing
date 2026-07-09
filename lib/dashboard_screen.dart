import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'service_input_screen.dart';
import 'service_history_screen.dart';
import 'ai_consultant_screen.dart';

/// ==========================================
/// MAIN DASHBOARD SCREEN (AutoCare+)
/// ==========================================
class DashboardScreen extends StatefulWidget {
  final Function(int)? onTabChanged;
  const DashboardScreen({super.key, this.onTabChanged});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1E293B);
    const Color backgroundColor = Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('AutoCare+', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.logout,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<String>(
              future: SharedPreferences.getInstance().then((prefs) => prefs.getString('user_name') ?? "Rizki Andaru"),
              builder: (context, snapshot) {
                final name = snapshot.data ?? "Rizki Andaru";
                return CustomHeaderWidget(userName: name);
              },
            ),
            const SizedBox(height: 24),

            // ─── 2 Quick Action Buttons ───────────────────────
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(
                          Icons.build,
                          color: Color(0xFF475569),
                          size: 36,
                        ),
                        Positioned(
                          top: -4,
                          left: -4,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_circle,
                              color: Color(0xFF475569),
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    title: 'Last Service',
                    subtitle: 'INPUT SERVIS TERAKHIR',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ServiceInputScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: const Icon(
                      Icons.calendar_month,
                      color: Color(0xFF475569),
                      size: 36,
                    ),
                    title: 'History',
                    subtitle: 'RIWAYAT SERVIS',
                    onTap: () {
                      if (widget.onTabChanged != null) {
                        widget.onTabChanged!(2); // Pindah ke Tab 2 (Jadwal Servis)
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ServiceHistoryScreen()),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ─── AI Consult Action (Banner Style) ──────────────
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B), // Dark navy matching header
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // Faint biology/psychology head with gear icon on the bottom right
                  Positioned(
                    right: -10,
                    bottom: -15,
                    child: Icon(
                      Icons.psychology,
                      size: 90,
                      color: Colors.white.withAlpha(20),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ada Keluhan Mesin?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Tanyakan ke AutoCare+ AI untuk analisis troubleshoot instan.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AiConsultantScreen()),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFBBF24), // Yellow/amber color
                            foregroundColor: const Color(0xFF1E293B), // Navy/black text
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.chat_bubble_outline, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Konsultasi AI Sekarang',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// Kartu aksi cepat di dashboard
class _QuickActionCard extends StatelessWidget {
  final Widget icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), // Light greyish background matching image
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)), // Subtle border
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 48,
                  child: Center(child: icon),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5,
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

/// ==========================================
/// 1. WIDGET: HEADER PROFIL SANGAT SEDERHANA
/// ==========================================
class CustomHeaderWidget extends StatelessWidget {
  final String userName;

  const CustomHeaderWidget({
    super.key,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Halo, $userName",
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Selamat datang kembali di AutoCare+",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
