from django.db import migrations, models

class Migration(migrations.Migration):

    dependencies = [
        ('core', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='userdetails',
            name='cv_file',
            field=models.FileField(blank=True, help_text='Upload your CV (PDF, DOC, DOCX)', null=True, upload_to='user_%(user_id)s/'),
        ),
    ] 