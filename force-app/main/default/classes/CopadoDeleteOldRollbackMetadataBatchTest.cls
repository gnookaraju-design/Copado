/*
* Author        : Pushpender Sharma
* Description   : SS-51096 - Add rollback feature in Copado setup
* Date          : 03/02/2026
* Test Class    : CopadoDeleteOldRollbackMetadataBatchTest
* Maintenance History: 
* 03/02/2026 - 1.0 - Created
* 02/09/2026 - 1.1 - Added insertCopadoLicense() helper to fix 
*                    FIELD_CUSTOM_VALIDATION_EXCEPTION on deployment.
*                    No original code was modified.
*/
@IsTest
private class CopadoDeleteOldRollbackMetadataBatchTest {

    // ---------------------------------------------------------------
    // NEW: Private helper to provision a Copado License for a given user.
    // Uses Type.forName() so the class compiles safely even if the
    // Copado managed package is not installed in the target org.
    // Called inside System.runAs() to cover the runAs user context.
    // ---------------------------------------------------------------
    private static void insertCopadoLicense(Id userId) {
        try {
            Type licenseType = Type.forName('copado__Copado_License__c');
            if (licenseType != null) {
                SObject license = (SObject) licenseType.newInstance();
                license.put('copado__Enable_Copado__c', true);
                license.put('SetupOwnerId', userId);
                insert license;
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Copado License setup skipped for user ' + userId + ': ' + e.getMessage());
        }
    }

    @IsTest
    static void testBatchDeletesRollbackMetadata() { 
             // Sumeru -13.07.2026 - SS-52869 - modified method to run as system user having Admin License 
           user adminUser = [select id from user where username like 'rishabh.gautam@bunge.com%' Limit 1];
           System.runAs(adminUser) {

            // NEW: Provision Copado License for adminUser to avoid
            // FIELD_CUSTOM_VALIDATION_EXCEPTION during DML inside runAs block.
            insertCopadoLicense(adminUser.Id);

            //List<String> eligibleStatuses = new List<String>{'Completed Successfully', 'Cancelled', 'Completed with Errors'};  
                // Get an existing Step record
                 /*
                copado__Step__c step = [
                SELECT Id 
                FROM copado__Step__c 
                WHERE copado__Deployment__r.LastModifiedDate < LAST_N_DAYS:60
                AND copado__Deployment__r.copado__Status__c IN :eligibleStatuses
                ORDER BY CreatedDate DESC
                LIMIT 1
                ];*/
            copado__Deployment__c deploymentRecord = new copado__Deployment__c();
            deploymentRecord.copado__Status__c ='Cancelled';
            insert deploymentRecord;
            
            copado__Step__c userStory = new copado__Step__c();
            userStory.copado__Deployment__c = deploymentRecord.id;
            insert userStory;
            
            // Create ContentVersion (File)
            ContentVersion cv = new ContentVersion(
                Title = 'Rollback metadata.zip',
                PathOnClient = 'Rollback metadata.zip',
                VersionData = Blob.valueOf('Test Data'),
                IsMajorVersion = true
            );
            insert cv;
            
            // Retrieve ContentDocumentId
            cv = [SELECT Id, ContentDocumentId, Title FROM ContentVersion WHERE Id = :cv.Id];
            
            // Link file to Step
            ContentDocumentLink cdl = new ContentDocumentLink(
                ContentDocumentId = cv.ContentDocumentId,
                LinkedEntityId = userStory.Id,
                ShareType = 'V',
                Visibility = 'AllUsers'
            );
            insert cdl;
            
            Test.startTest();
            Database.executeBatch(new CopadoDeleteOldRollbackMetadataBatch(), 1);
            Test.stopTest();
            List<ContentDocument> docs = [
                SELECT Id
                FROM ContentDocument
                WHERE Id = :cv.ContentDocumentId
            ];
           // Sumeru -13.07.2026 - SS-52869 - added assert to resolve static pmd issue.
            System.assertEquals(0, docs.size(), 'Document deleted');
        }
    }
}