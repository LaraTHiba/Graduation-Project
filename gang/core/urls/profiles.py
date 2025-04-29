# This file contains profile-related URLs

from django.urls import path
from core.views.profiles import (
    UserProfileView,
    UserProfileUpdateView,
    PublicUserProfileView
)
from core.views.files import FileUploadView

urlpatterns = [
    path('me/', UserProfileView.as_view(), name='user-profile'),
    path('me/update/', UserProfileUpdateView.as_view(), name='update-profile'),
    path('users/<str:username>/', PublicUserProfileView.as_view(), name='public-profile'),
    path('upload/', FileUploadView.as_view(), name='file-upload'),
] 