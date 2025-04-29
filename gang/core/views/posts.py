from rest_framework import generics, permissions, status, views, filters
from rest_framework.response import Response
from rest_framework.exceptions import PermissionDenied
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from django.db.models import Q
from core.models.posts import Post
from core.models.comments import Comment
from core.serializers.posts import PostSerializer, CommentSerializer
from core.models.interests import Interest
from core.serializers.interests import InterestSerializer


class PostListCreateView(generics.ListCreateAPIView):
    serializer_class = PostSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def get_queryset(self):
        # Return only non-deleted posts by default
        return Post.objects.filter(is_deleted=False).order_by('-created_at')

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class PostDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = PostSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]
    
    def get_queryset(self):
        # Include both deleted and non-deleted posts for retrieval
        return Post.objects.all()

    def perform_update(self, serializer):
        post = self.get_object()
        if post.user != self.request.user:
            raise PermissionDenied("You do not have permission to edit this post")
        serializer.save()

    def perform_destroy(self, instance):
        if instance.user != self.request.user:
            raise PermissionDenied("You do not have permission to delete this post")
        instance.delete()  # This uses our overridden delete method for soft delete


class PostHardDeleteView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]
    
    def delete(self, request, pk):
        try:
            post = Post.objects.get(pk=pk)
            
            # Only the post owner can delete it
            if post.user != request.user:
                raise PermissionDenied("You do not have permission to delete this post")
                
            # Permanently delete the post
            post.delete(hard_delete=True)
            return Response(status=status.HTTP_204_NO_CONTENT)
            
        except Post.DoesNotExist:
            return Response({'error': 'Post not found'}, status=status.HTTP_404_NOT_FOUND)


class UserPostListView(generics.ListAPIView):
    serializer_class = PostSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        username = self.kwargs.get('username')
        # Only return non-deleted posts by default
        return Post.objects.filter(user__username=username, is_deleted=False).order_by('-created_at')


class DeletedPostListView(generics.ListAPIView):
    serializer_class = PostSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        # Only return the current user's deleted posts
        return Post.objects.filter(user=self.request.user, is_deleted=True).order_by('-updated_at')


class PostRestoreView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request, pk):
        try:
            post = Post.objects.get(pk=pk)
            
            # Only the post owner can restore it
            if post.user != request.user:
                raise PermissionDenied("You do not have permission to restore this post")
                
            # Restore the post
            post.is_deleted = False
            post.save()
            
            serializer = PostSerializer(post, context={'request': request})
            return Response(serializer.data)
            
        except Post.DoesNotExist:
            return Response({'error': 'Post not found'}, status=status.HTTP_404_NOT_FOUND)


class SearchPostView(generics.ListAPIView):
    serializer_class = PostSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [filters.SearchFilter]
    search_fields = ['title', 'content', 'user__username']
    
    def get_queryset(self):
        # Only search non-deleted posts
        return Post.objects.filter(is_deleted=False).order_by('-created_at')


class CommentListCreateView(generics.ListCreateAPIView):
    serializer_class = CommentSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def get_queryset(self):
        post_id = self.kwargs.get('post_id')
        # Only return non-deleted top-level comments
        return Comment.objects.filter(
            post_id=post_id, 
            parent_comment=None,
            is_deleted=False
        ).order_by('-created_at')

    def perform_create(self, serializer):
        post_id = self.kwargs.get('post_id')
        post = Post.objects.get(id=post_id)
        serializer.save(user=self.request.user, post=post)


class CommentDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = CommentSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]
    
    def get_queryset(self):
        # Include both deleted and non-deleted comments for retrieval
        return Comment.objects.all()
    
    def perform_update(self, serializer):
        comment = self.get_object()
        if comment.user != self.request.user:
            raise PermissionDenied("You do not have permission to edit this comment")
        serializer.save()
    
    def perform_destroy(self, instance):
        if instance.user != self.request.user:
            raise PermissionDenied("You do not have permission to delete this comment")
        instance.delete()  # This uses our overridden delete method for soft delete


class CommentHardDeleteView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]
    
    def delete(self, request, pk):
        try:
            comment = Comment.objects.get(pk=pk)
            
            # Only the comment owner can delete it
            if comment.user != request.user:
                raise PermissionDenied("You do not have permission to delete this comment")
                
            # Permanently delete the comment
            comment.delete(hard_delete=True)
            return Response(status=status.HTTP_204_NO_CONTENT)
            
        except Comment.DoesNotExist:
            return Response({'error': 'Comment not found'}, status=status.HTTP_404_NOT_FOUND)


class DeletedCommentListView(generics.ListAPIView):
    serializer_class = CommentSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        # Only return the current user's deleted comments
        return Comment.objects.filter(user=self.request.user, is_deleted=True).order_by('-updated_at')


class CommentRestoreView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request, pk):
        try:
            comment = Comment.objects.get(pk=pk)
            
            # Only the comment owner can restore it
            if comment.user != request.user:
                raise PermissionDenied("You do not have permission to restore this comment")
                
            # Restore the comment
            comment.is_deleted = False
            comment.save()
            
            serializer = CommentSerializer(comment, context={'request': request})
            return Response(serializer.data)
            
        except Comment.DoesNotExist:
            return Response({'error': 'Comment not found'}, status=status.HTTP_404_NOT_FOUND)


class CommentReplyCreateView(generics.CreateAPIView):
    serializer_class = CommentSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def perform_create(self, serializer):
        post_id = self.kwargs.get('post_id')
        parent_id = self.kwargs.get('comment_id')
        post = Post.objects.get(id=post_id)
        parent_comment = Comment.objects.get(id=parent_id)
        serializer.save(user=self.request.user, post=post, parent_comment=parent_comment)


class UserCommentListView(generics.ListAPIView):
    serializer_class = CommentSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        username = self.kwargs.get('username')
        # Only return non-deleted comments
        return Comment.objects.filter(
            user__username=username, 
            is_deleted=False
        ).order_by('-created_at')


class InterestListView(generics.ListAPIView):
    """
    List all available interests.
    """
    serializer_class = InterestSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return Interest.objects.all().order_by('name') 