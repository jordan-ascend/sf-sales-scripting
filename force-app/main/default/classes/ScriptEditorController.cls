public class ScriptEditorController {
    public String scriptName {get;set;}
    public String script {get;set;} // May also need blob depending on how rich text editor works.
    public String selectedStage {get;set;}
    public String selectedOppType {get;set;}
    public String selectedUserRole {get;set;}
    public String templateTags {get;set;}
    public Set<String> tagsToAdd {get;set;}
    public Set<String> invalidTags {get;set;}
    public Boolean active {get;set;}
    public Boolean displayModel {get;set;}
    public Boolean showInvalidList {
        get {
            return !invalidTags.isEmpty();
        }
        private set;
    }
    public Boolean showToAddList {
        get {
            return !tagsToAdd.isEmpty();
        }
        private set;
    }
    public Sales_Rep_Script__c scriptObject {get;set;}
    public String testResponse {get;set;}
    private Opportunity oppForValidation {
        get {
            if(oppForValidation==null) {
                oppForValidation = [SELECT Id FROM Opportunity LIMIT 1];
                return oppForValidation;
            } else {
                return oppForValidation;
            }
        }
        set;
    }

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
        getFields();
        getTemplateTags();
        tagsToAdd = new Set<String>();
        invalidTags = new Set<String>();
    }

    public PageReference saveScript() {
        try {
            scriptObject.Active__c = this.active;
            String validationResult = validateTemplateTags(); 
            if(String.isBlank(validationResult))
                upsert scriptObject;
            else {
                // List<Object> tagList = (List<Object>)JSON.deserializeUntyped(validationResult.substring(validationResult.indexOf('['), validationResult.indexOf(']')+1));
                // System.debug(tagList.size());
                // for(Object str: tagList)
                //     tagsToAdd.add((String)str);
                // validateValidTags();
                System.debug(validationResult);
                setInvalidTagsSets(validationResult);
                displayModel = true;
                return null;
            }
        } catch(System.DMLException e) {
            ApexPages.addMessages(e);
            System.debug('return null DML Exception');
            return null;
        }
        PageReference redirectSuccess = new ApexPages.StandardController(scriptObject).view();
        return (redirectSuccess);
    }

    private String validateTemplateTags() {
        Opportunity opp = oppForValidation;

        try{
            ScriptTemplateHandler.interpolateScript(scriptObject.Script__c, opp.Id);
        } catch(ScriptInterpolationException e) {
            String erMsg = e.getMessage();
            System.debug(erMsg);
            ApexPages.addMessages(e);
            testResponse = erMsg;
            return erMsg;
        } catch(Exception e) {
            throw e;
        }
        
        return null;
    }

    private void setInvalidTagsSets(String tags) {
        List<String> taglists = new List<String>();
        taglists.addAll(tags.split(':::'));
        tagsToAdd = deserializeString(taglists[0]);
        invalidTags = deserializeString(taglists[1]);
    }

    private Set<String> deserializeString(String str) {
        Set<String> strSet = new Set<String>();
        List<Object> deserializedObjects = (List<Object>)JSON.deserializeUntyped(str.substring(str.indexOf('['), str.indexOf(']')+1));
        System.debug(deserializedObjects.size());
        for(Object strObj: deserializedObjects)
            strSet.add((String)strObj);
        return strSet;
    }

    /**
     * Get field info from object and display it in the form.
     */
    private void getFields() {
        this.script = this.scriptObject.Script__c;
        this.selectedStage = this.scriptObject.OpportunityStage__c;
        this.selectedOppType = this.scriptObject.OpportunityType__c;
        this.selectedUserRole = this.scriptObject.UserRole__c;
        this.active = this.scriptObject.Active__c;
    }

    private Sales_Rep_Script__c getScriptRecord(Id recordId) {
        return (recordId == null) ? new Sales_Rep_Script__c() : [SELECT Name, Script__c, OpportunityStage__c, OpportunityType__c, UserRole__c, scriptUser__c, Opportunity__c, Active__c FROM Sales_Rep_Script__c WHERE Id = :recordId];
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

    private void getTemplateTags() {
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

    public void saveNewTags() {
        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        for(String tag: tagsToAdd) {
            List<String> exprComponents = tag.split('[\\{\\.\\}]');
            exprComponents = ScriptTemplateHandler.removeBlanks(exprComponents);
            Metadata.CustomMetadata tagsMetadata = new Metadata.CustomMetadata();
            String label = exprComponents[1]+(exprComponents.size()==3?exprComponents[2]:'');
            tagsMetadata.fullName = 'Script_Template_Tag.'+label;
            tagsMetadata.label = label;

            Metadata.CustomMetadataValue tagField = new Metadata.CustomMetadataValue();
            tagField.field = 'Field_Name__c';
            tagField.value = tag;

            tagsMetadata.values.add(tagField);
            mdContainer.addMetadata(tagsMetadata);
        }

        MetadataCallback mdCallBack = new MetadataCallback();
        Id jobId = Metadata.Operations.enqueueDeployment(mdContainer, mdCallBack);
        System.debug('Script Editor Tag Metadata Deployment. Job Id: ' + jobId);
        closeModal();
        saveScript();
    }
}