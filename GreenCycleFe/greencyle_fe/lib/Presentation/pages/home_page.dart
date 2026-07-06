import 'package:flutter/material.dart';
import 'package:greencyle_fe/data/repositories/app_repository_impl.dart';
import 'package:greencyle_fe/domain/entities/app_info.dart';
import 'package:greencyle_fe/domain/usecases/get_app_info_usecase.dart';
import 'package:greencyle_fe/services/app_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final GetAppInfoUseCase _useCase;
  AppInfo? _appInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final repository = AppRepositoryImpl(AppService());
    _useCase = GetAppInfoUseCase(repository);
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    final appInfo = await _useCase.execute();
    setState(() {
      _appInfo = appInfo;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GreenCycle'),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _appInfo?.name ?? 'No name',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(_appInfo?.description ?? ''),
                ],
              ),
      ),
    );
  }
}
