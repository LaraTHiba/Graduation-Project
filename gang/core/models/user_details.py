from django.db import models
import os
from django.conf import settings
from .users import User

def get_upload_path(instance, filename):
    # File will be uploaded to MEDIA_ROOT/user_<id>/<filename>
    return f'user_{instance.user.id}/{filename}'

class UserDetails(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='details')
    full_name = models.CharField(max_length=200, blank=True, null=True)
    profile_picture = models.ImageField(upload_to=get_upload_path, blank=True, null=True)
    cv_file = models.FileField(upload_to=get_upload_path, blank=True, null=True, help_text='Upload your CV (PDF, DOC, DOCX)')
    cv_text = models.TextField(blank=True, null=True, help_text='Extracted text from CV file')
    bio = models.TextField(blank=True, null=True)
    location = models.CharField(max_length=100, blank=True, null=True)
    date_of_birth = models.DateTimeField(null=True, blank=True)
    background_image = models.ImageField(upload_to=get_upload_path, blank=True, null=True)
    theme = models.CharField(max_length=50, blank=True, null=True)
    font_style = models.CharField(max_length=50, blank=True, null=True)
    social_links = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'user_details'
        verbose_name = 'User Detail'
        verbose_name_plural = 'User Details'

    def __str__(self):
        return f"{self.user.username}'s details"
        
    @property
    def profile_picture_url(self):
        if self.profile_picture:
            return f"{settings.MEDIA_URL}{self.profile_picture}"
        return None
        
    @property
    def background_image_url(self):
        if self.background_image:
            return f"{settings.MEDIA_URL}{self.background_image}"
        return None

    @property
    def cv_file_url(self):
        if self.cv_file:
            return f"{settings.MEDIA_URL}{self.cv_file}"
        return None 