from fastapi import APIRouter, HTTPException, status, Depends, Query
from typing import List
from app.models.schemas import ChatRoomCreate, ChatRoomRead, ChatRoomListResponse
from app.infrastructure.chat_room_repository import ChatRoomRepository

router = APIRouter(prefix="/api/v1", tags=["ChatRoom"])

def get_chat_room_repository() -> ChatRoomRepository:
    return ChatRoomRepository()

@router.post("/chat-rooms/", response_model=ChatRoomRead, status_code=status.HTTP_201_CREATED)
async def create_chat_room(
    chat_room: ChatRoomCreate,
    repo: ChatRoomRepository = Depends(get_chat_room_repository)
) -> ChatRoomRead:
    """
    채팅방 생성 (user_id + product_id 조합, 이미 있으면 기존 반환)
    """
    chat_room_id = repo.create_chat_room(chat_room.user_id, chat_room.product_id)
    room = repo.get_chat_room_by_id(chat_room_id)
    if not room:
        raise HTTPException(status_code=500, detail="채팅방 생성 실패")
    return ChatRoomRead(**room)

@router.get("/chat-rooms/", response_model=ChatRoomListResponse)
async def list_chat_rooms(
    user_id: str = Query(..., description="사용자 ID"),
    repo: ChatRoomRepository = Depends(get_chat_room_repository)
) -> ChatRoomListResponse:
    """
    특정 사용자의 모든 채팅방 목록 조회
    """
    rooms = repo.get_chat_rooms_by_user(user_id)
    return ChatRoomListResponse(chat_rooms=[ChatRoomRead(**room) for room in rooms])

@router.get("/chat-rooms/{chat_room_id}", response_model=ChatRoomRead)
async def get_chat_room(
    chat_room_id: int,
    repo: ChatRoomRepository = Depends(get_chat_room_repository)
) -> ChatRoomRead:
    """
    채팅방 단일 조회
    """
    room = repo.get_chat_room_by_id(chat_room_id)
    if not room:
        raise HTTPException(status_code=404, detail="채팅방을 찾을 수 없습니다.")
    return ChatRoomRead(**room)

@router.delete("/chat-rooms/{chat_room_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_chat_room(
    chat_room_id: int,
    repo: ChatRoomRepository = Depends(get_chat_room_repository)
):
    """
    채팅방 삭제
    """
    ok = repo.delete_chat_room(chat_room_id)
    if not ok:
        raise HTTPException(status_code=404, detail="채팅방 삭제 실패 또는 존재하지 않음")
    return None 