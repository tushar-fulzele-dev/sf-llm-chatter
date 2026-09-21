/** OpenAI adapter (Chat Completions). Auth header is injected by the External Credential. */
public with sharing class OpenAiProvider extends LlmProviderBase {

    protected override HttpRequest buildHttpRequest(LlmRequest request) {
        List<Map<String, Object>> messages = new List<Map<String, Object>>();
        for (LlmMessage m : request.messages) {
            // OpenAI uses the same role names we do.
            messages.add(new Map<String, Object>{ 'role' => m.role, 'content' => m.content });
        }

        Map<String, Object> body = new Map<String, Object>{
            'model' => request.model,
            'messages' => messages
        };
        if (request.maxOutputTokens != null) {
            // max_tokens is deprecated (and rejected by reasoning models); max_completion_tokens replaces it.
            body.put('max_completion_tokens', request.maxOutputTokens);
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:' + request.namedCredential + '/v1/chat/completions');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(body));
        return req;
    }

    protected override LlmResponse parseSuccess(LlmRequest request, HttpResponse res) {
        OpenAiResponse parsed;
        try {
            parsed = (OpenAiResponse) JSON.deserialize(res.getBody(), OpenAiResponse.class);
        } catch (JSONException e) {
            throw LlmException.of(LlmException.UNKNOWN);
        }

        String text;
        if (parsed != null && parsed.choices != null && !parsed.choices.isEmpty() && parsed.choices[0].message != null) {
            text = parsed.choices[0].message.content;
        }
        // Blank content also covers refusals and reasoning models that spent the whole token cap thinking.
        if (String.isBlank(text)) {
            throw LlmException.of(LlmException.EMPTY_RESPONSE);
        }
        return new LlmResponse(text, request.model);
    }

    protected override String classifyError(Integer status, String body) {
        String b = (body == null ? '' : body).toLowerCase();
        // OpenAI uses 429 for both rate limits and an empty balance; the error code tells them apart.
        if (b.contains('insufficient_quota')) {
            return LlmException.QUOTA;
        }
        if (b.contains('model_not_found')) {
            return LlmException.MODEL_UNAVAILABLE;
        }
        return super.classifyError(status, body);
    }

    private class OpenAiResponse {
        public List<OpenAiChoice> choices;
    }
    private class OpenAiChoice {
        public OpenAiMessage message;
    }
    private class OpenAiMessage {
        public String content;
    }
}
