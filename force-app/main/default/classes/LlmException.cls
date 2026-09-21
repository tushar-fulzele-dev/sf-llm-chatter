/**
 * The only exception provider adapters throw.
 * - code: stable machine-readable value (stored in LLM_Message__c.Error_Code__c, drives fallback)
 * - message: FIXED, user-safe text. Provider bodies, headers and credentials are never copied in.
 */
public class LlmException extends Exception {
    public static final String AUTH = 'AUTH';
    public static final String RATE_LIMIT = 'RATE_LIMIT';
    public static final String QUOTA = 'QUOTA';
    public static final String TIMEOUT = 'TIMEOUT';
    public static final String MODEL_UNAVAILABLE = 'MODEL_UNAVAILABLE';
    public static final String PROVIDER_UNAVAILABLE = 'PROVIDER_UNAVAILABLE';
    public static final String BAD_REQUEST = 'BAD_REQUEST';
    public static final String EMPTY_RESPONSE = 'EMPTY_RESPONSE';
    public static final String UNSUPPORTED = 'UNSUPPORTED';
    public static final String UNKNOWN = 'UNKNOWN';

    private static final Map<String, String> MESSAGES = new Map<String, String>{
        AUTH => 'Invalid API credentials. Please check the configured connection.',
        RATE_LIMIT => 'The API rate limit for this connection has been reached.',
        QUOTA => 'The available API quota has been reached.',
        TIMEOUT => 'The request timed out. Please try again.',
        MODEL_UNAVAILABLE => 'The configured model is currently unavailable. Please update the provider configuration.',
        PROVIDER_UNAVAILABLE => 'The selected provider is currently unavailable.',
        BAD_REQUEST => 'The provider rejected the request.',
        EMPTY_RESPONSE => 'The provider returned an empty response.',
        UNSUPPORTED => 'This provider is not supported yet.',
        UNKNOWN => 'Something went wrong while contacting the provider.'
    };

    public String code { get; private set; }

    public LlmException(String code, String message) {
        this(message);
        this.code = code;
    }

    public static LlmException of(String code) {
        return new LlmException(code, messageFor(code));
    }

    public static String messageFor(String code) {
        return MESSAGES.containsKey(code) ? MESSAGES.get(code) : MESSAGES.get(UNKNOWN);
    }
}
