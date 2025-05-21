import csv
from playwright.sync_api import sync_playwright, TimeoutError
import time
import random

def main():
    with sync_playwright() as p:
        # 브라우저 설정
        browser = p.chromium.launch(
            headless=False,  # 브라우저 표시
            args=[
                '--disable-blink-features=AutomationControlled',
                '--disable-features=IsolateOrigins,site-per-process',
            ]
        )
        
        # 컨텍스트 설정 (모바일 User-Agent 사용)
        context = browser.new_context(
            viewport={'width': 390, 'height': 844},  # iPhone 12 Pro 크기
            user_agent='Mozilla/5.0 (iPhone; CPU iPhone OS 14_7_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.2 Mobile/15E148 Safari/604.1'
        )
        
        page = context.new_page()
        
        try:
            # 스마트스토어 모바일 페이지 바로 접속
            print("상품 페이지로 이동 중...")
            response = page.goto('https://smartstore.naver.com/superliving/products/9681861927', wait_until='networkidle')
            
            if response.ok:
                print("페이지 로딩 완료")
                print("현재 페이지 URL:", page.url)
                print("페이지 제목:", page.title())
                
                # 리뷰 탭이 나타날 때까지 대기
                try:
                    print("리뷰 탭 찾는 중...")
                    review_button = page.wait_for_selector('text=리뷰 보기', state='visible', timeout=20000)
                    if review_button:
                        print("리뷰 탭 발견, 클릭 시도...")
                        # 새 창(팝업) 대기 및 열기
                        with context.expect_page() as new_page_info:
                            review_button.click()
                        new_page = new_page_info.value
                        new_page.wait_for_load_state('domcontentloaded')
                        time.sleep(3)  # 팝업 로딩 대기
                        print("리뷰 팝업 창으로 전환 완료!")
                        # 리뷰 더보기 및 스크롤 반복
                        print("리뷰 더보기 및 스크롤 시작...")
                        for i in range(10):  # 반복으로 크롤링 데이터 수 조절 
                            # 마우스 휠로 스크롤
                            print(f"[{i+1}] 마우스 휠로 스크롤 중...")
                            for _ in range(20):
                                new_page.mouse.wheel(0, random.randint(250, 400))
                                time.sleep(random.uniform(0.8, 1.3))
                            
                            # '리뷰 더보기' 버튼 클릭 (여러 셀렉터 시도)
                            print(f"[{i+1}] '리뷰 더보기' 버튼 클릭 시도...")
                            selectors = [
                                'button._2cXtBROVbI',
                                'button:has-text("더보기")',
                                
                            ]
                            more_btn = None
                            for sel in selectors:
                                try:
                                    more_btn = new_page.wait_for_selector(sel, state='visible', timeout=2000)
                                    if more_btn:
                                        break
                                except TimeoutError:
                                    continue
                            if more_btn and more_btn.is_enabled():
                                more_btn.click()
                                print(f"[{i+1}] 리뷰 더보기 버튼 클릭 성공!")
                                time.sleep(3)
                            else:
                                print(f"[{i+1}] 리뷰 더보기 버튼을 찾지 못했거나 비활성화 상태입니다.")
                        
                        print("모든 리뷰 더보기 및 스크롤 완료!")
                        # 리뷰 데이터 크롤링 및 CSV 저장
                        print("리뷰 데이터 추출 및 CSV 저장 시작...")
                        review_data = []
                        reviews = new_page.query_selector_all('li._3nWgq8R6iy')
                        for review in reviews:
                            try:
                                # 리뷰 ID
                                review_id = review.get_attribute('id')
                                # 작성자 이름
                                author_name_elem = review.query_selector('strong._2Lwq_wRkPQ')
                                author_name = author_name_elem.inner_text() if author_name_elem else ""
                                # 작성자 프로필 이미지
                                author_img_elem = review.query_selector('img.zKddRPX3pR')
                                author_img_url = author_img_elem.get_attribute('src') if author_img_elem else ""
                                # 평점
                                rating_elem = review.query_selector('em._2QH91COWR1')
                                rating = rating_elem.inner_text() if rating_elem else ""
                                # # 작성 날짜
                                date_elem = review.query_selector('span._2Lwq_wRkPQ + span')
                                date = date_elem.inner_text() if date_elem else ""
                                # # 상품 옵션
                                product_option_elem = review.query_selector('span._13fI3LSPbq')
                                product_option_text = product_option_elem.inner_text() if product_option_elem else ""
                                # # 구매자 정보 (dt, dd 쌍을 문자열로)
                                buyer_info_elements = review.query_selector_all('dl.mlHbISIEB2 dt, dl.mlHbISIEB2 dd')
                                buyer_info_list = []
                                for i in range(0, len(buyer_info_elements), 2):
                                    if i + 1 < len(buyer_info_elements):
                                        key = buyer_info_elements[i].inner_text()
                                        value = buyer_info_elements[i + 1].inner_text()
                                        buyer_info_list.append(f"{key}: {value}")
                                buyer_info_str = "; ".join(buyer_info_list)
                                # # 리뷰 라벨
                                review_label_elem = review.query_selector('span._1LWEjWCGPC')
                                review_label_text = review_label_elem.inner_text() if review_label_elem else ""
                                # 리뷰 내용
                                content_elem = review.query_selector('p._2jm5-ElhFW')
                                content = content_elem.inner_text() if content_elem else ""
                                # 데이터 저장
                                review_data.append([
                                    review_id, author_name, author_img_url, rating, date,
                                    product_option_text, buyer_info_str, review_label_text, content
                                ])
                            except Exception as e:
                                print(f"리뷰 데이터 추출 중 오류: {e}")
                                continue
                        # CSV 저장
                        with open('reviews.csv', 'w', newline='', encoding='utf-8-sig') as f:
                            writer = csv.writer(f)
                            writer.writerow([
                                '리뷰ID', '작성자', '프로필이미지', '평점', '작성일',
                                '상품옵션', '구매자정보', '리뷰라벨', '리뷰내용'
                            ])
                            writer.writerows(review_data)
                        print(f"CSV 저장 완료! 총 {len(review_data)}건 저장됨.")
                        
                    else:
                        print("리뷰 버튼을 찾을 수 없습니다.")
                except TimeoutError:
                    print("리뷰 탭을 찾는 데 시간이 초과되었습니다.")
            else:
                print(f"페이지 로딩 실패: {response.status}")
            
            # 브라우저를 닫지 않고 대기
            input("\n계속하려면 엔터를 누르세요...")
            
        except Exception as e:
            print(f"에러 발생: {e}")
        finally:
            browser.close()

if __name__ == "__main__":
    main()