from django.urls import path
from core.views.auth import (
    UserRegistrationView,
    CustomTokenObtainPairView,
    LogoutView,
    ChangePasswordView,
    ResetPasswordEmailView,
    ResetPasswordView
)
from core.views.profiles import (
    UserProfileView,
    UserProfileUpdateView,
    PublicUserProfileView
)
from core.views.files import FileUploadView
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
)

# Auth URL patterns
auth_patterns = [
    path('auth/register/', UserRegistrationView.as_view(), name='register'),
    path('auth/login/', CustomTokenObtainPairView.as_view(), name='login'),
    path('auth/logout/', LogoutView.as_view(), name='logout'),
    path('auth/change-password/', ChangePasswordView.as_view(), name='change-password'),
    path('auth/reset-password-email/', ResetPasswordEmailView.as_view(), name='reset-password-email'),
    path('auth/reset-password/<str:uid>/', ResetPasswordView.as_view(), name='reset-password'),
    # JWT token endpoints
    path('auth/token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('auth/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
]

# Profile URL patterns
profile_patterns = [
    path('profiles/me/', UserProfileView.as_view(), name='user-profile'),
    path('profiles/me/update/', UserProfileUpdateView.as_view(), name='update-profile'),
    path('profiles/users/<str:username>/', PublicUserProfileView.as_view(), name='public-profile'),
    path('profiles/upload/', FileUploadView.as_view(), name='file-upload'),
    
]

# Combine all URL patterns
urlpatterns = auth_patterns + profile_patterns 