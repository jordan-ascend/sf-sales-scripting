/**
 * Process scripts with tags in them. The tokens will be replaced with the proper information requested.
 * All comments refering to tags are refering to the {Opportunity.someField__c} being written into scripts.
 */
public with sharing class ScriptTemplateHandler {

    private static List<String> allowedTokens;

    /**
     * Scans scripts and looks for tags, {Opportunity.someField__c} and dynamically replace them with info 
     * related to the current opp being looked at.
     */
    public static String interpolateScript(String script, Id oppId) {
        allowedTokens = getAllowedTokens();
        // Matches patterns such as {firstWord.SecondWord} or {opportunity.name}
        List<String> exprList = AscendUtils.getMatchedExpressions(script, '\\{\\w+[\\.\\w+]+\\w+\\}');
        
        Set<String> invalidTokens = new Set<String>();
        // Set<String> tokensToAdd = new Set<String>();
        if(exprList.isEmpty()) {
            return script;
        }

        ScriptTemplateHandlerHelper.ExprListSortResult result = ScriptTemplateHandlerHelper.sortExprList(exprList, allowedTokens);
        Map<String,String> fieldData = result.fieldData;
        Map<String,String> regexExprMap = result.regexExprMap;
        Set<String> tokensToAdd = result.tokensToAdd;

        System.debug(fieldData);
        System.debug(regexExprMap);

        // Build and execute query.
        List<String> tmpList = new List<String>();
        tmpList.addAll(fieldData.keySet());
        tmpList.add('Id'); 

        SObject opp = ScriptTemplateHandlerHelper.getOpportunity(oppId, tmpList);

        invalidTokens = ScriptTemplateTagValidator.validateValidTags(tokensToAdd);
        tokensToAdd = ScriptTemplateHandlerHelper.removeInvalidTokens(invalidTokens, tokensToAdd);

        if(!tokensToAdd.isEmpty() || !invalidTokens.isEmpty()) {
            // System.debug(JSON.serialize(tokensToAdd));
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
                if(fieldData.get(key) == null) {
                    fieldData.put(key, '[No data for ' + key + ']');
                }
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

    private static boolean stringListContainsIgnoreCase(List<String> strList, String str) {
        for(String s: strList) {
            if(str.containsIgnoreCase(s)) {
                return true;
            }
        }
        return false;
    }

    private static List<String> getAllowedTokens() {
        List<String> tags = new List<String>();
        for(Script_Template_Tag__mdt templateTagObj: [SELECT Field_Name__c FROM Script_Template_Tag__mdt]) {
            tags.add(templateTagObj.Field_Name__c);
        }

        if(Test.isRunningTest() && tags.contains('Opportunity.Description')) {
            Integer i = tags.indexOf('Opportunity.Description');
            tags.remove(i);
        }

        return tags;
    }

}
