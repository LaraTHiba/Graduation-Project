import os
import logging
import openai
import httpx
from django.conf import settings

logger = logging.getLogger(__name__)

class AIService:
    def __init__(self):
        # Check if necessary packages are installed
        try:
            import openai
            import httpx
        except ImportError as e:
            logger.error(f"Missing package: {e}. Please run 'pip install openai httpx'")
            raise ImportError(f"Missing package: {e}. Please run 'pip install openai httpx'")

        # Check if API key is configured
        api_key = settings.DEEPSEEK_API_KEY
        if not api_key:
            logger.error("DeepSeek API key is not configured")
            raise ValueError("DeepSeek API key is not configured. Please set DEEPSEEK_API_KEY in your environment variables.")

        base_url = settings.DEEPSEEK_BASE_URL

        # Initialize httpx client with default settings
        try:
            http_client = httpx.Client()
            logger.info("Successfully initialized httpx client")
        except Exception as e:
            logger.error(f"Failed to initialize httpx client: {str(e)}")
            raise

        # Initialize OpenAI client with DeepSeek settings and the custom httpx client
        try:
            self.client = openai.OpenAI(
                api_key=api_key,
                base_url=base_url,
                http_client=http_client
            )
            logger.info("Successfully initialized DeepSeek client with custom httpx client")
        except Exception as e:
            logger.error(f"Failed to initialize DeepSeek client: {str(e)}")
            # Re-raise the original exception to include the traceback
            raise

    def get_chat_response(self, message):
        try:
            if not message:
                return "Please provide a message to get a response."

            response = self.client.chat.completions.create(
                model="deepseek-chat",  # Use DeepSeek model
                messages=[
                    {"role": "system", "content": "You are a helpful assistant"},
                    {"role": "user", "content": message}
                ],
                stream=False
            )

            if not response.choices:
                return "Sorry, I couldn't generate a response at this time."

            return response.choices[0].message.content

        except Exception as e:
            logger.error(f"Error in get_chat_response: {str(e)}")
            # Return a more informative error message to the frontend
            return f"Error communicating with AI service: {str(e)}"