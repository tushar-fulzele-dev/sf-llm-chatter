@IsTest
private class OpenAiProviderTest {
    private static final String SUCCESS_BODY =
        '{"model":"gpt-test","choices":[{"index":0,"message":{"role":"assistant","content":"Hello there"},"finish_reason":"stop"}]}';

    @IsTest
    static void success_returnsTheAssistantText() {
        Test.setMock(HttpCalloutMock.class, new LlmHttpMock(200, SUCCESS_BODY));

        LlmResponse res = new OpenAiProvider().sendChat(LlmTestUtil.newRequest());

        Assert.areEqual('Hello there', res.content);
        Assert.areEqual('test-model', res.model);
    }

    @IsTest
    static void request_isBuiltCorrectly() {
        Test.setMock(HttpCalloutMock.class, new LlmHttpMock(200, SUCCESS_BODY));
        LlmRequest r = LlmTestUtil.newRequest();
        r.maxOutputTokens = 256;

        new OpenAiProvider().sendChat(r);

        Assert.areEqual('POST', LlmHttpMock.lastRequest.getMethod());
        Assert.areEqual('callout:NC_Test/v1/chat/completions', LlmHttpMock.lastRequest.getEndpoint());
        Map<String, Object> body = LlmTestUtil.sentBody();
        Assert.areEqual('test-model', body.get('model'));
        List<Object> messages = (List<Object>) body.get('messages');
        Assert.areEqual(3, messages.size());
        Assert.areEqual('assistant', ((Map<String, Object>) messages[1]).get('role'));
        Assert.areEqual(256, body.get('max_completion_tokens'));
        Assert.isFalse(body.containsKey('max_tokens'), 'max_tokens is deprecated; max_completion_tokens replaces it');
    }

    @IsTest
    static void request_omitsTokenCapWhenNotRequested() {
        Test.setMock(HttpCalloutMock.class, new LlmHttpMock(200, SUCCESS_BODY));

        new OpenAiProvider().sendChat(LlmTestUtil.newRequest());

        Assert.isFalse(LlmTestUtil.sentBody().containsKey('max_completion_tokens'));
    }

    @IsTest
    static void errorMapping() {
        OpenAiProvider p = new OpenAiProvider();
        Assert.areEqual(LlmException.AUTH, LlmTestUtil.codeFor(p, new LlmHttpMock(401,
            '{"error":{"code":"invalid_api_key","message":"Incorrect API key provided"}}')));
        Assert.areEqual(LlmException.QUOTA, LlmTestUtil.codeFor(p, new LlmHttpMock(429,
            '{"error":{"code":"insufficient_quota","message":"You exceeded your current quota"}}')));
        Assert.areEqual(LlmException.RATE_LIMIT, LlmTestUtil.codeFor(p, new LlmHttpMock(429,
            '{"error":{"code":"rate_limit_exceeded","message":"Rate limit reached"}}')));
        Assert.areEqual(LlmException.MODEL_UNAVAILABLE, LlmTestUtil.codeFor(p, new LlmHttpMock(404,
            '{"error":{"code":"model_not_found","message":"The model does not exist"}}')));
        Assert.areEqual(LlmException.BAD_REQUEST, LlmTestUtil.codeFor(p, new LlmHttpMock(400,
            '{"error":{"code":"invalid_request_error"}}')));
        Assert.areEqual(LlmException.PROVIDER_UNAVAILABLE, LlmTestUtil.codeFor(p, new LlmHttpMock(503, '{}')));
    }

    @IsTest
    static void timeoutAndTransportFailures() {
        OpenAiProvider p = new OpenAiProvider();
        Assert.areEqual(LlmException.TIMEOUT, LlmTestUtil.codeFor(p, LlmHttpMock.throwing('Read timed out')));
        Assert.areEqual(LlmException.PROVIDER_UNAVAILABLE, LlmTestUtil.codeFor(p, LlmHttpMock.throwing('Unauthorized endpoint')));
    }

    @IsTest
    static void unusableSuccessBodies() {
        OpenAiProvider p = new OpenAiProvider();
        Assert.areEqual(LlmException.EMPTY_RESPONSE, LlmTestUtil.codeFor(p, new LlmHttpMock(200, '{"choices":[]}')));
        Assert.areEqual(LlmException.EMPTY_RESPONSE, LlmTestUtil.codeFor(p, new LlmHttpMock(200,
            '{"choices":[{"message":{"role":"assistant","content":null,"refusal":"No"}}]}')));
        Assert.areEqual(LlmException.UNKNOWN, LlmTestUtil.codeFor(p, new LlmHttpMock(200, '{not json')));
    }

    @IsTest
    static void exceptionMessageNeverEchoesProviderBody() {
        Test.setMock(HttpCalloutMock.class, new LlmHttpMock(401, '{"error":{"message":"SECRET-DETAIL"}}'));
        try {
            new OpenAiProvider().sendChat(LlmTestUtil.newRequest());
            Assert.fail('Expected an LlmException');
        } catch (LlmException e) {
            Assert.areEqual(LlmException.messageFor(LlmException.AUTH), e.getMessage());
            Assert.isFalse(e.getMessage().contains('SECRET-DETAIL'));
        }
    }
}
