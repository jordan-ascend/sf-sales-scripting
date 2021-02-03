Opporunity_Script_Junction__c j = new Opporunity_Script_Junction__c();
List<Opporunity_Script_Junction__c> junctions = new List<Opporunity_Script_Junction__c>{
    new Opporunity_Script_Junction__c(
        Opportunity__c = '0064W00000xQDAfQAO',
        Sales_Rep_Script__c = 'a004W00000doRAxQAM',
        Opporunity_Stage__c = 'Prospecting'
    ),
    new Opporunity_Script_Junction__c(
        Opportunity__c = '0064W00000xQDAfQAO',
        Sales_Rep_Script__c = 'a004W00000doRc5QAE',
        Opporunity_Stage__c = 'Qualification'
    ),
    new Opporunity_Script_Junction__c(
        Opportunity__c = '0064W00000xQDAfQAO',
        Sales_Rep_Script__c = 'a004W00000doRa4QAE',
        Opporunity_Stage__c = 'Value Proposition'
    ),
    new Opporunity_Script_Junction__c(
        Opportunity__c = '0064W00000xQ18VQAS',
        Sales_Rep_Script__c = 'a004W00000do3vWQAQ',
        Opporunity_Stage__c = 'Prospecting'
    ),
    new Opporunity_Script_Junction__c(
        Opportunity__c = '0064W00000xQ18VQAS',
        Sales_Rep_Script__c = 'a004W00000doRc5QAE',
        Opporunity_Stage__c = 'Qualification'
    ),
    new Opporunity_Script_Junction__c(
        Opportunity__c = '0064W00000xQ18VQAS',
        Sales_Rep_Script__c = 'a004W00000doRa4QAE',
        Opporunity_Stage__c = 'Value Proposition'
    ),
    new Opporunity_Script_Junction__c(
        Opportunity__c = '0064W00000xQ18VQAS',
        Sales_Rep_Script__c = 'a004W00000doRa9QAE',
        Opporunity_Stage__c = 'Negotiation/Review'
    )
};
insert junctions;