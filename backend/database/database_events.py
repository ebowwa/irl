from fastapi import FastAPI
from utils.db_state import database

def register_db_events(app: FastAPI):
    @app.on_event("startup")
    async def startup():
        await database.connect()

    @app.on_event("shutdown")
    async def shutdown():
        await database.disconnect()
