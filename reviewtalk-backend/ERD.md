# ERD (Entity Relationship Diagram)

## ReviewTalk DB 구조

```mermaid
%%{init: {'theme': 'neutral'}}%%
erDiagram
    USER {
        INTEGER id PK
        TEXT user_id UNIQUE
        TEXT user_name
        TEXT user_type (human|ai)
        TIMESTAMP created_at
    }
    PRODUCTS {
        INTEGER id PK
        TEXT name
        TEXT url UNIQUE
        TIMESTAMP created_at
    }
    REVIEWS {
        INTEGER id PK
        INTEGER product_id FK
        TEXT review_id UNIQUE
        TEXT content
        INTEGER rating
        TEXT author
        TEXT date
        TIMESTAMP created_at
    }
    CONVERSATIONS {
        INTEGER id PK
        INTEGER product_id FK
        TEXT message
        TEXT chat_user_id FK
        TEXT related_review_ids
        TIMESTAMP created_at
    }

    PRODUCTS ||--o{ REVIEWS : "has"
    PRODUCTS ||--o{ CONVERSATIONS : "has"
    USER ||--o{ CONVERSATIONS : "participates"
    REVIEWS ||--o{ CONVERSATIONS : "referenced in"
```

## 설명
- USER: 사람/AI 모두 포함, user_type으로 구분
- CONVERSATIONS: message, chat_user_id(=user.user_id), 관련 리뷰 ID, 생성일 등 저장
- PRODUCTS, REVIEWS: 기존과 동일 