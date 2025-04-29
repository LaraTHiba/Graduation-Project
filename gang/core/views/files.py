from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators import api_view, permission_classes, parser_classes
from django.conf import settings
import os
import uuid

class FileUploadView(generics.GenericAPIView):
    """
    Upload files like videos to the user's directory
    """
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]
    
    def post(self, request, *args, **kwargs):
        file_type = request.data.get('file_type', 'other')
        file_obj = request.FILES.get('file')
        
        if not file_obj:
            return Response(
                {"error": "No file was submitted"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Validate file type based on requested type
        if file_type == 'video':
            allowed_extensions = ['.mp4', '.mov', '.avi', '.mkv', '.webm']
            max_size = 100 * 1024 * 1024  # 100MB
            
            # Check extension
            _, ext = os.path.splitext(file_obj.name)
            if ext.lower() not in allowed_extensions:
                return Response(
                    {"error": f"Invalid file type. Allowed types: {', '.join(allowed_extensions)}"},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Check size
            if file_obj.size > max_size:
                return Response(
                    {"error": "File too large (max 100MB)"},
                    status=status.HTTP_400_BAD_REQUEST
                )
        elif file_type == 'document':
            allowed_extensions = ['.pdf', '.doc', '.docx', '.txt', '.xls', '.xlsx', '.ppt', '.pptx']
            max_size = 20 * 1024 * 1024  # 20MB
            
            # Check extension
            _, ext = os.path.splitext(file_obj.name)
            if ext.lower() not in allowed_extensions:
                return Response(
                    {"error": f"Invalid file type. Allowed types: {', '.join(allowed_extensions)}"},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Check size
            if file_obj.size > max_size:
                return Response(
                    {"error": "File too large (max 20MB)"},
                    status=status.HTTP_400_BAD_REQUEST
                )
                
        # Generate a unique filename to prevent overwrites
        original_filename = file_obj.name
        filename, ext = os.path.splitext(original_filename)
        unique_filename = f"{filename}_{uuid.uuid4().hex[:8]}{ext}"
        
        # Create user-specific folder with user ID
        user_folder = f"user_{request.user.id}/{file_type}"
        user_folder_path = os.path.join(settings.MEDIA_ROOT, user_folder)
        os.makedirs(user_folder_path, exist_ok=True)
        
        # Save the file
        file_path = os.path.join(user_folder_path, unique_filename)
        with open(file_path, 'wb+') as destination:
            for chunk in file_obj.chunks():
                destination.write(chunk)
        
        # Return the URL to the file
        file_url = f"{settings.MEDIA_URL}{user_folder}/{unique_filename}"
        absolute_url = request.build_absolute_uri(file_url)
        
        return Response({
            "file_name": unique_filename,
            "file_type": file_type,
            "file_url": absolute_url,
            "size": file_obj.size
        }, status=status.HTTP_201_CREATED) 