import 'package:greencyle_fe/domain/entities/app_info.dart';

abstract class AppRepository {
  Future<AppInfo> getAppInfo();
}
