from django.db import models

# Import all models from the models directory
from core.models.users import User
from core.models.user_details import UserDetails
from core.models.skills import Skill
from core.models.user_skills import UserSkill
from core.models.interests import Interest
from core.models.user_interests import UserInterest
from core.models.company_interests import CompanyInterest
from core.models.notifications import Notification
from core.models.posts import Post
from core.models.comments import Comment

# Create your models here.
