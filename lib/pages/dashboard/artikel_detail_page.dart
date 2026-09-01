import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart'; // 👈 Tambahkan import ini
import '../../models/artikel_model.dart';

class ArtikelDetailPage extends StatelessWidget {
  final ArtikelModel artikel;

  const ArtikelDetailPage({super.key, required this.artikel});

  static const _green = Color(0xFF1AB673);
  static const _textDark = Color(
    0xFF1F2937,
  ); // Sesuaikan dengan warna teks admin (#1f2937)

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // ── Hero Image AppBar ──
          SliverAppBar(
            expandedHeight: 260,
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
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    artikel.gambar,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 48,
                        color: Colors.grey,
                      ),
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
                  if (artikel.isFeatured)
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '⭐ UNGGULAN',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 10,
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
                  // Kategori badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _green.withOpacity(0.3)),
                    ),
                    child: Text(
                      artikel.kategori,
                      style: GoogleFonts.poppins(
                        color: _green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Title
                  Text(
                    artikel.judul,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                      color: _textDark,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Meta info
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _green.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              artikel.penulis.isNotEmpty
                                  ? artikel.penulis[0].toUpperCase()
                                  : 'A',
                              style: GoogleFonts.poppins(
                                color: _green,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                artikel.penulis,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: _textDark,
                                ),
                              ),
                              Text(
                                _formatDate(artikel.createdAt),
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.visibility_outlined,
                                size: 14,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${artikel.dibaca}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Container(height: 1, color: Colors.grey[200]),
                  const SizedBox(height: 24),

                  // ── ISI KONTEN HTML (Sudah disesuaikan dengan Web Admin) ──
                  HtmlWidget(
                    artikel.isi,
                    textStyle: GoogleFonts.poppins(
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.7,
                    ),
                    customStylesBuilder: (element) {
                      // Custom styling h1, h2, h3 mirip global.css web admin
                      if (element.localName == 'h1') {
                        return {
                          'font-size': '22px',
                          'font-weight': '800',
                          'margin': '16px 0 8px 0',
                          'color': '#111827',
                        };
                      }
                      if (element.localName == 'h2') {
                        return {
                          'font-size': '18px',
                          'font-weight': '700',
                          'margin': '14px 0 8px 0',
                          'color': '#1F2937',
                        };
                      }
                      if (element.localName == 'h3') {
                        return {
                          'font-size': '16px',
                          'font-weight': '700',
                          'margin': '12px 0 6px 0',
                          'color': '#374151',
                        };
                      }
                      // Styling untuk blockquote kutipan teks
                      if (element.localName == 'blockquote') {
                        return {
                          'border-left': '3px solid #1AB673',
                          'padding-left': '12px',
                          'color': '#6B7280',
                          'font-style': 'italic',
                          'margin': '12px 0',
                        };
                      }
                      // Styling untuk link a href
                      if (element.localName == 'a') {
                        return {
                          'color': '#1AB673',
                          'text-decoration': 'underline',
                        };
                      }
                      return null;
                    },
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
}
