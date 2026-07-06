import 'package:greencyle_fe/domain/entities/app_info.dart';
import 'package:greencyle_fe/domain/repositories/app_repository.dart';

class GetAppInfoUseCase {
  GetAppInfoUseCase(this._repository);

  final AppRepository _repository;

  Future<AppInfo> execute() {
    return _repository.getAppInfo();
  }
}
