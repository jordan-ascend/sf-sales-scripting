/**
 * Process scripts with tags in them. The tokens will be replaced with the proper information requested.
 * All comments refering to tags are refering to the {Opportunity.someField__c} being written into scripts.
 */
public class ScriptTemplateHandler {

    private  List<String> ALLOWED_TOKENS;
    // private  final List<String> ALLOWED_TOKENS = new List<String>{
    //     'Opportunity.Amount',
    //     'Opportunity.CloseDate',
    //     'Opportunity.Description',
    //     'Opportunity.LeadSource',
    //     'Opportunity.Name',
    //     'Opportunity.Type',
    //     'Opportunity.Account.Name',
    //     'Opportunity.Account.AccountNumber',
    //     'Opportunity.Account.YearStarted'
    // };

    /**
     * Scans scripts and looks for tags, {Opportunity.someField__c} and dynamically replace them with info 
     * related to the current opp being looked at.
     */
    public String interpolateScript(String script, Id oppId) {
        ALLOWED_TOKENS = getAllowedTokens();
        // Matches patterns such as {firstWord.SecondWord} or {opportunity.name}
        List<String> exprList = AscendUtils.getMatchedExpressions(script, '\\{\\w+[\\.\\w+]+\\w+\\}');
        
        Set<String> invalidTokens = new Set<String>();
        Set<String> tokensToAdd = new Set<String>();
        if(exprList.isEmpty())
            return script;
        Map<String,String> regexExprMap = new  Map<String,String>();
        Map<String,String> fieldData = new Map<String,String>();

        // Sorting the results of exprList into maps to query the opportunity and keep track of the resulting 
        // query and what fields get used where in the script.
        for(String expr: exprList) {
            List<String> exprComponents = expr.split('[\\{\\.\\}]');
            exprComponents = removeBlanks(exprComponents);
            if(stringListContainsIgnoreCase(ALLOWED_TOKENS, expr)) {
                if(exprComponents.size() > 3) throw new ScriptInterpolationException('API field name cannot go more than one level deep.');
                if(exprComponents[0] != 'Opportunity') throw new ScriptInterpolationException('Tag must start with "Opportunity. i.e. {Opportunity.Name}');
                String key = exprComponents[1]+(exprComponents.size()==3?'.'+exprComponents[2]:'');
                fieldData.put(key, null);
                regexExprMap.put(key, '\\{' + exprComponents[0] + '\\.' + exprComponents[1] + (exprComponents.size()==3?'\\.' + exprComponents[2]:'') + '\\}');
            }
            else {
                tokensToAdd.add(expr);
            }
        }

        System.debug(fieldData);
        System.debug(regexExprMap);

        // Build and execute query.
        List<String> tmpList = new List<String>();
        tmpList.addAll(fieldData.keySet());
        tmpList.add('Id');
        String qryStr = 'SELECT ' + String.join(tmpList, ',') + ' FROM Opportunity WHERE Id = \'' + oppId + '\'';
        System.debug(qryStr);
        SObject opp;
        if(!String.isBlank(oppId)) {
            opp = Database.query(qryStr)[0];
        } else {
            opp = new Opportunity(Name = 'Temp Opp For Validation');
        }

        invalidTokens = validateValidTags(tokensToAdd);
        for(String tag: invalidTokens) {
            if(tokensToAdd.contains(tag))
                tokensToAdd.remove(tag);
        }  

        System.debug(opp);
        
        System.debug(invalidTokens);
        System.debug(tokensToAdd);

        if(!tokensToAdd.isEmpty() || !invalidTokens.isEmpty()) {
            System.debug(JSON.serialize(tokensToAdd));
            throw new ScriptInterpolationException('Invalid API names. ' + JSON.serialize(tokensToAdd) + ':::' + JSON.serialize(invalidTokens));
        }

        // Sorting queried data into fieldData map. The key is the field api name.
        for(String key: fieldData.keySet()) {
            try {
                List<String> keyCmp = key.split('\\.');
                System.debug(key);
                System.debug(keyCmp);
                if(keyCmp.size() < 2) {
                    fieldData.put(key, String.valueOf(opp?.get(key)));
                } else {
                    fieldData.put(key, String.valueOf(opp?.getSObject(keyCmp[0])?.get(keyCmp[1])));
                }
                if(fieldData.get(key) == null)
                    fieldData.put(key, '[No data for ' + key + ']');
            } catch (Exception e) {
                invalidTokens.add(regexExprMap.get(key));
                fieldData.put(key, '[No data for ' + key + ']');
            }
        }

        

        System.debug(regexExprMap);
        System.debug(fieldData);

        // Find the first tag and replace with appropriate value.
        // Doing this to initialize a pattern and matcher.
        tmpList.clear();
        tmpList.addAll(regexExprMap.keySet());
        Pattern tokenMatch = Pattern.compile(regexExprMap.get(tmpList[0]));
        Matcher m = tokenMatch.matcher(script);
        String newScript = m.replaceAll(fieldData.get(tmpList[0]));
        
        regexExprMap.remove(tmpList[0]);

        // Find and replace tags for the rest of the script.
        for(String key: regexExprMap.keySet()) {
            m.reset(newScript);
            m.usePattern(Pattern.compile(regexExprMap.get(key)));
            newScript = m.replaceAll(fieldData.get(key));
        }

        return newScript;
    }

    private Set<String> validateValidTags(Set<String> invalidTokens) {
        Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Set<String> invalidTags = new Set<String>();
        for(String tag: invalidTokens) {
            List<String> exprComponents = tag.split('[\\{\\.\\}]');//oppForValidation
            exprComponents = removeBlanks(exprComponents);
            System.debug(exprComponents.size());
            System.debug(exprComponents);
            if(!exprComponents[0].equalsIgnoreCase('Opportunity') || exprComponents.size() < 2 || exprComponents.size() > 3) {
                invalidTags.add(tag);
                continue;
            }
            Map <String, Schema.SObjectField> fieldMap = Opportunity.getSObjectType().getDescribe().fields.getMap();
            List<String> fieldNames = new List<String>();
            for(SObjectField field: fieldMap.values()) 
                fieldNames.add(field.getDescribe().name);
            try{
                if(exprComponents[1].equalsIgnoreCase('Account'))
                    exprComponents[1] = 'AccountId';
               if(exprComponents.size() == 2) {
                    if(!fieldNames.contains(exprComponents[1])) {
                        System.debug(exprComponents[1]);
                        invalidTags.add(tag);
                        continue;
                    }
                    if(exprComponents[1].endsWith('__r')) {
                        System.debug(exprComponents[1]);
                        invalidTags.add(tag);
                        continue;
                    }
                } else {
                    if(exprComponents[1].endsWith('__c')) {
                        System.debug(exprComponents[1]);
                        invalidTags.add(tag);
                        continue;
                    }
                    if(!fieldNames.contains(exprComponents[1])) {
                        System.debug(exprComponents[1]);
                        invalidTags.add(tag);
                        continue;
                    } else {
                        String oppField = exprComponents[1].replace('__r', '__c');
                        Schema.SObjectField SOField = fieldMap.get(oppField);
                        String relationshipName = SOField.getDescribe().getRelationshipName();

                        System.debug(oppField);
                        System.debug(relationshipName);
                        Map <String, Schema.SObjectField> relationFieldMap = schemaMap.get(relationshipName).getDescribe().fields.getMap();
                        List<String> relationFieldNames = new List<String>();
                        for(SObjectField field: relationFieldMap.values()) 
                            relationFieldNames.add(field.getDescribe().name);
                        if(!relationFieldNames.contains(exprComponents[2])) {
                            System.debug(exprComponents[1]);
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
        System.debug(invalidTags);
        return invalidTags;      
    }

    private boolean stringListContainsIgnoreCase(List<String> strList, String str) {
        for(String s: strList) {
            if(str.containsIgnoreCase(s))
                return true;
        }
        return false;
    }

    public static List<String> removeBlanks(List<String> strList) {
        List<String> newList = new List<String>();
        for(String str: strList) {
            if(String.isNotBlank(str))
                newList.add(str);
        }
        return newList;
    }

    private List<String> getAllowedTokens() {
        List<String> tags = new List<String>();
        for(Script_Template_Tag__mdt templateTagObj: [SELECT Field_Name__c FROM Script_Template_Tag__mdt]) {
            tags.add(templateTagObj.Field_Name__c);
        }
        return tags;
    }

}
