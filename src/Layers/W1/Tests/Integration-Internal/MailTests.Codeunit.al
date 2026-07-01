codeunit 139013 "Mail Tests"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [INT] [Mail]
        Initialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        ActiveDirectoryMockEvents: Codeunit "Active Directory Mock Events";
        Initialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateEmailTest()
    var
        CommunicationMethod: Record "Communication Method";
        Mail: Codeunit Mail;
        EMail: Text[80];
        Success: Boolean;
    begin
        LibraryLowerPermissions.SetO365Setup();
        Initialize();

        EMail := 'none@home.local';
        if not CommunicationMethod.Get() then begin
            CommunicationMethod.Init();
            CommunicationMethod."E-Mail" := EMail;
            CommunicationMethod.Insert();
        end else
            EMail := CommunicationMethod."E-Mail";

        Success := Mail.ValidateEmail(CommunicationMethod, EMail);
        Assert.IsTrue(Success, 'Invalid email');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateEmailFailTest()
    var
        CommunicationMethod: Record "Communication Method";
        Mail: Codeunit Mail;
        EMail: Text[80];
        Success: Boolean;
    begin
        LibraryLowerPermissions.SetO365Setup();
        Initialize();

        EMail := 'none@home.fail.local';
        CommunicationMethod.SetRange("E-Mail", CopyStr(CommunicationMethod."E-Mail", 1, MaxStrLen(CommunicationMethod."E-Mail")));
        if not CommunicationMethod.IsEmpty() then
            CommunicationMethod.DeleteAll();

        Success := Mail.ValidateEmail(CommunicationMethod, EMail);
        Assert.IsFalse(Success, 'E-mail is valid');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CollectAddressesTest()
    var
        CommunicationMethod: Record "Communication Method";
        Contact: Record Contact;
        Mail: Codeunit Mail;
    begin
        LibraryLowerPermissions.SetO365Setup();
        Initialize();

        if not Contact.FindFirst() then
            Assert.Fail('One or more contacts are required to run this test');

        Mail.CollectAddresses(Contact."No.", CommunicationMethod, false);
        Assert.IsTrue(CommunicationMethod.Count > 0, 'Expected to find at least one address');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CollectAddressesWithNoContactTest()
    var
        CommunicationMethod: Record "Communication Method";
        Contact: Record Contact;
        Mail: Codeunit Mail;
    begin
        LibraryLowerPermissions.SetO365Setup();
        Initialize();

        if Contact.Get('CTWRONG01') then
            Assert.Fail('Unexpected contact found');

        Mail.CollectAddresses('CTWRONG01', CommunicationMethod, false);
        Assert.IsTrue(CommunicationMethod.Count = 0, 'Expected not to find addresses');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CollectAddressesWithAlternativeAddressTest()
    var
        CommunicationMethod: Record "Communication Method";
        Contact: Record Contact;
        ContactAltAddress: Record "Contact Alt. Address";
        ContactAltAddrDateRange: Record "Contact Alt. Addr. Date Range";
        Mail: Codeunit Mail;
    begin
        LibraryLowerPermissions.SetO365Setup();
        Initialize();

        if not Contact.FindFirst() then
            CreateDefaultContact();

        ContactAltAddress.SetRange("Contact No.", Contact."No.");
        if not ContactAltAddress.IsEmpty() then
            ContactAltAddress.DeleteAll();

        ContactAltAddress.Reset();
        ContactAltAddress.Init();
        ContactAltAddress.Code := 'ACODE1';
        ContactAltAddress."Contact No." := Contact."No.";
        ContactAltAddress."E-Mail" := 'someothertemporaryemail@domain.local';
        ContactAltAddress.Insert();

        ContactAltAddrDateRange.SetRange("Contact No.", Contact."No.");
        if not ContactAltAddrDateRange.IsEmpty() then
            ContactAltAddrDateRange.DeleteAll();

        ContactAltAddrDateRange.Reset();
        ContactAltAddrDateRange.Init();
        ContactAltAddrDateRange."Contact No." := Contact."No.";
        ContactAltAddrDateRange."Starting Date" := CalcDate('<-3D>', Today);
        ContactAltAddrDateRange."Contact Alt. Address Code" := 'ACODE1';
        ContactAltAddrDateRange."Ending Date" := Today;
        ContactAltAddrDateRange.Insert();

        Mail.CollectAddresses(Contact."No.", CommunicationMethod, false);
        Assert.IsTrue(CommunicationMethod.Count > 1, 'Expected to find at least two address');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CollectAddressesWithCompanyTest()
    var
        CommunicationMethod: Record "Communication Method";
        Contact: Record Contact;
        Mail: Codeunit Mail;
        FirstAddress: Text;
    begin
        LibraryLowerPermissions.SetO365Setup();
        Initialize();

        Contact.SetRange(Type, Contact.Type::Person);
        Contact.SetFilter("Company No.", '<>""');
        if not Contact.FindFirst() then
            CreateDefaultContact();

        // Ensure contact has different address from company
        Contact."E-Mail" := 'thisisaspecialemail@somewherespecial.local';
        Contact.Modify();

        Mail.CollectAddresses(Contact."No.", CommunicationMethod, false);
        Assert.IsTrue(CommunicationMethod.Count > 1, 'Expected to find more than 1 items');

        CommunicationMethod.Find('-');
        FirstAddress := CommunicationMethod."E-Mail";
        while CommunicationMethod.Next() <> 0 do
            if CommunicationMethod."E-Mail" <> FirstAddress then
                exit; // Success

        Assert.Fail('Expected find more than one email address');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CollectUserEmailAddressesRemovesDublicatesTest()
    var
        User: Record User;
        UserSetup: Record "User Setup";
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        Mail: Codeunit Mail;
        OriginalCount: Integer;
    begin
        LibraryLowerPermissions.SetOutsideO365Scope();
        UserSetup.SetRange("User ID", UserId);
        if UserSetup.FindFirst() then begin
            UserSetup."E-Mail" := '';
            UserSetup.Modify();
        end;

        User.SetRange("User Name", UserId);
        if not User.FindFirst() then begin
            User.Init();
            User."User Security ID" := CreateGuid();
            User."User Name" := UserId;
            User.Insert();
        end;
        User."Authentication Email" := '';
        User.Modify();

        Mail.CollectCurrentUserEmailAddresses(TempNameValueBuffer);
        OriginalCount := TempNameValueBuffer.Count();

        if not UserSetup.FindFirst() then begin
            UserSetup.Init();
            UserSetup."User ID" := UserId;
            UserSetup.Insert();
        end;
        UserSetup."E-Mail" := Format(LibraryRandom.RandInt(1000)) + 'test1@mail.internal';
        UserSetup.Modify();
        TempNameValueBuffer.DeleteAll();
        Mail.CollectCurrentUserEmailAddresses(TempNameValueBuffer);
        Assert.AreEqual(OriginalCount + 1, TempNameValueBuffer.Count, 'Expected 1 email addresses to be added');

        User."Authentication Email" := UserSetup."E-Mail";
        User.Modify();
        TempNameValueBuffer.DeleteAll();
        Mail.CollectCurrentUserEmailAddresses(TempNameValueBuffer);
        Assert.AreEqual(OriginalCount + 1, TempNameValueBuffer.Count, 'Expected no email addresses to be added');

        User."Authentication Email" := Format(LibraryRandom.RandInt(1000)) + 'test1-1@mail.internal';
        User.Modify();
        TempNameValueBuffer.DeleteAll();
        Mail.CollectCurrentUserEmailAddresses(TempNameValueBuffer);
        Assert.AreEqual(OriginalCount + 2, TempNameValueBuffer.Count, 'Expected 1 email addresses to be added');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CollectUserEmailAddressesUserSetupEmailTest()
    var
        UserSetup: Record "User Setup";
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        Mail: Codeunit Mail;
        OriginalCount: Integer;
    begin
        LibraryLowerPermissions.SetO365Setup();
        UserSetup.SetRange("User ID", UserId);
        if UserSetup.FindFirst() then begin
            UserSetup."E-Mail" := '';
            UserSetup.Modify();
        end;

        Mail.CollectCurrentUserEmailAddresses(TempNameValueBuffer);
        OriginalCount := TempNameValueBuffer.Count();

        if not UserSetup.FindFirst() then begin
            UserSetup.Init();
            UserSetup."User ID" := UserId;
            UserSetup.Insert();
        end;
        UserSetup."E-Mail" := Format(LibraryRandom.RandInt(1000)) + 'test2@mail.internal';
        UserSetup.Modify();

        TempNameValueBuffer.DeleteAll();
        Mail.CollectCurrentUserEmailAddresses(TempNameValueBuffer);
        Assert.AreEqual(OriginalCount + 1, TempNameValueBuffer.Count, 'Expected 1 email addresses to be added');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CollectUserEmailAddressesUserAuthenticationEmailTest()
    var
        User: Record User;
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        Mail: Codeunit Mail;
        OriginalCount: Integer;
    begin
        LibraryLowerPermissions.SetOutsideO365Scope();
        User.SetRange("User Name", UserId);
        if not User.FindFirst() then begin
            User.Init();
            User."User Security ID" := CreateGuid();
            User."User Name" := UserId;
            User.Insert();
        end;
        User."Authentication Email" := '';
        User.Modify();

        Mail.CollectCurrentUserEmailAddresses(TempNameValueBuffer);
        OriginalCount := TempNameValueBuffer.Count();

        // Test smtp mail setup address with @
        User."Authentication Email" := Format(LibraryRandom.RandInt(1000)) + 'test3@mail.internal';
        User.Modify();

        TempNameValueBuffer.DeleteAll();
        Mail.CollectCurrentUserEmailAddresses(TempNameValueBuffer);
        Assert.AreEqual(OriginalCount + 1, TempNameValueBuffer.Count, 'Expected 1 email addresses to be added');
    end;

    local procedure CreateDefaultContact()
    var
        Contact: Record Contact;
    begin
        Contact.Init();
        Contact."No." := 'CNTC001';
        Contact.Type := Contact.Type::Company;
        Contact.Name := 'Default contact company name';
        Contact.Address := 'Default Contact Address 1';
        Contact."E-Mail" := 'defaultcompany@email.invaliddomain';
        Contact."Search E-Mail" := 'defaultcompany@email.invaliddomain';
        Contact.Insert();

        Contact.Init();
        Contact."No." := 'CNTP001';
        Contact.Type := Contact.Type::Person;
        Contact."Company No." := 'CNTC001';
        Contact.Name := 'Default contact name';
        Contact.Address := 'Default Contact Address 1';
        Contact."E-Mail" := 'default@email.invaliddomain';
        Contact."Search E-Mail" := 'default@email.invaliddomain';
        Contact.Insert();
    end;

    local procedure Initialize()
    begin
        BindActiveDirectoryMockEvents();
        if Initialized then
            exit;
        Initialized := true;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DisableEncryption()
    var
        CryptographyManagement: Codeunit "Cryptography Management";
    begin
        // a teardown as the encryption should be disabled in the end
        LibraryLowerPermissions.SetO365Setup();
        if CryptographyManagement.IsEncryptionEnabled() then
            CryptographyManagement.DisableEncryption(true);
    end;

    local procedure BindActiveDirectoryMockEvents()
    begin
        if ActiveDirectoryMockEvents.Enabled() then
            exit;
        BindSubscription(ActiveDirectoryMockEvents);
        ActiveDirectoryMockEvents.Enable();
    end;
}

