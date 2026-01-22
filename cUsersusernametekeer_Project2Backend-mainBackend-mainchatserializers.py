
class ChatMessageSerializer(serializers.ModelSerializer):
    class Meta:
        model = ChatMessage
        fields = ['user', 'message', 'is_user', 'created_at']
        read_only_fields = ['user', 'created_at']
