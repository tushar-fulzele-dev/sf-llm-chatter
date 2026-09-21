/** The contract every provider adapter fulfils. Callers never see provider-specific JSON. */
public interface LlmProvider {
    LlmResponse sendChat(LlmRequest request);
}
