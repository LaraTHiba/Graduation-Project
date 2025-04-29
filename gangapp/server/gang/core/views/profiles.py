from rest_framework import generics, status, permissions
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from rest_framework.permissions import IsAuthenticated
from django.shortcuts import get_object_or_404

from core.models.user_details import UserDetails
from core.serializers.profiles import UserDetailsSerializer, UserDetailsUpdateSerializer

class UserProfileView(generics.RetrieveAPIView):
    """
    Retrieve the authenticated user's profile
    """
    serializer_class = UserDetailsSerializer
    permission_classes = [IsAuthenticated]
    
    def get_object(self):
        # Get or create the user details for the authenticated user
        user_details, created = UserDetails.objects.get_or_create(user=self.request.user)
        return user_details

class UserProfileUpdateView(generics.UpdateAPIView):
    """
    Update the authenticated user's profile
    """
    serializer_class = UserDetailsUpdateSerializer
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]
    
    def get_object(self):
        # Get or create the user details for the authenticated user
        user_details, created = UserDetails.objects.get_or_create(user=self.request.user)
        return user_details
    
    def update(self, request, *args, **kwargs):
        partial = kwargs.pop('partial', True)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)
        
        # Return the updated instance using the full serializer
        return Response(UserDetailsSerializer(
            instance, 
            context={'request': request}
        ).data)

class PublicUserProfileView(generics.RetrieveAPIView):
    """
    Retrieve another user's public profile by username
    """
    serializer_class = UserDetailsSerializer
    permission_classes = [permissions.AllowAny]
    
    def get_object(self):
        username = self.kwargs.get('username')
        user_details = get_object_or_404(UserDetails, user__username=username)
        return user_details 