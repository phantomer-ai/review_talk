# ERD (Entity Relationship Diagram)

## ReviewTalk DB 구조 (최신)

```mermaid
erDiagram
    USER {
        int id PK
        string user_id UK
        string user_name
        string user_type
        timestamp created_at
    }
    PRODUCTS {
        int id PK
        string name
        string url UK
        timestamp created_at
    }
    CHAT_ROOM {
        int id PK
        string user_id FK "채팅방 소유자(사람) user_id"
        int product_id FK
        timestamp created_at
    }
    REVIEWS {
        int id PK
        int product_id FK
        string review_id UK
        string content
        int rating
        string author
        string date
        timestamp created_at
    }
    CONVERSATIONS {
        int id PK
        int chat_room_id FK "채팅방 ID"
        string message
        string chat_user_id FK "메시지 작성자(사람/AI)"
        string related_review_ids
        timestamp created_at
    }

    PRODUCTS ||--o{ REVIEWS : has
    PRODUCTS ||--o{ CHAT_ROOM : has
    USER ||--o{ CHAT_ROOM : owns
    CHAT_ROOM ||--o{ CONVERSATIONS : has
    USER ||--o{ CONVERSATIONS : writes
    REVIEWS ||--o{ CONVERSATIONS : referenced_in
```

## 설명
- USER: 사람/AI 모두 포함, user_type으로 구분
- CONVERSATIONS: user_id(대화 주체, 실제 사용자), chat_user_id(메시지 작성자, 사람/AI), 관련 리뷰 ID, 생성일 등 저장
- PRODUCTS, REVIEWS: 기존과 동일
- user_id + product_id 조합으로 대화 캐시 및 조회 