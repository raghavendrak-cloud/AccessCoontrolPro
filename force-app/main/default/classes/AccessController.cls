
/*
 Name: AccessSchedularClass
 Description: Schedule apex for revoke the access
 Created By : Cloud Avengers
 Date        :9-Dec-2023
 
*/
public with sharing class AccessController {
    @AuraEnabled(cacheable=true)
    public static List<Access__c> getAccessRecord(){
        try {
            List<Access__c> accessList = [SELECT Id, Name, CreatedDate, CreatedById, Owner.Name, Deployment_Information__c, 
                                                 Access_Expire_Date__c, Access_Expire_Time__c, Permission_to_Update__c, Status__c, Current_Profile__c, 
                                                 Profile_to_Update__c, Phone_Number__c, Email__c
                                         FROM Access__c
                                         WHERE Status__c != NULL
                                         ORDER BY CreatedDate DESC];
            return accessList;
            } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}