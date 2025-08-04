import 'package:network_info_plus/network_info_plus.dart';
import 'package:http/http.dart' as http;

/// 네트워크에서 백엔드 서버를 자동으로 찾는 서비스
class ServerDiscovery {
  static const int serverPort = 8000;
  static const Duration timeout = Duration(seconds: 2);

  /// 현재 네트워크에서 서버를 찾아서 기본 URL 반환
  static Future<String> discoverServer() async {
    try {
      print('🔍 서버 자동 탐지 시작...');

      // 1. 먼저 localhost 시도 (개발용)
      if (await testConnection('http://localhost:$serverPort')) {
        print('✅ localhost 서버 발견');
        return 'http://localhost:$serverPort';
      }

      // 2. 현재 Wi-Fi IP 가져오기
      final networkInfo = NetworkInfo();
      final wifiIP = await networkInfo.getWifiIP();

      if (wifiIP != null) {
        print('📱 현재 디바이스 IP: $wifiIP');

        // 3. 같은 서브넷에서 서버 스캔
        final baseIP = _getBaseIP(wifiIP);
        if (baseIP != null) {
          print('🌐 서브넷 스캔 시작: $baseIP.x');

          final serverIP = await _scanSubnet(baseIP);
          if (serverIP != null) {
            print('✅ 서버 발견: $serverIP');
            return 'http://$serverIP:$serverPort';
          }
        }
      }

      // 4. 공통 개발 IP들 시도
      final commonIPs = [
        '192.168.1.1', // 일반적인 라우터 IP
        '192.168.0.1', // 일반적인 라우터 IP
        '10.0.0.1', // 일부 라우터
        '192.168.35.239', // 이전에 사용했던 IP
        '192.168.35.156', // 최근 IP
      ];

      for (String ip in commonIPs) {
        if (await testConnection('http://$ip:$serverPort')) {
          print('✅ 공통 IP에서 서버 발견: $ip');
          return 'http://$ip:$serverPort';
        }
      }

      print('❌ 서버를 찾을 수 없음, localhost 사용');
      return 'http://localhost:$serverPort';
    } catch (e) {
      print('❌ 서버 탐지 오류: $e');
      return 'http://localhost:$serverPort';
    }
  }

  /// 특정 URL로 서버 연결 테스트
  static Future<bool> testConnection(String url) async {
    try {
      final response = await http
          .get(Uri.parse('$url/health'))
          .timeout(timeout);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// IP 주소에서 기본 서브넷 추출 (예: 192.168.1.100 -> 192.168.1)
  static String? _getBaseIP(String ip) {
    final parts = ip.split('.');
    if (parts.length == 4) {
      return '${parts[0]}.${parts[1]}.${parts[2]}';
    }
    return null;
  }

  /// 서브넷 스캔 (192.168.1.1~192.168.1.254)
  static Future<String?> _scanSubnet(String baseIP) async {
    final List<Future<String?>> futures = [];

    // 일반적으로 서버가 있을만한 IP들을 우선 검사
    final priorityIPs = [1, 100, 101, 102, 103, 200, 201, 254];

    for (int ip in priorityIPs) {
      futures.add(_checkIP('$baseIP.$ip'));
    }

    // 병렬로 검사하여 첫 번째로 응답하는 서버 반환
    try {
      final results = await Future.wait(futures);

      for (String? result in results) {
        if (result != null) {
          return result;
        }
      }
    } catch (e) {
      print('서브넷 스캔 오류: $e');
    }

    return null;
  }

  /// 개별 IP 확인
  static Future<String?> _checkIP(String ip) async {
    if (await testConnection('http://$ip:$serverPort')) {
      return ip;
    }
    return null;
  }
}
