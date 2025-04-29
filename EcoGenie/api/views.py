# Django Core Imports
from django.conf import settings
from django.contrib.auth import authenticate, get_user_model
from django.contrib.auth.tokens import PasswordResetTokenGenerator 
from django.db import IntegrityError
from django.http import JsonResponse
from django.shortcuts import get_object_or_404
from django.template.loader import render_to_string
from django.utils import timezone
from django.core.mail import send_mail


# Third-Party Library Imports
from django_countries import countries
from django_ratelimit.core import is_ratelimited
from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken

# Local Application Imports
from OrionEngine.models import CustomUser, UserProfile, UserIPLog

#serializers
from .serializers import (
    UserProfileSerializer,
    UserIPLogSerializer,
    PasswordResetRequestSerializer,
)

# Custom Modules
from AI.AI import AI

#get the user model defined in settings
User = get_user_model()



# Helper function to apply rate limits to incoming requests.
# Returns a Response object if rate limit is exceeded, otherwise None.
def apply_rate_limits(request, limits, group):
    for limit in limits:
        # Checks if the request exceeds the defined rate limit.
        if is_ratelimited(request, group=group, increment=True, **limit):
            # Returns a 429 Too Many Requests response if rate limited.
            return Response(
                {'error': 'Rate limit exceeded. Please slow down and try again later.'},
                status=status.HTTP_429_TOO_MANY_REQUESTS
            )
    return None

# Custom handler for rate limit exceptions, providing a JSON response.
def custom_ratelimit_exceeded(request, exception=None):
    return JsonResponse(
        {'error': 'Rate limit exceeded. Please slow down and try again later.'},
        status=429
    )


DEFAULT_TERMS_AND_CONDITIONS = """
Welcome to EcoGenie!

By creating an account with EcoGenie, you agree to the following Terms and Conditions:

1. Eligibility
You must be at least 16 years old to create an account and use our services.

2. Account Responsibility
You are responsible for maintaining the confidentiality of your login credentials.
EcoGenie is not liable for any unauthorized activity on your account.

3. Community Guidelines
- Respect other users.
- No harassment, bullying, or discrimination.
- Do not post offensive, illegal, or harmful content.

4. Use of Data
Your personal data is handled according to our Privacy Policy.
We collect information necessary for your account and app experience.

5. Prohibited Activities
You agree not to misuse our services, including but not limited to:
- Attempting to hack or disrupt EcoGenie.
- Sending spam or fraudulent communications.
- Violating any applicable laws or regulations.

6. Termination
EcoGenie reserves the right to suspend or terminate accounts that violate these Terms or behave maliciously.

7. Changes to Terms
EcoGenie may update these Terms from time to time.
We will notify users of significant changes through the app or email.

8. Contact Us
For questions about these Terms, please contact us at support@ecogenie.com.

By checking the box and signing up, you acknowledge that you have read, understood, and agree to these Terms and Conditions.

Thank you for joining EcoGenie and helping make the world greener!
"""

# API view to provide necessary information for user registration.
class RegisterInfoView(APIView):
    # Allows access to any user (authenticated or not).
    permission_classes = [AllowAny]

    # Handles GET requests to retrieve registration data.
    def get(self, request):
        # Defines and applies rate limits for this endpoint.
        rate_limits = [{'rate': '5/m', 'key': 'ip', 'method': 'GET'}]
        rate_limit_response = apply_rate_limits(request, rate_limits, group='register_info_get')
        if rate_limit_response:
            return rate_limit_response

        try:
            # Retrieves a list of countries and their codes.
            country_list = [{"name": name, "code": code} for code, name in list(countries)]
            # Returns terms and conditions text and country list.
            return Response({
                "terms_and_conditions_text": DEFAULT_TERMS_AND_CONDITIONS,
                "countries": country_list
            }, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

# API view to handle user registration.
class RegisterView(APIView):
    permission_classes = [AllowAny]

    # Handles POST requests for new user registration.
    def post(self, request):
        # Defines and applies rate limits for this endpoint.
        rate_limits = [{'rate': '5/m', 'key': 'ip', 'method': 'POST'}]
        rate_limit_response = apply_rate_limits(request, rate_limits, group='register_post')
        if rate_limit_response:
            return rate_limit_response

        try:
            # Extracts user data from the request.
            email = request.data.get('email')
            password = request.data.get('password')
            username = request.data.get('username')
            date_of_birth = request.data.get('date_of_birth')
            region = request.data.get('region')
            gender = request.data.get('gender')
            terms_accepted = request.data.get('terms_and_conditions_accepted')
            if isinstance(terms_accepted, str):
                terms_accepted = terms_accepted.lower() == 'true'

            # Performs validation checks on required fields.
            if not username:
                return Response({'error': 'Username is required.'}, status=status.HTTP_400_BAD_REQUEST)
            # ... (other validation checks) ...
            if not terms_accepted:
                return Response({'error': 'You must accept Terms and Conditions to register.'}, status=status.HTTP_400_BAD_REQUEST)

            #Added: Strong password policy check
            if not password or len(password) < 6 or password.isalnum():
                return Response({
                    'error': 'Password must be at least 6 characters long and include special characters.'
                }, status=status.HTTP_400_BAD_REQUEST)

            try:
                # Creates a new CustomUser instance.
                user = CustomUser.objects.create_user(
                    email=email,
                    username=username,
                    password=password,
                    date_of_birth=date_of_birth,
                    region=region,
                    terms_and_conditions_accepted=terms_accepted,
                    terms_accepted_at=timezone.now(),
                    gender=gender
                )

                # Sending Welcome Email
                send_mail(
                    subject='Welcome to EcoGenie!',
                    message=f'Hi {username},\n\nThank you for joining EcoGenie! We are thrilled to have you onboard.\n\nCheers,\nEcoGenie Team',
                    from_email=settings.DEFAULT_FROM_EMAIL,
                    recipient_list=[email],
                    fail_silently=False
                )

                # Generates JWT tokens (access and refresh) for the newly registered user.
                refresh = RefreshToken.for_user(user)
                # Returns success message and tokens.
                return Response({
                    "message": "User registered successfully",
                    "access": str(refresh.access_token),
                    "refresh": str(refresh)
                }, status=status.HTTP_201_CREATED)

            # Handles specific errors like duplicate email.
            except IntegrityError:
                return Response({'error': 'A user with that email already exists.'}, status=status.HTTP_400_BAD_REQUEST)
            # Handles validation errors during user creation.
            except ValueError as e:
                return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)
            except Exception as e:
                return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# API view to handle user login.
class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        #IP-based rate limiting
        rate_limits = [{'rate': '5/m', 'key': 'ip', 'method': 'POST'}]
        rate_limit_response = apply_rate_limits(request, rate_limits, group='login_post')
        if rate_limit_response:
            return rate_limit_response

        try:
            email = request.data.get('email')
            password = request.data.get('password')

            # Extra Per-email lockout
            login_attempt_key = f'failed_login_attempts_{email}'
            attempts = cache.get(login_attempt_key, 0)
            if attempts >= 5:
                return Response({
                    'error': 'Too many failed login attempts. Try again in 5 minutes.'
                }, status=status.HTTP_429_TOO_MANY_REQUESTS)

            user = authenticate(request, email=email, password=password)

            if user is not None:
                #Successful login — clear failed attempts
                cache.delete(login_attempt_key)

                refresh = RefreshToken.for_user(user)
                return Response({
                    "message": "User logged in successfully",
                    "access": str(refresh.access_token),
                    "refresh": str(refresh),
                    "username": user.username,
                    "email": user.email,
                    "is_staff": user.is_staff
                }, status=status.HTTP_200_OK)
            else:
                #Failed login — increment attempts
                cache.set(login_attempt_key, attempts + 1, timeout=300)  # 5 min cooldown
                return Response({'error': 'Invalid credentials'}, status=status.HTTP_401_UNAUTHORIZED)

        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)




#Forget Password Machanism

#Password Reset Request (Send OTP)

import random
from django.core.cache import cache


class PasswordResetRequestView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        # Rate limit
        rate_limits = [{'rate': '5/m', 'key': 'ip', 'method': 'POST'}]
        rate_limit_response = apply_rate_limits(request, rate_limits, group='password_reset_request')
        if rate_limit_response:
            return rate_limit_response

        try:
            serializer = PasswordResetRequestSerializer(data=request.data)
            if not serializer.is_valid():
                return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

            email = serializer.validated_data['email']
            user = CustomUser.objects.filter(email=email).first()

            if user:
                otp = random.randint(100000, 999999)
                cache_key = f'password_reset_otp_{user.pk}'
                cache.set(cache_key, otp, timeout=300)  # 5 minutes

                subject = 'Your EcoGenie Password Reset OTP'
                message = f"Hi {user.username},\n\nYour OTP for password reset is: {otp}\n\nThis OTP is valid for 5 minutes.\n\nIf you didn't request this, please ignore this email.\n\nThanks,\nEcoGenie Team"

                send_mail(
                    subject,
                    message,
                    settings.DEFAULT_FROM_EMAIL,
                    [user.email],
                    fail_silently=False,
                )

            # Always responds the same to avoid user enumeration
            return Response({'message': 'If an account with that email exists, an OTP has been sent.'}, status=status.HTTP_200_OK)

        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


##Verify OTP
class VerifyOTPView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        rate_limits = [{'rate': '10/m', 'key': 'ip', 'method': 'POST'}]
        rate_limit_response = apply_rate_limits(request, rate_limits, group='verify_otp')
        if rate_limit_response:
            return rate_limit_response

        try:
            email = request.data.get('email')
            otp = request.data.get('otp')

            if not email or not otp:
                return Response({'error': 'Email and OTP are required.'}, status=status.HTTP_400_BAD_REQUEST)

            user = CustomUser.objects.filter(email=email).first()
            if not user:
                return Response({'error': 'Invalid email address.'}, status=status.HTTP_404_NOT_FOUND)

            # Rate limit check per user for OTP verification attempts
            verify_attempts_key = f'otp_verify_attempts_{user.pk}'
            attempts = cache.get(verify_attempts_key, 0)

            if attempts >= 3:
                return Response({'error': 'Too many OTP verification attempts. Please try again later.'}, status=status.HTTP_429_TOO_MANY_REQUESTS)

            cache.set(verify_attempts_key, attempts + 1, timeout=300)  # 5 min window

            # Now check the OTP
            cache_key = f'password_reset_otp_{user.pk}'
            cached_otp = cache.get(cache_key)

            if cached_otp is None:
                return Response({'error': 'OTP expired. Please request a new one.'}, status=status.HTTP_400_BAD_REQUEST)

            if str(cached_otp) != str(otp):
                return Response({'error': 'Invalid OTP.'}, status=status.HTTP_400_BAD_REQUEST)

            # OTP Verified, reset attempts counter
            cache.delete(verify_attempts_key)

            # Mark user verified
            cache.set(f'password_reset_verified_{user.pk}', True, timeout=600)  # 10 mins

            return Response({'message': 'OTP verified successfully.'}, status=status.HTTP_200_OK)

        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


####Reset Password
class ResetPasswordView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        rate_limits = [{'rate': '5/m', 'key': 'ip', 'method': 'POST'}]
        rate_limit_response = apply_rate_limits(request, rate_limits, group='reset_password')
        if rate_limit_response:
            return rate_limit_response

        try:
            email = request.data.get('email')
            new_password = request.data.get('new_password')

            if not email or not new_password:
                return Response({'error': 'Email and new password are required.'}, status=status.HTTP_400_BAD_REQUEST)

            user = CustomUser.objects.filter(email=email).first()
            if not user:
                return Response({'error': 'Invalid email address.'}, status=status.HTTP_404_NOT_FOUND)

            verified = cache.get(f'password_reset_verified_{user.pk}')
            if not verified:
                return Response({'error': 'OTP verification required before resetting password.'}, status=status.HTTP_403_FORBIDDEN)


             # 🔥 Rate limit check per user for password resets
            reset_attempt_key = f'password_reset_attempts_{user.pk}'
            reset_attempts = cache.get(reset_attempt_key, 0)

            if reset_attempts >= 1:
                return Response({'error': 'Password reset limit exceeded. Please wait before trying again.'}, status=status.HTTP_429_TOO_MANY_REQUESTS)

            cache.set(reset_attempt_key, reset_attempts + 1, timeout=300)  # 5 min window


            # Reset password
            user.set_password(new_password)
            user.save()

            # Clear OTP and verification flags
            cache.delete(f'password_reset_otp_{user.pk}')
            cache.delete(f'password_reset_verified_{user.pk}')

            #Send Password Reset Success Email
            subject = 'Your EcoGenie Password Reset Confirmation'
            message = f"Hi {user.username},\n\nYour password has been successfully reset.\n\nIf you did not perform this action, please contact EcoGenie Support immediately.\n\nThanks,\nEcoGenie Team"

            send_mail(
                subject,
                message,
                settings.DEFAULT_FROM_EMAIL,
                [user.email],
                fail_silently=False,
            )

            return Response({'message': 'Password has been reset successfully.'}, status=status.HTTP_200_OK)

        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)



###Change Paaword from the profile section -user should be logged in 

class ChangePasswordView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        user = request.user
        current_password = request.data.get("current_password")
        new_password = request.data.get("new_password")

        # 1. Validate presence of both fields
        if not current_password or not new_password:
            return Response({'message': 'Both current_password and new_password are required.'}, status=status.HTTP_400_BAD_REQUEST)

        # 2. Verify current password
        if not user.check_password(current_password):
            return Response({'message': 'Incorrect current password.'}, status=status.HTTP_401_UNAUTHORIZED)

        # 3. Update password
        try:
            user.set_password(new_password)
            user.save()
            return Response({'message': 'Password updated successfully!'}, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# API view to manage user profiles.
class UserProfileView(APIView):
    # Requires the user to be authenticated.
    permission_classes = [IsAuthenticated]

    # Handles GET requests to retrieve the authenticated user's profile.
    def get(self, request):
        # Applies user-specific and IP-specific rate limits.
        rate_limits = [
            {'rate': '5/m', 'key': 'user', 'method': 'GET'},
            {'rate': '100/d', 'key': 'user', 'method': 'GET'},
        ]
        rate_limit_response = apply_rate_limits(request, rate_limits, group='user_profile_get')
        if rate_limit_response:
            return rate_limit_response

        try:
            # Retrieves the UserProfile for the current user, or returns 404 if not found.
            profile = get_object_or_404(UserProfile, user=request.user)
            # Serializes the profile data.
            serializer = UserProfileSerializer(profile)
            # Combines profile data with basic user data.
            user_data = {
                "email": request.user.email,
                "username": request.user.username,
                "is_staff": request.user.is_staff,
                "date_of_birth": request.user.date_of_birth,
            }
            response_data = {**serializer.data, **user_data}
            # Returns the combined profile data.
            return Response(response_data)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    # Handles POST requests to update or create the authenticated user's profile.
    def post(self, request):
        # Applies user-specific and IP-specific rate limits.
        rate_limits = [
            {'rate': '5/m', 'key': 'user', 'method': 'POST'},
            {'rate': '100/d', 'key': 'user', 'method': 'POST'},
        ]
        rate_limit_response = apply_rate_limits(request, rate_limits, group='user_profile_post')
        if rate_limit_response:
            return rate_limit_response

        try:
            try:
                # Attempts to get the existing profile for the user.
                profile = request.user.profile
                # Initializes serializer with existing profile for update.
                serializer = UserProfileSerializer(profile, data=request.data, context={"request": request})
            except UserProfile.DoesNotExist:
                # If profile doesn't exist, initializes serializer for creation.
                serializer = UserProfileSerializer(data=request.data, context={"request": request})
            except AttributeError:
                return Response({'error': 'User profile could not be accessed. Ensure it exists and is linked correctly.'}, status=status.HTTP_400_BAD_REQUEST)

            # Validates the incoming data against the serializer.
            if serializer.is_valid():
                # Saves the data, linking it to the current user.
                serializer.save(user=request.user)
                # Returns the updated/created profile data.
                return Response(serializer.data, status=status.HTTP_200_OK)
            # Returns validation errors if data is invalid.
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


#### AI Stuffs #########

##Helper Function profile.

def get_effective_user_profile(user):
    """
    Returns the effective user profile for AI usage.
    - If ai_profile exists, return ai_profile text (string).
    - Otherwise, return survey data combined with basic user info (dict).
    """
    try:
        profile = user.profile  # related_name='profile'
    except UserProfile.DoesNotExist:
        return None

    if profile.ai_profile:
        return profile.ai_profile  # String

    # Build from survey fields if ai_profile doesn't exist yet
    serializer = UserProfileSerializer(profile)
    basic_user_info = {
        "name": user.username,
        "date_of_birth": user.date_of_birth,
        "user_region": user.region,
        "user_gender": user.gender,
    }
    return {**serializer.data, **basic_user_info}




# API view for the user's home screen data.
class UserHomeView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        # Apply rate limits
        rate_limits = [
            {'rate': '5/m', 'key': 'user', 'method': 'GET'},
            {'rate': '100/d', 'key': 'user', 'method': 'GET'},
        ]
        rate_limit_response = apply_rate_limits(request, rate_limits, group='user_home_get')
        if rate_limit_response:
            return rate_limit_response

        try:
            # Profile Helper Function
            user_profile_data = get_effective_user_profile(request.user)

            if not user_profile_data:
                return Response({"error": "User profile not found."}, status=status.HTTP_404_NOT_FOUND)

            # Send to AI
            ai_response = AI.AI_home_response(user_profile=user_profile_data)

            return Response({"home_response": ai_response}, status=status.HTTP_200_OK)

        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# API view to handle AI chat interactions.
class AIChatView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        # Rate limits
        rate_limits = [
            {'rate': '15/m', 'key': 'user', 'method': 'POST'},
            {'rate': '100/d', 'key': 'user', 'method': 'POST'},
        ]
        rate_limit_response = apply_rate_limits(request, rate_limits, group='ai_chat_post')
        if rate_limit_response:
            return rate_limit_response

        try:
            chat_history = request.data.get("chat_history", [])
            if not isinstance(chat_history, list) or not chat_history:
                return Response({"error": "chat_history must be a non-empty list."}, status=status.HTTP_400_BAD_REQUEST)

            user_profile_data = get_effective_user_profile(request.user)
            if not user_profile_data:
                return Response({"error": "User profile not found."}, status=status.HTTP_404_NOT_FOUND)

            ai_response_data = AI.get_response(chat_history=chat_history, user_profile=user_profile_data)

            #Save new AI profile if returned
            if "new_profile" in ai_response_data:
                profile = request.user.profile
                profile.ai_profile = ai_response_data["new_profile"]
                profile.save()

            return Response({"ai_response": ai_response_data.get("response")}, status=status.HTTP_200_OK)

        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)



# API view to provide product recommendations.
import math

class ProductRecommendationsView(APIView):
    permission_classes = [IsAuthenticated]

    REQUIRED_FIELDS = ["title", "brand", "description", "image-link", "site-link"]

    def clean_products(self, products):
        """
        Ensures each product contains only required fields 
        and replace missing or NaN values with 'Not available'.
        """
        cleaned_products = []
        for product in products:
            cleaned = {}
            for field in self.REQUIRED_FIELDS:
                value = product.get(field, "Not available")
                if value is None or (isinstance(value, float) and math.isnan(value)):
                    value = "Not available"
                cleaned[field] = value
            cleaned_products.append(cleaned)
        return cleaned_products

    def get(self, request):
        """
        GET - Generate product recommendations based on the user's profile
        """
        # Apply user-specific rate limits
        rate_limits = [
            {'rate': '5/m', 'key': 'user', 'method': 'GET'},
            {'rate': '100/d', 'key': 'user', 'method': 'GET'},
        ]
        rate_limit_response = apply_rate_limits(request, rate_limits, group='product_recommendations_get')
        if rate_limit_response:
            return rate_limit_response

        try:
            # Step 1: Get effective user profile data
            user_profile_data = get_effective_user_profile(request.user)
            if not user_profile_data:
                return Response({"error": "User profile not found."}, status=status.HTTP_404_NOT_FOUND)

            # Step 2: Generate query from the user profile
            generated_query = AI.get_product_query_from_profile(user_profile_data)

            # Step 3: Paraphrase the generated query
            paraphrased_query = AI.paraphrase_query(generated_query)

            # Step 4: Get matching products
            products = AI.get_products(paraphrased_query)

            # Step 5: Clean products
            products = self.clean_products(products)

            return Response({"products": products}, status=status.HTTP_200_OK)

        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    def post(self, request):
        """
        POST - Search for products based on a custom user query
        """
        # Apply user-specific rate limits
        rate_limits = [
            {'rate': '10/m', 'key': 'user', 'method': 'POST'},
            {'rate': '500/d', 'key': 'user', 'method': 'POST'},
        ]
        rate_limit_response = apply_rate_limits(request, rate_limits, group='product_recommendations_post')
        if rate_limit_response:
            return rate_limit_response

        try:
            query = request.data.get('query', '')

            if not query:
                return Response({'error': 'Query field is required.'}, status=status.HTTP_400_BAD_REQUEST)

            # Step 1: Paraphrase the user's custom query
            paraphrased_query = AI.paraphrase_query(query)

            # Step 2: Get matching products
            products = AI.get_products(paraphrased_query)

            # Step 3: Clean products
            products = self.clean_products(products)

            return Response({"products": products}, status=status.HTTP_200_OK)

        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)



# Admin API view to get user statistics.
class AdminUserStatsView(APIView):
    # Requires the user to be authenticated.
    permission_classes = [IsAuthenticated]

    # Handles GET requests for user statistics.
    def get(self, request):
        # Applies user-specific and IP-specific rate limits.
        rate_limits = [
            {'rate': '15/m', 'key': 'user', 'method': 'GET'},
            {'rate': '200/d', 'key': 'user', 'method': 'GET'},
        ]
        rate_limit_response = apply_rate_limits(request, rate_limits, group='admin_user_stats_get')
        if rate_limit_response:
            return rate_limit_response

        # Checks if the authenticated user is a staff member (admin).
        if not request.user.is_staff:
            # Returns forbidden if user is not an admin.
            return Response({"error": "Unauthorized access. Admins only."}, status=status.HTTP_403_FORBIDDEN)

        try:
            # Queries the database to get user counts by type.
            total_users = CustomUser.objects.count()
            admin_users = CustomUser.objects.filter(is_staff=True).count()
            super_admin_users = CustomUser.objects.filter(is_superuser=True).count()
            normal_users = total_users - admin_users

            # Returns the user statistics.
            return Response({
                "total_users": total_users,
                "admin_users": admin_users,
                "normal_users": normal_users,
                "super_admin_users": super_admin_users
            }, status=status.HTTP_200_OK)

        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

# Admin API view to get user IP logs.
class AdminUserIPLogsView(APIView):
    # Requires the user to be authenticated.
    permission_classes = [IsAuthenticated]

    # Handles GET requests for user IP logs.
    def get(self, request):
        # Applies user-specific and IP-specific rate limits.
        rate_limits = [
            {'rate': '15/m', 'key': 'user', 'method': 'GET'},
            {'rate': '200/d', 'key': 'user', 'method': 'GET'},
        ]
        rate_limit_response = apply_rate_limits(request, rate_limits, group='admin_ip_logs_get')
        if rate_limit_response:
            return rate_limit_response

        # Checks if the authenticated user is a staff member (admin).
        if not request.user.is_staff:
            # Returns forbidden if user is not an admin.
            return Response({"error": "Unauthorized access. Admins only."}, status=status.HTTP_403_FORBIDDEN)

        try:
            # Retrieves the latest 100 IP logs, ordered by timestamp.
            logs = UserIPLog.objects.all().order_by('-timestamp')[:100]
            # Serializes the log data.
            serializer = UserIPLogSerializer(logs, many=True)
            # Returns the list of serialized logs.
            return Response({"logs": serializer.data}, status=status.HTTP_200_OK)

        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)