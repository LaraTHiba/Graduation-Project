from rest_framework import serializers
from core.models.user_details import UserDetails
from core.models.users import User

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name', 'phone_number', 'user_type']
        read_only_fields = ['id', 'email']

class UserDetailsSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    profile_picture_url = serializers.SerializerMethodField()
    background_image_url = serializers.SerializerMethodField()
    
    class Meta:
        model = UserDetails
        fields = [
            'id', 'user', 'full_name', 'profile_picture', 'profile_picture_url', 
            'bio', 'location', 'date_of_birth', 'background_image', 
            'background_image_url', 'theme', 'font_style', 'social_links',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'user', 'created_at', 'updated_at', 'profile_picture_url', 'background_image_url']
    
    def get_profile_picture_url(self, obj):
        if obj.profile_picture:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.profile_picture.url)
            return obj.profile_picture.url
        return None
    
    def get_background_image_url(self, obj):
        if obj.background_image:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.background_image.url)
            return obj.background_image.url
        return None

class UserDetailsUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserDetails
        fields = [
            'full_name', 'profile_picture', 'bio', 'location', 
            'date_of_birth', 'background_image', 'theme', 
            'font_style', 'social_links'
        ]

    def validate_profile_picture(self, value):
        if value:
            # Validate file type
            if not value.name.lower().endswith(('.png', '.jpg', '.jpeg', '.gif')):
                raise serializers.ValidationError("Only image files are allowed")
            # Validate file size (limit to 5MB)
            if value.size > 5 * 1024 * 1024:
                raise serializers.ValidationError("Image file too large (> 5MB)")
        return value
    
    def validate_background_image(self, value):
        if value:
            # Validate file type
            if not value.name.lower().endswith(('.png', '.jpg', '.jpeg', '.gif')):
                raise serializers.ValidationError("Only image files are allowed")
            # Validate file size (limit to 10MB)
            if value.size > 10 * 1024 * 1024:
                raise serializers.ValidationError("Image file too large (> 10MB)")
        return value 