from urllib.parse import urlparse, parse_qs
from typing import Optional

def extract_product_id(url: str) -> Optional[str]:
    """
    주어진 URL에서 pcode 값을 추출하여 product_id로 반환합니다.
    """
    try:
        parsed_url = urlparse(url)
        query_params = parse_qs(parsed_url.query)
        product_id = query_params.get("pcode", [None])[0]
        return product_id
    except Exception as e:
        print(f"URL 파싱 오류: {e}")
        return None 