public class ScriptTemplateTagValidator {
    private static Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
    private static Map <String, Schema.SObjectField> fieldMap = Opportunity.getSObjectType().getDescribe().fields.getMap();

    public static Set<String> validateValidTags(Set<String> invalidTokens) {
        // Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Set<String> invalidTags = new Set<String>();
        for(String tag: invalidTokens) {
            List<String> exprComponents = tag.split('[\\{\\.\\}]');//oppForValidation
            exprComponents = ScriptTemplateHandlerHelper.removeBlanks(exprComponents);
            
            if(!exprComponents[0].equalsIgnoreCase('Opportunity') || exprComponents.size() < 2 || exprComponents.size() > 3) {
                invalidTags.add(tag);
                continue;
            }
            Map <String, Schema.SObjectField> fieldMap = Opportunity.getSObjectType().getDescribe().fields.getMap();
            List<String> fieldNames = new List<String>();
            for(SObjectField field: fieldMap.values())  {
                fieldNames.add(field.getDescribe().name);
            }
            try{
                if(exprComponents[1].equalsIgnoreCase('Account')) {
                    exprComponents[1] = 'AccountId';
                }
               if(exprComponents.size() == 2) {
                    if(!fieldNames.contains(exprComponents[1])) {
                        invalidTags.add(tag);
                        continue;
                    }
                } else {
                    if(exprComponents[1].endsWith('__c')) {
                        invalidTags.add(tag);
                        continue;
                    }
                    if(!fieldNames.contains(exprComponents[1])) {
                        invalidTags.add(tag);
                        continue;
                    } else {
                        List<String> relationFieldNames = addRelatioFieldNames(exprComponents[1].replace('__r', '__c'));
                        if(!relationFieldNames.contains(exprComponents[2])) {
                            invalidTags.add(tag);
                            continue;
                        }
                    }
                }
            } catch(Exception e) {
                System.debug(e.getMessage());
                invalidTags.add(tag);
            }
        }
        return invalidTags;      
    }

    private static List<String> addRelatioFieldNames(String oppField) {
        Schema.SObjectField sOField = fieldMap.get(oppField);
        String relationshipName = sOField.getDescribe().getRelationshipName();

        Map <String, Schema.SObjectField> relationFieldMap = schemaMap.get(relationshipName).getDescribe().fields.getMap();
        List<String> relationFieldNames = new List<String>();
        for(SObjectField field: relationFieldMap.values()) {
            relationFieldNames.add(field.getDescribe().name);
        }

        return relationFieldNames;
    }
}
