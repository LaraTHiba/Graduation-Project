try:
    import openai
    OPENAI_AVAILABLE = True
except ImportError:
    OPENAI_AVAILABLE = False

from django.conf import settings

class AIService:
    def __init__(self):
        if not OPENAI_AVAILABLE:
            raise ImportError("The OpenAI package is not installed. Run 'pip install openai' to install it.")
        openai.api_key = settings.OPENAI_API_KEY

    def get_chat_response(self, message):
        try:
            response = openai.ChatCompletion.create(
                model="gpt-3.5-turbo",
                messages=[{"role": "user", "content": message}]
            )
            return response['choices'][0]['message']['content']
        except Exception as e:
            return f"Error: {str(e)}"