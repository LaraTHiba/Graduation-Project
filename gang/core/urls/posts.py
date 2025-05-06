# This file contains post and comment-related URLs

from django.urls import path
from core.views.posts import (
    PostListCreateView,
    PostDetailView,
    UserPostListView,
    CommentListCreateView,
    CommentReplyCreateView,
    PostHardDeleteView,
    DeletedPostListView,
    PostRestoreView,
    SearchPostView,
    CommentDetailView,
    CommentHardDeleteView,
    DeletedCommentListView,
    CommentRestoreView,
    UserCommentListView,
    InterestListView
)

# Post URL patterns
urlpatterns = [
    # Post endpoints
    path('posts/', PostListCreateView.as_view(), name='post-list-create'),
    path('posts/<int:pk>/', PostDetailView.as_view(), name='post-detail'),
    path('posts/user/<str:username>/', UserPostListView.as_view(), name='user-posts'),
    path('posts/search/', SearchPostView.as_view(), name='search-posts'),
    path('posts/deleted/', DeletedPostListView.as_view(), name='deleted-posts'),
    path('posts/<int:pk>/restore/', PostRestoreView.as_view(), name='restore-post'),
    path('posts/<int:pk>/hard-delete/', PostHardDeleteView.as_view(), name='hard-delete-post'),
    
    # Post-related comment endpoints
    path('posts/<int:post_id>/comments/', CommentListCreateView.as_view(), name='comment-list-create'),
    path('posts/<int:post_id>/comments/<int:comment_id>/reply/', CommentReplyCreateView.as_view(), name='comment-reply-create'),
    
    # Comment endpoints
    path('comments/<int:pk>/', CommentDetailView.as_view(), name='comment-detail'),
    path('comments/user/<str:username>/', UserCommentListView.as_view(), name='user-comments'),
    path('comments/deleted/', DeletedCommentListView.as_view(), name='deleted-comments'),
    path('comments/<int:pk>/restore/', CommentRestoreView.as_view(), name='restore-comment'),
    path('comments/<int:pk>/hard-delete/', CommentHardDeleteView.as_view(), name='hard-delete-comment'),
    
    # Interest endpoint
    path('interests/', InterestListView.as_view(), name='interest-list'),
] 