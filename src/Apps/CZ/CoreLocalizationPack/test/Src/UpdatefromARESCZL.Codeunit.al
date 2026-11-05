codeunit 148051 "Update from ARES CZL"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Core] [Registration No.] [ARES]
        isInitialized := false;
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        isInitialized: Boolean;

    local procedure Initialize();
    var
        RegistrationLogCZL: Record "Registration Log CZL";
        RegistrationLogDetailCZL: Record "Registration Log Detail CZL";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Update from ARES CZL");

        RegistrationLogCZL.Reset();
        RegistrationLogCZL.DeleteAll();
        RegistrationLogDetailCZL.Reset();
        RegistrationLogDetailCZL.DeleteAll();
        LibraryRandom.Init();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Update from ARES CZL");

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Update from ARES CZL");
    end;

    [Test]
    [HandlerFunctions('RegistrationLogDetailsModalPageHandler,MessageHandler')]
    procedure UpdateCustomerFromRegistrationLog()
    var
        Customer: Record Customer;
        RegistrationLogCZL: Record "Registration Log CZL";
    begin
        // [SCENARIO] Update Customer from Registration Log Entry
        Initialize();

        // [GIVEN] New Customer has been created
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Registration Log Entry has been created
        RegistrationLogCZL := CreateRegistrationLog(Enum::"Reg. Log Account Type CZL"::Customer, Customer."No.");
        Commit();

        // [GIVEN] Registration Log Details have been created
        RegistrationLogCZL.LogDetails();

        // [WHEN] Run Registration Log Details page and accept all fields
        RegistrationLogCZL.OpenModifyDetails();

        // [THEN] Customer will be updated
        Customer.Get(Customer."No.");
        Customer.Testfield(Name, CopyStr(RegistrationLogCZL."Verified Name", 1, MaxStrLen(Customer.Name)));
        Customer.Testfield(Address, CopyStr(RegistrationLogCZL."Verified Address", 1, MaxStrLen(Customer.Address)));
        Customer.Testfield(City, CopyStr(RegistrationLogCZL."Verified City", 1, MaxStrLen(Customer.City)));
        Customer.Testfield("Post Code", CopyStr(RegistrationLogCZL."Verified Post Code", 1, MaxStrLen(Customer."Post Code")));
        Customer.Testfield("VAT Registration No.", CopyStr(RegistrationLogCZL."Verified VAT Registration No.", 1, MaxStrLen(Customer."VAT Registration No.")));
    end;

    [Test]
    [HandlerFunctions('RegistrationLogDetailsModalPageHandler,MessageHandler')]
    procedure UpdateVendorFromRegistrationLog()
    var
        Vendor: Record Vendor;
        RegistrationLogCZL: Record "Registration Log CZL";
    begin
        // [SCENARIO] Update Vendor from Registration Log Entry
        Initialize();

        // [GIVEN] New Vendor created
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Registration Log Entry has been created
        RegistrationLogCZL := CreateRegistrationLog(Enum::"Reg. Log Account Type CZL"::Vendor, Vendor."No.");
        Commit();

        // [GIVEN] Registration Log Details have been created
        RegistrationLogCZL.LogDetails();

        // [WHEN] Run Registration Log Details page and accept all fields
        RegistrationLogCZL.OpenModifyDetails();

        // [THEN] Vendor will be updated
        Vendor.Get(Vendor."No.");
        Vendor.Testfield(Name, CopyStr(RegistrationLogCZL."Verified Name", 1, MaxStrLen(Vendor.Name)));
        Vendor.Testfield(Address, CopyStr(RegistrationLogCZL."Verified Address", 1, MaxStrLen(Vendor.Address)));
        Vendor.Testfield(City, CopyStr(RegistrationLogCZL."Verified City", 1, MaxStrLen(Vendor.City)));
        Vendor.Testfield("Post Code", CopyStr(RegistrationLogCZL."Verified Post Code", 1, MaxStrLen(Vendor."Post Code")));
        Vendor.Testfield("VAT Registration No.", CopyStr(RegistrationLogCZL."Verified VAT Registration No.", 1, MaxStrLen(Vendor."VAT Registration No.")));
    end;

    [Test]
    [HandlerFunctions('RegistrationLogDetailsModalPageHandler,MessageHandler')]
    procedure UpdateContactFromRegistrationLog()
    var
        Contact: Record Contact;
        RegistrationLogCZL: Record "Registration Log CZL";
    begin
        // [SCENARIO] Update Contact from Registration Log Entry
        Initialize();

        // [GIVEN] New contact created
        LibraryMarketing.CreateCompanyContact(Contact);

        // [GIVEN] Registration Log Entry has been created
        RegistrationLogCZL := CreateRegistrationLog(Enum::"Reg. Log Account Type CZL"::Contact, Contact."No.");
        Commit();

        // [GIVEN] Registration Log Details have been created
        RegistrationLogCZL.LogDetails();

        // [WHEN] Run Registration Log Details page and accept all fields
        RegistrationLogCZL.OpenModifyDetails();

        // [THEN] Contact will be updated
        Contact.Get(Contact."No.");
        Contact.Testfield(Name, CopyStr(RegistrationLogCZL."Verified Name", 1, MaxStrLen(Contact.Name)));
        Contact.Testfield(Address, CopyStr(RegistrationLogCZL."Verified Address", 1, MaxStrLen(Contact.Address)));
        Contact.Testfield(City, CopyStr(RegistrationLogCZL."Verified City", 1, MaxStrLen(Contact.City)));
        Contact.Testfield("Post Code", CopyStr(RegistrationLogCZL."Verified Post Code", 1, MaxStrLen(Contact."Post Code")));
        Contact.Testfield("VAT Registration No.", CopyStr(RegistrationLogCZL."Verified VAT Registration No.", 1, MaxStrLen(Contact."VAT Registration No.")));
    end;

    [Test]
    procedure LogVerificationAcceptsResponseEchoingRegistrationNo()
    var
        RegistrationLogCZL: Record "Registration Log CZL";
        RegistrationLogMgtCZL: Codeunit "Registration Log Mgt. CZL";
    begin
        // [SCENARIO] An ARES response that echoes the requested IČO is accepted
        Initialize();

        // [GIVEN] A registration log entry for the 8-digit IČO 00006947 (the only form ARES accepts)
        InitRegistrationLogForResponse(RegistrationLogCZL, '00006947');

        // [WHEN] ARES responds with the same IČO
        RegistrationLogMgtCZL.LogVerification(RegistrationLogCZL, CreateAresResponse('{"ico":"00006947","obchodniJmeno":"Test","sidlo":{"kodStatu":"CZ"}}'));

        // [THEN] The response is trusted and logged as valid
        RegistrationLogCZL.TestField(Status, RegistrationLogCZL.Status::Valid);
        RegistrationLogCZL.TestField("Verified Name", 'Test');
    end;

    [Test]
    procedure LogVerificationRejectsResponseForDifferentRegistrationNo()
    var
        RegistrationLogCZL: Record "Registration Log CZL";
        RegistrationLogMgtCZL: Codeunit "Registration Log Mgt. CZL";
    begin
        // [SCENARIO] An ARES response for a different company is rejected instead of being trusted
        Initialize();

        // [GIVEN] A registration log entry for IČO 12345678
        InitRegistrationLogForResponse(RegistrationLogCZL, '12345678');

        // [WHEN] ARES responds with the data of another IČO
        asserterror RegistrationLogMgtCZL.LogVerification(RegistrationLogCZL, CreateAresResponse('{"ico":"87654321","obchodniJmeno":"Other","sidlo":{"kodStatu":"CZ"}}'));

        // [THEN] The response is rejected and nothing is logged as valid
        Assert.ExpectedError('did not match the requested registration number');
        VerifyNoValidLogEntry(RegistrationLogCZL);
    end;

    [Test]
    procedure LogVerificationRejectsResponseWithoutLeadingZeros()
    var
        RegistrationLogCZL: Record "Registration Log CZL";
        RegistrationLogMgtCZL: Codeunit "Registration Log Mgt. CZL";
    begin
        // [SCENARIO] The IČO comparison is exact, so leading zeros are significant
        Initialize();

        // [GIVEN] A registration log entry for IČO 00006947
        InitRegistrationLogForResponse(RegistrationLogCZL, '00006947');

        // [WHEN] The response echoes the IČO without its leading zeros
        asserterror RegistrationLogMgtCZL.LogVerification(RegistrationLogCZL, CreateAresResponse('{"ico":"6947","obchodniJmeno":"Test","sidlo":{"kodStatu":"CZ"}}'));

        // [THEN] The response is rejected and nothing is logged as valid
        Assert.ExpectedError('did not match the requested registration number');
        VerifyNoValidLogEntry(RegistrationLogCZL);
    end;

    [Test]
    procedure LogVerificationRejectsResponseWithoutRegistrationNo()
    var
        RegistrationLogCZL: Record "Registration Log CZL";
        RegistrationLogMgtCZL: Codeunit "Registration Log Mgt. CZL";
    begin
        // [SCENARIO] An ARES response that does not echo the requested IČO is rejected
        Initialize();

        // [GIVEN] A registration log entry for IČO 12345678
        InitRegistrationLogForResponse(RegistrationLogCZL, '12345678');

        // [WHEN] ARES responds without the IČO
        asserterror RegistrationLogMgtCZL.LogVerification(RegistrationLogCZL, CreateAresResponse('{"obchodniJmeno":"Test","sidlo":{"kodStatu":"CZ"}}'));

        // [THEN] The response is rejected and nothing is logged as valid
        Assert.ExpectedError('did not contain the expected data');
        VerifyNoValidLogEntry(RegistrationLogCZL);
    end;

    [Test]
    procedure LogVerificationRejectsNonScalarRegistrationNo()
    var
        RegistrationLogCZL: Record "Registration Log CZL";
        RegistrationLogMgtCZL: Codeunit "Registration Log Mgt. CZL";
    begin
        // [SCENARIO] An ARES response whose IČO is not a scalar value is rejected
        Initialize();

        // [GIVEN] A registration log entry for IČO 12345678
        InitRegistrationLogForResponse(RegistrationLogCZL, '12345678');

        // [WHEN] ARES responds with the IČO wrapped in an object
        asserterror RegistrationLogMgtCZL.LogVerification(RegistrationLogCZL, CreateAresResponse('{"ico":{"value":"12345678"},"obchodniJmeno":"Test","sidlo":{"kodStatu":"CZ"}}'));

        // [THEN] The response is rejected and nothing is logged as valid
        Assert.ExpectedError('did not contain the expected data');
        VerifyNoValidLogEntry(RegistrationLogCZL);
    end;

    [Test]
    procedure LogVerificationRejectsNumericRegistrationNo()
    var
        RegistrationLogCZL: Record "Registration Log CZL";
        RegistrationLogMgtCZL: Codeunit "Registration Log Mgt. CZL";
    begin
        // [SCENARIO] An ARES response whose IČO is a JSON number instead of a string is rejected, even if the digits match
        Initialize();

        // [GIVEN] A registration log entry for IČO 12345678
        InitRegistrationLogForResponse(RegistrationLogCZL, '12345678');

        // [WHEN] ARES responds with the IČO as a number
        asserterror RegistrationLogMgtCZL.LogVerification(RegistrationLogCZL, CreateAresResponse('{"ico":12345678,"obchodniJmeno":"Test","sidlo":{"kodStatu":"CZ"}}'));

        // [THEN] The response is rejected and nothing is logged as valid
        Assert.ExpectedError('did not contain the expected data');
        VerifyNoValidLogEntry(RegistrationLogCZL);
    end;

    [Test]
    procedure LogVerificationRejectsResponseWithoutName()
    var
        RegistrationLogCZL: Record "Registration Log CZL";
        RegistrationLogMgtCZL: Codeunit "Registration Log Mgt. CZL";
    begin
        // [SCENARIO] An ARES response with a matching IČO but without the company name is rejected
        Initialize();

        // [GIVEN] A registration log entry for IČO 12345678
        InitRegistrationLogForResponse(RegistrationLogCZL, '12345678');

        // [WHEN] ARES responds with the matching IČO but no name
        asserterror RegistrationLogMgtCZL.LogVerification(RegistrationLogCZL, CreateAresResponse('{"ico":"12345678","sidlo":{"kodStatu":"CZ"}}'));

        // [THEN] The response is rejected and nothing is logged as valid
        Assert.ExpectedError('did not contain the expected data');
        VerifyNoValidLogEntry(RegistrationLogCZL);
    end;

    [Test]
    procedure LogVerificationRejectsResponseWithoutAddress()
    var
        RegistrationLogCZL: Record "Registration Log CZL";
        RegistrationLogMgtCZL: Codeunit "Registration Log Mgt. CZL";
    begin
        // [SCENARIO] An ARES response with a matching IČO but without the registered address is rejected
        Initialize();

        // [GIVEN] A registration log entry for IČO 12345678
        InitRegistrationLogForResponse(RegistrationLogCZL, '12345678');

        // [WHEN] ARES responds with the matching IČO and name but no address object
        asserterror RegistrationLogMgtCZL.LogVerification(RegistrationLogCZL, CreateAresResponse('{"ico":"12345678","obchodniJmeno":"Test"}'));

        // [THEN] The response is rejected and nothing is logged as valid
        Assert.ExpectedError('did not contain the expected data');
        VerifyNoValidLogEntry(RegistrationLogCZL);
    end;

    [Test]
    procedure ResponseSizeRejectsOversizedPayload()
    var
        RegLookupExtDataCZL: Codeunit "Reg. Lookup Ext. Data CZL";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [SCENARIO] An ARES response larger than the maximum allowed size is rejected before it is parsed
        Initialize();

        // [GIVEN] A response body of 70,000 bytes, above the 64 KB cap
        WriteResponseToTempBlob(TempBlob, PadStr('', 70000, 'A'));

        // [WHEN] The size check runs
        asserterror RegLookupExtDataCZL.CheckResponseSize(TempBlob);

        // [THEN] The response is rejected
        Assert.ExpectedError('exceeded the maximum allowed size');
    end;

    [Test]
    procedure ResponseSizeRejectsMultibyteOversizedPayload()
    var
        RegLookupExtDataCZL: Codeunit "Reg. Lookup Ext. Data CZL";
        TempBlob: Codeunit "Temp Blob";
        MultibyteChar: Char;
    begin
        // [SCENARIO] The size limit counts bytes, so a multibyte response under the limit in characters is still rejected
        Initialize();

        // [GIVEN] A response body of 40,000 two-byte UTF-8 characters (U+0158, Ř): under 64 KB in characters, 80,000 bytes in size
        MultibyteChar := 344;
        WriteResponseToTempBlob(TempBlob, PadStr('', 40000, Format(MultibyteChar)));

        // [WHEN] The size check runs
        asserterror RegLookupExtDataCZL.CheckResponseSize(TempBlob);

        // [THEN] The response is rejected
        Assert.ExpectedError('exceeded the maximum allowed size');
    end;

    [Test]
    procedure ResponseSizeAcceptsWithinLimit()
    var
        RegLookupExtDataCZL: Codeunit "Reg. Lookup Ext. Data CZL";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [SCENARIO] An ARES response within the maximum allowed size passes the size check
        Initialize();

        // [GIVEN] A response body of a realistic size
        WriteResponseToTempBlob(TempBlob, PadStr('', 6000, 'A'));

        // [WHEN] The size check runs
        // [THEN] No error is raised
        RegLookupExtDataCZL.CheckResponseSize(TempBlob);
    end;

    local procedure WriteResponseToTempBlob(var TempBlob: Codeunit "Temp Blob"; ResponseText: Text)
    var
        OutStream: OutStream;
    begin
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(ResponseText);
    end;

    local procedure InitRegistrationLogForResponse(var RegistrationLogCZL: Record "Registration Log CZL"; RegistrationNo: Text[20])
    begin
        // The account does not exist, so no field details are logged - only the response verification is exercised
        RegistrationLogCZL.InitRegLog(RegistrationLogCZL, Enum::"Reg. Log Account Type CZL"::Customer, CopyStr(LibraryRandom.RandText(20), 1, 20), RegistrationNo);
    end;

    local procedure CreateAresResponse(ResponseText: Text) ResponseObject: JsonObject
    begin
        ResponseObject.ReadFrom(ResponseText);
    end;

    local procedure VerifyNoValidLogEntry(RequestedRegistrationLogCZL: Record "Registration Log CZL")
    var
        RegistrationLogCZL: Record "Registration Log CZL";
    begin
        // Scope to the account of this test: asserterror rolls back to the last commit, which restores the Valid entries
        // that other tests in this codeunit commit, so a table-wide check would not reflect this test's outcome.
        RegistrationLogCZL.SetRange("Account Type", RequestedRegistrationLogCZL."Account Type");
        RegistrationLogCZL.SetRange("Account No.", RequestedRegistrationLogCZL."Account No.");
        RegistrationLogCZL.SetRange(Status, RegistrationLogCZL.Status::Valid);
        Assert.RecordIsEmpty(RegistrationLogCZL);
    end;

    local procedure CreateRegistrationLog(AccountType: Enum "Reg. Log Account Type CZL"; AccountNo: Code[20]) RegistrationLogCZL: Record "Registration Log CZL"
    begin
        RegistrationLogCZL.Init();
        RegistrationLogCZL."Entry No." := LibraryRandom.RandInt(1000);
        RegistrationLogCZL."Registration No." := '12345678';
        RegistrationLogCZL."Account Type" := AccountType;
        RegistrationLogCZL."Account No." := AccountNo;
        RegistrationLogCZL.Status := RegistrationLogCZL.Status::Valid;
        RegistrationLogCZL."Verified Name" := CopyStr(LibraryRandom.RandText(150), 1, MaxStrLen(RegistrationLogCZL."Verified Name"));
        RegistrationLogCZL."Verified Address" := CopyStr(LibraryRandom.RandText(150), 1, MaxStrLen(RegistrationLogCZL."Verified Address"));
        RegistrationLogCZL."Verified City" := CopyStr(LibraryRandom.RandText(150), 1, MaxStrLen(RegistrationLogCZL."Verified City"));
        RegistrationLogCZL."Verified Post Code" := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(RegistrationLogCZL."Verified Post Code"));
        RegistrationLogCZL."Verified VAT Registration No." := 'CZ12345678';
        RegistrationLogCZL.Insert();
    end;

    [ModalPageHandler]
    procedure RegistrationLogDetailsModalPageHandler(var RegistrationLogDetailsCZL: TestPage "Registration Log Details CZL")
    begin
        RegistrationLogDetailsCZL.AcceptAll.Invoke();
    end;

    [MessageHandler]
    procedure MessageHandler(Msg: Text[1024])
    begin
    end;
}
