codeunit 132569 "Data Encryption Mgmt. Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Encryption Management]
    end;

    var
        CryptographyManagement: Codeunit "Cryptography Management";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        InputStringTxt: Label 'Test string';
        KeyTxt: Label 'key';
        WrongHashErr: Label 'Wrong hash generated';
        SHA512Txt: Label '811AA0C53C0039B6EAD0CA878B096EED1D39ED873FD2D2D270ABFB9CA620D3ED561C565D6DBD1114C323D38E3F59C00DF475451FC9B30074F2ABDA3529DF2FA7';
        HMACSHA512Txt: Label 'A4C31E9B1E4F224A437888B35856A8E914E0A6562317A52763ECEA0CF96CDBF6AC5C7D777F42BBD5AD41AEF425D7EDA429ED1C1D8EA080B436F4A7FEEC1DC238';
        HashAlgorithmType: Option MD5,SHA1,SHA256,SHA384,SHA512;
        KeyedHashAlgorithmType: Option HMACMD5,HMACSHA1,HMACSHA256,HMACSHA384,HMACSHA512;
        SHA512Base64Txt: Label 'gRqgxTwAObbq0MqHiwlu7R057Yc/0tLScKv7nKYg0+1WHFZdbb0RFMMj044/WcAN9HVFH8mzAHTyq9o1Kd8vpw==';
        HMACSHA512Base64Txt: Label 'pMMemx5PIkpDeIizWFao6RTgplYjF6UnY+zqDPls2/asXH13f0K71a1BrvQl1+2kKe0cHY6ggLQ29Kf+7B3COA==';

    [Test]
    [Scope('OnPrem')]
    procedure EncryptThrowsErrorWhenEncryptionIsNotEnabled()
    var
        TextToEncrypt: Text[215];
    begin
        // [SCENARIO 1] Call to the Encrypt function throws an error when the encryption is not enabled.
        // [GIVEN] A text to encrypt.
        // [GIVEN] Encryption is not set.
        // [WHEN] Encrypt method on the "Encryption Management" codeunit is called.
        // [THEN] An error is thrown suggesting that the encryption is not enabled.
        if CryptographyManagement.IsEncryptionEnabled() then
            CryptographyManagement.DisableEncryption(true);
        TextToEncrypt := CopyStr(LibraryUtility.GenerateRandomText(10), 1, 215);
        asserterror CryptographyManagement.EncryptText(TextToEncrypt);
        Assert.ExpectedError('Encryption is either not enabled or the encryption key cannot be found.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DecryptThrowsErrorWhenEncryptionIsNotEnabled()
    var
        TextToEncrypt: Text;
    begin
        // [SCENARIO 2] Call to the Decrypt function throws an error when the encryption is not enabled.
        // [GIVEN] A text to be decrypted.
        // [GIVEN] Encryption is not set.
        // [WHEN] Decrypt method on the "Encryption Management" codeunit is called.
        // [THEN] An error is thrown suggesting that the encryption is not enabled.
        if CryptographyManagement.IsEncryptionEnabled() then
            CryptographyManagement.DisableEncryption(true);
        TextToEncrypt := LibraryUtility.GenerateRandomText(10);
        asserterror CryptographyManagement.Decrypt(TextToEncrypt);
        Assert.ExpectedError('Encryption is either not enabled or the encryption key cannot be found.');
    end;

    [Test]
    [HandlerFunctions('HandleConfirm1')]
    [Scope('OnPrem')]
    procedure EncryptDecryptText()
    var
        TextToEncrypt: Text[215];
        EncryptedText: Text;
    begin
        // [SCENARIO 3] Text data can be encrypted and decrypted when the encryption is ON.
        // [GIVEN] A text to be encrypted.
        // [GIVEN] Encryption is turned ON.
        // [WHEN] Encrypt is called on the text data.
        // [THEN] Encrypted text is returned.
        // [WHEN] Decrypt is called on the encrypted text data.
        // [THEN] Decrypted text is returned.
        if not CryptographyManagement.IsEncryptionEnabled() then
            CryptographyManagement.EnableEncryption(FALSE);

        TextToEncrypt := CopyStr(LibraryUtility.GenerateRandomText(100), 1, 215);
        EncryptedText := CryptographyManagement.EncryptText(TextToEncrypt);
        Assert.AreNotEqual(TextToEncrypt, EncryptedText, 'Encrypted data seem to be same as the original text.');
        Assert.AreEqual(TextToEncrypt, CryptographyManagement.Decrypt(EncryptedText), 'Decrypted text different from the original text');
    end;

    // [Test]
    // [HandlerFunctions('HandleConfirmYes,HandlePasswordDlgOK,MessageHandler')]
    // [Scope('OnPrem')]
    // procedure EncryptionKeyCanBeExportedImported()
    // var
    //     ExportedKey: Text;
    //     DataEncryptionTestPage: TestPage "Data Encryption Management";
    // begin
    //     // [SCENARIO 5] Encryption Key can be imported to a file.
    //     // [GIVEN] Encryption is not enabled.
    //     // [WHEN] Import Encryption Key action is invoked.
    //     // [THEN] Encryption key can be uploaded to the server.

    //     CryptographyManagement.SetSilentFileUploadDownload(true, '');
    //     if not CryptographyManagement.IsEncryptionPossible() then
    //         CryptographyManagement.EnableEncryption(FALSE);

    //     DataEncryptionTestPage."Export Encryption Key";


    //     ExportedKey := CryptographyManagement.GetGlblTempClientFileName;
    //     Assert.AreNotEqual('', ExportedKey, 'Encryption key is not exported to the client location');

    //     CryptographyManagement.SetSilentFileUploadDownload(true, ExportedKey);
    //     CryptographyManagement.ImportKey;
    //     Assert.IsTrue(CryptographyManagement.IsEncryptionPossible, 'Encryption should be possible');
    // end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEncryptionMgmtPageOpenWhenEncryptionIsDisabled()
    var
        DataEncryptionManagement: TestPage "Data Encryption Management";
    begin
        if CryptographyManagement.IsEncryptionEnabled() then
            CryptographyManagement.DisableEncryption(true);

        DataEncryptionManagement.OpenView();
        Assert.IsFalse(DataEncryptionManagement.EncryptionEnabledState.Editable(), 'Enabled checkbox expected to be non editable');
        Assert.AreEqual('No', DataEncryptionManagement.EncryptionEnabledState.Value, 'Enabled checkbox expected to be unchecked');
        Assert.IsFalse(DataEncryptionManagement.EncryptionKeyExistsState.Editable(), 'Key Exists checkbox expected to be non editable');
        Assert.AreEqual('No', DataEncryptionManagement.EncryptionKeyExistsState.Value, 'Key Exists checkbox expected to be unchecked');
        Assert.IsTrue(DataEncryptionManagement."Enable Encryption".Enabled(), 'Enable action is expected to be enabled');
        Assert.IsTrue(DataEncryptionManagement."Import Encryption Key".Enabled(), 'Import action is expected to be enabled');
        Assert.IsFalse(DataEncryptionManagement."Export Encryption Key".Enabled(), 'Export action is expected to be disabled');
        Assert.IsFalse(DataEncryptionManagement."Disable Encryption".Enabled(), 'Disable Encryption action is expected to be disabled');
    end;

    [Test]
    [HandlerFunctions('HandleConfirm1')]
    [Scope('OnPrem')]
    procedure TestEncryptionMgmtPageOpenWhenEncryptionIsEnabled()
    var
        DataEncryptionManagement: TestPage "Data Encryption Management";
    begin
        if not CryptographyManagement.IsEncryptionPossible() then
            CryptographyManagement.EnableEncryption(FALSE);

        DataEncryptionManagement.OpenView();
        Assert.IsFalse(DataEncryptionManagement.EncryptionEnabledState.Editable(), 'Enabled checkbox expected to be non editable');
        Assert.AreEqual('Yes', DataEncryptionManagement.EncryptionEnabledState.Value, 'Enabled checkbox expected to be checked');
        Assert.IsFalse(DataEncryptionManagement.EncryptionKeyExistsState.Editable(), 'Key Exists checkbox expected to be non editable');
        Assert.AreEqual('Yes', DataEncryptionManagement.EncryptionKeyExistsState.Value, 'Key Exists checkbox expected to be checked');
        Assert.IsFalse(DataEncryptionManagement."Enable Encryption".Enabled(), 'Enable action is expected to be disabled');
        Assert.IsTrue(DataEncryptionManagement."Import Encryption Key".Enabled(), 'Import action is expected to be enabled');
        Assert.IsTrue(DataEncryptionManagement."Export Encryption Key".Enabled(), 'Export action is expected to be enabled');
        Assert.IsTrue(DataEncryptionManagement."Disable Encryption".Enabled(), 'Disable Encryption action is expected to be enabled');
    end;

    [Test]
    [HandlerFunctions('HandleConfirm1')]
    [Scope('OnPrem')]
    procedure TestEnableEncryptionInEncryptionMgmtPage()
    var
        DataEncryptionManagement: TestPage "Data Encryption Management";
    begin
        if CryptographyManagement.IsEncryptionEnabled() then
            CryptographyManagement.DisableEncryption(true);

        DataEncryptionManagement.OpenView();
        DataEncryptionManagement."Enable Encryption".Invoke();

        Assert.IsTrue(CryptographyManagement.IsEncryptionPossible(), 'Encryption is not possible');
        Assert.IsFalse(DataEncryptionManagement.EncryptionEnabledState.Editable(), 'Enabled checkbox expected to be non editable');
        Assert.AreEqual('Yes', DataEncryptionManagement.EncryptionEnabledState.Value, 'Enabled checkbox expected to be unchecked');
        Assert.IsFalse(DataEncryptionManagement.EncryptionKeyExistsState.Editable(), 'Key Exists checkbox expected to be non editable');
        Assert.AreEqual('Yes', DataEncryptionManagement.EncryptionKeyExistsState.Value, 'Key Exists checkbox expected to be unchecked');
        Assert.IsFalse(DataEncryptionManagement."Enable Encryption".Enabled(), 'Enable action is expected to be disabled');
        Assert.IsTrue(DataEncryptionManagement."Import Encryption Key".Enabled(), 'Import action is expected to be enabled');
        Assert.IsTrue(DataEncryptionManagement."Export Encryption Key".Enabled(), 'Export action is expected to be enabled');
        Assert.IsTrue(DataEncryptionManagement."Disable Encryption".Enabled(), 'Disable Encryption action is expected to be enabled');
    end;

    [Test]
    [HandlerFunctions('HandleConfirm1')]
    [Scope('OnPrem')]
    procedure TestDisableEncryptionInEncryptionMgmtPage()
    var
        DataEncryptionManagement: TestPage "Data Encryption Management";
    begin
        if not CryptographyManagement.IsEncryptionPossible() then
            CryptographyManagement.EnableEncryption(FALSE);

        DataEncryptionManagement.OpenView();
        DataEncryptionManagement."Disable Encryption".Invoke();

        Assert.IsFalse(CryptographyManagement.IsEncryptionEnabled(), 'Encryption is enabled');
        Assert.IsFalse(DataEncryptionManagement.EncryptionEnabledState.Editable(), 'Enabled checkbox expected to be non editable');
        Assert.AreEqual('No', DataEncryptionManagement.EncryptionEnabledState.Value, 'Enabled checkbox expected to be unchecked');
        Assert.IsFalse(DataEncryptionManagement.EncryptionKeyExistsState.Editable(), 'Key Exists checkbox expected to be non editable');
        Assert.AreEqual('No', DataEncryptionManagement.EncryptionKeyExistsState.Value, 'Key Exists checkbox expected to be unchecked');
        Assert.IsTrue(DataEncryptionManagement."Enable Encryption".Enabled(), 'Enable action is expected to be enabled');
        Assert.IsTrue(DataEncryptionManagement."Import Encryption Key".Enabled(), 'Import action is expected to be enabled');
        Assert.IsFalse(DataEncryptionManagement."Export Encryption Key".Enabled(), 'Export action is expected to be disabled');
        Assert.IsFalse(DataEncryptionManagement."Disable Encryption".Enabled(), 'Disable Encryption action is expected to be disabled');
    end;

    // [Test]
    // [HandlerFunctions('HandleConfirm1')]
    // [Scope('OnPrem')]
    // procedure TestExportActionCancelledInEncryptionMgmtPage()
    // var
    //     DataEncryptionManagement: TestPage "Data Encryption Management";
    // begin
    //     CryptographyManagement.SetSilentFileUploadDownload(true, '');
    //     if not CryptographyManagement.IsEncryptionPossible() then
    //         CryptographyManagement.EnableEncryption(FALSE);

    //     DataEncryptionManagement.OpenView();
    //     DataEncryptionManagement."Export Encryption Key".Invoke();
    //     Assert.AreEqual('', CryptographyManagement.GetGlblTempClientFileName, 'Encryption key is created');
    // end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetBlobGetContentHash()
    var
        TempBlob: Codeunit "Temp Blob";
        CryptographyManagement: Codeunit "Cryptography Management";
        OutStream: OutStream;
        InStr: InStream;
    begin
        // [FEATURE] [TempBlob function GetContentLength]
        // [GIVEN] A blob containing a seting 'abc'
        TempBlob.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.WriteText('abc');

        // [THEN] The SHA256-hash value of that string is 'BA7816BF8F01CFEA414140DE5DAE2223B00361A396177A9CB410FF61F20015AD'
        TempBlob.CreateInStream(InStr);
        Assert.AreEqual(
          'BA7816BF8F01CFEA414140DE5DAE2223B00361A396177A9CB410FF61F20015AD',
          CryptographyManagement.GenerateHash(InStr, HashAlgorithmType::SHA256),
          'Wrong hashvalue returned');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_MD5HashGeneration()
    var
        CryptographyManagement: Codeunit "Cryptography Management";
    begin
        // [FEATURE] [Hash]
        // [SCENARIO 228632] Generate hash using MD5 algorithm

        // [WHEN] GenerateHash is invoked with input string
        // [THEN] Correct MD5 hash is generated
        Assert.AreEqual(
          '0FD3DBEC9730101BFF92ACC820BEFC34',
          CryptographyManagement.GenerateHash(InputStringTxt, HashAlgorithmType::MD5), WrongHashErr);

        // [WHEN] GenerateHash is invoked with input string and key
        // [THEN] Correct HMACMD5 hash is generated
        Assert.AreEqual(
          '9BE0525D61D151628E90A9B41ACA7C38',
          CryptographyManagement.GenerateHash(InputStringTxt, GetKeyAsSecret(), KeyedHashAlgorithmType::HMACMD5), WrongHashErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_SHA1HashGeneration()
    var
        CryptographyManagement: Codeunit "Cryptography Management";
    begin
        // [FEATURE] [Hash]
        // [SCENARIO 228632] Generate hash using SHA1 algorithm

        // [WHEN] GenerateHash is invoked with input string
        // [THEN] Correct SHA1 hash is generated
        Assert.AreEqual(
          '18AF819125B70879D36378431C4E8D9BFA6A2599',
          CryptographyManagement.GenerateHash(InputStringTxt, HashAlgorithmType::SHA1), WrongHashErr);

        // [WHEN] GenerateHash is invoked with input string and key
        // [THEN] Correct HMACSHA1 hash is generated
        Assert.AreEqual(
          '8D9FD1B063F9C22DF573382B210B581DB67A333D',
          CryptographyManagement.GenerateHash(InputStringTxt, GetKeyAsSecret(), KeyedHashAlgorithmType::HMACSHA1), WrongHashErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_TestSHA256HashGeneration()
    var
        CryptographyManagement: Codeunit "Cryptography Management";
    begin
        // [FEATURE] [Hash]
        // [SCENARIO 228632] Generate hash using SHA256 algorithm

        // [WHEN] GenerateHash is invoked with input string
        // [THEN] Correct SHA256 hash is generated
        Assert.AreEqual(
          'A3E49D843DF13C2E2A7786F6ECD7E0D184F45D718D1AC1A8A63E570466E489DD',
          CryptographyManagement.GenerateHash(InputStringTxt, HashAlgorithmType::SHA256), WrongHashErr);

        // [WHEN] GenerateHash is invoked with input string and key
        // [THEN] Correct HMACSHA256 hash is generated
        Assert.AreEqual(
          '696BB89AEBCD37E936A8FC339345733C1434FA9577B8E6D1A75A29CCE0037C58',
          CryptographyManagement.GenerateHash(InputStringTxt, GetKeyAsSecret(), KeyedHashAlgorithmType::HMACSHA256), WrongHashErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_TestSHA384HashGeneration()
    var
        CryptographyManagement: Codeunit "Cryptography Management";
    begin
        // [FEATURE] [Hash]
        // [SCENARIO 228632] Generate hash using SHA384 algorithm

        // [WHEN] GenerateHash is invoked with input string
        // [THEN] Correct SHA384 hash is generated
        Assert.AreEqual(
          '83CA14EBF3005A10F50839742BDA82AA607D972A03B1E6A3086E29195CEAF05F038FECDFF02AFF6E9DCDD273268875F7',
          CryptographyManagement.GenerateHash(InputStringTxt, HashAlgorithmType::SHA384), WrongHashErr);

        // [WHEN] GenerateHash is invoked with input string and key
        // [THEN] Correct HMACSHA384 hash is generated
        Assert.AreEqual(
          'EF021136E20A1AA760C803BE21163772BAB48A53EF178A8F5BEB4CEB2E66830E1BBEE5DE26632CFF325352B80B52BB6F',
          CryptographyManagement.GenerateHash(InputStringTxt, GetKeyAsSecret(), KeyedHashAlgorithmType::HMACSHA384), WrongHashErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_TestSHA512HashGeneration()
    var
        CryptographyManagement: Codeunit "Cryptography Management";
    begin
        // [FEATURE] [Hash]
        // [SCENARIO 228632] Generate hash using SHA512 algorithm

        // [WHEN] GenerateHash is invoked with input string
        // [THEN] Correct SHA512 hash is generated
        Assert.AreEqual(
          SHA512Txt,
          CryptographyManagement.GenerateHash(InputStringTxt, HashAlgorithmType::SHA512), WrongHashErr);

        // [WHEN] GenerateHash is invoked with input string and key
        // [THEN] Correct HMACSHA512 hash is generated
        Assert.AreEqual(
          HMACSHA512Txt,
          CryptographyManagement.GenerateHash(InputStringTxt, GetKeyAsSecret(), KeyedHashAlgorithmType::HMACSHA512), WrongHashErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_MD5HashGenerationBase64()
    var
        CryptographyManagement: Codeunit "Cryptography Management";
    begin
        // [FEATURE] [Hash]
        // [SCENARIO 228632] Generate Base64 hash using MD5 algorithm

        // [WHEN] GenerateHash is invoked with input string
        // [THEN] Correct Base64 MD5 hash is generated
        Assert.AreEqual(
          'D9Pb7JcwEBv/kqzIIL78NA==',
          CryptographyManagement.GenerateHashAsBase64String(InputStringTxt, HashAlgorithmType::MD5), WrongHashErr);

        // [WHEN] GenerateHash is invoked with input string and key
        // [THEN] Correct Base64 HMACMD5 hash is generated
        Assert.AreEqual(
          'm+BSXWHRUWKOkKm0Gsp8OA==',
          CryptographyManagement.GenerateHashAsBase64String(InputStringTxt, GetKeyAsSecret(), KeyedHashAlgorithmType::HMACMD5), WrongHashErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_SHA1HashGenerationBase64()
    var
        CryptographyManagement: Codeunit "Cryptography Management";
    begin
        // [FEATURE] [Hash]
        // [SCENARIO 228632] Generate Base64 hash using SHA1 algorithm

        // [WHEN] GenerateHash is invoked with input string
        // [THEN] Correct Base64 SHA1 hash is generated
        Assert.AreEqual(
          'GK+BkSW3CHnTY3hDHE6Nm/pqJZk=',
          CryptographyManagement.GenerateHashAsBase64String(InputStringTxt, HashAlgorithmType::SHA1), WrongHashErr);

        // [WHEN] GenerateHash is invoked with input string and key
        // [THEN] Correct Base64 HMACSHA1 hash is generated
        Assert.AreEqual(
          'jZ/RsGP5wi31czgrIQtYHbZ6Mz0=',
          CryptographyManagement.GenerateHashAsBase64String(InputStringTxt, GetKeyAsSecret(), KeyedHashAlgorithmType::HMACSHA1), WrongHashErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_TestSHA256HashGenerationBase64()
    var
        CryptographyManagement: Codeunit "Cryptography Management";
    begin
        // [FEATURE] [Hash]
        // [SCENARIO 228632] Generate Base64 hash using SHA256 algorithm

        // [WHEN] GenerateHash is invoked with input string
        // [THEN] Correct Base64 SHA256 hash is generated
        Assert.AreEqual(
          'o+SdhD3xPC4qd4b27Nfg0YT0XXGNGsGopj5XBGbkid0=',
          CryptographyManagement.GenerateHashAsBase64String(InputStringTxt, HashAlgorithmType::SHA256), WrongHashErr);

        // [WHEN] GenerateHash is invoked with input string and key
        // [THEN] Correct Base64 HMACSHA256 hash is generated
        Assert.AreEqual(
          'aWu4muvNN+k2qPwzk0VzPBQ0+pV3uObRp1opzOADfFg=',
          CryptographyManagement.GenerateHashAsBase64String(InputStringTxt, GetKeyAsSecret(), KeyedHashAlgorithmType::HMACSHA256), WrongHashErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_TestSHA384HashGenerationBase64()
    var
        CryptographyManagement: Codeunit "Cryptography Management";
    begin
        // [FEATURE] [Hash]
        // [SCENARIO 228632] Generate Base64 hash using SHA384 algorithm

        // [WHEN] GenerateHash is invoked with input string
        // [THEN] Correct Base64 SHA384 hash is generated
        Assert.AreEqual(
          'g8oU6/MAWhD1CDl0K9qCqmB9lyoDseajCG4pGVzq8F8Dj+zf8Cr/bp3N0nMmiHX3',
          CryptographyManagement.GenerateHashAsBase64String(InputStringTxt, HashAlgorithmType::SHA384), WrongHashErr);

        // [WHEN] GenerateHash is invoked with input string and key
        // [THEN] Correct Base64 HMACSHA384 hash is generated
        Assert.AreEqual(
          '7wIRNuIKGqdgyAO+IRY3crq0ilPvF4qPW+tM6y5mgw4bvuXeJmMs/zJTUrgLUrtv',
          CryptographyManagement.GenerateHashAsBase64String(InputStringTxt, GetKeyAsSecret(), KeyedHashAlgorithmType::HMACSHA384), WrongHashErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_TestSHA512HashGenerationBase64()
    var
        CryptographyManagement: Codeunit "Cryptography Management";
    begin
        // [FEATURE] [Hash]
        // [SCENARIO 228632] Generate Base64 hash using SHA512 algorithm

        // [WHEN] GenerateHash is invoked with input string
        // [THEN] Correct Base64 SHA512 hash is generated
        Assert.AreEqual(
          SHA512Base64Txt,
          CryptographyManagement.GenerateHashAsBase64String(InputStringTxt, HashAlgorithmType::SHA512), WrongHashErr);

        // [WHEN] GenerateHash is invoked with input string and key
        // [THEN] Correct Base64 HMACSHA512 hash is generated
        Assert.AreEqual(
          HMACSHA512Base64Txt,
          CryptographyManagement.GenerateHashAsBase64String(InputStringTxt, GetKeyAsSecret(), KeyedHashAlgorithmType::HMACSHA512), WrongHashErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_TestEmptyParametersHashGeneration()
    var
        KeySecretText: SecretText;
        XTxt: Text;
    begin
        // [FEATURE] [Hash]
        // [SCENARIO 228632] Test hash generation with empty input parameters

        // [WHEN] Input string is empty for hash with key generation function
        // [THEN] Result is empty string
        XTxt := 'X';
        KeySecretText := XTxt;
        Assert.AreEqual(
          '',
          CryptographyManagement.GenerateHash('', KeySecretText, KeyedHashAlgorithmType::HMACMD5), WrongHashErr);

        // [WHEN] Key is empty for hash with key generation function
        // [THEN] Result is empty string
        Clear(KeySecretText);
        Assert.AreEqual(
          '',
          CryptographyManagement.GenerateHash('X', KeySecretText, KeyedHashAlgorithmType::HMACMD5), WrongHashErr);

        // [WHEN] Both input parameters are empty for hash with key generation function
        // [THEN] Result is empty string
        Assert.AreEqual(
          '',
          CryptographyManagement.GenerateHash('', KeySecretText, KeyedHashAlgorithmType::HMACMD5), WrongHashErr);
    end;

    [Test]
    procedure GenerateEmptyStringHash()
    var
        MD5: Text;
        SHA1: Text;
        SHA256: Text;
        SHA384: Text;
        SHA512: Text;
    begin
        MD5 := CryptographyManagement.GenerateHash('', HashAlgorithmType::MD5);
        SHA1 := CryptographyManagement.GenerateHash('', HashAlgorithmType::SHA1);
        SHA256 := CryptographyManagement.GenerateHash('', HashAlgorithmType::SHA256);
        SHA384 := CryptographyManagement.GenerateHash('', HashAlgorithmType::SHA384);
        SHA512 := CryptographyManagement.GenerateHash('', HashAlgorithmType::SHA512);

        Assert.AreEqual('d41d8cd98f00b204e9800998ecf8427e', MD5.ToLower(), 'MD5 hashes do not match');
        Assert.AreEqual('da39a3ee5e6b4b0d3255bfef95601890afd80709', SHA1.ToLower(), 'SHA1 hashes do not match');
        Assert.AreEqual('e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', SHA256.ToLower(), 'SHA256 hashes do not match');
        Assert.AreEqual('38b060a751ac96384cd9327eb1b1e36a21fdb71114be07434c0cc7bf63f6e1da274edebfe76f65fbd51ad2f14898b95b', SHA384.ToLower(), 'SHA384 hashes do not match');
        Assert.AreEqual('cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e', SHA512.ToLower(), 'SHA512 hashes do not match');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Cleanup()
    begin
        if CryptographyManagement.IsEncryptionEnabled() then
            CryptographyManagement.DisableEncryption(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure HandleConfirm1(Message: Text[1024]; var Reply: Boolean)
    begin
        case true of
            StrPos(Message, 'Do you want to save the encryption key?') <> 0:
                Reply := false;
            StrPos(Message, 'Enabling encryption will generate an encryption key') <> 0:
                Reply := true;
            StrPos(Message, 'Disabling encryption will decrypt the encrypted data') <> 0:
                Reply := true;
            else
                Reply := false;
        end;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure HandleConfirmYes(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
        exit;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Msg: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HandlePasswordDlgOK(var StdPasswordDialog: TestPage "Password Dialog")
    begin
        StdPasswordDialog.Password.SetValue := 'Password101!';
        StdPasswordDialog.ConfirmPassword.SetValue := 'Password101!';
        StdPasswordDialog.OK().Invoke();
    end;

    local procedure GetKeyAsSecret(): SecretText
    var
        KTxt: Text;
    begin
        KTxt := KeyTxt;
        exit(KTxt);
    end;
}

