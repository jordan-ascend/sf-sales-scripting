public with sharing class ScriptInfoController {
    
    @AuraEnabled(cacheable=true)
    public static List<ScriptInfoController.CountObject> getScriptsWinsOverTime(Id scriptId){
        Integer monthsBack = 5;
        List<Opporunity_Script_Junction__c> junctions;
        if(
            Opporunity_Script_Junction__c.SObjectType.getDescribe().isAccessible() &&
            Schema.SObjectType.Opporunity_Script_Junction__c.fields.Date_Won__c.isAccessible()
        ) {
            junctions = [SELECT Date_Won__c FROM Opporunity_Script_Junction__c WHERE Sales_Rep_Script__c = :scriptId];
            System.debug(junctions);
        }
        List<ScriptInfoController.CountObject> counts = new List<ScriptInfoController.CountObject>();

        Datetime dt = Datetime.now();

        for(Integer i = monthsBack; i >= 0; i--) {
            Datetime ofMonth = dt.addMonths((-1*i));
            Datetime beginDate = Datetime.newInstance(ofMonth.year(), ofMonth.month(), 1);
            Datetime endDate = Datetime.newInstance(ofMonth.year(), ofMonth.month(), 1);
            endDate = endDate.addMonths(1);

            ScriptInfoController.CountObject c = new ScriptInfoController.CountObject();
            c.month = ofMonth.format('MMMM');
            c.monthNumber = Integer.valueOf(ofMonth.format('MM'));
            c.count = 0;



            for(Opporunity_Script_Junction__c j: junctions) {
                if(j.Date_Won__c == null) {
                    continue;
                }
                Date d = j.Date_Won__c;
                Datetime jdt = Datetime.newInstance(d.year(), d.month(), d.day());

                System.debug(beginDate);
                System.debug(jdt);
                System.debug(endDate);

                if(jdt >= beginDate && jdt < endDate) {c.count++;}
            }

            counts.add(c);
        }
        return counts;
    }

    public class CountObject {
        @AuraEnabled public String month;
        @AuraEnabled public Integer monthNumber;
        @AuraEnabled public Integer count;
    }
}
