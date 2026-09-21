// Live end-to-end check: CMT connection -> factory -> Gemini adapter -> Named Credential -> Google.
// Uses a handful of tokens on your free tier. The model is hard-coded here only until Step 5
// reads it from the model policy.
LLM_Connection__mdt conn = LLM_Connection__mdt.getInstance('Gemini_Personal');

LlmRequest req = new LlmRequest();
req.namedCredential = conn.Named_Credential__c;
req.model = 'gemini-3.6-flash';
req.messages.add(new LlmMessage(LlmMessage.ROLE_USER, 'In one sentence, what is an Apex Set?'));

try {
    LlmResponse res = LlmProviderFactory.forProvider(conn.Provider__c).sendChat(req);
    System.debug('OK from ' + res.model + ': ' + res.content);
} catch (LlmException e) {
    System.debug('FAILED [' + e.code + '] ' + e.getMessage());
}
