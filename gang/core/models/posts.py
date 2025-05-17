from django.db import models
from .users import User
from .interests import Interest
import os
from django.conf import settings

def post_image_path(instance, filename):
    # Create directory structure: media/posts/{user_id}/{post_id}_{filename}
    if instance.id is None:
        # If post doesn't have an ID yet, use a temporary name
        return os.path.join('posts', str(instance.user.id), f"temp_{filename}")
    return os.path.join('posts', str(instance.user.id), f"{instance.id}_{filename}")

class Post(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='posts')
    title = models.CharField(max_length=255)
    content = models.TextField()
    image_url = models.URLField(max_length=255, blank=True, null=True)
    # New image field that uses the storage path function
    image = models.ImageField(upload_to=post_image_path, blank=True, null=True)
    interest = models.ForeignKey(Interest, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    is_deleted = models.BooleanField(default=False)

    class Meta:
        db_table = 'posts'
        verbose_name = 'Post'
        verbose_name_plural = 'Posts'

    def __str__(self):
        return f"Post by {self.user.username}: {self.title[:50]}"
    
    def delete(self, *args, **kwargs):
        # Override delete to implement soft delete
        if kwargs.pop('hard_delete', False):
            # If hard_delete is True, perform an actual delete
            super().delete(*args, **kwargs)
        else:
            # Otherwise, just mark as deleted
            self.is_deleted = True
            self.save()

    def save(self, *args, **kwargs):
        # If this is a new post and has an image
        if self.id is None and self.image:
            # Save the post first to get an ID
            super().save(*args, **kwargs)
            # Update the image path with the new post ID
            if self.image.name.startswith('posts/'):
                old_path = self.image.path
                new_name = f"{self.id}_{os.path.basename(self.image.name)}"
                new_path = os.path.join(os.path.dirname(old_path), new_name)
                os.rename(old_path, new_path)
                self.image.name = os.path.join('posts', str(self.user.id), new_name)
                super().save(update_fields=['image'])
        else:
            super().save(*args, **kwargs) 