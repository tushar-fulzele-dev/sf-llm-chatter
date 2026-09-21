/** Shared helpers for adapter tests. */
@IsTest
public class LlmTestUtil {
    public static LlmRequest newRequest() {
        LlmRequest r = new LlmRequest();
        r.namedCredential = 'NC_Test';
        r.model = 'test-model';
        r.messages.add(new LlmMessage(LlmMessage.ROLE_USER, 'Hi'));
        r.messages.add(new LlmMessage(LlmMessage.ROLE_ASSISTANT, 'Hello'));
        r.messages.add(new LlmMessage(LlmMessage.ROLE_USER, 'Explain Apex sets'));
        return r;
    }

    /** Sends with the given canned response and returns the LlmException code (fails if none is thrown). */
    public static String codeFor(LlmProvider provider, HttpCalloutMock mock) {
        Test.setMock(HttpCalloutMock.class, mock);
        try {
            provider.sendChat(newRequest());
        } catch (LlmException e) {
            return e.code;
        }
        Assert.fail('Expected an LlmException');
        return null;
    }

    /** The JSON body of the last request the mock saw. */
    public static Map<String, Object> sentBody() {
        return (Map<String, Object>) JSON.deserializeUntyped(LlmHttpMock.lastRequest.getBody());
    }
}
