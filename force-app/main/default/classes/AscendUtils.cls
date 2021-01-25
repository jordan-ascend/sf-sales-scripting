/**
 * A class of common or potentially common methods that can be used throughout the org.
 */
public class AscendUtils {
    /**
     * Create a list of SelectOptions with a Map of labels to values.
     * 
     * Parameters:
     * Map<String,String> optionMap - Used to set the SelectOption labels and values.
     * The map key is used as the label.
     * Boolean addAnyOption - Add the SelectOption '-- Any --'
     * 
     * Returns:
     * List<SelectOption> - A list of SelectOption based on the passed map.
     */
    public static List<SelectOption> createSelectOption(Map<String,String> optionMap, Boolean addAnyOption) {
        List<SelectOption> selectOptionList = new List<SelectOption>();
        if(addAnyOption)
            selectOptionList.add(new SelectOption('-- Any --', '-- Any --'));

        for(String label: optionMap.keySet()) {
            selectOptionList.add(new SelectOption(label, optionMap.get(label)));
        }

        return selectOptionList;
    }

    /**
     * Create a list of SelectOptions where the labels and values are the same.
     * 
     * Parameters:
     * List<String> optionList - Used to set the SelectOption labels and value.
     * The map key is used as the label.
     * Boolean addAnyOption - Add the SelectOption '-- Any --'
     * 
     * Returns:
     * List<SelectOption> - A list of SelectOption based on the passed map.
     */
    public static List<SelectOption> createSelectOption(List<String> optionList, Boolean addAnyOption) {
        Map<String,String> optionMap = new Map<String,String>();
        for(String option: optionList)
            optionMap.put(option, option);
        return createSelectOption(optionMap, addAnyOption);
    }

    /**
     * Create a list of SelectOptions with a Map of labels to values.
     * 
     * Parameters:
     * Map<String,String> optionMap - Used to set the SelectOption labels and value.
     * The map key is used as the label.
     * 
     * Returns:
     * List<SelectOption> - A list of SelectOption based on the passed map.
     */
    public static List<SelectOption> createSelectOption(Map<String,String> optionMap) {
        return createSelectOption(optionMap, false);
    }

    /**
     * Create a list of SelectOptions where the labels and values are the same.
     * 
     * Parameters:
     * List<String> optionList - Used to set the SelectOption labels and value.
     * The map key is used as the label.
     * 
     * Returns:
     * List<SelectOption> - A list of SelectOption based on the passed map.
     */
    public static List<SelectOption> createSelectOption(List<String> optionList) {
        return createSelectOption(optionList, false);
    }


    /**
     * Gets all current user roles.
     * 
     * Returns:
     * List of UserRole
     */
    public static List<UserRole> getAllUserRoles() {
        return [SELECT Id, Name FROM UserRole];
    }

    /**
     * Parameters:
     * String obj - API name of the object with the picklist.
     * String field - API name of the field from the object.
     * 
     * Returns:
     * Map<String,String> - A map of picklist labels to values.
     */
    public static Map<String,String> getPicklistValues(String objName, String fieldName) {
        Map<String,AscendUtils.PickListInfo> picklistInfoMap = getPickListInfo(objName, fieldName);

        Map<String,String> pickListValMap = new Map<String,String>();

        for(String label: picklistInfoMap.keySet()) {
            pickListValMap.put(label, picklistInfoMap.get(label).value);
        }

        return pickListValMap;
    }

    /**
     * Create a string of random digits.
     * 
     * Parameters:
     * Integer length - Set how long the string will be.
     * 
     * Returns:
     * String
     */
    public static String randomNumberString(Integer length) {
        String randNum = '';
        while(randNum.length() < length) {
            Integer diff = length-randNum.length();
            Integer i = Integer.valueOf(Math.Random()*Math.pow(10,diff));
            randNum += String.valueOf(i);
        }
        
        return randNum;
    }

    public static UserRole getUserRoleFromId(Id userRoleId) {
        List<UserRole> roles = [SELECT Id, Name FROM UserRole WHERE Id = :userRoleId LIMIT 1];
        if(roles.isEmpty())
            return null;
        return roles[0];
    }

    /**
     * Parameters:
     * String obj - API name of the object with the picklist.
     * String field - API name of the field from the object.
     * 
     * Returns:
     * Map<String,AscendUtils.PickListInfo> - A map of picklist labels to an 
     * object that stores the label, value, if it's active, and if it's the default value.
     */
    public static Map<String,AscendUtils.PickListInfo> getPickListInfo(String objName, String fieldName) {
        Map<String,AscendUtils.PickListInfo> pickListMap = new Map<String,AscendUtils.PickListInfo>();

        SObjectType objToken;
        try {
            objToken = Schema.getGlobalDescribe().get(objName);
        } catch(Exception e) {
            return pickListMap;
        }
        if(objToken == null)
            return pickListMap;

        DescribeSObjectResult objDef = objToken.getDescribe();
        Map<String, SObjectField> fields = objDef.fields.getMap(); 

        SObjectField field;
        try {
            field = fields.get(fieldName);
        } catch(Exception e) {
            return pickListMap;
        }
        if(field == null)
            return pickListMap;

        DescribeFieldResult fieldResult = field.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        for(Schema.PicklistEntry pickListVal : ple) {
            AscendUtils.PickListInfo picklistObj = new AscendUtils.PickListInfo();
            picklistObj.label = pickListVal.getLabel();
            picklistObj.value = pickListVal.getValue();
            picklistObj.isActive = pickListVal.isActive();
            picklistObj.isDefaultValue = pickListVal.isDefaultValue();

            pickListMap.put(pickListVal.getLabel(), picklistObj);
        }   

        return pickListMap;
    }

    public class PickListInfo {
        public String label {get;set;}
        public String value {get;set;}
        public Boolean isActive {get;set;}
        public Boolean isDefaultValue {get;set;}
    }
}