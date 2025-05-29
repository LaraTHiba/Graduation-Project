# This file contains profile-related URLs

from django.urls import path
from core.views.profiles import (
    UserProfileView,
    PublicUserProfileView,
    CVSearchView
)
from core.views.files import FileUploadView

urlpatterns = [
    path('me/', UserProfileView.as_view(), name='user-profile'),
    path('users/<str:username>/', PublicUserProfileView.as_view(), name='public-profile'),
    path('cv-search/', CVSearchView.as_view(), name='cv-search'),
    path('upload/', FileUploadView.as_view(), name='file-upload'),
] 