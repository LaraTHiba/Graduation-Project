from django.urls import path
from core.views.profiles import UserProfileView, UserProfileUpdateView, PublicUserProfileView
from core.views.files import FileUploadView

urlpatterns = [
    # User profile endpoints
    path('me/', UserProfileView.as_view(), name='user-profile'),
    path('me/update/', UserProfileUpdateView.as_view(), name='update-profile'),
    path('users/<str:username>/', PublicUserProfileView.as_view(), name='public-profile'),
    
    # File upload endpoint
    path('upload/', FileUploadView.as_view(), name='file-upload'),
] 