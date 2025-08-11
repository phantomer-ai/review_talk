import '../../data/models/chat_model.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/usecases/send_message.dart';
import '../../domain/usecases/get_chat_history.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../core/utils/user_id_manager.dart';
import '../../core/utils/app_logger.dart';
import 'base_viewmodel.dart';

/// 채팅 화면 ViewModel
class ChatViewModel extends BaseViewModel {
  final SendMessage _sendMessage;
  final GetChatHistory _getChatHistory;
  final ChatRepository _chatRepository;

  ChatViewModel({
    required SendMessage sendMessage,
    required GetChatHistory getChatHistory,
    required ChatRepository chatRepository,
  }) : _sendMessage = sendMessage,
       _getChatHistory = getChatHistory,
       _chatRepository = chatRepository;

  // 현재 상품 정보
  String? _productId;
  String? get productId => _productId;

  String? _productName;
  String? get productName => _productName;

  // 채팅 메시지 리스트
  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  // 메시지 입력 상태
  String _currentMessage = '';
  String get currentMessage => _currentMessage;

  // 추천 질문들
  static const List<String> _suggestedQuestions = [
    '이 상품의 장점은 무엇인가요?',
    '단점이나 주의사항이 있나요?',
    '가격 대비 어떤가요?',
    '다른 제품과 비교했을 때 어떤가요?',
    '구매를 추천하시나요?',
    '배송이나 포장은 어떤가요?',
    'A/S나 품질은 어떤가요?',
  ];

  List<String> get suggestedQuestions => _suggestedQuestions;

  // 채팅이 처음 시작되었는지 여부
  bool get isFirstMessage => _messages.isEmpty;

  /// 채팅 초기화 (상품 정보 설정 및 기록 로드)
  Future<void> initializeChat({
    required String productId,
    required String productName,
  }) async {
    _productId = productId;
    _productName = productName;
    _messages.clear();
    clearAllMessages();

    // 기존 채팅 기록 로드 시도
    await _loadChatHistory();

    // 기록이 없으면 환영 메시지 추가
    if (_messages.isEmpty) {
      final welcomeMessage = ChatMessage.ai(
        content:
            '안녕하세요! $_productName에 대해 궁금한 점을 물어보세요. '
            '실제 구매자들의 리뷰를 분석해서 답변드릴게요! 😊',
      );

      _messages.add(welcomeMessage);
    }

    notifyListeners();
  }

  /// 채팅 기록 로드
  Future<void> _loadChatHistory() async {
    if (_productId == null) return;

    try {
      final userId = await UserIdManager().getUserId();
      final params = GetChatHistoryParams(
        userId: userId,
        productId: _productId,
        limit: 50, // 최근 50개 메시지
      );

      final history = await _getChatHistory(params);

      if (history.isNotEmpty) {
        _messages.addAll(history);
        // 채팅 기록이 있으면 상태 메시지 추가
        final resumeMessage = ChatMessage.ai(
          content: '이전 대화를 불러왔습니다. 계속해서 질문해주세요! 😊',
        );
        _messages.add(resumeMessage);
      }
    } catch (e) {
      // 기록 로드 실패 시 로그만 남기고 계속 진행
      AppLogger.e('[ChatViewModel] 채팅 기록 로드 실패', e);
    }
  }

  /// 메시지 입력 텍스트 업데이트
  void updateMessageText(String text) {
    _currentMessage = text.trim();
    notifyListeners();
  }

  /// 메시지 전송 가능 여부
  bool get canSendMessage =>
      _currentMessage.isNotEmpty && !isLoading && _productId != null;

  /// 메시지 전송
  Future<void> sendMessage([String? messageText]) async {
    final message = messageText ?? _currentMessage;

    if (message.isEmpty || _productId == null) {
      setError('메시지를 입력해주세요');
      return;
    }

    // 사용자 메시지 추가
    final userMessage = ChatMessage.user(content: message);
    _addMessage(userMessage);

    // 입력창 초기화
    if (messageText == null) {
      _currentMessage = '';
      notifyListeners();
    }

    // AI 응답 요청
    final result = await executeWithLoading<ChatResponseModel>(() async {
      final params = SendMessageParams(
        productId: _productId!,
        question: message,
      );

      final result = await _sendMessage(params);

      return result.fold(
        (failure) => throw Exception(failure.message),
        (success) => success,
      );
    }, errorPrefix: 'AI 응답 요청 실패');

    if (result != null) {
      // 사용자 메시지 상태 업데이트 (전송 완료)
      _updateMessageStatus(userMessage.id, ChatMessageStatus.sent);

      // AI 응답 메시지 추가
      final aiMessage = ChatMessage.ai(
        content: result.aiResponse,
        sourceReviews:
            result.sourceReviews.map((review) => review.document).toList(),
      );

      _addMessage(aiMessage);
    } else {
      // 사용자 메시지 상태 업데이트 (에러)
      _updateMessageStatus(userMessage.id, ChatMessageStatus.error);
    }
  }

  /// 추천 질문 선택
  Future<void> selectSuggestedQuestion(String question) async {
    await sendMessage(question);
  }

  /// 메시지 재전송
  Future<void> retryMessage(String messageId) async {
    final messageIndex = _messages.indexWhere((msg) => msg.id == messageId);
    if (messageIndex == -1) return;

    final message = _messages[messageIndex];
    if (!message.isUser) return;

    // 메시지 상태를 전송 중으로 변경
    _updateMessageStatus(messageId, ChatMessageStatus.sending);

    // 재전송
    await sendMessage(message.content);
  }

  /// productId 명시적 초기화 (chat 화면 벗어날 때 호출)
  void clearProductId() {
    _productId = null;
    _productName = null;
    notifyListeners();
  }

  /// 채팅 기록 삭제
  Future<void> clearChat() async {
    _messages.clear();
    clearAllMessages();

    // Repository의 캐시도 정리
    if (_productId != null) {
      await _chatRepository.clearChatHistory(productId: _productId);
    }

    if (_productName != null) {
      // 환영 메시지 다시 추가
      final welcomeMessage = ChatMessage.ai(
        content: '채팅이 초기화되었습니다. $_productName에 대해 다시 질문해주세요! 😊',
      );
      _messages.add(welcomeMessage);
    }

    notifyListeners();
  }

  /// 메시지 추가
  void _addMessage(ChatMessage message) {
    _messages.add(message);

    // Repository 캐시에도 메시지 저장 (비동기이지만 UI 업데이트와 분리)
    _chatRepository.saveMessage(message).catchError((e) {
      AppLogger.e('[ChatViewModel] 메시지 캐시 저장 실패', e);
    });

    notifyListeners();
  }

  /// 메시지 상태 업데이트
  void _updateMessageStatus(String messageId, ChatMessageStatus status) {
    final index = _messages.indexWhere((msg) => msg.id == messageId);
    if (index != -1) {
      _messages[index] = _messages[index].copyWith(status: status);
      notifyListeners();
    }
  }

  /// 특정 신뢰도 이하의 응답인지 확인
  bool isLowConfidenceResponse(ChatMessage message) {
    return !message.isUser &&
        message.confidence != null &&
        message.confidence! < 0.6;
  }

  /// 메시지에 소스 리뷰가 있는지 확인
  bool hasSourceReviews(ChatMessage message) {
    return !message.isUser &&
        message.sourceReviews != null &&
        message.sourceReviews!.isNotEmpty;
  }
}
