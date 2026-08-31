@isTest
private class LoopViolationSampleTest {
    @isTest
    static void testUpdateAccountContacts() {
        // Create test data
        Account testAcc = new Account(Name = 'Test Loop');
        insert testAcc;

        Contact testCon = new Contact(LastName = 'Smith', AccountId = testAcc.Id);
        insert testCon;

        List<Id> accountIds = new List<Id>{testAcc.Id};
        LoopViolationSample sample = new LoopViolationSample();

        // Execute the vulnerable method
        Test.startTest();
        sample.updateAccountContacts(accountIds);
        Test.stopTest();

        // Verify the update occurred
        Contact updatedCon = [SELECT LastName FROM Contact WHERE Id = :testCon.Id];
        System.assert(updatedCon.LastName.contains('Updated'), 'Contact last name should be updated.');
    }
}