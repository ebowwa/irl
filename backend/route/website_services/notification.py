# backend/route/website_services/notification.py
# telegram should provide admin updates
import os
import logging
import requests
from typing import Optional

class TelegramNotifier:
    """
    A reusable notifier class for sending Telegram messages.
    """

    def __init__(self):
        # Configure logging for the notification module
        self.logger = logging.getLogger(self.__class__.__name__)
        self.logger.setLevel(logging.INFO)
        handler = logging.StreamHandler()
        formatter = logging.Formatter(
            "%(asctime)s [%(levelname)s] %(name)s: %(message)s"
        )
        handler.setFormatter(formatter)
        if not self.logger.handlers:
            self.logger.addHandler(handler)

        # Load Telegram credentials from environment variables
        self.TELEGRAM_BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN")
        self.TELEGRAM_CHAT_ID = os.getenv("TELEGRAM_CHAT_ID")

        if not self.TELEGRAM_BOT_TOKEN or not self.TELEGRAM_CHAT_ID:
            self.logger.error("Telegram credentials are not set in environment variables.")
            raise ValueError("Missing Telegram configuration.")

        self.TELEGRAM_API_URL = f"https://api.telegram.org/bot{self.TELEGRAM_BOT_TOKEN}/sendMessage"
        self.logger.info("TelegramNotifier initialized successfully.")

    def send_message(self, message: str) -> None:
        """
        Sends a Telegram message with the provided text.

        Args:
            message (str): The message text to send.
        """
        payload = {
            "chat_id": self.TELEGRAM_CHAT_ID,
            "text": message,
            "parse_mode": "Markdown"
        }

        self.logger.debug(f"Sending Telegram message: {message}")
        try:
            response = requests.post(self.TELEGRAM_API_URL, data=payload)
            response.raise_for_status()
            self.logger.info("Telegram notification sent successfully.")
        except requests.exceptions.RequestException as e:
            self.logger.error(f"Failed to send Telegram notification: {e}")
            raise

    def send_new_waitlist_entry(self, name: str, email: str, comment: Optional[str] = None) -> None:
        """
        Sends a Telegram message specifically formatted for new waitlist entries.

        Args:
            name (str): Name of the user.
            email (str): Email of the user.
            comment (Optional[str]): Optional comment from the user.
        """
        message = f"🆕 *New Waitlist Entry:*\n\n*Name:* {name}\n*Email:* {email}"
        if comment:
            message += f"\n*Comment:* {comment}"

        self.logger.debug("Formatted message for new waitlist entry.")
        self.send_message(message)
