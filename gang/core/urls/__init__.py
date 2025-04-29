# This file makes the urls directory a Python package 

# Import URL patterns from modular files
from django.urls import path, include
from core.urls.auth import urlpatterns as auth_urlpatterns
from core.urls.profiles import urlpatterns as profile_urlpatterns 
from core.urls.posts import urlpatterns as post_urlpatterns
from core.urls.posts import comment_urlpatterns

# Combine all URL patterns
urlpatterns = auth_urlpatterns + profile_urlpatterns + post_urlpatterns

# Add comment URLs with a different prefix
urlpatterns += [
    path('comments/', include((comment_urlpatterns, 'comments')))
] 