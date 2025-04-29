from django.db import models
from .users import User
from .interests import Interest

class CompanyInterest(models.Model):
    company = models.ForeignKey(User, on_delete=models.CASCADE, related_name='company_interests')
    interest = models.ForeignKey(Interest, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'company_interests'
        verbose_name = 'Company Interest'
        verbose_name_plural = 'Company Interests'
        unique_together = ('company', 'interest')

    def __str__(self):
        return f"{self.company.username}'s {self.interest.name} interest" 