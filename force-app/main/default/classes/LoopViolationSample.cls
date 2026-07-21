public class LoopViolationSample {
    public void updateAccountContacts(List<Id> accountIds) {
        for (Id accId : accountIds) {
            // P1 Violation: SOQL query inside a loop
            List<Contact> contacts = [SELECT Id, LastName FROM Contact WHERE AccountId = :accId];
            
            for (Contact con : contacts) {
                con.LastName = con.LastName + ' Updated';
                // P1 Violation: DML statement inside a loop
                update con;
            }
        }
    }
}