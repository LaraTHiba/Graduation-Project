from django.core.management.base import BaseCommand
from core.models.user_details import UserDetails

class Command(BaseCommand):
    help = 'Prints all users with a PDF CV and their cv_text fields.'

    def handle(self, *args, **options):
        users_with_pdf = UserDetails.objects.filter(cv_file__iendswith='.pdf')
        if not users_with_pdf.exists():
            self.stdout.write(self.style.WARNING('No users with PDF CVs found.'))
            return
        for user_detail in users_with_pdf:
            username = user_detail.user.username if user_detail.user else '(no user)'
            self.stdout.write(self.style.SUCCESS(f'User: {username}'))
            self.stdout.write(f'CV file: {user_detail.cv_file}')
            self.stdout.write(f'cv_text (first 500 chars): {user_detail.cv_text[:500] if user_detail.cv_text else "[EMPTY]"}')
            self.stdout.write('-' * 60) 