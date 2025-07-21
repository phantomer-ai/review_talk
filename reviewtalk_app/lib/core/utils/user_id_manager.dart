import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'app_logger.dart';
import '../constants/api_constants.dart';

class UserIdManager {
  static const _userIdKey = 'user_id';
  static final UserIdManager _instance = UserIdManager._internal();
  factory UserIdManager() => _instance;
  UserIdManager._internal();

  String? _userId;

  /// user_id를 반환. 없으면 백엔드에서 발급받아 저장
  Future<String> getUserId() async {
    if (_userId != null) return _userId!;
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString(_userIdKey);
    if (_userId != null) {
      AppLogger.d('로컬 user_id 사용: $_userId');
      return _userId!;
    }
    // 백엔드에서 발급
    try {
      final dio = Dio();
      final response = await dio.post(
        '${ApiConstants.baseUrl}/api/v1/account/guest',
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      if (response.statusCode == 201 && response.data['user_id'] != null) {
        _userId = response.data['user_id'];
        await prefs.setString(_userIdKey, _userId!);
        AppLogger.i('신규 user_id 발급 및 저장: $_userId');
        return _userId!;
      } else {
        AppLogger.e('user_id 발급 실패: ${response.data}');
        throw Exception('user_id 발급 실패');
      }
    } catch (e, s) {
      AppLogger.e('user_id 발급 네트워크 오류: $e', e, s);
      rethrow;
    }
  }

  /// 강제로 user_id 재발급 (테스트용)
  Future<String> refreshUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    _userId = null;
    return getUserId();
  }
}
