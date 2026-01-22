
# Gemini Chat Message
class ChatMessage(models.Model):
    user = models.ForeignKey('users.User', on_delete=models.CASCADE)
    message = models.TextField()
    is_user = models.BooleanField(default=True) # True: 사용자 질문, False: AI 답변
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f'{self.user.email} - {self.message[:20]}'
