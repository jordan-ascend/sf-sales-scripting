public with sharing class ScriptTemplateHandlerHelper {

    /**
     * Sorting the results of exprList into maps to query the opportunity and keep track of the resulting query and what fields get used where in the script.
     */
    public static ScriptTemplateHandlerHelper.ExprListSortResult sortExprList(List<String> exprList, List<String> allowedTokens) {
        ScriptTemplateHandlerHelper.ExprListSortResult result = new ScriptTemplateHandlerHelper.ExprListSortResult();
        result.tokensToAdd = new Set<String>();
        result.regexExprMap = new  Map<String,String>();
        result.fieldData = new Map<String,String>();

        for(String expr: exprList) {
            List<String> exprComponents = expr.split('[\\{\\.\\}]');
            exprComponents = removeBlanks(exprComponents);
            if(stringListContainsIgnoreCase(allowedTokens, expr)) {
                if(exprComponents.size() > 3) {
                    throw new ScriptInterpolationException('API field name cannot go more than one level deep.');
                }
                if(exprComponents[0] != 'Opportunity') {
                    throw new ScriptInterpolationException('Tag must start with "Opportunity. i.e. {Opportunity.Name}');
                }
                String key = concatExprKey(exprComponents);
                result.fieldData.put(key, null);
                result.regexExprMap.put(key, concatExprComps(exprComponents));
            }
            else {
                result.tokensToAdd.add(expr);
            }
        }

        return result;
    }

    public static List<String> removeBlanks(List<String> strList) {
        List<String> newList = new List<String>();
        for(String str: strList) {
            if(String.isNotBlank(str)) {
                newList.add(str);
            }
        }
        return newList;
    }

    public static SObject getOpportunity(Id oppId, List<String> tmpList) {
        SObject opp;
        if(!String.isBlank(oppId)) {
            opp = Database.query('SELECT ' + String.join(tmpList, ',') + ' FROM Opportunity WHERE Id = \'' + oppId + '\'')[0];
        } else {
            opp = new Opportunity(Name = 'Temp Opp For Validation');
        }
        return opp;
    }

    public static Set<String> removeInvalidTokens(Set<String> invalidTokens,  Set<String> tokensToAdd) {
        for(String tag: invalidTokens) {
            if(tokensToAdd.contains(tag)) {
                tokensToAdd.remove(tag);
            }
        }
        return tokensToAdd;
    }

    private static String concatExprComps(List<String> exprComponents) {
        return '\\{' + exprComponents[0] + '\\.' + exprComponents[1] + (exprComponents.size()==3?'\\.' + exprComponents[2]:'') + '\\}';
    }

    private static String concatExprKey(List<String> exprComponents) {
        return exprComponents[1]+(exprComponents.size()==3?'.'+exprComponents[2]:'');
    }

    private static boolean stringListContainsIgnoreCase(List<String> strList, String str) {
        for(String s: strList) {
            if(str.containsIgnoreCase(s)) {
                return true;
            }
        }
        return false;
    }

    public class ExprListSortResult {
        public Set<String> tokensToAdd;
        public Map<String,String> regexExprMap;
        public Map<String,String> fieldData;
    }
}
