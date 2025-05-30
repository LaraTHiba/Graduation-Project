from django.urls import path
from core.views.ai_views import chat_with_ai

urlpatterns = [
    path('chat/', chat_with_ai, name='chat_with_ai'),
] 