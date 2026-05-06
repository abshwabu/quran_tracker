import 'package:dio/dio.dart';
import '../models/quran_models.dart';

class ApiService {
  final Dio _transcriptionDio = Dio(BaseOptions(
    baseUrl: 'http://109.199.121.222:8000',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
  ));

  final Dio _quranDio = Dio(BaseOptions(
    baseUrl: 'https://api.alquran.cloud/v1',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  Future<Map<String, dynamic>?> transcribeAudio(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: 'recitation.wav'),
      });

      final response = await _transcriptionDio.post('/transcribe', data: formData);

      if (response.statusCode == 200) {
        return response.data;
      }
      return {'error': 'Server error: ${response.statusCode}'};
    } on DioException catch (e) {
      print('Error transcribing audio: $e');
      if (e.response != null) {
        return e.response?.data is Map ? e.response?.data : {'error': 'Server error: ${e.response?.statusCode}'};
      }
      return {'error': 'Network error: ${e.message}'};
    } catch (e) {
      print('Unexpected error: $e');
      return {'error': 'Unexpected error: $e'};
    }
  }

  Future<List<Surah>> getSurahs() async {
    try {
      final response = await _quranDio.get('/surah');
      if (response.statusCode == 200) {
        final List data = response.data['data'];
        return data.map((json) => Surah.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching surahs: $e');
      return [];
    }
  }

  Future<List<Ayah>> getAyahs(int surahNumber) async {
    try {
      final response = await _quranDio.get('/surah/$surahNumber');
      if (response.statusCode == 200) {
        final List data = response.data['data']['ayahs'];
        return data.map((json) => Ayah.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
