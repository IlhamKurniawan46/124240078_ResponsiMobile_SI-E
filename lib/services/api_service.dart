import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/recipe_model.dart';

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() =>
      'ApiException${statusCode != null ? ' ($statusCode)' : ''}: $message';
}

class ApiService {
  static const String baseUrl = ' https://dummyjson.com/recipes';
  static const Duration requestTimeout = Duration(seconds: 30);

  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<RecipeModel>> fetchList(
    ContentType type, {
    int limit = 50,
  }) async {
    final uri = Uri.parse('$baseUrl/${type.endpoint}/?limit=$limit');

    try {
      final response = await _client.get(uri).timeout(requestTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic> results = body['results'] as List<dynamic>? ?? [];

        return results
            .map((item) => RecipeModel.fromJson(
                  item as Map<String, dynamic>,
                  defaultType: type,
                ))
            .toList();
      } else {
        throw ApiException(
          'Gagal mengambil daftar ${type.displayName}. Server merespon dengan status ${response.statusCode}.',
          statusCode: response.statusCode,
        );
      }
    } on SocketException catch (e) {
      throw ApiException(
        'Tidak ada koneksi internet. Periksa jaringan Anda (${e.message}).',
      );
    } on TimeoutException {
      throw const ApiException(
        'Koneksi ke server waktu habis (timeout). Silakan coba lagi.',
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        'Terjadi kendala jaringan: ${e.message}',
      );
    } on FormatException {
      throw const ApiException(
        'Format data dari server tidak valid (gagal parsing JSON).',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Terjadi kesalahan tidak terduga: $e');
    }
  }

  Future<RecipeModel> fetchDetail(ContentType type, int id) async {
    final uri = Uri.parse('$baseUrl/${type.endpoint}/$id/');

    try {
      final response = await _client.get(uri).timeout(requestTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        return RecipeModel.fromJson(body, defaultType: type);
      } else if (response.statusCode == 404) {
        throw ApiException(
          'Data ${type.displayName} dengan ID $id tidak ditemukan.',
          statusCode: 404,
        );
      } else {
        throw ApiException(
          'Gagal mengambil detail ${type.displayName}. Status: ${response.statusCode}.',
          statusCode: response.statusCode,
        );
      }
    } on SocketException catch (e) {
      throw ApiException(
        'Tidak ada koneksi internet. Periksa jaringan Anda (${e.message}).',
      );
    } on TimeoutException {
      throw const ApiException(
        'Koneksi ke server waktu habis (timeout). Silakan coba lagi.',
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        'Terjadi kendala jaringan: ${e.message}',
      );
    } on FormatException {
      throw const ApiException(
        'Format data detail tidak valid (gagal parsing JSON).',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Terjadi kesalahan tidak terduga: $e');
    }
  }
}