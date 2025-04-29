from django.urls import path
from django.contrib.auth import views as auth_views
from rest_framework_simplejwt.views import TokenRefreshView
from .views import (
    RegisterInfoView,
    RegisterView,
    LoginView,
    UserProfileView,
    UserHomeView,
    AIChatView,
    ProductRecommendationsView,
    AdminUserStatsView,
    AdminUserIPLogsView,
    PasswordResetRequestView,
    VerifyOTPView,
    ResetPasswordView,
    ChangePasswordView
)


urlpatterns = [
    path('register-info/', RegisterInfoView.as_view(), name='register-info'),
    path('register/', RegisterView.as_view(), name='register'),
    path('login/', LoginView.as_view(), name='login'),
    path('password-reset-request/', PasswordResetRequestView.as_view(), name='password_reset_request'),
    path('verify-otp/', VerifyOTPView.as_view(), name='verify_otp'),
    path('reset-password/', ResetPasswordView.as_view(), name='reset_password'),
    path('change-password/', ChangePasswordView.as_view(), name='change-password'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('user/profile/', UserProfileView.as_view(), name='api_profile'),
    path('userhome/', UserHomeView.as_view(), name='user-home'),
    path('ai/chat/', AIChatView.as_view(), name='ai-chat'),
    path('recommendations/', ProductRecommendationsView.as_view(), name='product_recommendations'),
    path('admin/user-stats/', AdminUserStatsView.as_view(), name='admin-user-stats'),
    path('admin/user-ip-logs/', AdminUserIPLogsView.as_view(), name='admin-user-ip-logs'),
]
