/// 앱 전체에서 사용하는 문자열 상수
class AppStrings {
  AppStrings._();

  // 앱 기본 정보
  static const String appName = 'ReviewTalk';
  static const String appDescription = 'AI가 분석하는 스마트 리뷰 채팅';

  // 공통 버튼
  static const String confirm = '확인';
  static const String cancel = '취소';
  static const String close = '닫기';
  static const String retry = '다시 시도';
  static const String back = '뒤로';
  static const String next = '다음';
  static const String complete = '완료';
  static const String save = '저장';
  static const String delete = '삭제';
  static const String edit = '편집';
  static const String copy = '복사';
  static const String share = '공유';

  // URL 입력 화면
  static const String urlInputTitle = '상품 URL 입력';
  static const String urlInputSubtitle = '다나와 상품 링크를 입력하시면\nAI가 리뷰를 분석해드려요!';
  static const String urlInputHint = '다나와 상품 URL을 입력하세요';
  static const String urlInputPlaceholder =
      'https://prod.danawa.com/info/?pcode=...';
  static const String urlInputButton = '리뷰 분석 시작';
  static const String urlInputValidationEmpty = '다나와 상품 URL을 입력해주세요';
  static const String urlInputValidationInvalid =
      '올바른 다나와 상품 URL을 입력해주세요\n예: https://prod.danawa.com/info/?pcode=1234567';
  static const String urlInputExampleTitle = '지원하는 URL 형식:';
  static const String urlInputExample1 = '• prod.danawa.com/info/?pcode=...';
  static const String urlInputExample2 = '• shop.danawa.com/...';
  static const String urlInputExample3 = '• danawa.com/product/...';

  // 최근 검색 기록
  static const String recentSearchTitle = '최근 검색한 상품';
  static const String recentSearchEmpty = '최근 검색 기록이 없습니다';
  static const String recentSearchClear = '기록 삭제';
  static const String recentSearchClearConfirm = '모든 검색 기록을 삭제하시겠습니까?';

  // 리뷰 수량 설정
  static const String maxReviewsTitle = '분석할 리뷰 수';
  static const String maxReviewsDescription = '더 많은 리뷰를 분석할수록 정확해져요';

  // 로딩 화면
  static const String loadingTitle = '리뷰 분석 중...';
  static const String loadingPreparing = '리뷰 수집을 준비하고 있습니다...';
  static const String loadingFetchingProduct = '상품 정보를 가져오고 있습니다...';
  static const String loadingCollectingReviews = '리뷰를 수집하고 있습니다...';
  static const String loadingAnalyzing = 'AI가 리뷰를 분석하고 있습니다...';
  static const String loadingCompleting = '분석을 완료하고 있습니다...';
  static const String loadingComplete = '완료!';
  static const String loadingCancel = '취소';
  static const String loadingCancelConfirm = '리뷰 분석을 취소하시겠습니까?';

  // 채팅 화면
  static const String chatTitle = 'AI 채팅';
  static const String chatWelcomeTitle = '안녕하세요! 👋';
  static const String chatWelcomeMessage = '수집된 리뷰를 기반으로\n궁금한 것을 물어보세요!';
  static const String chatInputHint = '궁금한 점을 물어보세요...';
  static const String chatInputSend = '전송';
  static const String chatClearTitle = '채팅 기록 삭제';
  static const String chatClearMessage = '모든 채팅 기록을 삭제하시겠습니까?';
  static const String chatRetry = '재전송';
  static const String chatCopy = '복사';

  // 추천 질문
  static const String suggestedQuestionsTitle = '추천 질문';
  static const List<String> suggestedQuestions = [
    '이 상품의 장점은 무엇인가요?',
    '단점이나 주의사항이 있나요?',
    '가격 대비 어떤가요?',
    '다른 제품과 비교했을 때 어떤가요?',
    '구매를 추천하시나요?',
    '배송이나 포장은 어떤가요?',
    'A/S나 품질은 어떤가요?',
    '실제 사용해보신 분들 후기는?',
  ];

  // 에러 메시지
  static const String errorGeneral = '오류가 발생했습니다';
  static const String errorNetwork = '네트워크 연결을 확인해주세요';
  static const String errorTimeout = '요청 시간이 초과되었습니다';
  static const String errorServer = '서버에 문제가 발생했습니다';
  static const String errorUnknown = '알 수 없는 오류가 발생했습니다';
  static const String errorRetry = '다시 시도해주세요';

  // 성공 메시지
  static const String successAnalysisComplete = '리뷰 분석이 완료되었습니다!';
  static const String successCopyMessage = '메시지가 복사되었습니다';

  // 신뢰도 관련
  static const String confidenceLow = '이 답변은 확실하지 않습니다';
  static const String confidenceHigh = '높은 신뢰도의 답변입니다';
  static const String sourceReviews = '참고한 리뷰';

  // 접근성
  static const String semanticUrlInput = '상품 URL 입력 필드';
  static const String semanticSendButton = '메시지 전송 버튼';
  static const String semanticChatMessage = '채팅 메시지';
  static const String semanticLoadingIndicator = '로딩 인디케이터';
  static const String semanticBackButton = '뒤로가기 버튼';
}
