/** Everything an adapter needs to send one chat request. Provider-neutral. */
public class LlmRequest {
    public String namedCredential { get; set; }   // e.g. NC_Gemini_Personal
    public String model { get; set; }             // e.g. gemini-2.5-flash (from the model policy)
    public List<LlmMessage> messages { get; set; }
    public Integer maxOutputTokens { get; set; }  // null = provider default
    public Integer timeoutMs { get; set; }        // null = 60000, capped at 120000

    public LlmRequest() {
        messages = new List<LlmMessage>();
    }
}
