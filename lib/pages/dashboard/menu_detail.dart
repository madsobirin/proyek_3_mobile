import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MenuDetailPage extends StatelessWidget {
  final Map<String, dynamic> menu;

  const MenuDetailPage({super.key, required this.menu});

  static const _green = Color(0xFF1AB673);

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Kurus':
        return Colors.blue;
      case 'Normal':
        return _green;
      case 'Berlebih':
        return Colors.orange;
      case 'Obesitas':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(menu['target_status'] ?? '');

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // ── Hero Image AppBar ──
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.white,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new,
                      size: 18, color: Colors.white),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (menu['gambar'] != null)
                    Image.network(
                      menu['gambar'],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported,
                            size: 48, color: Colors.grey),
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.5),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  // Status badge
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        menu['target_status'] ?? '',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Content ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    menu['nama_menu'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Info Row
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _infoItem(
                          Icons.local_fire_department,
                          '${menu['kalori'] ?? 0} kal',
                          Colors.orange,
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.grey[200],
                        ),
                        _infoItem(
                          Icons.access_time,
                          '${menu['waktu_memasak'] ?? 0} menit',
                          Colors.blue,
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.grey[200],
                        ),
                        _infoItem(
                          Icons.visibility_outlined,
                          '${menu['dibaca'] ?? 0} views',
                          _green,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Divider
                  Container(height: 1, color: Colors.grey[200]),

                  const SizedBox(height: 24),

                  // Description
                  Text(
                    'Deskripsi',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    menu['deskripsi'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.7,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Cara Membuat
                  Text(
                    'Cara Membuat',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Ikuti langkah-langkah sehat untuk menyajikan menu ini. Pastikan bahan yang digunakan segar dan porsi sesuai dengan kebutuhan kalori harian Anda.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.7,
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String label, Color color) {
    return Column(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}