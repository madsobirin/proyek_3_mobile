import 'api_service.dart';

class ChatService {
  final ApiService _api = ApiService();

  Future<String> sendMessage(
    List<Map<String, String>> messages,
  ) async {
    try {
      final response = await _api.post('/chat', {
        'messages': messages,
      });

      final data = _api.handleResponse(response);

      return data['response'] ??
          'Maaf, FitBot tidak memberikan respons.';
    } catch (e) {
      throw Exception(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}