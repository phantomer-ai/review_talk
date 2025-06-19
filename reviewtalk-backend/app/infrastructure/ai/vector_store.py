"""
ChromaDB를 사용한 벡터 저장소 관리
"""
import uuid
from typing import List, Dict, Any, Optional
import chromadb
from chromadb.config import Settings as ChromaSettings
from chromadb.utils import embedding_functions
from chromadb import EmbeddingFunction
from sentence_transformers import SentenceTransformer
from app.core.config import settings
from app.models.schemas import ReviewData
from loguru import logger

from urllib.parse import urlparse, parse_qs
from typing import Optional
from app.utils.url_utils import extract_product_id


class CustomEmbeddingFunction(EmbeddingFunction):
    """ChromaDB v0.4.16+ 호환 커스텀 임베딩 함수"""
    
    def __init__(self):
        self.model = SentenceTransformer("intfloat/multilingual-e5-small")
    
    def __call__(self, input):
        """ChromaDB v0.4.16+ 호환 임베딩 함수"""
        # input을 리스트로 변환
        if isinstance(input, str):
            texts = [input]
        elif isinstance(input, list):
            texts = input
        else:
            texts = [str(input)]
        
        # E5 모델을 위한 prefix 추가
        formatted_texts = []
        for text in texts:
            if not (text.strip().startswith("query:") or text.strip().startswith("passage:")):
                formatted_texts.append("query: " + text.strip())
            else:
                formatted_texts.append(text)
        
        # 임베딩 생성
        embeddings = self.model.encode(formatted_texts)
        return embeddings.tolist()


class VectorStore:
    """ChromaDB를 사용한 벡터 저장소"""
    
    def __init__(self):
        """벡터 저장소 초기화"""
        self.client = chromadb.PersistentClient(
            path=settings.chroma_db_path,
            settings=ChromaSettings(
                anonymized_telemetry=False
            )
        )
        
        # ChromaDB v0.4.16+ 호환 커스텀 임베딩 함수 사용
        self.embedding_function = CustomEmbeddingFunction()
        
        # 컬렉션 생성 또는 가져오기
        self.collection = self.client.get_or_create_collection(
            name="product_reviews",
            embedding_function=self.embedding_function,
            metadata={"hnsw:space": "cosine"}
        )
    
    def add_reviews(self, reviews: List[ReviewData], product_id: str) -> None:
        """리뷰 데이터를 벡터 저장소에 추가"""
        try:
            documents = []
            metadatas = []
            ids = []
            
            for review in reviews:
                # 리뷰 텍스트와 메타데이터 준비
                document = f"평점: {review.rating}/5\n리뷰: {review.content}"
                
                # None 값들을 적절한 기본값으로 변환
                metadata = {
                    "product_id" : product_id,
                    "rating": int(review.rating) if review.rating is not None else 0,
                    "date": review.date or "unknown",
                    "review_id": review.review_id or str(uuid.uuid4()),
                    "author": review.author or "anonymous"
                }
                
                documents.append(document)
                metadatas.append(metadata)
                ids.append(f"review_{metadata['review_id']}")

            logger.info(f"metas : [{metadatas}]")


            # ChromaDB에 추가
            self.collection.add(
                documents=documents,
                metadatas=metadatas,
                ids=ids
            )
            
            logger.info(f"✅ {len(reviews)}개 리뷰가 벡터 저장소에 추가되었습니다.")
            
        except Exception as e:
            logger.error(f"❌ 벡터 저장소 추가 오류: {e}")
            raise
    
    def search_similar_reviews(
        self, 
        query: str, 
        n_results: int = 5,
        product_id: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """유사한 리뷰 검색"""
        try:
            
            product_id_int = int(product_id) if product_id is not None else None
            
            # 검색 필터 설정
            where_filter = {}
            if product_id:
                where_filter["product_id"] = product_id_int
            
            logger.info(f"✅ product_id : {product_id_int} ")
            # 벡터 검색 수행
            results = self.collection.query(
                query_texts=[query],
                n_results=n_results,
                where=where_filter if where_filter else None
            )
            
            # 결과 포맷팅
            search_results = []
            if results["documents"] and len(results["documents"]) > 0:
                for i, doc in enumerate(results["documents"][0]):
                    result = {
                        "document": doc,
                        "metadata": results["metadatas"][0][i],
                        "distance": results["distances"][0][i] if results["distances"] else None
                    }
                    search_results.append(result)
            
            return search_results
            
        except Exception as e:
            logger.error(f"❌ 벡터 검색 오류: {e}")
            return []
    
    def get_collection_stats(self) -> Dict[str, Any]:
        """컬렉션 통계 정보 반환"""
        try:
            count = self.collection.count()
            return {
                "total_reviews": count,
                "collection_name": self.collection.name
            }
        except Exception as e:
            logger.error(f"❌ 통계 조회 오류: {e}")
            return {"total_reviews": 0, "collection_name": "unknown"}
    
    def delete_collection(self) -> None:
        """컬렉션 삭제 (테스트용)"""
        try:
            self.client.delete_collection(name="product_reviews")
            logger.info("✅ 컬렉션이 삭제되었습니다.")
        except Exception as e:
            logger.error(f"❌ 컬렉션 삭제 오류: {e}")


# 전역 벡터 저장소 인스턴스 - 지연 초기화
vector_store = None

def get_vector_store():
    """벡터 저장소 싱글톤 인스턴스 반환"""
    global vector_store
    if vector_store is None:
        vector_store = VectorStore()
    return vector_store 