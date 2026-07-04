// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 139596 "Company Metadata Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        Name2SentinelTxt: Label 'SENTINEL-NAME2', Locked = true;

    [Test]
    procedure PopulatesCompanyInformationValues()
    var
        CompanyInformation: Record "Company Information";
        ReportManagement: Codeunit ReportManagement;
        CompanyMetadata: JsonObject;
    begin
        Initialize();

        // [SCENARIO] GetCompanyMetadata writes Company Information values under the frozen wire keys.
        // [GIVEN] Company Information populated with known values.
        SetCompanyInformation(CompanyInformation);

        // [WHEN] The shared company metadata is built.
        ReportManagement.GetCompanyMetadata(CompanyMetadata);

        // [THEN] Each scalar value carries the Company Information value under its frozen key.
        Assert.AreEqual(CompanyInformation.Name, GetValue(CompanyMetadata, 'CompanyName'), 'CompanyName');
        Assert.AreEqual(CompanyInformation."Phone No.", GetValue(CompanyMetadata, 'CompanyPhone'), 'CompanyPhone');
        Assert.AreEqual(CompanyInformation."Fax No.", GetValue(CompanyMetadata, 'CompanyFaxNo'), 'CompanyFaxNo');
        Assert.AreEqual(CompanyInformation."E-Mail", GetValue(CompanyMetadata, 'CompanyEmail'), 'CompanyEmail');
        Assert.AreEqual(CompanyInformation."Home Page", GetValue(CompanyMetadata, 'CompanyHomePage'), 'CompanyHomePage');
        Assert.AreEqual(CompanyInformation."VAT Registration No.", GetValue(CompanyMetadata, 'CompanyVATRegistrationNo'), 'CompanyVATRegistrationNo');
        Assert.AreEqual(CompanyInformation."Registration No.", GetValue(CompanyMetadata, 'CompanyRegistrationNo'), 'CompanyRegistrationNo');
        Assert.AreEqual(CompanyInformation."Bank Name", GetValue(CompanyMetadata, 'CompanyBankName'), 'CompanyBankName');
        Assert.AreEqual(CompanyInformation."Bank Account No.", GetValue(CompanyMetadata, 'CompanyBankAccountNo'), 'CompanyBankAccountNo');
        Assert.AreEqual(CompanyInformation."Bank Branch No.", GetValue(CompanyMetadata, 'CompanyBankBranchNo'), 'CompanyBankBranchNo');
        Assert.AreEqual(CompanyInformation.IBAN, GetValue(CompanyMetadata, 'CompanyIBAN'), 'CompanyIBAN');
        Assert.AreEqual(CompanyInformation."SWIFT Code", GetValue(CompanyMetadata, 'CompanyBankSWIFT'), 'CompanyBankSWIFT');
        Assert.AreEqual(CompanyInformation."Giro No.", GetValue(CompanyMetadata, 'CompanyGiroNo'), 'CompanyGiroNo');
    end;

    [Test]
    procedure CaptionsMatchFieldCaptions()
    var
        CompanyInformation: Record "Company Information";
        ReportManagement: Codeunit ReportManagement;
        CompanyMetadata: JsonObject;
    begin
        Initialize();

        // [SCENARIO] Each labeled value carries a paired caption sourced from the Company Information
        // field caption (so a layout swap keeps localized labels).
        SetCompanyInformation(CompanyInformation);

        ReportManagement.GetCompanyMetadata(CompanyMetadata);

        Assert.AreEqual(CompanyInformation.FieldCaption("Phone No."), GetValue(CompanyMetadata, 'CompanyPhoneCaption'), 'CompanyPhoneCaption');
        Assert.AreEqual(CompanyInformation.FieldCaption("Fax No."), GetValue(CompanyMetadata, 'CompanyFaxNoCaption'), 'CompanyFaxNoCaption');
        Assert.AreEqual(CompanyInformation.FieldCaption("VAT Registration No."), GetValue(CompanyMetadata, 'CompanyVATRegistrationNoCaption'), 'CompanyVATRegistrationNoCaption');
        Assert.AreEqual(CompanyInformation.FieldCaption(IBAN), GetValue(CompanyMetadata, 'CompanyIBANCaption'), 'CompanyIBANCaption');
        Assert.AreEqual(CompanyInformation.FieldCaption("Giro No."), GetValue(CompanyMetadata, 'CompanyGiroNoCaption'), 'CompanyGiroNoCaption');
    end;

    [Test]
    procedure DisplayNameFromCompanyRecordNotName2()
    var
        CompanyInformation: Record "Company Information";
        ReportManagement: Codeunit ReportManagement;
        CompanyMetadata: JsonObject;
        ExpectedDisplayName: Text;
    begin
        Initialize();

        // [SCENARIO] CompanyDisplayName mirrors ReportRequest: the tenant Company record's display
        // name (CompanyProperty.DisplayName(), fallback to CompanyName()), NOT Company Information."Name 2".
        // [GIVEN] Company Information."Name 2" set to a distinct sentinel.
        CompanyInformation.Get();
        CompanyInformation."Name 2" := Name2SentinelTxt;
        CompanyInformation.Modify();

        // [WHEN] The shared company metadata is built.
        ReportManagement.GetCompanyMetadata(CompanyMetadata);

        // [THEN] DisplayName equals the Company record display name (with company-name fallback)...
        ExpectedDisplayName := CompanyProperty.DisplayName();
        if ExpectedDisplayName = '' then
            ExpectedDisplayName := CompanyName();
        Assert.AreEqual(ExpectedDisplayName, GetValue(CompanyMetadata, 'CompanyDisplayName'), 'CompanyDisplayName should come from the Company record.');

        // [THEN] ...and is never the Company Information "Name 2" sentinel.
        Assert.AreNotEqual(Name2SentinelTxt, GetValue(CompanyMetadata, 'CompanyDisplayName'), 'CompanyDisplayName must not be sourced from "Name 2".');
    end;

    [Test]
    procedure EmptyCompanyInformationEmitsEmptyValues()
    var
        CompanyInformation: Record "Company Information";
        ReportManagement: Codeunit ReportManagement;
        CompanyMetadata: JsonObject;
    begin
        Initialize();

        // [SCENARIO] Empty-safe: blank Company Information fields are emitted as present-but-empty keys
        // rather than erroring or omitting the keys.
        ClearCompanyInformation(CompanyInformation);

        ReportManagement.GetCompanyMetadata(CompanyMetadata);

        Assert.IsTrue(CompanyMetadata.Contains('CompanyBankSWIFT'), 'Key should be present even when empty.');
        Assert.AreEqual('', GetValue(CompanyMetadata, 'CompanyBankSWIFT'), 'Empty field should emit an empty value.');
        Assert.AreEqual('', GetValue(CompanyMetadata, 'CompanyIBAN'), 'Empty field should emit an empty value.');
    end;

    [Test]
    procedure MissingCompanyInformationEmitsEmptyValues()
    var
        CompanyInformation: Record "Company Information";
        ReportManagement: Codeunit ReportManagement;
        CompanyMetadata: JsonObject;
    begin
        Initialize();

        // [SCENARIO] Empty-safe: with no Company Information record at all (the CompanyInfo.Init()
        // path), the fields - including the logo - are emitted as blank values rather than erroring.
        // [GIVEN] No Company Information record.
        CompanyInformation.Get();
        CompanyInformation.Delete();

        // [WHEN] The shared company metadata is built.
        ReportManagement.GetCompanyMetadata(CompanyMetadata);

        // Reinsert the record before asserting: Library - Setup Storage restores via Modify(),
        // which requires the row to exist even when an assertion below fails the test.
        CompanyInformation.Init();
        CompanyInformation.Insert();

        // [THEN] Keys are present and blank, including CompanyLogo (BLOB path must not error).
        Assert.AreEqual('', GetValue(CompanyMetadata, 'CompanyName'), 'CompanyName should be blank without Company Information.');
        Assert.AreEqual('', GetValue(CompanyMetadata, 'CompanyLogo'), 'CompanyLogo should be blank without Company Information.');
        Assert.AreEqual('', GetValue(CompanyMetadata, 'CompanyIBAN'), 'CompanyIBAN should be blank without Company Information.');
    end;

    [Test]
    procedure AddressIsArrayAndSkipsEmptyLines()
    var
        CompanyInformation: Record "Company Information";
        ReportManagement: Codeunit ReportManagement;
        CompanyMetadata: JsonObject;
        AddressToken: JsonToken;
        LineToken: JsonToken;
        AddressLines: JsonArray;
        Index: Integer;
    begin
        Initialize();

        // [SCENARIO] CompanyAddressLines is a JSON array (repeater) with no empty entries.
        SetCompanyInformation(CompanyInformation);

        ReportManagement.GetCompanyMetadata(CompanyMetadata);

        Assert.IsTrue(CompanyMetadata.Get('CompanyAddressLines', AddressToken), 'CompanyAddressLines key should exist.');
        Assert.IsTrue(AddressToken.IsArray(), 'CompanyAddressLines should be a JSON array.');
        AddressLines := AddressToken.AsArray();
        Assert.IsTrue(AddressLines.Count() > 0, 'Address should have at least one line.');
        for Index := 0 to AddressLines.Count() - 1 do begin
            AddressLines.Get(Index, LineToken);
            Assert.AreNotEqual('', LineToken.AsValue().AsText(), 'Address array should not contain empty lines.');
        end;
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Company Metadata Test");

        // Lazy setup: restore Company Information to the baseline captured on first run so each
        // test starts from a known state and its edits don't leak into the next test.
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Company Metadata Test");
        IsInitialized := true;
        Commit();
        LibrarySetupStorage.Save(Database::"Company Information");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Company Metadata Test");
    end;

    local procedure SetCompanyInformation(var CompanyInformation: Record "Company Information")
    begin
        // Direct assignment (not Validate) to avoid country-specific format validations on VAT/IBAN.
        CompanyInformation.Get();
        CompanyInformation.Name := 'CML Test Company';
        CompanyInformation.Address := '5 The Ring';
        CompanyInformation.City := 'London';
        CompanyInformation."Post Code" := 'W2 8HG';
        CompanyInformation."Phone No." := '111-222-333';
        CompanyInformation."Fax No." := '111-222-334';
        CompanyInformation."E-Mail" := 'test@contoso.com';
        CompanyInformation."Home Page" := 'https://contoso.com';
        CompanyInformation."VAT Registration No." := 'GB123456789';
        CompanyInformation."Registration No." := 'REG-001';
        CompanyInformation."Bank Name" := 'Test Bank';
        CompanyInformation."Bank Account No." := '12-34-567';
        CompanyInformation."Bank Branch No." := 'BR-99';
        CompanyInformation.IBAN := 'GB12TEST08929965044991';
        CompanyInformation."SWIFT Code" := 'TESTGB2L';
        CompanyInformation."Giro No." := '888-9999';
        CompanyInformation.Modify();
    end;

    local procedure ClearCompanyInformation(var CompanyInformation: Record "Company Information")
    begin
        CompanyInformation.Get();
        CompanyInformation."Phone No." := '';
        CompanyInformation."Fax No." := '';
        CompanyInformation."E-Mail" := '';
        CompanyInformation."Home Page" := '';
        CompanyInformation."VAT Registration No." := '';
        CompanyInformation."Registration No." := '';
        CompanyInformation."Bank Name" := '';
        CompanyInformation."Bank Account No." := '';
        CompanyInformation."Bank Branch No." := '';
        CompanyInformation.IBAN := '';
        CompanyInformation."SWIFT Code" := '';
        CompanyInformation."Giro No." := '';
        CompanyInformation.Modify();
    end;

    local procedure GetValue(CompanyMetadata: JsonObject; KeyName: Text): Text
    var
        ValueToken: JsonToken;
    begin
        if not CompanyMetadata.Get(KeyName, ValueToken) then
            Assert.Fail(StrSubstNo('CompanyMetadata is missing key %1.', KeyName));
        exit(ValueToken.AsValue().AsText());
    end;
}
