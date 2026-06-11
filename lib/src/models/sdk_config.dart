/// Runtime SDK configuration stored locally.
class SdkConfig {
  final String baseUrl;
  final String appKey;
  final Duration refreshInterval;
  final Set<String> enabledFeatures;

  const SdkConfig({
    required this.baseUrl,
    required this.appKey,
    this.refreshInterval = const Duration(minutes: 5),
    this.enabledFeatures = const {},
  });
}
