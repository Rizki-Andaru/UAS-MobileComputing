import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_navigation.dart';
import 'vehicle_management_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoginMode = true;
  bool _obscurePassword = true;
  bool _isLoading = false;

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _vehicleController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _vehicleController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _formKey.currentState?.reset();
    });
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simpan data ke SharedPreferences secara asinkron
      final prefs = await SharedPreferences.getInstance();
      if (!_isLoginMode) {
        // Mode Daftar
        final name = _nameController.text.trim();
        final email = _emailController.text.trim();
        await prefs.setString('user_name', name);
        await prefs.setString('user_email', email);

        // Tambah kendaraan pertama ke garasi jika diisi
        final vehicleName = _vehicleController.text.trim();
        if (vehicleName.isNotEmpty) {
          final newVehicle = Vehicle(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: vehicleName,
            plateNumber: 'D 9999 REG',
            odometerKm: 10000, // Default KM awal untuk demo
            type: 'Mobil',
          );
          await VehicleStorage.add(newVehicle);
          await VehicleStorage.setActiveId(newVehicle.id);
        }
      } else {
        // Mode Masuk: pastikan ada user_name default jika belum ada data sebelumnya
        if (prefs.getString('user_name') == null) {
          final emailOrUser = _emailController.text.trim();
          final name = emailOrUser.contains('@') ? emailOrUser.split('@').first : emailOrUser;
          // Kapitalisasi huruf pertama nama
          final formattedName = name.isNotEmpty 
              ? '${name[0].toUpperCase()}${name.substring(1)}' 
              : "Rizki Andaru";
          await prefs.setString('user_name', formattedName);
        }
      }

      // Simulasikan autentikasi/pendaftaran selama 1.5 detik
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });

        // Tampilkan pesan sukses singkat
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isLoginMode 
                ? "Selamat datang kembali di AutoCare+!" 
                : "Akun berhasil dibuat! Selamat datang di AutoCare+."
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigasi ke MainNavigationScreen dengan animasi slide up yang halus
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const MainNavigationScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.easeInOutCubic;

              var drawAnim = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

              return SlideTransition(
                position: animation.drive(drawAnim),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1E293B); // Charcoal / Deep Blue
    const Color accentColor = Colors.amber;       // Amber accent for highlights

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo & Branding
                      const Icon(
                        Icons.build_circle_outlined,
                        size: 80,
                        color: accentColor,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "AutoCare+",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isLoginMode 
                            ? "Asisten kesehatan & perawatan mobil pintar Anda"
                            : "Daftar sekarang untuk analisis mobil berbasis AI",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Input Fields Card
                      Card(
                        color: primaryColor.withValues(alpha: 0.85),
                        elevation: 8,
                        shadowColor: Colors.black45,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isLoginMode ? "MASUK" : "DAFTAR AKUN",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Form Field: Nama Lengkap (Hanya Register)
                              if (!_isLoginMode) ...[
                                TextFormField(
                                  controller: _nameController,
                                  style: const TextStyle(color: Colors.white),
                                  enabled: !_isLoading,
                                  decoration: InputDecoration(
                                    labelText: "Nama Lengkap",
                                    labelStyle: TextStyle(color: Colors.grey[400]),
                                    prefixIcon: const Icon(Icons.person_outline, color: accentColor),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: Colors.grey[700]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: accentColor),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Colors.redAccent),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Colors.redAccent),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return "Nama tidak boleh kosong";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Form Field: Email / Username
                              TextFormField(
                                controller: _emailController,
                                style: const TextStyle(color: Colors.white),
                                enabled: !_isLoading,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: "Email atau Username",
                                  labelStyle: TextStyle(color: Colors.grey[400]),
                                  prefixIcon: const Icon(Icons.mail_outline, color: accentColor),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.grey[700]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: accentColor),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Colors.redAccent),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Colors.redAccent),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return "Email / Username tidak boleh kosong";
                                  }
                                  if (value.contains('@') && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                    return "Masukkan format email yang valid";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Form Field: Merek & Tipe Kendaraan (Hanya Register)
                              if (!_isLoginMode) ...[
                                TextFormField(
                                  controller: _vehicleController,
                                  style: const TextStyle(color: Colors.white),
                                  enabled: !_isLoading,
                                  decoration: InputDecoration(
                                    labelText: "Kendaraan (Contoh: Honda Civic 2022)",
                                    labelStyle: TextStyle(color: Colors.grey[400]),
                                    prefixIcon: const Icon(Icons.directions_car_outlined, color: accentColor),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: Colors.grey[700]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: accentColor),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Colors.redAccent),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Colors.redAccent),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return "Detail kendaraan tidak boleh kosong";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Form Field: Password
                              TextFormField(
                                controller: _passwordController,
                                style: const TextStyle(color: Colors.white),
                                enabled: !_isLoading,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: "Kata Sandi",
                                  labelStyle: TextStyle(color: Colors.grey[400]),
                                  prefixIcon: const Icon(Icons.lock_outline, color: accentColor),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                      color: Colors.grey[400],
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.grey[700]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: accentColor),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Colors.redAccent),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Colors.redAccent),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Kata sandi tidak boleh kosong";
                                  }
                                  if (value.length < 6) {
                                    return "Kata sandi minimal berisi 6 karakter";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              // Submit Button
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: accentColor,
                                    foregroundColor: const Color(0xFF0F172A),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 4,
                                  ),
                                  onPressed: _isLoading ? null : _submitForm,
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F172A)),
                                          ),
                                        )
                                      : Text(
                                          _isLoginMode ? "MASUK" : "DAFTAR",
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Toggle Login/Register Mode
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isLoginMode 
                                ? "Belum punya akun? " 
                                : "Sudah memiliki akun? ",
                            style: const TextStyle(color: Colors.white70),
                          ),
                          GestureDetector(
                            onTap: _isLoading ? null : _toggleMode,
                            child: Text(
                              _isLoginMode ? "Daftar di sini" : "Masuk di sini",
                              style: const TextStyle(
                                color: accentColor,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
