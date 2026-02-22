String uiErrorMessage(Object error) {
  var message = error.toString().trim();

  const prefixes = <String>[
    'Exception: ',
    'Bad state: ',
    'StateError: ',
    'FormatException: ',
    'Invalid argument(s): ',
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
