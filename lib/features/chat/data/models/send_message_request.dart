/// Payload DTO for sending a new concierge message
class SendMessageRequest {
  final String conversationId;
  final String text;
  final String? attachmentUrl;

  const SendMessageRequest({
    required this.conversationId,
    required this.text,
    this.attachmentUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'conversation_id': conversationId,
      'text': text.trim(),
      if (attachmentUrl != null) 'attachment_url': attachmentUrl,
    };
  }
}
