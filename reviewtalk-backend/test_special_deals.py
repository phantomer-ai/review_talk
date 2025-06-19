#!/usr/bin/env python3
"""
특가 상품 크롤링 시스템 테스트
"""
import asyncio
import sys
import os

# 프로젝트 루트를 파이썬 경로에 추가
sys.path.insert(0, os.path.dirname(__file__))

from app.models.schemas import CrawlSpecialProductsRequest
from app.services.special_deals_service import special_deals_service


async def test_special_deals_crawling():
    """특가 상품 크롤링 테스트"""
    print("🚀 특가 상품 크롤링 시스템 테스트 시작")
    
    try:
        # 1. 소량 테스트 (상품 목록만)
        print("\n📦 1단계: 특가 상품 목록 크롤링 테스트 (리뷰 제외)")
        request = CrawlSpecialProductsRequest(
            max_products=3,  # 테스트용으로 3개만
            crawl_reviews=False,
            max_reviews_per_product=10
        )
        
        result = await special_deals_service.crawl_and_save_special_deals(request)
        
        if result.success:
            print(f"✅ 특가 상품 크롤링 성공!")
            print(f"   - 수집된 상품 수: {result.total_products}")
            print(f"   - 리뷰 크롤링된 상품: {result.products_with_reviews}")
            print(f"   - 총 리뷰 수: {result.total_reviews}")
        else:
            print(f"❌ 특가 상품 크롤링 실패: {result.error_message}")
            return
        
        # 2. 저장된 상품 조회 테스트
        print("\n📋 2단계: 저장된 특가 상품 조회 테스트")
        products_response = special_deals_service.get_special_products(limit=10)
        
        if products_response.success:
            print(f"✅ 상품 조회 성공!")
            print(f"   - 전체 상품 수: {products_response.total_count}")
            print(f"   - 조회된 상품 수: {len(products_response.products)}")
            
            # 상품 정보 출력
            for i, product in enumerate(products_response.products[:3], 1):
                print(f"   {i}. {product.product_name}")
                print(f"      가격: {product.price or '정보없음'}")
                print(f"      리뷰크롤링: {'완료' if product.is_crawled else '미완료'}")
        else:
            print(f"❌ 상품 조회 실패: {products_response.error_message}")
        
        # 3. 특정 상품의 리뷰 크롤링 테스트 (1개만)
        if products_response.success and products_response.products:
            print(f"\n📝 3단계: 특정 상품 리뷰 크롤링 테스트")
            test_product = products_response.products[0]
            
            print(f"테스트 상품: {test_product.product_name}")
            print(f"상품 URL: {test_product.product_url}")
            
            # 소량 리뷰 크롤링 테스트
            print("리뷰 크롤링 중...")
            
            # 임시로 직접 크롤링 함수 호출
            from app.infrastructure.crawler.danawa_crawler import crawl_danawa_reviews
            
            review_result = await crawl_danawa_reviews(test_product.product_url, 10)
            
            if review_result.get("success"):
                reviews = review_result.get("reviews", [])
                print(f"✅ 리뷰 크롤링 성공: {len(reviews)}개")
                
                # 몇 개 리뷰 출력
                for i, review in enumerate(reviews[:2], 1):
                    content = review.content if hasattr(review, 'content') else review.get('content', '') if isinstance(review, dict) else str(review)
                    rating = review.rating if hasattr(review, 'rating') else review.get('rating', 'N/A') if isinstance(review, dict) else 'N/A'
                    print(f"   리뷰 {i}: {content[:50]}...")
                    print(f"   평점: {rating}")
            else:
                print(f"❌ 리뷰 크롤링 실패: {review_result.get('error_message', '알 수 없는 오류')}")
        
        print(f"\n🎉 특가 상품 크롤링 시스템 테스트 완료!")
        
    except Exception as e:
        print(f"❌ 테스트 중 오류 발생: {e}")
        import traceback
        traceback.print_exc()


def test_repository():
    """Repository 기본 기능 테스트"""
    print("\n🗄️ Repository 기본 기능 테스트")
    
    try:
        # 데이터베이스 초기화
        special_deals_service.repository.init_db()
        print("✅ 데이터베이스 초기화 완료")
        
        # 전체 상품 수 조회
        total_count = special_deals_service.repository.get_total_count()
        print(f"✅ 전체 특가 상품 수: {total_count}")
        
        # 미크롤링 상품 조회
        uncrawled = special_deals_service.repository.get_uncrawled_products(5)
        print(f"✅ 미크롤링 상품 수: {len(uncrawled)}")
        
    except Exception as e:
        print(f"❌ Repository 테스트 오류: {e}")


async def main():
    """메인 테스트 함수"""
    print("🧪 ReviewTalk 특가 상품 시스템 종합 테스트")
    print("=" * 50)
    
    # Repository 테스트
    test_repository()
    
    # 크롤링 테스트
    await test_special_deals_crawling()
    
    print("\n" + "=" * 50)
    print("✅ 모든 테스트 완료")


if __name__ == "__main__":
    asyncio.run(main()) 