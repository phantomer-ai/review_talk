#!/usr/bin/env python3
import asyncio
import sys
import os

# 현재 디렉토리를 Python 경로에 추가
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.infrastructure.crawler.special_deals_crawler import crawl_special_deals

async def main():
    print('🚀 특가 상품 크롤링 시작...')
    try:
        products = await crawl_special_deals(max_products=6)
        print(f'📦 크롤링된 상품 수: {len(products)}')
        
        if not products:
            print('❌ 크롤링된 상품이 없습니다.')
            return
            
        for i, product in enumerate(products, 1):
            print(f'\n{i}. {product.product_name}')
            print(f'   - ID: {product.product_id}')
            print(f'   - 가격: {product.price}')
            print(f'   - 원가: {product.original_price}')
            print(f'   - 할인율: {product.discount_rate}')
            print(f'   - 이미지: {product.image_url}')
            print(f'   - URL: {product.product_url}')
            print(f'   - 리뷰 크롤링 여부: {product.is_crawled}')
            print(f'   - 리뷰 수: {product.review_count}')
            print(f'   - 채팅 가능 여부: {hasattr(product, "canChat") and product.canChat}')
    except Exception as e:
        print(f'❌ 크롤링 오류: {e}')
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(main()) 