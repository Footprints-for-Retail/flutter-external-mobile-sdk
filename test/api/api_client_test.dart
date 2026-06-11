import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footprints_sdk/src/api/footprints_api_client.dart';
import 'package:footprints_sdk/src/config/footprints_config.dart';
import 'package:footprints_sdk/src/models/init_request.dart';
import 'package:footprints_sdk/src/models/technical_info.dart';
import 'package:footprints_sdk/src/models/tracking_event.dart';

/// Interceptor that captures requests and returns mock responses.
class _MockInterceptor extends Interceptor {
  final Map<String, dynamic> Function(RequestOptions options) responder;
  RequestOptions? lastRequest;

  _MockInterceptor(this.responder);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    lastRequest = options;
    try {
      final data = responder(options);
      handler.resolve(Response(
        requestOptions: options,
        data: data,
        statusCode: 200,
      ),);
    } catch (e) {
      handler.reject(DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: options,
          statusCode: 400,
          data: {'success': false, 'error': e.toString()},
        ),
      ),);
    }
  }
}

/// Interceptor that always rejects with a server error.
class _ErrorInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    handler.reject(DioException(
      requestOptions: options,
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: options,
        statusCode: 500,
        data: {'success': false},
      ),
    ),);
  }
}

void main() {
  const appKey = 'testkey123';
  const mobileId = 'c1234567890abcdef';

  late Dio dio;
  late _MockInterceptor mockInterceptor;
  late FootprintsApiClient client;

  group('FootprintsApiClient', () {
    group('initDevice', () {
      setUp(() {
        dio = Dio(BaseOptions(baseUrl: 'https://test.example.com'));
        mockInterceptor = _MockInterceptor((options) {
          return {'success': true, 'mobileId': mobileId};
        });
        dio.interceptors.add(mockInterceptor);
        client = FootprintsApiClient(
          baseUrl: 'https://test.example.com',
          appKey: appKey,
          config: const FootprintsConfig(),
          dio: dio,
        );
      });

      test('sends POST to /mobileapi/init', () async {
        const request = InitRequest(
          appkey: appKey,
          technicalInfo: TechnicalInfo(
            screenSize: '1080x2400',
            deviceType: 'Smartphone',
            deviceOs: 'Android 14',
            deviceUuid: 'test-uuid',
          ),
        );

        final response = await client.initDevice(request);

        expect(mockInterceptor.lastRequest?.method, 'POST');
        expect(mockInterceptor.lastRequest?.path, '/mobileapi/init');
        expect(response.success, isTrue);
        expect(response.mobileId, mobileId);
      });

      test('sends correct request body', () async {
        const request = InitRequest(
          appkey: appKey,
          technicalInfo: TechnicalInfo(
            screenSize: '1080x2400',
            deviceType: 'Smartphone',
            deviceOs: 'Android 14',
            deviceUuid: 'test-uuid',
          ),
          pushNotificationToken: 'fcm-token-123',
        );

        await client.initDevice(request);

        final body = mockInterceptor.lastRequest?.data as Map<String, dynamic>;
        expect(body['appkey'], appKey);
        expect(body.containsKey('technicalInfo'), isTrue);
        expect(body['pushNotificationToken'], 'fcm-token-123');
      });
    });

    group('getContentDelivery', () {
      setUp(() {
        dio = Dio(BaseOptions(baseUrl: 'https://test.example.com'));
        mockInterceptor = _MockInterceptor((options) {
          return {
            'success': true,
            'mobileId': mobileId,
            'data': {
              'displayAd': [
                {
                  'adType': 'displayAd',
                  'adId': 'ad_001',
                  'title': 'Summer Sale',
                  'campaignName': 'Summer Campaign',
                  'contentType': 'image',
                  'contentUrl': 'https://cdn.example.com/banner.jpg',
                  'bannerType': 'mobileAppBanner600x400',
                  'campaignId': 'camp_001',
                  'linkUrl': 'https://example.com/sale',
                },
              ],
              'videoAdHorizontalVideo': [],
              'videoAdVerticalVideo': [],
              'leadAd': [],
              'sponsoredProducts': [],
              'recommendationProducts': [],
              'mobileNotifications': [],
            },
          };
        });
        dio.interceptors.add(mockInterceptor);
        client = FootprintsApiClient(
          baseUrl: 'https://test.example.com',
          appKey: appKey,
          config: const FootprintsConfig(),
          dio: dio,
        );
      });

      test('sends POST to /mobileapi/content-delivery with appkey and mid',
          () async {
        final response = await client.getContentDelivery(
          appKey: appKey,
          mid: mobileId,
        );

        expect(mockInterceptor.lastRequest?.method, 'POST');
        expect(
          mockInterceptor.lastRequest?.path,
          '/mobileapi/content-delivery',
        );
        final body = mockInterceptor.lastRequest?.data as Map<String, dynamic>;
        expect(body['appkey'], appKey);
        expect(body['mid'], mobileId);
        expect(response.success, isTrue);
      });

      test('parses displayAd array from response', () async {
        final response = await client.getContentDelivery(
          appKey: appKey,
          mid: mobileId,
        );

        expect(response.data, isNotNull);
        final data = response.data!;
        expect(data.displayAd, isNotEmpty);
        expect(data.displayAd.first.adId, 'ad_001');
        expect(data.displayAd.first.title, 'Summer Sale');
        expect(
          data.displayAd.first.bannerType,
          'mobileAppBanner600x400',
        );
      });

      test('sends additionalData and searchQuery when provided', () async {
        await client.getContentDelivery(
          appKey: appKey,
          mid: mobileId,
          additionalData: [
            {'screenIdentifier': 'home'},
          ],
          searchQuery: 'shoes',
        );

        final body = mockInterceptor.lastRequest?.data as Map<String, dynamic>;
        final adData = body['additionalData'] as List;
        expect((adData.first as Map)['screenIdentifier'], 'home');
        expect(body['searchQuery'], 'shoes');
      });

      test('omits additionalData and searchQuery when null', () async {
        await client.getContentDelivery(
          appKey: appKey,
          mid: mobileId,
        );

        final body = mockInterceptor.lastRequest?.data as Map<String, dynamic>;
        expect(body.containsKey('additionalData'), isFalse);
        expect(body.containsKey('searchQuery'), isFalse);
      });
    });

    group('sendEvent', () {
      setUp(() {
        dio = Dio(BaseOptions(baseUrl: 'https://test.example.com'));
        mockInterceptor = _MockInterceptor((options) {
          return {'success': true, 'message': 'Track saved'};
        });
        dio.interceptors.add(mockInterceptor);
        client = FootprintsApiClient(
          baseUrl: 'https://test.example.com',
          appKey: appKey,
          config: const FootprintsConfig(),
          dio: dio,
        );
      });

      test('sends reach event to POST /mobileapi/send', () async {
        const event = TrackingEvent(
          appkey: appKey,
          mid: mobileId,
          requestType: 'action',
          actionType: 'visit',
        );

        final result = await client.sendEvent(event);

        expect(mockInterceptor.lastRequest?.method, 'POST');
        expect(mockInterceptor.lastRequest?.path, '/mobileapi/send');
        expect(result['success'], isTrue);
      });

      test('sends impression event with additionalData', () async {
        const event = TrackingEvent(
          appkey: appKey,
          mid: mobileId,
          requestType: 'action',
          actionType: 'visit',
          additionalData: {
            'campaignId': 'camp_001',
            'adId': 'ad_001',
          },
        );

        await client.sendEvent(event);

        final body = mockInterceptor.lastRequest?.data as Map<String, dynamic>;
        expect(body['requestType'], 'action');
        expect(body['actionType'], 'visit');
        expect(body['additionalData']['campaignId'], 'camp_001');
        expect(body['additionalData']['adId'], 'ad_001');
      });
    });

    group('updateGeo', () {
      setUp(() {
        dio = Dio(BaseOptions(baseUrl: 'https://test.example.com'));
        mockInterceptor = _MockInterceptor((options) {
          return {'success': true};
        });
        dio.interceptors.add(mockInterceptor);
        client = FootprintsApiClient(
          baseUrl: 'https://test.example.com',
          appKey: appKey,
          config: const FootprintsConfig(),
          dio: dio,
        );
      });

      test('sends PUT to /mobileapi/geo', () async {
        final result = await client.updateGeo(
          appKey: appKey,
          mid: mobileId,
          lat: 40.7128,
          lon: -74.0060,
          accuracy: 10.5,
        );

        expect(mockInterceptor.lastRequest?.method, 'PUT');
        expect(mockInterceptor.lastRequest?.path, '/mobileapi/geo');
        expect(result['success'], isTrue);
      });

      test('sends correct geo body', () async {
        await client.updateGeo(
          appKey: appKey,
          mid: mobileId,
          lat: 40.7128,
          lon: -74.0060,
          accuracy: 10.5,
        );

        final body = mockInterceptor.lastRequest?.data as Map<String, dynamic>;
        expect(body['appkey'], appKey);
        expect(body['mid'], mobileId);
        expect(body['lat'], 40.7128);
        expect(body['lon'], -74.0060);
        expect(body['accuracy'], 10.5);
      });
    });

    group('error handling', () {
      test('propagates DioException on server error', () {
        dio = Dio(BaseOptions(baseUrl: 'https://test.example.com'));
        dio.interceptors.add(_ErrorInterceptor());
        client = FootprintsApiClient(
          baseUrl: 'https://test.example.com',
          appKey: appKey,
          config: const FootprintsConfig(),
          dio: dio,
        );

        expect(
          () => client.initDevice(const InitRequest(
            appkey: appKey,
            technicalInfo: TechnicalInfo(
              screenSize: '1080x2400',
              deviceType: 'Smartphone',
              deviceOs: 'Android 14',
              deviceUuid: 'test-uuid',
            ),
          ),),
          throwsA(isA<DioException>()),
        );
      });
    });
  });
}
