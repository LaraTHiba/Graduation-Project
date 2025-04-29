from rest_framework import serializers
from core.models.interests import Interest

class InterestSerializer(serializers.ModelSerializer):
    class Meta:
        model = Interest
        fields = ['id', 'name', 'description'] 