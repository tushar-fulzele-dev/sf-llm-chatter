// Creates the org-wide default for retention (idempotent).
LLM_Chat_Settings__c s = LLM_Chat_Settings__c.getOrgDefaults();
if (s.Id == null) {
    s.SetupOwnerId = UserInfo.getOrganizationId();
    s.Retention_Days__c = 30;
    insert s;
}
System.debug('Retention days = ' + s.Retention_Days__c);
