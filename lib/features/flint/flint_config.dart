class FlintConfig {
  const FlintConfig._();

  static const apiBaseUrl = String.fromEnvironment(
    'FLINT_API_BASE_URL',
    defaultValue: '',
  );

  static const apiToken = String.fromEnvironment(
    'FLINT_API_TOKEN',
    defaultValue: '',
  );

  static const ruDirectPath = String.fromEnvironment(
    'FLINT_RU_DIRECT_PATH',
    defaultValue: '/v1/rules/ru-direct',
  );

  static bool get apiConfigured => apiBaseUrl.trim().isNotEmpty;
}
