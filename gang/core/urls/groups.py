from django.urls import path, include
from rest_framework.routers import DefaultRouter
from core.views.groups import UserGroupViewSet

router = DefaultRouter()
router.register(r'groups', UserGroupViewSet, basename='group')

urlpatterns = [
    path('', include(router.urls)),
] 