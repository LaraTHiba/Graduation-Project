from django.db import models
from .users import User
from .interests import Interest

class UserInterest(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='interests')
    interest = models.ForeignKey(Interest, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'user_interests'
        verbose_name = 'User Interest'
        verbose_name_plural = 'User Interests'
        unique_together = ('user', 'interest')

    def __str__(self):
        return f"{self.user.username}'s {self.interest.name} interest" 