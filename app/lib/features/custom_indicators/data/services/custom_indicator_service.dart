import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../../core/network/dio_client.dart';
import '../../../../config/api_config.dart';
import '../models/custom_indicator.dart';

/// Service para gerenciar Indicadores Personalizados
/// 
/// Por enquanto usa storage local (SharedPreferences) como fallback,
/// mas está preparado para usar API quando o endpoint estiver disponível.
class CustomIndicatorService {
  static const String _storageKey = 'custom_indicators';
  static const String _apiEndpoint = '${ApiConfig.apiPrefix}/custom-indicators';

  /// Lista todos os indicadores
  /// 
  /// [from] e [to] são opcionais e usados para calcular valores e percentuais
  static Future<List<CustomIndicator>> list({
    String? from,
    String? to,
  }) async {
    try {
      // Tentar buscar da API primeiro
      try {
        final queryParams = <String, dynamic>{};
        if (from != null) queryParams['from'] = from;
        if (to != null) queryParams['to'] = to;
        
        final response = await DioClient.get(
          _apiEndpoint,
          queryParameters: queryParams.isEmpty ? null : queryParams,
        );
        if (response.statusCode == 200) {
          final data = response.data['data'] as List<dynamic>;
          return data.map((json) => CustomIndicator.fromJson(json)).toList();
        }
      } catch (e) {
        // Se API não estiver disponível, usar storage local
        return await _loadFromStorage();
      }
    } catch (e) {
      // Fallback para storage local
      return await _loadFromStorage();
    }
    return await _loadFromStorage();
  }

  /// Obtém um indicador específico
  static Future<CustomIndicator?> get(int id) async {
    try {
      try {
        final response = await DioClient.get('$_apiEndpoint/$id');
        if (response.statusCode == 200) {
          return CustomIndicator.fromJson(response.data['data']);
        }
      } catch (e) {
        // Fallback para storage local
        final indicators = await _loadFromStorage();
        return indicators.firstWhere(
          (ind) => ind.id == id,
          orElse: () => throw Exception('Indicador não encontrado'),
        );
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  /// Cria um novo indicador
  static Future<CustomIndicator> create({
    required String name,
    required List<int> categoryIds,
  }) async {
    try {
      try {
        final response = await DioClient.post(
          _apiEndpoint,
          data: {
            'name': name,
            'category_ids': categoryIds,
          },
        );
        if (response.statusCode == 201 || response.statusCode == 200) {
          return CustomIndicator.fromJson(response.data['data']);
        }
      } catch (e) {
        // Fallback para storage local
        return await _createInStorage(name: name, categoryIds: categoryIds);
      }
    } catch (e) {
      // Fallback para storage local
      return await _createInStorage(name: name, categoryIds: categoryIds);
    }
    return await _createInStorage(name: name, categoryIds: categoryIds);
  }

  /// Atualiza um indicador
  static Future<CustomIndicator> update(
    int id, {
    String? name,
    List<int>? categoryIds,
  }) async {
    try {
      try {
        final response = await DioClient.put(
          '$_apiEndpoint/$id',
          data: {
            if (name != null) 'name': name,
            if (categoryIds != null) 'category_ids': categoryIds,
          },
        );
        if (response.statusCode == 200) {
          return CustomIndicator.fromJson(response.data['data']);
        }
      } catch (e) {
        // Fallback para storage local
        return await _updateInStorage(
          id: id,
          name: name,
          categoryIds: categoryIds,
        );
      }
    } catch (e) {
      // Fallback para storage local
      return await _updateInStorage(
        id: id,
        name: name,
        categoryIds: categoryIds,
      );
    }
    return await _updateInStorage(
      id: id,
      name: name,
      categoryIds: categoryIds,
    );
  }

  /// Deleta um indicador
  static Future<void> delete(int id) async {
    try {
      try {
        await DioClient.delete('$_apiEndpoint/$id');
        return;
      } catch (e) {
        // Fallback para storage local
        await _deleteFromStorage(id);
      }
    } catch (e) {
      // Fallback para storage local
      await _deleteFromStorage(id);
    }
  }

  // Métodos de storage local (fallback)

  static Future<List<CustomIndicator>> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => CustomIndicator.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<CustomIndicator> _createInStorage({
    required String name,
    required List<int> categoryIds,
  }) async {
    final indicators = await _loadFromStorage();
    final now = DateTime.now();
    final newId = indicators.isEmpty
        ? 1
        : indicators.map((i) => i.id).reduce((a, b) => a > b ? a : b) + 1;

    final newIndicator = CustomIndicator(
      id: newId,
      name: name,
      categoryIds: categoryIds,
      createdAt: now,
      updatedAt: now,
    );

    indicators.add(newIndicator);
    await _saveToStorage(indicators);
    return newIndicator;
  }

  static Future<CustomIndicator> _updateInStorage({
    required int id,
    String? name,
    List<int>? categoryIds,
  }) async {
    final indicators = await _loadFromStorage();
    final index = indicators.indexWhere((ind) => ind.id == id);
    if (index == -1) throw Exception('Indicador não encontrado');

    final existing = indicators[index];
    final updated = existing.copyWith(
      name: name,
      categoryIds: categoryIds,
      updatedAt: DateTime.now(),
    );

    indicators[index] = updated;
    await _saveToStorage(indicators);
    return updated;
  }

  static Future<void> _deleteFromStorage(int id) async {
    final indicators = await _loadFromStorage();
    indicators.removeWhere((ind) => ind.id == id);
    await _saveToStorage(indicators);
  }

  static Future<void> _saveToStorage(List<CustomIndicator> indicators) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = indicators.map((ind) => ind.toJson()).toList();
    await prefs.setString(_storageKey, json.encode(jsonList));
  }
}

