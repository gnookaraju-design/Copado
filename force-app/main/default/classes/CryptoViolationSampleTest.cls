@isTest
private class CryptoViolationSampleTest {
    @isTest
    static void testEncryptData() {
        CryptoViolationSample sample = new CryptoViolationSample();
        Blob dataToEncrypt = Blob.valueOf('Sensitive Data');

        // Execute the vulnerable method
        Blob encryptedData = sample.encryptData(dataToEncrypt);

        // Verify the encryption returned a result
        System.assertNotEquals(null, encryptedData, 'Encrypted data should not be null.');
        System.assertNotEquals(dataToEncrypt, encryptedData, 'Encrypted data should differ from original.');
    }
}