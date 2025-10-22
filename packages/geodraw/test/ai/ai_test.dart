import 'package:flutter_test/flutter_test.dart';
import 'package:geodraw/geodraw.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Generate mocks
@GenerateMocks([http.Client])
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

  group('CommandValidator', () {
    late CommandValidator validator;

    setUp(() {
      validator = CommandValidator();
    });

    test('validates simple point command', () {
      final result = validator.validate(['point(0, 0, A)']);
      
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
      expect(result.validCommands, hasLength(1));
      expect(result.validCommands[0].name, equals('point'));
    });

    test('validates command sequence with dependencies', () {
      final result = validator.validate([
        'point(0, 0, A)',
        'point(5, 0, B)',
        'line(A, B, AB)',
      ]);
      
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
      expect(result.validCommands, hasLength(3));
    });

    test('detects undefined references', () {
      final result = validator.validate([
        'point(0, 0, A)',
        'line(A, B, AB)', // B is undefined
      ]);
      
      expect(result.isValid, isFalse);
      expect(result.errors, hasLength(1));
      expect(result.errors[0], anyOf(contains('undefined'), contains('Undefined')));
      expect(result.errors[0], contains('B'));
    });

    test('detects invalid syntax', () {
      final result = validator.validate([
        'invalid command format',
      ]);
      
      expect(result.isValid, isFalse);
      expect(result.errors, isNotEmpty);
    });

    test('warns on label redefinition', () {
      final result = validator.validate([
        'point(0, 0, A)',
        'point(5, 0, A)', // Redefining A
      ]);
      
      expect(result.isValid, isTrue);
      expect(result.warnings, hasLength(1));
      expect(result.warnings[0], contains('redefined'));
    });

    test('validates circle command with dependencies', () {
      final result = validator.validate([
        'point(0, 0, O)',
        'point(5, 0, P)',
        'circle(O, P, C)',
      ]);
      
      expect(result.isValid, isTrue);
      expect(result.validCommands, hasLength(3));
    });

    test('validates midpoint command', () {
      final result = validator.validate([
        'point(0, 0, A)',
        'point(10, 0, B)',
        'midpoint(A, B, M)',
      ]);
      
      expect(result.isValid, isTrue);
      expect(result.validCommands, hasLength(3));
    });

    test('validates perpendicular command', () {
      final result = validator.validate([
        'point(0, 0, A)',
        'point(5, 0, B)',
        'line(A, B, L)',
        'point(2, 5, C)',
        'perpendicular(L, C, P)',
      ]);
      
      expect(result.isValid, isTrue);
      expect(result.validCommands, hasLength(5));
    });

    test('detects insufficient arguments', () {
      final result = validator.validate([
        'point(0)', // Missing y and label
      ]);
      
      expect(result.isValid, isFalse);
      expect(result.errors, isNotEmpty);
    });

    test('validates complex construction', () {
      final result = validator.validate([
        'point(0, 0, A)',
        'point(5, 0, B)',
        'point(2.5, 4, C)',
        'triangle(A, B, C, T)',
        'midpoint(A, B, M1)',
        'midpoint(B, C, M2)',
        'midpoint(C, A, M3)',
      ]);
      
      expect(result.isValid, isTrue);
      expect(result.validCommands, hasLength(7));
      expect(result.errors, isEmpty);
    });

    test('isValidCommand checks single command', () {
      expect(validator.isValidCommand('point(0, 0, A)'), isTrue);
      expect(validator.isValidCommand('invalid'), isFalse);
      expect(validator.isValidCommand(''), isFalse);
    });
  });

  group('AIService Configuration', () {
    test('development config has correct defaults', () {
      final config = AIServiceConfig.development();
      
      expect(config.apiEndpoint, contains('localhost'));
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

  group('ValidationResult', () {
    test('success factory creates valid result', () {
      final commands = [
        Command(name: 'point', arguments: [0, 0, 'A'], originalInput: 'point(0, 0, A)'),
      ];
      final result = ValidationResult.success(commands);
      
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
      expect(result.warnings, isEmpty);
      expect(result.validCommands, equals(commands));
    });

    test('failure factory creates invalid result', () {
      final result = ValidationResult.failure(['Error 1', 'Error 2']);
      
      expect(result.isValid, isFalse);
      expect(result.errors, hasLength(2));
      expect(result.validCommands, isEmpty);
    });

    test('hasWarnings and hasErrors properties work', () {
      final resultWithWarnings = ValidationResult(
        isValid: true,
        errors: [],
        warnings: ['Warning 1'],
        validCommands: [],
      );
      
      expect(resultWithWarnings.hasWarnings, isTrue);
      expect(resultWithWarnings.hasErrors, isFalse);

      final resultWithErrors = ValidationResult(
        isValid: false,
        errors: ['Error 1'],
        warnings: [],
        validCommands: [],
      );
      
      expect(resultWithErrors.hasWarnings, isFalse);
      expect(resultWithErrors.hasErrors, isTrue);
    });
  });
}
