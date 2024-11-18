from fastapi import FastAPI, APIRouter
from fastapi.openapi.docs import get_swagger_ui_html

# Create a router object
router = APIRouter()

# Serve OpenAPI JSON
@router.get("/openapi.json", include_in_schema=False)
async def get_openapi():
    """
    Returns the OpenAPI schema in JSON format.
    """
    return router.openapi()

# Serve Swagger UI at /api/docs
@router.get("/api/docs", include_in_schema=False)
async def custom_swagger_ui():
    """
    Renders the Swagger UI for the CaringMind API.
    """
    return get_swagger_ui_html(
        openapi_url="/openapi.json",
        title="CaringMind API Docs",
        swagger_favicon_url="https://fastapi.tiangolo.com/img/favicon.png",
    )