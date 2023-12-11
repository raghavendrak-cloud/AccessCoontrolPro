/*
 Name: AccessTrigger
 Description: Triggering on Access__c Object on After Update
 Created By : Cloud Avengers
 Date        :9-Dec-2023
 
*/

trigger AccessTrigger on Access__c (after Update) {
   if (Trigger.isUpdate) 
   {
      RequestForAccess.AccessTriggerController(Trigger.new);       
   }
}