import 'package:greencyle_fe/domain/entities/app_info.dart';
import 'package:greencyle_fe/domain/repositories/app_repository.dart';
import 'package:greencyle_fe/services/app_service.dart';

class AppRepositoryImpl implements AppRepository {
  AppRepositoryImpl(this._service);

  final AppService _service;

  @override
  Future<AppInfo> getAppInfo() async {
    final data = await _service.fetchAppInfo();

    return AppInfo(
      name: data['name'] as String,
      description: data['description'] as String,
    );
  }
}
