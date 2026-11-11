import '../config/app_config.dart';
import '../core/api_client.dart';
import '../models/climate_info.dart';
import '../models/history_entry.dart';
import '../models/json_utils.dart';
import '../models/recommendation_result.dart';

/// Acceso a recomendaciones, historial y clima.
class AgroService {
  AgroService(this._api);

  final ApiClient _api;

  Future<RecommendationResult> recommend(FarmInput input) async {
    final data = await _api.post(ApiEndpoints.recommend, data: input.toJson());
    return RecommendationResult.fromJson(asMap(data));
  }

  Future<HistoryPage> history({int limit = AppConfig.historyPageSize, int offset = 0}) async {
    final data = await _api.get(ApiEndpoints.history, query: {'limit': limit, 'offset': offset});
    return HistoryPage.fromJson(asMap(data));
  }

  Future<RecommendationResult> historyDetail(int id) async {
    final data = await _api.get(ApiEndpoints.historyItem(id));
    return RecommendationResult.fromJson(asMap(data));
  }

  Future<void> deleteHistory(int id) => _api.delete(ApiEndpoints.historyItem(id));

  Future<ClimateInfo> climate(String department) async {
    final data = await _api.get(ApiEndpoints.climate(department));
    return ClimateInfo.fromJson(asMap(data));
  }
}
