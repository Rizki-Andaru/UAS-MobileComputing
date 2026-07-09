import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// ==========================================
/// AI CONSULTANT SCREEN - AutoCare+ AI Chat
/// Powered by RAG (Gemini) + ML Classifier
/// ==========================================
class AiConsultantScreen extends StatefulWidget {
  const AiConsultantScreen({super.key});

  @override
  State<AiConsultantScreen> createState() => _AiConsultantScreenState();
}

class _AiConsultantScreenState extends State<AiConsultantScreen>
    with TickerProviderStateMixin {
  // ─── Controllers ───────────────────────
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _odometerController =
      TextEditingController(text: "60000");
  final TextEditingController _monthsController =
      TextEditingController(text: "1.0");
  final TextEditingController _dtcController =
      TextEditingController(text: "None");
  final ScrollController _scrollController = ScrollController();
  // URL backend — bisa diubah pengguna di panel pengaturan
  // Android emulator → 10.0.2.2  |  HP fisik/Web → IP LAN komputer
  late final TextEditingController _backendUrlController;

  // ─── State ─────────────────────────────
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _showSettings = false;
  bool _apiKeyVisible = false;
  bool _isTesting = false;
  String _connectionStatus = ""; // "", "ok", "error"

  @override
  void initState() {
    super.initState();
    // Default URL: emulator Android → 10.0.2.2, HP fisik harus set manual ke IP LAN
    String defaultUrl;
    if (kIsWeb) {
      defaultUrl = "http://127.0.0.1:5000";
    } else if (!kIsWeb && _isAndroid()) {
      defaultUrl = "http://10.0.2.2:5000";
    } else {
      defaultUrl = "http://127.0.0.1:5000";
    }
    _backendUrlController = TextEditingController(text: defaultUrl);
    _loadSavedSettings();
  }

  bool _isAndroid() {
    try {
      return Platform.isAndroid;
    } catch (_) {
      return false;
    }
  }

  String get _backendUrl => _backendUrlController.text.trim().isEmpty
      ? "http://10.0.2.2:5000"
      : _backendUrlController.text.trim();

  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKeyController.text = prefs.getString('google_api_key') ?? '';
      final savedUrl = prefs.getString('backend_url');
      if (savedUrl != null && savedUrl.isNotEmpty) {
        _backendUrlController.text = savedUrl;
      }
    });
    // Lakukan pengetesan koneksi saat pertama kali dibuka
    _testConnection();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('google_api_key', _apiKeyController.text.trim());
    await prefs.setString('backend_url', _backendUrlController.text.trim());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _apiKeyController.dispose();
    _odometerController.dispose();
    _monthsController.dispose();
    _dtcController.dispose();
    _backendUrlController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ─── Test koneksi ke backend ─────────────
  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _connectionStatus = "";
    });
    try {
      final response = await http
          .get(Uri.parse("$_backendUrl/health"))
          .timeout(const Duration(seconds: 5));
      setState(() {
        _connectionStatus = response.statusCode == 200 ? "ok" : "error";
      });
    } catch (_) {
      setState(() {
        _connectionStatus = "error";
      });
    } finally {
      setState(() => _isTesting = false);
    }
  }

  // ─── Kirim pesan ke backend ─────────────
  Future<void> _sendMessage() async {
    final userText = _messageController.text.trim();
    if (userText.isEmpty) return;

    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      _showSettingsPanel();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Masukkan Google API Key terlebih dahulu di panel pengaturan."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await _saveSettings();

    // Tambah pesan user ke chat
    setState(() {
      _messages.add(_ChatMessage(text: userText, isUser: true));
      _isLoading = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse("$_backendUrl/chat"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "message": userText,
          "api_key": apiKey,
          "odometer_km": double.tryParse(_odometerController.text) ?? 60000,
          "months_since_service": double.tryParse(_monthsController.text) ?? 1.0,
          "dtc_code": _dtcController.text.trim().isEmpty
              ? "None"
              : _dtcController.text.trim(),
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data["reply"] as String? ?? "Tidak ada respons.";
        final urgency = data["urgency"] as String? ?? "Unknown";
        final sources = (data["sources"] as List<dynamic>?)
                ?.map((s) => "${s['file']} hal.${s['page']}")
                .toList() ??
            [];

        setState(() {
          _messages.add(_ChatMessage(
            text: reply,
            isUser: false,
            urgency: urgency,
            sources: sources,
          ));
        });
      } else {
        final errorData = jsonDecode(response.body);
        final errorMsg = errorData["error"] ?? "Terjadi kesalahan pada server.";
        setState(() {
          _messages.add(_ChatMessage(
            text: "❌ Error: $errorMsg",
            isUser: false,
            isError: true,
          ));
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(
          text:
              "❌ Tidak dapat terhubung ke server AI.\n\nPastikan:\n• Backend Flask sudah berjalan (`python api_server.py`)\n• URL backend sudah benar di kode\n\nDetail: $e",
          isUser: false,
          isError: true,
        ));
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSettingsPanel() {
    setState(() => _showSettings = true);
  }

  void _clearChat() {
    setState(() => _messages.clear());
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1E293B);
    const Color accentColor = Color(0xFFF59E0B);
    const Color bgColor = Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "AutoCare+",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  "AI Konsultan Chat",
                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                ),
              ],
            )
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.tune,
              color: _showSettings ? accentColor : Colors.white,
            ),
            tooltip: "Pengaturan AI",
            onPressed: () => setState(() => _showSettings = !_showSettings),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            tooltip: "Hapus Chat",
            onPressed: _clearChat,
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Panel Pengaturan (collapsible) ───
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _showSettings ? _buildSettingsPanel(accentColor) : const SizedBox.shrink(),
          ),

          // ─── Header Info di Body ───
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Konsultasi Masalah Kendaraan",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Tanyakan langsung keluhan mesin Anda pada Asisten AI AutoCare+",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ─── Chat Area ─────────────────────────
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState(accentColor)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isLoading) {
                        return _buildTypingIndicator();
                      }
                      return _buildChatBubble(_messages[index]);
                    },
                  ),
          ),

          // ─── Input Bar ─────────────────────────
          _buildInputBar(primaryColor, accentColor),
        ],
      ),
    );
  }

  // ─── Settings Panel ─────────────────────────
  Widget _buildSettingsPanel(Color accentColor) {
    return Container(
      color: const Color(0xFF1E293B),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      constraints: const BoxConstraints(maxHeight: 250), // Prevent excessive height expansion
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings, color: Colors.amber, size: 16),
                const SizedBox(width: 8),
                const Text(
                  "Pengaturan AI",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _showSettings = false),
                  child: const Icon(Icons.close, color: Colors.white54, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ─── URL Backend Server ───────────────
            Row(
              children: [
                const Text("URL Backend Server:",
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                const Spacer(),
                if (_connectionStatus == "ok")
                  const Row(children: [
                    Icon(Icons.wifi, color: Color(0xFF10B981), size: 13),
                    SizedBox(width: 4),
                    Text("Terhubung", style: TextStyle(color: Color(0xFF10B981), fontSize: 11)),
                  ])
                else if (_connectionStatus == "error")
                  const Row(children: [
                    Icon(Icons.wifi_off, color: Color(0xFFEF4444), size: 13),
                    SizedBox(width: 4),
                    Text("Gagal", style: TextStyle(color: Color(0xFFEF4444), fontSize: 11)),
                  ]),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _backendUrlController,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      hintText: "http://10.0.2.2:5000",
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                      prefixIcon: const Icon(Icons.dns_outlined, color: Colors.white54, size: 16),
                      filled: true,
                      fillColor: const Color(0xFF334155),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    onPressed: _isTesting ? null : _testConnection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0EA5E9),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: _isTesting
                        ? const SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text("Test", style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
            // Petunjuk URL untuk HP fisik
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF0EA5E9).withValues(alpha: 0.24)),
              ),
              child: const Text(
                "💡 HP fisik: ganti URL ke http://IP_KOMPUTER:5000\n"
                "   Contoh: http://172.20.28.87:5000\n"
                "   Emulator Android: http://10.0.2.2:5000",
                style: TextStyle(color: Color(0xFF7DD3FC), fontSize: 10.5, height: 1.5),
              ),
            ),
            const SizedBox(height: 12),

            // API Key Field
            const Text("Google API Key:",
                style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: _apiKeyController,
              obscureText: !_apiKeyVisible,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: "Masukkan Google API Key...",
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF334155),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                suffixIcon: IconButton(
                  icon: Icon(
                    _apiKeyVisible ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white54,
                    size: 18,
                  ),
                  onPressed: () =>
                      setState(() => _apiKeyVisible = !_apiKeyVisible),
                ),
              ),
            ),
            const SizedBox(height: 12),

            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _saveSettings();
                  setState(() => _showSettings = false);
                },
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: const Text("Simpan & Tutup"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Empty State ─────────────────────────────
  Widget _buildEmptyState(Color accentColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 300;
        return SingleChildScrollView(
          padding: EdgeInsets.all(isCompact ? 16.0 : 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isCompact) ...[
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E293B), Color(0xFF334155)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.psychology, size: 38, color: Colors.amber),
                ),
                const SizedBox(height: 16),
              ],
              const Text(
                "AutoCare+ AI Siap Membantu",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B)),
                textAlign: TextAlign.center,
              ),
              if (!isCompact) ...[
                const SizedBox(height: 8),
                Text(
                  "Ceritakan keluhan kendaraanmu. AI akan menganalisis berdasarkan riwayat servis & dokumen teknis resmi.",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    "Mesin berisik saat start",
                    "Aki sering tekor",
                    "Rem berdecit",
                    "Kapan ganti oli?",
                  ]
                      .map((s) => GestureDetector(
                            onTap: () => _messageController.text = s,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B).withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: const Color(0xFF334155).withValues(alpha: 0.24)),
                              ),
                              child: Text(s,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF334155))),
                            ),
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _showSettingsPanel,
                icon: const Icon(Icons.vpn_key_outlined, size: 14),
                label: const Text("Set API Key"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Chat Bubble ─────────────────────────────
  Widget _buildChatBubble(_ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!msg.isUser) ...[
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF475569)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.psychology, size: 18, color: Colors.amber),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Urgency Badge (hanya untuk pesan AI)
                if (!msg.isUser && msg.urgency != null && msg.urgency != "Unknown")
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _buildUrgencyBadge(msg.urgency!),
                  ),

                // Bubble
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: msg.isUser
                        ? const LinearGradient(
                            colors: [Color(0xFF334155), Color(0xFF1E293B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: !msg.isUser
                        ? (msg.isError ? const Color(0xFFFEF2F2) : Colors.white)
                        : null,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(msg.isUser ? 20 : 6),
                      bottomRight: Radius.circular(msg.isUser ? 6 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: msg.isError
                        ? Border.all(color: const Color(0xFFFCA5A5))
                        : (!msg.isUser
                            ? Border.all(color: Colors.grey.withValues(alpha: 0.1))
                            : null),
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      color: msg.isUser
                          ? Colors.white
                          : msg.isError
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF334155),
                      fontSize: 14.5,
                      height: 1.5,
                    ),
                  ),
                ),

                // Sources
                if (!msg.isUser &&
                    msg.sources != null &&
                    msg.sources!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: GestureDetector(
                      onTap: () => _showSourcesDialog(msg.sources!),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.source_outlined,
                              size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            "${msg.sources!.length} sumber referensi",
                            style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                decoration: TextDecoration.underline),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (msg.isUser) ...[
            const SizedBox(width: 10),
            const CircleAvatar(
              radius: 17,
              backgroundColor: Color(0xFFF59E0B),
              child: Text(
                "R",
                style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUrgencyBadge(String urgency) {
    Color bgColor, textColor, borderColor;
    IconData icon;
    String label;

    switch (urgency.toLowerCase()) {
      case "high":
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFF991B1B);
        borderColor = const Color(0xFFFCA5A5);
        icon = Icons.warning_amber_rounded;
        label = "🔴 Urgensi: HIGH — Segera periksa!";
        break;
      case "medium":
        bgColor = const Color(0xFFFFFBEB);
        textColor = const Color(0xFF92400E);
        borderColor = const Color(0xFFFDE68A);
        icon = Icons.info_outline;
        label = "🟡 Urgensi: MEDIUM — Perlu perhatian";
        break;
      default:
        bgColor = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF065F46);
        borderColor = const Color(0xFF6EE7B7);
        icon = Icons.check_circle_outline;
        label = "🟢 Urgensi: LOW — Aman dikendarai";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: textColor,
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ─── Typing Indicator ─────────────────────────
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF475569)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.psychology, size: 18, color: Colors.amber),
          ),
          const SizedBox(width: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 2))
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (i) => _DotIndicator(delay: Duration(milliseconds: i * 200)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Input Bar ──────────────────────────────
  Widget _buildInputBar(Color primaryColor, Color accentColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -3))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.newline,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
              decoration: InputDecoration(
                hintText: "Ceritakan keluhan kendaraanmu...",
                hintStyle:
                    TextStyle(color: Colors.grey[400], fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _isLoading ? null : _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _isLoading ? Colors.grey[300] : accentColor,
                shape: BoxShape.circle,
                boxShadow: _isLoading
                    ? []
                    : [
                        BoxShadow(
                            color: accentColor.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3))
                      ],
              ),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded,
                      color: Color(0xFF1E293B), size: 22),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Sources Dialog ─────────────────────────
  void _showSourcesDialog(List<String> sources) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Sumber Referensi",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: sources
              .map((s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.description_outlined,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(s,
                                style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Tutup"),
          )
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

// ─── Dot Indicator untuk Typing ──────────────
class _DotIndicator extends StatefulWidget {
  final Duration delay;
  const _DotIndicator({required this.delay});

  @override
  State<_DotIndicator> createState() => _DotIndicatorState();
}

class _DotIndicatorState extends State<_DotIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _animation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 6,
          height: 6,
          transform: Matrix4.translationValues(0, -_animation.value, 0),
          decoration: const BoxDecoration(
            color: Color(0xFF94A3B8),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final String? urgency;
  final List<String>? sources;
  final bool isError;

  _ChatMessage({
    required this.text,
    required this.isUser,
    this.urgency,
    this.sources,
    this.isError = false,
  });
}
