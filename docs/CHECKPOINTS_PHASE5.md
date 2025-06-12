# CHECKPOINTS_PHASE5 

# Phase 5: 배포 준비
## Railway 백엔드 배포 & APK 빌드

---

## 📋 **Phase 5 목표**
- ✅ Railway에 FastAPI 백엔드 배포
- ✅ 프로덕션 환경변수 설정
- ✅ Flutter APK 빌드 및 테스트
- ✅ 최종 데모 준비 완료

**예상 소요시간:** 45분

---

## 🚂 **Checkpoint 5.1: Railway 백엔드 배포**
⏱️ **25분**

### **목표**
FastAPI 서버를 Railway에 배포하여 프로덕션 환경에서 동작시키기

### **완료 기준**
- ✅ Railway에 백엔드 배포 성공
- ✅ 프로덕션 환경변수 설정 완료
- ✅ 배포된 API가 정상 동작
- ✅ HTTPS 도메인으로 접근 가능

### **Cursor 명령어**
```
FastAPI 백엔드를 Railway에 배포해주세요.

현재 상황:
- 로컬에서 FastAPI 서버 정상 동작 확인
- uv 기반 pyproject.toml 프로젝트 구조
- OpenAI API 키 등 환경변수 사용 중

구현 내용:
1. Railway 배포 설정
   - railway.json 또는 Procfile 생성 (필요시)
   - PORT 환경변수 대응
   - 프로덕션용 uvicorn 설정

2. 환경변수 프로덕션 설정
   - OPENAI_API_KEY (실제 키 값)
   - CORS_ORIGINS (프로덕션 도메인 포함)
   - DATABASE_URL (Railway PostgreSQL)
   - 기타 필요한 설정들

3. 데이터베이스 설정
   - Railway PostgreSQL 서비스 추가
   - SQLAlchemy를 사용한다면 마이그레이션 설정
   - ChromaDB 데이터 저장소 설정

4. 프로덕션 최적화
   - 로그 레벨 설정
   - 에러 처리 강화
   - 보안 헤더 추가
   - CORS 설정 최적화

Railway 배포 단계:
1. GitHub에 코드 푸시
2. Railway 프로젝트 생성
3. GitHub 저장소 연결
4. 환경변수 설정
5. 자동 배포 대기
6. 도메인 확인 및 API 테스트

배포 후 확인사항:
- https://your-app.railway.app/health 접속 가능
- https://your-app.railway.app/docs Swagger 문서 확인
- API 엔드포인트들이 정상 응답
- 로그에서 에러 없음 확인

주의사항:
- OpenAI API 키가 올바르게 설정되었는지 확인
- Playwright 브라우저