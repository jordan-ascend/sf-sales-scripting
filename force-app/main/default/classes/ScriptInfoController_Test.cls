@isTest
public class ScriptInfoController_Test {
    static Date d = Date.today();

    @TestSetup
    static void makeData(){
        AscendTestDataFactory.autoCommit = false;
        List<Opportunity> opps = AscendTestDataFactory.createOpportunities(3, null);
        Sales_Rep_Script__c script = AscendTestDataFactory.createScript(null);
        AscendTestDataFactory.autoCommit = true;

        List<Opporunity_Script_Junction__c> juncts = new List<Opporunity_Script_Junction__c>();
        for(Opportunity opp: opps) {
            Opporunity_Script_Junction__c j = new Opporunity_Script_Junction__c();
            j.Opportunity__c = opp.Id;
            j.Sales_Rep_Script__c = script.Id;
            j.Opporunity_Stage__c = 'Closed Won';
            juncts.add(j);
        }
        juncts[0].Date_Won__c = d;
        juncts[1].Date_Won__c = d.addMonths(-1);
        juncts[2].Date_Won__c = d.addMonths(-2);
        insert juncts;
    }
    
    @isTest
    static void testGetScriptsWinsOverTime() {
        Sales_Rep_Script__c script = [SELECT Id FROM Sales_Rep_Script__c LIMIT 1];

        List<ScriptInfoController.CountObject> objs = ScriptInfoController.getScriptsWinsOverTime(script.Id);
        for(ScriptInfoController.CountObject obj: objs) {
            System.debug(obj.count);
            System.debug(obj.month);
            System.debug(obj.monthNumber);
        }

        System.assertEquals(0, objs[0].count, 'There should be zero won opportunities for the associated month.');
        System.assertEquals(d.addMonths(-5).month(), objs[0].monthNumber, 'The month number should be ' + d.addMonths(-5).month() + '. If not, then it was not properly calculated or not put in the right order. Check ScriptInfoController.getScriptsWinsOverTime.');
        System.assertEquals(getMonthStr(d.addMonths(-5)), objs[0].month, 'The month should be ' + getMonthStr(d.addMonths(-5)) + '. If not, then it was not properly calculated or not put in the right order. Check ScriptInfoController.getScriptsWinsOverTime.');

        System.assertEquals(0, objs[1].count, 'There should be zero won opportunities for the associated month.');
        System.assertEquals(d.addMonths(-4).month(), objs[1].monthNumber, 'The month number should be ' + d.addMonths(-4).month() + '. If not, then it was not properly calculated or not put in the right order. Check ScriptInfoController.getScriptsWinsOverTime.');
        System.assertEquals(getMonthStr(d.addMonths(-4)), objs[1].month, 'The month should be ' + getMonthStr(d.addMonths(-54)) + '. If not, then it was not properly calculated or not put in the right order. Check ScriptInfoController.getScriptsWinsOverTime.');

        System.assertEquals(0, objs[2].count, 'There should be zero won opportunities for the associated month.');
        System.assertEquals(d.addMonths(-3).month(), objs[2].monthNumber, 'The month number should be ' + d.addMonths(-3).month() + '. If not, then it was not properly calculated or not put in the right order. Check ScriptInfoController.getScriptsWinsOverTime.');
        System.assertEquals(getMonthStr(d.addMonths(-3)), objs[2].month, 'The month should be ' + getMonthStr(d.addMonths(-3)) + '. If not, then it was not properly calculated or not put in the right order. Check ScriptInfoController.getScriptsWinsOverTime.');

        System.assertEquals(1, objs[3].count, 'There should be one won opportunities for the associated month.');
        System.assertEquals(d.addMonths(-2).month(), objs[3].monthNumber, 'The month number should be ' + d.addMonths(-2).month() + '. If not, then it was not properly calculated or not put in the right order. Check ScriptInfoController.getScriptsWinsOverTime.');
        System.assertEquals(getMonthStr(d.addMonths(-2)), objs[3].month, 'The month should be ' + getMonthStr(d.addMonths(-2)) + '. If not, then it was not properly calculated or not put in the right order. Check ScriptInfoController.getScriptsWinsOverTime.');

        System.assertEquals(1, objs[4].count, 'There should be one won opportunities for the associated month.');
        System.assertEquals(d.addMonths(-1).month(), objs[4].monthNumber, 'The month number should be ' + d.addMonths(-1).month() + '. If not, then it was not properly calculated or not put in the right order. Check ScriptInfoController.getScriptsWinsOverTime.');
        System.assertEquals(getMonthStr(d.addMonths(-1)), objs[4].month, 'The month should be ' + getMonthStr(d.addMonths(-1)) + '. If not, then it was not properly calculated or not put in the right order. Check ScriptInfoController.getScriptsWinsOverTime.');

        System.assertEquals(1, objs[5].count, 'There should be one won opportunities for the associated month.');
        System.assertEquals(d.month(), objs[5].monthNumber, 'The month number should be ' + d.month() + '. If not, then it was not properly calculated or not put in the right order. Check ScriptInfoController.getScriptsWinsOverTime.');
        System.assertEquals(getMonthStr(d), objs[5].month, 'The month should be ' + getMonthStr(d) + '. If not, then it was not properly calculated or not put in the right order. Check ScriptInfoController.getScriptsWinsOverTime.');
    }

    static String getMonthStr(Date d) {
        Datetime dt = Datetime.newInstance(d.year(), d.month(), d.day());
        return dt.format('MMMM');
    }
}
