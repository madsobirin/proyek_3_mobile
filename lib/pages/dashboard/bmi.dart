import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

class BmiPage extends StatefulWidget {
  final VoidCallback onBack;
  const BmiPage({super.key, required this.onBack});

  @override
  State<BmiPage> createState() => _BmiPageState();
}

class _BmiPageState extends State<BmiPage> {
  String gender = "Pria";
  double height = 170;
  double weight = 65;
  double? bmiResult;
  String kategori = "";

  void hitungBMI() {
    double tinggiMeter = height / 100;
    double bmi = weight / pow(tinggiMeter, 2);

    String hasilKategori;
    if (bmi < 18.5) {
      hasilKategori = "Berat Badan Rendah";
    } else if (bmi < 25) {
      hasilKategori = "Normal (Ideal)";
    } else if (bmi < 30) {
      hasilKategori = "Berlebih";
    } else {
      hasilKategori = "Obesitas";
    }

    setState(() {
      bmiResult = bmi;
      kategori = hasilKategori;
    });
  }

  Color kategoriColor() {
    if (bmiResult == null) return Colors.grey;
    if (bmiResult! < 18.5) return Colors.blue;
    if (bmiResult! < 25) return const Color(0xFF1AB673);
    if (bmiResult! < 30) return Colors.orange;
    return Colors.red;
  }

  String adviceText() {
    if (bmiResult == null) return "";
    if (bmiResult! < 18.5) {
      return "Perbanyak asupan kalori bernutrisi dan latihan beban rutin.";
    } else if (bmiResult! < 25) {
      return "Pertahankan pola makan seimbang dan gaya hidup aktif.";
    } else if (bmiResult! < 30) {
      return "Lakukan defisit kalori ringan dan olahraga kardio rutin.";
    } else {
      return "Disarankan konsultasi dengan ahli gizi untuk program sehat.";
    }
  }

  Widget modernCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget genderSelector(String label) {
    final isSelected = gender == label;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => gender = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF1AB673).withOpacity(0.12)
                : Colors.grey.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: isSelected ? const Color(0xFF1AB673) : Colors.black54,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: widget.onBack,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 18,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Kalkulator BMI",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          /// FORM CARD
          modernCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Jenis Kelamin",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    genderSelector("Pria"),
                    const SizedBox(width: 10),
                    genderSelector("Wanita"),
                  ],
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Tinggi"),
                    Text(
                      "${height.toInt()} cm",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Slider(
                  value: height,
                  min: 100,
                  max: 250,
                  activeColor: const Color(0xFF1AB673),
                  onChanged: (value) => setState(() => height = value),
                ),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Berat"),
                    Text(
                      "${weight.toInt()} kg",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Slider(
                  value: weight,
                  min: 30,
                  max: 200,
                  activeColor: const Color(0xFF1AB673),
                  onChanged: (value) => setState(() => weight = value),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: hitungBMI,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1AB673),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      "Hitung BMI",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          /// MINI INFO SEBELUM RESULT
          if (bmiResult == null)
            modernCard(
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF1AB673)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "BMI membantu mengetahui apakah berat badan Anda sudah ideal.",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          /// RESULT + ADVICE
          if (bmiResult != null) ...[
            const SizedBox(height: 20),

            modernCard(
              child: Column(
                children: [
                  /// ICON BULAT BESAR
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: kategoriColor().withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.insights,
                      size: 36,
                      color: kategoriColor(),
                    ),
                  ),

                  const SizedBox(height: 15),

                  /// ANGKA BMI
                  Text(
                    bmiResult!.toStringAsFixed(1),
                    style: GoogleFonts.poppins(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: kategoriColor(),
                    ),
                  ),

                  const SizedBox(height: 4),

                  /// KATEGORI
                  Text(
                    kategori,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: kategoriColor(),
                    ),
                  ),

                  const SizedBox(height: 15),

                  Divider(color: Colors.grey.shade200),

                  const SizedBox(height: 10),

                  /// HASIL ANALISIS TITLE
                  Row(
                    children: [
                      Icon(Icons.bar_chart, size: 18, color: kategoriColor()),
                      const SizedBox(width: 6),
                      Text(
                        "Hasil Analisis",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  /// ADVICE TEXT
                  Text(
                    adviceText(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
