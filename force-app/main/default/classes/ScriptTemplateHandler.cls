/**
 * Process scripts with tokens in them. The tokens will be replaced with the proper information requested.
 */
public class ScriptTemplateHandler {

    // Matches patterns such as {firstWord.SecondWord} or {opportunity.name}
    private static Pattern tokenMatch = Pattern.compile('\\{\\w+\\.\\w+\\}');
    private static final List<String> ALLOWED_TOKENS = new List<String>{
        'Ammount',
        'CloseDate',
        'Description',
        'LeadSource',
        'Name',
        'Type'
    };

    public static String tokenizeString(String str, SObject obj) {
        // if(String.isBlank(str) || !(str.contains('{') && str.contains('}')))
        //     return str;

        List<String> strList = str.split(' ');
        List<String> returnStrList = new List<String>();

        for(String s: strList) {
            String temp = s.trim();
            System.debug('Going through words: ' + temp);
            if(tokenMatch.matcher(temp).find() && stringListContainsIgnoreCase(ALLOWED_TOKENS, temp)) {

                // List<String> tempStrLst = temp.split('[\\{\\}]');
                // tempStrLst = AscendUtils.slice(tempStrLst, ge, l)
                // Kind of a crude form of interpolation. Works at a basic level. Working on refining int.

                System.debug('Token: ' + temp);
                System.debug('Requested field: ' + temp.substring(temp.indexOf('.')+1, temp.indexOf('}')));
                String newWord = String.valueOf(obj.get(temp.substring(temp.indexOf('.')+1, temp.indexOf('}'))));
                if(s.substring(0, 1).equals(' '))
                    newWord = ' ' + newWord;
                returnStrList.add(newWord);
            }
            else {
                returnStrList.add(s);
            }
        }
        return String.join(returnStrList, ' ');
    }

    private static boolean stringListContainsIgnoreCase(List<String> strList, String str) {
        for(String s: strList) {
            System.debug('Matching string to list: ' + str + ' to ' + s);
            if(str.containsIgnoreCase(s))
                return true;
        }
        System.debug('Matching returning false');
        return false;
    }

}
