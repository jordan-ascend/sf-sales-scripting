public class accountLayoutController {
    public accountLayoutController() {

    }

    @AuraEnabled(cacheable=true)
    public static List<Contact> getContacts(String actId){
        System.debug(actId);
        return [SELECT Id, Name, MailingStreet, MailingCity, MailingState, MailingPostalCode FROM Contact WHERE Accountid = :actId];
    }
}