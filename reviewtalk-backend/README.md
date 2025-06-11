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
