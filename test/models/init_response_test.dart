import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:footprints_sdk/src/models/init_response.dart';

void main() {
  group('InitResponse', () {
    test('fromJson/toJson round-trip', () {
      const response = InitResponse(
        success: true,
        mobileId: 'c1234567890abcdef',
      );

      final json = response.toJson();
      final restored = InitResponse.fromJson(json);

      expect(restored.success, isTrue);
      expect(restored.mobileId, 'c1234567890abcdef');
    });

    test('deserializes from fixture', () {
      final fixture = File('test/fixtures/init_response.json');
      final json = jsonDecode(fixture.readAsStringSync()) as Map<String, dynamic>;
      final response = InitResponse.fromJson(json);

      expect(response.success, isTrue);
      expect(response.mobileId, startsWith('c'));
    });
  });
}
