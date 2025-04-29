# This file contains authentication-related URLs

from django.urls import path
from core.views.auth import (
    UserRegistrationView,
    CustomTokenObtainPairView,
    LogoutView,
    ChangePasswordView,
    ResetPasswordEmailView,
    ResetPasswordView,
    UserProfileView
)
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
)

urlpatterns = [
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