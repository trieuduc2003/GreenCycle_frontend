class AppService {
  Future<Map<String, dynamic>> fetchAppInfo() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));

    return {
      'name': 'GreenCycle',
      'description': 'A Flutter app structured with separated domain and service layers.',
    };
  }
}
