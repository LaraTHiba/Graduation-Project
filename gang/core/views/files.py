from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators import api_view, permission_classes, parser_classes
from django.conf import settings
import os
import uuid
import logging
from core.models.user_details import UserDetails
from django.db import models
from core.utils.cv_extractor import extract_cv_text

logger = logging.getLogger(__name__)

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
        
        # Handle CV file upload
        if file_type == 'cv':
            # Validate file type
            if not file_obj.name.lower().endswith(('.pdf', '.doc', '.docx')):
                logger.warning(f"Invalid CV file type - User ID: {request.user.id}, Filename: {file_obj.name}")
                return Response(
                    {"error": "Only PDF, DOC, and DOCX files are allowed"},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Validate file size (10MB limit)
            if file_obj.size > 10 * 1024 * 1024:
                logger.warning(f"CV file too large - User ID: {request.user.id}, Filename: {file_obj.name}, Size: {file_obj.size}")
                return Response(
                    {"error": "CV file too large (max 10MB)"},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            try:
                # Get or create user details
                user_details, created = UserDetails.objects.get_or_create(user=request.user)
                
                # Save the CV file to the user's profile
                user_details.cv_file = file_obj
                # Extract text from CV file and save it
                cv_text = extract_cv_text(file_obj)
                user_details.cv_text = cv_text
                user_details.save()
                
                # Get the URL for the saved file
                file_url = request.build_absolute_uri(user_details.cv_file.url)
                
                logger.info(f"CV file uploaded successfully - User ID: {request.user.id}, Filename: {file_obj.name}")
                
                return Response({
                    "file_name": file_obj.name,
                    "file_type": "cv",
                    "file_url": file_url,
                    "size": file_obj.size,
                    "cv_url": file_url,
                    "cv_original_filename": file_obj.name
                }, status=status.HTTP_201_CREATED)
                
            except Exception as e:
                logger.error(f"Error uploading CV file - User ID: {request.user.id}, Error: {str(e)}")
                return Response(
                    {"error": "Failed to upload CV file"},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
        
        # Handle other file types
        elif file_type == 'video':
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

def get_upload_path(instance, filename):
    # File will be uploaded to MEDIA_ROOT/user_<id>/<filename>
    return f'user_{instance.user.id}/{filename}' 