import 'package:larpland/service/app_error.dart';

String uiErrorMessage(Object error) {
  if (error is AppError) {
    return error.message;
  }

  var message = error.toString().trim();

  const prefixes = <String>[
    'Exception: ',
    'Exception:',
    'Bad state: ',
    'Bad state:',
    'StateError: ',
    'StateError:',
    'FormatException: ',
    'FormatException:',
    'Invalid argument(s): ',
    'Invalid argument(s):',
  ];

  var changed = true;
  while (changed) {
    changed = false;
    for (final prefix in prefixes) {
      if (message.startsWith(prefix)) {
        message = message.substring(prefix.length).trim();
        changed = true;
      }
    }
  }

  return message.isEmpty ? 'Ha ocurrido un error inesperado.' : message;
}
