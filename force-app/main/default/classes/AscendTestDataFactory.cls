/**
 * This class is for the creation of commonly used data in apex tests as well as test utilities.
 */
@istest
public class AscendTestDataFactory {
    private static List<SObject> recordsToCommit = new List<SObject>();

    public static Boolean autoCommit{
        get{
            if(autoCommit == null) {
                return true;
            } else {
                return autoCommit;
            }
        }
        set{
            if(autoCommit != null) {
                if(value && !autoCommit) {
                    autoCommit = true;
                    commitData();
                }
            }
            autoCommit = value;
        }
    }

    /**
     * Common data that my be dependencies of other SObjects
     */
    // public static void setupDefaultData() {
        // No common dependencies yet. If there is commonly required data to be set up across the org's test classes, put it here.
        // For example, if a trigger framework is implemented and custom settings are used to store trigger enabled/disabled 
        // states for accounts, then those settings would need to be recreated here since the likelihood of using accounts 
        // anywhere in in code is high.
    // }

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
     * Create Opportunity
     * Parameters:
     * fields - Map of SObjectField to Object to set fields
     * Returns:
     * An Opportunity Object
     * 
     * Field Defaults:
     * LastName = 'TestOpportunity[randomStringOfNumners]'
     * CloseDate = Seven days from Opportunity instantiation
     * StageName = 'Prospecting'
     */
    public static Opportunity createOpportunity(Map<SObjectField,Object> fields) {
        return createOpportunities(1, fields)[0];
    }

    /**
     * Create Opportunities
     * Parameters:
     * howMany - integer of opportunities to create
     * fields - Map of SObjectField to Object to set fields
     * Returns:
     * A list of Opportunity Objects
     * 
     * 
     * Field Defaults:
     * LastName = 'TestOpportunity[randomStringOfNumners]'
     * CloseDate = Seven days from Opportunity instantiation
     * StageName = 'Prospecting'
     */
    public static List<Opportunity> createOpportunities(Integer howMany, Map<SObjectField,Object> fields) {
        List<Opportunity> objs = new List<Opportunity>();
        for(Integer i = 0; i < howMany; i++) {
            objs.add(new Opportunity(
                Name = 'TestOpportunity' + AscendUtils.randomNumberString(5),
                CloseDate = Date.Today().addDays(7),
                StageName = 'Prospecting'
            ));
        }
        assignFields(objs, fields);
        recordsToCommit.addAll(objs);
        commitData();
        return objs;
    }

    /**
     * Create Sales_Rep_Script__c
     * Parameters:
     * howMany - integer of opportunities to create
     * Returns:
     * A Sales_Rep_Script__c
     * 
     * 
     * Field Defaults:
     * Active__c = true
     * OpportunityStage__c = 'Prospecting'
     * Script__c = 'This is a test script'
     * OpportunityType__c = '-- Any --'
     * UserRole__c = '-- Any --'
     */
    public static Sales_Rep_Script__c createScript(Map<SObjectField,Object> fields) {
        Sales_Rep_Script__c obj = new Sales_Rep_Script__c(
            Active__c = true,
            OpportunityStage__c = 'Prospecting',
            OpportunityType__c = '-- Any --',
            Script__c = 'This is a test script',
            UserRole__c = '-- Any --'
        );
        assignFields(new List<SObject>{obj}, fields);
        recordsToCommit.add(obj);
        commitData();
        return obj;
    }

    /**
     * Create Script_Metric__c
     * Parameters:
     * howMany - integer of opportunities to create
     * Returns:
     * A Script_Metric__c
     * 
     * 
     * Field Defaults:
     * Opportunity__c = Id of given opportunity
     * Opportunity_Stage__c = Stage of given opportunity
     * Opportunity_Won__c = Boolean set true if opportunity is won, false otherwise
     * Scripts_Used__c = '[opportunity stage name]:[given script id]'
     */
    public static Script_Metric__c createScriptMetric(Sales_Rep_Script__c script, Opportunity opp, Map<SObjectField,Object> fields) {
        Script_Metric__c obj = new Script_Metric__c(
            Opportunity__c = opp.Id,
            Opportunity_Stage__c = opp.StageName,
            Opportunity_Won__c = opp.StageName == 'Closed Won'?true:false,
            Scripts_Used__c = opp.StageName + ':' + script.Id
        );
        assignFields(new List<SObject>{obj}, fields);
        recordsToCommit.add(obj);
        commitData();
        return obj;
    }

    /**
     * Accepts a list of SObjects and a map of SObjectField to Object. 
     * This will set field values for the list of SObjects.
     * Example: Set website for list of Accounts. The map: {Account.Website => 'example.com'}
     */
    private static void assignFields(List<SObject> objs, Map<SObjectField,Object> fields) {
        if(objs == null || fields == null) {
            return;
        }
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