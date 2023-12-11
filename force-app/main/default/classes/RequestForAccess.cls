/*
 Name: RequestForAccess
 Description: Get the Request and upgrade the access and schedule apex for revoke the access
 Created By : Cloud Avengers
 Date        :9-Dec-2023
 
*/

global class RequestForAccess {
    
    public static void AccessTriggerController(List<Access__c> access)
    {
           for(Access__c obj : access)
           {
               if (Obj.Status__c == 'Approved') 
                {  
                    String RecordId=obj.Id;
                    RequestForAccess.upgradeAccess(RecordId);
                }
           }
    }
 
    public static Access__c getAccessDetails(String CurrentRecordId){
    Access__c access = [SELECT Id, Name, Profile_to_Update__c, Permission_to_Update__c, Request_For_Profile__c, Request_For_Permission_Set__c,
                        Access_Expire_Date__c,Access_Expire_Time__c,Email__c,Phone_Number__c
                        FROM Access__c
                        WHERE Id =: CurrentRecordId ];
    return access;
    }
    @future
    global static void upgradeAccess(String RecordId){
        
        Access__c access = RequestForAccess.getAccessDetails(RecordId);
        
        Profile profiles;
        String RequesterOriginalProfileId;
        String permissionSetId;
        String CurrentRecordId = RecordId;
        List<PermissionSet> permissionSets = new List<PermissionSet>{};
        
        String SchedulejobName = access.Name; 
        String ProfileToBeUpdate = access.Profile_to_Update__c;
        String PermissionSetToBeUpdate = access.Permission_to_Update__c;
        Boolean ProfileCheck = access.Request_For_Profile__c;
        Boolean PermissionCheck = access.Request_For_Permission_Set__c;
        Date EstimatedDate = access.Access_Expire_Date__c; 
        Time EstimatedTime = access.Access_Expire_Time__c; 
      
        Integer hour = EstimatedTime.hour();
        Integer min = EstimatedTime.minute();
        Datetime ScheduledTime = Datetime.newInstanceGmt(EstimatedDate.year(), EstimatedDate.month(), EstimatedDate.day(), 0, 0, 0);
        
        String cronExpression = 0 + ' ' + min + ' ' + hour + ' ' + ScheduledTime.day() + ' ' + ScheduledTime.month() + ' ? ' + ScheduledTime.year();
        String userId = UserInfo.getUserId();
        
        String RequesterUserId = [SELECT Id, ProcessInstance.SubmittedBy.Id 
                                  FROM ProcessInstanceStep
                                  WHERE StepStatus = 'Approved' AND ActorId =:userId 
                                  ORDER BY CreatedDate DESC LIMIT 1].ProcessInstance.SubmittedBy.Id;
        User requestedUser = [SELECT Id, firstname, lastname, IsActive, ProfileId, UserType FROM User WHERE Id = :RequesterUserId];
        
        if(PermissionCheck){
           permissionSets = [SELECT Id FROM PermissionSet WHERE Label = :  PermissionSetToBeUpdate LIMIT 1];
           if (!permissionSets.isEmpty()) {
                permissionSetId = permissionSets[0].Id;
                try {
                    PermissionSetAssignment newAssignment = new PermissionSetAssignment( 
                                            AssigneeId = RequesterUserId,
                                            PermissionSetId = permissionSetId
                    );
                    insert newAssignment;
                }catch (Exception e) {
                    System.debug('Error Message: ' + e.getMessage());
                    throw e;
                }
            } 
        }
        if(ProfileCheck){
            RequesterOriginalProfileId = requestedUser.ProfileId;
            profiles = [SELECT Id, Name FROM profile WHERE Name =: ProfileToBeUpdate];
            requestedUser.ProfileId = profiles.Id;
            try{
                UPDATE requestedUser; 
            } catch(Exception e){

            }
        }

        AccessSchedularClass scheduledJob = new AccessSchedularClass(RequesterUserId, RequesterOriginalProfileId, permissionSetId);
        System.schedule( SchedulejobName, cronExpression , scheduledJob);
    }
    
     global static void revoketheProfileAccess(String RequesterUserId, String RequesterOriginalProfileId){
         
         User requestedUser = [SELECT Id, firstname, lastname, email,  IsActive, ProfileId, UserType 
                               FROM User  
                               WHERE Id = :RequesterUserId];
         
         Profile OldProfile = [SELECT Id, Name 
                               FROM profile 
                               WHERE id=: RequesterOriginalProfileId];

         requestedUser.ProfileId = OldProfile.Id;
         
         UPDATE requestedUser;
     } 
    
    global static void revokethePermissionsetAccess(String RequesterId, String RequesterPermissionSetId){ 

        PermissionSetAssignment existingAssignment = [
            SELECT Id
            FROM PermissionSetAssignment
            WHERE AssigneeId = : RequesterId
            AND PermissionSetId = : RequesterPermissionSetId
            LIMIT 1
        ];
        
        if (existingAssignment != null) 
        {
            DELETE existingAssignment ;
        }else{
            System.debug('Permission Set is not Assigned to the User');
        }
    } 
}