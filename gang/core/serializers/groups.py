from rest_framework import serializers
from core.models.user_groups import UserGroup
from core.models.users import User

class UserGroupSerializer(serializers.ModelSerializer):
    member_count = serializers.SerializerMethodField()
    created_by_username = serializers.SerializerMethodField()
    is_member = serializers.SerializerMethodField()
    
    class Meta:
        model = UserGroup
        fields = [
            'id', 'name', 'description', 'created_by', 'created_by_username',
            'member_count', 'created_at', 'updated_at', 'is_member'
        ]
        read_only_fields = ['id', 'created_by', 'created_at', 'updated_at']
    
    def get_member_count(self, obj):
        return obj.members.count()
    
    def get_created_by_username(self, obj):
        return obj.created_by.username
    
    def get_is_member(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.members.filter(id=request.user.id).exists()
        return False 