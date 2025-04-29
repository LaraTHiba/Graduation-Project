from django.db import models
from django.contrib.auth.models import AbstractUser
from django.utils import timezone

class User(AbstractUser):
    # Override the default email field to make it unique
    email = models.EmailField(unique=True, max_length=254)
    # Additional fields
    email_confirmed = models.BooleanField(default=False)
    phone_number = models.CharField(max_length=15, blank=True, null=True)
    phone_number_confirmed = models.BooleanField(default=False)
    two_factor_enabled = models.BooleanField(default=False)
    lockout_end = models.DateTimeField(null=True, blank=True)
    lockout_enabled = models.BooleanField(default=False)
    access_failed_count = models.IntegerField(default=0)
    user_type = models.CharField(
        max_length=50,
        default='User',
        choices=[('User', 'User'), ('Company', 'Company')],
        null=False
    )
    date_joined = models.DateTimeField(default=timezone.now)
    last_login = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    # Override default fields to ensure they match the schema
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    is_superuser = models.BooleanField(default=False)

    class Meta:
        db_table = 'users'
        verbose_name = 'User'
        verbose_name_plural = 'Users'

    def __str__(self):
        return self.username

    def save(self, *args, **kwargs):
        # Ensure user_type is set
        if not self.user_type:
            self.user_type = 'User'
        super().save(*args, **kwargs)
