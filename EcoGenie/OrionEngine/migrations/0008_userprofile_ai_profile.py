# Generated by Django 5.1.4 on 2025-04-29 04:41

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('OrionEngine', '0007_ai_userprofile'),
    ]

    operations = [
        migrations.AddField(
            model_name='userprofile',
            name='ai_profile',
            field=models.TextField(blank=True, help_text='AI generated user profile text', null=True),
        ),
    ]
