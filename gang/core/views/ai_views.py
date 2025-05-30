from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from ..utils.ai_service import AIService

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def chat_with_ai(request):
    try:
        user_input = request.data.get('message')
        if not user_input:
            return Response({"error": "Message is required"}, status=400)
        
        ai_service = AIService()
        reply = ai_service.get_chat_response(user_input)
        
        return Response({"reply": reply})
    except Exception as e:
        return Response({"error": str(e)}, status=500) 