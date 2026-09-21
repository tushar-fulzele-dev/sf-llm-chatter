// Deletes the test data AND empties the Recycle Bin (the same technique the retention job will use).
List<LLM_Message__c> msgs = [SELECT Id FROM LLM_Message__c WHERE Conversation__r.Name = 'Storage test'];
List<LLM_Conversation__c> convs = [SELECT Id FROM LLM_Conversation__c WHERE Name = 'Storage test'];
delete convs; // cascades to the messages
Database.emptyRecycleBin(msgs);
Database.emptyRecycleBin(convs);
System.debug('Removed ' + convs.size() + ' conversation(s) and ' + msgs.size() + ' message(s)');
