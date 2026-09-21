/** Maps a provider name (LLM_Connection__mdt.Provider__c) to its adapter. */
public with sharing class LlmProviderFactory {
    public static LlmProvider forProvider(String provider) {
        LlmProvider adapter;
        switch on provider {
            when 'Gemini' {
                adapter = new GeminiProvider();
            }
            when 'OpenAI' {
                adapter = new OpenAiProvider();
            }
            when 'Claude' {
                adapter = new ClaudeProvider();
            }
            when else {
                throw LlmException.of(LlmException.UNSUPPORTED);
            }
        }
        return adapter;
    }
}
