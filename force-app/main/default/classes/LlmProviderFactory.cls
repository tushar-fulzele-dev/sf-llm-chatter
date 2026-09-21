/** Maps a provider name (LLM_Connection__mdt.Provider__c) to its adapter. */
public with sharing class LlmProviderFactory {
    public static LlmProvider forProvider(String provider) {
        LlmProvider adapter;
        switch on provider {
            when 'Gemini' {
                adapter = new GeminiProvider();
            }
            when else {
                // OpenAI and Claude adapters are added in the next step.
                throw LlmException.of(LlmException.UNSUPPORTED);
            }
        }
        return adapter;
    }
}
