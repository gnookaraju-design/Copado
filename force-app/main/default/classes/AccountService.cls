public with sharing class AccountService {

    public static String createAccount(String accountName) {
        if (String.isBlank(accountName)) {
            return 'Account name cannot be blank';
        }

        Account acc = new Account(Name = accountName);
        insert acc;

        return 'Account Created';
    }
}