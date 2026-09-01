@isTest
private class AccountServiceTest {

    @isTest
    static void testCreateAccount_Success() {

        Test.startTest();

        String result = AccountService.createAccount('Test Account');

        Test.stopTest();

        System.assertEquals('Account Created', result);

        Account acc = [
            SELECT Id, Name
            FROM Account
            WHERE Name = 'Test Account'
            LIMIT 1
        ];

        System.assertNotEquals(null, acc);
        System.assertEquals('Test Account', acc.Name);
    }

    @isTest
    static void testCreateAccount_BlankName() {

        Test.startTest();

        String result = AccountService.createAccount('');

        Test.stopTest();

        System.assertEquals('Account name cannot be blank', result);

        Integer countAccounts = [SELECT COUNT() FROM Account];
        System.assertEquals(0, countAccounts);
    }
}