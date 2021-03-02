public with sharing class ScriptEditorController {
    public Boolean userFieldNotEditable {get;set;}
    public Boolean showToAddList {
        get {
            return !tagsToAdd.isEmpty();
        }
        private set;
    }
    @testVisible private Sales_Rep_Script__c scriptObject {get;set;}
    private Sales_Rep_Script__c tempScript {get;set;}
    // public String scriptName {get;set;}
    private String script {get;set;} // May also need blob depending on how rich text editor works.
    private String selectedStage {get;set;}
    private String selectedOppType {get;set;}
    private String selectedUserRole {get;set;}
    private String templateTags {get;set;}
    @testVisible private Set<String> tagsToAdd {get;set;}
    private Set<String> invalidTags {get;set;}
    // private Boolean active {get;set;}
    private Boolean displayModel {get;set;}
    // private PageReference returnPage {get;set;}
    private Boolean personalEdit {get;set;}
    private id userId {get;set;}

    public ScriptEditorController() {
        Id id = ApexPages.currentPage().getParameters().get('id');
        this.scriptObject = getScriptRecord(Id);
        commonInit();
    }

    public ScriptEditorController(ApexPages.StandardController stdController) {
        Id recordId = ((Sales_Rep_Script__c)stdController.getRecord()).Id;
        this.scriptObject = getScriptRecord(recordId);
        commonInit();
    }

    private void commonInit() {
        // getFields();
        this.userId = UserInfo.getUserId();
        getTemplateTagsMDT();
        checkForScriptUserPermission();
        // returnPage = new PageReference(ApexPages.currentPage().getParameters().get('retURL'));  
        tagsToAdd = new Set<String>();
        invalidTags = new Set<String>();
        
        this.userFieldNotEditable = this.personalEdit;
        System.debug(getIsReadOnly());
        // this.active = scriptObject.Active__c == null? false:scriptObject.Active__c;
    }

    public PageReference saveScript() {
        System.debug('Attempting Save...');
        try {
            // scriptObject.Active__c = this.active;
            // System.debug('State of Active__c ' + this.active);
            String validationResult = validateTemplateTags(); 

            if(String.isBlank(validationResult)) {
                if(personalEdit) {
                    validatePersonalEdit();
                } 
                if(Sales_Rep_Script__c.sObjectType.getDescribe().isAccessible() ||
                Sales_Rep_Script__c.sObjectType.getDescribe().isCreateable() ||
                Sales_Rep_Script__c.sObjectType.getDescribe().isUpdateable()) {
                    upsert scriptObject;
                }
                
            } else {

                System.debug(validationResult);
                setInvalidTagsSets(validationResult);
                showModal();
                return null;
            }
        } catch(System.DMLException e) {
            ApexPages.addMessages(e);
            System.debug('DML Exception:' + e.getMessage() + '\n' + e.getStackTraceString());
            System.debug('return null DML Exception');
            return null;
        }
        catch(ScriptValidationException e) {
            System.debug('Validation Exception:' + e.getMessage() + '\n' + e.getStackTraceString());
            System.debug('return null Validation Exception');
            return null;
        }
        PageReference redirectSuccess = new ApexPages.StandardController(scriptObject).view();
        return (redirectSuccess);
        // return returnPage;
    }

    /**
     * Make sure that only the script is being modified when creating a personalized copy of a script object.
     */
    private void validatePersonalEdit() {
        List<ApexPages.Message> errs = new List<ApexPages.Message>();
        if(scriptObject.Active__c != tempScript.Active__c) {errs.add(new ApexPages.Message(Apexpages.Severity.ERROR, 'Cannot modify "Active"'));}
        if(scriptObject.Opportunity__c != tempScript.Opportunity__c) {errs.add(new ApexPages.Message(Apexpages.Severity.ERROR, 'Cannot modify "Opportunity"'));}
        if(scriptObject.OpportunityStage__c != tempScript.OpportunityStage__c) {errs.add(new ApexPages.Message(Apexpages.Severity.ERROR, 'Cannot modify "Opportunity Stage"'));}
        if(scriptObject.OpportunityType__c != tempScript.OpportunityType__c) {errs.add(new ApexPages.Message(Apexpages.Severity.ERROR, 'Cannot modify "Opportunity Type"'));}
        if(scriptObject.scriptUser__c != tempScript.scriptUser__c) {errs.add(new ApexPages.Message(Apexpages.Severity.ERROR, 'Cannot modify "User"'));}
        if(scriptObject.UserRole__c != tempScript.UserRole__c) {errs.add(new ApexPages.Message(Apexpages.Severity.ERROR, 'Cannot modify "User"'));}
        if(scriptObject.Name != tempScript.Name) {errs.add(new ApexPages.Message(Apexpages.Severity.ERROR, 'Cannot modify "Name"'));}

        if(!errs.isEmpty()) {
            for(ApexPages.Message m: errs) {ApexPages.addMessage(m);}
            throw new ScriptValidationException('Script Validation failed. One or more fields are now allowed to be changed');
        }
    }

    /**
     * Need to know if a script user is accessing this page. That affrects what can be edited.
     */
    private void checkForScriptUserPermission() {
        System.debug(this.userId);
        Integer i = [SELECT Id FROM PermissionSetAssignment
                     WHERE AssigneeId = :this.userId AND PermissionSet.Name = 'Script_User'].size();

        if(i == 1) {
            this.personalEdit = true;
            
            if(this.scriptObject.scriptUser__c == null || this.scriptObject.scriptUser__c != this.userId) {
                this.scriptObject.Id = null;
                this.scriptObject.scriptUser__c = this.userId;
                this.scriptObject.Name = this.scriptObject.Name + ' [Personalized by ' + UserInfo.getName() + ']';
            }
            this.tempScript = new Sales_Rep_Script__c(
                Active__c = this.scriptObject.Active__c,
                Name = this.scriptObject.Name,
                Opportunity__c = this.scriptObject.Opportunity__c,
                OpportunityStage__c = this.scriptObject.OpportunityStage__c,
                OpportunityType__c = this.scriptObject.OpportunityType__c,
                scriptUser__c = this.scriptObject.scriptUser__c,
                UserRole__c = this.scriptObject.UserRole__c
            );
        } else {
            this.personalEdit = false;
        }

        System.debug(this.personalEdit);
    }

    /**
     * If the user tries to change anything that is not allowed to be changed, it will change back.
     */
    public Pagereference processUserChange() {
        if(this.personalEdit) {
            this.scriptObject.scriptUser__c = this.tempScript.scriptUser__c;
            this.scriptObject.Opportunity__c = this.tempScript.Opportunity__c;
        }
        return null;
    }

    private String validateTemplateTags() {
        // Opportunity opp = oppForValidation;
        // ScriptTemplateHandler hndlr = new ScriptTemplateHandler();

        try{
            ScriptTemplateHandler.interpolateScript(scriptObject.Script__c, null);
        } catch(ScriptInterpolationException e) {
            String erMsg = e.getMessage();
            System.debug(erMsg);
            ApexPages.addMessages(e);
            return erMsg;
        } catch(Exception e) {
            throw e;
        }
        
        return null;
    }

    /**
     * pulls the erroneous tags from a string and separates them into two lists. One for tags that can be added as valid tags and ones that can't. 
     */
    private void setInvalidTagsSets(String tags) {
        List<String> taglists = new List<String>();
        taglists.addAll(tags.split(':::'));
        tagsToAdd = deserializeString(taglists[0]);
        invalidTags = deserializeString(taglists[1]);
    }

    /**
     * Deserializes JSON lists specifically.
     */
    private Set<String> deserializeString(String str) {
        Set<String> strSet = new Set<String>();
        List<Object> deserializedObjects = (List<Object>)JSON.deserializeUntyped(str.substring(str.indexOf('['), str.indexOf(']')+1));
        System.debug(deserializedObjects.size());
        for(Object strObj: deserializedObjects) {
            strSet.add((String)strObj);
        }
        return strSet;
    }

    /**
     * Get field info from object and display it in the form.
     */
    // private void getFields() {
    //     this.script = this.scriptObject.Script__c;
    //     this.selectedStage = this.scriptObject.OpportunityStage__c;
    //     this.selectedOppType = this.scriptObject.OpportunityType__c;
    //     this.selectedUserRole = this.scriptObject.UserRole__c;
    //     this.active = this.scriptObject.Active__c;
    // }

    private Sales_Rep_Script__c getScriptRecord(Id recordId) {
        return (recordId == null) ? new Sales_Rep_Script__c() : [SELECT Name, Script__c, OpportunityStage__c, OpportunityType__c, UserRole__c, scriptUser__c, Opportunity__c, Active__c FROM Sales_Rep_Script__c WHERE Id = :recordId];
    }

    public List<SelectOption> getStageList() {
        return AscendUtils.createSelectOption(AscendUtils.getPicklistValues('Opportunity', 'StageName'));
    }

    public List<SelectOption> getOppTypeList() {
        return AscendUtils.createSelectOption(AscendUtils.getPicklistValues('Opportunity', 'Type'), true);
    }

    /**
     * Creates SelectOption list of user roles.
     */
    public List<SelectOption> getUserRoleList() {
        List<UserRole> roles = AscendUtils.getAllUserRoles();
        List<String> rolesString = new List<String>();
        for(UserRole role: roles) {
            rolesString.add(role.Name);
        }

        return AscendUtils.createSelectOption(rolesString, true);
    }

    /**
     * Get list of allowed template tags from custom metadata.
     */
    private void getTemplateTagsMDT() {
        List<String> tags = new List<String>();
        for(Script_Template_Tag__mdt templateTagObj: [SELECT Field_Name__c FROM Script_Template_Tag__mdt]) {
            tags.add('{' + templateTagObj.Field_Name__c + '}');
        }
        templateTags = String.join(tags, '\n');
    }

    public void closeModal() {        
        displayModel = false;  
        tagsToAdd.clear();  
        invalidTags.clear();
    }     
    public void showModal() {        
        displayModel = true;    
    }

    public Boolean getIsReadOnly() {
        return personalEdit;
    }

    public String getTemplateTags() {
        return templateTags;
    }

    public Set<String> getTagsToAdd() {
        return tagsToAdd;
    }

    public Set<String> getInvalidTags() {
        return invalidTags;
    }

    public Boolean getDisplayModel() {
        return displayModel;
    }

    public Sales_Rep_Script__c getScriptObject() {
        return scriptObject;
    }

    /** Creates new metadata records for new script tags */
    public void saveNewTags() {
        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        System.debug(tagsToAdd);
        String tagsToAddString = '';
        for(String tag: tagsToAdd) {
            System.debug(tag);
            List<String> exprComponents = tag.split('[\\{\\.\\}]');
            exprComponents = ScriptTemplateHandler.removeBlanks(exprComponents);
            Metadata.CustomMetadata tagsMetadata = new Metadata.CustomMetadata();
            String label = exprComponents[1]+(exprComponents.size()==3?exprComponents[2]:'');
            tagsMetadata.fullName = 'Script_Template_Tag.'+label;
            tagsMetadata.label = label;

            Metadata.CustomMetadataValue tagField = new Metadata.CustomMetadataValue();
            tagField.field = 'Field_Name__c';
            System.debug(exprComponents[0] + '.' + exprComponents[1] + (exprComponents.size() == 3 ? '.' + exprComponents[2] : ''));
            tagField.value = exprComponents[0] + '.' + exprComponents[1] + (exprComponents.size() == 3 ? '.' + exprComponents[2] : '');

            tagsMetadata.values.add(tagField);
            mdContainer.addMetadata(tagsMetadata);
            tagsToAddString += '\n' + tag;
        }

        MetadataCallback mdCallBack = new MetadataCallback();
        if(!Test.isRunningTest()) {
            Id jobId = Metadata.Operations.enqueueDeployment(mdContainer, mdCallBack);
            System.debug('Script Editor Tag Metadata Deployment. Job Id: ' + jobId);
        }
        closeModal();
        templateTags += tagsToAddString;
        // getTemplateTags();
    }
}