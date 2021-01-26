@isTest
public class AscendUtils_Test {
    
    @isTest
    static void testCreateSelectOptionWithMap() {
        Map<String,String> selectOps = new Map<String,String>{'label1' => 'value1', 'label2' => 'value2'};

        List<SelectOption> opps = AscendUtils.createSelectOption(selectOps, true);
        System.assertEquals('-- Any --', opps[0].getValue());
        System.assertEquals(3, opps.size());

        opps = AscendUtils.createSelectOption(selectOps);
        System.assertEquals(2, opps.size());
        System.assert(opps[0].getValue() != '-- Any --');
        System.assert(opps[1].getValue() != '-- Any --');
    }

    @isTest
    static void testCreateSelectOptionWithList() {
        List<String> selectOps = new List<String>{'label1', 'label2'};

        List<SelectOption> opps = AscendUtils.createSelectOption(selectOps, true);
        System.assertEquals('-- Any --', opps[0].getValue());
        System.assertEquals(opps[1].getValue(), opps[1].getValue());
        System.assertEquals(3, opps.size());

        opps = AscendUtils.createSelectOption(selectOps);
        System.assertEquals(2, opps.size());
        System.assertEquals(opps[1].getValue(), opps[1].getValue());
        System.assert(opps[0].getValue() != '-- Any --');
        System.assert(opps[1].getValue() != '-- Any --');
    }

    @isTest
    static void testGetUserRole() {
        List<UserRole> roles = AscendUtils.getAllUserRoles();
        System.assert(!roles.isEmpty());
    }

    @isTest
    static void testGetPicklistValues() {
        Map<String,String> oppMap = AscendUtils.getPickListValues('Opportunity', 'StageName');
        Boolean found = false;
        for(String stage: oppMap.keySet()) {
            if(stage.equals('Prospecting'))
                found = true;
        }
        if(!found)
            System.assert(false);

        oppMap = AscendUtils.getPickListValues('Doesnt', 'exist');
        system.assert(oppMap.isEmpty());

        oppMap = AscendUtils.getPickListValues('Opportunity', 'DoesntExist');
        system.assert(oppMap.isEmpty());
    }

    @isTest
    static void testGetRandomNumberString() {
        String numStr = AscendUtils.randomNumberString(35);
        System.assertEquals(35, numStr.length());
    }

    @isTest
    static void testGetUserRoleFromId() {
        UserRole role1 = [SELECT Id FROM UserRole LIMIT 1];
        UserRole role2 = AscendUtils.getUserRoleFromId(role1.Id);
        UserRole role3 = AscendUtils.getUserRoleFromId('00E4W00000' + AscendUtils.randomNumberString(8));

        System.assertEquals(role1.Id, role2.Id);
        System.assertEquals(null, role3);
    }

    @isTest
    static void testAddToDelimitedSet() {
        String str = '';
        str = AscendUtils.addToDelimitedSet(str, 'one;two;three', ';');
        system.assertEquals('one;two;three', str);
        str = AscendUtils.addToDelimitedSet(str, 'four', ';');
        system.assertEquals('one;two;three;four', str);
        str = AscendUtils.addToDelimitedSet(str, 'two', ';');
        system.assertEquals('one;two;three;four', str);
    }
}