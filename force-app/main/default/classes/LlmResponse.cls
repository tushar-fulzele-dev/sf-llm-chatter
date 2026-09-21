/** The assistant's reply, provider-neutral. */
public class LlmResponse {
    public String content { get; private set; }
    public String model { get; private set; }

    public LlmResponse(String content, String model) {
        this.content = content;
        this.model = model;
    }
}
