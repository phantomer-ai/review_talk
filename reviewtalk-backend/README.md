---

## Loguru 기반 로깅 안내

- 본 프로젝트는 Python 표준 print/logging 대신 [loguru](https://github.com/Delgan/loguru) 기반의 고급 로깅을 사용합니다.
- 모든 주요 서비스/크롤러/AI 모듈에서 logger.info, logger.error, logger.warning 등으로 로그를 남깁니다.
- 로그는 시간, 레벨, 메시지, 예외 등 글로벌 표준 포맷으로 출력됩니다.

### 주요 사용 예시
```python
from loguru import logger
logger.info("정상 처리 메시지")
logger.error("에러 발생: {}", error)
logger.warning("경고: {}", warning)
```

### 로그 레벨 및 포맷
- 로그 레벨: DEBUG, INFO, WARNING, ERROR, CRITICAL
- 기본 포맷: 시간 | 레벨 | 메시지 | 예외

### 커스텀 설정 예시
```python
from loguru import logger
logger.add("logs/app.log", rotation="10 MB", retention="7 days", level="INFO")
```

- 자세한 설정 및 활용법은 [공식 문서](https://loguru.readthedocs.io/en/stable/) 참고

## ChatRoom(채팅방) 기능 요약

- **chat_room 테이블**: 사용자(user_id)와 상품(product_id) 조합별 1개 채팅방 생성 (중복 불가)
- **conversations**: 각 채팅방(chat_room_id)별 대화 메시지 저장
- **주요 엔드포인트**
    - POST `/api/v1/chat-rooms/` : 채팅방 생성
    - GET `/api/v1/chat-rooms/?user_id=...` : 사용자별 채팅방 목록 조회
    - GET `/api/v1/chat-rooms/{chat_room_id}` : 단일 채팅방 조회
    - DELETE `/api/v1/chat-rooms/{chat_room_id}` : 채팅방 삭제

### 예시
- 채팅방 생성 요청:
```json
{
  "user_id": "user1",
  "product_id": 123
}
```
- 목록 조회 응답:
```json
{
  "chat_rooms": [
    {"id": 1, "user_id": "user1", "product_id": 123, "created_at": "..."}
  ]
}
```

- 한 사용자는 상품별로 1개의 chat_room만 생성 가능
- user_id로 본인 채팅방 전체 조회 가능 (개인화)
