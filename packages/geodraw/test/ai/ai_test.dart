import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:geodraw/geodraw.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'ai_test.mocks.dart';

void main() {
  group('AIService', () {
    late MockClient mockClient;
    late AIService aiService;

    setUp(() {
      mockClient = MockClient();
      aiService = AIService(
        config: const AIServiceConfig(
          apiEndpoint: 'http://test.com/api/generate',
        ),
        client: mockClient,
      );
    });

    tearDown(() {
      aiService.dispose();
    });

    test('generates commands from description', () async {
      // Mock response
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({
              'commands': [
                'point(0, 0, A)',
                'point(5, 0, B)',
                'line(A, B, AB)',
              ],
            }),
            200,
          ));

      final response = await aiService.generateCommands(
        'Draw a horizontal line of length 5',
      );

      expect(response.isSuccess, isTrue);
      expect(response.commands, hasLength(3));
      expect(response.commands![0], contains('point'));
      expect(response.commands![1], contains('point'));
      expect(response.commands![2], contains('line'));
    });

    test('handles empty description', () async {
      final response = await aiService.generateCommands('');
      
      expect(response.isSuccess, isFalse);
      expect(response.error, contains('empty'));
    });

    test('handles API error', () async {
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('Server error', 500));

      final response = await aiService.generateCommands('test');
      
      expect(response.isSuccess, isFalse);
      expect(response.error, isNotNull);
    });

    test('handles malformed response', () async {
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('not json', 200));

      final response = await aiService.generateCommands('test');
      
      expect(response.isSuccess, isFalse);
      expect(response.error, isNotNull);
      expect(response.error, anyOf(contains('parse'), contains('format')));
    });

    test('retries on network failure', () async {
      int attemptCount = 0;
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async {
        attemptCount++;
        if (attemptCount < 2) {
          throw http.ClientException('Network error');
        }
        return http.Response(
          jsonEncode({'commands': ['point(0, 0, A)']}),
          200,
        );
      });

      final response = await aiService.generateCommands('test');
      
      expect(response.isSuccess, isTrue);
      expect(attemptCount, equals(2));
    });

    test('includes API key in headers when configured', () async {
      final serviceWithKey = AIService(
        config: const AIServiceConfig(
          apiEndpoint: 'http://test.com/api',
          apiKey: 'test-key',
        ),
        client: mockClient,
      );

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({'commands': []}),
            200,
          ));

      await serviceWithKey.generateCommands('test');

      final captured = verify(mockClient.post(
        any,
        headers: captureAnyNamed('headers'),
        body: anyNamed('body'),
      )).captured;

      expect(captured[0], contains('Authorization'));
      expect(captured[0]['Authorization'], equals('Bearer test-key'));

      serviceWithKey.dispose();
    });
  });

  group('AIService Configuration', () {
    test('development config has correct defaults', () {
      final config = AIServiceConfig.development();
      
      expect(config.apiEndpoint, contains('192.168.1.3'));
      expect(config.timeout.inSeconds, equals(30));
      expect(config.maxRetries, equals(3));
    });

    test('production config accepts optional API key', () {
      final configWithKey = AIServiceConfig.production(
        'https://api.example.com',
        apiKey: 'secret-key',
      );

      final configWithoutKey = AIServiceConfig.production(
        'https://api.example.com',
      );
      
      expect(configWithKey.apiEndpoint, equals('https://api.example.com'));
      expect(configWithKey.apiKey, equals('secret-key'));
      expect(configWithoutKey.apiEndpoint, equals('https://api.example.com'));
      expect(configWithoutKey.apiKey, isNull);
    });
  });
}
