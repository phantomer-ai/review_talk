# CHECKPOINTS_PHASE2 

# Phase 2: 핵심 기능 개발
## 크롤링 & AI 챗봇 엔진 구현

---

## 📋 **Phase 2 목표**
- ✅ 다나와 크롤링 기능을 FastAPI와 연동
- ✅ ChromaDB + OpenAI 기반 RAG 챗봇 엔진 구현
- ✅ /crawl-reviews, /chat API 엔드포인트 완성
- ✅ Postman으로 전체 API 테스트 성공

**예상 소요시간:** 105분

---

## 🕷️ **Checkpoint 2.1: 다나와 크롤러 연동**
⏱️ **45분**

### **목표**
기존 다나와 크롤링 코드를 FastAPI와 연결하여 API 엔드포인트로 만들기

### **완료 기준**
- ✅ Playwright 크롤링 함수 FastAPI에 통합
- ✅ POST /api/v1/crawl-reviews 엔드포인트 동작
- ✅ Pydantic 스키마로 요청/응답 검증
- ✅ Postman으로 실제 다나와 URL 테스트 성공

### **Cursor 명령어**
```
다나와 크롤링 기능을 FastAPI와 연동해주세요.

현재 상황:
- Phase 1에서 FastAPI 기본 구조 완성
- 기존 다나와 크롤링 코드가 Playwright 기반으로 구현됨
- 이를 FastAPI 엔드포인트로 만들어야 함

구현 내용:
1. app/models/schemas.py - Pydantic 요청/응답 스키마
2. app/infrastructure/crawler/danawa_crawler.py - 크롤링 로직
3. app/services/crawl_service.py - 크롤링 비즈니스 로직
4. app/api/routes/crawl.py - API 엔드포인트
5. app/main.py에 라우터 추가

API 스펙:
POST /api/v1/crawl-reviews
요청: {"product_url": "https://prod.danawa.com/info/?pcode=123456", "max_reviews": 20}
응답: {"success": true, "product_id": "danawa_123456", "product_name": "상품명", "total_reviews": 15, "reviews": [...]}

필요한 의존성 추가:
- playwright
- beautifulsoup4
- requests

에러 처리:
- 잘못된 URL 형식
- 크롤링 실패
- 타임아웃
- 리뷰 없음

기존 크롤링 코드를 제공하겠습니다: 
[import os
import time
import csv
import re
import openai
import chromadb
from chromadb.config import Settings
from playwright.sync_api import sync_playwright
from dotenv import load_dotenv
from sentence_transformers import SentenceTransformer
load_dotenv()


# 크롤링 함수
def crawl_reviews(url, max_reviews=1000):
    reviews = []
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page(
            user_agent="MyResearchBot/1.0 (for academic research, contact: cheonzion@gmail.com)"
        )
        page.goto(url)
        # '의견/리뷰' 탭 클릭 (텍스트로 찾기)
        try:
            opinion_tab = page.query_selector("a:has-text('의견/리뷰')")
            if opinion_tab:
                opinion_tab.click()
                time.sleep(1)
        except Exception:
            pass
        # '쇼핑몰 상품리뷰' 탭 클릭 (a.bd_ai 태그로 찾기)
        try:
            review_tab = page.query_selector("#productBlog-opinion-tab-mall")
            if review_tab:
                review_tab.click()
                time.sleep(2)
        except Exception:
            pass
        # '펼쳐보기' 버튼 반복 클릭 (설정한 횟수만큼)
        view_more_clicks = 10  # 원하는 만큼 조절
        for _ in range(view_more_clicks):
            more_btn = page.query_selector('#productBlog-opinion-mall-button-viewMore')
            if more_btn:
                span = more_btn.query_selector('span')
                if span and '펼쳐보기' in span.inner_text():
                    span.click()
                    time.sleep(2)
                else:
                    break
            else:
                break
        # 리뷰 본문 수집 (.all_review_cont가 여러 개일 수 있으므로 모두 순회)
        review_conts = page.query_selector_all('.all_review_cont')
        for cont in review_conts:
            review_ps = cont.query_selector_all('p.txt_best_rvw')
            for p in review_ps:
                text = p.inner_text().strip()
                if text:
                    reviews.append(text)
                if len(reviews) >= max_reviews:
                    break
            if len(reviews) >= max_reviews:
                break
        browser.close()
    return reviews[:max_reviews]

# 텍스트 정제 함수
def clean_text(text):
    text = str(text)
    text = text.strip()
    text = re.sub(r'\s+', ' ', text)
    text = re.sub(r'http\S+', '', text)
    text = re.sub(r'[^\w가-힣 .,!?]', '', text)
    return text

def clean_reviews(reviews, min_length=10):
    cleaned = [clean_text(r) for r in reviews]
    cleaned = list({r for r in cleaned if len(r) >= min_length})
    return cleaned

# CSV 저장 함수
def save_reviews_csv(reviews, filename):
    with open(filename, "w", encoding="utf-8", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["index", "review"])
        for idx, review in enumerate(reviews, 1):
            writer.writerow([idx, review])

# 임베딩 함수
def get_e5_multilingual_embedding(text, model_name="intfloat/multilingual-e5-small"):
    model = SentenceTransformer(model_name)
    # e5 계열은 입력 앞에 "query: " 또는 "passage: " 프리픽스 권장
    if not text.strip().startswith("query:") and not text.strip().startswith("passage:"):
        text = "query: " + text.strip()
    embedding = model.encode([text])[0]
    return embedding

# ChromaDB 저장 함수
def save_to_chromadb(reviews, collection_name="danawa_reviews"):
    client = chromadb.Client(Settings(persist_directory="./chroma_db"))
    collection = client.get_or_create_collection(collection_name)
    for idx, review in enumerate(reviews, 1):
        embedding = get_e5_multilingual_embedding(review)
        collection.add(
            documents=[review],
            embeddings=[embedding],
            ids=[str(idx)]
        )
    print(f"{len(reviews)}개의 리뷰가 ChromaDB에 저장되었습니다.")

# RAG 검색 함수
def search_chromadb(query, collection_name="danawa_reviews", top_k=3):
    client = chromadb.Client(Settings(persist_directory="./chroma_db"))
    collection = client.get_collection(collection_name)
    query_embedding = get_e5_multilingual_embedding(query)
    results = collection.query(
        query_embeddings=[query_embedding],
        n_results=top_k
    )
    return results["documents"][0]

def ask_gpt(query, context, model="gpt-3.5-turbo"):
    client = openai.OpenAI()  # api_key는 환경변수에서 자동 인식
    prompt = f"다음은 제품 리뷰입니다:\n{context}\n\n질문: {query}\n답변:"
    response = client.chat.completions.create(
        model=model,
        messages=[{"role": "user", "content": prompt}]
    )
    return response.choices[0].message.content

if __name__ == "__main__":
    url = input("다나와 리뷰 URL 입력: ")
    #url = "https://m.danawa.com/product/product.html?code=65303006&cateCode=13255594"
    reviews = crawl_reviews(url)
    cleaned = clean_reviews(reviews)
    save_reviews_csv(cleaned, "reviews_cleaned.csv")  # CSV 저장
    print(f"{len(cleaned)}개의 정제된 리뷰를 reviews_cleaned.csv 파일로 저장했습니다.")

    save_to_chromadb(cleaned)  # 임베딩 및 ChromaDB 저장

    while True:
        user_query = input("질문을 입력하세요(종료: exit): ")
        if user_query.lower() == "exit":
            break
        context = "\n".join(search_chromadb(user_query))
        answer = ask_gpt(user_query, context)
        print("챗봇 답변:", answer) ]
```

###
크롤링 HTML 셀렉터 

1. 리뷰버튼 : #productBlog-starsButton > div.text__review > span.text__number
2. 펼쳐보기 :  #productBlog-opinion-mall-button-viewMore > span
3. 리뷰 컨테이너 셀렉터 : #productBlog-opinion-mall-list-listItem-9123372001990022352 > div
4. 리뷰 텍스트 셀렉터 : #productBlog-opinion-mall-list-content-9123372001990022352
5. 별점 셀렉터 : #productBlog-opinion-mall-list-listItem-9123372001865032107 > div > div > div:nth-child(1) > div > span > span
###

### **검증 방법**
```bash
# 서버 실행
uv run dev

# Postman 테스트
POST http://localhost:8000/api/v1/crawl-reviews
Content-Type: application/json

{
  "product_url": "https://prod.danawa.com/info/?pcode=실제상품코드",
  "max_reviews": 10
}

# 응답 확인: 실제 리뷰 데이터가 수집되는지 확인
```

---

## 🤖 **Checkpoint 2.2: ChromaDB + OpenAI 연동**
⏱️ **60분**

### **목표**
ChromaDB와 OpenAI를 사용한 RAG 기반 AI 챗봇 엔진 구현

### **완료 기준**
- ✅ ChromaDB 벡터 저장소 연결
- ✅ OpenAI 임베딩 생성 및 저장
- ✅ 질문-답변 RAG 파이프라인 완성
- ✅ POST /api/v1/chat 엔드포인트 동작
- ✅ 실제 리뷰 데이터로 질문-답변 테스트 성공

### **Cursor 명령어**
```
ChromaDB와 OpenAI를 사용한 RAG 챗봇을 구현해주세요.

현재 상황:
- Checkpoint 2.1에서 크롤링 API 완성
- OpenAI API 키는 환경변수로 설정됨
- ChromaDB를 사용한 벡터 저장소 구축 필요

구현 내용:
1. app/infrastructure/ai/chroma_store.py - ChromaDB 연결 및 관리
2. app/infrastructure/ai/openai_client.py - OpenAI API 클라이언트
3. app/services/ai_service.py - RAG 비즈니스 로직
4. app/api/routes/chat.py - 채팅 API 엔드포인트
5. app/models/schemas.py에 채팅 스키마 추가

필요한 의존성 추가:
- chromadb
- openai
- langchain
- langchain-openai
- sentence-transformers

기능 구현:
1. 리뷰 텍스트를 OpenAI 임베딩으로 변환
2. ChromaDB에 임베딩 벡터 저장 (메타데이터: 상품ID, 리뷰 내용, 평점 등)
3. 사용자 질문을 임베딩으로 변환
4. ChromaDB에서 유사한 리뷰 검색 (top-k)
5. 관련 리뷰들을 컨텍스트로 OpenAI GPT에게 답변 요청

API 스펙:
POST /api/v1/chat
요청: {"product_id": "danawa_123456", "question": "배터리 지속시간이 어떤가요?"}
응답: {"success": true, "answer": "리뷰를 분석한 결과...", "confidence": 0.85, "source_reviews": [...]}

환경변수 필요:
OPENAI_API_KEY=sk-your-key-here
CHROMA_DB_PATH=./data/chroma_db
```

### **검증 방법**
```bash
# 전체 플로우 테스트
# 1. 크롤링으로 리뷰 수집
POST http://localhost:8000/api/v1/crawl-reviews
{
  "product_url": "다나와URL",
  "max_reviews": 10
}

# 2. 수집된 리뷰에 대해 질문
POST http://localhost:8000/api/v1/chat
{
  "product_id": "응답받은_product_id",
  "question": "배터리는 어때요?"
}

# 3. AI 답변이 관련 리뷰 기반으로 생성되는지 확인
```

---

## ✅ **Phase 2 완료 체크리스트**

### **크롤링 기능 확인사항**
- [ ] POST /api/v1/crawl-reviews 엔드포인트 동작
- [ ] 실제 다나와 상품 URL로 리뷰 수집 성공
- [ ] 수집된 리뷰 데이터가 구조화되어 반환됨
- [ ] 에러 상황 (잘못된 URL, 타임아웃 등) 처리됨
- [ ] Swagger 문서에서 API 스펙 확인 가능

### **AI 챗봇 확인사항**
- [ ] ChromaDB 벡터 저장소 정상 동작
- [ ] OpenAI 임베딩 생성 및 저장 성공
- [ ] POST /api/v1/chat 엔드포인트 동작
- [ ] 질문에 대해 관련 리뷰 기반 답변 생성
- [ ] 답변 품질이 합리적 수준 (리뷰 내용 반영)

### **통합 테스트 확인사항**
- [ ] 크롤링 → AI 답변 전체 플로우 동작
- [ ] 여러 다른 상품으로 테스트 성공
- [ ] API 응답 시간이 합리적 (30초 이내)
- [ ] 로그에서 각 단계별 진행 상황 확인 가능

---

## 🐛 **문제 해결 가이드**

### **크롤링 관련 문제**
```
문제: Playwright 브라우저 설치 오류
해결: uv run playwright install

문제: 다나와 페이지 구조 변경으로 크롤링 실패
해결: CSS 선택자 수정, 여러 선택자 시도

문제: 크롤링 속도 너무 느림
해결: headless 모드 사용, 불필요한 리소스 로딩 차단
```

### **AI 관련 문제**
```
문제: OpenAI API 할당량 초과
해결: .env에서 API 키 확인, 요청 횟수 제한

문제: ChromaDB 저장소 초기화 실패
해결: 데이터 폴더 권한 확인, 경로 설정 확인

문제: 임베딩 생성 너무 느림
해결: 배치 처리로 여러 텍스트 한 번에 임베딩
```

---

## 🚀 **다음 단계 준비사항**

Phase 2 완료 후 Flutter 앱 개발을 위한 준비:

1. **API 엔드포인트 정리**
   - 완성된 API 스펙을 Flutter 개발에 활용
   - Swagger 문서 URL: http://localhost:8000/docs

2. **테스트 데이터 준비**
   - 몇 개 상품의 크롤링 결과를 미리 준비
   - Flutter 개발 시 빠른 테스트를 위함

3. **CORS 설정 확인**
   - Flutter 앱에서 로컬 서버 호출 가능하도록 CORS 설정
   - 모바일 에뮬레이터 IP 주소 고려

**Phase 2 완료시 CHECKPOINT_PHASE3.md 파일을 참조하여 Flutter 앱 개발을 시작하세요.**