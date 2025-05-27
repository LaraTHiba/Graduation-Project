from rest_framework import serializers
from core.models.user_details import UserDetails
from core.models.users import User
import logging

logger = logging.getLogger(__name__)

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name', 'phone_number', 'user_type']
        read_only_fields = ['id', 'email']

class UserDetailsSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    profile_picture_url = serializers.SerializerMethodField()
    background_image_url = serializers.SerializerMethodField()
    cv_url = serializers.SerializerMethodField()
    cv_original_filename = serializers.SerializerMethodField()
    
    class Meta:
        model = UserDetails
        fields = [
            'id', 'user', 'full_name', 'profile_picture', 'profile_picture_url', 
            'bio', 'location', 'date_of_birth', 'background_image', 
            'background_image_url', 'theme', 'font_style', 'social_links',
            'cv_file', 'cv_url', 'cv_original_filename', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'user', 'created_at', 'updated_at', 'profile_picture_url', 'background_image_url', 'cv_url', 'cv_original_filename']
    
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

    def get_cv_url(self, obj):
        try:
            if obj.cv_file:
                request = self.context.get('request')
                if request:
                    url = request.build_absolute_uri(obj.cv_file.url)
                    logger.info(f"Generated CV URL for user {obj.user.id}: {url}")
                    return url
                url = obj.cv_file.url
                logger.info(f"Generated CV URL for user {obj.user.id}: {url}")
                return url
            logger.info(f"No CV file found for user {obj.user.id}")
            return None
        except Exception as e:
            logger.error(f"Error generating CV URL for user {obj.user.id}: {str(e)}")
            return None

    def get_cv_original_filename(self, obj):
        try:
            if obj.cv_file:
                filename = obj.cv_file.name.split('/')[-1]
                logger.info(f"Original CV filename for user {obj.user.id}: {filename}")
                return filename
            logger.info(f"No CV file found for user {obj.user.id}")
            return None
        except Exception as e:
            logger.error(f"Error getting CV filename for user {obj.user.id}: {str(e)}")
            return None

class UserDetailsUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserDetails
        fields = [
            'full_name', 'profile_picture', 'bio', 'location', 
            'date_of_birth', 'background_image', 'theme', 
            'font_style', 'social_links', 'cv_file'
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

    def validate_cv_file(self, value):
        if value:
            # Validate file type
            if not value.name.lower().endswith(('.pdf', '.doc', '.docx')):
                raise serializers.ValidationError("Only PDF, DOC, and DOCX files are allowed")
            # Validate file size (limit to 10MB)
            if value.size > 10 * 1024 * 1024:
                raise serializers.ValidationError("CV file too large (> 10MB)")
            logger.info(f"Validated CV file: {value.name}, size: {value.size} bytes")
        return value 