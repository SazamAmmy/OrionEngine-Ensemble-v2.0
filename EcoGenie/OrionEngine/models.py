from django.contrib.auth.models import AbstractUser, UserManager
from django.db import models
from django.utils.translation import gettext_lazy as _
from django_countries.fields import CountryField
from .managers import CustomUserManager
from django.conf import settings




### Custom Manager ###
class CustomUserManager(UserManager):
    def create_user(self, email, username, password=None, **extra_fields):
        if not email:
            raise ValueError('The Email field must be set')

        email = self.normalize_email(email)
        extra_fields.setdefault('is_active', True)

        user = self.model(
            email=email,
            username=username,
            **extra_fields
        )
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, username, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)

        if extra_fields.get('is_staff') is not True:
            raise ValueError('Superuser must have is_staff=True.')
        if extra_fields.get('is_superuser') is not True:
            raise ValueError('Superuser must have is_superuser=True.')

        return self.create_user(email, username, password, **extra_fields)


class CustomUser(AbstractUser):
    email = models.EmailField(_("email address"), unique=True)
    date_of_birth = models.DateField(null=False, blank=False) #Mandatory
    region = CountryField(blank_label='(Select country)', blank=True, null=True)

    terms_and_conditions_accepted = models.BooleanField(default=False)
    terms_accepted_at = models.DateTimeField(null=True, blank=True)

    #Gender Field
    GENDER_CHOICES = [
        ("Male", "Male"),
        ("Female", "Female"),
        ("Prefer not to say", "Prefer not to say"),
    ]
    gender = models.CharField(max_length=20, choices=GENDER_CHOICES, blank=True, null=True)

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["username"]

    objects = CustomUserManager()

    def __str__(self):
        return self.email


"""
Actually this is a User Survey/Questions Answer - Mistakly set as user UserProfile. The real user profile to store actual user profile that sumarises this Survey
Questions including the actual AI made profile will be called AI_UserProfile.
"""
class UserProfile(models.Model):
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,  # Use settings.AUTH_USER_MODEL
        on_delete=models.CASCADE,
        related_name='profile'  # Allows reverse lookup: user.profile
    )
    sustainability_level = models.CharField(
        max_length=50,
        choices=[
            ("Very Sustainable", "Very Sustainable"),
            ("Somewhat Sustainable", "Somewhat Sustainable"),
            ("Not Sustainable", "Not Sustainable"),
            ("I don't know", "I don't know"),
        ],
        blank=True,  # Allow it to be blank initially
        null=True  # Allow it to be null initially
    )
    eco_choices = models.CharField(
        max_length=50,
        choices=[
            ("Always", "Always"),
            ("Often", "Often"),
            ("Rarely", "Rarely"),
            ("Never", "Never"),
        ],
        blank=True,
        null=True
    )
    biggest_challenge = models.CharField(
        max_length=100,
        choices=[
            ("Lack of knowledge", "Lack of knowledge"),
            ("Sustainable products are expensive", "Sustainable products are expensive"),
            ("No time", "No time"),
            ("I don't think it's important", "I don't think it's important"),
        ],
        blank=True,
        null=True
    )
    purchase_preference = models.CharField(
        max_length=50,
        choices=[
            ("Very important", "Very important"),
            ("Somewhat important", "Somewhat important"),
            ("Not important", "Not important"),
        ],
        blank=True,
        null=True
    )
    waste_reduction = models.CharField(
        max_length=50,
        choices=[
            ("Always", "Always"),
            ("Often", "Often"),
            ("Rarely", "Rarely"),
            ("Never", "Never"),
        ],
        blank=True,
        null=True
    )
    energy_saving = models.CharField(
        max_length=50,
        choices=[
            ("Yes", "Yes"),
            ("Sometimes", "Sometimes"),
            ("No", "No"),
        ],
        blank=True,
        null=True
    )
    wants_tips = models.CharField(
        max_length=50,
        choices=[
            ("Yes", "Yes"),
            ("Maybe", "Maybe"),
            ("No", "No"),
        ],
        blank=True,
        null=True
    )

    ai_profile = models.TextField(blank=True, null=True, help_text="AI generated user profile text")


    def __str__(self):
        return f"Profile for {self.user.email}"
    

class AI_UserProfile(models.Model):
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='ai_profile'
    )
    profile_summary = models.TextField(
        blank=True,
        null=True,
    )

    def __str__(self):
        return f"AI Profile of {self.user.username}"



class UserIPLog(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    ipv4_address = models.GenericIPAddressField(null=True, blank=True, protocol='IPv4')
    ipv6_address = models.GenericIPAddressField(null=True, blank=True, protocol='IPv6')
    endpoint = models.CharField(max_length=255)
    timestamp = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.email} - {self.ipv4_address or self.ipv6_address} - {self.endpoint}"


# class Goal(models.Model):
#     user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="goals")
#     name = models.CharField(max_length=255)
#     description = models.TextField()

#     def __str__(self):
#         return self.name

 

# class Recommendation(models.Model):
#     user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="recommendations")
#     content = models.TextField(default="No Recommendation provided")
#     generated_at = models.DateTimeField(default=now)

#     def __str__(self):
#         return f"Recommendation for {self.user.email}"


# class Feedback(models.Model):
#     user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="feedbacks")
#     feedback_text = models.TextField(default="No feedback provided")
#     submitted_at = models.DateTimeField(default=now)

#     def __str__(self):
#         return f"{self.feedback_text} - Feedback by: {self.user.email}"


# class ActivityLog(models.Model):
#     user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="activity_logs")
#     action = models.CharField(max_length=255)
#     timestamp = models.DateTimeField(default=now)
#     details = models.TextField(default='No details provided')

#     def __str__(self):
#         return f"{self.user.email} - {self.action} at {self.timestamp}"



