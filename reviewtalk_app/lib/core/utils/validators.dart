/// 유효성 검사를 위한 유틸리티 클래스
class Validators {
  /// 다나와 URL 유효성 검사
  static bool isDanawaUrl(String url) {
    if (url.isEmpty) return false;

    // 다나와 URL 패턴 확인
    final danawaPatterns = [
      r'https?://prod\.danawa\.com/info/\?pcode=\d+',
      r'https?://www\.danawa\.com/product/\?productSeq=\d+',
      r'https?://danawa\.com/info/\?pcode=\d+',
    ];

    for (String pattern in danawaPatterns) {
      if (RegExp(pattern).hasMatch(url)) {
        return true;
      }
    }

    return false;
  }

  /// URL 기본 유효성 검사
  static bool isValidUrl(String url) {
    if (url.isEmpty) return false;

    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// 빈 문자열 검사
  static bool isNotEmpty(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  /// 최소 길이 검사
  static bool hasMinLength(String? value, int minLength) {
    return value != null && value.length >= minLength;
  }

  /// 최대 길이 검사
  static bool hasMaxLength(String? value, int maxLength) {
    return value != null && value.length <= maxLength;
  }

  /// 질문 유효성 검사
  static String? validateQuestion(String? question) {
    if (!isNotEmpty(question)) {
      return '질문을 입력해주세요.';
    }

    if (!hasMinLength(question, 2)) {
      return '질문은 최소 2글자 이상 입력해주세요.';
    }

    if (!hasMaxLength(question, 500)) {
      return '질문은 최대 500글자까지 입력 가능합니다.';
    }

    return null;
  }

  /// 다나와 URL 유효성 검사 (에러 메시지 포함)
  static String? validateDanawaUrl(String? url) {
    if (!isNotEmpty(url)) {
      return '상품 URL을 입력해주세요.';
    }

    if (!isValidUrl(url!)) {
      return '올바른 URL 형식이 아닙니다.';
    }

    if (!isDanawaUrl(url)) {
      return '다나와 상품 URL을 입력해주세요.\n예: https://prod.danawa.com/info/?pcode=123456';
    }

    return null;
  }
}
