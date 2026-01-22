
class ChatView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        messages = ChatMessage.objects.filter(user=request.user).order_by('created_at')
        serializer = ChatMessageSerializer(messages, many=True)
        return Response(serializer.data)

    def post(self, request):
        message_text = request.data.get('message')
        if not message_text:
            return Response({'error': 'Message is required'}, status=status.HTTP_400_BAD_REQUEST)

        # 1. Save user message
        user_message = ChatMessage.objects.create(
            user=request.user,
            message=message_text,
            is_user=True
        )

        # 2. Call Gemini API
        try:
            genai.configure(api_key=settings.GEMINI_API_KEY)
            model = genai.GenerativeModel('gemini-pro')
            prompt = f"금융 전문가로서 답변해 달라\n\n{message_text}"
            response = model.generate_content(prompt)
            ai_response_text = response.text
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        # 3. Save AI response
        ai_message = ChatMessage.objects.create(
            user=request.user,
            message=ai_response_text,
            is_user=False
        )

        # 4. Return both
        return Response({
            'user_message': ChatMessageSerializer(user_message).data,
            'ai_message': ChatMessageSerializer(ai_message).data
        })
