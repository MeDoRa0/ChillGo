import '../entities/app_configuration.dart';

abstract class ConfigRepository {
  Future<AppConfiguration> getConfiguration();
  Future<void> saveConfiguration(AppConfiguration config);
}
