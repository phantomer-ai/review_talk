# ReviewTalk 프로젝트 개요 (최신)

## 주요 DB 구조 및 관계

- **user**: 사용자 및 AI 식별
- **products**: 상품 정보
- **chat_room**: 사용자별 상품별 채팅방 (user_id + product_id = unique)
- **conversations**: 각 채팅방의 대화 메시지
- **reviews**: 상품 리뷰

### chat_room 테이블
| 컬럼명      | 타입      | 설명                         |
| ----------- | --------- | ---------------------------- |
| id          | INTEGER   | PK, 채팅방 고유 ID           |
| user_id     | TEXT      | FK, 채팅방 소유자(사용자)    |
| product_id  | INTEGER   | FK, 상품 ID                  |
| created_at  | TIMESTAMP | 생성일시                     |

- user_id + product_id 조합이 unique (한 사용자의 한 상품별 1개 채팅방)
- conversations는 chat_room_id로 연결됨

### ERD (요약)
- user 1:N chat_room
- products 1:N chat_room
- chat_room 1:N conversations

---

## ChatRoom API 명세

### 1. 채팅방 생성
- **POST** `/api/v1/chat-rooms/`
- body 예시:
```json
{
  "user_id": "user1",
  "product_id": 123
}
```
- 응답 예시:
```json
{
  "id": 1,
  "user_id": "user1",
  "product_id": 123,
  "created_at": "2024-06-20T12:34:56"
}
```

### 2. 사용자별 채팅방 목록 조회
- **GET** `/api/v1/chat-rooms/?user_id=user1`
- 응답 예시:
```json
{
  "chat_rooms": [
    {"id": 1, "user_id": "user1", "product_id": 123, "created_at": "..."},
    {"id": 2, "user_id": "user1", "product_id": 456, "created_at": "..."}
  ]
}
```

### 3. 단일 채팅방 조회
- **GET** `/api/v1/chat-rooms/{chat_room_id}`

### 4. 채팅방 삭제
- **DELETE** `/api/v1/chat-rooms/{chat_room_id}`

---

## 활용 예시 및 정책
- 한 사용자는 상품별로 1개의 chat_room만 생성 가능
- 대화(conversations)는 반드시 chat_room_id를 통해 연결
- user_id로 본인 채팅방 전체 조회 가능 (개인화)

---

## 기타
- 자세한 ERD 및 테이블 구조는 ERD.md 참고
- 기존 대화/AI/리뷰 기능과 연동됨 