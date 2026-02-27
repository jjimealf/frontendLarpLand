import 'package:flutter_test/flutter_test.dart';
import 'package:larpland/service/app_error.dart';
import 'package:larpland/util/error_message.dart';

void main() {
  group('uiErrorMessage', () {
    test('returns AppError message', () {
      const error = AppError(
        code: 'validation.empty_name',
        message: 'El nombre no puede estar vacio.',
      );

      expect(uiErrorMessage(error), 'El nombre no puede estar vacio.');
    });

    test('strips known exception prefixes', () {
      final error = Exception('Fallo de red');

      expect(uiErrorMessage(error), 'Fallo de red');
    });

    test('returns fallback for empty message', () {
      expect(uiErrorMessage(Exception('')), 'Ha ocurrido un error inesperado.');
    });
  });
}
