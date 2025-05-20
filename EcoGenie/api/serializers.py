from rest_framework import serializers
from OrionEngine.models import UserProfile
from OrionEngine.models import UserIPLog

class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserProfile
        fields = [
            "sustainability_level",
            "eco_choices",
            "biggest_challenge",
            "purchase_preference",
            "waste_reduction",
            "energy_saving",
            "wants_tips",
        ]
        # user should be excluded


    #user should be set to the currently authenticated user (i.e., request.user), it should be read-only in the serializer and setted in the save() method.
    def save(self, **kwargs):
        kwargs["user"] = self.context["request"].user
        return super().save(**kwargs)


class UserIPLogSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)

    class Meta:
        model = UserIPLog
        fields = ['username', 'ipv4_address', 'ipv6_address', 'endpoint', 'timestamp']



class PasswordResetRequestSerializer(serializers.Serializer):
    email = serializers.EmailField()
       