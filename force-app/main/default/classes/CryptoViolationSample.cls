public class CryptoViolationSample {
    public Blob encryptData(Blob dataToEncrypt) {
        // P1 Violation: Hardcoded encryption key
        Blob cryptoKey = Blob.valueOf('HardcodedSecretKey12345678901234');
        return Crypto.encryptWithManagedIV('AES256', cryptoKey, dataToEncrypt);
    }
}