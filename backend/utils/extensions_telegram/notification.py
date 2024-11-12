# backend/route/extensions_telegram/notification.py
# probably use this to notify me if the server ever goes down
import os
import logging
from typing import Optional
from aiogram import Bot, types
import asyncio
from dotenv import load_dotenv

# Load environment variables from a .env file (if you choose to use one)
load_dotenv()

class TelegramNotifier:
    def __init__(self):
        # Initialize logger
        self.logger = logging.getLogger(self.__class__.__name__)
        self.logger.setLevel(logging.INFO)
        handler = logging.StreamHandler()
        formatter = logging.Formatter(
            "%(asctime)s [%(levelname)s] %(name)s: %(message)s"
        )
        handler.setFormatter(formatter)
        if not self.logger.handlers:
            self.logger.addHandler(handler)

        # Load environment variables
        self.TELEGRAM_BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN")
        self.TELEGRAM_CHAT_ID = os.getenv("TELEGRAM_CHAT_ID")

        # Validate environment variables
        if not self.TELEGRAM_BOT_TOKEN or not self.TELEGRAM_CHAT_ID:
            self.logger.error("Telegram credentials are not set in environment variables.")
            raise ValueError("Missing Telegram configuration.")

        # Initialize the bot
        self.bot = Bot(token=self.TELEGRAM_BOT_TOKEN)
        self.logger.info("TelegramNotifier initialized successfully.")

    async def send_message(self, message: str) -> None:
        self.logger.debug(f"Sending Telegram message: {message}")
        try:
            await self.bot.send_message(
                chat_id=self.TELEGRAM_CHAT_ID,
                text=message,
                parse_mode="Markdown"  # Use string literals instead of types.ParseMode
            )
            self.logger.info("Telegram notification sent successfully.")
        except Exception as e:
            self.logger.error(f"Failed to send Telegram notification: {e}")
            raise

    async def send_new_waitlist_entry(self, name: str, email: str, comment: Optional[str] = None) -> None:
        message = f"🆕 *New Waitlist Entry:*\n\n*Name:* {name}\n*Email:* {email}"
        if comment:
            message += f"\n*Comment:* {comment}"

        self.logger.debug("Formatted message for new waitlist entry.")
        await self.send_message(message)

    async def close(self) -> None:
        await self.bot.session.close()

if __name__ == "__main__":
    async def main():
        notifier = TelegramNotifier()
        await notifier.send_new_waitlist_entry("John Doe", "john@example.com", "Looking forward!")
        await notifier.close()

    asyncio.run(main())
