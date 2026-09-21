/** One turn of a conversation in provider-neutral form. Adapters translate roles as needed. */
public class LlmMessage {
    public static final String ROLE_USER = 'user';
    public static final String ROLE_ASSISTANT = 'assistant';

    public String role { get; private set; }
    public String content { get; private set; }

    public LlmMessage(String role, String content) {
        this.role = role;
        this.content = content;
    }
}
