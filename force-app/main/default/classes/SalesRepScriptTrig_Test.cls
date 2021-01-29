@isTest
public class SalesRepScriptTrig_Test {

    /**
     * Test that the trigger prevents a script with identical filters to another from being inserted.
     */
    @isTest
    static void testDuplicateScript() {
        Opportunity opp = AscendTestDataFactory.createOpportunity(null);
        try{
            Sales_Rep_Script__c script1 = AscendTestDataFactory.createScript(new Map<SObjectField,Object>{
                Sales_Rep_Script__c.Opportunity__c => opp.Id,
                Sales_Rep_Script__c.OpportunityType__c => 'New Customer'
            });
            Sales_Rep_Script__c script2 = AscendTestDataFactory.createScript(new Map<SObjectField,Object>{
                Sales_Rep_Script__c.Opportunity__c => opp.Id,
                Sales_Rep_Script__c.OpportunityType__c => 'New Customer'
            });
        } catch(Exception e) {
            System.assert(e.getMessage().contains(errStrPartial));
        }
    }

    static String errStrPartial = 'is already using the combination of filters that you are trying to select. You must select a unique combination of filters, or mark this script or';
}
