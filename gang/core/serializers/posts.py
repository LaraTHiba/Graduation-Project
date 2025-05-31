from rest_framework import serializers
from core.models.posts import Post
from core.models.comments import Comment
from django.contrib.auth import get_user_model
from core.models.interests import Interest
import json

User = get_user_model()

class CommentSerializer(serializers.ModelSerializer):
    username = serializers.SerializerMethodField()
    image_url = serializers.SerializerMethodField()
    replies = serializers.SerializerMethodField()
    
    class Meta:
        model = Comment
        fields = ['id', 'user', 'username', 'content', 'parent_comment', 'created_at', 
                 'updated_at', 'image', 'image_url', 'is_deleted', 'replies']
        read_only_fields = ['id', 'created_at', 'updated_at', 'username', 'image_url', 'replies']
    
    def get_username(self, obj):
        return obj.user.username
    
    def get_image_url(self, obj):
        if obj.image:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.image.url)
            return obj.image.url
        return None

    def get_replies(self, obj):
        # Get all non-deleted replies for this comment
        replies = obj.replies.filter(is_deleted=False).order_by('created_at')
        serializer = CommentSerializer(replies, many=True, context=self.context)
        return serializer.data

    def to_representation(self, instance):
        data = super().to_representation(instance)
        # Ensure content is properly encoded
        if 'content' in data:
            data['content'] = data['content']
        return data

class PostSerializer(serializers.ModelSerializer):
    username = serializers.SerializerMethodField()
    comments = serializers.SerializerMethodField()
    image_full_url = serializers.SerializerMethodField()
    interest = serializers.PrimaryKeyRelatedField(
        queryset=Interest.objects.all(),
        required=False,
        allow_null=True,
        error_messages={
            'does_not_exist': 'The specified interest does not exist.',
            'invalid': 'Invalid interest value.'
        }
    )
    
    class Meta:
        model = Post
        fields = ['id', 'user', 'username', 'title', 'content', 'image_url', 'image', 
                 'image_full_url', 'interest', 'created_at', 'updated_at', 'comments', 
                 'is_deleted']
        
        read_only_fields = [
            'id', 'user', 'created_at', 'updated_at', 'username', 'image_full_url'
        ] 

    def get_username(self, obj):
        return obj.user.username
    
    def get_image_full_url(self, obj):
        if obj.image:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.image.url)
            return obj.image.url
        return obj.image_url  # Return the URL string if using the URL field
    
    def get_comments(self, obj):
        # Get all non-deleted top-level comments
        comments = obj.comments.filter(is_deleted=False, parent_comment=None).order_by('-created_at')
        serializer = CommentSerializer(comments, many=True, context=self.context)
        return serializer.data

    def to_representation(self, instance):
        data = super().to_representation(instance)
        # Ensure content is properly encoded
        if 'content' in data:
            data['content'] = data['content']
        if 'title' in data:
            data['title'] = data['title']
        return data 