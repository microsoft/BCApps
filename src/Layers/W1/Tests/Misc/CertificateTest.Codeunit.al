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
        Assert: Codeunit Assert;
        TestCertBase64: Text;
        TestCertThumbprint: Text;
        TestCertPassword: SecretText;
        TestCertExpiryDate: DateTime;
        TestCertSubjectTxt: Label 'CN=Certificate Test', Locked = true;
        SelfSignedCertNotCreatedErr: Label 'The self-signed test certificate was not created.';
        PasswordProtectedCertNotCreatedErr: Label 'The password-protected test certificate was not created.';
        CertCodeTxt: Label 'CERT';
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
    begin
        // [SCENARIO] Use a runtime-generated, password-protected test certificate and verify the certificate
        // [GIVEN] Runtime-generated testCert
        // [WHEN] Reading & Verifying the cert
        InsertCertificateWithTestBlob(IsolatedCertificate, CertificateManagement);

        // [THEN] Cert values must match the actual cert values
        Assert.AreEqual(Format(TestCertExpiryDate), Format(IsolatedCertificate."Expiry Date"), ExpiryDateErr);
        Assert.AreEqual(TestCertThumbprint, IsolatedCertificate.ThumbPrint, ThumbprintErr);
        Assert.IsTrue(IsolatedCertificate."Has Private Key", HasPrivateKeyErr);

        // [WHEN] TestSaving Cert and Password to IS
        IsolatedCertificate.Insert(true);
        CertificateManagement.SaveCertToIsolatedStorage(IsolatedCertificate);
        CertificateManagement.SavePasswordToIsolatedStorage(IsolatedCertificate);

        // [THEN] Cert base64 string stored in Isolated storage must equal to the generated cert string.
        Assert.AreEqual(CertificateManagement.GetCertAsBase64String(IsolatedCertificate), TestCertBase64, StoredCertErr);
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
    begin
        InsertCertificate(IsolatedCertificate);

        CreatePasswordProtectedTestCertificate();
        CertificateManagement.SetCertPassword(TestCertPassword);
        CertificateManagement.VerifyCertFromString(IsolatedCertificate, TestCertBase64);

        // Save to Isolated storage
        CertificateManagement.SaveCertToIsolatedStorage(IsolatedCertificate);
        CertificateManagement.SavePasswordToIsolatedStorage(IsolatedCertificate);
    end;

    local procedure CreatePasswordProtectedTestCertificate()
    var
        CertificateRequest: Codeunit CertificateRequest;
        X509Certificate2: Codeunit X509Certificate2;
        PrivateKeyXmlString: SecretText;
        PublicCertBase64: Text;
    begin
        TestCertPassword := Format(CreateGuid());
        TestCertExpiryDate := CreateDateTime(Today() + 365, 000000T);

        CertificateRequest.InitializeRSA(2048, true, PrivateKeyXmlString);
        CertificateRequest.InitializeCertificateRequestUsingRSA(TestCertSubjectTxt, Enum::"Hash Algorithm"::SHA256, Enum::"RSA Signature Padding"::Pkcs1);
        CertificateRequest.CreateSelfSigned(CreateDateTime(Today(), 000000T), TestCertExpiryDate, Enum::"X509 Content Type"::Cert, PublicCertBase64);
        Assert.AreNotEqual('', PublicCertBase64, SelfSignedCertNotCreatedErr);

        TestCertBase64 := X509Certificate2.CreateFromPemAndExportAsBase64(PublicCertBase64, PrivateKeyXmlString, TestCertPassword);
        Assert.AreNotEqual('', TestCertBase64, PasswordProtectedCertNotCreatedErr);

        X509Certificate2.GetCertificateThumbprint(TestCertBase64, TestCertPassword, TestCertThumbprint);
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

