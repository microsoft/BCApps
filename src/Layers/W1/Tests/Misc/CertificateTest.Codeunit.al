codeunit 134666 "Certificate Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    Permissions = TableData "No. Series Tenant" = rimd;

    trigger OnRun()
    begin
        // [FEATURE] [Certificate]
    end;

    var
        TestCertTxt: Label 'MIIFMQIBAzCCBPcGCSqGSIb3DQEHAaCCBOgEggTkMIIE4DCCAv8GCSqGSIb3DQEHBqCCAvAwggLsAgEAMIIC5QYJKoZIhvcNAQcBMBwGCiqGSIb3DQEMAQYwDgQInoKB6qoKZIQCAggAgIICuF9ZKEqoyo2dKPmAYqXL+Cf35+SDMgXxhRc89HKDXQ4va5umT+wBsy51FRxRahSiKksHmqRSLfZwTKEcQvSaOTyJdT0pL4uV5WNajrneiqw8JbdJYK57YLqol+92doBECbPMxQwZUuC2oZo3cyWJJBi3ehIqEOeSfYVBcDDCQrGy+ggmKfcYeDwjS9XDCnBO9xgl462J2w02tm/KW1rC1926xyVvmzspTdL0QFSc6t810oZ/f9L4/F04mRdvlbuR7RU09jHFSzLm5D2ybtXJd/B9YhwwGNQkfp/dPxq17Z7b4usEjXJWO7TwJtduOGXadznQJIVihWZBYBsqVI3mABh5FVZWrwdPGhfVOaeDhvAiqpKLA2+aewFuT7unaKSsjoOGHFvHF4RiiTCR/ag+2sHQPqpSUQJdlQjmiZ1F8tbpzuhJdBLY/i5Iqs13sk3zPrwP1oqwv9Xp3gd6hjktHNWyTrI/0LZct9REvJznOeLnKct0EhWuDuY4L24ZRjrMgBqNCgkm4hcUfhiOAlbYaMMVFWbUzA+6dEgwcltIp1gSZbhj8aB8MP/1fT8VjyhJsSE4p6wsqsgTpd27zsenJcLgyu7COjSstmkQ3qeIwNS/x9zuEinxzA7t3II1kROJz0nTqtQi4IgcBjb/2DiD2QwCLD4NvbbR7hWjDrUTOgtmgxrhn3qfsemDe2bQw3/ZJkKZrJO9fJzkhwXQWv7aj+4Nf1wxYIOcxKp30lB3zcKrTlBkNsmZDnVNEU7UwN8qAWkMyvWdyZaBW1TgbVer1D+YSGxXMqPesm7IJ+HBYJBUuC6xyXmOJ8QScNcIWHUDFUpb2Hg2Vw64y7nyPgxdb3C9zquM2TPAKUKEQylOGwTtzgd+73wVvoqLZbo0DXe9ZXrT/GRlac1mFP0lbF1GoAYOGgSbJoWF8jCCAdkGCSqGSIb3DQEHAaCCAcoEggHGMIIBwjCCAb4GCyqGSIb3DQEMCgECoIIBhjCCAYIwHAYKKoZIhvcNAQwBAzAOBAhJN3StWPRixwICCAAEggFg42+YWXJTaw52YnkoBFZMN5zWdMa6HlsJHV4FYbaCKE8NKTuxKibLWU/f0qgOJwo9fxy503Xz22wnEL7xRU2B9JblrlGrHlix0mswt/QU4rjhfzpYIv6kfOIHE8zKacQYdy2zDUXax54gX+Dj8m2dE22l+gCRZHqkYymV1nMdWJsqFRAiV2EsSwGLLZovYqp0/fVUxry7bYUCnu+yj9wkYr53LZ9O4EFUePDoJXMvGasPeB7876xDnVWdzQA6jZne0syZ8tH6q7/0wckPn0SvFfhphYqHFKlCc0FDCk/Nsxjod0A1PZz8HMueHJO1Jo3oODYMktI+HVCAC9UUqcmrW4jBBczEzKtCPyDgZkiP6xYU5AHUcBomHO94KHE5X5mZdgXblTRM1zc0uJS2CrBx4jc59s28S/bWABKduqNcczEnBuLyUsYKxX5/WkTmqSPdaJkU2xrfA/PcOTUodzYJVTElMCMGCSqGSIb3DQEJFTEWBBTxYMwv+lUDqlEPcjZoIfCnM5GzbzAxMCEwCQYFKw4DAhoFAAQU+06w2rleuz30pmANAqG7IHZX8q0ECF8gd+t0FeE8AgIIAA==';
        TestCertPasswordTxt: Label 'test1234';
        Assert: Codeunit Assert;
        CertCodeTxt: Label 'CERT';
        TestCertThumbprintTxt: Label 'F160CC2FFA5503AA510F72366821F0A73391B36F';
        ExpiryDateErr: Label 'Incorrect expiry date for the stored cert.';
        ThumbprintErr: Label 'Incorrect thumbprint for the stored cert.';
        HasPrivateKeyErr: Label 'Can not find the testCert private key.';
        StoredCertErr: Label 'Stored string should match the one that is saved in Isolated storage.';
        CertDoesntExistInISErr: Label 'Cert does not exist in Isolated storage.';
        PasswordDoesntExistInISErr: Label 'Cert pasword does not exist in Isolated storage.';
        CertNotCleanedUpErr: Label 'Cert must be cleaned up from isolated storage once its deleted.';
        CertPasswordNotCleanedUpErr: Label 'Cert password must be cleaned up from isolated storage once its deleted.';
        NoSeriesNotFoundErr: Label 'Certificate No.Series was not inserted correctly.';
        InsertedCertCodeErr: Label 'Inserted certificate code is not correct.';
        CertCompanyNameErr: Label 'Company Name is not set correctly.';
        CertCompanyNameEmptyErr: Label 'Company name should be empty.';
        CertUserIDEmptyErr: Label 'User ID should be empty.';
        CertUserIDErr: Label 'User ID is not set correctly.';
        CertListPageReadOnlyErr: Label 'Certificate page should be read only.';
        AssignUserScopeErr: Label 'This certificate is available to everyone in the company, so you cannot assign it to a specific user. To do that, you can add a new certificate with a different option chosen in the Available To field.';

    [Test]
    [Scope('OnPrem')]
    procedure VerifyCertificate()
    var
        IsolatedCertificate: Record "Isolated Certificate";
        CertificateManagement: Codeunit "Certificate Management";
        AssertExpiryDate: DateTime;
    begin
        // [SCENARIO] Use pre-defined testCert and verify the certificate
        // [GIVEN] Pre-defined testCert
        // [WHEN] Reading & Verifying the cert
        InsertCertificateWithTestBlob(IsolatedCertificate, CertificateManagement);

        // [THEN] Cert values must match the actual cert values
        AssertExpiryDate := CreateDateTime(20200610D, 031600T);
        Assert.AreEqual(Format(AssertExpiryDate), Format(IsolatedCertificate."Expiry Date"), ExpiryDateErr);
        Assert.AreEqual(TestCertThumbprintTxt, IsolatedCertificate.ThumbPrint, ThumbprintErr);
        Assert.IsTrue(IsolatedCertificate."Has Private Key", HasPrivateKeyErr);

        // [WHEN] TestSaving Cert and Password to IS
        IsolatedCertificate.Insert(true);
        CertificateManagement.SaveCertToIsolatedStorage(IsolatedCertificate);
        CertificateManagement.SavePasswordToIsolatedStorage(IsolatedCertificate);

        // [THEN] Cert base64 string stored in Isolated storagemust equal to the predefined cert string.
        Assert.AreEqual(CertificateManagement.GetCertAsBase64String(IsolatedCertificate), TestCertTxt, StoredCertErr);
    end;

    [Scope('OnPrem')]
    procedure InsertCertificateScenarios()
    var
        IsolatedCertificate: Record "Isolated Certificate";
        CertificateManagement: Codeunit "Certificate Management";
        CertDataScope: DataScope;
    begin
        // [SCENARIO] Insert and delete certificate should store/delete cert and password in Isolated storage.
        InsertCertificateWithTestBlob(IsolatedCertificate, CertificateManagement);

        CertDataScope := CertificateManagement.GetCertDataScope(IsolatedCertificate);

        // [THEN] Values must be set in Isolated Storage.
        Assert.IsTrue(ISOLATEDSTORAGE.Contains(IsolatedCertificate.Code, CertDataScope), CertDoesntExistInISErr);
        Assert.IsTrue(ISOLATEDSTORAGE.Contains(IsolatedCertificate.Code + 'Password', CertDataScope), PasswordDoesntExistInISErr);

        // [WHEN] Deleting the certificate.
        IsolatedCertificate.Delete(true);

        // [THEN] Value must be cleared from Isolated Storage.
        Assert.IsFalse(ISOLATEDSTORAGE.Contains(IsolatedCertificate.Code, CertDataScope), CertNotCleanedUpErr);
        Assert.IsFalse(ISOLATEDSTORAGE.Contains(IsolatedCertificate.Code + 'Password', CertDataScope), CertPasswordNotCleanedUpErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewCertWithEmptyNoSeries()
    var
        NoSeriesTenant: Record "No. Series Tenant";
        IsolatedCertificate: Record "Isolated Certificate";
    begin
        // [SCENARIO] When adding a new certificate while No.Series tenant is empty, it should be initialized.
        // [WHEN] Cert and No. Series tenant are empty.
        IsolatedCertificate.DeleteAll(true);
        NoSeriesTenant.DeleteAll();

        // [Then] Adding new cert should create No. Series record.
        InsertCertificate(IsolatedCertificate);

        Assert.IsTrue(NoSeriesTenant.Get(CertCodeTxt), NoSeriesNotFoundErr);
        Assert.AreEqual(IsolatedCertificate.Code, Format(NoSeriesTenant.Code + NoSeriesTenant."Last Used number"), InsertedCertCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertScopeManagement()
    var
        IsolatedCertificate: Record "Isolated Certificate";
    begin
        // [SCENARIO] Insert and delete certificate should store/delete cert and password in Isolated storage.
        // [WHEN] Inserting a certificate with scope Company
        InsertCertificateWithScope(IsolatedCertificate, IsolatedCertificate.Scope::Company);

        // [Then] Company Name should equal current company name,, and user should be empty.
        Assert.AreEqual(IsolatedCertificate."Company ID", CompanyName, CertCompanyNameErr);
        Assert.AreEqual(IsolatedCertificate."User ID", '', CertUserIDEmptyErr);

        // [WHEN] Inserting a certificate with scope CompanyAndUser.
        InsertCertificateWithScope(IsolatedCertificate, IsolatedCertificate.Scope::CompanyAndUser);

        // [Then] Company Name should equal current company name, and user should equal current userID.
        Assert.AreEqual(CompanyName, IsolatedCertificate."Company ID", CertCompanyNameErr);
        Assert.AreEqual(Format(UserSecurityId()), IsolatedCertificate."User ID", CertUserIDErr);

        // [WHEN] Inserting a certificate with scope User.
        InsertCertificateWithScope(IsolatedCertificate, IsolatedCertificate.Scope::User);

        // [Then] Company Name should be empty, and user should equal current userID.
        Assert.AreEqual('', IsolatedCertificate."Company ID", CertCompanyNameEmptyErr);
        Assert.AreEqual(Format(UserSecurityId()), IsolatedCertificate."User ID", CertUserIDErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertificatesPageIsReadOnly()
    var
        CertificateList: TestPage "Certificate List";
    begin
        // [WHEN] Open Certificate list page
        CertificateList.OpenView();
        // [THEN] Page should not be editable
        Assert.IsFalse(CertificateList.Editable(), CertListPageReadOnlyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChangeUserFunctionality()
    var
        IsolatedCertificate: Record "Isolated Certificate";
    begin
        // [SCENARIO] Insert a certificate then try to change the assigned user, this should only work with user, companyAndUser Scope
        // [WHEN] Inserting a certificate with scope Company
        InsertCertificateWithScope(IsolatedCertificate, IsolatedCertificate.Scope::Company);
        asserterror ChangeUserForCertificate(IsolatedCertificate);
        Assert.ExpectedError(AssignUserScopeErr);

        // [WHEN] Inserting a certificate with scope User with empty user ID
        InsertCertificateWithScope(IsolatedCertificate, IsolatedCertificate.Scope::User);
        asserterror ChangeUserForCertificate(IsolatedCertificate);
    end;

    local procedure InsertCertificateWithScope(var IsolatedCertificate: Record "Isolated Certificate"; CertScope: Option ,Company,User,CompanyAndUser)
    begin
        InsertCertificate(IsolatedCertificate);
        IsolatedCertificate.Validate(Scope, CertScope);
        SetScope(IsolatedCertificate);
    end;

    local procedure InsertCertificateWithTestBlob(var IsolatedCertificate: Record "Isolated Certificate"; var CertificateManagement: Codeunit "Certificate Management")
    var
        Cert: Text;
        CertPass: Text;
    begin
        InsertCertificate(IsolatedCertificate);

        // Add saved test Password
        CertPass := TestCertPasswordTxt;
        CertificateManagement.SetCertPassword(CertPass);
        Cert := TestCertTxt;
        CertificateManagement.VerifyCertFromString(IsolatedCertificate, Cert);

        // Save to Isolated storage
        CertificateManagement.SaveCertToIsolatedStorage(IsolatedCertificate);
        CertificateManagement.SavePasswordToIsolatedStorage(IsolatedCertificate);
    end;

    local procedure InsertCertificate(var IsolatedCertificate: Record "Isolated Certificate")
    begin
        IsolatedCertificate.Init();
        IsolatedCertificate.Insert(true);
    end;

    local procedure ChangeUserForCertificate(IsolatedCertificate: Record "Isolated Certificate")
    var
        CertificateList: TestPage "Certificate List";
        ChangeUser: TestPage "Change User";
    begin
        // Open Certificate list page
        CertificateList.OpenView();
        CertificateList.GotoRecord(IsolatedCertificate);
        CertificateList."Change User".Invoke();

        ChangeUser.Trap();
        CertificateList."Change User".Invoke();
        ChangeUser."User ID".Value('');
        ChangeUser.OK().Invoke();
    end;

    local procedure SetScope(var IsolatedCertificate: Record "Isolated Certificate")
    begin
        case IsolatedCertificate.Scope of
            IsolatedCertificate.Scope::Company:
                IsolatedCertificate.Validate("Company ID", CompanyName);
            IsolatedCertificate.Scope::User:
                IsolatedCertificate."User ID" := Format(UserSecurityId());
            IsolatedCertificate.Scope::CompanyAndUser:
                begin
                    IsolatedCertificate.Validate("Company ID", CompanyName);
                    IsolatedCertificate."User ID" := Format(UserSecurityId());
                end;
        end;
        IsolatedCertificate.Modify();
    end;
}

