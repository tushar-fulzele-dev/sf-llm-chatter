@IsTest
private class ClaudeProviderTest {
    private static final String SUCCESS_BODY =
        '{"id":"msg_1","type":"message","role":"assistant","content":[{"type":"text","text":"Hello "},{"type":"text","text":"there"}],"model":"claude-test","stop_reason":"end_turn"}';

    @IsTest
    static void success_joinsTextBlocksAndSkipsOthers() {
        Test.setMock(HttpCalloutMock.class, new LlmHttpMock(200, SUCCESS_BODY));
        Assert.areEqual('Hello there', new ClaudeProvider().sendChat(LlmTestUtil.newRequest()).content);

        Test.setMock(HttpCalloutMock.class, new LlmHttpMock(200,
            '{"content":[{"type":"thinking","thinking":"hmm"},{"type":"text","text":"Hi"}]}'));
        LlmResponse res = new ClaudeProvider().sendChat(LlmTestUtil.newRequest());
        Assert.areEqual('Hi', res.content, 'Thinking blocks must be ignored');
        Assert.areEqual('test-model', res.model);
    }

    @IsTest
    static void request_isBuiltCorrectly() {
        Test.setMock(HttpCalloutMock.class, new LlmHttpMock(200, SUCCESS_BODY));
        LlmRequest r = LlmTestUtil.newRequest();
        r.maxOutputTokens = 256;

        new ClaudeProvider().sendChat(r);

        HttpRequest sent = LlmHttpMock.lastRequest;
        Assert.areEqual('callout:NC_Test/v1/messages', sent.getEndpoint());
        Assert.areEqual('2023-06-01', sent.getHeader('anthropic-version'));
        Map<String, Object> body = LlmTestUtil.sentBody();
        Assert.areEqual('test-model', body.get('model'));
        Assert.areEqual(256, body.get('max_tokens'));
        List<Object> messages = (List<Object>) body.get('messages');
        Assert.areEqual(3, messages.size());
        Assert.areEqual('assistant', ((Map<String, Object>) messages[1]).get('role'));
    }

    @IsTest
    static void request_alwaysSendsMaxTokensBecauseTheApiRequiresIt() {
        Test.setMock(HttpCalloutMock.class, new LlmHttpMock(200, SUCCESS_BODY));

        new ClaudeProvider().sendChat(LlmTestUtil.newRequest());

        Assert.areEqual(4096, LlmTestUtil.sentBody().get('max_tokens'));
    }

    @IsTest
    static void errorMapping() {
        ClaudeProvider p = new ClaudeProvider();
        Assert.areEqual(LlmException.AUTH, LlmTestUtil.codeFor(p, new LlmHttpMock(401,
            '{"type":"error","error":{"type":"authentication_error","message":"invalid x-api-key"}}')));
        Assert.areEqual(LlmException.AUTH, LlmTestUtil.codeFor(p, new LlmHttpMock(403,
            '{"type":"error","error":{"type":"permission_error"}}')));
        Assert.areEqual(LlmException.MODEL_UNAVAILABLE, LlmTestUtil.codeFor(p, new LlmHttpMock(404,
            '{"type":"error","error":{"type":"not_found_error","message":"model: x"}}')));
        Assert.areEqual(LlmException.RATE_LIMIT, LlmTestUtil.codeFor(p, new LlmHttpMock(429,
            '{"type":"error","error":{"type":"rate_limit_error"}}')));
        Assert.areEqual(LlmException.QUOTA, LlmTestUtil.codeFor(p, new LlmHttpMock(400,
            '{"type":"error","error":{"type":"invalid_request_error","message":"Your credit balance is too low to access the API."}}')));
        Assert.areEqual(LlmException.BAD_REQUEST, LlmTestUtil.codeFor(p, new LlmHttpMock(400,
            '{"type":"error","error":{"type":"invalid_request_error","message":"messages: bad"}}')));
        Assert.areEqual(LlmException.BAD_REQUEST, LlmTestUtil.codeFor(p, new LlmHttpMock(413, '{}')));
        Assert.areEqual(LlmException.PROVIDER_UNAVAILABLE, LlmTestUtil.codeFor(p, new LlmHttpMock(529,
            '{"type":"error","error":{"type":"overloaded_error"}}')));
        Assert.areEqual(LlmException.PROVIDER_UNAVAILABLE, LlmTestUtil.codeFor(p, new LlmHttpMock(500, '{}')));
    }

    @IsTest
    static void timeoutAndTransportFailures() {
        ClaudeProvider p = new ClaudeProvider();
        Assert.areEqual(LlmException.TIMEOUT, LlmTestUtil.codeFor(p, LlmHttpMock.throwing('Read timed out')));
        Assert.areEqual(LlmException.PROVIDER_UNAVAILABLE, LlmTestUtil.codeFor(p, LlmHttpMock.throwing('Unauthorized endpoint')));
    }

    @IsTest
    static void unusableSuccessBodies() {
        ClaudeProvider p = new ClaudeProvider();
        Assert.areEqual(LlmException.EMPTY_RESPONSE, LlmTestUtil.codeFor(p, new LlmHttpMock(200, '{"content":[]}')));
        Assert.areEqual(LlmException.UNKNOWN, LlmTestUtil.codeFor(p, new LlmHttpMock(200, '{not json')));
    }

    @IsTest
    static void exceptionMessageNeverEchoesProviderBody() {
        Test.setMock(HttpCalloutMock.class, new LlmHttpMock(401, '{"error":{"message":"SECRET-DETAIL"}}'));
        try {
            new ClaudeProvider().sendChat(LlmTestUtil.newRequest());
            Assert.fail('Expected an LlmException');
        } catch (LlmException e) {
            Assert.areEqual(LlmException.messageFor(LlmException.AUTH), e.getMessage());
            Assert.isFalse(e.getMessage().contains('SECRET-DETAIL'));
        }
    }
}
