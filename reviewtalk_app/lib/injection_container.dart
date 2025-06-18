import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'core/network/api_client.dart';
import 'core/constants/api_constants.dart';

// 새로운 데이터 레이어 imports
import 'data/datasources/remote/review_api.dart';
import 'data/datasources/remote/chat_api.dart';
import 'data/repositories/review_repository_impl.dart';
import 'data/repositories/chat_repository_impl.dart';
import 'domain/repositories/review_repository.dart';
import 'domain/repositories/chat_repository.dart';

// 새로운 UseCase imports
import 'domain/usecases/crawl_reviews.dart';
import 'domain/usecases/send_message.dart';

// ViewModel imports
import 'presentation/viewmodels/url_input_viewmodel.dart';
import 'presentation/viewmodels/chat_viewmodel.dart';

// 기존 채팅 관련 imports
import 'data/datasources/chat_remote_datasource.dart';
import 'domain/usecases/get_chat_history.dart';

/// 의존성 주입 컨테이너
final GetIt sl = GetIt.instance;

/// 의존성 주입 초기화
Future<void> init() async {
  // =============================================
  // External dependencies
  // =============================================
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // Dio 클라이언트 설정
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl, // 환경변수 기반 baseUrl 사용
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );
  sl.registerLazySingleton(() => dio);

  // =============================================
  // Core
  // =============================================
  sl.registerLazySingleton(() => ApiClient());

  // =============================================
  // Data sources
  // =============================================
  // 새로운 API 데이터 소스들
  sl.registerLazySingleton<ReviewApiDataSource>(
    () => ReviewApiDataSourceImpl(apiClient: sl()),
  );

  sl.registerLazySingleton<ChatApiDataSource>(
    () => ChatApiDataSourceImpl(apiClient: sl()),
  );

  // 기존 채팅 데이터 소스
  sl.registerLazySingleton<ChatRemoteDataSource>(
    () => ChatRemoteDataSourceImpl(dio: sl()),
  );

  // =============================================
  // Repositories
  // =============================================
  // 새로운 리포지토리들
  sl.registerLazySingleton<ReviewRepository>(
    () => ReviewRepositoryImpl(reviewApiDataSource: sl()),
  );

  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(remoteDataSource: sl(), chatApiDataSource: sl()),
  );

  // =============================================
  // Use cases
  // =============================================
  // 새로운 UseCase들
  sl.registerLazySingleton(() => CrawlReviews(sl()));
  sl.registerLazySingleton(() => SendMessage(sl()));

  // 기존 UseCase들
  sl.registerLazySingleton(() => GetChatHistory(sl()));

  // =============================================
  // ViewModels
  // =============================================
  // 새로운 ViewModel들
  sl.registerFactory(() => UrlInputViewModel(crawlReviews: sl(), prefs: sl()));

  sl.registerFactory(() => ChatViewModel(sendMessage: sl()));
}
