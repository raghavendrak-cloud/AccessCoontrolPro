/*
 Name: AccessSchedularClass
 Description: Schedule apex for revoke the access
 Created By : Cloud Avengers
 Date        :9-Dec-2023
 
*/

global class AccessSchedularClass implements Schedulable
{
    global String RequesterId;
    global String RequesterprofileId;
    global String RequesterPermissionSetId;
    
    public AccessSchedularClass(String RequesterId, String RequesterprofileId, String RequesterPermissionSetId)
    {
         this.RequesterId = RequesterId;
         this.RequesterprofileId = RequesterprofileId;
         this.RequesterPermissionSetId = RequesterPermissionSetId;
    }
    
    public void execute(SchedulableContext sc) 
    {
        if(RequesterprofileId != null)
        {
            RequestForAccess.revoketheProfileAccess(RequesterId, RequesterprofileId);
        }
        if(RequesterPermissionSetId != null)
        {
           RequestForAccess.revokethePermissionsetAccess(RequesterId, RequesterPermissionSetId);
        }
        else 
        {
            System.debug('Values are Not Selected');
        } 

    } 
    
}