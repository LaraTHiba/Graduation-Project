# This file makes the urls directory a Python package 

# Import URL patterns from modular files
from django.urls import path, include
from core.urls.auth import urlpatterns as auth_urlpatterns
from core.urls.profiles import urlpatterns as profile_urlpatterns 
from core.urls.posts import urlpatterns as post_urlpatterns
from core.urls.groups import urlpatterns as group_urlpatterns
from rest_framework.routers import DefaultRouter
from core.views.groups import UserGroupViewSet

# Combine all URL patterns
router = DefaultRouter()
router.register(r'groups', UserGroupViewSet, basename='group')

urlpatterns = [
    path('', include(router.urls)),
    path('ai/', include('core.urls.ai_urls')),
]

urlpatterns += auth_urlpatterns + profile_urlpatterns + post_urlpatterns + group_urlpatterns 