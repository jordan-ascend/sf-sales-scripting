/**
 * Process scripts with tags in them. The tokens will be replaced with the proper information requested.
 * All comments refering to tags are refering to the {Opportunity.someField__c} being written into scripts.
 */
public class ScriptTemplateHandler {

    private static final List<String> ALLOWED_TOKENS = getAllowedTokens();
    // private static final List<String> ALLOWED_TOKENS = new List<String>{
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
    public static String interpolateScript(String script, Id oppId) {
        // Matches patterns such as {firstWord.SecondWord} or {opportunity.name}
        List<String> exprList = AscendUtils.getMatchedExpressions(script, '\\{\\w+[\\.\\w+]+\\w+\\}');
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
                fieldData.put(exprComponents[1]+(exprComponents.size()==3?'.'+exprComponents[2]:''), null);
                regexExprMap.put(exprComponents[1]+(exprComponents.size()==3?'.'+exprComponents[2]:''), '\\{' + exprComponents[0] + '\\.' + exprComponents[1] + (exprComponents.size()==3?'\\.' + exprComponents[2]:'') + '\\}');
            }
            else {
                throw new ScriptInterpolationException('Invalid API name.');
            }
        }

        System.debug(fieldData);
        System.debug(regexExprMap);

        // Build and execute query.
        List<String> tmpList = new List<String>();
        tmpList.addAll(fieldData.keySet());
        String qryStr = 'SELECT ' + String.join(tmpList, ',') + ' FROM Opportunity WHERE Id = \'' + oppId + '\'';
        System.debug(qryStr);
        SObject opp = Database.query(qryStr)[0];

        // Sorting queried data into fieldData map. The key is the field api name.
        for(String key: fieldData.keySet()) {
            List<String> keyCmp = key.split('\\.');
            System.debug(key);
            System.debug(keyCmp);
            if(keyCmp.size() < 2)
                fieldData.put(key, String.valueOf(opp.get(key)));
            else
                fieldData.put(key, String.valueOf(opp.getSObject(keyCmp[0]).get(keyCmp[1])));
            if(fieldData.get(key) == null)
                fieldData.put(key, '[No data for ' + key + ']');
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
            if(str.containsIgnoreCase(s))
                return true;
        }
        return false;
    }

    private static List<String> removeBlanks(List<String> strList) {
        List<String> newList = new List<String>();
        for(String str: strList) {
            if(String.isNotBlank(str))
                newList.add(str);
        }
        return newList;
    }

    private static List<String> getAllowedTokens() {
        List<String> tags = new List<String>();
        for(Script_Template_Tag__mdt templateTagObj: [SELECT Field_Name__c FROM Script_Template_Tag__mdt]) {
            tags.add(templateTagObj.Field_Name__c);
        }
        return tags;
    }

}
