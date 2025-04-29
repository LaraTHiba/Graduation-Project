from django.db import models
from .users import User
from .skills import Skill

class UserSkill(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='skills')
    skill = models.ForeignKey(Skill, on_delete=models.CASCADE)
    proficiency_level = models.IntegerField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'user_skills'
        verbose_name = 'User Skill'
        verbose_name_plural = 'User Skills'
        unique_together = ('user', 'skill')

    def __str__(self):
        return f"{self.user.username}'s {self.skill.name} skill" 