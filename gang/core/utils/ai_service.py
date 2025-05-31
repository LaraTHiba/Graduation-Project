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
        
        # Initialize client with DeepSeek settings
        self.client = openai.OpenAI(
            api_key=settings.DEEPSEEK_API_KEY,
            base_url=settings.DEEPSEEK_BASE_URL
        )
        # Add this print statement temporarily:
        print(f"Using DeepSeek API key: {settings.DEEPSEEK_API_KEY}")

    def get_chat_response(self, message):
        try:
            response = self.client.chat.completions.create(
                model="deepseek-chat",  # Use DeepSeek model
                messages=[
                    {"role": "system", "content": "You are a helpful assistant"},
                    {"role": "user", "content": message}
                ],
                stream=False
            )
            return response.choices[0].message.content
        except Exception as e:
            return f"Error: {str(e)}"