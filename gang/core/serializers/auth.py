from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

User = get_user_model()

class UserRegistrationSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True, validators=[validate_password])
    password2 = serializers.CharField(write_only=True, required=True)
    user_type = serializers.ChoiceField(
        choices=[('User', 'User'), ('Company', 'Company')],
        required=True,
        error_messages={
            'required': 'User type is required',
            'invalid_choice': 'User type must be either "User" or "Company"'
        }
    )

    class Meta:
        model = User
        fields = ('username', 'email', 'password', 'password2', 'first_name', 'last_name', 'phone_number', 'user_type')
        extra_kwargs = {
            'first_name': {'required': True},
            'last_name': {'required': True},
            'email': {'required': True},
            'user_type': {'required': True}
        }

    def validate_email(self, value):
        # Get the user_type from the data
        user_type = self.initial_data.get('user_type', 'User')
        
        if user_type == 'Company':
            # List of accepted Palestinian company email domains
            palestinian_domains = [
                # Official Palestinian domains
                'palestine.ps',
                'palestine.com',
                'palestine.net',
                'pal.ps',
                'pal.com',
                'pal.net',
                'palestinian.ps',
                'palestinian.com',
                'palestinian.net',
                # Additional Palestinian domains
                'gaza.ps',
                'gaza.com',
                'gaza.net',
                'ramallah.ps',
                'ramallah.com',
                'ramallah.net',
                'bethlehem.ps',
                'bethlehem.com',
                'bethlehem.net',
                'jerusalem.ps',
                'jerusalem.com',
                'jerusalem.net',
                'nablus.ps',
                'nablus.com',
                'nablus.net',
                'hebron.ps',
                'hebron.com',
                'hebron.net',
                'pna.ps',  # Palestinian National Authority
                'pna.com',
                'pna.net',
                'plo.ps',  # Palestine Liberation Organization
                'plo.com',
                'plo.net',
                'pa.ps',   # Palestinian Authority
                'pa.com',
                'pa.net'
            ]
            
            # Extract domain from email
            email_parts = value.split('@')
            if len(email_parts) != 2:
                raise serializers.ValidationError("Invalid email format")
                
            email_domain = email_parts[-1].lower()
            
            # Check if domain is in the allowed list
            if not any(email_domain.endswith(domain) for domain in palestinian_domains):
                raise serializers.ValidationError(
                    "Company users must use a Palestinian company email domain. "
                    "Accepted domains include: .ps, .com, and .net domains for Palestinian cities and organizations"
                )
            
            # Additional validation rules
            username = email_parts[0].lower()
            
            # Check if username contains company-related terms
            company_terms = ['company', 'corp', 'inc', 'ltd', 'llc', 'enterprise', 'business', 'org', 'co']
            if not any(term in username for term in company_terms):
                raise serializers.ValidationError(
                    "Company email username should contain company-related terms (e.g., company, corp, inc)"
                )
            
            # Check email length
            if len(value) > 254:  # Standard email length limit
                raise serializers.ValidationError("Email address is too long")
        
        return value

    def validate(self, attrs):
        if attrs['password'] != attrs['password2']:
            raise serializers.ValidationError({"password": "Password fields didn't match."})
        return attrs

    def create(self, validated_data):
        validated_data.pop('password2')
        user = User.objects.create_user(**validated_data)
        return user

class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        # Add user data to token payload
        token['username'] = user.username
        token['email'] = user.email
        token['user_type'] = user.user_type  # This will be either 'User' or 'Company'
        return token

    def validate(self, attrs):
        data = super().validate(attrs)
        user = self.user
        
        # Ensure user_type is included in both token and response
        data['user_type'] = user.user_type
        data['user'] = {
            'username': user.username,
            'email': user.email,
            'user_type': user.user_type,
            'first_name': user.first_name,
            'last_name': user.last_name,
        }
        
        # Add tokens to response
        refresh = self.get_token(user)
        data['refresh'] = str(refresh)
        data['access'] = str(refresh.access_token)
        
        return data

class ChangePasswordSerializer(serializers.Serializer):
    old_password = serializers.CharField(required=True)
    new_password = serializers.CharField(required=True, validators=[validate_password])
    new_password2 = serializers.CharField(required=True)

    def validate(self, attrs):
        if attrs['new_password'] != attrs['new_password2']:
            raise serializers.ValidationError({"new_password": "Password fields didn't match."})
        return attrs

class ResetPasswordEmailSerializer(serializers.Serializer):
    email = serializers.EmailField(required=True)

class ResetPasswordSerializer(serializers.Serializer):
    new_password = serializers.CharField(required=True, validators=[validate_password])
    new_password2 = serializers.CharField(required=True)
    token = serializers.CharField(required=True)

    def validate(self, attrs):
        if attrs['new_password'] != attrs['new_password2']:
            raise serializers.ValidationError({"new_password": "Password fields didn't match."})
        return attrs 