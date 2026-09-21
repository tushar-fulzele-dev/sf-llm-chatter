@IsTest
private class GeminiProviderTest {
    private static final String SUCCESS_BODY =
        '{"candidates":[{"content":{"role":"model","parts":[{"text":"Hello "},{"text":"there"}]},"finishReason":"STOP"}]}';

    private static LlmRequest newRequest() {
        LlmRequest r = new LlmRequest();
        r.namedCredential = 'NC_Test';
        r.model = 'models/gemini-2.5-flash';
        r.messages.add(new LlmMessage(LlmMessage.ROLE_USER, 'Hi'));
        r.messages.add(new LlmMessage(LlmMessage.ROLE_ASSISTANT, 'Hello'));
        r.messages.add(new LlmMessage(LlmMessage.ROLE_USER, 'Explain Apex sets'));
        return r;
    }

    /** Sends with the given canned response and returns the LlmException code (fails if none is thrown). */
    private static String codeFor(HttpCalloutMock mock) {
        Test.setMock(HttpCalloutMock.class, mock);
        try {
            new GeminiProvider().sendChat(newRequest());
        } catch (LlmException e) {
            return e.code;
        }
        Assert.fail('Expected an LlmException');
        return null;
    }

    @IsTest
    static void success_joinsPartsAndNormalizesModel() {
        Test.setMock(HttpCalloutMock.class, new LlmHttpMock(200, SUCCESS_BODY));

        LlmResponse res = new GeminiProvider().sendChat(newRequest());

        Assert.areEqual('Hello there', res.content);
        Assert.areEqual('gemini-2.5-flash', res.model, 'The models/ prefix should be stripped');
    }

    @IsTest
    static void request_isBuiltCorrectly() {
        Test.setMock(HttpCalloutMock.class, new LlmHttpMock(200, SUCCESS_BODY));
        LlmRequest r = newRequest();
        r.maxOutputTokens = 256;

        new GeminiProvider().sendChat(r);

        HttpRequest sent = LlmHttpMock.lastRequest;
        Assert.areEqual('POST', sent.getMethod());
        Assert.isTrue(sent.getEndpoint().startsWith('callout:NC_Test/'), sent.getEndpoint());
        Assert.isTrue(sent.getEndpoint().endsWith('/v1beta/models/gemini-2.5-flash:generateContent'), sent.getEndpoint());

        Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(sent.getBody());
        List<Object> contents = (List<Object>) body.get('contents');
        Assert.areEqual(3, contents.size());
        Assert.areEqual('user', ((Map<String, Object>) contents[0]).get('role'));
        Assert.areEqual('model', ((Map<String, Object>) contents[1]).get('role'), 'assistant must become model');
        Map<String, Object> config = (Map<String, Object>) body.get('generationConfig');
        Assert.areEqual(256, config.get('maxOutputTokens'));
    }

    @IsTest
    static void request_omitsGenerationConfigWhenNoLimit() {
        Test.setMock(HttpCalloutMock.class, new LlmHttpMock(200, SUCCESS_BODY));

        new GeminiProvider().sendChat(newRequest());

        Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(LlmHttpMock.lastRequest.getBody());
        Assert.isFalse(body.containsKey('generationConfig'));
    }

    @IsTest
    static void errorMapping() {
        Assert.areEqual(LlmException.AUTH, codeFor(new LlmHttpMock(400,
            '{"error":{"code":400,"message":"API key not valid.","details":[{"reason":"API_KEY_INVALID"}]}}')),
            'Gemini reports a bad key as 400');
        Assert.areEqual(LlmException.AUTH, codeFor(new LlmHttpMock(403, '{"error":{"status":"PERMISSION_DENIED"}}')));
        Assert.areEqual(LlmException.QUOTA, codeFor(new LlmHttpMock(429,
            '{"error":{"status":"RESOURCE_EXHAUSTED","message":"You exceeded your current quota"}}')));
        Assert.areEqual(LlmException.RATE_LIMIT, codeFor(new LlmHttpMock(429,
            '{"error":{"status":"RESOURCE_EXHAUSTED","message":"Too many requests"}}')));
        Assert.areEqual(LlmException.MODEL_UNAVAILABLE, codeFor(new LlmHttpMock(404, '{"error":{"status":"NOT_FOUND"}}')));
        Assert.areEqual(LlmException.BAD_REQUEST, codeFor(new LlmHttpMock(400,
            '{"error":{"status":"INVALID_ARGUMENT","message":"bad"}}')));
        Assert.areEqual(LlmException.PROVIDER_UNAVAILABLE, codeFor(new LlmHttpMock(503, '{"error":{"status":"UNAVAILABLE"}}')));
        Assert.areEqual(LlmException.UNKNOWN, codeFor(new LlmHttpMock(418, '{}')));
    }

    @IsTest
    static void timeoutAndTransportFailures() {
        Assert.areEqual(LlmException.TIMEOUT, codeFor(LlmHttpMock.throwing('Read timed out')));
        Assert.areEqual(LlmException.PROVIDER_UNAVAILABLE, codeFor(LlmHttpMock.throwing('Unauthorized endpoint, please check Setup')));
    }

    @IsTest
    static void unusableSuccessBodies() {
        Assert.areEqual(LlmException.EMPTY_RESPONSE, codeFor(new LlmHttpMock(200, '{"candidates":[]}')));
        Assert.areEqual(LlmException.EMPTY_RESPONSE, codeFor(new LlmHttpMock(200,
            '{"promptFeedback":{"blockReason":"SAFETY"}}')));
        Assert.areEqual(LlmException.UNKNOWN, codeFor(new LlmHttpMock(200, '{not json')));
    }

    @IsTest
    static void exceptionMessageNeverEchoesProviderBody() {
        Test.setMock(HttpCalloutMock.class, new LlmHttpMock(400, '{"error":{"message":"SECRET-DETAIL API_KEY_INVALID"}}'));
        try {
            new GeminiProvider().sendChat(newRequest());
            Assert.fail('Expected an LlmException');
        } catch (LlmException e) {
            Assert.areEqual(LlmException.messageFor(LlmException.AUTH), e.getMessage());
            Assert.isFalse(e.getMessage().contains('SECRET-DETAIL'));
        }
    }

    @IsTest
    static void invalidRequestsAreRejectedBeforeAnyCallout() {
        LlmRequest noCredential = newRequest();
        noCredential.namedCredential = null;
        LlmRequest noMessages = newRequest();
        noMessages.messages.clear();

        for (LlmRequest r : new List<LlmRequest>{ noCredential, noMessages }) {
            try {
                new GeminiProvider().sendChat(r);
                Assert.fail('Expected an LlmException');
            } catch (LlmException e) {
                Assert.areEqual(LlmException.BAD_REQUEST, e.code);
            }
        }
    }
}
