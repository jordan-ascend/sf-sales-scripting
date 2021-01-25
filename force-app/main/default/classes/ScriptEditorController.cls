public class ScriptEditorController {
    public String scriptName {get;set;}
    public String script {get;set;} // May also need blob depending on how rich text editor works.
    public String selectedStage {get;set;}
    public String selectedOppType {get;set;}
    public String selectedUserRole {get;set;}
    public jgaude__Sales_Rep_Script__c scriptObject {get;set;}

    public ScriptEditorController() {
        Id id = ApexPages.currentPage().getParameters().get('id');
        this.scriptObject = getScriptRecord(Id);
        getFields();
    }

    public ScriptEditorController(ApexPages.StandardController stdController) {
        Id recordId = ((jgaude__Sales_Rep_Script__c)stdController.getRecord()).Id;
        this.scriptObject = getScriptRecord(recordId);
        getFields();
    }

    public PageReference saveScript() {
        try {
            upsert scriptObject;
        } catch(System.DMLException e) {
            ApexPages.addMessages(e);
            return null;
        }
        PageReference redirectSuccess = new ApexPages.StandardController(scriptObject).view();
        return (redirectSuccess);
    }

    /**
     * Get field info from object and display it in the form.
     */
    private void getFields() {
        this.script = this.scriptObject.jgaude__Script__c;
        this.selectedStage = this.scriptObject.jgaude__OpportunityStage__c;
        this.selectedOppType = this.scriptObject.jgaude__OpportunityType__c;
        this.selectedUserRole = this.scriptObject.jgaude__UserRole__c;
    }

    private jgaude__Sales_Rep_Script__c getScriptRecord(Id recordId) {
        return (recordId == null) ? new jgaude__Sales_Rep_Script__c() : [SELECT Name, jgaude__Script__c, jgaude__OpportunityStage__c, jgaude__OpportunityType__c, jgaude__UserRole__c, jgaude__scriptUser__c, jgaude__Opportunity__c FROM jgaude__Sales_Rep_Script__c WHERE Id = :recordId];
    }

    public List<SelectOption> getStageList() {
        return AscendUtils.createSelectOption(AscendUtils.getPicklistValues('Opportunity', 'StageName'));
    }

    public List<SelectOption> getOppTypeList() {
        return AscendUtils.createSelectOption(AscendUtils.getPicklistValues('Opportunity', 'Type'), true);
    }

    public List<SelectOption> getUserRoleList() {
        List<UserRole> roles = AscendUtils.getAllUserRoles();
        List<String> rolesString = new List<String>();
        for(UserRole role: roles) {
            rolesString.add(role.Name);
        }

        return AscendUtils.createSelectOption(rolesString, true);
    }
}
