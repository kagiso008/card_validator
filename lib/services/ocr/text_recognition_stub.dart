// Used on web and desktop where scanning isn't available
bool get isSupported => false;

Future<String> recognizeText(String path) => throw UnsupportedError(
  'Card scanning is only available on iOS and Android.',
);
