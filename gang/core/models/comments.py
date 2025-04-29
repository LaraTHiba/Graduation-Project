from django.db import models
from .users import User
from .posts import Post
import os
from django.conf import settings

def comment_image_path(instance, filename):
    # Create directory structure: media/comments/{user_id}/{post_id}_{comment_id}_{filename}
    return os.path.join('comments', str(instance.user.id), f"{instance.post.id}_{instance.id}_{filename}")

class Comment(models.Model):
    post = models.ForeignKey(Post, on_delete=models.CASCADE, related_name='comments')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='comments')
    content = models.TextField()
    parent_comment = models.ForeignKey('self', on_delete=models.CASCADE, null=True, blank=True, related_name='replies')
    image = models.ImageField(upload_to=comment_image_path, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    is_deleted = models.BooleanField(default=False)

    class Meta:
        db_table = 'comments'
        verbose_name = 'Comment'
        verbose_name_plural = 'Comments'

    def __str__(self):
        return f"Comment by {self.user.username} on post {self.post.id}"
    
    def delete(self, *args, **kwargs):
        # Override delete to implement soft delete
        if kwargs.pop('hard_delete', False):
            # If hard_delete is True, perform an actual delete
            super().delete(*args, **kwargs)
        else:
            # Otherwise, just mark as deleted
            self.is_deleted = True
            self.save() 