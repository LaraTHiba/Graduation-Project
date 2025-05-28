# Re-export the URL patterns from the urls package
from core.urls import urlpatterns as core_urlpatterns

# This file is kept for compatibility reasons
# The actual URL patterns are defined in the core/urls/ directory 

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from core.views.groups import UserGroupViewSet

router = DefaultRouter()
router.register(r'groups', UserGroupViewSet, basename='group')

urlpatterns = [
    path('', include(core_urlpatterns)),
] 