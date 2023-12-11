/*  Name: AccessTest
 Description: Test Class to cover RequestForAccess, AccessTrigger and AccessSchedulerClass.
 Created By : Cloud Avengers
 Date        :9-Dec-2023
*/

@isTest
public class AccessTest 
{
    @testSetup
    public static void createAccessData()
    {  
        Profile testProfile = [SELECT Id, Name FROM Profile WHERE Name = 'Custom Standard Admin' LIMIT 1];
        User testUser = new User(
           FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            UserName = 'testDemouser11@example.com',
            ProfileId = testProfile.Id,
            Alias = 'TUser',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_IN',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        INSERT testUser;
        
        Access__c accessObject = new Access__c(
            OwnerId = testUser.Id,
            Request_For_Profile__c = true,
            Request_For_Permission_Set__c = true,
            Name = 'Test Request',
            Profile_to_Update__c = 'System Administrator',
            Phone_Number__c = '9876543657' ,
            Email__c = 'nareshkummara782@gmail.com',
            Access_Expire_Date__c = Date.today(),
            Access_Expire_Time__c = Time.newInstance(20, 30, 0, 0),
            Permission_to_Update__c = 'Experience Profile Manager'
        );
        INSERT accessObject;
    }
    @isTest
    static void testUpdateToRequestedProfile() {
        Id testRequest1 = [SELECT Id,Name FROM Access__c WHERE Name='Test Request'].Id;
        Id testUser1 = [SELECT id,Name FROM User WHERE UserName = 'testDemouser11@example.com'].id;
        Profile testProfile = [SELECT Id, Name FROM Profile WHERE Name = 'Custom Standard Admin' LIMIT 1];
       
        Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
        approvalRequest.setComments('Submitting record for approval');
        approvalRequest.setObjectId(testRequest1);
        approvalRequest.setProcessDefinitionNameOrId('Access_Object_Approval_Process');
        approvalRequest.setSubmitterId(testUser1);
        Approval.ProcessResult result = Approval.process(approvalRequest);
        Assert.isTrue(result.isSuccess());

        List<Id> newWorkItemIds = result.getNewWorkitemIds();
        Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
        req2.setComments('Approving request.');
        req2.setAction('Approve');
        req2.setNextApproverIds(new Id[] { UserInfo.getUserId() });
        req2.setWorkitemId(newWorkItemIds.get(0));
        Approval.ProcessResult result2 = Approval.process(req2);
        Assert.isTrue(result2.isSuccess());
       
        Test.startTest();
        RequestForAccess.upgradeAccess(testRequest1);
        Test.stopTest();
        
        User updatedUser = [SELECT Id, Profile.Name, ProfileId FROM User WHERE Id = :testUser1];
        Assert.areEqual('System Administrator', updatedUser.Name);
    }
    //reverting back to original profile
    @isTest
    static void testRevertBackToOriginalProfile() 
    {
        Id testRequest1 = [SELECT Id,Name FROM Access__c WHERE Name='Test Request'].Id;
        Id testUser1 = [select id,Name FROM User WHERE UserName = 'testDemouser11@example.com'].id;
        Profile testProfile = [SELECT Id, Name FROM Profile WHERE Name = 'Custom Standard Admin' LIMIT 1];
     
        Test.startTest();
        RequestForAccess.revoketheProfileAccess(testUser1, testProfile.Id);
        Test.stopTest();

        User revertedUser = [SELECT Id, Profile.Name, ProfileId FROM User WHERE Id = :testUser1];
        Assert.areEqual('Custom Standard Admin', revertedUser.Profile.Name);
    }
    //schedulong the job
    @isTest
    static void testScheduleForRequestAccess() {

        Id testUser1 = [SELECT Id, Name FROM User WHERE UserName = 'testDemouser11@example.com'].Id;
        Profile testProfile = [SELECT Id, Name FROM Profile WHERE Name = 'Custom Standard Admin' LIMIT 1];
        Test.startTest();
         String jobIdWithProfile = System.schedule('TestScheduleWithProfile', '0 30 21 10 12 ? 2023', new AccessSchedularClass(testUser1, testProfile.Id, null));
        Assert.isNull(null, jobIdWithProfile);
        Test.stopTest();
    }
     @isTest
    static void testRemovePermissionSet() {
        Id testRequest1 = [SELECT Id, Name FROM Access__c WHERE Name = 'Test Request'].Id;
        Id testUser1 = [SELECT Id, Name FROM User WHERE UserName = 'testDemouser11@example.com'].Id;
        Id testPermission = [SELECT Id, Name FROM PermissionSet WHERE label = 'Experience Profile Manager'].Id;
        
        List<PermissionSetAssignment> existingAssignments = [SELECT ID FROM PermissionSetAssignment WHERE AssigneeId = :testUser1 AND PermissionSetId = :testPermission];
        if (!existingAssignments.isEmpty()) {
            delete existingAssignments;
        }
        PermissionSetAssignment testAssignment = new PermissionSetAssignment(
                AssigneeId = testUser1,
                PermissionSetId = testPermission
                 );
            INSERT testAssignment;
        Test.startTest();
        RequestForAccess.revokethePermissionsetAccess(testUser1, testPermission);
        Test.stopTest();

       List<PermissionSetAssignment> remainingAssignments = [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :testUser1 AND PermissionSetId = :testPermission];
       Assert.areEqual(0, remainingAssignments.size());
    } 
}