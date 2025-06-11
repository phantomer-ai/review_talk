# DB 스키마 변경 내역 (2024-06)

## 주요 변경점

1. **user 테이블 신설**
   - user_id, user_name, user_type(human/ai), created_at 컬럼 포함
   - user_type을 통해 사람과 AI를 구분

2. **conversations 테이블 구조 변경**
   - 기존 user_message, ai_response 컬럼 제거
   - message, chat_user_id, created_at 등으로 통합
   - chat_user_id는 user 테이블의 user_id를 참조하며, 대화 참여자(사람/AI 모두 포함)를 식별
   - related_review_ids: 관련 리뷰 ID 목록(쉼표 구분)

## chat_user_id 네이밍
- 대화 참여자(사람/AI 모두 포함)의 식별자라는 의미로 chat_user_id를 사용
- user_id, participant_id 등도 고려할 수 있으나, chat_user_id가 의도를 가장 명확히 드러냄

## 설계 의도
- 대화 메시지를 단일 테이블에 저장하고, 발화 주체를 chat_user_id로 구분
- user 테이블에서 사람/AI 구분 및 이름 관리
- 확장성 및 추후 통계/분석 용이성 확보 