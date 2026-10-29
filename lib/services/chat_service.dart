import 'api_service.dart';

class ChatService {
  final ApiService _api = ApiService();

  static const String formatInstruction =
      '\n\n[ATURAN FORMAT OUTPUT:\n'
      '1. JANGAN PERNAH menggunakan sintaks Markdown apa pun dalam jawabanmu.\n'
      '2. Dilarang keras menggunakan tanda bintang ganda (**) untuk menebalkan kata.\n'
      '3. Dilarang menggunakan tanda pagar (#) untuk heading.\n'
      '4. Gunakan huruf kapital (ALL CAPS) secukupnya hanya jika ingin memberi penekanan pada kata penting.\n'
      '5. Untuk membuat daftar urutan, gunakan angka standar (1., 2., 3.) atau strip (-), bukan karakter bintang (*).\n'
      '6. Berikan jawaban dalam bentuk teks polos (plain text) yang langsung nyaman dibaca di layar aplikasi mobile.]';

  /// Membersihkan teks dari sintaks Markdown agar selalu tampil bersih sebagai teks polos di ponsel.
  static String formatPlainText(String raw) {
    if (raw.isEmpty) return raw;
    String text = raw;

    // 1. Hapus code blocks ```...```
    text = text.replaceAllMapped(
      RegExp(r'```(?:[a-zA-Z]*\n)?([\s\S]*?)```'),
      (m) => m[1]?.trim() ?? '',
    );

    // 2. Hapus inline backtick `...`
    text = text.replaceAll('`', '');

    // 3. Konversi heading (#, ##, ###) menjadi huruf kapital polos tanpa tanda pagar
    text = text.replaceAllMapped(
      RegExp(r'^\s*#{1,6}\s*(.+)$', multiLine: true),
      (m) => (m[1] ?? '').trim().toUpperCase(),
    );

    // 4. Ubah bullet bintang (* item atau + item) di awal baris menjadi strip (- item)
    text = text.replaceAllMapped(
      RegExp(r'^\s*[\*\+]\s+(.+)$', multiLine: true),
      (m) => '- ${m[1]}',
    );

    // 5. Hapus bintang ganda bold (**teks** -> teks)
    text = text.replaceAllMapped(
      RegExp(r'\*\*([^*]+)\*\*'),
      (m) => m[1] ?? '',
    );

    // 6. Hapus underscore ganda bold (__teks__ -> teks)
    text = text.replaceAllMapped(
      RegExp(r'__([^_]+)__'),
      (m) => m[1] ?? '',
    );

    // 7. Hapus italic bintang (*teks* -> teks) jika bukan baris bullet
    text = text.replaceAllMapped(
      RegExp(r'(?<!\*)\*([^*\n]+)\*(?!\*)'),
      (m) => m[1] ?? '',
    );

    // 8. Hapus markdown link [Label](url) menjadi Label (url)
    text = text.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\(([^)]+)\)'),
      (m) => '${m[1]} (${m[2]})',
    );

    // 9. Rapikan baris kosong berlebihan
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return text.trim();
  }

  Future<String> sendMessage(List<Map<String, String>> messages) async {
    try {
      // Sisipkan petunjuk format output ke pesan terakhir user
      final List<Map<String, String>> payload = [];
      for (int i = 0; i < messages.length; i++) {
        final m = messages[i];
        if (i == messages.length - 1 && m['role'] == 'user') {
          payload.add({
            'role': 'user',
            'content': '${m['content']}$formatInstruction',
          });
        } else {
          payload.add(m);
        }
      }

      final response = await _api.post('/chat', {'messages': payload});
      final data = _api.handleResponse(response);

      final rawResponse = data['response']?.toString() ??
          'Maaf, FitBot tidak memberikan respons.';

      return formatPlainText(rawResponse);
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}
