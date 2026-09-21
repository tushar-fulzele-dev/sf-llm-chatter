/** Google Gemini adapter (generateContent). Auth header is injected by the External Credential. */
public with sharing class GeminiProvider extends LlmProviderBase {

    protected override HttpRequest buildHttpRequest(LlmRequest request) {
        String model = normalizeModel(request.model);

        List<Map<String, Object>> contents = new List<Map<String, Object>>();
        for (LlmMessage m : request.messages) {
            contents.add(new Map<String, Object>{
                // Gemini calls the assistant role "model"
                'role' => (m.role == LlmMessage.ROLE_ASSISTANT ? 'model' : 'user'),
                'parts' => new List<Object>{ new Map<String, Object>{ 'text' => m.content } }
            });
        }

        Map<String, Object> body = new Map<String, Object>{ 'contents' => contents };
        if (request.maxOutputTokens != null) {
            body.put('generationConfig', new Map<String, Object>{ 'maxOutputTokens' => request.maxOutputTokens });
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint(
            'callout:' + request.namedCredential + '/v1beta/models/'
            + EncodingUtil.urlEncode(model, 'UTF-8') + ':generateContent'
        );
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(body));
        return req;
    }

    protected override LlmResponse parseSuccess(LlmRequest request, HttpResponse res) {
        GeminiResponse parsed;
        try {
            parsed = (GeminiResponse) JSON.deserialize(res.getBody(), GeminiResponse.class);
        } catch (JSONException e) {
            throw LlmException.of(LlmException.UNKNOWN);
        }

        String text = '';
        if (parsed != null && parsed.candidates != null && !parsed.candidates.isEmpty()) {
            GeminiContent content = parsed.candidates[0].content;
            if (content != null && content.parts != null) {
                for (GeminiPart p : content.parts) {
                    if (p.text != null) {
                        text += p.text;
                    }
                }
            }
        }
        if (String.isBlank(text)) {
            throw LlmException.of(LlmException.EMPTY_RESPONSE);
        }
        return new LlmResponse(text, normalizeModel(request.model));
    }

    protected override String classifyError(Integer status, String body) {
        String b = (body == null ? '' : body).toUpperCase();
        // Gemini reports a bad API key as HTTP 400, not 401.
        if (b.contains('API_KEY_INVALID') || b.contains('API KEY NOT VALID')) {
            return LlmException.AUTH;
        }
        // Gemini uses 429 for both rate limits and exhausted quota; the body wording is the only hint.
        if (status == 429) {
            return b.contains('QUOTA') ? LlmException.QUOTA : LlmException.RATE_LIMIT;
        }
        return super.classifyError(status, body);
    }

    /** The models list returns "models/gemini-x"; the policy stores the bare id. Accept both. */
    private static String normalizeModel(String model) {
        return model.removeStart('models/');
    }

    private class GeminiResponse {
        public List<GeminiCandidate> candidates;
    }
    private class GeminiCandidate {
        public GeminiContent content;
    }
    private class GeminiContent {
        public List<GeminiPart> parts;
    }
    private class GeminiPart {
        public String text;
    }
}
