import 'package:dartz/dartz.dart';

import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';
import '../datasources/remote/chat_api.dart';
import '../models/chat_model.dart';

/// 채팅 리포지토리 구현
class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;
  final ChatApiDataSource _chatApiDataSource;
  final List<ChatMessage> _chatHistory = [];

  ChatRepositoryImpl({
    required this.remoteDataSource,
    required ChatApiDataSource chatApiDataSource,
  }) : _chatApiDataSource = chatApiDataSource;

  @override
  Future<Either<Failure, ChatResponseModel>> sendMessage({
    required String productId,
    required String question,
  }) async {
    try {
      final request = ChatRequestModel(
        productId: productId,
        question: question,
      );

      final result = await _chatApiDataSource.sendMessage(request);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on TimeoutException catch (e) {
      return Left(TimeoutFailure(message: e.message));
    } on JsonParsingException catch (e) {
      return Left(JsonParsingFailure(message: e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(
        GeneralFailure(message: '알 수 없는 오류가 발생했습니다: ${e.toString()}'),
      );
    }
  }

  @override
  Future<void> saveMessage(ChatMessage message) async {
    _chatHistory.add(message);
  }

  @override
  Future<List<ChatMessage>> getChatHistory({
    String? productId,
    int? limit,
  }) async {
    var history = List<ChatMessage>.from(_chatHistory);

    if (limit != null && limit > 0) {
      history = history.take(limit).toList();
    }

    return history.reversed.toList();
  }

  @override
  Future<void> clearChatHistory({String? productId}) async {
    _chatHistory.clear();
  }
}
