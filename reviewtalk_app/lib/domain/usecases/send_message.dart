import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../core/error/failures.dart';
import '../../data/models/chat_model.dart';
import '../repositories/chat_repository.dart';

/// 메시지 전송 유스케이스
class SendMessage {
  final ChatRepository repository;

  SendMessage(this.repository);

  /// 메시지 전송 실행
  Future<Either<Failure, ChatResponseModel>> call(
    SendMessageParams params,
  ) async {
    return await repository.sendMessage(
      productId: params.productId,
      question: params.question,
    );
  }
}

/// 메시지 전송 파라미터
class SendMessageParams extends Equatable {
  final String productId;
  final String question;

  const SendMessageParams({required this.productId, required this.question});

  @override
  List<Object> get props => [productId, question];

  @override
  String toString() {
    return 'SendMessageParams(productId: $productId, question: $question)';
  }
}
