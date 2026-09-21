@IsTest
private class LlmProviderTest {
    @IsTest
    static void factory_returnsGeminiAdapter() {
        Assert.isInstanceOfType(LlmProviderFactory.forProvider('Gemini'), GeminiProvider.class);
    }

    @IsTest
    static void factory_rejectsProvidersWithoutAnAdapter() {
        for (String name : new List<String>{ 'OpenAI', 'Claude', 'Nonsense', null }) {
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
