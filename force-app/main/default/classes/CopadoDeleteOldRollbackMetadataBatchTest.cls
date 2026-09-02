/*
 * Author       : Pushpender Sharma
 * Description  : SS-51096 - Add rollback feature in Copado setup
 * Date         : 03/02/2026
 * Test Class   : CopadoDeleteOldRollbackMetadataBatchTest
 * Maintenance History:
 * 03/02/2026 - 1.0 - Created
 * 13/07/2026 - 1.1 - Sumeru - SS-52869 - Modified method to run as system user having Admin License
 * 02/09/2026 - 1.2 - Added @testSetup to provision Copado License using dynamic Apex to resolve
 *                    FIELD_CUSTOM_VALIDATION_EXCEPTION and Invalid type compile error
 */
@IsTest
private class CopadoDeleteOldRollbackMetadataBatchTest {

    // ---------------------------------------------------------------
    // @testSetup runs ONCE before all test methods in this class.
    // Uses Type.forName() to dynamically reference copado__Copado_License__c
    // so the class compiles even if the Copado package is not installed.
    // ---------------------------------------------------------------
    @testSetup
    static void setupLicense() {
        try {
            Type licenseType = Type.forName('copado__Copado_License__c');
            if (licenseType != null) {
                SObject license = (SObject) licenseType.newInstance();
                license.put('copado__Enable_Copado__c', true);
                license.put('SetupOwnerId', UserInfo.getUserId());
                insert license;
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Copado License setup skipped: ' + e.getMessage());
        }
    }

    // ---------------------------------------------------------------
    // Helper method to insert Copado License dynamically for any user.
    // Reused inside System.runAs() blocks to avoid code duplication.
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
        // Sumeru - 13.07.2026 - SS-52869 - Modified method to run as system user having Admin License
        User adminUser = [SELECT Id FROM User WHERE Username LIKE 'rishabh.gautam@bunge.com%' LIMIT 1];

        System.runAs(adminUser) {

            // Provision Copado License for adminUser inside runAs block.
            // @testSetup runs as the test-running user, not as adminUser,
            // so adminUser needs its own license record.
            insertCopadoLicense(adminUser.Id);

            // Create Deployment record with eligible status
            copado__Deployment__c deploymentRecord = new copado__Deployment__c();
            deploymentRecord.copado__Status__c = 'Cancelled';
            insert deploymentRecord;

            // Create Step linked to Deployment
            copado__Step__c stepRecord = new copado__Step__c();
            stepRecord.copado__Deployment__c = deploymentRecord.Id;
            insert stepRecord;

            // Create ContentVersion (File)
            ContentVersion cv = new ContentVersion(
                Title = 'Rollback metadata.zip',
                PathOnClient = 'Rollback metadata.zip',
                VersionData = Blob.valueOf('Test Data'),
                IsMajorVersion = true
            );
            insert cv;

            // Retrieve ContentDocumentId after insert
            cv = [SELECT Id, ContentDocumentId, Title FROM ContentVersion WHERE Id = :cv.Id];

            // Link file to Step
            ContentDocumentLink cdl = new ContentDocumentLink(
                ContentDocumentId = cv.ContentDocumentId,
                LinkedEntityId = stepRecord.Id,
                ShareType = 'V',
                Visibility = 'AllUsers'
            );
            insert cdl;

            Test.startTest();
            Database.executeBatch(new CopadoDeleteOldRollbackMetadataBatch(), 1);
            Test.stopTest();

            // Sumeru - 13.07.2026 - SS-52869 - Added assert to resolve static PMD issue.
            List<ContentDocument> docs = [
                SELECT Id
                FROM ContentDocument
                WHERE Id = :cv.ContentDocumentId
            ];
            System.assertEquals(0, docs.size(), 'Document should have been deleted by the batch.');
        }
    }
}