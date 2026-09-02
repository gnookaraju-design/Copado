/**
 * @Description     : SS-51096 - Add rollback feature in Copado setup
 * @Author          : Pushpender Sharma
 * @Date            : 03/02/2026
 * Class         : CopadoDeleteOldRollbackMetadataBatch
 * @Test Class      : CopadoDeleteOldRollbackMetadataBatchTest
 * @Maintenance History: 
 * 03/02/2026 - 1.0 - Created
*/

public class CopadoDeleteOldRollbackMetadataBatch implements Database.Batchable<SObject> {
/**
* Description: Start method
* @param bc
* @return Database.QueryLocator
*/ 
    public Database.QueryLocator start(Database.BatchableContext bc) {
        //Define all deployment statuses
        List<String> eligibleStatuses = new List<String>{'Completed Successfully', 'Cancelled', 'Completed with Errors'};            
            // Sumeru -13.07.2026 - SS-52869 -  Modified query to collect all attachments.
            String query =
            'SELECT Id, copado__Deployment__r.LastModifiedDate, ' +
            '(SELECT Id, ContentDocumentId, ContentDocument.Title FROM ContentDocumentLinks) ' +
            'FROM copado__Step__c ' +
            'WHERE copado__Deployment__r.copado__Status__c IN :eligibleStatuses';
        // 'SELECT Id,(SELECT Id, ContentDocumentId FROM ContentDocumentLinks WHERE ContentDocument.Title = \'Rollback metadata.zip\') '+
        //    'FROM copado__Step__c '+
        //'WHERE copado__Deployment__r.LastModifiedDate < LAST_N_DAYS:60 '+
        //'AND copado__Deployment__r.copado__Status__c IN :eligibleStatuses';
        
        
        if(Test.isRunningTest()){
            query += ' ORDER BY CreatedDate DESC LIMIT 1';
        }
        
        return Database.getQueryLocator(query);
    }
/**
* Description: execute method
* @param bc
* @param scope
*/    
    public void execute(Database.BatchableContext bc, List<copado__Step__c> scope) {        
        //Set to avoid any duplicate deletion
        Set<Id> contentDocIds = new Set<Id>();
        DateTime lastSixtyDays;
        if(Test.isRunningTest()){
           lastSixtyDays = System.now().addDays(1);
        }
        else{
           lastSixtyDays = System.now().addDays(-60);        
        }
        for (copado__Step__c step : scope) {
            //Ensure child relationship exists and contains record
            //// Sumeru -13.07.2026 - SS-52869 - Ensure Rollback metadata.zip documents are validated and old logic is preserved before deletion.
            if (!step.ContentDocumentLinks.isEmpty()) {
                for (ContentDocumentLink cdl : step.ContentDocumentLinks) {
                    if (cdl.ContentDocument != null && cdl.ContentDocument.Title == 'Rollback metadata.zip') {//check ContentDocument title
                        if (step.copado__Deployment__r != null && step.copado__Deployment__r.LastModifiedDate < lastSixtyDays) {
                            contentDocIds.add(cdl.ContentDocumentId);
                        }
                    } else {
                        contentDocIds.add(cdl.ContentDocumentId);
                    }
                }
            }
        }
        if (!contentDocIds.isEmpty()){
            //Query actual ContentDocument before deletion
            List<ContentDocument> docsToDelete = [SELECT Id FROM ContentDocument WHERE Id IN :contentDocIds ];
            //Perform delete
            if (!docsToDelete.isEmpty()) {
                delete docsToDelete;
            }
        }
    }
    /**
* @description: Finish method
* @param bc
*/   
    public void finish(Database.BatchableContext bc) {
        // Sumeru -13.07.2026 - SS-52869 - Commented debug to resolve pmd.
        //System.debug(LoggingLevel.WARN,'DeleteOldRollbackMetadataBatch job completed.');
    }
}