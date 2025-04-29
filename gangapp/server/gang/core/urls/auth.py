# This file makes the urls directory a Python package 

from django.urls import path
from core.views.auth import *

urlpatterns = [
    # Authentication URLs
    path('register/', UserRegistrationView.as_view(), name='register'),
    path('login/', CustomTokenObtainPairView.as_view(), name='login'),
    path('logout/', LogoutView.as_view(), name='logout'),
    path('change-password/', ChangePasswordView.as_view(), name='change-password'),
    path('reset-password-email/', ResetPasswordEmailView.as_view(), name='reset-password-email'),
    path('reset-password/<str:uid>/', ResetPasswordView.as_view(), name='reset-password'),
    path('profile/', UserProfileView.as_view(), name='user-profile'),
] 