# backend/routers/post/get_chatgpt_share_chat.py
from fastapi import APIRouter, HTTPException
from services.scrapeChatGPTSharedChat import scrape_chatgpt_conversation, extract_chat_messages

router = APIRouter()

@router.get("/get-chatgpt-conversation", tags=["ChatGPT Conversations"])
async def get_chatgpt_conversation(share_link: str):
    """
    Get ChatGPT conversation metadata and chat messages from a share link.
    """
    conversation_data = scrape_chatgpt_conversation(share_link)
    chat_data = extract_chat_messages(share_link)

    if not conversation_data or not chat_data:
        raise HTTPException(status_code=404, detail="No conversation data found")

    return {
        "conversation_metadata": conversation_data,
        "chat_messages": chat_data
    }
