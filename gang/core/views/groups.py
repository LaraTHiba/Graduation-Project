from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db.models import Q
from core.models.user_groups import UserGroup
from core.serializers.groups import UserGroupSerializer

class UserGroupViewSet(viewsets.ModelViewSet):
    serializer_class = UserGroupSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        # Get groups where user is either a member or creator
        return UserGroup.objects.filter(
            Q(members=self.request.user) | 
            Q(created_by=self.request.user)
        ).distinct()
    
    def perform_create(self, serializer):
        # Automatically add creator as a member
        group = serializer.save(created_by=self.request.user)
        group.members.add(self.request.user)
    
    @action(detail=True, methods=['post'])
    def join(self, request, pk=None):
        group = self.get_object()
        if request.user in group.members.all():
            return Response(
                {"error": "You are already a member of this group"},
                status=status.HTTP_400_BAD_REQUEST
            )
        group.members.add(request.user)
        return Response({"message": "Successfully joined the group"})
    
    @action(detail=True, methods=['post'])
    def leave(self, request, pk=None):
        group = self.get_object()
        if request.user not in group.members.all():
            return Response(
                {"error": "You are not a member of this group"},
                status=status.HTTP_400_BAD_REQUEST
            )
        if request.user == group.created_by:
            return Response(
                {"error": "Group creator cannot leave the group"},
                status=status.HTTP_400_BAD_REQUEST
            )
        group.members.remove(request.user)
        return Response({"message": "Successfully left the group"})
    
    @action(detail=False, methods=['get'])
    def available(self, request):
        # Get groups that the user is not a member of
        available_groups = UserGroup.objects.exclude(
            Q(members=request.user) | 
            Q(created_by=request.user)
        )
        serializer = self.get_serializer(available_groups, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def my_groups(self, request):
        # Get groups created by the user
        my_groups = UserGroup.objects.filter(created_by=request.user)
        serializer = self.get_serializer(my_groups, many=True)
        return Response(serializer.data) 