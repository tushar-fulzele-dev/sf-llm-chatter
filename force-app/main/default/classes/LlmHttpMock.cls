/** Test helper: canned HTTP responses (or a thrown CalloutException) and a record of the last request. */
@IsTest
public class LlmHttpMock implements HttpCalloutMock {
    public static HttpRequest lastRequest;

    private Integer status;
    private String body;
    private String errorMessage;

    public LlmHttpMock(Integer status, String body) {
        this.status = status;
        this.body = body;
    }

    /** A mock whose callout throws, e.g. throwing('Read timed out'). */
    public static LlmHttpMock throwing(String message) {
        LlmHttpMock m = new LlmHttpMock(0, null);
        m.errorMessage = message;
        return m;
    }

    public HttpResponse respond(HttpRequest req) {
        lastRequest = req;
        if (errorMessage != null) {
            CalloutException e = new CalloutException();
            e.setMessage(errorMessage);
            throw e;
        }
        HttpResponse res = new HttpResponse();
        res.setStatusCode(status);
        res.setHeader('Content-Type', 'application/json');
        res.setBody(body);
        return res;
    }
}
