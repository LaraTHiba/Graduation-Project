from django.core.management.base import BaseCommand
from core.models.user_details import UserDetails
from core.utils.cv_extractor import extract_cv_text

class Command(BaseCommand):
    help = 'Re-extracts and saves cv_text for all users with a PDF CV.'

    def handle(self, *args, **options):
        users_with_pdf = UserDetails.objects.filter(cv_file__iendswith='.pdf')
        if not users_with_pdf.exists():
            self.stdout.write(self.style.WARNING('No users with PDF CVs found.'))
            return
        for user_detail in users_with_pdf:
            username = user_detail.user.username if user_detail.user else '(no user)'
            self.stdout.write(self.style.SUCCESS(f'Processing user: {username}'))
            try:
                # Open the file from storage
                cv_file = user_detail.cv_file
                if not cv_file:
                    self.stdout.write(self.style.WARNING('No cv_file found.'))
                    continue
                cv_file.open('rb')
                text = extract_cv_text(cv_file)
                cv_file.close()
                user_detail.cv_text = text
                user_detail.save()
                self.stdout.write(f'Extracted text length: {len(text)}')
                self.stdout.write(f'Sample text: {text[:200]}')
            except Exception as e:
                self.stdout.write(self.style.ERROR(f'Error processing {username}: {str(e)}'))
            self.stdout.write('-' * 60) 