/** Anthropic Claude adapter (Messages API). Auth header is injected by the External Credential. */
public with sharing class ClaudeProvider extends LlmProviderBase {
    private static final String API_VERSION = '2023-06-01';
    private static final Integer DEFAULT_MAX_TOKENS = 4096; // max_tokens is REQUIRED by this API

    protected override HttpRequest buildHttpRequest(LlmRequest request) {
        List<Map<String, Object>> messages = new List<Map<String, Object>>();
        for (LlmMessage m : request.messages) {
            messages.add(new Map<String, Object>{ 'role' => m.role, 'content' => m.content });
        }

        Map<String, Object> body = new Map<String, Object>{
            'model' => request.model,
            'max_tokens' => (request.maxOutputTokens == null ? DEFAULT_MAX_TOKENS : request.maxOutputTokens),
            'messages' => messages
        };

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:' + request.namedCredential + '/v1/messages');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('anthropic-version', API_VERSION); // protocol header, not a secret
        req.setBody(JSON.serialize(body));
        return req;
    }

    protected override LlmResponse parseSuccess(LlmRequest request, HttpResponse res) {
        ClaudeResponse parsed;
        try {
            parsed = (ClaudeResponse) JSON.deserialize(res.getBody(), ClaudeResponse.class);
        } catch (JSONException e) {
            throw LlmException.of(LlmException.UNKNOWN);
        }

        // The reply is a list of content blocks. Only text blocks carry "text"; others (e.g. thinking) are skipped.
        String text = '';
        if (parsed != null && parsed.content != null) {
            for (ClaudeBlock block : parsed.content) {
                if (block.text != null) {
                    text += block.text;
                }
            }
        }
        if (String.isBlank(text)) {
            throw LlmException.of(LlmException.EMPTY_RESPONSE);
        }
        return new LlmResponse(text, request.model);
    }

    protected override String classifyError(Integer status, String body) {
        String b = (body == null ? '' : body).toLowerCase();
        // An empty balance is reported as a plain 400, not a 429.
        if (b.contains('credit balance')) {
            return LlmException.QUOTA;
        }
        // 401/403 -> AUTH, 404 -> MODEL_UNAVAILABLE, 429 -> RATE_LIMIT, 5xx and 529 (overloaded) -> PROVIDER_UNAVAILABLE
        return super.classifyError(status, body);
    }

    private class ClaudeResponse {
        public List<ClaudeBlock> content;
    }
    private class ClaudeBlock {
        public String text;
    }
}
