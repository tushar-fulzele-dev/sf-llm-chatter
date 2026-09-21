// Inserts 1 conversation + 100 messages of ~4,000 characters each.
// Compare Setup > Storage Usage before/after to learn what a real message costs.
LLM_Conversation__c c = new LLM_Conversation__c(
    Name = 'Storage test',
    Provider__c = 'OpenAI',
    Connection_Name__c = 'test',
    Last_Activity__c = System.now()
);
insert c;

String body = 'x'.repeat(4000);
List<LLM_Message__c> msgs = new List<LLM_Message__c>();
for (Integer i = 1; i <= 100; i++) {
    msgs.add(new LLM_Message__c(
        Conversation__c = c.Id,
        Sequence__c = i,
        Role__c = Math.mod(i, 2) == 1 ? 'user' : 'assistant',
        Content__c = body
    ));
}
insert msgs;
System.debug('Inserted 1 conversation and ' + msgs.size() + ' messages');
