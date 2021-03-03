@isTest
public class AscendUtils_Test {
    
    @isTest
    static void testCreateSelectOptionWithMap() {
        Map<String,String> selectOps = new Map<String,String>{'label1' => 'value1', 'label2' => 'value2'};

        List<SelectOption> opps = AscendUtils.createSelectOption(selectOps, true);
        System.assertEquals('-- Any --', opps[0].getValue(), 'Default "Any" not set');
        System.assertEquals(3, opps.size(), 'Options not added to SelectOption list correctly');

        opps = AscendUtils.createSelectOption(selectOps);
        System.assertEquals(2, opps.size(), 'Options not added to SelectOption list correctly');
        System.assert(opps[0].getValue() != '-- Any --', 'The default "any" select option was added to the list when it should not have been.');
        System.assert(opps[1].getValue() != '-- Any --', 'The default "any" select option was added to the list when it should not have been.');
    }

    @isTest
    static void testCreateSelectOptionWithList() {
        List<String> selectOps = new List<String>{'label1', 'label2'};

        List<SelectOption> opps = AscendUtils.createSelectOption(selectOps, true);
        System.assertEquals('-- Any --', opps[0].getValue(), 'Default "Any" not set');
        System.assertEquals(opps[1].getLabel(), opps[1].getValue(), 'Select list label and value are not the same.');
        System.assertEquals(3, opps.size(), 'Options not added to SelectOption list correctly');

        opps = AscendUtils.createSelectOption(selectOps);
        System.assertEquals(2, opps.size(), 'Options not added to SelectOption list correctly');
        System.assertEquals(opps[1].getLabel(), opps[1].getValue(), 'Select list label and value are not the same.');
        System.assert(opps[0].getValue() != '-- Any --', 'The default "any" select option was added to the list when it should not have been.');
        System.assert(opps[1].getValue() != '-- Any --', 'The default "any" select option was added to the list when it should not have been.');
    }

    @isTest
    static void testGetUserRole() {
        List<UserRole> roles = AscendUtils.getAllUserRoles();
        System.assert(!roles.isEmpty(), 'Test should have found user roles');
    }

    @isTest
    static void testGetPicklistValues() {
        Map<String,String> oppMap = AscendUtils.getPickListValues('Opportunity', 'StageName');
        Boolean found = false;
        for(String stage: oppMap.keySet()) {
            if(stage.equals('Prospecting')) {
                found = true;
            }
        }
        if(!found) {
            System.assert(false, 'Test failed because Stagename "Prospecting" could not be found. The getPicklistValues method did not work correctly or the stagename was removed.');
        }

        oppMap = AscendUtils.getPickListValues('Doesnt', 'exist');
        system.assert(oppMap.isEmpty(), 'Found picklist values from an object when it should not have');

        oppMap = AscendUtils.getPickListValues('Opportunity', 'DoesntExist');
        system.assert(oppMap.isEmpty(), 'Found picklist values from an object when it should not have');
    }

    @isTest
    static void testGetRandomNumberString() {
        String numStr = AscendUtils.randomNumberString(35);
        System.assertEquals(35, numStr.length(), 'Random number string method did not produce a string of the specified length');
    }

    @isTest
    static void testGetUserRoleFromId() {
        UserRole role1 = [SELECT Id FROM UserRole LIMIT 1];
        UserRole role2 = AscendUtils.getUserRoleFromId(role1.Id);
        UserRole role3 = AscendUtils.getUserRoleFromId('00E4W00000' + AscendUtils.randomNumberString(8));

        System.assertEquals(role1.Id, role2.Id, 'AscendUtils.getUserRoleFromId did not return the correct role.');
        System.assertEquals(null, role3, 'AscendUtils.getUserRoleFromId should not have returned a role.');
    }

    @isTest
    static void testAddToDelimitedSet() {
        String str = '';
        str = AscendUtils.addToDelimitedSet(str, 'one;two;three', ';');
        system.assertEquals('one;two;three', str, 'Delimited list string not formed correctly.');
        str = AscendUtils.addToDelimitedSet(str, 'four', ';');
        system.assertEquals('one;two;three;four', str, '"four" was not appended to list string correctly');
        str = AscendUtils.addToDelimitedSet(str, 'two', ';');
        system.assertEquals('one;two;three;four', str, '"two" was added to the list string again.');
    }

    @isTest
    static void testListSlice() {
        List<String> strList = new List<String>{'First', 'second', 'third', 'fourth', 'fifth', 'sixth'};
        List<String> newStrList = (List<String>)AscendUtils.slice(strList, 1, 3);
        System.assertEquals('second,third', String.join(newStrList, ','), 'A sublist of strList with elements 1 and 2, the words "second" and "third" respectively, was not created properly.');
    }

    @isTest
    static void testGetMatchedExpressions() {
        String str = 'The name of the opportunity is {Opportunity.Name}, and the close date is {Opportunity.closedate}.';
        List<String> exprList = AscendUtils.getMatchedExpressions(str, '\\{\\w+\\.\\w+\\}');

        System.assertEquals('{Opportunity.Name}', exprList[0], 'AscendUtils.getMatchedExpressions did not find one of its expressions it was suppsed to find.');
        System.assertEquals('{Opportunity.closedate}', exprList[1], 'AscendUtils.getMatchedExpressions did not find one of its expressions it was suppsed to find.');

        str = 'There are no matching expressions in this list.';
        List<String> emptyExprList = AscendUtils.getMatchedExpressions(str, '\\{\\w+\\.\\w+\\}');
        System.assert(emptyExprList.isEmpty(), 'AscendUtils.getMatchedExpressions found a matched expression when it should not have.');
    }
}