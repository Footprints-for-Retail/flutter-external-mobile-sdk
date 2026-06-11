import 'package:dio/dio.dart';

import '../config/footprints_config.dart';
import '../models/init_request.dart';
import '../models/init_response.dart';
import '../models/content_delivery_response.dart';
import '../models/tracking_event.dart';
import '../models/geo_request.dart';
import '../models/sensor_request.dart';
import '../models/sponsored_product.dart';
import '../models/recommendation_product.dart';
import 'retry_interceptor.dart';

/// HTTP client for all 14 /mobileapi endpoints.
class FootprintsApiClient {
  late final Dio _dio;

  FootprintsApiClient({
    required String baseUrl,
    required String appKey,
    required FootprintsConfig config,
    Dio? dio,
  }) {
    _dio = dio ??
        Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: config.connectTimeout,
          receiveTimeout: config.readTimeout,
          headers: {
            'Content-Type': 'application/json',
            'appKey': appKey,
          },
        ),);

    _dio.interceptors.add(RetryInterceptor(
      maxRetries: config.maxRetryAttempts,
    ),);
  }

  // ─── Core endpoints (Phase 1) ───────────────────────────────

  /// POST /mobileapi/init — Register device.
  Future<InitResponse> initDevice(InitRequest request) async {
    final response = await _dio.post(
      '/mobileapi/init',
      data: request.toJson(),
    );
    return InitResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// POST /mobileapi/content-delivery — Fetch ad content.
  Future<ContentDeliveryResponse> getContentDelivery({
    required String appKey,
    required String mid,
    List<Map<String, dynamic>>? additionalData,
    String? searchQuery,
  }) async {
    final body = <String, dynamic>{
      'appkey': appKey,
      'mid': mid,
    };
    if (additionalData != null) body['additionalData'] = additionalData;
    if (searchQuery != null) body['searchQuery'] = searchQuery;

    final response = await _dio.post(
      '/mobileapi/content-delivery',
      data: body,
    );
    return ContentDeliveryResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// POST /mobileapi/send — Send tracking event (reach or impression).
  Future<Map<String, dynamic>> sendEvent(TrackingEvent event) async {
    final response = await _dio.post(
      '/mobileapi/send',
      data: event.toJson(),
    );
    return response.data as Map<String, dynamic>;
  }

  /// PUT /mobileapi/geo — Update device geo-location.
  Future<Map<String, dynamic>> updateGeo({
    required String appKey,
    required String mid,
    required double lat,
    required double lon,
    double? accuracy,
  }) async {
    final body = GeoRequest(
      appkey: appKey,
      mid: mid,
      lat: lat,
      lon: lon,
      accuracy: accuracy,
    );
    final response = await _dio.put(
      '/mobileapi/geo',
      data: body.toJson(),
    );
    return response.data as Map<String, dynamic>;
  }

  /// PUT /mobileapi/sensors — Submit BLE beacon data.
  Future<Map<String, dynamic>> submitSensors(SensorRequest request) async {
    final response = await _dio.put(
      '/mobileapi/sensors',
      data: request.toJson(),
    );
    return response.data as Map<String, dynamic>;
  }

  // ─── Sponsored products (Phase 2) ──────────────────────────

  /// POST /mobileapi/sponsored-products-id
  Future<SponsoredProductsResponse> getSponsoredProductIds({
    required String appKey,
    required String mid,
    Map<String, dynamic>? additionalData,
  }) async {
    final response = await _dio.post(
      '/mobileapi/sponsored-products-id',
      data: _buildBody(appKey, mid, additionalData),
    );
    return SponsoredProductsResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// POST /mobileapi/sponsored-products-json
  Future<SponsoredProductsResponse> getSponsoredProductsJson({
    required String appKey,
    required String mid,
    Map<String, dynamic>? additionalData,
  }) async {
    final response = await _dio.post(
      '/mobileapi/sponsored-products-json',
      data: _buildBody(appKey, mid, additionalData),
    );
    return SponsoredProductsResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// POST /mobileapi/sponsored-products-ad
  Future<SponsoredProductsResponse> getSponsoredProductAd({
    required String appKey,
    required String mid,
    Map<String, dynamic>? additionalData,
  }) async {
    final response = await _dio.post(
      '/mobileapi/sponsored-products-ad',
      data: _buildBody(appKey, mid, additionalData),
    );
    return SponsoredProductsResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  // ─── Recommendation products (Phase 2) ─────────────────────

  /// POST /mobileapi/recommendation-products
  Future<RecommendationProductsResponse> getRecommendationProducts({
    required String appKey,
    required String mid,
    required String searchQuery,
    Map<String, dynamic>? additionalData,
  }) async {
    final body = _buildBody(appKey, mid, additionalData);
    body['searchQuery'] = searchQuery;
    final response = await _dio.post(
      '/mobileapi/recommendation-products',
      data: body,
    );
    return RecommendationProductsResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// POST /mobileapi/recommendation-products-ids
  Future<RecommendationProductsResponse> getRecommendationProductIds({
    required String appKey,
    required String mid,
    required String searchQuery,
    Map<String, dynamic>? additionalData,
  }) async {
    final body = _buildBody(appKey, mid, additionalData);
    body['searchQuery'] = searchQuery;
    final response = await _dio.post(
      '/mobileapi/recommendation-products-ids',
      data: body,
    );
    return RecommendationProductsResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// POST /mobileapi/recommendation-products-json
  Future<RecommendationProductsResponse> getRecommendationProductsJson({
    required String appKey,
    required String mid,
    required String searchQuery,
    Map<String, dynamic>? additionalData,
  }) async {
    final body = _buildBody(appKey, mid, additionalData);
    body['searchQuery'] = searchQuery;
    final response = await _dio.post(
      '/mobileapi/recommendation-products-json',
      data: body,
    );
    return RecommendationProductsResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// POST /mobileapi/recommendation-products/search
  Future<RecommendationProductsResponse> searchRecommendationProducts({
    required String appKey,
    required String mid,
    required String searchQuery,
    Map<String, dynamic>? additionalData,
  }) async {
    final body = _buildBody(appKey, mid, additionalData);
    body['searchQuery'] = searchQuery;
    final response = await _dio.post(
      '/mobileapi/recommendation-products/search',
      data: body,
    );
    return RecommendationProductsResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  // ─── Proximity (Phase 3) ───────────────────────────────────

  /// POST /mobileapi/proximity-location
  Future<Map<String, dynamic>> getProximityLocation({
    required String appKey,
    required String mid,
  }) async {
    final response = await _dio.post(
      '/mobileapi/proximity-location',
      data: {'appkey': appKey, 'mid': mid},
    );
    return response.data as Map<String, dynamic>;
  }

  // ─── Helpers ───────────────────────────────────────────────

  Map<String, dynamic> _buildBody(
    String appKey,
    String mid,
    Map<String, dynamic>? additionalData,
  ) {
    final body = <String, dynamic>{
      'appkey': appKey,
      'mid': mid,
    };
    if (additionalData != null) body['additionalData'] = additionalData;
    return body;
  }
}
