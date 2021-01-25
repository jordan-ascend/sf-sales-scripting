/**
 * This class is for the creation of commonly used data in apex tests as well as test utilities.
 */
@istest
public class AscendTestDataFactory {
    private static List<SObject> recordsToCommit = new List<SObject>();

    public static Boolean autoCommit{
        get{
            if(autoCommit == null) 
                return true;
            else
                return autoCommit;
        }
        set{
            if(autoCommit != null)
                if(value && !autoCommit) {
                    autoCommit = true;
                    commitData();
                }
            autoCommit = value;
        }
    }

    /**
     * Common data that my be dependencies of other SObjects
     */
    public static void setupDefaultData() {
        // No common dependencies yet. If there is commonly required data to be set up across the org's test classes, put it here.
        // For example, if a trigger framework is implemented and custom settings are used to store trigger enabled/disabled 
        // states for accounts, then those settings would need to be recreated here since the likelihood of using accounts 
        // anywhere in in code is high.
    }

    /**
     * Create User
     * Parameters:
     * fields - Map of SObjectField to Object to set fields
     * Returns:
     * An User Object
     * 
     * Field Defaults:
     * Alias = '[randomStringOfNumners]'
     * Email='testUser[randomStringOfNumners]@testorg.com'
     * EmailEncodingKey='UTF-8'
     * LastName='testUser[randomStringOfNumners]'
     * LanguageLocaleKey='en_US'
     * LocaleSidKey='en_US'
     * ProfileId = [Id of Standard User]
     * TimeZoneSidKey='America/Los_Angeles'
     * UserName='testUser[randomStringOfNumners]@testorg.com'
     */
    public static User createUser(Map<SObjectField,Object> fields) {
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        String numString = AscendUtils.randomNumberString(5);
        User u = new User(Alias = numString, Email='testUser'+numString+'@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='testUser'+numString, LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='testUser'+numString+'@testorg.com');
        List<SObject> objs = new List<SObject>{u};
        assignFields(objs, fields);
        recordsToCommit.addAll(objs);
        commitData();
        return u;
    }

    /**
     * Create Account
     * Parameters:
     * fields - Map of SObjectField to Object to set fields
     * Returns:
     * An Account Object
     * 
     * Field Defaults:
     * Name = 'TestAccount[randomStringOfNumners]'
     */
    public static Account createAccount(Map<SObjectField,Object> fields) {
        return createAccounts(1, fields)[0];
    }

    /**
     * Create Accounts
     * Parameters:
     * howMany - integer of accounts to create
     * fields - Map of SObjectField to Object to set fields
     * Returns:
     * A list of Account Objects
     * 
     * Field Defaults:
     * Name = 'TestAccount[randomStringOfNumners]'
     */
    public static List<Account> createAccounts(Integer howMany, Map<SObjectField,Object> fields) {
        List<Account> objs = new List<Account>();
        for(Integer i = 0; i < howMany; i++) {
            objs.add(new Account(
                Name = 'TestAccount' + AscendUtils.randomNumberString(5)
            ));
        }
        assignFields(objs, fields);
        recordsToCommit.addAll(objs);
        commitData();
        return objs;
    }

    /**
     * Create Contact
     * Parameters:
     * fields - Map of SObjectField to Object to set fields
     * Returns:
     * A Contact Object
     * 
     * Field Defaults:
     * LastName = 'TestContact[randomStringOfNumners]'
     */
    public static Contact createContact(Map<SObjectField,Object> fields) {
        return createContacts(1, fields)[0];
    }

    /**
     * Create Contacts
     * Parameters:
     * howMany - integer of contacts to create
     * fields - Map of SObjectField to Object to set fields
     * Returns:
     * A list of Contact Objects
     * 
     * 
     * Field Defaults:
     * LastName = 'TestContact[randomStringOfNumners]'
     */
    public static List<Contact> createContacts(Integer howMany, Map<SObjectField,Object> fields) {
        List<Contact> objs = new List<Contact>();
        for(Integer i = 0; i < howMany; i++) {
            objs.add(new Contact(
                LastName = 'TestContact' + AscendUtils.randomNumberString(5)
            ));
        }
        assignFields(objs, fields);
        recordsToCommit.addAll(objs);
        commitData();
        return objs;
    }

    /**
     * Accepts a list of SObjects and a map of SObjectField to Object. 
     * This will set field values for the list of SObjects.
     * Example: Set website for list of Accounts. The map: {Account.Website => 'example.com'}
     */
    private static void assignFields(List<SObject> objs, Map<SObjectField,Object> fields) {
        if(objs == null || fields == null)
            return;
        for(SObject o: objs) {
            for(SObjectField field: fields.keySet()) {
                o.put(field.getDescribe().getName(), fields.get(field));
            }
        }
    }

    private static void commitData() {
        if(autoCommit) {
            System.debug('TestFactory::Committing Data');
            upsert recordsToCommit;
            recordsToCommit.clear();
        }
    }
}
