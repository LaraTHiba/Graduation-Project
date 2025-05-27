from rest_framework import generics, status, permissions
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from rest_framework.permissions import IsAuthenticated
from django.shortcuts import get_object_or_404
import logging
from rest_framework.exceptions import PermissionDenied

from core.models.user_details import UserDetails
from core.serializers.profiles import UserDetailsSerializer, UserDetailsUpdateSerializer

logger = logging.getLogger(__name__)

class UserProfileView(generics.RetrieveUpdateAPIView):
    """
    Retrieve and update the authenticated user's profile
    """
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]
    
    def get_object(self):
        try:
            # Get or create the user details for the authenticated user
            user_details, created = UserDetails.objects.get_or_create(user=self.request.user)
            logger.info(f"GET request - User ID: {self.request.user.id}, UserDetails ID: {user_details.id}, Created: {created}")
            return user_details
        except Exception as e:
            logger.error(f"Error in get_object - User ID: {self.request.user.id}, Error: {str(e)}")
            raise

    def get_serializer_class(self):
        if self.request.method in ['PUT', 'PATCH']:
            return UserDetailsUpdateSerializer
        return UserDetailsSerializer

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['request'] = self.request
        return context

    def check_object_permissions(self, request, obj):
        # Ensure user can only modify their own profile
        if obj.user != request.user:
            logger.warning(f"Permission denied - Requested User ID: {request.user.id}, Object User ID: {obj.user.id}")
            raise PermissionDenied("You can only modify your own profile")
        return super().check_object_permissions(request, obj)

    def patch(self, request, *args, **kwargs):
        try:
            instance = self.get_object()
            logger.info(f"PATCH request - User ID: {request.user.id}, UserDetails ID: {instance.id}")
            
            if 'cv_file' in request.FILES:
                cv_file = request.FILES['cv_file']
                logger.info(f"CV file upload - User ID: {request.user.id}, Filename: {cv_file.name}, Size: {cv_file.size} bytes")
                
                # Validate file type
                if not cv_file.name.lower().endswith(('.pdf', '.doc', '.docx')):
                    logger.warning(f"Invalid file type - User ID: {request.user.id}, Filename: {cv_file.name}")
                    return Response(
                        {"error": "Only PDF, DOC, and DOCX files are allowed"},
                        status=status.HTTP_400_BAD_REQUEST
                    )
                
                # Validate file size (10MB limit)
                if cv_file.size > 10 * 1024 * 1024:
                    logger.warning(f"File too large - User ID: {request.user.id}, Filename: {cv_file.name}, Size: {cv_file.size}")
                    return Response(
                        {"error": "CV file too large (max 10MB)"},
                        status=status.HTTP_400_BAD_REQUEST
                    )
                
                instance.cv_file = cv_file
                instance.save()
                logger.info(f"CV file saved successfully - User ID: {request.user.id}, Filename: {cv_file.name}")
            
            return super().patch(request, *args, **kwargs)
        except Exception as e:
            logger.error(f"Error in PATCH request - User ID: {request.user.id}, Error: {str(e)}")
            raise

class PublicUserProfileView(generics.RetrieveAPIView):
    """
    Retrieve another user's public profile by username
    """
    serializer_class = UserDetailsSerializer
    permission_classes = [permissions.AllowAny]
    
    def get_object(self):
        try:
            username = self.kwargs.get('username')
            user_details = get_object_or_404(UserDetails, user__username=username)
            logger.info(f"Public profile view - Requested username: {username}, User ID: {user_details.user.id}")
            return user_details
        except Exception as e:
            logger.error(f"Error in public profile view - Username: {self.kwargs.get('username')}, Error: {str(e)}")
            raise 