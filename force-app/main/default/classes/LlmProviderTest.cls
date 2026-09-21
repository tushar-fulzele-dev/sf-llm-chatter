@IsTest
private class LlmProviderTest {
    @IsTest
    static void factory_returnsTheRightAdapter() {
        Assert.isInstanceOfType(LlmProviderFactory.forProvider('Gemini'), GeminiProvider.class);
        Assert.isInstanceOfType(LlmProviderFactory.forProvider('OpenAI'), OpenAiProvider.class);
        Assert.isInstanceOfType(LlmProviderFactory.forProvider('Claude'), ClaudeProvider.class);
    }

    @IsTest
    static void factory_rejectsUnknownProviders() {
        for (String name : new List<String>{ 'Nonsense', null }) {
            try {
                LlmProviderFactory.forProvider(name);
                Assert.fail('Expected an LlmException for ' + name);
            } catch (LlmException e) {
                Assert.areEqual(LlmException.UNSUPPORTED, e.code);
            }
        }
    }

    @IsTest
    static void exception_unknownCodesGetTheGenericMessage() {
        Assert.areEqual(LlmException.messageFor(LlmException.UNKNOWN), LlmException.messageFor('SOMETHING_NEW'));
        Assert.areEqual('The request timed out. Please try again.', LlmException.of(LlmException.TIMEOUT).getMessage());
    }
}
