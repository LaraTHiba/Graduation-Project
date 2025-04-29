from django.contrib import admin
from core.models.posts import Post
from core.models.comments import Comment
from core.models.interests import Interest
from core.models.users import User
from core.models.user_details import UserDetails
# Register your models here.
admin.site.register(Post)
admin.site.register(Comment)
admin.site.register(Interest)   
admin.site.register(User)
admin.site.register(UserDetails)
