// Smoke-tests a connection end to end: CMT record -> Named Credential -> provider API.
// Calls the provider's "list models" endpoint: it is read-only and consumes no tokens.
String connName = 'Gemini_Personal';   // DeveloperName of the LLM_Connection__mdt record
String path     = '/v1beta/models';    // OpenAI: /v1/models   Gemini: /v1beta/models   Claude: /v1/models

LLM_Connection__mdt conn = LLM_Connection__mdt.getInstance(connName);
System.assertNotEquals(null, conn, 'No LLM_Connection__mdt record named ' + connName);

HttpRequest req = new HttpRequest();
req.setEndpoint('callout:' + conn.Named_Credential__c + path);
req.setMethod('GET');
req.setTimeout(30000);
if (conn.Provider__c == 'Claude') {
    req.setHeader('anthropic-version', '2023-06-01'); // protocol header, not a secret
}

HttpResponse res = new Http().send(req);
System.debug('Status: ' + res.getStatusCode());
System.debug('Body (first 300 chars): ' + res.getBody().left(300));
