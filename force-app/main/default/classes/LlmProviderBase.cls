/**
 * Template Method base class: the shared plumbing (validation, timeout, callout,
 * error mapping) lives here; subclasses supply only what differs per provider.
 */
public abstract with sharing class LlmProviderBase implements LlmProvider {
    private static final Integer DEFAULT_TIMEOUT_MS = 60000;
    private static final Integer MAX_TIMEOUT_MS = 120000; // Salesforce's per-callout ceiling

    /** Build the provider-specific HTTP request (endpoint, body, protocol headers). */
    protected abstract HttpRequest buildHttpRequest(LlmRequest request);

    /** Turn a 2xx response into an LlmResponse. */
    protected abstract LlmResponse parseSuccess(LlmRequest request, HttpResponse res);

    /** Map a non-2xx response to an LlmException code. Override to read provider-specific bodies. */
    protected virtual String classifyError(Integer status, String body) {
        if (status == 401 || status == 403) {
            return LlmException.AUTH;
        }
        if (status == 404) {
            return LlmException.MODEL_UNAVAILABLE;
        }
        if (status == 429) {
            return LlmException.RATE_LIMIT;
        }
        if (status == 400 || status == 413 || status == 422) {
            return LlmException.BAD_REQUEST;
        }
        if (status >= 500) {
            return LlmException.PROVIDER_UNAVAILABLE;
        }
        return LlmException.UNKNOWN;
    }

    public LlmResponse sendChat(LlmRequest request) {
        validate(request);

        HttpRequest req = buildHttpRequest(request);
        req.setTimeout(timeoutFor(request));

        HttpResponse res;
        try {
            res = new Http().send(req);
        } catch (CalloutException e) {
            // Log the exception text (never bodies or headers) so config problems stay diagnosable.
            System.debug(LoggingLevel.WARN, 'LLM callout failed: ' + e.getMessage());
            String msg = e.getMessage() == null ? '' : e.getMessage().toLowerCase();
            throw LlmException.of(msg.contains('timed out') ? LlmException.TIMEOUT : LlmException.PROVIDER_UNAVAILABLE);
        }

        Integer status = res.getStatusCode();
        if (status >= 200 && status < 300) {
            return parseSuccess(request, res);
        }
        System.debug(LoggingLevel.WARN, 'LLM call failed with HTTP ' + status);
        // Debug-log only (never in the exception, DB or UI). Error bodies do not contain our credentials.
        System.debug(LoggingLevel.DEBUG, 'LLM error body (truncated): ' + (res.getBody() == null ? '' : res.getBody().left(500)));
        throw LlmException.of(classifyError(status, res.getBody()));
    }

    private static void validate(LlmRequest request) {
        if (request == null
            || String.isBlank(request.namedCredential)
            || String.isBlank(request.model)
            || request.messages == null
            || request.messages.isEmpty()) {
            throw LlmException.of(LlmException.BAD_REQUEST);
        }
    }

    private static Integer timeoutFor(LlmRequest request) {
        Integer requested = request.timeoutMs == null ? DEFAULT_TIMEOUT_MS : request.timeoutMs;
        return Math.min(requested, MAX_TIMEOUT_MS);
    }
}
