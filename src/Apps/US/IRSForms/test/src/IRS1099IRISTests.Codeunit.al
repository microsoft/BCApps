// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Foundation.Company;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using System.Privacy;
using System.Test.Library;
using System.TestLibraries.Azure.KeyVault;
using System.TestLibraries.Environment;
using System.TestLibraries.Utilities;
using System.Text;
using System.Utilities;

codeunit 148022 "IRS 1099 IRIS Tests"
{
    Subtype = Test;
    TestHttpRequestPolicy = BlockOutboundRequests;
    TestType = IntegrationTest;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    var
        SandboxTransmission: Record "Transmission IRIS";
        SandboxOtherTransmission: Record "Transmission IRIS";
        SandboxDocHeader: Record "IRS 1099 Form Doc. Header";
        SandboxAbandonedDocHeader: Record "IRS 1099 Form Doc. Header";
        SandboxOtherDocHeader: Record "IRS 1099 Form Doc. Header";
        SandboxDraftDocHeader: Record "IRS 1099 Form Doc. Header";
        Assert: Codeunit Assert;
        LibraryIRSReportingPeriod: Codeunit "Library IRS Reporting Period";
        LibraryIRS1099FormBox: Codeunit "Library IRS 1099 Form Box";
        LibraryIRS1099Document: Codeunit "Library IRS 1099 Document";
        LibraryIRS1099IRIS: Codeunit "Library - IRS 1099 IRIS";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        OfflineResponses: Codeunit "Library - Variable Storage";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryFileMgtHandler: Codeunit "Library - File Mgt Handler";
        AzureKeyVaultTestLibrary: Codeunit "Azure Key Vault Test Library";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        MockAzureKeyVaultSecretProvider: DotNet MockAzureKeyVaultSecretProvider;
        IsInitialized: Boolean;
        XmlDetailPathTok: Label '//n1:Form1099%1Detail/', Locked = true;
        XmlTotalPathTok: Label '//n1:Form1099%1TotalAmtGrp/', Locked = true;
        UnknownSupplementalErr: Label 'Document %1: Supplemental box CUSTOM', Locked = true;
        LegacySupplementalErr: Label 'Document %1 contains supplemental lines', Locked = true;
        NoRecordedCorrectionTxt: Label 'has no recorded IRIS submission to correct', Locked = true;
        PreviousFilingDetailsTxt: Label 'is missing previous IRS filing details required for a correction', Locked = true;
        OfflineRequestPaths: List of [Text];
        OfflineTokenProbeCount: Integer;
        OfflineExpectedRequestKinds: Text;
        OfflineObservedRequestKinds: Text;
        OfflinePrivacyConsentSaved: Boolean;
        OfflineOriginalPrivacyConsent: Boolean;
        OfflineSubmissionStatuses: Dictionary of [Text, Text];
        OfflineReceiptID: Text[100];
        OfflineUTID: Text[100];
        OfflineStatus: Text;
        OfflinePayload: Text;
        OfflineResponse: Text;
        OfflineAcknowledgment: Text;
        OfflinePreReceiptError: Boolean;
        OfflineRecordError: Boolean;
        OfflineSubmitHttpStatus: Integer;
        OfflineStatusHttpStatus: Integer;
        OfflineTransmissionID: Integer;
        SandboxHistoryID: Integer;
        SandboxErrorID: Integer;
        SandboxFailHistoryID: Integer;
        SandboxSharedSnapshot: Dictionary of [Text, BigInteger];
        SandboxContentsSnapshot: Dictionary of [Text, BigInteger];
        SandboxAllSnapshot: Dictionary of [Text, BigInteger];
        SandboxOnlyErr: Label 'only be removed with this action in a sandbox', Locked = true;
        SandboxChangedErr: Label 'associated documents or history changed', Locked = true;
        SandboxFailureErr: Label 'Simulated sandbox history deletion failure.', Locked = true;
        TestPageClosedErr: Label 'The TestPage is not open.', Locked = true;
        SandboxConflictTxt: Label 'Document %1 belongs to another transmission or reporting year', Comment = '%1 = document ID', Locked = true;
        SandboxConfirmationIdentityTxt: Label 'transmission %1 for tax year %2', Comment = '%1 = transmission ID, %2 = tax year', Locked = true;
        SandboxRecordRemainsTxt: Label 'Record %1 must remain.', Comment = '%1 = record key', Locked = true;
        SandboxRecordUnchangedTxt: Label 'Record %1 must not change.', Comment = '%1 = record key', Locked = true;
        SandboxResetDocumentsTxt: Label 'reset 2 documents, keeping their contents', Locked = true;
        SandboxDeleteDocumentsTxt: Label 'delete 2 documents and their contents', Locked = true;

    [Test]
    procedure ContactPersonInfoGrpNotAddedWhenContactPersonIsEmpty()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        TempIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header" temporary;
        TempBlob: Codeunit "Temp Blob";
        UniqueTransmissionId: Text[100];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 619239] ContactPersonInformationGrp is not added to XML when Contact Person is empty but Phone No. and E-Mail are filled
        Initialize();

        // [GIVEN] Company Information with empty Contact Person but filled Phone No. and E-Mail
        UpdateCompanyContactInfo('', '1234567890', 'test@example.com');

        // [GIVEN] A vendor "V" with 1099 form document ready for transmission
        CreateTransmissionWithSingleFormDoc(Transmission, IRS1099FormDocHeader);

        // [WHEN] Create transmission XML
        LibraryIRS1099IRIS.CreateTransmissionXmlContent(Transmission, Enum::"Transmission Type IRIS"::"O", false, UniqueTransmissionId, TempIRS1099FormDocHeader, TempBlob);

        // [THEN] ContactPersonInformationGrp is not present in the XML
        InitXMLReader(TempBlob);
        LibraryXPathXMLReader.VerifyXmlNodeAbsence('//n1:ContactPersonInformationGrp');
    end;

    [Test]
    procedure ContactPersonInfoGrpAddedWhenContactPersonIsFilled()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        TempIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header" temporary;
        TempBlob: Codeunit "Temp Blob";
        UniqueTransmissionId: Text[100];
        ContactName: Text[50];
        PhoneNo: Text[30];
        Email: Text[80];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 619239] ContactPersonInformationGrp is added to XML when Contact Person is filled
        Initialize();

        // [GIVEN] Company Information with filled Contact Person, Phone No. and E-Mail
        ContactName := LibraryUtility.GenerateGUID();
        PhoneNo := LibraryUtility.GenerateRandomPhoneNo();
        Email := LibraryUtility.GenerateRandomEmail();
        UpdateCompanyContactInfo(ContactName, PhoneNo, Email);

        // [GIVEN] A vendor "V" with 1099 form document ready for transmission
        CreateTransmissionWithSingleFormDoc(Transmission, IRS1099FormDocHeader);

        // [WHEN] Create transmission XML
        LibraryIRS1099IRIS.CreateTransmissionXmlContent(Transmission, Enum::"Transmission Type IRIS"::"O", false, UniqueTransmissionId, TempIRS1099FormDocHeader, TempBlob);

        // [THEN] ContactPersonInformationGrp is present in the XML with ContactPersonNm
        InitXMLReader(TempBlob);
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:ContactPersonInformationGrp/n1:ContactPersonNm', ContactName);
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:ContactPersonInformationGrp/n1:ContactPhoneNum', DelChr(PhoneNo, '=', ' -+()'));
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:ContactPersonInformationGrp/n1:ContactEmailAddressTxt', Email);
    end;

    [Test]
    procedure StateCodeWithLeadingAndTrailingSpacesIsTrimmed()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        TempIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header" temporary;
        TempBlob: Codeunit "Temp Blob";
        UniqueTransmissionId: Text[100];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 619973] State code with leading and trailing spaces is trimmed in the XML
        Initialize();

        // [GIVEN] A vendor "V" with 1099 form document ready for transmission
        CreateTransmissionWithSingleFormDoc(Transmission, IRS1099FormDocHeader);

        // [GIVEN] Vendor's County (State) = " CA " (with leading and trailing spaces)
        UpdateVendorProvinceOrState(IRS1099FormDocHeader."Vendor No.", ' CA ');

        // [WHEN] Create transmission XML
        LibraryIRS1099IRIS.CreateTransmissionXmlContent(Transmission, Enum::"Transmission Type IRIS"::"O", false, UniqueTransmissionId, TempIRS1099FormDocHeader, TempBlob);

        // [THEN] StateAbbreviationCd is "CA" without spaces
        InitXMLReader(TempBlob);
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:RecipientDetail/n1:MailingAddressGrp/n1:USAddress/n1:StateAbbreviationCd', 'CA');
    end;

    [Test]
    [HandlerFunctions('ErrorMessagesPageHandler')]
    procedure NonExistingStateCodeCausesValidationError()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        IRSFormsFacade: Codeunit "IRS Forms Facade";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 619973] Non-existing state code causes validation error when checking data to report
        Initialize();

        // [GIVEN] A vendor "V" with 1099 form document ready for transmission
        CreateTransmissionWithSingleFormDoc(Transmission, IRS1099FormDocHeader);

        // [GIVEN] Vendor's County (State) = "A1" (invalid state code)
        UpdateVendorProvinceOrState(IRS1099FormDocHeader."Vendor No.", 'A1');

        // [WHEN] Check data to report
        asserterror IRSFormsFacade.CheckDataToReport(Transmission);

        // [THEN] Error is thrown for invalid state code
        Assert.ExpectedMessage('State must be a valid 2-letter US state code', LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ErrorMessagesPageHandler')]
    procedure EmptyStateCodeCausesValidationError()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        IRSFormsFacade: Codeunit "IRS Forms Facade";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 632904] Empty state code causes validation error when checking data to report
        Initialize();

        // [GIVEN] A vendor "V" with 1099 form document ready for transmission
        CreateTransmissionWithSingleFormDoc(Transmission, IRS1099FormDocHeader);

        // [GIVEN] Vendor's County (State) is empty
        UpdateVendorProvinceOrState(IRS1099FormDocHeader."Vendor No.", '');

        // [WHEN] Check data to report
        asserterror IRSFormsFacade.CheckDataToReport(Transmission);

        // [THEN] Error is thrown for empty state code
        Assert.ExpectedMessage('State must be a valid 2-letter US state code', LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MultipleErrorMessagesPageHandler')]
    procedure TwoDuplicateTINGroupsInSameSubmission()
    var
        Vendor: array[5] of Record Vendor;
        IRS1099FormDocHeader: array[5] of Record "IRS 1099 Form Doc. Header";
        Transmission: Record "Transmission IRIS";
        IRSFormsFacade: Codeunit "IRS Forms Facade";
        PeriodNo: Code[20];
        TINGroup1: Text[30];
        TINGroup2: Text[30];
        i: Integer;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 621343] Two groups of vendors with duplicate TINs in same submission cause two error messages
        Initialize();
        PeriodNo := Format(Date2DMY(WorkDate(), 3));

        // [GIVEN] 3 vendors "V1", "V2", "V3" share TIN "A" without bank accounts
        TINGroup1 := LibraryIRS1099IRIS.GetUniqueTIN();
        for i := 1 to 3 do begin
            LibraryIRS1099IRIS.CreateUSVendor(Vendor[i]);
            UpdateVendorFederalId(Vendor[i]."No.", TINGroup1);
        end;

        // [GIVEN] 2 vendors "V4", "V5" share TIN "B" without bank accounts
        TINGroup2 := LibraryIRS1099IRIS.GetUniqueTIN();
        for i := 4 to 5 do begin
            LibraryIRS1099IRIS.CreateUSVendor(Vendor[i]);
            UpdateVendorFederalId(Vendor[i]."No.", TINGroup2);
        end;

        // [GIVEN] Form documents for all vendors with form NEC
        for i := 1 to 5 do
            CreateReleasedFormDocForVendor(IRS1099FormDocHeader[i], Vendor[i]."No.", 'NEC', 'NEC-01');

        // [GIVEN] Transmission created that picks up released form documents
        LibraryIRS1099IRIS.CreateTransmission(Transmission, PeriodNo);

        // [WHEN] Check data to report
        asserterror IRSFormsFacade.CheckDataToReport(Transmission);

        // [THEN] Two error messages are shown for duplicate TINs (one for each group)
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedMessage('vendors have the same TIN', LibraryVariableStorage.DequeueText());
        Assert.ExpectedMessage('vendors have the same TIN', LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MultipleErrorMessagesPageHandler')]
    procedure DuplicateTINsWithSameBankAccountNo()
    var
        Vendor: array[2] of Record Vendor;
        IRS1099FormDocHeader: array[2] of Record "IRS 1099 Form Doc. Header";
        Transmission: Record "Transmission IRIS";
        IRSFormsFacade: Codeunit "IRS Forms Facade";
        PeriodNo: Code[20];
        SharedTIN: Text[30];
        SharedBankAccountNo: Code[30];
        i: Integer;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 621343] Two vendors with the same TIN and same Bank Account No. cause validation error
        Initialize();
        PeriodNo := Format(Date2DMY(WorkDate(), 3));
        SharedTIN := LibraryIRS1099IRIS.GetUniqueTIN();
        SharedBankAccountNo := 'SHARED-BANK-123';

        // [GIVEN] 2 vendors "V1", "V2" share the same TIN with same bank account number
        LibraryIRS1099IRIS.CreateUSVendorWithBankAccount(Vendor[1], SharedBankAccountNo);
        UpdateVendorFederalId(Vendor[1]."No.", SharedTIN);
        LibraryIRS1099IRIS.CreateUSVendorWithBankAccount(Vendor[2], SharedBankAccountNo);
        UpdateVendorFederalId(Vendor[2]."No.", SharedTIN);

        // [GIVEN] Form documents for both vendors
        for i := 1 to 2 do
            CreateReleasedFormDocForVendor(IRS1099FormDocHeader[i], Vendor[i]."No.", 'NEC', 'NEC-01');

        // [GIVEN] Transmission created that picks up released form documents
        LibraryIRS1099IRIS.CreateTransmission(Transmission, PeriodNo);

        // [WHEN] Check data to report
        asserterror IRSFormsFacade.CheckDataToReport(Transmission);

        // [THEN] Error message is shown for duplicate TINs with same bank account
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedMessage('2 vendors have the same TIN', LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MultipleErrorMessagesPageHandler')]
    procedure DuplicateTINsOneVendorHasBankAccountOneDoesNot()
    var
        Vendor: array[2] of Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        IRS1099FormDocHeader: array[2] of Record "IRS 1099 Form Doc. Header";
        Transmission: Record "Transmission IRIS";
        IRSFormsFacade: Codeunit "IRS Forms Facade";
        PeriodNo: Code[20];
        SharedTIN: Text[30];
        i: Integer;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 621343] Two vendors with the same TIN where only one has a bank account cause validation error
        Initialize();
        PeriodNo := Format(Date2DMY(WorkDate(), 3));
        SharedTIN := LibraryIRS1099IRIS.GetUniqueTIN();

        // [GIVEN] 2 vendors "V1", "V2" share the same TIN
        for i := 1 to 2 do begin
            LibraryIRS1099IRIS.CreateUSVendor(Vendor[i]);
            UpdateVendorFederalId(Vendor[i]."No.", SharedTIN);
        end;

        // [GIVEN] Only vendor "V1" has a bank account
        LibraryIRS1099IRIS.CreateVendorBankAccount(VendorBankAccount, Vendor[1]."No.", 'BANK-ACCOUNT-1');

        // [GIVEN] Form documents for both vendors
        for i := 1 to 2 do
            CreateReleasedFormDocForVendor(IRS1099FormDocHeader[i], Vendor[i]."No.", 'NEC', 'NEC-01');

        // [GIVEN] Transmission created that picks up released form documents
        LibraryIRS1099IRIS.CreateTransmission(Transmission, PeriodNo);

        // [WHEN] Check data to report
        asserterror IRSFormsFacade.CheckDataToReport(Transmission);

        // [THEN] Error message is shown because "V2" has empty bank account
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedMessage('2 vendors have the same TIN', LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure DuplicateTINsWithUniqueBankAccountNos()
    var
        Vendor: array[2] of Record Vendor;
        IRS1099FormDocHeader: array[2] of Record "IRS 1099 Form Doc. Header";
        Transmission: Record "Transmission IRIS";
        IRSFormsFacade: Codeunit "IRS Forms Facade";
        PeriodNo: Code[20];
        SharedTIN: Text[30];
        i: Integer;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 621343] Two vendors with the same TIN but unique bank account numbers do not cause error
        Initialize();
        PeriodNo := Format(Date2DMY(WorkDate(), 3));
        SharedTIN := LibraryIRS1099IRIS.GetUniqueTIN();

        // [GIVEN] 2 vendors "V1", "V2" share the same TIN with unique bank account numbers
        LibraryIRS1099IRIS.CreateUSVendorWithBankAccount(Vendor[1], 'UNIQUE-BANK-001');
        UpdateVendorFederalId(Vendor[1]."No.", SharedTIN);
        LibraryIRS1099IRIS.CreateUSVendorWithBankAccount(Vendor[2], 'UNIQUE-BANK-002');
        UpdateVendorFederalId(Vendor[2]."No.", SharedTIN);

        // [GIVEN] Form documents for both vendors
        for i := 1 to 2 do
            CreateReleasedFormDocForVendor(IRS1099FormDocHeader[i], Vendor[i]."No.", 'NEC', 'NEC-01');

        // [GIVEN] Transmission created that picks up released form documents
        LibraryIRS1099IRIS.CreateTransmission(Transmission, PeriodNo);

        // [WHEN] Check data to report
        IRSFormsFacade.CheckDataToReport(Transmission);

        // [THEN] No error is raised because bank account numbers are unique
    end;

    [Test]
    procedure DuplicateTINsAcrossDifferentSubmissions()
    var
        Vendor: array[2] of Record Vendor;
        IRS1099FormDocHeader: array[2] of Record "IRS 1099 Form Doc. Header";
        Transmission: Record "Transmission IRIS";
        IRSFormsFacade: Codeunit "IRS Forms Facade";
        PeriodNo: Code[20];
        SharedTIN: Text[30];
        i: Integer;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 621343] Vendors with the same TIN but different form types do not cause error
        Initialize();
        PeriodNo := Format(Date2DMY(WorkDate(), 3));
        SharedTIN := LibraryIRS1099IRIS.GetUniqueTIN();

        // [GIVEN] 2 vendors "V1", "V2" share the same TIN without bank accounts
        for i := 1 to 2 do begin
            LibraryIRS1099IRIS.CreateUSVendor(Vendor[i]);
            UpdateVendorFederalId(Vendor[i]."No.", SharedTIN);
        end;

        // [GIVEN] Vendor "V1" has form doc for NEC, vendor "V2" has form doc for MISC (different submissions)
        CreateReleasedFormDocForVendor(IRS1099FormDocHeader[1], Vendor[1]."No.", 'NEC', 'NEC-01');
        CreateReleasedFormDocForVendor(IRS1099FormDocHeader[2], Vendor[2]."No.", 'MISC', 'MISC-03');

        // [GIVEN] Transmission created that picks up released form documents
        LibraryIRS1099IRIS.CreateTransmission(Transmission, PeriodNo);

        // [WHEN] Check data to report
        IRSFormsFacade.CheckDataToReport(Transmission);

        // [THEN] No error is raised because vendors are in different submissions (form types)
    end;

    [Test]
    procedure NoDuplicateTINsNoError()
    var
        Vendor: array[3] of Record Vendor;
        IRS1099FormDocHeader: array[3] of Record "IRS 1099 Form Doc. Header";
        Transmission: Record "Transmission IRIS";
        IRSFormsFacade: Codeunit "IRS Forms Facade";
        PeriodNo: Code[20];
        i: Integer;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 621343] Multiple vendors with unique TINs do not cause error
        Initialize();
        PeriodNo := Format(Date2DMY(WorkDate(), 3));

        // [GIVEN] 3 vendors "V1", "V2", "V3" with unique TINs
        LibraryIRS1099IRIS.CreateUSVendor(Vendor[1]);
        UpdateVendorFederalId(Vendor[1]."No.", LibraryIRS1099IRIS.GetUniqueTIN());
        LibraryIRS1099IRIS.CreateUSVendor(Vendor[2]);
        UpdateVendorFederalId(Vendor[2]."No.", LibraryIRS1099IRIS.GetUniqueTIN());
        LibraryIRS1099IRIS.CreateUSVendor(Vendor[3]);
        UpdateVendorFederalId(Vendor[3]."No.", LibraryIRS1099IRIS.GetUniqueTIN());

        // [GIVEN] Form documents for all vendors
        for i := 1 to 3 do
            CreateReleasedFormDocForVendor(IRS1099FormDocHeader[i], Vendor[i]."No.", 'NEC', 'NEC-01');

        // [GIVEN] Transmission created that picks up released form documents
        LibraryIRS1099IRIS.CreateTransmission(Transmission, PeriodNo);

        // [WHEN] Check data to report
        IRSFormsFacade.CheckDataToReport(Transmission);

        // [THEN] No error is raised because all TINs are unique
    end;

    [Test]
    [HandlerFunctions('ErrorMessagesPageHandler')]
    procedure EmptyContactPersonCausesValidationError()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        IRSFormsFacade: Codeunit "IRS Forms Facade";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 621425] Empty Contact Person in Company Information causes validation error
        Initialize();

        // [GIVEN] Vendor "V" with 1099 form document ready for transmission
        CreateTransmissionWithSingleFormDoc(Transmission, IRS1099FormDocHeader);

        // [GIVEN] Company Information with empty Contact Person
        UpdateCompanyContactInfo('', '1234567890', 'test@example.com');

        // [WHEN] Check data to report
        asserterror IRSFormsFacade.CheckDataToReport(Transmission);

        // [THEN] Error is thrown for empty Contact Person
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedMessage('Contact Person must be between 1 and 35 characters', LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure ContactPersonWithMaxLengthPasses()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        IRSFormsFacade: Codeunit "IRS Forms Facade";
        ContactPerson35Chars: Text[50];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 621425] Contact Person with exactly 35 characters passes validation
        Initialize();

        // [GIVEN] Vendor "V" with 1099 form document ready for transmission
        CreateTransmissionWithSingleFormDoc(Transmission, IRS1099FormDocHeader);

        // [GIVEN] Company Information with Contact Person of exactly 35 characters
        ContactPerson35Chars := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(35, 0), 1, 50);
        UpdateCompanyContactInfo(ContactPerson35Chars, '1234567890', 'test@example.com');

        // [WHEN] Check data to report
        IRSFormsFacade.CheckDataToReport(Transmission);

        // [THEN] No error is raised for Contact Person
    end;

    [Test]
    [HandlerFunctions('ErrorMessagesPageHandler')]
    procedure ContactPersonExceedingMaxLengthCausesError()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        IRSFormsFacade: Codeunit "IRS Forms Facade";
        ContactPersonTooLong: Text[50];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 621425] Contact Person exceeding 35 characters after formatting causes validation error
        Initialize();

        // [GIVEN] Vendor "V" with 1099 form document ready for transmission
        CreateTransmissionWithSingleFormDoc(Transmission, IRS1099FormDocHeader);

        // [GIVEN] Company Information with Contact Person exceeding 35 characters
        ContactPersonTooLong := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(36, 0), 1, 50);
        UpdateCompanyContactInfo(ContactPersonTooLong, '1234567890', 'test@example.com');

        // [WHEN] Check data to report
        asserterror IRSFormsFacade.CheckDataToReport(Transmission);

        // [THEN] Error is thrown for Contact Person exceeding max length
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedMessage('Contact Person must be between 1 and 35 characters', LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ErrorMessagesPageHandler')]
    procedure EmptyPhoneNoCausesValidationError()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        IRSFormsFacade: Codeunit "IRS Forms Facade";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 621425] Empty Phone No. in Company Information causes validation error
        Initialize();

        // [GIVEN] Vendor "V" with 1099 form document ready for transmission
        CreateTransmissionWithSingleFormDoc(Transmission, IRS1099FormDocHeader);

        // [GIVEN] Company Information with empty Phone No.
        UpdateCompanyContactInfo('John Doe', '', 'test@example.com');

        // [WHEN] Check data to report
        asserterror IRSFormsFacade.CheckDataToReport(Transmission);

        // [THEN] Error is thrown for empty Phone No.
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedMessage('Phone No. must be between 10 and 30 digits', LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure PhoneNoWithMinLengthPasses()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        IRSFormsFacade: Codeunit "IRS Forms Facade";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 621425] Phone No. with exactly 10 digits passes validation
        Initialize();

        // [GIVEN] Vendor "V" with 1099 form document ready for transmission
        CreateTransmissionWithSingleFormDoc(Transmission, IRS1099FormDocHeader);

        // [GIVEN] Company Information with Phone No. of exactly 10 digits
        UpdateCompanyContactInfo('John Doe', '1234567890', 'test@example.com');

        // [WHEN] Check data to report
        IRSFormsFacade.CheckDataToReport(Transmission);

        // [THEN] No error is raised for Phone No.
    end;

    [Test]
    [HandlerFunctions('ErrorMessagesPageHandler')]
    procedure PhoneNoTooShortCausesError()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        IRSFormsFacade: Codeunit "IRS Forms Facade";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 621425] Phone No. with less than 10 digits causes validation error
        Initialize();

        // [GIVEN] Vendor "V" with 1099 form document ready for transmission
        CreateTransmissionWithSingleFormDoc(Transmission, IRS1099FormDocHeader);

        // [GIVEN] Company Information with Phone No. of only 9 digits
        UpdateCompanyContactInfo('John Doe', '123456789', 'test@example.com');

        // [WHEN] Check data to report
        asserterror IRSFormsFacade.CheckDataToReport(Transmission);

        // [THEN] Error is thrown for Phone No. too short
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedMessage('Phone No. must be between 10 and 30 digits', LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure PhoneNoWithMaxLengthPasses()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        IRSFormsFacade: Codeunit "IRS Forms Facade";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 621425] Phone No. with exactly 30 digits passes validation
        Initialize();

        // [GIVEN] Vendor "V" with 1099 form document ready for transmission
        CreateTransmissionWithSingleFormDoc(Transmission, IRS1099FormDocHeader);

        // [GIVEN] Company Information with Phone No. of exactly 30 digits (max allowed)
        UpdateCompanyContactInfo('John Doe', '123456789012345678901234567890', 'test@example.com');

        // [WHEN] Check data to report
        IRSFormsFacade.CheckDataToReport(Transmission);

        // [THEN] No error is raised for Phone No. at max length
    end;

    [Test]
    procedure SchemaOverrideUsesOnlySelectedEnvironmentAndAcceptsUnverifiedYear()
    var
        ReportingPeriod: Record "IRS Reporting Period";
        MockKeyVaultClientIRIS: Codeunit "Mock Key Vault Client IRIS";
        Source: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A period's Test and Live schema overrides are independent and can be saved for an unverified year.
        Initialize();

        // [GIVEN] Period 2099 has Test schema 5.0.7 and Live schema 2.0.3.
        LibraryIRSReportingPeriod.CreateSpecificReportingPeriod('2099', 20990101D, 20991231D);
        ReportingPeriod.Get('2099');
        ReportingPeriod.Validate("IRIS XML Schema Version Test", "XML Schema Version IRIS"::"5.0.7");
        ReportingPeriod.Validate("IRIS XML Schema Version Live", "XML Schema Version IRIS"::"2.0.3");
        ReportingPeriod.Modify(true);

        // [WHEN] Resolve schema first in Test mode, then in production mode.

        // [THEN] Test uses 5.0.7 and production uses 2.0.3, both from period rather than Key Vault.
        Assert.AreEqual(
            "XML Schema Version IRIS"::"5.0.7",
            LibraryIRS1099IRIS.ResolveSchemaVersion('2099', Source), 'TEST override must be used.');
        Assert.AreEqual('ReportingPeriod', Source, 'The configuration source must identify the period.');
        MockKeyVaultClientIRIS.SetTestMode(false);
        Assert.AreEqual(
            "XML Schema Version IRIS"::"2.0.3",
            LibraryIRS1099IRIS.ResolveSchemaVersion('2099', Source), 'Production override must be used.');
        MockKeyVaultClientIRIS.SetTestMode(true);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure EmptyEffectiveSchemaCannotSelectLegacyContract()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] An empty schema-version setting causes an error instead of defaulting to schema 2.0.3.
        Initialize();

        // [GIVEN] Schema-version text is empty.

        // [WHEN] Try to parse empty schema version.
        asserterror LibraryIRS1099IRIS.ParseSchemaVersion('');

        // [THEN] Error instructs user to select 2.0.3 or 5.0.7.
        Assert.ExpectedError('Select 2.0.3 or 5.0.7');
        Assert.ExpectedErrorCode('Dialog');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure UnsupportedEnumOverrideCannotFallBack()
    var
        ReportingPeriod: Record "IRS Reporting Period";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A schema override without an implementation cannot be saved.
        Initialize();

        // [GIVEN] Reporting-period record is ready for schema-override validation.
        ReportingPeriod.Init();

        // [WHEN] Try to select unsupported schema enum value.
        asserterror ReportingPeriod.Validate("IRIS XML Schema Version Test", "XML Schema Version IRIS".FromInteger(100000));

        // [THEN] Validation fails with guidance to select 2.0.3 or 5.0.7.
        Assert.ExpectedError('Select 2.0.3 or 5.0.7');
        Assert.ExpectedErrorCode('Dialog');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure EnumOnlySchemaCannotBeResolvedAtUse()
    var
        ReportingPeriod: Record "IRS Reporting Period";
        Source: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A stored schema override without an implementation is rejected when used.
        Initialize();

        // [GIVEN] Period 2099 has unimplemented schema value saved by bypassing field validation.
        InitializeEmptySchemaPeriod();
        ReportingPeriod.Get('2099');
        ReportingPeriod."IRIS XML Schema Version Test" := "XML Schema Version IRIS"::"Unimplemented Test";
        ReportingPeriod.Modify();

        // [WHEN] Try to resolve period's schema version.
        asserterror LibraryIRS1099IRIS.ResolveSchemaVersion('2099', Source);

        // [THEN] Error rejects unsupported value rather than using default schema.
        Assert.ExpectedError('Select 2.0.3 or 5.0.7');
        Assert.ExpectedErrorCode('Dialog');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure AlternatingSchemasDoNotReuseXmlOrCorrectionMode()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        TempIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header" temporary;
        IRSFormsFacade: Codeunit "IRS Forms Facade";
        Payload: Codeunit "Temp Blob";
        UniqueTransmissionId: Text[100];
        PreviousTransmissionId: Text[100];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Switching XML schemas does not reuse a previous request's amounts, counts or correction settings.
        Initialize();

        // [GIVEN] Accepted 2025 document can be generated with schemas 5.0.7 and 2.0.3.
        CreateContractTransmission(Transmission, IRS1099FormDocHeader, 2025);
        SetCorrectionReference(IRS1099FormDocHeader);

        // [WHEN] Generate correction with zero amounts using schema 5.0.7.
        IRSFormsFacade.CreateTransmissionXmlContent(
            Transmission, "Transmission Type IRIS"::C, true, UniqueTransmissionId, TempIRS1099FormDocHeader, Payload);

        // [THEN] XML contains zero amounts, correction reference and counts for this request only.
        VerifySchemaAttempt(Payload, '5.0.7', '1', '0', '1');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:OtherIntakeSystemInd', '0');
        PreviousTransmissionId := UniqueTransmissionId;

        // [WHEN] Use same facade to generate original transmission with schema 2.0.3.
        SetPeriodSchema('2025', "XML Schema Version IRIS"::"2.0.3");
        Clear(Payload);
        IRSFormsFacade.CreateTransmissionXmlContent(
            Transmission, "Transmission Type IRIS"::O, false, UniqueTransmissionId, TempIRS1099FormDocHeader, Payload);

        // [THEN] XML contains income 5000, its own counts and new transmission ID, without correction references.
        VerifySchemaAttempt(Payload, '2.0.3', '0', '5000', '0');
        LibraryXPathXMLReader.VerifyXmlNodeAbsence('//n1:PrevSubmittedRecRecipientGrp');
        Assert.AreNotEqual(PreviousTransmissionId, UniqueTransmissionId, 'Each attempt needs its own UTID.');
        PreviousTransmissionId := UniqueTransmissionId;

        // [WHEN] Switch back to schema 5.0.7 and generate another original transmission.
        SetPeriodSchema('2025', "XML Schema Version IRIS"::"5.0.7");
        Clear(Payload);
        IRSFormsFacade.CreateTransmissionXmlContent(
            Transmission, "Transmission Type IRIS"::O, false, UniqueTransmissionId, TempIRS1099FormDocHeader, Payload);

        // [THEN] Income remains 5000, transmission ID is new, and earlier zero-correction settings are not reused.
        VerifySchemaAttempt(Payload, '5.0.7', '1', '5000', '0');
        LibraryXPathXMLReader.VerifyXmlNodeAbsence('//n1:PrevSubmittedRecRecipientGrp');
        Assert.AreNotEqual(PreviousTransmissionId, UniqueTransmissionId, 'Each attempt needs its own UTID.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure TaxYearValidationAcceptsInclusiveBoundaries()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Tax-year validation accepts both ends of the allowed range, 2000 and 3000.
        Initialize();

        // [GIVEN] Minimum allowed year is 2000 and maximum is 3000.

        // [WHEN] Validate 2000 and 3000.
        LibraryIRS1099IRIS.ValidateTaxYear('2000');
        LibraryIRS1099IRIS.ValidateTaxYear('3000');

        // [THEN] Both years are accepted without errors.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure TaxYearValidationRejectsOutOfRangeYears()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Tax-year validation rejects 1999 and 3001, just outside the allowed range.
        Initialize();

        // [GIVEN] Allowed tax years are 2000 through 3000.

        // [WHEN] Validate 1999 and 3001.

        // [THEN] Both years fail with four-digit, 2000-to-3000 validation error.
        VerifyInvalidTaxYear('1999');
        VerifyInvalidTaxYear('3001');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure TaxYearValidationRejectsMalformedYears()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Tax-year validation requires exactly four digits, with no sign, letters or whitespace.
        Initialize();

        // [GIVEN] Inputs include empty text, too few or too many digits, letter, plus sign and trailing whitespace.

        // [WHEN] Validate each malformed input.

        // [THEN] Every input fails with same tax-year format error.
        VerifyInvalidTaxYear('');
        VerifyInvalidTaxYear('202');
        VerifyInvalidTaxYear('02026');
        VerifyInvalidTaxYear('20A6');
        VerifyInvalidTaxYear('+026');
        VerifyInvalidTaxYear('2026 ');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SoftwareIdRejectsOutOfRangeTaxYear()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Software ID lookup rejects an invalid tax year before reading configuration.
        Initialize();

        // [GIVEN] Software ID is requested for year 3001, above maximum allowed year.

        // [WHEN] Try to resolve Software ID for 3001.
        asserterror LibraryIRS1099IRIS.ResolveSoftwareId('3001');

        // [THEN] Tax-year validation fails before Software ID configuration is read.
        Assert.ExpectedError('tax year 3001 must contain four digits and be between 2000 and 3000');
        Assert.ExpectedErrorCode('Dialog');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure MappingLookupRejectsOutOfRangeTaxYear()
    var
        AmountXmlElements: JsonObject;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] XML mapping lookup cannot use an earlier resource to bypass tax-year validation.
        Initialize();

        // [GIVEN] Amount mappings are requested for year 3001, above maximum allowed year.

        // [WHEN] Try to load amount mappings for 3001.
        asserterror AmountXmlElements := LibraryIRS1099IRIS.GetAmountXmlElements('3001');

        // [THEN] Tax-year validation fails instead of returning mappings from earlier year.
        Assert.ExpectedError('tax year 3001 must contain four digits and be between 2000 and 3000');
        Assert.ExpectedErrorCode('Dialog');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure OriginalConfigurationSoftwareIdMustMatchRequestedYear()
    var
        MockKeyVaultClientIRIS: Codeunit "Mock Key Vault Client IRIS";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A partner's shared Software ID must still match the requested tax year.
        Initialize();

        // [GIVEN] Original configuration interface returns 2026 Software ID 26TEST0001.
        MockKeyVaultClientIRIS.SetSoftwareId('26TEST0001');

        // [WHEN] Request that provider's Software ID for 2025.
        asserterror LibraryIRS1099IRIS.ResolveSoftwareId('2025');

        // [THEN] Error explains that 2025 Software ID must start with 25.
        Assert.ExpectedError('tax year 2025 must start with 25');
        Assert.ExpectedErrorCode('Dialog');
        MockKeyVaultClientIRIS.SetDefaultValues();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure PartnerStatusAndAcknowledgmentDispatchIsPreserved()
    var
        IRSFormsSetup: Record "IRS Forms Setup";
        IRSFormsFacade: Codeunit "IRS Forms Facade";
        TempBlob: Codeunit "Temp Blob";
        ContentStream: InStream;
        Content: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Status and acknowledgment XML requests use the configured partner implementation.
        Initialize();

        // [GIVEN] IRS Forms Setup selects mock partner XML implementation.
        IRSFormsSetup.Get();
        IRSFormsSetup.Implementation := IRSFormsSetup.Implementation::"Mock XML Test";
        IRSFormsSetup.Modify();

        // [WHEN] Request status XML through IRS Forms Facade.
        IRSFormsFacade.CreateGetStatusRequestXmlContent("Search Param Type IRIS"::RID, 'RECEIPT', TempBlob);

        // [THEN] Returned content is produced by partner implementation.
        TempBlob.CreateInStream(ContentStream, TextEncoding::UTF8);
        ContentStream.ReadText(Content);
        Assert.AreEqual('PartnerStatus:RECEIPT', Content, 'The partner status implementation must be called.');

        // [WHEN] Request acknowledgment XML through same facade.
        Clear(TempBlob);
        IRSFormsFacade.CreateAcknowledgmentRequestXmlContent("Search Param Type IRIS"::UTID, 'UTID', TempBlob);

        // [THEN] Partner implementation also produces acknowledgment request.
        TempBlob.CreateInStream(ContentStream, TextEncoding::UTF8);
        ContentStream.ReadText(Content);
        Assert.AreEqual('PartnerAcknowledgment:UTID', Content, 'The partner acknowledgment implementation must be called.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure NewContractCorrectionIncludesIntakeIndicatorBeforeAcceptedReference()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        TempIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header" temporary;
        TempBlob: Codeunit "Temp Blob";
        UniqueTransmissionId: Text[100];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Schema 5.0.7 correction XML places the intake-system indicator before the accepted record reference.
        Initialize();

        // [GIVEN] 2026 document D is selected for correction with accepted receipt, submission ID and record ID.
        CreateContractTransmission(Transmission, IRS1099FormDocHeader, 2026);
        IRS1099FormDocHeader."IRIS Needs Correction" := true;
        IRS1099FormDocHeader."IRIS Last Accepted Receipt ID" := 'ACCEPTED';
        IRS1099FormDocHeader."IRIS Submission ID" := '1';
        IRS1099FormDocHeader."IRIS Record ID" := '2';
        IRS1099FormDocHeader.Modify();

        // [WHEN] Generate correction XML.
        LibraryIRS1099IRIS.CreateTransmissionXmlContent(Transmission, "Transmission Type IRIS"::C, false, UniqueTransmissionId, TempIRS1099FormDocHeader, TempBlob);

        // [THEN] Previous-record group contains OtherIntakeSystemInd first and accepted receipt/submission/record reference second.
        VerifyContractManifest(TempBlob, '2026', '26TEST0001', '0');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:PrevSubmittedRecRecipientGrp/*[1]', '0');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:PrevSubmittedRecRecipientGrp/*[2]', 'ACCEPTED|1|2');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure StandardSoftwareIdsAlternateWithoutSharedIdChanges()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Standard configuration resolves Software IDs by the requested year, not a shared ID or the most recently used year.
        Initialize();

        // [GIVEN] Key Vault has IDs for 2024, 2025 and 2026 plus incompatible old shared ID.
        InitializeStandardProvider();
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-SoftwareID-2024', '24TEST0001');
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-SoftwareID-2025', '25TEST0001');
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-SoftwareID-2026', '26TEST0001');
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-SoftwareID', '99SHARED');

        // [WHEN] Request IDs for 2025, 2026, 2025 again and then 2024.

        // [THEN] Each request returns that year's ID; shared ID and any previously used year's ID are ignored.
        Assert.AreEqual('25TEST0001', LibraryIRS1099IRIS.ResolveSoftwareId('2025'), 'TY2025 identity.');
        Assert.AreEqual('26TEST0001', LibraryIRS1099IRIS.ResolveSoftwareId('2026'), 'TY2026 identity.');
        Assert.AreEqual('25TEST0001', LibraryIRS1099IRIS.ResolveSoftwareId('2025'), 'Cached TY2026 cannot replace TY2025.');
        Assert.AreEqual('24TEST0001', LibraryIRS1099IRIS.ResolveSoftwareId('2024'), 'The older contract also requires year-specific identity.');
        ResetStandardProvider();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure MissingStandardYearIdCannotUseLegacyOrNewestId()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A missing year-specific Software ID cannot be replaced by a shared ID or a newer year's ID.
        Initialize();

        // [GIVEN] Key Vault has shared ID and 2026 ID, but no 2025 ID.
        InitializeStandardProvider();
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-SoftwareID', '25SHARED');
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-SoftwareID-2026', '26TEST0001');

        // [WHEN] Request Software ID for 2025.
        asserterror LibraryIRS1099IRIS.ResolveSoftwareId('2025');

        // [THEN] Error reports missing Software ID without using either available ID.
        Assert.ExpectedError('Software ID');
        Assert.ExpectedErrorCode('Dialog');
        ResetStandardProvider();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure MismatchedStandardYearIdFailsLocally()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A year-specific Software ID must start with the matching year prefix.
        Initialize();

        // [GIVEN] 2025 Key Vault key contains 2026 ID 26TEST0001.
        InitializeStandardProvider();
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-SoftwareID-2025', '26TEST0001');

        // [WHEN] Request Software ID for 2025.
        asserterror LibraryIRS1099IRIS.ResolveSoftwareId('2025');

        // [THEN] Validation fails locally and explains that ID must start with 25.
        Assert.ExpectedError('tax year 2025 must start with 25');
        Assert.ExpectedErrorCode('Dialog');
        ResetStandardProvider();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure EmptyOverridesUseSelectedProviderAndClearingRestoresIt()
    var
        ReportingPeriod: Record "IRS Reporting Period";
        Source: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] An empty period override uses that environment's provider setting, and clearing an override restores the setting.
        Initialize();

        // [GIVEN] Provider has Test schema 5.0.7 and Live schema 2.0.3; period's Test override is empty and its inactive Live override is unsupported.
        InitializeStandardProvider();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        EnvironmentInfoTestLibrary.SetTestabilitySandbox(true);
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-XmlSchemaVersionTest', '5.0.7');
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-XmlSchemaVersionLive', '2.0.3');
        InitializeEmptySchemaPeriod();
        ReportingPeriod.Get('2099');
        ReportingPeriod."IRIS XML Schema Version Live" := "XML Schema Version IRIS".FromInteger(100000);
        ReportingPeriod.Modify();

        // [WHEN] Resolve schema in Test mode.

        // [THEN] Provider schema 5.0.7 is used, ignoring inactive Live override.
        Assert.AreEqual("XML Schema Version IRIS"::"5.0.7", LibraryIRS1099IRIS.ResolveSchemaVersion('2099', Source), 'Use TEST provider.');
        Assert.AreEqual('KeyVault', Source, 'Provider source must be retained.');

        // [WHEN] Set and then clear environment-specific overrides.
        ReportingPeriod.Validate("IRIS XML Schema Version Test", "XML Schema Version IRIS"::"2.0.3");
        ReportingPeriod.Modify();
        Assert.AreEqual("XML Schema Version IRIS"::"2.0.3", LibraryIRS1099IRIS.ResolveSchemaVersion('2099', Source), 'Explicit older contract remains supported.');
        ReportingPeriod.Validate("IRIS XML Schema Version Test", "XML Schema Version IRIS"::" ");
        ReportingPeriod.Validate("IRIS XML Schema Version Live", "XML Schema Version IRIS"::" ");
        ReportingPeriod.Modify();

        // [THEN] Clearing each override restores its own environment's provider schema.
        Assert.AreEqual("XML Schema Version IRIS"::"5.0.7", LibraryIRS1099IRIS.ResolveSchemaVersion('2099', Source), 'Clearing restores TEST provider.');
        EnvironmentInfoTestLibrary.SetTestabilitySandbox(false);
        Assert.AreEqual("XML Schema Version IRIS"::"2.0.3", LibraryIRS1099IRIS.ResolveSchemaVersion('2099', Source), 'Production stays on its own default.');
        ResetStandardProvider();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure MissingStandardSchemaFailsClosed()
    var
        Source: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A missing current schema setting causes an error, even if a retired setting exists.
        Initialize();

        // [GIVEN] Key Vault contains only retired schema-version setting.
        InitializeStandardProvider();
        InitializeEmptySchemaPeriod();
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-ReleaseProfileLive', 'Legacy');

        // [WHEN] Resolve production schema version.
        asserterror LibraryIRS1099IRIS.ResolveSchemaVersion('2099', Source);

        // [THEN] Operation stops instead of reading retired setting or defaulting to older schema.
        VerifyRequiredSchemaFailure();
        ResetStandardProvider();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure EmptyStandardSchemaFailsClosed()
    var
        Source: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] An empty current schema setting causes an error without inventing a retrieval failure.
        Initialize();

        // [GIVEN] Production schema-version key exists but contains empty text.
        InitializeStandardProvider();
        InitializeEmptySchemaPeriod();
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-XmlSchemaVersionLive', '');

        // [WHEN] Resolve production schema version.
        asserterror LibraryIRS1099IRIS.ResolveSchemaVersion('2099', Source);

        // [THEN] Error reports unusable setting; no fallback schema is selected.
        VerifyRequiredSchemaFailure();
        ResetStandardProvider();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure UnsupportedStandardSchemaFailsClosed()
    var
        Source: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A current schema setting must contain a supported XML version, not a retired alias.
        Initialize();

        // [GIVEN] Production schema-version key contains retired alias.
        InitializeStandardProvider();
        InitializeEmptySchemaPeriod();
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-XmlSchemaVersionLive', 'PY2027');

        // [WHEN] Resolve production schema version.
        asserterror LibraryIRS1099IRIS.ResolveSchemaVersion('2099', Source);

        // [THEN] Parsing rejects alias rather than converting it to supported version.
        Assert.ExpectedError('Select 2.0.3 or 5.0.7');
        Assert.ExpectedErrorCode('Dialog');
        ResetStandardProvider();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure UnsupportedStoredActiveOverrideCannotFallBackToValidProvider()
    var
        ReportingPeriod: Record "IRS Reporting Period";
        Source: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] An unsupported active override is rejected even when the provider has a valid default.
        Initialize();

        // [GIVEN] Period's active schema override was saved with unsupported value by bypassing validation.
        InitializeStandardProvider();
        InitializeEmptySchemaPeriod();
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-XmlSchemaVersionLive', '2.0.3');
        ReportingPeriod.Get('2099');
        ReportingPeriod."IRIS XML Schema Version Live" := "XML Schema Version IRIS".FromInteger(100000);
        ReportingPeriod.Modify();

        // [WHEN] Resolve active schema version.
        asserterror LibraryIRS1099IRIS.ResolveSchemaVersion('2099', Source);

        // [THEN] Error rejects stored value rather than treating it as empty override.
        Assert.ExpectedError('Select 2.0.3 or 5.0.7');
        Assert.ExpectedErrorCode('Dialog');
        ResetStandardProvider();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('TestDestinationMessageHandler')]
    procedure StandardSandboxAndProductionUseMatchingEndpointsAndDestination()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        TempIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header" temporary;
        IRSFormsFacade: Codeunit "IRS Forms Facade";
        TempBlob: Codeunit "Temp Blob";
        TransmissionPage: TestPage "Transmission IRIS";
        SetupPage: TestPage "IRS Forms Setup";
        UniqueTransmissionId: Text[100];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] The sender, transmission card and setup page agree on Test or Production independently of schema version.
        Initialize();

        // [GIVEN] Standard configuration has different test and production endpoint URLs and fixed schema selection.
        CreateContractTransmission(Transmission, IRS1099FormDocHeader, 2025);
        InitializeStandardProvider();
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-SoftwareID-2025', '25TEST0001');
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-SoftwareDevTCC', 'TEST1');
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-TransmitterTCC', 'LIVE1');
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-ContactInfo', '{"ContactName":"Test Contact","ContactEmail":"test@example.com","ContactPhone":"1234567890"}');
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-SubmitEndpointTest', 'https://test.example/submit');
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-SubmitEndpointLive', 'https://production.example/submit');
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-GetStatusEndpointTest', 'https://test.example/status');
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-GetStatusEndpointLive', 'https://production.example/status');
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-AuthURLTest', 'https://test.example/auth');
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-AuthURLLive', 'https://production.example/auth');
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-ClientID', '11111111-2222-4333-8444-555555555555');
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        EnvironmentInfoTestLibrary.SetTestabilitySandbox(true);

        // [WHEN] Generate XML and open transmission and setup pages in sandbox mode.
        IRSFormsFacade.CreateTransmissionXmlContent(Transmission, "Transmission Type IRIS"::O, false, UniqueTransmissionId, TempIRS1099FormDocHeader, TempBlob);
        TransmissionPage.OpenEdit();
        TransmissionPage.GoToRecord(Transmission);

        // [THEN] XML marks request as Test, sender uses test URLs, and both pages show Test.
        VerifyStandardEnvironment(TempBlob, 'T', 'https://test.example/submit', 'https://test.example/status', 'https://test.example/auth');
        Assert.IsTrue(TransmissionPage.TestModeIndicator.Visible(), 'The destination must always be visible.');
        TransmissionPage.TestModeIndicator.AssertEquals('Test');
        Assert.IsFalse(TransmissionPage.TestModeIndicator.Editable(), 'The destination is determined by routing, not edited on the transmission.');
        TransmissionPage.TestModeIndicator.DrillDown();
        VerifyTestDestinationMessage();
        TransmissionPage.Close();
        SetupPage.OpenEdit();
        SetupPage.IRISDestination.AssertEquals('Test');
        SetupPage.SubmissionEndpointURL.AssertEquals('https://test.example/submit');
        Assert.IsTrue(SetupPage.IRISDestination.Visible(), 'Setup must show the destination by default.');
        Assert.IsTrue(SetupPage.SubmissionEndpointURL.Visible(), 'Setup must show the submission endpoint by default.');
        Assert.IsFalse(SetupPage.IRISDestination.Editable(), 'Setup must not allow changing the destination.');
        Assert.IsFalse(SetupPage.SubmissionEndpointURL.Editable(), 'Setup must not allow changing the endpoint.');
        SetupPage.Close();

        // [WHEN] Switch to production mode without changing period or schema.
        EnvironmentInfoTestLibrary.SetTestabilitySandbox(false);
        IRSFormsFacade.CreateTransmissionXmlContent(Transmission, "Transmission Type IRIS"::O, false, UniqueTransmissionId, TempIRS1099FormDocHeader, TempBlob);
        TransmissionPage.OpenEdit();
        TransmissionPage.GoToRecord(Transmission);

        // [THEN] XML marks request as Production, sender uses production URLs, and both pages show Production.
        VerifyStandardEnvironment(TempBlob, 'P', 'https://production.example/submit', 'https://production.example/status', 'https://production.example/auth');
        Assert.IsTrue(TransmissionPage.TestModeIndicator.Visible(), 'Production must not be indicated only by the absence of a test banner.');
        TransmissionPage.TestModeIndicator.AssertEquals('Production');
        TransmissionPage.Close();
        SetupPage.OpenEdit();
        SetupPage.IRISDestination.AssertEquals('Production');
        SetupPage.SubmissionEndpointURL.AssertEquals('https://production.example/submit');
        SetupPage.Close();
        ResetStandardProvider();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure TransmissionAndSetupOpenWhenSubmitEndpointIsMissing()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Transmission and setup pages remain usable when the production submission URL is missing.
        Initialize();

        // [GIVEN] Standard configuration has client ID but no production submission endpoint.
        InitializeStandardProvider();
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-ClientID', '11111111-2222-4333-8444-555555555555');

        // [WHEN] Open transmission and setup pages.

        // [THEN] Both pages open without attempting submission or failing on missing URL.
        VerifyPagesOpenWithoutSubmitEndpoint();
        ResetStandardProvider();

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure TransmissionAndSetupOpenWhenSubmitEndpointIsEmpty()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Transmission and setup pages remain usable when the production submission URL is empty.
        Initialize();

        // [GIVEN] Standard configuration has client ID and empty production submission endpoint.
        InitializeStandardProvider();
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-ClientID', '11111111-2222-4333-8444-555555555555');
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-SubmitEndpointLive', '');

        // [WHEN] Open transmission and setup pages.

        // [THEN] Both pages open without attempting submission or failing on empty URL.
        VerifyPagesOpenWithoutSubmitEndpoint();
        ResetStandardProvider();

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('DeclineDestinationConfirmation')]
    procedure TestSendConfirmationsDescribeAtsAndAllowCancellation()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Test send confirmations explain that data goes to IRS ATS, not production, and allow cancellation.
        Initialize();

        // [GIVEN] 2025 transmission uses sandbox Test destination.

        // [WHEN] Attempt each supported send action and decline its destination confirmation.
        VerifySendConfirmationDestination(true);

        // [THEN] Every confirmation names tax year 2025, IRS Test and IRIS Assurance Testing System, and explains that it is not production filing.
        VerifyTestSendConfirmations();

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('DeclineDestinationConfirmation')]
    procedure ProductionSendConfirmationsDescribeLiveSubmissionAndAllowCancellation()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Production send confirmations identify the live IRS destination and allow cancellation.
        Initialize();

        // [GIVEN] 2025 transmission uses Production destination.

        // [WHEN] Attempt each supported send action and decline its destination confirmation.
        VerifySendConfirmationDestination(false);

        // [THEN] Every confirmation names tax year 2025 and live production filing destination.
        VerifyProductionSendConfirmations();

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure HistoryDestinationUsesStoredTestCode()
    var
        TestAttempt: Record "Transmission Log IRIS";
        ProductionAttempt: Record "Transmission Log IRIS";
        EarlierAttempt: Record "Transmission Log IRIS";
        HistoryPage: TestPage "Transmission Logs IRIS";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Transmission history shows each attempt's saved destination, not the current environment.
        Initialize();

        // [GIVEN] Log records have saved Test code T, Production code P and no destination code.
        TestAttempt."XML Test Code" := 'T';
        TestAttempt.Insert(true);
        ProductionAttempt."XML Test Code" := 'P';
        ProductionAttempt.Insert(true);
        EarlierAttempt.Insert(true);

        // [WHEN] View log records while switching current environment between production and sandbox.
        EnvironmentInfoTestLibrary.SetTestabilitySandbox(false);
        HistoryPage.OpenView();
        HistoryPage.GoToRecord(TestAttempt);

        // [THEN] History still shows Test, Production and empty destination respectively, without guessing missing information.
        Assert.IsTrue(HistoryPage.Destination.Visible(), 'History must show readable destinations by default.');
        HistoryPage.Destination.AssertEquals('Test');
        EnvironmentInfoTestLibrary.SetTestabilitySandbox(true);
        HistoryPage.GoToRecord(ProductionAttempt);
        HistoryPage.Destination.AssertEquals('Production');
        HistoryPage.GoToRecord(EarlierAttempt);
        HistoryPage.Destination.AssertEquals('');
        HistoryPage.Close();
        ResetStandardProvider();

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalNecXmlUsesSharedValuesAndSchemaOrder()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] NEC XML reports tips and overtime as amounts already included in compensation and places occupation codes between them.
        Initialize();

        // [GIVEN] NEC document D has compensation 5000, tips 100, overtime 50 and codes 101 and 000.
        CreateSupplementalTransmission(Transmission, IRS1099FormDocHeader, 'NEC');

        // [WHEN] Generate original-transmission XML.
        CreateSupplementalXml(Transmission, "Transmission Type IRIS"::O, false, TempBlob);

        // [THEN] Compensation stays 5000; recipient fields and submission totals follow NEC schema order without correction references.
        VerifySupplementalXml(TempBlob, 'NEC', '5000', '100', '50');
        VerifySupplementalOrder('NEC');
        LibraryXPathXMLReader.VerifyXmlNodeAbsence('//n1:PrevSubmittedRecRecipientGrp');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:CorrectedInd', '0');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalMiscXmlUsesDifferentDetailAndTotalOrder()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] MISC XML uses the schema's different ordering rules for recipient fields and submission totals.
        Initialize();

        // [GIVEN] MISC document D has tips and overtime already included in Other Income.
        CreateSupplementalTransmission(Transmission, IRS1099FormDocHeader, 'MISC');

        // [WHEN] Generate original-transmission XML.
        CreateSupplementalXml(Transmission, "Transmission Type IRIS"::O, false, TempBlob);

        // [THEN] Recipient tips follow deferrals, total tips follow withholding, and remaining fields follow their required order.
        VerifySupplementalXml(TempBlob, 'MISC', '5000', '100', '50');
        VerifySupplementalOrder('MISC');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalDifferentRecipientsRoundBeforeTotals()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        SecondIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Submission totals add amounts rounded for each recipient separately.
        Initialize();

        // [GIVEN] Two documents for different recipients each have tips 0.006 and overtime 0.004.
        CreateSupplementalTransmission(Transmission, IRS1099FormDocHeader, 'NEC');
        AddSupplementalHeader(IRS1099FormDocHeader, SecondIRS1099FormDocHeader, false);
        SetSupplementalValues(IRS1099FormDocHeader, 0.006, 0.004, '101', '000');
        SetSupplementalValues(SecondIRS1099FormDocHeader, 0.006, 0.004, '102', '');

        // [WHEN] Generate original-transmission XML.
        CreateSupplementalXml(Transmission, "Transmission Type IRIS"::O, false, TempBlob);

        // [THEN] Each recipient has tips 0.01 and overtime 0, so submission totals are tips 0.02 and overtime 0.
        InitXMLReader(TempBlob);
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:TotalRecipientFormCnt', '2');
        LibraryXPathXMLReader.VerifyXmlNodeValue('(//n1:Form1099NECDetail)[1]/n1:CashTipsAmt', '0.01');
        LibraryXPathXMLReader.VerifyXmlNodeValue('(//n1:Form1099NECDetail)[2]/n1:CashTipsAmt', '0.01');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:Form1099NECTotalAmtGrp/n1:CashTipsAmt', '0.02');
        LibraryXPathXMLReader.VerifyXmlNodeValue('(//n1:Form1099NECDetail)[1]/n1:OvertimeCompensationAmt', '0');
        LibraryXPathXMLReader.VerifyXmlNodeValue('(//n1:Form1099NECDetail)[2]/n1:OvertimeCompensationAmt', '0');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:Form1099NECTotalAmtGrp/n1:OvertimeCompensationAmt', '0');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:Form1099NECTotalAmtGrp/n1:NonemployeeCompensationAmt', '10000');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:IRSubmission1Header/following-sibling::*[1][self::n1:IRSubmission1Detail]//n1:Form1099NECDetail[1]/n1:CashTipsAmt', '0.01');
        VerifySavedSupplementalValues(IRS1099FormDocHeader, 0.006, 0.004, '101', '000');
        VerifySavedSupplementalValues(SecondIRS1099FormDocHeader, 0.006, 0.004, '102', '');
        VerifyDocLineAmount(IRS1099FormDocHeader, 'NEC-01', 5000);
        VerifyDocLineAmount(SecondIRS1099FormDocHeader, 'NEC-01', 5000);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalSameRecipientRoundsCombinedRawValues()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        SecondIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Documents for the same recipient are combined before rounding amounts to cents.
        Initialize();

        // [GIVEN] Two documents for one recipient each have tips 0.004, overtime 0.006 and same occupation codes.
        CreateSupplementalTransmission(Transmission, IRS1099FormDocHeader, 'NEC');
        AddSupplementalHeader(IRS1099FormDocHeader, SecondIRS1099FormDocHeader, true);
        SetSupplementalValues(IRS1099FormDocHeader, 0.004, 0.006, '000', '101');
        SetSupplementalValues(SecondIRS1099FormDocHeader, 0.004, 0.006, '101', '000');

        // [WHEN] Generate original-transmission XML.
        CreateSupplementalXml(Transmission, "Transmission Type IRIS"::O, false, TempBlob);

        // [THEN] Combined tips round to 0.01 and overtime to 0.01; duplicate codes are reported only once.
        VerifySupplementalXml(TempBlob, 'NEC', '10000', '0.01', '0.01');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:TotalRecipientFormCnt', '1');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:Form1099NECDetail/n1:TreasuryTippedOccupationCd[1]', '000');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:Form1099NECDetail/n1:TreasuryTippedOccupationCd[2]', '101');
        LibraryXPathXMLReader.VerifyXmlNodeAbsence('//n1:Form1099NECDetail/n1:TreasuryTippedOccupationCd[3]');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:Form1099NECDetail/n1:CashTipsAmt/following-sibling::*[1][self::n1:TreasuryTippedOccupationCd]', '000');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:Form1099NECDetail/n1:TreasuryTippedOccupationCd[2]/following-sibling::*[1][self::n1:OvertimeCompensationAmt]', '0.01');
        VerifySavedSupplementalValues(IRS1099FormDocHeader, 0.004, 0.006, '000', '101');
        VerifySavedSupplementalValues(SecondIRS1099FormDocHeader, 0.004, 0.006, '101', '000');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalRoundedZeroTipsRetainAndRestoreCodes()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] XML omits occupation codes when rounded tips are zero without changing the saved values.
        Initialize();

        // [GIVEN] Document D has tips that round to zero, overtime that rounds up, and saved occupation codes.
        CreateSupplementalTransmission(Transmission, IRS1099FormDocHeader, 'MISC');
        SetSupplementalValues(IRS1099FormDocHeader, 0.004, 0.006, '101', '000');

        // [WHEN] Generate original-transmission XML.
        CreateSupplementalXml(Transmission, "Transmission Type IRIS"::O, false, TempBlob);

        // [THEN] XML omits codes, while saved tips, overtime and codes remain unchanged.
        VerifySupplementalXml(TempBlob, 'MISC', '5000', '0', '0.01');
        LibraryXPathXMLReader.VerifyXmlNodeAbsence('//n1:TreasuryTippedOccupationCd');
        VerifySavedSupplementalValues(IRS1099FormDocHeader, 0.004, 0.006, '101', '000');
        VerifyDocLineAmount(IRS1099FormDocHeader, 'MISC-03', 5000);

        // [GIVEN] Increase tips so they round to positive cent.
        SetSupplementalValues(IRS1099FormDocHeader, 0.006, 0.004, '101', '000');

        // [WHEN] Generate original XML again.
        CreateSupplementalXml(Transmission, "Transmission Type IRIS"::O, false, TempBlob);

        // [THEN] Saved codes appear again, while overtime is rounded independently to zero.
        VerifySupplementalXml(TempBlob, 'MISC', '5000', '0.01', '0');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:Form1099MISCDetail/n1:TreasuryTippedOccupationCd[2]', '000');
        VerifySavedSupplementalValues(IRS1099FormDocHeader, 0.006, 0.004, '101', '000');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalRoundedZeroUnionSuppressesAllCodes()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        SecondIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] More than two saved recipient codes cause no error when the combined tips round to zero.
        Initialize();

        // [GIVEN] Two documents for one recipient have three distinct saved codes, but their combined tips round to zero.
        CreateSupplementalTransmission(Transmission, IRS1099FormDocHeader, 'NEC');
        AddSupplementalHeader(IRS1099FormDocHeader, SecondIRS1099FormDocHeader, true);
        SetSupplementalValues(IRS1099FormDocHeader, 0.001, 0.004, '101', '000');
        SetSupplementalValues(SecondIRS1099FormDocHeader, 0.001, 0.004, '101', '102');

        // [WHEN] Generate original-transmission XML.
        CreateSupplementalXml(Transmission, "Transmission Type IRIS"::O, false, TempBlob);

        // [THEN] All codes are omitted from XML, and no saved amounts or codes are changed.
        VerifySupplementalXml(TempBlob, 'NEC', '10000', '0', '0.01');
        LibraryXPathXMLReader.VerifyXmlNodeAbsence('//n1:TreasuryTippedOccupationCd');
        VerifySavedSupplementalValues(IRS1099FormDocHeader, 0.001, 0.004, '101', '000');
        VerifySavedSupplementalValues(SecondIRS1099FormDocHeader, 0.001, 0.004, '101', '102');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalRoundedTotalsRejectOverflow()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        SecondIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Rounding each recipient's amounts can make a submission total exceed the allowed maximum.
        Initialize();

        // [GIVEN] Two recipients' unrounded tips sum to maximum, but rounding each recipient to cents makes total larger.
        CreateSupplementalTransmission(Transmission, IRS1099FormDocHeader, 'NEC');
        AddSupplementalHeader(IRS1099FormDocHeader, SecondIRS1099FormDocHeader, false);
        SetDocLineAmount(IRS1099FormDocHeader, 'NEC-01', 499999999999999.995, 2000);
        SetDocLineAmount(SecondIRS1099FormDocHeader, 'NEC-01', 499999999999999.995, 2000);
        SetSupplementalValues(IRS1099FormDocHeader, 499999999999999.995, 0, '101', '');
        SetSupplementalValues(SecondIRS1099FormDocHeader, 499999999999999.995, 0, '102', '');

        // [WHEN] Try to generate original-transmission XML.
        asserterror CreateSupplementalXml(Transmission, "Transmission Type IRIS"::O, false, TempBlob);

        // [THEN] Error rejects rounded total and identifies both contributing documents.
        Assert.ExpectedError('for supplemental XML element CashTipsAmt must be between zero');
        Assert.ExpectedError(Format(IRS1099FormDocHeader.ID));
        Assert.ExpectedError(Format(SecondIRS1099FormDocHeader.ID));
        Assert.ExpectedErrorCode('Dialog');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalSelectedCorrectionExcludesUnselectedDocuments()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        UnselectedIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Correction XML includes amounts, codes and counts only for selected documents.
        Initialize();

        // [GIVEN] Transmission T contains document D1 selected for correction and unselected document D2.
        CreateSupplementalTransmission(Transmission, IRS1099FormDocHeader, 'NEC');
        AddSupplementalHeader(IRS1099FormDocHeader, UnselectedIRS1099FormDocHeader, false);
        SetSupplementalValues(IRS1099FormDocHeader, 0.006, 0.004, '101', '000');
        SetSupplementalValues(UnselectedIRS1099FormDocHeader, 200, 75, '102', '103');
        SetCorrectionReference(IRS1099FormDocHeader);

        // [WHEN] Generate correction with saved nonzero amounts.
        CreateSupplementalXml(Transmission, "Transmission Type IRIS"::C, false, TempBlob);

        // [THEN] Only D1 contributes recipient counts, amounts and occupation codes.
        VerifySupplementalXml(TempBlob, 'NEC', '5000', '0.01', '0');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:TotalRecipientFormCnt', '1');
        LibraryXPathXMLReader.VerifyXmlNodeAbsence('//n1:TreasuryTippedOccupationCd[text()="102" or text()="103"]');
        VerifySavedSupplementalValues(UnselectedIRS1099FormDocHeader, 200, 75, '102', '103');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalXmlFollowsExcludedParentAndPositiveWithholding()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] MISC XML includes tips linked to Other Income only when that income is reportable.
        Initialize();

        // [GIVEN] MISC document D has rents 2500, Other Income 500 below minimum, and valid saved supplemental values.
        CreateSupplementalTransmission(Transmission, IRS1099FormDocHeader, 'MISC');
        SetDocLineAmount(IRS1099FormDocHeader, 'MISC-03', 500, 2000);
        SetDocLineAmount(IRS1099FormDocHeader, 'MISC-01', 2500, 2000);
        SetDocLineAmount(IRS1099FormDocHeader, 'MISC-04', 0, 0);

        // [WHEN] Generate XML without positive backup withholding.
        CreateSupplementalXml(Transmission, "Transmission Type IRIS"::O, false, TempBlob);

        // [THEN] Rents do not make Other Income or its supplemental values reportable.
        VerifySupplementalXml(TempBlob, 'MISC', '0', '0', '0');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:Form1099MISCDetail/n1:RentAmt', '2500');
        LibraryXPathXMLReader.VerifyXmlNodeAbsence('//n1:TreasuryTippedOccupationCd');

        // [GIVEN] Add positive withholding, making nonzero Other Income reportable.
        SetDocLineAmount(IRS1099FormDocHeader, 'MISC-04', 25, 0);

        // [WHEN] Refresh income inclusion and generate XML again.
        CreateSupplementalXml(Transmission, "Transmission Type IRIS"::O, false, TempBlob);

        // [THEN] Saved tips, overtime and codes appear, without adding their amounts to Other Income.
        VerifySupplementalXml(TempBlob, 'MISC', '500', '100', '50');
        VerifySavedSupplementalValues(IRS1099FormDocHeader, 100, 50, '101', '000');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalXmlRetainsZeroTipCodesAndRestoresThem()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] XML excludes codes for zero tips but reuses the saved codes after positive tips return.
        Initialize();

        // [GIVEN] Document D has zero tips, positive overtime and two saved occupation codes.
        CreateSupplementalTransmission(Transmission, IRS1099FormDocHeader, 'NEC');
        SetSupplementalValues(IRS1099FormDocHeader, 0, 50, '101', '000');

        // [WHEN] Generate original-transmission XML.
        CreateSupplementalXml(Transmission, "Transmission Type IRIS"::O, false, TempBlob);

        // [THEN] Overtime is included but occupation-code elements are absent.
        VerifySupplementalXml(TempBlob, 'NEC', '5000', '0', '50');
        LibraryXPathXMLReader.VerifyXmlNodeAbsence('//n1:TreasuryTippedOccupationCd');
        VerifySavedSupplementalValues(IRS1099FormDocHeader, 0, 50, '101', '000');

        // [GIVEN] Restore positive tips without entering codes again.
        SetSupplementalValues(IRS1099FormDocHeader, 125, 50, '101', '000');

        // [WHEN] Generate another original transmission.
        CreateSupplementalXml(Transmission, "Transmission Type IRIS"::O, false, TempBlob);

        // [THEN] Saved codes appear, including leading zeros in 000.
        VerifySupplementalXml(TempBlob, 'NEC', '5000', '125', '50');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:Form1099NECDetail/n1:TreasuryTippedOccupationCd[2]', '000');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalRecipientUnionRejectsThirdDistinctCode()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        SecondIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A recipient cannot be reported with more than two distinct occupation codes across multiple documents.
        Initialize();

        // [GIVEN] Two documents for same recipient each have valid codes, but together have three distinct codes.
        CreateSupplementalTransmission(Transmission, IRS1099FormDocHeader, 'NEC');
        AddSupplementalHeader(IRS1099FormDocHeader, SecondIRS1099FormDocHeader, true);
        SetSupplementalValues(IRS1099FormDocHeader, 0.004, 0.006, '101', '000');
        SetSupplementalValues(SecondIRS1099FormDocHeader, 0.004, 0.006, '101', '102');

        // [WHEN] Try to generate XML.
        asserterror CreateSupplementalXml(Transmission, "Transmission Type IRIS"::O, false, TempBlob);

        // [THEN] Error identifies both documents instead of silently dropping third code.
        Assert.ExpectedError('more than two different Treasury tipped occupation codes for the same recipient');
        Assert.ExpectedError(Format(IRS1099FormDocHeader.ID));
        Assert.ExpectedError(Format(SecondIRS1099FormDocHeader.ID));
        Assert.ExpectedErrorCode('Dialog');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalXmlRejectsPopulatedUnknownMapping()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        SupplementalBox: Record "IRS 1099 Suppl. Box";
        SupplementalLine: Record "IRS 1099 Doc. Suppl. Line";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] XML generation rejects a populated custom supplemental box without a supported mapping.
        Initialize();

        // [GIVEN] Document D has saved value in custom supplemental box with no supported XML mapping.
        CreateSupplementalTransmission(Transmission, IRS1099FormDocHeader, 'NEC');
        IRS1099FormDocHeader.Status := IRS1099FormDocHeader.Status::Open;
        IRS1099FormDocHeader.Modify();
        SupplementalBox."Period No." := '2026';
        SupplementalBox."Form No." := 'NEC';
        SupplementalBox."No." := 'CUSTOM';
        SupplementalBox."Parent Form Box No." := 'NEC-01';
        SupplementalBox.Insert(true);
        SupplementalLine."Document ID" := IRS1099FormDocHeader.ID;
        SupplementalLine.Validate("Supplemental Box No.", 'CUSTOM');
        SupplementalLine.Validate(Amount, 10);
        SupplementalLine.Insert(true);
        IRS1099FormDocHeader.Status := IRS1099FormDocHeader.Status::Released;
        IRS1099FormDocHeader.Modify();

        // [WHEN] Try to generate original-transmission XML.
        asserterror CreateSupplementalXml(Transmission, "Transmission Type IRIS"::O, false, TempBlob);

        // [THEN] Error identifies document D and unsupported supplemental box.
        Assert.ExpectedError(StrSubstNo(UnknownSupplementalErr, IRS1099FormDocHeader.ID));
        Assert.ExpectedError('contains values that cannot be reported in IRIS XML');
        Assert.ExpectedErrorCode('Dialog');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('AcceptMappingConfirmation')]
    procedure SupplementalLegacyContractRejectsPopulatedDisclosures()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Schema 2.0.3 cannot silently omit saved 2026 supplemental values.
        Initialize();

        // [GIVEN] 2026 document has saved tips, codes and overtime, but its period explicitly selects schema 2.0.3.
        CreateSupplementalTransmission(Transmission, IRS1099FormDocHeader, 'NEC');
        SetPeriodSchema('2026', "XML Schema Version IRIS"::"2.0.3");

        // [WHEN] Try to generate XML.
        asserterror CreateSupplementalXml(Transmission, "Transmission Type IRIS"::O, false, TempBlob);

        // [THEN] Error explains that selected schema does not support supplemental values.
        Assert.ExpectedError(StrSubstNo(LegacySupplementalErr, IRS1099FormDocHeader.ID));
        Assert.ExpectedError('2.0.3');
        Assert.ExpectedErrorCode('Dialog');
        VerifyMappingConfirmation('2026', '2026', '2.0.3');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalZeroCorrectionPreservesSavedSourceAndReference()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        UnselectedIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A zero correction changes only outgoing XML amounts, not saved income, supplemental values or accepted references.
        Initialize();

        // [GIVEN] D1 is selected for correction with accepted filing references; D2 is not selected.
        CreateSupplementalTransmission(Transmission, IRS1099FormDocHeader, 'NEC');
        AddSupplementalHeader(IRS1099FormDocHeader, UnselectedIRS1099FormDocHeader, false);
        SetSupplementalValues(UnselectedIRS1099FormDocHeader, 200, 75, '102', '103');
        SetCorrectionReference(IRS1099FormDocHeader);

        // [WHEN] Generate correction XML with zero amounts.
        CreateSupplementalXml(Transmission, "Transmission Type IRIS"::C, true, TempBlob);

        // [THEN] D1's outgoing income, tips and overtime are zero and codes are absent; D2 is excluded and saved source values and references remain unchanged.
        VerifySupplementalXml(TempBlob, 'NEC', '0', '0', '0');
        LibraryXPathXMLReader.VerifyXmlNodeAbsence('//n1:TreasuryTippedOccupationCd');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:TotalRecipientFormCnt', '1');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:PrevSubmittedRecRecipientGrp/*[1]', '0');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:PrevSubmittedRecRecipientGrp/*[2]', 'ACCEPTED|1|2');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:CorrectedInd', '1');
        VerifySavedSupplementalValues(IRS1099FormDocHeader, 100, 50, '101', '000');
        VerifySavedSupplementalValues(UnselectedIRS1099FormDocHeader, 200, 75, '102', '103');
        IRS1099FormDocHeader.Get(IRS1099FormDocHeader.ID);
        Assert.AreEqual('ACCEPTED', IRS1099FormDocHeader."IRIS Last Accepted Receipt ID", 'The accepted reference is not rewritten.');
        VerifyDocLineAmount(IRS1099FormDocHeader, 'NEC-01', 5000);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalCorrectionWithoutAcceptedReferenceFails()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A zero correction requires a saved accepted filing reference.
        Initialize();

        // [GIVEN] Document D is selected for correction but has no accepted reference.
        CreateSupplementalTransmission(Transmission, IRS1099FormDocHeader, 'MISC');
        IRS1099FormDocHeader."IRIS Needs Correction" := true;
        IRS1099FormDocHeader.Modify();

        // [WHEN] Try to generate zero correction.
        asserterror CreateSupplementalXml(Transmission, "Transmission Type IRIS"::C, true, TempBlob);

        // [THEN] Error blocks correction rather than creating accepted reference.
        Assert.ExpectedError('Last accepted receipt ID is missing');
        Assert.ExpectedErrorCode('Dialog');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalTwoStepResubmissionIsOriginal()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Step 2 sends a new original, not another correction, even when old accepted references are present.
        Initialize();

        // [GIVEN] Document D retains previously accepted zero-correction reference and is Released for Step 2.
        CreateSupplementalTransmission(Transmission, IRS1099FormDocHeader, 'MISC');
        SetCorrectionReference(IRS1099FormDocHeader);
        IRS1099FormDocHeader."IRIS Corrected to Zeros" := true;
        IRS1099FormDocHeader.Modify();

        // [WHEN] Generate Step 2 XML as new original transmission.
        CreateSupplementalXml(Transmission, "Transmission Type IRIS"::O, false, TempBlob);

        // [THEN] XML includes saved supplemental values and no previous-recipient correction group.
        VerifySupplementalXml(TempBlob, 'MISC', '5000', '100', '50');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:TransmissionTypeCd', 'O');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:CorrectedInd', '0');
        LibraryXPathXMLReader.VerifyXmlNodeAbsence('//n1:PrevSubmittedRecRecipientGrp');
        VerifySavedSupplementalValues(IRS1099FormDocHeader, 100, 50, '101', '000');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalXmlOrderIsIndependentOfConfiguredPrintOrder()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        StatementLine: Record "IRS 1099 Form Statement Line";
        TempBlob: Codeunit "Temp Blob";
        Lines: JsonArray;
        Line: JsonToken;
        Value: JsonToken;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Changing statement row order does not change the required XML element order.
        Initialize();

        // [GIVEN] Document's statement is configured to show overtime before cash tips.
        CreateSupplementalTransmission(Transmission, IRS1099FormDocHeader, 'NEC');
        StatementLine.SetRange("Period No.", '2026');
        StatementLine.SetRange("Form No.", 'NEC');
        StatementLine.DeleteAll(true);
        InsertSupplementalStatement('NEC-01D', 1, 'Overtime first');
        InsertSupplementalStatement('NEC-01C', 2, 'Codes second');
        InsertSupplementalStatement('NEC-01B', 3, 'Tips last');

        // [WHEN] Generate both statement data and transmission XML.
        Lines := LibraryIRS1099Document.GetStatementDataset(IRS1099FormDocHeader);
        CreateSupplementalXml(Transmission, "Transmission Type IRIS"::O, false, TempBlob);

        // [THEN] Statement follows configured row order, while XML still places tips before occupation codes and overtime.
        Assert.AreEqual(3, Lines.Count(), 'The configured supplemental rows are used.');
        Lines.Get(0, Line);
        Line.AsObject().Get('name', Value);
        Assert.AreEqual('NEC-01D - Overtime first', Value.AsValue().AsText(), 'Print ordering remains configurable.');
        VerifySupplementalXml(TempBlob, 'NEC', '5000', '100', '50');
        VerifySupplementalOrder('NEC');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalFieldsNeverLeakInto2025OrLegacyXml()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] 2025 XML keeps its original income fields and excludes the new 2026 supplemental fields in both schemas.
        Initialize();

        // [GIVEN] 2025 document uses schema 5.0.7.
        CreateContractTransmission(Transmission, IRS1099FormDocHeader, 2025);

        // [WHEN] Generate XML with schema 5.0.7.
        CreateSupplementalXml(Transmission, "Transmission Type IRIS"::O, false, TempBlob);

        // [THEN] No 2026 supplemental fields appear in recipient details or submission totals.
        VerifyNoSupplementalXml(TempBlob);
        VerifyContractManifest(TempBlob, '2025', '25TEST0001', '1');

        // [GIVEN] Change same period to schema 2.0.3.
        SetPeriodSchema('2025', "XML Schema Version IRIS"::"2.0.3");

        // [WHEN] Generate XML with schema 2.0.3.
        CreateSupplementalXml(Transmission, "Transmission Type IRIS"::O, false, TempBlob);

        // [THEN] Saved income is still reported, and supplemental fields remain absent.
        VerifyNoSupplementalXml(TempBlob);
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:SchemaVersionNum', '2.0.3');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:Form1099NECDetail/n1:NonemployeeCompensationAmt', '5000');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('AcceptMappingConfirmation')]
    procedure SupplementalFieldsUseFutureYearMappings()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] 2027 XML can use available 2026 mappings after confirmation while retaining the 2027 tax year and Software ID.
        Initialize();

        // [GIVEN] 2027 NEC document has income 5000, tips 100, overtime 50 and codes 101 and 000.

        CreateContractTransmission(Transmission, IRS1099FormDocHeader, 2027);
        SetSupplementalValues(IRS1099FormDocHeader, 100, 50, '101', '000');

        // [WHEN] Generate original XML and accept warning about using 2026 mappings.
        CreateSupplementalXml(Transmission, "Transmission Type IRIS"::O, false, TempBlob);

        // [THEN] XML reports those values in correct order with year 2027 and Software ID 27TEST0001; warning names mapping year 2026 and schema 5.0.7.
        VerifySupplementalXml(TempBlob, 'NEC', '5000', '100', '50');
        VerifySupplementalOrder('NEC');
        VerifyContractManifest(TempBlob, '2027', '27TEST0001', '0');
        VerifyMappingConfirmation('2027', '2026', '5.0.7');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalMappingsDoNotUseLaterYearResources()
    var
        Helper: Codeunit "Helper IRIS";
        ParentFormBoxNo: Code[20];
        ElementName: Text[100];
        ValueType: Enum "IRS 1099 Supplemental Type";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Mapping lookup can reuse an earlier resource for a future year, but never a later resource for an older year.
        Initialize();

        // [GIVEN] Occupation-code mappings are available for tax year 2026.

        // [WHEN] Look up NEC-01C first for 2027 and then for 2025.

        // [THEN] 2027 receives occupation-code mapping; 2025 receives no mapping and previous lookup's output values are cleared.
        Assert.IsTrue(Helper.GetMapping('2027', 'NEC', 'NEC-01C', ParentFormBoxNo, ElementName, ValueType),
            'Future years must use the available earlier mapping.');
        Assert.AreEqual(ValueType::"Occupation Codes", ValueType, 'Preserve the mapped value type.');
        Assert.IsFalse(Helper.GetMapping('2025', 'NEC', 'NEC-01C', ParentFormBoxNo, ElementName, ValueType),
            'Earlier years must not load a later resource.');
        Assert.AreEqual('', ParentFormBoxNo, 'An absent mapping must clear the previous parent.');
        Assert.AreEqual('', ElementName, 'An absent mapping must clear the previous XML element.');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler,ChangeConfigurationDuringMappingConfirmation')]
    procedure ActualAttemptPreservesConfigurationDuringConfirmation()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        FirstAttempt: Record "Transmission Log IRIS";
        SecondAttempt: Record "Transmission Log IRIS";
        Payload: Codeunit "Temp Blob";
        StoredPayload: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Changing configuration during filing consent affects the next attempt, not the attempt already being confirmed.
        Initialize();

        // [GIVEN] Unverified-year send starts with period schema override and that year's Software ID.
        CreateContractTransmission(Transmission, IRS1099FormDocHeader, 2027);
        InitializeOfflineTransport(Transmission);
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-SoftwareID-2027', '27TEST0001');

        // [WHEN] Change period override and provider configuration while accepting consent dialog.
        QueueOfflineSend();
        LibraryIRS1099IRIS.SendOriginal(Transmission);

        // [THEN] Current XML and saved history keep schema and Software ID selected before edit.
        FindLastAttempt(Transmission, FirstAttempt);
        Payload.FromRecord(FirstAttempt, FirstAttempt.FieldNo("Transmission Content"));
        VerifyContractManifest(Payload, '2027', '27TEST0001', '0');
        Assert.AreEqual('5.0.7', FirstAttempt."XML Schema Version", 'The attempt retains its selected schema.');
        Assert.AreEqual('ReportingPeriod', FirstAttempt."Schema Source", 'The attempt retains its selected source.');
        Assert.AreEqual('27TEST0001', FirstAttempt."Software ID", 'The attempt retains its selected identity.');
        VerifyAttemptEnvironment(FirstAttempt, Payload, 'T', 'TEST1', 'Sandbox');
        VerifyRequestPaths(1, 1, 'https://test.example/status');
        Assert.AreEqual('https://test.example/submit', OfflineRequestPaths.Get(2), 'Submission must use the sandbox endpoint.');
        VerifyRequestPaths(3, 4, 'https://test.example/status');
        StoredPayload := ReadAttemptContentBytes(FirstAttempt, 20);
        VerifyMappingConfirmation('2027', '2026', '5.0.7');

        // [WHEN] Start another attempt after override was cleared and provider settings changed.
        QueueOfflineSend();
        LibraryIRS1099IRIS.SendOriginal(Transmission);

        // [THEN] New attempt uses new settings, without rewriting earlier XML.
        FindLastAttempt(Transmission, SecondAttempt);
        Payload.FromRecord(SecondAttempt, SecondAttempt.FieldNo("Transmission Content"));
        InitXMLReader(Payload);
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:SchemaVersionNum', '2.0.3');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:TaxYr', '2027');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:SoftwareId', '27NEW0001');
        Assert.AreEqual('KeyVault', SecondAttempt."Schema Source", 'Only a later attempt observes the cleared override.');
        Assert.AreEqual('27NEW0001', SecondAttempt."Software ID", 'Only a later attempt observes the changed year ID.');
        VerifyAttemptEnvironment(SecondAttempt, Payload, 'T', 'TEST1', 'Sandbox');
        VerifyRequestPaths(5, 5, 'https://test.example/status');
        Assert.AreEqual('https://test.example/submit', OfflineRequestPaths.Get(6), 'A schema change must not change the sandbox endpoint.');
        Assert.AreEqual(8, OfflineRequestPaths.Count(), 'No extra submission is expected.');
        Assert.AreEqual(StoredPayload, ReadAttemptContentBytes(FirstAttempt, 20), 'Earlier attempt bytes are immutable.');
        VerifyMappingConfirmation('2027', '2026', '2.0.3');
        FinishOfflineTransport();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ChangeSchemaBeforePreflight,OfflineHttpHandler')]
    procedure ActualAttemptUsesCurrentSchemaForPreflightAndXml()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        Attempt: Record "Transmission Log IRIS";
        Payload: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A schema change during the Open-document warning applies to both data validation and XML generation.
        Initialize();

        // [GIVEN] 2026 transmission uses schema 5.0.7, has no contact email and includes Open document.
        CreateContractTransmission(Transmission, IRS1099FormDocHeader, 2026);
        AddOpenTransmissionDocument(IRS1099FormDocHeader);
        InitializeOfflineTransport(Transmission);
        UpdateCompanyContactInfo('Test Contact', '1234567890', '');
        Commit();

        // [WHEN] Change period to schema 2.0.3 while accepting Open-document warning.
        QueueOfflineSend();
        LibraryIRS1099IRIS.SendOriginal(Transmission);

        // [THEN] Both data validation and XML generation use 2.0.3, where email is optional, and send succeeds without retry.
        VerifyOpenDocumentConfirmation();
        VerifyMappingConfirmation('2026', '2026', '2.0.3');
        FindLastAttempt(Transmission, Attempt);
        Payload.FromRecord(Attempt, Attempt.FieldNo("Transmission Content"));
        InitXMLReader(Payload);
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:SchemaVersionNum', '2.0.3');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:TaxYr', '2026');
        Assert.AreEqual(4, OfflineRequestPaths.Count(), 'The send must proceed using the current schema.');
        FinishOfflineTransport();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('DeclineAndChangeAttemptConfiguration,OfflineHttpHandler')]
    procedure ActualCancelledAttemptRereadsConfigurationOnRetry()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        Attempt: Record "Transmission Log IRIS";
        Payload: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Retrying a cancelled send uses current settings and asks for confirmation again.
        Initialize();

        // [GIVEN] 2027 sandbox transmission starts with schema 5.0.7.
        CreateContractTransmission(Transmission, IRS1099FormDocHeader, 2027);
        InitializeOfflineTransport(Transmission);
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-SoftwareID-2027', '27TEST0001');
        Commit();

        // [WHEN] Change settings in warning dialog, then decline send.
        asserterror LibraryIRS1099IRIS.SendOriginal(Transmission);

        // [THEN] No send attempt or HTTP request is saved.
        Assert.AreEqual('', GetLastErrorText(), 'Declining cancels the send.');
        Assert.ExpectedErrorCode('Dialog');
        VerifyMappingConfirmation('2027', '2026', '5.0.7');
        Assert.IsTrue(Attempt.IsEmpty(), 'No cancelled attempt may be stored.');
        Assert.AreEqual(0, OfflineRequestPaths.Count(), 'Cancellation precedes all HTTP requests.');

        // [GIVEN] After cancellation rolls back, explicitly select different schema for next send.
        SetPeriodSchema('2027', "XML Schema Version IRIS"::"2.0.3");

        // [WHEN] Retry same transmission and accept its warning.
        QueueOfflineSend();
        LibraryIRS1099IRIS.SendOriginal(Transmission);

        // [THEN] New warning and XML use newly selected schema and year-specific Software ID.
        VerifyMappingConfirmation('2027', '2026', '2.0.3');
        FindLastAttempt(Transmission, Attempt);
        Payload.FromRecord(Attempt, Attempt.FieldNo("Transmission Content"));
        InitXMLReader(Payload);
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:SchemaVersionNum', '2.0.3');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:SoftwareId', '27NEW0001');
        VerifyAttemptEnvironment(Attempt, Payload, 'T', 'TEST1', 'Sandbox');
        Assert.AreEqual('https://test.example/submit', OfflineRequestPaths.Get(2), 'The new send still uses the sandbox endpoint.');
        VerifyRequestPaths(3, 4, 'https://test.example/status');
        FinishOfflineTransport();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('AcceptMappingConfirmation')]
    procedure UnverifiedYearConfirmsOnceAcrossPreflightAndDocuments()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        SecondIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        TempIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header" temporary;
        IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
        IRSFormsFacade: Codeunit "IRS Forms Facade";
        TempBlob: Codeunit "Temp Blob";
        UniqueTransmissionId: Text[100];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] One generation operation asks once before reusing mappings, but each later operation asks again.
        Initialize();

        // [GIVEN] Two 2027 documents use available 2026 mappings.
        CreateContractTransmission(Transmission, IRS1099FormDocHeader, 2027);
        SecondIRS1099FormDocHeader := IRS1099FormDocHeader;
        SecondIRS1099FormDocHeader.ID := 0;
        SecondIRS1099FormDocHeader.Insert();
        IRS1099FormDocLine.SetRange("Document ID", IRS1099FormDocHeader.ID);
        IRS1099FormDocLine.FindFirst();
        IRS1099FormDocLine."Document ID" := SecondIRS1099FormDocHeader.ID;
        IRS1099FormDocLine.Insert();

        // [WHEN] Validate data twice and generate XML for both documents in one operation.
        IRSFormsFacade.CheckDataToReport(Transmission);
        IRSFormsFacade.CheckDataToReport(Transmission);
        IRSFormsFacade.CreateTransmissionXmlContent(Transmission, "Transmission Type IRIS"::O, false, UniqueTransmissionId, TempIRS1099FormDocHeader, TempBlob);

        // [THEN] One warning names reused mappings, and XML retains requested tax year and Software ID.
        VerifyMappingConfirmation('2027', '2026', '5.0.7');
        VerifyContractManifest(TempBlob, '2027', '27TEST0001', '0');
        Assert.AreEqual(2, TempIRS1099FormDocHeader.Count(), 'Both selected documents must use the same consent.');

        // [WHEN] Start another operation with same transmission and generator.
        Clear(TempBlob);
        IRSFormsFacade.CreateTransmissionXmlContent(Transmission, "Transmission Type IRIS"::O, false, UniqueTransmissionId, TempIRS1099FormDocHeader, TempBlob);

        // [THEN] New confirmation is required even though settings are unchanged.
        VerifyMappingConfirmation('2027', '2026', '5.0.7');

        // [WHEN] Start later operation with different schema.
        SetPeriodSchema('2027', "XML Schema Version IRIS"::"2.0.3");
        Clear(TempBlob);
        IRSFormsFacade.CreateTransmissionXmlContent(Transmission, "Transmission Type IRIS"::O, false, UniqueTransmissionId, TempIRS1099FormDocHeader, TempBlob);

        // [THEN] New warning names newly selected schema version.
        VerifyMappingConfirmation('2027', '2026', '2.0.3');
        InitXMLReader(TempBlob);
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:SchemaVersionNum', '2.0.3');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:TaxYr', '2027');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:SoftwareId', '27TEST0001');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('DeclineMappingConfirmation')]
    procedure DeclinedMappingLeavesAttemptAndDocumentsUnchanged()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        TempIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header" temporary;
        TempBlob: Codeunit "Temp Blob";
        IRSFormsFacade: Codeunit "IRS Forms Facade";
        UniqueTransmissionId: Text[100];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Declining mapping reuse cancels generation before XML, filing IDs or history are saved.
        Initialize();

        // [GIVEN] Released document for unverified year has no new attempt or filing IDs.
        CreateContractTransmission(Transmission, IRS1099FormDocHeader, 2027);
        UniqueTransmissionId := 'UNCHANGED';
        Commit();

        // [WHEN] Decline warning before generating XML.
        asserterror IRSFormsFacade.CreateTransmissionXmlContent(Transmission, "Transmission Type IRIS"::O, false, UniqueTransmissionId, TempIRS1099FormDocHeader, TempBlob);

        // [THEN] No XML or attempt history is created, and document stays Released with its original values.
        Assert.AreEqual('', GetLastErrorText(), 'Declining must cancel, not report a filing success.');
        Assert.ExpectedErrorCode('Dialog');
        Assert.AreEqual('UNCHANGED', UniqueTransmissionId, 'Cancellation must precede UTID creation.');
        VerifyCancelledXmlCreationLeavesNoChanges(IRS1099FormDocHeader, TempIRS1099FormDocHeader, TempBlob);
        VerifyMappingConfirmation('2027', '2026', '5.0.7');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure MissingRequestedYearSoftwareIdBlocksBeforeMappingConfirmation()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        TempIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header" temporary;
        TempBlob: Codeunit "Temp Blob";
        IRSFormsFacade: Codeunit "IRS Forms Facade";
        UniqueTransmissionId: Text[100];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A missing Software ID for the requested year blocks generation before the mapping-reuse warning.
        Initialize();

        // [GIVEN] 2027 can reuse available mappings, but only 2026 Software ID is configured.
        CreateContractTransmission(Transmission, IRS1099FormDocHeader, 2027);
        InitializeStandardProvider();
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-SoftwareID-2026', '26TEST0001');
        Commit();

        // [WHEN] Try to generate XML for 2027.
        asserterror IRSFormsFacade.CreateTransmissionXmlContent(Transmission, "Transmission Type IRIS"::O, false, UniqueTransmissionId, TempIRS1099FormDocHeader, TempBlob);

        // [THEN] Missing 2027 Software ID error is raised before any confirmation to reuse mappings.
        Assert.ExpectedError('Software ID');
        Assert.ExpectedErrorCode('Dialog');
        VerifyCancelledXmlCreationLeavesNoChanges(IRS1099FormDocHeader, TempIRS1099FormDocHeader, TempBlob);
        ResetStandardProvider();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('AcceptMappingConfirmation')]
    procedure UnverifiedEarlierYearNamesItsActualResource()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A warning for an unverified older year identifies the mapping resource actually used.
        Initialize();

        // [GIVEN] Tax year 2024 uses schema 5.0.7 but is not verified for that schema.
        CreateContractTransmission(Transmission, IRS1099FormDocHeader, 2024);

        // [WHEN] Accept warning to generate XML using its available resource.
        CreateSupplementalXml(Transmission, "Transmission Type IRIS"::O, false, TempBlob);

        // [THEN] Warning names actual older resource, and XML keeps year 2024 and its matching Software ID.
        VerifyMappingConfirmation('2024', '2024', '5.0.7');
        VerifyContractManifest(TempBlob, '2024', '24TEST0001', '1');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure MissingMappingCannotBeConfirmed()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A year with no usable mapping resource fails without offering confirmation to bypass the error.
        Initialize();

        // [GIVEN] No mapping resource exists for tax year 2023 or earlier usable year.
        CreateContractTransmission(Transmission, IRS1099FormDocHeader, 2023);

        // [WHEN] Try to generate XML without confirmation handler.
        asserterror CreateSupplementalXml(Transmission, "Transmission Type IRIS"::O, false, TempBlob);

        // [THEN] Missing-resource error stops generation; no substitute mapping is chosen.
        Assert.ExpectedError('The resource file for the period 2023 is not found');
        Assert.ExpectedErrorCode('Dialog');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ErrorMessagesPageHandler')]
    procedure NewContract2026PreflightRequiresContactEmail()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        IRSFormsFacade: Codeunit "IRS Forms Facade";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] 2026 data validation with schema 5.0.7 requires a contact email address.
        Initialize();

        // [GIVEN] 2026 transmission has valid contact name and phone number but no email.
        CreateContractTransmission(Transmission, IRS1099FormDocHeader, 2026);
        UpdateCompanyContactInfo('Test Contact', '1234567890', '');

        // [WHEN] Run CheckDataToReport through IRS Forms Facade.
        asserterror IRSFormsFacade.CheckDataToReport(Transmission);

        // [THEN] Error Messages page reports Email must be set, and validation cancels operation.
        Assert.AreEqual('', GetLastErrorText(), 'Preflight shows the structured errors before cancelling.');
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedMessage('Email must be set.', LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure NewContract2025PreflightKeepsEmailOptional()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        IRSFormsFacade: Codeunit "IRS Forms Facade";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] 2025 data validation with schema 5.0.7 keeps contact email optional.
        Initialize();

        // [GIVEN] 2025 transmission uses schema 5.0.7 and has no contact email.
        CreateContractTransmission(Transmission, IRS1099FormDocHeader, 2025);
        UpdateCompanyContactInfo('Test Contact', '1234567890', '');

        // [WHEN] Run CheckDataToReport through IRS Forms Facade.
        IRSFormsFacade.CheckDataToReport(Transmission);

        // [THEN] Validation succeeds without contact-email error.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler,ConfirmYes')]
    procedure ActualTwoStep2026NecPreservesSupplementalSource()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] The 2026 NEC two-step workflow sends zeros first and then a new original without changing saved supplemental values.
        Initialize();

        // [GIVEN] Accepted 2026 NEC document D1 is selected for zero correction; D2 is not selected.

        // [WHEN] Send zero correction, simulate IRS acceptance, then use Step 2 Send Corrected Original with newly prepared document.
        VerifyActualTwoStep(2026, 'NEC');

        // [THEN] Only D1 is zero-corrected and Abandoned; Step 2 sends new original with saved amounts, while old source values and unselected D2 remain intact.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler,ConfirmYes')]
    procedure ActualTwoStep2026MiscPreservesSupplementalSource()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] The 2026 MISC two-step workflow keeps saved tips, codes and overtime through zero correction and a new original.
        Initialize();

        // [GIVEN] Accepted 2026 MISC document D1 is selected for zero correction; D2 is not selected.

        // [WHEN] Send zero correction, simulate IRS acceptance, then use Step 2 Send Corrected Original with newly prepared document.
        VerifyActualTwoStep(2026, 'MISC');

        // [THEN] Step 1 sends zeros, Step 2 sends new original amounts, and old source's supplemental values and accepted references remain unchanged.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler,ConfirmYes')]
    procedure ActualTwoStep2025NecRetainsOriginalSemantics()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] The 2025 NEC two-step workflow sends a zero correction followed by a new original without supplemental fields.
        Initialize();

        // [GIVEN] Accepted 2025 NEC document D1 is selected for zero correction; D2 is not selected.

        // [WHEN] Send zero correction, simulate IRS acceptance, then use Step 2 Send Corrected Original with newly prepared document.
        VerifyActualTwoStep(2025, 'NEC');

        // [THEN] Step 1 references accepted original; Step 2 has original-transmission XML, and saved source values and unselected D2 remain intact.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler')]
    procedure ActualWholeReplacementReferencesRejectedReceipt()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A full replacement references the rejected transmission's receipt once at transmission level.
        Initialize();

        // [GIVEN] 2026 transmission has rejected NEC and MISC submissions and saved original receipt.

        // [WHEN] Send replacement for both rejected submissions.
        VerifyActualReplacement(2026, "Transmission Status IRIS"::Rejected, false);

        // [THEN] XML includes both submissions and original receipt at transmission level, without per-submission or correction references.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler')]
    procedure ActualPartialReplacementExcludesAcceptedSubmission()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A partial replacement sends only the rejected submission and references its original submission ID.
        Initialize();

        // [GIVEN] 2026 transmission has rejected NEC and accepted MISC submissions with saved original references.

        // [WHEN] Send replacement.
        VerifyActualReplacement(2026, "Transmission Status IRIS"::"Partially Accepted", true);

        // [THEN] Only NEC is sent with its original submission reference and saved values; accepted MISC remains unchanged.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler')]
    procedure ActualReplacementAfterAcceptedCorrectionExcludesAcceptedSubmission()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Replacing a still-rejected submission after another correction was accepted does not resend the accepted submission.
        Initialize();

        // [GIVEN] 2026 transmission's latest status is Accepted, but NEC remains rejected and MISC is accepted.

        // [WHEN] Send replacement for remaining rejected submission.
        VerifyActualReplacement(2026, "Transmission Status IRIS"::Accepted, true);

        // [THEN] Only NEC is sent using its original submission reference; accepted MISC is neither sent nor changed.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler')]
    procedure Actual2025WholeReplacementPreservesReferences()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A full 2025 replacement keeps the original receipt reference and includes both rejected submissions.
        Initialize();

        // [GIVEN] 2025 transmission has rejected NEC and MISC submissions and saved original receipt.

        // [WHEN] Send replacement for both submissions.
        VerifyActualReplacement(2025, "Transmission Status IRIS"::Rejected, false);

        // [THEN] XML includes both submissions with transmission-level original receipt reference, no correction references and unchanged source values.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler')]
    procedure Actual2025PartialReplacementExcludesAcceptedSubmission()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A partial 2025 replacement excludes an already accepted submission.
        Initialize();

        // [GIVEN] 2025 transmission has rejected NEC and accepted MISC submissions.

        // [WHEN] Send replacement.
        VerifyActualReplacement(2025, "Transmission Status IRIS"::"Partially Accepted", true);

        // [THEN] Only NEC is sent with its original submission reference; accepted MISC and saved source values remain unchanged.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler')]
    procedure Actual2026NecManualCorrectionPreservesUnselectedSource()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A 2026 NEC correction sends edited values only for the selected document.
        Initialize();

        // [GIVEN] Accepted NEC document D1 is selected and edited to income 6000, tips 120 and overtime 60; accepted D2 is not selected.

        // [WHEN] Send correction with nonzero amounts.
        VerifyActualNonzeroCorrection(2026, 'NEC');

        // [THEN] D1's edited values and accepted reference appear in XML, its new accepted receipt is saved, and D2 remains unchanged.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler')]
    procedure Actual2026MiscManualCorrectionPreservesUnselectedSource()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A 2026 MISC correction sends edited values only for the selected document.
        Initialize();

        // [GIVEN] Accepted MISC document D1 is selected and edited to income 6000, tips 120 and overtime 60; accepted D2 is not selected.

        // [WHEN] Send correction with nonzero amounts.
        VerifyActualNonzeroCorrection(2026, 'MISC');

        // [THEN] D1's edited values and accepted reference appear in XML, its new accepted receipt is saved, and D2 remains unchanged.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler')]
    procedure Actual2025NecManualCorrectionPreservesUnselectedSource()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A 2025 NEC correction sends edited income only for the selected document.
        Initialize();

        // [GIVEN] Accepted NEC document D1 is selected and edited to income 6000; accepted D2 is not selected.

        // [WHEN] Send correction with nonzero amounts.
        VerifyActualNonzeroCorrection(2025, 'NEC');

        // [THEN] XML includes only D1 with income 6000 and its accepted reference, without changing D2 or treating D1 as zero correction.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler')]
    procedure ActualHistoryDownloadsSelectedAttemptBytesWithoutRegeneration()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        TransmissionLog: Record "Transmission Log IRIS";
        HistoryPage: TestPage "Transmission Logs IRIS";
        PayloadBytes: Text;
        ResponseBytes: Text;
        AcknowledgmentBytes: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] History downloads return the exact saved request, response and acknowledgment without regenerating them.
        Initialize();

        // [GIVEN] 2026 NEC transmission is ready to send using simulated HTTP responses.
        CreateLifecycleTransmission(Transmission, IRS1099FormDocHeader, 2026, 'NEC');
        InitializeOfflineTransport(Transmission);

        // [WHEN] Send it, change current schema and income, then download its saved request, response and acknowledgment from history.
        QueueOfflineSend();
        LibraryIRS1099IRIS.SendOriginal(Transmission);
        FindLastAttempt(Transmission, TransmissionLog);
        PayloadBytes := ReadAttemptContentBytes(TransmissionLog, 20);
        ResponseBytes := ReadAttemptContentBytes(TransmissionLog, 30);
        AcknowledgmentBytes := ReadAttemptContentBytes(TransmissionLog, 40);

        SetPeriodSchema('2026', "XML Schema Version IRIS"::" ");
        SetDocLineAmount(IRS1099FormDocHeader, 'NEC-01', 9000, 0);
        LibraryFileMgtHandler.SetBeforeDownloadFromStreamHandlerActivated(true);
        BindSubscription(LibraryFileMgtHandler);
        HistoryPage.OpenView();
        HistoryPage.GoToRecord(TransmissionLog);
        HistoryPage.DownloadTransmContent.Invoke();

        // [THEN] Each download matches saved bytes and attempt ID, with no XML rewrite or extra HTTP requests.
        VerifyCapturedDownload(PayloadBytes, 'Transmission_', TransmissionLog."Unique Transmission ID");
        HistoryPage.DownloadRespContent.Invoke();
        VerifyCapturedDownload(ResponseBytes, 'Response_', TransmissionLog."Unique Transmission ID");
        HistoryPage.DownloadAcknowledgContent.Invoke();
        VerifyCapturedDownload(AcknowledgmentBytes, 'Acknowledgement_', TransmissionLog."Unique Transmission ID");
        HistoryPage.Close();
        UnbindSubscription(LibraryFileMgtHandler);
        Assert.AreEqual(4, OfflineRequestPaths.Count(), 'Downloads do not regenerate, authenticate or make another request.');
        Assert.AreEqual(PayloadBytes, ReadAttemptContentBytes(TransmissionLog, 20), 'Downloads never rewrite stored XML.');
        FinishOfflineTransport();

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler')]
    procedure ActualRecordErrorAcknowledgmentRetainsSupplementalSource()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        ErrorInformation: Record "Error Information IRIS";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A record-level acknowledgment error is saved without changing supplemental values or resending.
        Initialize();

        // [GIVEN] 2026 NEC document has saved supplemental values, and simulated acknowledgment returns Accepted with Errors and record error.
        CreateLifecycleTransmission(Transmission, IRS1099FormDocHeader, 2026, 'NEC');
        InitializeOfflineTransport(Transmission);
        OfflineStatus := 'Accepted with Errors';
        OfflineSubmissionStatuses.Add('1', OfflineStatus);
        OfflineRecordError := true;

        // [WHEN] Send original transmission.
        QueueOfflineSend();
        LibraryIRS1099IRIS.SendOriginal(Transmission);

        // [THEN] Transmission is Accepted with Errors, document is In Progress, error is linked to correct record, and saved values remain unchanged without resend.
        VerifyLifecycleStatus(Transmission, IRS1099FormDocHeader, "Transmission Status IRIS"::"Accepted with Errors", IRS1099FormDocHeader.Status::"In Progress");
        Assert.IsTrue(ErrorInformation.FindLast(), 'The actual acknowledgment creates a record error.');
        Assert.AreEqual(Transmission."Document ID", ErrorInformation."Transmission Document ID", 'Error belongs to this transmission.');
        Assert.AreEqual(IRS1099FormDocHeader."IRIS Submission ID", ErrorInformation."Submission ID", 'Error belongs to this submission.');
        Assert.AreEqual(IRS1099FormDocHeader."IRIS Record ID", ErrorInformation."Record ID", 'Error belongs to this record.');
        Assert.AreEqual('SIMULATED-RECORD', ErrorInformation."Error Code", 'Record error code is retained.');
        Assert.AreEqual('SIMULATED record disclosure error', ErrorInformation."Error Message", 'Actual parser retains record-level errors.');
        VerifyLifecycleSource(IRS1099FormDocHeader, 2026);
        Assert.AreEqual(4, OfflineRequestPaths.Count(), 'A record error does not trigger an automatic resend.');
        FinishOfflineTransport();

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler')]
    procedure ActualHistoryUsesCurrentEnvironmentWithoutRegeneration()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        TransmissionLog: Record "Transmission Log IRIS";
        StoredPayload: Text;
        StoredResponse: Text;
        StatusText: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Querying production history from a sandbox uses current sandbox endpoints without regenerating the old XML.
        Initialize();

        // [GIVEN] Transmission was sent in simulated production mode, with all HTTP requests intercepted by test.
        CreateLifecycleTransmission(Transmission, IRS1099FormDocHeader, 2026, 'NEC');
        InitializeOfflineTransport(Transmission);
        EnvironmentInfoTestLibrary.SetTestabilitySandbox(false);
        QueueOfflineSend();
        LibraryIRS1099IRIS.SendOriginal(Transmission);
        FindLastAttempt(Transmission, TransmissionLog);
        VerifyAttemptContext(TransmissionLog, 'P', 'Production');
        StoredPayload := ReadAttemptContentBytes(TransmissionLog, 20);
        StoredResponse := ReadAttemptContentBytes(TransmissionLog, 30);

        // [WHEN] Switch to sandbox, remove current schema configuration, and request status by receipt ID and unique transmission ID.
        EnvironmentInfoTestLibrary.SetTestabilitySandbox(true);
        SetPeriodSchema('2026', "XML Schema Version IRIS"::" ");
        OfflineStatus := 'Not Found';
        QueueOfflineAcknowledgment();
        LibraryIRS1099IRIS.RequestStatus(TransmissionLog."Receipt ID", TransmissionLog."Unique Transmission ID", StatusText);
        Assert.AreEqual('Not Found', StatusText, 'A not-found response does not trigger a production retry.');
        QueueOfflineAcknowledgment();
        LibraryIRS1099IRIS.RequestStatus('', TransmissionLog."Unique Transmission ID", StatusText);

        // [THEN] All requests use sandbox endpoints, while saved production request bytes and document values remain unchanged.
        VerifyRequestPaths(5, 8, 'https://test.example/status');
        Assert.AreEqual(8, OfflineRequestPaths.Count(), 'No cross-environment retry or automatic resend.');
        Assert.AreEqual(StoredPayload, ReadAttemptContentBytes(TransmissionLog, 20), 'Configuration changes never regenerate stored XML bytes.');
        Assert.AreEqual(StoredResponse, ReadAttemptContentBytes(TransmissionLog, 30), 'The original acceptance response bytes are retained.');
        Assert.AreEqual(OfflineAcknowledgment, ReadAttemptContent(TransmissionLog, 40), 'Stored acknowledgment is the actual intercepted response.');
        VerifyAttemptContext(TransmissionLog, 'P', 'Production');
        FinishOfflineTransport();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler')]
    procedure ActualAcknowledgmentsKeepLifecycleStatesDistinct()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        TransmissionPage: TestPage "Transmission IRIS";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Status polling distinguishes processing, rejection, partial acceptance and final acceptance without resending.
        Initialize();

        // [GIVEN] Send returns receipt but its first acknowledgment is not final.
        CreateLifecycleTransmission(Transmission, IRS1099FormDocHeader, 2026, 'NEC');
        InitializeOfflineTransport(Transmission);
        OfflineStatus := 'Processing';
        OfflineSubmissionStatuses.Add('1', 'Processing');
        QueueOfflineSend();
        LibraryIRS1099IRIS.SendOriginal(Transmission);
        VerifyLifecycleStatus(Transmission, IRS1099FormDocHeader, "Transmission Status IRIS"::Processing, "IRS 1099 Form Doc. Status"::"In Progress");
        TransmissionPage.OpenEdit();
        TransmissionPage.GoToRecord(Transmission);

        // [WHEN] Use Request Status to process simulated acknowledgments for each lifecycle state.
        VerifyStatusAction(TransmissionPage, Transmission, IRS1099FormDocHeader, 'Rejected', "Transmission Status IRIS"::Rejected, "IRS 1099 Form Doc. Status"::"In Progress");
        VerifyStatusAction(TransmissionPage, Transmission, IRS1099FormDocHeader, 'Partially Accepted', "Transmission Status IRIS"::"Partially Accepted", "IRS 1099 Form Doc. Status"::"In Progress");
        VerifyStatusAction(TransmissionPage, Transmission, IRS1099FormDocHeader, 'Accepted with Errors', "Transmission Status IRIS"::"Accepted with Errors", "IRS 1099 Form Doc. Status"::"In Progress");
        VerifyStatusAction(TransmissionPage, Transmission, IRS1099FormDocHeader, 'Accepted', "Transmission Status IRIS"::Accepted, "IRS 1099 Form Doc. Status"::Submitted);

        // [THEN] Each status is handled distinctly, with no new submission or loss of saved supplemental values.
        Assert.AreEqual(12, OfflineRequestPaths.Count(), 'Four polls each have a validity probe, not another submission.');
        VerifyRequestPaths(5, 12, 'https://test.example/status');
        VerifySavedSupplementalValues(IRS1099FormDocHeader, 100, 50, '101', '000');
        TransmissionPage.Close();
        FinishOfflineTransport();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler,ConfirmYes,RecoveredReceiptHandler')]
    procedure ActualPreReceiptFailureUsesUtidAndManualReceiptRecovery()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        TransmissionLog: Record "Transmission Log IRIS";
        ErrorInformation: Record "Error Information IRIS";
        TransmissionPage: TestPage "Transmission IRIS";
        StoredPayload: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A failure before a usable receipt is obtained keeps the unique transmission ID available for status recovery.
        Initialize();

        // [GIVEN] Sender receives simulated schema-validation failure before usable receipt is obtained.
        CreateLifecycleTransmission(Transmission, IRS1099FormDocHeader, 2026, 'NEC');
        InitializeOfflineTransport(Transmission);
        OfflinePreReceiptError := true;
        OfflineStatus := 'Rejected';
        QueueOfflineSend();
        LibraryIRS1099IRIS.SendOriginal(Transmission);
        FindLastAttempt(Transmission, TransmissionLog);
        StoredPayload := ReadAttemptContent(TransmissionLog, 20);

        // [THEN] Response is not treated as final acceptance of document or transmission.
        Assert.AreEqual('', Transmission."Receipt ID", 'Pre-receipt failure cannot assign a usable receipt.');
        Assert.AreEqual("Transmission Status IRIS"::None, Transmission.Status, 'Pre-receipt failure is not ordinary rejection.');
        ErrorInformation.SetRange("Transmission Document ID", Transmission."Document ID");
        ErrorInformation.SetRange("Error Code", 'XML Schema Validation Error');
        Assert.RecordIsNotEmpty(ErrorInformation);

        // [WHEN] Request status by unique transmission ID and manually assign recovered receipt through transmission page.
        TransmissionPage.OpenEdit();
        TransmissionPage.GoToRecord(Transmission);
        QueueOfflineAcknowledgment();
        TransmissionPage.RequestTransmissionStatusByUTID.Invoke();
        OfflinePreReceiptError := false;
        OfflineStatus := 'Processing';
        TransmissionPage.AssignReceiptIDManually.Invoke();
        QueueOfflineAcknowledgment();
        TransmissionPage.RequestTransmissionStatusByRID.Invoke();

        // [THEN] Recovery uses same request and saved XML without blindly resending original.
        Transmission.Get(Transmission."Document ID");
        Assert.AreEqual(OfflineReceiptID, Transmission."Receipt ID", 'Explicit recovered receipt is assigned.');
        Assert.AreEqual("Transmission Status IRIS"::Processing, Transmission.Status, 'Recovered receipt can be polled.');
        Assert.AreEqual(8, OfflineRequestPaths.Count(), 'Recovery does not send another payload.');
        Assert.AreEqual(StoredPayload, ReadAttemptContent(TransmissionLog, 20), 'Recovery retains exact original payload bytes.');
        VerifySavedSupplementalValues(IRS1099FormDocHeader, 100, 50, '101', '000');
        TransmissionPage.Close();
        FinishOfflineTransport();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler,OfflineErrorMessageHandler')]
    procedure FailedZeroCorrectionCannotCompletePreviouslyAcceptedDocuments()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A failed zero-correction send cannot reuse the original filing's accepted status to mark the document zero-corrected.
        Initialize();

        // [GIVEN] Document D was accepted before its selected zero-correction attempt.

        // [WHEN] Send zero correction and simulate HTTP 503 Service Unavailable.
        QueueOfflineSubmission();
        VerifyUnacceptedZeroCorrection(503, 'Accepted');

        // [THEN] Old accepted filing does not make failed correction complete or abandon document D.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler')]
    procedure ProcessingZeroCorrectionCompletesOnlyAfterAcceptedPoll()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A zero correction completes only after IRS acceptance, not while Processing.
        Initialize();

        // [GIVEN] Document D was accepted before its selected zero-correction attempt.

        // [WHEN] Send correction with Processing acknowledgment, then poll status with Accepted acknowledgment.
        QueueOfflineSend();
        VerifyUnacceptedZeroCorrection(200, 'Processing');

        // [THEN] Processing leaves correction pending; later acceptance completes it once.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure NormalOnPremStillRejectsAllThreeSendOperations()
    var
        Transmission: Record "Transmission IRIS";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Original, replacement and correction sends remain SaaS-only in an ordinary on-premises environment.
        Initialize();

        // [GIVEN] Environment is on-premises and is not simulated as SaaS.

        // [WHEN] Try each of three send operations.
        asserterror LibraryIRS1099IRIS.SendOriginal(Transmission);

        // [THEN] Each operation fails with existing SaaS-only error before authentication or HTTP transport.
        Assert.ExpectedError('only be sent electronically in the SaaS environment');
        Assert.ExpectedErrorCode('Dialog');
        asserterror LibraryIRS1099IRIS.SendReplacement(Transmission);
        Assert.ExpectedError('only be sent electronically in the SaaS environment');
        Assert.ExpectedErrorCode('Dialog');
        asserterror LibraryIRS1099IRIS.SendCorrection(Transmission, false);
        Assert.ExpectedError('only be sent electronically in the SaaS environment');
        Assert.ExpectedErrorCode('Dialog');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler')]
    procedure RecoveredReceiptCompletesOnlyTheNonzeroRetry()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A receipt recovered from acknowledgment belongs to the current retry, not an older zero correction.
        Initialize();

        // [GIVEN] Document D has rejected zero correction and new nonzero retry whose receipt appears only in acknowledgment.
        CreateRejectedZeroCorrection(Transmission, IRS1099FormDocHeader);
        OfflineReceiptID := 'ACCEPTED-NONZERO';
        OfflineStatus := 'Accepted';
        OfflineSubmissionStatuses.Set('1', 'Accepted');

        // [WHEN] Send nonzero retry.
        QueueOfflineSubmissionWithoutReceipt();
        QueueOfflineAcknowledgment();
        LibraryIRS1099IRIS.SendCorrection(Transmission, false);

        // [THEN] Retry's receipt is saved and only that retry completes; document D is not Abandoned as though old zero correction succeeded.
        VerifyRecoveredNonzeroCorrection(Transmission, IRS1099FormDocHeader);
        FinishOfflineTransport();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler')]
    procedure DelayedAcceptancePreservesReleasedCorrectionEdits()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Late acceptance of a zero correction does not overwrite newer Released values.
        Initialize();

        // [GIVEN] Document D has pending zero correction and newer supplemental values that are already Released.
        CreatePendingZeroCorrection(Transmission, IRS1099FormDocHeader);
        ReopenAndEditPendingCorrection(IRS1099FormDocHeader);
        LibraryIRS1099Document.ReleaseDocument(IRS1099FormDocHeader);

        // [WHEN] Process acceptance of older zero correction.
        RequestAcceptedCorrection(Transmission);

        // [THEN] Newer Released values remain unsent and selected for correction.
        VerifyPendingCorrectionEdits(Transmission, IRS1099FormDocHeader, IRS1099FormDocHeader.Status::Released);
        Assert.IsTrue(IRS1099FormDocHeader."IRIS Updated Not Sent", 'Newer released values must remain unsent.');
        FinishOfflineTransport();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler')]
    procedure DelayedAcceptancePreservesOpenCorrectionEdits()
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Late acceptance of a zero correction does not close a document with newer Open edits.
        Initialize();

        // [GIVEN] Document D has pending zero correction and newer supplemental values still being edited.
        CreatePendingZeroCorrection(Transmission, IRS1099FormDocHeader);
        ReopenAndEditPendingCorrection(IRS1099FormDocHeader);

        // [WHEN] Process acceptance of older zero correction.
        RequestAcceptedCorrection(Transmission);

        // [THEN] Document D stays Open, keeping newer values selected for correction.
        VerifyPendingCorrectionEdits(Transmission, IRS1099FormDocHeader, IRS1099FormDocHeader.Status::Open);
        FinishOfflineTransport();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler,SelectIncomeUpdateHandler,UpdateTransmissionMessageHandler')]
    procedure DelayedAcceptancePreservesTransmissionUpdateEdits()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        IRS1099VendorFormBoxAdj: Record "IRS 1099 Vendor Form Box Adj.";
        Transmission: Record "Transmission IRIS";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Late acknowledgment does not mark income recalculated after a zero-correction send as already sent.
        Initialize();

        // [GIVEN] Document D has pending zero correction and selected income recalculation to 6000.
        CreatePendingZeroCorrection(Transmission, IRS1099FormDocHeader);
        IRS1099VendorFormBoxAdj.Validate("Period No.", IRS1099FormDocHeader."Period No.");
        IRS1099VendorFormBoxAdj.Validate("Vendor No.", IRS1099FormDocHeader."Vendor No.");
        IRS1099VendorFormBoxAdj.Validate("Form No.", IRS1099FormDocHeader."Form No.");
        IRS1099VendorFormBoxAdj.Validate("Form Box No.", 'NEC-01');
        IRS1099VendorFormBoxAdj.Validate(Amount, 6000);
        IRS1099VendorFormBoxAdj.Insert(true);
        Commit();
        LibraryVariableStorage.Enqueue(IRS1099FormDocHeader."Vendor No.");
        LibraryIRS1099Document.UpdateTransmission(Transmission);

        // [WHEN] Process acceptance of older zero correction.
        RequestAcceptedCorrection(Transmission);

        // [THEN] New income remains unsent, and document D is not Abandoned.
        VerifyPendingTransmissionUpdate(IRS1099FormDocHeader);
        FinishOfflineTransport();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler')]
    procedure RepeatedAcceptancePreservesAbandonedZeroCorrection()
    var
        Transmission: Record "Transmission IRIS";
        DocHeader: Record "IRS 1099 Form Doc. Header";
        AcceptedModifiedAt: DateTime;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Polling the same accepted zero correction again does not reopen its Abandoned document.
        Initialize();

        // [GIVEN] Document D was already Abandoned after its zero correction was accepted.
        CreatePendingZeroCorrection(Transmission, DocHeader);
        RequestAcceptedCorrection(Transmission);
        DocHeader.Get(DocHeader.ID);
        AcceptedModifiedAt := DocHeader.SystemModifiedAt;

        // [WHEN] Request same acknowledgment again.
        RequestAcceptedCorrection(Transmission);

        // [THEN] Document D stays Abandoned, and its saved history is not rewritten.
        VerifyAcceptedZeroCorrection(DocHeader);
        Assert.AreEqual(AcceptedModifiedAt, DocHeader.SystemModifiedAt, 'Repeated acceptance must not rewrite the abandoned source.');
        FinishOfflineTransport();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler')]
    procedure TwoStepZeroCorrectionWaitsForAcceptedAcknowledgment()
    var
        Transmission: Record "Transmission IRIS";
        DocHeader: Record "IRS 1099 Form Doc. Header";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Step 1 keeps a zero correction pending until an Accepted acknowledgment is received.
        Initialize();

        // [GIVEN] Document D is accepted, and next simulated acknowledgment is Processing.
        CreateAcceptedCorrectionSource(Transmission, DocHeader);
        DocHeader."IRIS Needs Correction" := false;
        DocHeader.Modify();
        OfflineStatus := 'Processing';
        OfflineSubmissionStatuses.Add('1', 'Processing');

        // [WHEN] Run send operation used by Step 1 and later poll Accepted acknowledgment.
        QueueOfflineSend();
        LibraryIRS1099IRIS.SendTwoStepZeroCorrection(Transmission);

        // [THEN] Document D remains pending while Processing and completes zero correction only after acceptance.
        VerifyPendingZeroCorrection(DocHeader);
        RequestAcceptedCorrection(Transmission);
        VerifyAcceptedZeroCorrection(DocHeader);
        FinishOfflineTransport();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler,SelectNewBoxUpdateHandler,UpdateTransmissionMessageHandler')]
    procedure OriginalAcknowledgmentPreservesUnsentReplacement()
    var
        Transmission: Record "Transmission IRIS";
        DocHeader: Record "IRS 1099 Form Doc. Header";
        ReplacementDocHeader: Record "IRS 1099 Form Doc. Header";
        ReplacementModifiedAt: DateTime;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Replaying an old acknowledgment does not update a replacement document that was not in that send attempt.
        Initialize();

        // [GIVEN] Accepted source document has new box, creating unsent replacement with inherited filing references.
        CreateLifecycleTransmission(Transmission, DocHeader, 2026, 'NEC');
        InitializeOfflineTransport(Transmission);
        QueueOfflineSend();
        LibraryIRS1099IRIS.SendOriginal(Transmission);
        SetTransmissionUpdateAdjustment(DocHeader, 'NEC-01', 5000);
        SetTransmissionUpdateAdjustment(DocHeader, 'NEC-03', 7000);
        Commit();
        LibraryVariableStorage.Enqueue(DocHeader."Vendor No.");
        LibraryIRS1099Document.UpdateTransmission(Transmission);
        FindUnsentReplacement(DocHeader, ReplacementDocHeader);
        ReplacementModifiedAt := ReplacementDocHeader.SystemModifiedAt;

        // [WHEN] Process original send's Accepted acknowledgment again.
        RequestAcceptedCorrection(Transmission);

        // [THEN] Replacement remains unsent and unchanged because old attempt did not contain it.
        VerifyUnsentReplacement(ReplacementDocHeader, ReplacementModifiedAt);
        FinishOfflineTransport();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure AcceptedCorrectionKeepsRejectedReplacementAvailable()
    var
        Transmission: Record "Transmission IRIS";
        DocHeader: Record "IRS 1099 Form Doc. Header";
        TransmissionLog: Record "Transmission Log IRIS";
        TransmissionPage: TestPage "Transmission IRIS";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] An accepted correction does not hide the replacement action for a different rejected submission.
        Initialize();

        // [GIVEN] Transmission's latest correction is accepted, but earlier submission is still rejected.
        CreateLifecycleTransmission(Transmission, DocHeader, 2026, 'NEC');
        SetLifecycleReference(DocHeader, Transmission."Document ID", '1', '2', "Transmission Status IRIS"::Rejected, false);
        CreateFilingAttempt(Transmission, "Transmission Type IRIS"::O, DocHeader."IRIS Last Receipt ID", TransmissionLog);
        AddFilingAttemptDocument(TransmissionLog, DocHeader, 1);
        Transmission.Status := Transmission.Status::Accepted;
        Transmission."Last Type" := Transmission."Last Type"::C;
        Transmission.Modify();
        InitializeOfflineTransport(Transmission);

        // [WHEN] Open transmission card.
        TransmissionPage.OpenEdit();
        TransmissionPage.GoToRecord(Transmission);

        // [THEN] Replacement remains available for rejected submission.
        Assert.IsTrue(TransmissionPage.SendReplacement.Visible(), 'An accepted correction cannot hide remaining rejected submissions.');

        // [WHEN] Change latest correction's status to Rejected.
        Transmission.Status := Transmission.Status::Rejected;
        Transmission.Modify();
        TransmissionPage.GoToRecord(Transmission);

        // [THEN] That rejected correction requires correction retry, not replacement.
        Assert.IsFalse(TransmissionPage.SendReplacement.Visible(), 'A rejected correction must not become replaceable.');
        TransmissionPage.Close();
        FinishOfflineTransport();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler,SelectIncomeUpdateHandler,UpdateTransmissionMessageHandler,ConfirmYes')]
    procedure CorrectionRejectsRecreatedDocumentWithoutSubmission()
    var
        Transmission: Record "Transmission IRIS";
        SourceDocHeader: Record "IRS 1099 Form Doc. Header";
        DocHeader: Record "IRS 1099 Form Doc. Header";
        TransmissionLog: Record "Transmission Log IRIS";
        RequestCount: Integer;
        AttemptCount: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A new document created after an accepted zero correction must be sent as an original, not a correction.
        Initialize();

        // [GIVEN] Source is Abandoned after zero correction, and Update Transmission creates unsent replacement document.
        CreatePendingZeroCorrection(Transmission, SourceDocHeader);
        RequestAcceptedCorrection(Transmission);
        SetTransmissionUpdateAdjustment(SourceDocHeader, 'NEC-01', 5000);
        LibraryVariableStorage.Enqueue(SourceDocHeader."Vendor No.");
        Commit();
        LibraryIRS1099Document.UpdateTransmission(Transmission);
        FindUnsentReplacement(SourceDocHeader, DocHeader);
        Assert.AreEqual('', DocHeader."IRIS Record ID", 'The recreated document must not have a previous filing record.');
        DocHeader."IRIS Needs Correction" := true;
        DocHeader.Modify();
        DocHeader.Get(DocHeader.ID);
        RequestCount := OfflineRequestPaths.Count();
        TransmissionLog.SetRange("Transmission Document ID", Transmission."Document ID");
        AttemptCount := TransmissionLog.Count();
        Commit();

        // [WHEN] Try to correct new document.
        asserterror LibraryIRS1099IRIS.SendCorrection(Transmission, false);

        // [THEN] Clear guidance blocks operation before XML generation or HTTP requests.
        Assert.ExpectedError(NoRecordedCorrectionTxt);
        Assert.ExpectedError('Clear Needs Correction');
        Assert.ExpectedError('original returns');
        Assert.ExpectedError(DocHeader."Vendor No.");
        Assert.ExpectedErrorCode('Dialog');
        VerifyBlockedCorrection(DocHeader, Transmission, RequestCount, AttemptCount);
        VerifyAcceptedZeroCorrection(SourceDocHeader);
        FinishOfflineTransport();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler,SelectNewBoxUpdateHandler,UpdateTransmissionMessageHandler,ConfirmYes')]
    procedure CorrectionAcceptsUpdatedAcceptedSource()
    var
        Transmission: Record "Transmission IRIS";
        SourceDocHeader: Record "IRS 1099 Form Doc. Header";
        DocHeader: Record "IRS 1099 Form Doc. Header";
        TransmissionLog: Record "Transmission Log IRIS";
        Payload: Codeunit "Temp Blob";
        AcceptedRecordReference: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Adding a box to an accepted return preserves the accepted reference needed for correction.
        Initialize();

        // [GIVEN] Update Transmission creates unsent replacement from accepted source, retaining source's filing references.
        CreateLifecycleTransmission(Transmission, SourceDocHeader, 2026, 'NEC');
        InitializeOfflineTransport(Transmission);
        QueueOfflineSend();
        LibraryIRS1099IRIS.SendOriginal(Transmission);
        SourceDocHeader.Get(SourceDocHeader.ID);
        AcceptedRecordReference := StrSubstNo('%1|%2|%3', SourceDocHeader."IRIS Last Accepted Receipt ID",
            SourceDocHeader."IRIS Submission ID", SourceDocHeader."IRIS Record ID");
        SetTransmissionUpdateAdjustment(SourceDocHeader, 'NEC-01', 5000);
        SetTransmissionUpdateAdjustment(SourceDocHeader, 'NEC-03', 7000);
        LibraryVariableStorage.Enqueue(SourceDocHeader."Vendor No.");
        Commit();
        LibraryIRS1099Document.UpdateTransmission(Transmission);
        FindUnsentReplacement(SourceDocHeader, DocHeader);
        // [WHEN] Send updated return as correction.
        QueueOfflineSend();
        LibraryIRS1099IRIS.SendCorrection(Transmission, false);

        // [THEN] XML reports new box against accepted source reference rather than sending another original.
        FindLastAttempt(Transmission, TransmissionLog);
        WriteTextBlob(Payload, ReadAttemptContent(TransmissionLog, 20));
        VerifyAcceptedUpdatedSource(SourceDocHeader, DocHeader, Payload, AcceptedRecordReference);
        FinishOfflineTransport();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler')]
    procedure CorrectionWithMissingFilingDetailsRequiresAcknowledgment()
    var
        Transmission: Record "Transmission IRIS";
        DocHeader: Record "IRS 1099 Form Doc. Header";
        TransmissionLog: Record "Transmission Log IRIS";
        RequestCount: Integer;
        AttemptCount: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A sent document with missing filing IDs requires recovery guidance, not a new original send.
        Initialize();

        // [GIVEN] Successfully submitted document is missing its saved filing record ID.
        CreateLifecycleTransmission(Transmission, DocHeader, 2026, 'NEC');
        InitializeOfflineTransport(Transmission);
        QueueOfflineSend();
        LibraryIRS1099IRIS.SendOriginal(Transmission);
        DocHeader.Get(DocHeader.ID);
        DocHeader."IRIS Record ID" := '';
        DocHeader."IRIS Needs Correction" := true;
        DocHeader.Modify();
        DocHeader.Get(DocHeader.ID);
        RequestCount := OfflineRequestPaths.Count();
        TransmissionLog.SetRange("Transmission Document ID", Transmission."Document ID");
        AttemptCount := TransmissionLog.Count();
        Commit();

        // [WHEN] Try to send correction.
        asserterror LibraryIRS1099IRIS.SendCorrection(Transmission, false);

        // [THEN] Acknowledgment guidance is shown before any send, new attempt or identifier changes.
        Assert.ExpectedError(PreviousFilingDetailsTxt);
        Assert.ExpectedError('Use Request Status to retrieve the IRS acknowledgment');
        Assert.ExpectedError('The document cannot be corrected in Business Central while these details are missing');
        Assert.ExpectedError('Do not submit this document as a new original return');
        Assert.ExpectedErrorCode('Dialog');
        VerifyBlockedCorrection(DocHeader, Transmission, RequestCount, AttemptCount);
        FinishOfflineTransport();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmSandboxRemoval')]
    procedure SandboxRemovalAllowsSandboxWithoutSaaSFlag()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Sandbox transmission removal depends on sandbox classification, not the SaaS flag.
        Initialize();

        // [GIVEN] Filed transmission exists in sandbox whose SaaS flag is cleared.
        CreateSandboxRemovalTestData();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        Commit();

        VerifySandboxRemovalVisibility(true);

        // [WHEN] Call sandbox reset operation directly.
        Assert.IsTrue(LibraryIRS1099IRIS.RemoveSandboxTransmission(SandboxTransmission, false), 'Sandbox reset must not require the SaaS deployment flag.');

        // [THEN] Removal succeeds, and related document's filing state is reset.
        VerifySandboxResetDocHeader(SandboxDocHeader.ID, SandboxDocHeader.Status::Open);
        VerifySandboxRemovalCompleted();
        VerifySandboxRemovalConfirmation(SandboxResetDocumentsTxt);
    end;

    [Test]
    procedure SandboxRemovalRejectsProduction()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Sandbox removal operations are unavailable and rejected in production.
        Initialize();

        // [GIVEN] Filed transmission exists in production.
        CreateSandboxRemovalTestData();
        EnvironmentInfoTestLibrary.SetTestabilitySandbox(false);
        Commit();

        // [WHEN] Call sandbox delete operation directly.
        asserterror LibraryIRS1099IRIS.RemoveSandboxTransmission(SandboxTransmission, true);

        // [THEN] Backend rejects operation, both removal actions are hidden, and all records remain unchanged.
        Assert.ExpectedError(SandboxOnlyErr);
        Assert.ExpectedErrorCode('Dialog');
        VerifySandboxRemovalVisibility(false);
        VerifySandboxRemovalUnchanged();
    end;

    [Test]
    procedure SandboxRemovalRejectsConflictingHistoricalOwner()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Sandbox reset fails if a historically related document now belongs to another transmission.
        Initialize();

        // [GIVEN] Document in transmission T1's history is now linked to T2.
        CreateSandboxRemovalTestData();
        SandboxAbandonedDocHeader."IRIS Transmission Document ID" := SandboxOtherTransmission."Document ID";
        SandboxAbandonedDocHeader.Modify();
        CaptureSandboxAllRecords(SandboxAllSnapshot);
        Commit();

        // [WHEN] Reset T1.
        asserterror LibraryIRS1099IRIS.RemoveSandboxTransmission(SandboxTransmission, false);

        // [THEN] Error identifies conflicting document, and no records are changed.
        VerifySandboxConflict(SandboxAbandonedDocHeader.ID);
        VerifySandboxRemovalUnchanged();
    end;

    [Test]
    procedure SandboxRemovalRejectsConflictingHistoricalYear()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Sandbox deletion fails if a historically related document now belongs to another year.
        Initialize();

        // [GIVEN] Document in transmission T's history now belongs to different existing reporting year.
        CreateSandboxRemovalTestData();
        SetSandboxHistoricalYear();
        CaptureSandboxAllRecords(SandboxAllSnapshot);
        Commit();

        // [WHEN] Delete T and its documents.
        asserterror LibraryIRS1099IRIS.RemoveSandboxTransmission(SandboxTransmission, true);

        // [THEN] Error identifies conflicting document, and no records are changed.
        VerifySandboxConflict(SandboxAbandonedDocHeader.ID);
        VerifySandboxRemovalUnchanged();
    end;

    [Test]
    [HandlerFunctions('ConfirmSandboxRemoval')]
    procedure SandboxRemovalResetKeepsContentsAndAbandonedVersions()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Sandbox reset clears filing state but keeps document contents, including Abandoned versions.
        Initialize();

        // [GIVEN] Transmission T has active document, detached Abandoned document, duplicate history links and history link to missing document.
        CreateSandboxRemovalTestData();

        // [WHEN] Remove T while retaining its documents.
        Assert.IsTrue(LibraryIRS1099IRIS.RemoveSandboxTransmission(SandboxTransmission, false), 'Confirmed reset must succeed.');

        // [THEN] Each existing related document is reset once; document contents and unrelated records stay unchanged.
        VerifySandboxResetDocHeader(SandboxDocHeader.ID, SandboxDocHeader.Status::Open);
        VerifySandboxResetDocHeader(SandboxAbandonedDocHeader.ID, SandboxAbandonedDocHeader.Status::Abandoned);
        VerifySandboxContentsUnchanged();
        VerifySandboxRemovalCompleted();
        VerifySandboxRemovalConfirmation(SandboxResetDocumentsTxt);
    end;

    [Test]
    [HandlerFunctions('ConfirmSandboxRemoval')]
    procedure SandboxRemovalDeleteUsesDocumentCascade()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Sandbox deletion removes related documents and their child records, not posted source entries or setup.
        Initialize();

        // [GIVEN] Transmission T has active and Abandoned documents with income lines, details, supplemental values and saved PDFs.
        CreateSandboxRemovalTestData();

        // [WHEN] Delete T and its associated documents.
        Assert.IsTrue(LibraryIRS1099IRIS.RemoveSandboxTransmission(SandboxTransmission, true), 'Confirmed deletion must succeed.');

        // [THEN] Only T's documents, child records and history are deleted; posted sources and reporting setup remain.
        VerifySandboxDocumentDeleted(SandboxDocHeader.ID);
        VerifySandboxDocumentDeleted(SandboxAbandonedDocHeader.ID);
        VerifySandboxRemovalCompleted();
        VerifySandboxRemovalConfirmation(SandboxDeleteDocumentsTxt);
    end;

    [Test]
    [HandlerFunctions('DeclineDestinationConfirmation')]
    procedure SandboxRemovalResetActionDeclined()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Declining sandbox reset leaves the transmission card open and all data unchanged.
        Initialize();

        // [GIVEN] Filed transmission is open in sandbox.
        CreateSandboxRemovalTestData();

        // [WHEN] Choose reset, then decline its confirmation.
        InvokeAndDeclineSandboxReset();

        // [THEN] Confirmation describes exactly what would be removed or reset, but nothing is changed and card stays usable.
        VerifySandboxRemovalConfirmation(SandboxResetDocumentsTxt);
        VerifySandboxRemovalUnchanged();
    end;

    [Test]
    [HandlerFunctions('DeclineDestinationConfirmation')]
    procedure SandboxRemovalDeleteActionDeclined()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Declining sandbox document deletion leaves the card open and all data unchanged.
        Initialize();

        // [GIVEN] Filed transmission is open in sandbox.
        CreateSandboxRemovalTestData();

        // [WHEN] Choose deletion, then decline its confirmation.
        InvokeAndDeclineSandboxDelete();

        // [THEN] Confirmation describes exactly which documents would be deleted, but nothing is changed and card stays usable.
        VerifySandboxRemovalConfirmation(SandboxDeleteDocumentsTxt);
        VerifySandboxRemovalUnchanged();
    end;

    [Test]
    [HandlerFunctions('ConfirmSandboxRemoval')]
    procedure SandboxRemovalResetProcessingActionClosesCard()
    var
        TransmissionPage: TestPage "Transmission IRIS";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A sandbox Processing transmission can be removed without HTTP while retaining and reopening its documents.
        Initialize();

        // [GIVEN] Processing transmission T1 and unrelated T2 share reporting year.
        CreateSandboxRemovalTestData();
        SetSandboxTransmissionProcessing();

        // [WHEN] Confirm reset from T1's card.
        InvokeSandboxReset(TransmissionPage);
        Commit();

        // [THEN] T1 is removed and its card closes; its document becomes Open, and T2 remains unchanged.
        VerifySandboxResetDocHeader(SandboxDocHeader.ID, SandboxDocHeader.Status::Open);
        VerifySandboxRemovalCompleted();
        VerifySandboxRemovalConfirmation(SandboxResetDocumentsTxt);
        VerifySandboxCardClosed(TransmissionPage);
    end;

    [Test]
    [HandlerFunctions('ConfirmSandboxRemoval')]
    procedure SandboxRemovalDeleteProcessingActionClosesCard()
    var
        TransmissionPage: TestPage "Transmission IRIS";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A sandbox Processing transmission and its documents can be deleted without HTTP.
        Initialize();

        // [GIVEN] Processing transmission T1 and unrelated T2 share reporting year.
        CreateSandboxRemovalTestData();
        SetSandboxTransmissionProcessing();

        // [WHEN] Confirm deletion from T1's card.
        InvokeSandboxDelete(TransmissionPage);
        Commit();

        // [THEN] T1 and its documents are deleted and card closes, while T2 and unrelated records remain.
        VerifySandboxDocumentDeleted(SandboxDocHeader.ID);
        VerifySandboxDocumentDeleted(SandboxAbandonedDocHeader.ID);
        VerifySandboxRemovalCompleted();
        VerifySandboxRemovalConfirmation(SandboxDeleteDocumentsTxt);
        VerifySandboxCardClosed(TransmissionPage);
    end;

    [Test]
    [HandlerFunctions('ChangeSandboxRemovalScope')]
    procedure SandboxRemovalRejectsChangedConfirmedScope()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Sandbox removal detects a changed document set even when its count stays the same.
        Initialize();

        // [GIVEN] Transmission T's related-document set changes while its confirmation is open.
        CreateSandboxRemovalTestData();
        Commit();

        // [WHEN] Replace one historical document link with another before confirming removal.
        asserterror LibraryIRS1099IRIS.RemoveSandboxTransmission(SandboxTransmission, false);

        // [THEN] Removal fails instead of including newly linked document without confirmation.
        Assert.ExpectedError(SandboxChangedErr);
        Assert.ExpectedErrorCode('Dialog');
        VerifySandboxRemovalUnchanged();
    end;

    [Test]
    [HandlerFunctions('ChangeSandboxRemovalDocument')]
    procedure SandboxRemovalFailureLeavesCardUsable()
    var
        TransmissionPage: TestPage "Transmission IRIS";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A document change during confirmation cancels sandbox removal without closing the card.
        Initialize();

        // [GIVEN] Transmission T's card is open, and related document is changed during confirmation.
        CreateSandboxRemovalTestData();
        Commit();
        TransmissionPage.OpenEdit();
        TransmissionPage.GoToRecord(SandboxTransmission);

        // [WHEN] Confirm reset after that document receives newer receipt.
        asserterror TransmissionPage.RemoveTransmissionAndResetDocuments.Invoke();

        // [THEN] No cleanup is performed, and card still shows T.
        Assert.ExpectedError(SandboxChangedErr);
        Assert.ExpectedErrorCode('Dialog');
        TransmissionPage."Period No.".AssertEquals(SandboxTransmission."Period No.");
        TransmissionPage.Close();
        VerifySandboxRemovalUnchanged();
    end;

    [Test]
    [HandlerFunctions('ConfirmSandboxRemoval')]
    procedure SandboxRemovalResetRollsBackOnLaterHistoryFailure()
    var
        FailureSubscriber: Codeunit "IRS 1099 IRIS Tests";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A history-deletion error rolls back earlier document resets and log-line deletions.
        Initialize();

        // [GIVEN] Test subscriber will reject deletion of T's history after its documents have been reset.
        CreateSandboxRemovalTestData();
        FailureSubscriber.FailSandboxRemovalOnHistory(SandboxHistoryID);
        BindSubscription(FailureSubscriber);
        Commit();

        // [WHEN] Run sandbox reset until it reaches history deletion.
        asserterror LibraryIRS1099IRIS.RemoveSandboxTransmission(SandboxTransmission, false);

        // [THEN] Operation fails, restoring all original document state and history records.
        Assert.ExpectedError(SandboxFailureErr);
        Assert.ExpectedErrorCode('Dialog');
        UnbindSubscription(FailureSubscriber);
        VerifySandboxRemovalUnchanged();
        VerifySandboxRemovalConfirmation(SandboxResetDocumentsTxt);
    end;

    [Test]
    [HandlerFunctions('ConfirmSandboxRemoval')]
    procedure SandboxRemovalDeleteRollsBackOnLaterHistoryFailure()
    var
        FailureSubscriber: Codeunit "IRS 1099 IRIS Tests";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A history-deletion error restores documents and child records already deleted by sandbox removal.
        Initialize();

        // [GIVEN] Test subscriber will reject deletion of T's history after document deletion has run.
        CreateSandboxRemovalTestData();
        FailureSubscriber.FailSandboxRemovalOnHistory(SandboxHistoryID);
        BindSubscription(FailureSubscriber);
        Commit();

        // [WHEN] Delete T and its documents until history cleanup fails.
        asserterror LibraryIRS1099IRIS.RemoveSandboxTransmission(SandboxTransmission, true);

        // [THEN] All original document headers, child records and history are restored.
        Assert.ExpectedError(SandboxFailureErr);
        Assert.ExpectedErrorCode('Dialog');
        UnbindSubscription(FailureSubscriber);
        VerifySandboxRemovalUnchanged();
        VerifySandboxRemovalConfirmation(SandboxDeleteDocumentsTxt);
    end;

    [Test]
    procedure SandboxRemovalDoesNotRelaxOrdinaryDelete()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Normal table deletion of a sent transmission stays blocked even in sandbox.
        Initialize();

        // [GIVEN] Accepted transmission exists in sandbox.
        CreateSandboxRemovalTestData();
        Commit();

        // [WHEN] Try ordinary table deletion instead of sandbox removal operation.
        asserterror SandboxTransmission.Delete(true);

        // [THEN] Existing deletion restriction raises error, and no data changes.
        Assert.ExpectedError('A transmission with status other than None cannot be deleted.');
        Assert.ExpectedErrorCode('Dialog');
        VerifySandboxRemovalUnchanged();
    end;

    [Test]
    procedure SandboxRemovalResetRejectsReusedTransmissionID()
    var
        StaleTransmission: Record "Transmission IRIS";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Reset cannot act on a different transmission that has reused a stale selection's numeric ID.
        Initialize();

        // [GIVEN] Selected transmission was replaced by another record with same numeric ID but different SystemId.
        CreateSandboxRemovalTestData();
        RecreateSandboxRemovalTransmission(StaleTransmission);
        Commit();

        // [WHEN] Call reset using old selected record.
        asserterror LibraryIRS1099IRIS.RemoveSandboxTransmission(StaleTransmission, false);

        // [THEN] Changed-record error occurs before confirmation, leaving replacement transmission, documents and history untouched.
        Assert.ExpectedError(SandboxChangedErr);
        Assert.ExpectedErrorCode('Dialog');
        VerifySandboxRemovalUnchanged();
        Assert.AreEqual(0, OfflineRequestPaths.Count(), 'Rejecting a stale selection must not make any HTTP request.');
    end;

    [Test]
    procedure SandboxRemovalDeleteRejectsReusedTransmissionID()
    var
        StaleTransmission: Record "Transmission IRIS";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Delete cannot act on a different transmission that has reused a stale selection's numeric ID.
        Initialize();

        // [GIVEN] Selected transmission was replaced by another record with same numeric ID but different SystemId.
        CreateSandboxRemovalTestData();
        RecreateSandboxRemovalTransmission(StaleTransmission);
        Commit();

        // [WHEN] Call delete using old selected record.
        asserterror LibraryIRS1099IRIS.RemoveSandboxTransmission(StaleTransmission, true);

        // [THEN] Changed-record error occurs before confirmation, leaving replacement transmission, documents and history untouched.
        Assert.ExpectedError(SandboxChangedErr);
        Assert.ExpectedErrorCode('Dialog');
        VerifySandboxRemovalUnchanged();
        Assert.AreEqual(0, OfflineRequestPaths.Count(), 'Rejecting a stale selection must not make any HTTP request.');
    end;

    [Test]
    procedure CorrectionRejectsCopiedIdentifiersWithoutSubmission()
    var
        Transmission: Record "Transmission IRIS";
        DocHeader: Record "IRS 1099 Form Doc. Header";
        TransmissionLog: Record "Transmission Log IRIS";
        RequestCount: Integer;
        AttemptCount: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Copied filing IDs do not make a document that was never sent eligible for correction.
        Initialize();

        // [GIVEN] Unfiled document has copied IDs but no submission status or send history.
        CreateLifecycleTransmission(Transmission, DocHeader, 2026, 'NEC');
        SetLifecycleReference(DocHeader, Transmission."Document ID", '1', '1', "Transmission Status IRIS"::None, true);
        Transmission.Status := Transmission.Status::Accepted;
        Transmission."Receipt ID" := 'ACCEPTED';
        Transmission.Modify();
        DocHeader.Get(DocHeader.ID);
        InitializeOfflineTransport(Transmission);
        RequestCount := OfflineRequestPaths.Count();
        TransmissionLog.SetRange("Transmission Document ID", Transmission."Document ID");
        AttemptCount := TransmissionLog.Count();
        Commit();

        // [WHEN] Try to send correction.
        asserterror LibraryIRS1099IRIS.SendCorrection(Transmission, false);

        // [THEN] Operation is blocked before XML generation or HTTP requests.
        Assert.ExpectedError(NoRecordedCorrectionTxt);
        Assert.ExpectedError('Clear Needs Correction');
        Assert.ExpectedErrorCode('Dialog');
        VerifyBlockedCorrection(DocHeader, Transmission, RequestCount, AttemptCount);
        FinishOfflineTransport();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler,OfflineErrorMessageHandler')]
    procedure OriginalReceiptSurvivesFailedAcknowledgment()
    var
        Transmission: Record "Transmission IRIS";
        DocHeader: Record "IRS 1099 Form Doc. Header";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] An original send keeps its receipt when the immediate acknowledgment request fails, so status can be retried without resending.
        Initialize();

        // [GIVEN] Released document D is ready to send, and acknowledgment endpoint returns HTTP 503.
        CreateLifecycleTransmission(Transmission, DocHeader, 2026, 'NEC');
        InitializeOfflineTransport(Transmission);
        OfflineStatusHttpStatus := 503;

        // [WHEN] Send original.
        QueueOfflineSend();
        LibraryIRS1099IRIS.SendOriginal(Transmission);

        // [THEN] Receipt is saved, and another original send is blocked before HTTP.
        VerifyPendingIntake(Transmission, DocHeader, "Transmission Type IRIS"::O);
        asserterror LibraryIRS1099IRIS.SendOriginal(Transmission);
        Assert.ExpectedError('The IRS is still processing the transmission.');
        Assert.ExpectedErrorCode('Dialog');
        Assert.AreEqual(2, OfflineRequestPaths.Count() - OfflineTokenProbeCount, 'A duplicate intake must not be sent.');

        // [WHEN] Restore acknowledgment endpoint and request status.
        OfflineStatusHttpStatus := 200;
        RequestAcceptedCorrection(Transmission);

        // [THEN] Saved attempt becomes Accepted without another submission.
        DocHeader.Get(DocHeader.ID);
        Assert.AreEqual(DocHeader.Status::Submitted, DocHeader.Status, 'The original must complete through polling.');
        Assert.AreEqual(3, OfflineRequestPaths.Count() - OfflineTokenProbeCount, 'Recovery must only request an acknowledgment.');
        FinishOfflineTransport();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler,OfflineErrorMessageHandler')]
    procedure OriginalReceiptSurvivesUnparseableAcknowledgment()
    var
        Transmission: Record "Transmission IRIS";
        DocHeader: Record "IRS 1099 Form Doc. Header";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] An acknowledgment without a status does not discard the receipt from a successful original send.
        Initialize();

        // [GIVEN] Released document D is ready to send, and acknowledgment response has no status.
        CreateLifecycleTransmission(Transmission, DocHeader, 2026, 'NEC');
        InitializeOfflineTransport(Transmission);
        OfflineStatus := '';

        // [WHEN] Send original.
        QueueOfflineSend();
        LibraryIRS1099IRIS.SendOriginal(Transmission);

        // [THEN] Parsing error leaves saved receipt and pending state available for status recovery.
        VerifyPendingIntake(Transmission, DocHeader, "Transmission Type IRIS"::O);
        VerifySavedSupplementalValues(DocHeader, 100, 50, '101', '000');
        FinishOfflineTransport();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler,OfflineErrorMessageHandler')]
    procedure CorrectionReceiptSurvivesFailedAcknowledgment()
    var
        Transmission: Record "Transmission IRIS";
        DocHeader: Record "IRS 1099 Form Doc. Header";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A correction keeps its new receipt after acknowledgment failure without losing the original accepted reference.
        Initialize();

        // [GIVEN] Document D corrects accepted filing, and acknowledgment endpoint returns HTTP 503.
        CreateAcceptedCorrectionSource(Transmission, DocHeader);
        OfflineStatusHttpStatus := 503;

        // [WHEN] Send correction.
        QueueOfflineSend();
        LibraryIRS1099IRIS.SendCorrection(Transmission, false);

        // [THEN] Duplicate correction is blocked, and D keeps its original accepted reference.
        VerifyPendingIntake(Transmission, DocHeader, "Transmission Type IRIS"::C);
        Assert.AreEqual('ACCEPTED', DocHeader."IRIS Last Accepted Receipt ID", 'Intake is not acceptance.');
        Assert.IsTrue(DocHeader."IRIS Needs Correction", 'Unacknowledged correction must remain pending.');
        asserterror LibraryIRS1099IRIS.SendCorrection(Transmission, false);
        Assert.ExpectedError('The IRS is still processing the transmission.');
        Assert.ExpectedErrorCode('Dialog');
        Assert.AreEqual(2, OfflineRequestPaths.Count() - OfflineTokenProbeCount, 'A pending correction must not be resubmitted.');

        // [WHEN] Successfully poll new receipt.
        OfflineStatusHttpStatus := 200;
        RequestAcceptedCorrection(Transmission);

        // [THEN] Nonzero correction completes only after Accepted acknowledgment.
        DocHeader.Get(DocHeader.ID);
        Assert.IsTrue(DocHeader."IRIS Corrected", 'The recorded correction must complete.');
        Assert.IsFalse(DocHeader."IRIS Needs Correction", 'Accepted correction selection must be cleared.');
        Assert.IsFalse(DocHeader."IRIS Corrected to Zeros", 'A nonzero correction must not be reclassified.');
        FinishOfflineTransport();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler,OfflineErrorMessageHandler')]
    procedure FailedTwoStepSendPreservesOriginalSelection()
    var
        Transmission: Record "Transmission IRIS";
        OtherTransmission: Record "Transmission IRIS";
        SelectedDocHeader: Record "IRS 1099 Form Doc. Header";
        UnselectedDocHeader: Record "IRS 1099 Form Doc. Header";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A failed Step 1 send restores the user's original correction selections.
        Initialize();

        // [GIVEN] Accepted documents D1 and D2 have different correction selections.
        CreateAcceptedCorrectionSource(Transmission, SelectedDocHeader);
        CreateLifecycleTransmission(OtherTransmission, UnselectedDocHeader, 2026, 'NEC');
        SetLifecycleReference(UnselectedDocHeader, Transmission."Document ID", '1', '3', "Transmission Status IRIS"::Accepted, false);
        OfflineSubmitHttpStatus := 400;

        // [WHEN] Send two-step zero correction and simulate failure during submission.
        QueueOfflineSubmission();
        LibraryIRS1099IRIS.SendTwoStepZeroCorrection(Transmission);

        // [THEN] Both documents retain their original selection flags and accepted filing references.
        SelectedDocHeader.Get(SelectedDocHeader.ID);
        UnselectedDocHeader.Get(UnselectedDocHeader.ID);
        Assert.IsTrue(SelectedDocHeader."IRIS Needs Correction", 'Existing selection must remain.');
        Assert.IsFalse(UnselectedDocHeader."IRIS Needs Correction", 'The action-added selection must be restored.');
        Assert.AreEqual('ACCEPTED', Transmission."Receipt ID", 'Failed intake must not replace the accepted receipt.');
        Assert.AreEqual(1, OfflineRequestPaths.Count() - OfflineTokenProbeCount, 'Failed intake must not request acknowledgment.');
        VerifySavedSupplementalValues(UnselectedDocHeader, 100, 50, '101', '000');
        FinishOfflineTransport();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler,ConfirmYes,RecoveredReceiptHandler,OfflineErrorMessageHandler')]
    procedure ManualReceiptWithoutHistoryUpdatesOnlyTransmission()
    var
        Transmission: Record "Transmission IRIS";
        DocHeader: Record "IRS 1099 Form Doc. Header";
        TransmissionLog: Record "Transmission Log IRIS";
        TransmissionPage: TestPage "Transmission IRIS";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A manually recovered receipt can update a transmission without inventing document send history.
        Initialize();

        // [GIVEN] Document D has no locally saved send attempt.
        CreateLifecycleTransmission(Transmission, DocHeader, 2026, 'NEC');
        InitializeOfflineTransport(Transmission);
        OfflineUTID := 'RECOVERED-UTID';

        // [WHEN] Assign recovered receipt on transmission page and request its status.
        TransmissionPage.OpenEdit();
        TransmissionPage.GoToRecord(Transmission);
        TransmissionPage.AssignReceiptIDManually.Invoke();
        QueueOfflineHistorylessAcknowledgment();
        TransmissionPage.RequestTransmissionStatusByRID.Invoke();

        // [THEN] Only transmission becomes Accepted; document D is unchanged and no attempt or document membership is created.
        TransmissionLog.SetRange("Transmission Document ID", Transmission."Document ID");
        Assert.RecordIsEmpty(TransmissionLog);
        VerifyManualReceiptRecovery(Transmission, DocHeader);
        TransmissionPage.Close();
        FinishOfflineTransport();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler,ConfirmYes,RecoveredReceiptHandler,OfflineErrorMessageHandler')]
    procedure ManualReceiptDoesNotReuseUnrelatedAttempt()
    var
        Transmission: Record "Transmission IRIS";
        DocHeader: Record "IRS 1099 Form Doc. Header";
        TransmissionLog: Record "Transmission Log IRIS";
        TransmissionPage: TestPage "Transmission IRIS";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Assigning a recovered receipt does not link it to an older attempt with a different receipt.
        Initialize();

        // [GIVEN] Transmission T has older history belonging to another receipt.
        CreateLifecycleTransmission(Transmission, DocHeader, 2026, 'NEC');
        CreateFilingAttempt(Transmission, "Transmission Type IRIS"::O, 'OLDER-RECEIPT', TransmissionLog);
        InitializeOfflineTransport(Transmission);
        OfflineUTID := 'RECOVERED-UTID';

        // [WHEN] Assign different recovered receipt and request status.
        TransmissionPage.OpenEdit();
        TransmissionPage.GoToRecord(Transmission);
        TransmissionPage.AssignReceiptIDManually.Invoke();
        QueueOfflineHistorylessAcknowledgment();
        TransmissionPage.RequestTransmissionStatusByRID.Invoke();

        // [THEN] Older attempt and its unique transmission ID remain unchanged and are not reused for new receipt.
        TransmissionLog.Get(TransmissionLog."Line ID");
        Assert.AreEqual('OLDER-RECEIPT', TransmissionLog."Receipt ID", 'Unrelated history must remain unchanged.');
        VerifyManualReceiptRecovery(Transmission, DocHeader);
        TransmissionPage.Close();
        FinishOfflineTransport();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler')]
    procedure OlderRejectedCorrectionCannotBecomeReplacement()
    var
        Transmission: Record "Transmission IRIS";
        OtherTransmission: Record "Transmission IRIS";
        NECDocHeader: Record "IRS 1099 Form Doc. Header";
        MISCDocHeader: Record "IRS 1099 Form Doc. Header";
        TransmissionLog: Record "Transmission Log IRIS";
        Payload: Codeunit "Temp Blob";
        OriginalRecordReference: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A rejected NEC correction remains a correction retry after a later MISC correction is accepted.
        Initialize();

        // [GIVEN] NEC and MISC originals were accepted with schema 2.0.3, then NEC correction was rejected and later MISC correction was accepted.
        CreateLifecycleTransmission(Transmission, NECDocHeader, 2025, 'NEC');
        CreateLifecycleTransmission(OtherTransmission, MISCDocHeader, 2025, 'MISC');
        NECDocHeader.Get(NECDocHeader.ID);
        NECDocHeader."IRIS Transmission Document ID" := Transmission."Document ID";
        NECDocHeader.Modify();
        MISCDocHeader."IRIS Transmission Document ID" := Transmission."Document ID";
        MISCDocHeader.Modify();
        SetPeriodSchema('2025', "XML Schema Version IRIS"::"2.0.3");
        InitializeOfflineTransport(Transmission);
        QueueOfflineSend();
        LibraryIRS1099IRIS.SendOriginal(Transmission);
        NECDocHeader.Get(NECDocHeader.ID);
        OriginalRecordReference := StrSubstNo('%1|%2|%3', NECDocHeader."IRIS Last Accepted Receipt ID", NECDocHeader."IRIS Submission ID", NECDocHeader."IRIS Record ID");
        NECDocHeader."IRIS Needs Correction" := true;
        NECDocHeader.Modify();
        OfflineReceiptID := 'REJECTED-NEC-CORRECTION';
        OfflineStatus := 'Rejected';
        Clear(OfflineSubmissionStatuses);
        OfflineSubmissionStatuses.Add(NECDocHeader."IRIS Submission ID", 'Rejected');
        QueueOfflineSend();
        LibraryIRS1099IRIS.SendCorrection(Transmission, false);
        NECDocHeader.Get(NECDocHeader.ID);
        NECDocHeader."IRIS Needs Correction" := false;
        NECDocHeader.Modify();
        MISCDocHeader.Get(MISCDocHeader.ID);
        MISCDocHeader."IRIS Needs Correction" := true;
        MISCDocHeader.Modify();
        OfflineReceiptID := 'ACCEPTED-MISC-CORRECTION';
        OfflineStatus := 'Accepted';
        Clear(OfflineSubmissionStatuses);
        QueueOfflineSend();
        LibraryIRS1099IRIS.SendCorrection(Transmission, false);
        // Preserve the filing history for the correction retry after the expected error.
        Commit();

        // [WHEN] Try replacement while NEC correction is still rejected.
        asserterror LibraryIRS1099IRIS.SendReplacement(Transmission);

        // [THEN] Operation does not turn older NEC correction into replacement of original submission.
        Assert.ExpectedError('can only be corrected');
        Assert.ExpectedErrorCode('Dialog');
        NECDocHeader.Get(NECDocHeader.ID);
        NECDocHeader."IRIS Needs Correction" := true;
        NECDocHeader.Modify();
        OfflineReceiptID := 'ACCEPTED-NEC-RETRY';
        Clear(OfflineSubmissionStatuses);
        QueueOfflineSend();
        LibraryIRS1099IRIS.SendCorrection(Transmission, false);
        FindLastAttempt(Transmission, TransmissionLog);
        WriteTextBlob(Payload, ReadAttemptContent(TransmissionLog, 20));
        InitXMLReader(Payload);
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:TransmissionTypeCd', 'C');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:Form1099NECDetail/n1:CorrectedInd', '1');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:PrevSubmittedRecRecipientGrp/n1:UniqueRecordId', OriginalRecordReference);
        FinishOfflineTransport();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmYes')]
    procedure Schema507Marks2024AsPriorYear()
    var
        Transmission: Record "Transmission IRIS";
        DocHeader: Record "IRS 1099 Form Doc. Header";
        Payload: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Schema 5.0.7 marks confirmed 2024 data as prior-year data.
        Initialize();

        // [GIVEN] Document D reports tax year 2024 with explicit schema 5.0.7 override.
        CreateContractTransmission(Transmission, DocHeader, 2024);

        // [WHEN] Accept unverified-year warning and generate XML.
        CreateSupplementalXml(Transmission, "Transmission Type IRIS"::O, false, Payload);

        // [THEN] XML retains tax year 2024 and sets prior-year indicator.
        VerifyContractManifest(Payload, '2024', '24TEST0001', '1');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler,OfflineErrorMessageHandler')]
    procedure DelayedPreReceiptRejectionRestoresOriginalState()
    var
        Transmission: Record "Transmission IRIS";
        DocHeader: Record "IRS 1099 Form Doc. Header";
        TransmissionLog: Record "Transmission Log IRIS";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A later validation rejection restores the state from before submission.
        Initialize();

        // [GIVEN] Document D received initial submission response, but its immediate acknowledgment was unavailable.
        CreateLifecycleTransmission(Transmission, DocHeader, 2026, 'NEC');
        InitializeOfflineTransport(Transmission);
        OfflineStatusHttpStatus := 503;
        QueueOfflineSend();
        LibraryIRS1099IRIS.SendOriginal(Transmission);
        FindLastAttempt(Transmission, TransmissionLog);

        // [WHEN] Poll status and confirm that IRS rejected validation before issuing usable receipt.
        OfflineStatusHttpStatus := 200;
        OfflinePreReceiptError := true;
        OfflineStatus := 'Rejected';
        QueueOfflineAcknowledgment();
        LibraryIRS1099IRIS.RequestAcknowledgementAndUpdateTransmission(Transmission, Transmission."Receipt ID", TransmissionLog."Unique Transmission ID");

        // [THEN] Unusable receipt and temporary Processing state are cleared, restoring earlier state.
        Transmission.Get(Transmission."Document ID");
        DocHeader.Get(DocHeader.ID);
        Assert.AreEqual(Transmission.Status::None, Transmission.Status, 'A pre-receipt failure is not a completed submission.');
        Assert.AreEqual('', Transmission."Receipt ID", 'A failed pre-receipt intake has no usable receipt.');
        Assert.AreEqual('', Transmission."Original Receipt ID", 'An invalid intake must not replace the original reference.');
        Assert.AreEqual(DocHeader.Status::Released, DocHeader.Status, 'The pre-intake document state must be restored.');
        Assert.AreEqual('', DocHeader."IRIS Last Receipt ID", 'The invalid receipt must not remain on the document.');
        VerifySavedSupplementalValues(DocHeader, 100, 50, '101', '000');
        FinishOfflineTransport();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmYes,DeclineIRISPrivacyConsent')]
    procedure DeclinedTwoStepConsentDoesNotChangeSelection()
    var
        Transmission: Record "Transmission IRIS";
        DocHeader: Record "IRS 1099 Form Doc. Header";
        TransmissionPage: TestPage "Transmission IRIS";
        OriginalConsent: Boolean;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Declining privacy consent for Step 1 changes no correction selections and sends no HTTP requests.
        Initialize();

        // [GIVEN] Accepted document D is not selected for correction, and privacy consent has not been given.
        CreateAcceptedCorrectionSource(Transmission, DocHeader);
        DocHeader."IRIS Needs Correction" := false;
        DocHeader.Modify();
        OriginalConsent := LibraryIRS1099IRIS.GetPrivacyConsent();
        LibraryIRS1099IRIS.SetPrivacyConsent(false);

        // [WHEN] Accept destination confirmation but decline privacy consent.
        TransmissionPage.OpenEdit();
        TransmissionPage.GoToRecord(Transmission);
        TransmissionPage.Step1CorrectionToZero.Invoke();

        // [THEN] Consent stays unset, no correction selection is changed, and no filing is sent.
        DocHeader.Get(DocHeader.ID);
        Assert.IsFalse(DocHeader."IRIS Needs Correction", 'Declined consent must not select every document.');
        Assert.IsFalse(LibraryIRS1099IRIS.GetPrivacyConsent(), 'Decline must not persist consent.');
        Assert.AreEqual(0, OfflineRequestPaths.Count(), 'Declined consent must not send any request.');
        Assert.IsTrue(StrPos(LibraryVariableStorage.DequeueText(), 'By choosing this action') > 0, 'The existing filing consent text must be shown.');
        LibraryIRS1099IRIS.SetPrivacyConsent(OriginalConsent);
        TransmissionPage.Close();
        FinishOfflineTransport();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler,OfflineErrorMessageHandler')]
    procedure UnconfirmedTwoStepSendCompletesAfterAcceptedPoll()
    var
        Transmission: Record "Transmission IRIS";
        DocHeader: Record "IRS 1099 Form Doc. Header";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] An uncertain Step 1 delivery stays pending and completes when IRS later accepts it.
        Initialize();

        // [GIVEN] Accepted document D is not selected for correction, and intake returns HTTP 503.
        CreateAcceptedCorrectionSource(Transmission, DocHeader);
        DocHeader."IRIS Needs Correction" := false;
        DocHeader.Modify();
        OfflineSubmitHttpStatus := 503;

        // [WHEN] Send Step 1 without receiving a confirmed intake response.
        QueueOfflineSubmission();
        LibraryIRS1099IRIS.SendTwoStepZeroCorrection(Transmission);

        // [THEN] Correction selection remains pending and another filing is blocked.
        DocHeader.Get(DocHeader.ID);
        Assert.IsTrue(DocHeader."IRIS Needs Correction", 'Uncertain delivery must retain the pending zero correction.');
        Assert.AreEqual(Transmission.Status::Processing, Transmission.Status, 'Uncertain delivery must block resending.');
        Assert.AreEqual('', Transmission."Receipt ID", 'The old accepted receipt must not identify the uncertain attempt.');
        Assert.AreEqual('ACCEPTED', DocHeader."IRIS Last Accepted Receipt ID", 'Uncertain delivery is not acceptance.');
        Assert.AreEqual(1, OfflineRequestPaths.Count() - OfflineTokenProbeCount, 'Uncertain intake must not be submitted again.');

        // [WHEN] Poll the recorded UTID and receive an Accepted acknowledgment.
        RequestAcceptedCorrection(Transmission);

        // [THEN] The same zero correction completes without another submission.
        VerifyAcceptedZeroCorrection(DocHeader);
        Assert.AreEqual(2, OfflineRequestPaths.Count() - OfflineTokenProbeCount, 'Recovery must only poll the existing attempt.');
        VerifySavedSupplementalValues(DocHeader, 100, 50, '101', '000');
        FinishOfflineTransport();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler,OfflineErrorMessageHandler')]
    procedure RepeatedRejectionPreservesRecoveredManualReceipt()
    var
        Transmission: Record "Transmission IRIS";
        DocHeader: Record "IRS 1099 Form Doc. Header";
        TransmissionLog: Record "Transmission Log IRIS";
        RecoveredReceiptID: Text[100];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Replaying an old rejection cannot erase a newer manual receipt or remove its filing guard.
        Initialize();

        // [GIVEN] An original attempt was rejected before receipt validation.
        CreateLifecycleTransmission(Transmission, DocHeader, 2026, 'NEC');
        InitializeOfflineTransport(Transmission);
        OfflinePreReceiptError := true;
        OfflineStatus := 'Rejected';
        QueueOfflineSend();
        LibraryIRS1099IRIS.SendOriginal(Transmission);
        FindLastAttempt(Transmission, TransmissionLog);

        // [GIVEN] A different manually assigned receipt has been reconciled without local send history.
        RecoveredReceiptID := 'RECOVERED-LATER-RECEIPT';
        Transmission."Receipt ID" := RecoveredReceiptID;
        Transmission."Receipt ID Assigned Manually" := true;
        Transmission.Modify();
        OfflineReceiptID := RecoveredReceiptID;
        OfflineUTID := 'RECOVERED-LATER-UTID';
        OfflinePreReceiptError := false;
        OfflineStatus := 'Accepted';
        QueueOfflineHistorylessAcknowledgment();
        LibraryIRS1099IRIS.RequestAcknowledgementAndUpdateTransmission(Transmission, RecoveredReceiptID, '');

        // [WHEN] Request the old rejected attempt again by its UTID.
        OfflineReceiptID := TransmissionLog."Receipt ID";
        OfflineUTID := TransmissionLog."Unique Transmission ID";
        OfflinePreReceiptError := true;
        OfflineStatus := 'Rejected';
        QueueOfflineHistorylessAcknowledgment();
        LibraryIRS1099IRIS.RequestAcknowledgementAndUpdateTransmission(Transmission, '', TransmissionLog."Unique Transmission ID");

        // [THEN] The recovered identity remains active and original filing remains blocked.
        Transmission.Get(Transmission."Document ID");
        Assert.AreEqual(RecoveredReceiptID, Transmission."Receipt ID", 'Old rejection must not erase the recovered receipt.');
        Assert.AreEqual(Transmission.Status::Accepted, Transmission.Status, 'Old rejection must remain history-only.');
        Assert.IsTrue(Transmission."Receipt ID Assigned Manually", 'Old rejection must not remove the manual-history guard.');
        asserterror LibraryIRS1099IRIS.SendOriginal(Transmission);
        Assert.ExpectedError('no matching local submission history');
        Assert.ExpectedErrorCode('Dialog');
        Assert.AreEqual(4, OfflineRequestPaths.Count() - OfflineTokenProbeCount, 'Replaying history must not submit another filing.');
        FinishOfflineTransport();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler')]
    procedure PreReceiptRejectionPreservesNewerCorrectionEdits()
    var
        Transmission: Record "Transmission IRIS";
        DocHeader: Record "IRS 1099 Form Doc. Header";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Rejecting Step 1 preserves newer edits and their correction flag after the intake commit.
        Initialize();

        // [GIVEN] Document D is edited while its Step 1 acknowledgment is being requested.
        CreateAcceptedCorrectionSource(Transmission, DocHeader);
        DocHeader."IRIS Needs Correction" := false;
        DocHeader.Modify();
        OfflinePreReceiptError := true;
        OfflineStatus := 'Rejected';

        // [WHEN] Send Step 1 and receive a pre-receipt rejection after the newer edit.
        QueueOfflineSubmission();
        QueueOfflineEditedAcknowledgment(DocHeader.ID);
        LibraryIRS1099IRIS.SendTwoStepZeroCorrection(Transmission);

        // [THEN] Snapshot restoration does not trigger another rollback of the newer correction selection.
        DocHeader.Get(DocHeader.ID);
        Assert.IsTrue(DocHeader."IRIS Updated Not Sent", 'The newer amounts must remain unsent.');
        Assert.IsTrue(DocHeader."IRIS Needs Correction", 'The newer edit must remain selected for correction.');
        Assert.IsFalse(DocHeader."IRIS Corrected to Zeros", 'Rejected Step 1 must not complete the correction.');
        VerifyDocLineAmount(DocHeader, 'NEC-01', 6000);
        VerifySavedSupplementalValues(DocHeader, 100, 50, '101', '000');
        FinishOfflineTransport();
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        MockKeyVaultClientIRIS: Codeunit "Mock Key Vault Client IRIS";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"IRS 1099 IRIS Tests");
        LibraryVariableStorage.Clear();
        Clear(LibraryFileMgtHandler);
        LibraryIRS1099IRIS.RestoreOfflineAccessToken();
        RestoreOfflinePrivacyConsent();
        Clear(OfflineRequestPaths);
        Clear(OfflineTokenProbeCount);
        OfflineResponses.Clear();
        Clear(OfflineExpectedRequestKinds);
        Clear(OfflineObservedRequestKinds);
        Clear(OfflineSubmissionStatuses);
        Clear(OfflinePayload);
        Clear(OfflinePreReceiptError);
        Clear(OfflineRecordError);
        OfflineSubmitHttpStatus := 200;
        OfflineStatusHttpStatus := 200;
        Clear(OfflineUTID);
        AzureKeyVaultTestLibrary.ClearSecrets();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        EnvironmentInfoTestLibrary.SetTestabilitySandbox(false);

        LibrarySetupStorage.Restore();
        LibraryIRS1099IRIS.RestoreIRISUserID();
        LibraryIRSReportingPeriod.RemoveAllReportingPeriodsWithRelatedData();
        MockKeyVaultClientIRIS.SetDefaultValues();
        MockKeyVaultClientIRIS.SetSoftwareId(CopyStr(Format(Date2DMY(WorkDate(), 3)), 3, 2) + 'TEST0001');
        InitializeReportingPeriodAndForms(Date2DMY(WorkDate(), 3));
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"IRS 1099 IRIS Tests");

        LibraryIRS1099IRIS.InitializeCompanyInformation();
        LibraryIRS1099IRIS.InitializeIRSFormsSetup();
        LibraryIRS1099IRIS.SaveIRISUserID();
        LibraryIRS1099IRIS.InitializeIRISUserID();
        LibrarySetupStorage.SaveCompanyInformation();
        LibrarySetupStorage.Save(Database::"IRS Forms Setup");

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"IRS 1099 IRIS Tests");
    end;

    local procedure AddOpenTransmissionDocument(IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header")
    begin
        IRS1099FormDocHeader.ID := 0;
        IRS1099FormDocHeader.Status := IRS1099FormDocHeader.Status::Open;
        IRS1099FormDocHeader.Insert(true);
    end;

    local procedure AddSupplementalHeader(SourceIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; var IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; SameRecipient: Boolean)
    var
        Vendor: Record Vendor;
        IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
    begin
        IRS1099FormDocHeader := SourceIRS1099FormDocHeader;
        IRS1099FormDocHeader.ID := 0;
        IRS1099FormDocHeader."IRIS Submission ID" := '';
        IRS1099FormDocHeader."IRIS Record ID" := '';
        IRS1099FormDocHeader."IRIS Last Accepted Receipt ID" := '';
        IRS1099FormDocHeader."IRIS Needs Correction" := false;
        if not SameRecipient then begin
            LibraryIRS1099IRIS.CreateUSVendor(Vendor);
            IRS1099FormDocHeader."Vendor No." := Vendor."No.";
        end;
        // Existing extensions can supply several headers to the recipient grouping.
        IRS1099FormDocHeader.Insert();
        IRS1099FormDocLine.SetRange("Document ID", SourceIRS1099FormDocHeader.ID);
        IRS1099FormDocLine.FindFirst();
        IRS1099FormDocLine."Document ID" := IRS1099FormDocHeader.ID;
        IRS1099FormDocLine."Vendor No." := IRS1099FormDocHeader."Vendor No.";
        IRS1099FormDocLine.Insert();
        SetSupplementalValues(IRS1099FormDocHeader, 100, 50, '101', '000');
    end;

    local procedure AddFilingAttemptDocument(TransmissionLog: Record "Transmission Log IRIS"; DocHeader: Record "IRS 1099 Form Doc. Header"; LineNo: Integer)
    var
        TransmissionLogLine: Record "Transmission Log Line IRIS";
    begin
        TransmissionLogLine."Transmission Log ID" := TransmissionLog."Line ID";
        TransmissionLogLine."Line ID" := LineNo;
        TransmissionLogLine."IRS 1099 Form Document ID" := DocHeader.ID;
        TransmissionLogLine."Submission ID" := DocHeader."IRIS Submission ID";
        TransmissionLogLine."Record ID" := DocHeader."IRIS Record ID";
        TransmissionLogLine."Submission Status Text" := Format(DocHeader."IRIS Submission Status");
        TransmissionLogLine.Insert();
    end;

    local procedure CaptureLatestOfflinePayload()
    var
        TransmissionLog: Record "Transmission Log IRIS";
        Document: XmlDocument;
        Node: XmlNode;
        Nodes: XmlNodeList;
        SubmissionID: Text;
    begin
        TransmissionLog.SetRange("Transmission Document ID", OfflineTransmissionID);
        if not TransmissionLog.FindLast() then
            exit;
        OfflinePayload := ReadAttemptContent(TransmissionLog, 20);
        XmlDocument.ReadFrom(OfflinePayload, Document);
        Document.SelectSingleNode('//*[local-name()="UniqueTransmissionId"]', Node);
        OfflineUTID := CopyStr(Node.AsXmlElement().InnerText(), 1, MaxStrLen(OfflineUTID));
        Document.SelectNodes('//*[local-name()="SubmissionId"]', Nodes);
        foreach Node in Nodes do begin
            SubmissionID := Node.AsXmlElement().InnerText();
            if not OfflineSubmissionStatuses.ContainsKey(SubmissionID) then
                OfflineSubmissionStatuses.Add(SubmissionID, 'Accepted');
        end;
    end;

    local procedure CaptureSandboxAllRecords(var Snapshot: Dictionary of [Text, BigInteger])
    begin
        CaptureSandboxSharedRecords(Snapshot);
        CaptureSandboxTable(Database::"Transmission IRIS", Snapshot);
        CaptureSandboxTable(Database::"Transmission Log IRIS", Snapshot);
        CaptureSandboxTable(Database::"Transmission Log Line IRIS", Snapshot);
        CaptureSandboxTable(Database::"Error Information IRIS", Snapshot);
        CaptureSandboxTable(Database::"IRS 1099 Form Doc. Header", Snapshot);
        CaptureSandboxTable(Database::"IRS 1099 Form Doc. Line", Snapshot);
        CaptureSandboxTable(Database::"IRS 1099 Form Doc. Line Detail", Snapshot);
        CaptureSandboxTable(Database::"IRS 1099 Doc. Suppl. Line", Snapshot);
        CaptureSandboxTable(Database::"IRS 1099 Form Report", Snapshot);
    end;

    local procedure CaptureSandboxContentsSnapshot(var Snapshot: Dictionary of [Text, BigInteger])
    begin
        Clear(Snapshot);
        CaptureSandboxTable(Database::"IRS 1099 Form Doc. Line", Snapshot);
        CaptureSandboxTable(Database::"IRS 1099 Form Doc. Line Detail", Snapshot);
        CaptureSandboxTable(Database::"IRS 1099 Doc. Suppl. Line", Snapshot);
        CaptureSandboxTable(Database::"IRS 1099 Form Report", Snapshot);
    end;

    local procedure CaptureSandboxSharedRecords(var Snapshot: Dictionary of [Text, BigInteger])
    begin
        Clear(Snapshot);
        CaptureSandboxTable(Database::"Vendor Ledger Entry", Snapshot);
        CaptureSandboxTable(Database::"IRS 1099 Vendor Form Box Adj.", Snapshot);
        CaptureSandboxTable(Database::"IRS 1099 Vendor Form Box Setup", Snapshot);
        CaptureSandboxTable(Database::"IRS Forms Setup", Snapshot);
        CaptureSandboxTable(Database::"IRS Reporting Period", Snapshot);
        CaptureSandboxTable(Database::"IRS 1099 Form", Snapshot);
        CaptureSandboxTable(Database::"IRS 1099 Form Box", Snapshot);
        CaptureSandboxTable(Database::"IRS 1099 Suppl. Box", Snapshot);
        CaptureSandboxTable(Database::Vendor, Snapshot);
    end;

    local procedure CaptureSandboxTable(TableID: Integer; var Snapshot: Dictionary of [Text, BigInteger])
    var
        RecordReference: RecordRef;
        RowVersion: BigInteger;
        MoreRecords: Boolean;
    begin
        RecordReference.Open(TableID);
        MoreRecords := RecordReference.FindSet();
        while MoreRecords do begin
            RowVersion := RecordReference.Field(0).Value;
            Snapshot.Add(Format(RecordReference.RecordId()), RowVersion);
            MoreRecords := RecordReference.Next() <> 0;
        end;
        RecordReference.Close();
    end;

    local procedure CaptureSandboxUnrelatedDocumentContents(DocumentID: Integer; var Snapshot: Dictionary of [Text, BigInteger])
    var
        RecordReference: RecordRef;
        TableIDs: List of [Integer];
        TableID: Integer;
        RowVersion: BigInteger;
        MoreRecords: Boolean;
    begin
        TableIDs.Add(Database::"IRS 1099 Form Doc. Line");
        TableIDs.Add(Database::"IRS 1099 Form Doc. Line Detail");
        TableIDs.Add(Database::"IRS 1099 Doc. Suppl. Line");
        TableIDs.Add(Database::"IRS 1099 Form Report");
        foreach TableID in TableIDs do begin
            RecordReference.Open(TableID);
            RecordReference.Field(1).SetRange(DocumentID);
            MoreRecords := RecordReference.FindSet();
            while MoreRecords do begin
                RowVersion := RecordReference.Field(0).Value;
                Snapshot.Add(Format(RecordReference.RecordId()), RowVersion);
                MoreRecords := RecordReference.Next() <> 0;
            end;
            RecordReference.Close();
        end;
    end;

    local procedure CaptureSandboxUnrelatedHistory(var Snapshot: Dictionary of [Text, BigInteger])
    var
        TransmissionLog: Record "Transmission Log IRIS";
        TransmissionLogLine: Record "Transmission Log Line IRIS";
        ErrorInformation: Record "Error Information IRIS";
        DocHeader: Record "IRS 1099 Form Doc. Header";
        Transmission: Record "Transmission IRIS";
    begin
        Transmission.Get(SandboxOtherTransmission."Document ID");
        Snapshot.Add(Format(Transmission.RecordId()), Transmission.SystemRowVersion);
        DocHeader.Get(SandboxOtherDocHeader.ID);
        Snapshot.Add(Format(DocHeader.RecordId()), DocHeader.SystemRowVersion);
        DocHeader.Get(SandboxDraftDocHeader.ID);
        Snapshot.Add(Format(DocHeader.RecordId()), DocHeader.SystemRowVersion);
        TransmissionLog.SetRange("Transmission Document ID", SandboxOtherTransmission."Document ID");
        TransmissionLog.FindFirst();
        Snapshot.Add(Format(TransmissionLog.RecordId()), TransmissionLog.SystemRowVersion);
        TransmissionLogLine.SetRange("Transmission Log ID", TransmissionLog."Line ID");
        TransmissionLogLine.FindFirst();
        Snapshot.Add(Format(TransmissionLogLine.RecordId()), TransmissionLogLine.SystemRowVersion);
        ErrorInformation.Get(SandboxErrorID + 1);
        Snapshot.Add(Format(ErrorInformation.RecordId()), ErrorInformation.SystemRowVersion);
        CaptureSandboxUnrelatedDocumentContents(SandboxOtherDocHeader.ID, Snapshot);
        CaptureSandboxUnrelatedDocumentContents(SandboxDraftDocHeader.ID, Snapshot);
    end;

    local procedure CaptureSandboxUnrelatedRecords(var Snapshot: Dictionary of [Text, BigInteger])
    begin
        CaptureSandboxSharedRecords(Snapshot);
        CaptureSandboxUnrelatedHistory(Snapshot);
    end;


    local procedure CreateTransmissionWithSingleFormDoc(var Transmission: Record "Transmission IRIS"; var IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header")
    var
        ReportingPeriod: Record "IRS Reporting Period";
        MockKeyVaultClientIRIS: Codeunit "Mock Key Vault Client IRIS";
    begin
        if not ReportingPeriod.Get('2025') then
            InitializeReportingPeriodAndForms(2025);
        SetPeriodSchema('2025', "XML Schema Version IRIS"::"2.0.3");
        MockKeyVaultClientIRIS.SetSoftwareId('25TEST0001');
        CreateReleasedFormDocument(IRS1099FormDocHeader, 2025);
        LibraryIRS1099IRIS.CreateTransmission(Transmission, IRS1099FormDocHeader."Period No.");
        IRS1099FormDocHeader.Get(IRS1099FormDocHeader.ID);
    end;

    local procedure CreateReleasedFormDocument(var IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; Year: Integer)
    var
        Vendor: Record Vendor;
        StartingDate: Date;
        EndingDate: Date;
        PeriodNo: Code[20];
    begin
        StartingDate := DMY2Date(1, 1, Year);
        EndingDate := CalcDate('<CY>', StartingDate);
        PeriodNo := Format(Year);

        LibraryIRS1099IRIS.CreateUSVendor(Vendor);

        // Identity/XML tests need two reportable forms, not direct-sales boxes whose $5,000 minimum exceeds the invoice factory's lower bound.
        LibraryIRS1099Document.CreateAndPostPurchaseDocument("Purchase Document Type"::Invoice, Vendor."No.", Year, 'MISC', 'MISC-03');
        LibraryIRS1099Document.CreateAndPostPurchaseDocument("Purchase Document Type"::Invoice, Vendor."No.", Year, 'NEC', 'NEC-01');

        LibraryIRS1099Document.CreateFormDocuments(StartingDate, EndingDate, Vendor."No.");
        IRS1099FormDocHeader.SetRange("Period No.", PeriodNo);
        IRS1099FormDocHeader.SetRange("Vendor No.", Vendor."No.");
        IRS1099FormDocHeader.FindFirst();
        IRS1099FormDocHeader.Validate(Status, IRS1099FormDocHeader.Status::Released);
        IRS1099FormDocHeader.Modify(true);
    end;

    local procedure CreateReleasedFormDocForVendor(var IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; VendorNo: Code[20]; FormNo: Code[20]; FormBoxNo: Code[20])
    var
        Year: Integer;
        StartingDate: Date;
        EndingDate: Date;
        PeriodNo: Code[20];
    begin
        Year := Date2DMY(WorkDate(), 3);
        StartingDate := DMY2Date(1, 1, Year);
        EndingDate := CalcDate('<CY>', StartingDate);
        PeriodNo := Format(Year);

        LibraryIRS1099Document.CreateAndPostPurchaseDocument("Purchase Document Type"::Invoice, VendorNo, Year, FormNo, FormBoxNo);
        LibraryIRS1099Document.CreateFormDocuments(StartingDate, EndingDate, VendorNo);

        IRS1099FormDocHeader.SetRange("Period No.", PeriodNo);
        IRS1099FormDocHeader.SetRange("Vendor No.", VendorNo);
        IRS1099FormDocHeader.SetRange("Form No.", FormNo);
        IRS1099FormDocHeader.FindFirst();
        IRS1099FormDocHeader.Validate(Status, IRS1099FormDocHeader.Status::Released);
        IRS1099FormDocHeader.Modify(true);
    end;

    local procedure CreateContractTransmission(var Transmission: Record "Transmission IRIS"; var IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; Year: Integer)
    var
        Vendor: Record Vendor;
        ReportingPeriod: Record "IRS Reporting Period";
        IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
        MockKeyVaultClientIRIS: Codeunit "Mock Key Vault Client IRIS";
    begin
        if not ReportingPeriod.Get(Format(Year)) then
            InitializeReportingPeriodAndForms(Year);
        SetPeriodSchema(Format(Year), "XML Schema Version IRIS"::"5.0.7");
        MockKeyVaultClientIRIS.SetSoftwareId(CopyStr(Format(Year), 3, 2) + 'TEST0001');
        UpdateCompanyContactInfo('Test Contact', '1234567890', 'test@example.com');
        LibraryIRS1099IRIS.CreateUSVendor(Vendor);
        IRS1099FormDocHeader.Init();
        IRS1099FormDocHeader."Period No." := Format(Year);
        IRS1099FormDocHeader."Vendor No." := Vendor."No.";
        IRS1099FormDocHeader."Form No." := 'NEC';
        IRS1099FormDocHeader.Status := IRS1099FormDocHeader.Status::Released;
        IRS1099FormDocHeader.Insert(true);
        IRS1099FormDocLine.Init();
        IRS1099FormDocLine."Document ID" := IRS1099FormDocHeader.ID;
        IRS1099FormDocLine."Line No." := 10000;
        IRS1099FormDocLine."Period No." := Format(Year);
        IRS1099FormDocLine."Vendor No." := Vendor."No.";
        IRS1099FormDocLine."Form No." := 'NEC';
        IRS1099FormDocLine."Form Box No." := 'NEC-01';
        IRS1099FormDocLine.Amount := 5000;
        IRS1099FormDocLine."Include In 1099" := true;
        IRS1099FormDocLine.Insert();
        LibraryIRS1099IRIS.CreateTransmission(Transmission, Format(Year));
        IRS1099FormDocHeader.Get(IRS1099FormDocHeader.ID);
    end;

    local procedure CreateLifecycleTransmission(var Transmission: Record "Transmission IRIS"; var IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; Year: Integer; FormNo: Code[20])
    var
        IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
    begin
        CreateContractTransmission(Transmission, IRS1099FormDocHeader, Year);
        if FormNo <> IRS1099FormDocHeader."Form No." then begin
            IRS1099FormDocLine.Get(IRS1099FormDocHeader."Period No.", IRS1099FormDocHeader."Vendor No.", IRS1099FormDocHeader."Form No.", IRS1099FormDocHeader.ID, 10000);
            IRS1099FormDocLine.Rename(IRS1099FormDocHeader."Period No.", IRS1099FormDocHeader."Vendor No.", FormNo, IRS1099FormDocHeader.ID, 10000);
            IRS1099FormDocLine."Form Box No." := 'MISC-03';
            IRS1099FormDocLine.Modify();
            IRS1099FormDocHeader."Form No." := FormNo;
            IRS1099FormDocHeader.Modify();
        end;
        if Year = 2026 then
            SetSupplementalValues(IRS1099FormDocHeader, 100, 50, '101', '000');
    end;

    local procedure CreateOfflineAcknowledgment(): Text
    var
        Content: TextBuilder;
        SubmissionID: Text;
    begin
        Content.Append('<Ack xmlns="urn:us:gov:treasury:irs:ir"><ResultGrp><TransmissionResultGrp>');
        Content.Append('<UniqueTransmissionId>' + OfflineUTID + '</UniqueTransmissionId>');
        Content.Append('<ReceiptId>' + OfflineReceiptID + '</ReceiptId><TransmissionStatusCd>' + OfflineStatus + '</TransmissionStatusCd>');
        if OfflinePreReceiptError then
            Content.Append('<ErrorInformationGrp><ErrorMessageCd>XML Schema Validation Error</ErrorMessageCd><ErrorMessageTxt>SIMULATED pre-receipt validation failure</ErrorMessageTxt></ErrorInformationGrp>');
        Content.Append('</TransmissionResultGrp>');
        foreach SubmissionID in OfflineSubmissionStatuses.Keys() do begin
            Content.Append('<SubmissionResultGrp><SubmissionId>' + SubmissionID + '</SubmissionId><SubmissionStatusCd>' +
                OfflineSubmissionStatuses.Get(SubmissionID) + '</SubmissionStatusCd>');
            if OfflineRecordError then
                Content.Append('<RecordResultGrp><RecordId>1</RecordId><ErrorInformationGrp><ErrorMessageCd>SIMULATED-RECORD</ErrorMessageCd><ErrorMessageTxt>SIMULATED record disclosure error</ErrorMessageTxt></ErrorInformationGrp></RecordResultGrp>');
            Content.Append('</SubmissionResultGrp>');
        end;
        Content.Append('</ResultGrp></Ack>');
        exit(Content.ToText());
    end;

    local procedure CreateSupplementalTransmission(var Transmission: Record "Transmission IRIS"; var IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; FormNo: Code[20])
    var
        IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
    begin
        CreateContractTransmission(Transmission, IRS1099FormDocHeader, 2026);
        if FormNo = 'MISC' then begin
            IRS1099FormDocLine.SetRange("Document ID", IRS1099FormDocHeader.ID);
            IRS1099FormDocLine.FindFirst();
            IRS1099FormDocLine.Rename('2026', IRS1099FormDocHeader."Vendor No.", FormNo, IRS1099FormDocHeader.ID, IRS1099FormDocLine."Line No.");
            IRS1099FormDocLine."Form Box No." := 'MISC-03';
            IRS1099FormDocLine.Modify();
            IRS1099FormDocHeader."Form No." := FormNo;
            IRS1099FormDocHeader.Modify();
        end;
        SetSupplementalValues(IRS1099FormDocHeader, 100, 50, '101', '000');
    end;

    local procedure CreateSupplementalXml(Transmission: Record "Transmission IRIS"; TransmissionType: Enum "Transmission Type IRIS"; ZeroCorrection: Boolean; var TempBlob: Codeunit "Temp Blob")
    var
        TempIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header" temporary;
        UniqueTransmissionId: Text[100];
    begin
        Clear(TempBlob);
        LibraryIRS1099IRIS.CreateTransmissionXmlContent(Transmission, TransmissionType, ZeroCorrection, UniqueTransmissionId, TempIRS1099FormDocHeader, TempBlob);
    end;

    local procedure CreateAcceptedCorrectionSource(var Transmission: Record "Transmission IRIS"; var IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header")
    begin
        CreateLifecycleTransmission(Transmission, IRS1099FormDocHeader, 2026, 'NEC');
        SetLifecycleReference(IRS1099FormDocHeader, Transmission."Document ID", '1', '2', "Transmission Status IRIS"::Accepted, true);
        Transmission.Status := Transmission.Status::Accepted;
        Transmission."Receipt ID" := 'ACCEPTED';
        Transmission.Modify();
        InitializeOfflineTransport(Transmission);
    end;

    local procedure CreateFilingAttempt(Transmission: Record "Transmission IRIS"; TransmissionType: Enum "Transmission Type IRIS"; ReceiptID: Text[100]; var TransmissionLog: Record "Transmission Log IRIS")
    begin
        TransmissionLog.Init();
        TransmissionLog."Transmission Document ID" := Transmission."Document ID";
        TransmissionLog."Period No." := Transmission."Period No.";
        TransmissionLog."Transmission Type" := TransmissionType;
        TransmissionLog."Receipt ID" := ReceiptID;
        TransmissionLog."Unique Transmission ID" := Format(CreateGuid());
        TransmissionLog."Response Http Status Code" := 200;
        TransmissionLog.Insert();
    end;

    local procedure CreatePendingZeroCorrection(var Transmission: Record "Transmission IRIS"; var IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header")
    begin
        CreateAcceptedCorrectionSource(Transmission, IRS1099FormDocHeader);
        OfflineStatus := 'Processing';
        OfflineSubmissionStatuses.Add('1', 'Processing');
        QueueOfflineSend();
        LibraryIRS1099IRIS.SendCorrection(Transmission, true);
    end;

    local procedure CreateRejectedZeroCorrection(var Transmission: Record "Transmission IRIS"; var IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header")
    begin
        CreateAcceptedCorrectionSource(Transmission, IRS1099FormDocHeader);
        OfflineReceiptID := 'REJECTED-ZERO';
        OfflineStatus := 'Rejected';
        OfflineSubmissionStatuses.Add('1', 'Rejected');
        QueueOfflineSend();
        LibraryIRS1099IRIS.SendCorrection(Transmission, true);
    end;

    local procedure CreateSandboxHistory(Transmission: Record "Transmission IRIS"; DocumentID: Integer): Integer
    var
        TransmissionLog: Record "Transmission Log IRIS";
        TransmissionLogLine: Record "Transmission Log Line IRIS";
    begin
        TransmissionLog."Transmission Document ID" := Transmission."Document ID";
        TransmissionLog."Period No." := Transmission."Period No.";
        TransmissionLog."Transmission Status" := Transmission.Status;
        TransmissionLog.Insert();
        TransmissionLogLine."Transmission Log ID" := TransmissionLog."Line ID";
        TransmissionLogLine."Line ID" := 1;
        TransmissionLogLine."IRS 1099 Form Document ID" := DocumentID;
        TransmissionLogLine.Insert();
        exit(TransmissionLog."Line ID");
    end;

    local procedure CreateSandboxRemovalTestData()
    var
        TransmissionLogLine: Record "Transmission Log Line IRIS";
        ErrorInformation: Record "Error Information IRIS";
        MissingDocHeader: Record "IRS 1099 Form Doc. Header";
    begin
        CreateLifecycleTransmission(SandboxTransmission, SandboxDocHeader, 2026, 'NEC');
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        EnvironmentInfoTestLibrary.SetTestabilitySandbox(true);
        SandboxTransmission.Status := SandboxTransmission.Status::Accepted;
        SandboxTransmission."Receipt ID" := 'SANDBOX-RECEIPT';
        SandboxTransmission.Modify();
        SetSandboxFilingFields(SandboxDocHeader, SandboxTransmission."Document ID", SandboxDocHeader.Status::Submitted);
        SetTransmissionUpdateAdjustment(SandboxDocHeader, 'NEC-01', 5000);
        CreateSandboxStoredContents(SandboxDocHeader);

        AddSupplementalHeader(SandboxDocHeader, SandboxAbandonedDocHeader, true);
        SetSandboxFilingFields(SandboxAbandonedDocHeader, 0, SandboxAbandonedDocHeader.Status::Abandoned);
        CreateSandboxStoredContents(SandboxAbandonedDocHeader);
        SandboxHistoryID := CreateSandboxHistory(SandboxTransmission, SandboxDocHeader.ID);
        TransmissionLogLine."Transmission Log ID" := SandboxHistoryID;
        TransmissionLogLine."Line ID" := 2;
        TransmissionLogLine."IRS 1099 Form Document ID" := SandboxAbandonedDocHeader.ID;
        TransmissionLogLine.Insert();
        AddSupplementalHeader(SandboxDocHeader, MissingDocHeader, false);
        MissingDocHeader.Status := MissingDocHeader.Status::Open;
        MissingDocHeader."IRIS Transmission Document ID" := 0;
        MissingDocHeader.Modify(true);
        TransmissionLogLine."Line ID" := 3;
        TransmissionLogLine."IRS 1099 Form Document ID" := MissingDocHeader.ID;
        TransmissionLogLine.Insert();
        MissingDocHeader.Delete(true);
        CreateSandboxHistory(SandboxTransmission, SandboxAbandonedDocHeader.ID);

        SandboxOtherTransmission := SandboxTransmission;
        SandboxOtherTransmission."Document ID" += 1;
        SandboxOtherTransmission.Insert();
        AddSupplementalHeader(SandboxDocHeader, SandboxOtherDocHeader, false);
        SetSandboxFilingFields(SandboxOtherDocHeader, SandboxOtherTransmission."Document ID", SandboxOtherDocHeader.Status::Submitted);
        AddSupplementalHeader(SandboxDocHeader, SandboxDraftDocHeader, false);
        SetSandboxFilingFields(SandboxDraftDocHeader, 0, SandboxDraftDocHeader.Status::Open);
        CreateSandboxHistory(SandboxOtherTransmission, SandboxOtherDocHeader.ID);
        ErrorInformation."Line ID" := LibraryUtility.GetNewRecNo(ErrorInformation, ErrorInformation.FieldNo("Line ID"));
        ErrorInformation."Transmission Document ID" := SandboxTransmission."Document ID";
        ErrorInformation."Error Code" := 'SANDBOX';
        ErrorInformation.Insert();
        SandboxErrorID := ErrorInformation."Line ID";
        ErrorInformation."Line ID" += 1;
        ErrorInformation."Transmission Document ID" := SandboxOtherTransmission."Document ID";
        ErrorInformation.Insert();
        SandboxOtherTransmission.Get(SandboxOtherTransmission."Document ID");
        SandboxOtherDocHeader.Get(SandboxOtherDocHeader.ID);
        SandboxDraftDocHeader.Get(SandboxDraftDocHeader.ID);
        CaptureSandboxUnrelatedRecords(SandboxSharedSnapshot);
        CaptureSandboxContentsSnapshot(SandboxContentsSnapshot);
        CaptureSandboxAllRecords(SandboxAllSnapshot);
    end;

    local procedure CreateSandboxStoredContents(DocHeader: Record "IRS 1099 Form Doc. Header")
    var
        DocLine: Record "IRS 1099 Form Doc. Line";
        DocLineDetail: Record "IRS 1099 Form Doc. Line Detail";
        FormReport: Record "IRS 1099 Form Report";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Content: OutStream;
        PostedDocumentNo: Code[20];
    begin
        DocLine.SetRange("Document ID", DocHeader.ID);
        DocLine.FindFirst();
        DocLine."Calculated Amount" := 4500;
        DocLine.Amount := 6000;
        DocLine."Manually Changed" := true;
        DocLine.Modify();
        PostedDocumentNo := LibraryIRS1099Document.CreateAndPostPurchaseDocument(
            "Purchase Document Type"::Invoice, DocHeader."Vendor No.", 2026, 'NEC', 'NEC-01');
        VendorLedgerEntry.SetRange("Document No.", PostedDocumentNo);
        VendorLedgerEntry.FindFirst();
        DocLineDetail."Document ID" := DocHeader.ID;
        DocLineDetail."Line No." := DocLine."Line No.";
        DocLineDetail."Vendor Ledger Entry No." := VendorLedgerEntry."Entry No.";
        DocLineDetail."Calculated Amount" := 4500;
        DocLineDetail.Insert();
        FormReport."Document ID" := DocHeader.ID;
        FormReport."File Content".CreateOutStream(Content);
        Content.WriteText('retained test PDF');
        FormReport.Insert();
    end;

    procedure FailSandboxRemovalOnHistory(HistoryID: Integer)
    begin
        SandboxFailHistoryID := HistoryID;
    end;

    local procedure FindLastAttempt(Transmission: Record "Transmission IRIS"; var TransmissionLog: Record "Transmission Log IRIS")
    begin
        TransmissionLog.Reset();
        TransmissionLog.SetRange("Transmission Document ID", Transmission."Document ID");
        Assert.IsTrue(TransmissionLog.FindLast(), 'An actual orchestrated attempt must be logged.');
    end;

    local procedure FindUnsentReplacement(SourceDocHeader: Record "IRS 1099 Form Doc. Header"; var ReplacementDocHeader: Record "IRS 1099 Form Doc. Header")
    begin
        ReplacementDocHeader.SetRange("Period No.", SourceDocHeader."Period No.");
        ReplacementDocHeader.SetRange("Vendor No.", SourceDocHeader."Vendor No.");
        ReplacementDocHeader.SetRange("Form No.", SourceDocHeader."Form No.");
        ReplacementDocHeader.SetFilter(ID, '<>%1', SourceDocHeader.ID);
        ReplacementDocHeader.SetRange(Status, ReplacementDocHeader.Status::Released);
        Assert.IsTrue(ReplacementDocHeader.FindFirst(), 'Update Transmission must create a released replacement.');
    end;

    local procedure FinishOfflineTransport()
    begin
        OfflineResponses.AssertEmpty();
        Assert.AreEqual(OfflineExpectedRequestKinds, OfflineObservedRequestKinds, 'HTTP requests must follow the configured probe, submission and acknowledgment sequence.');
        LibraryIRS1099IRIS.RestoreOfflineAccessToken();
        LibraryIRS1099IRIS.RestoreIRISUserID();
        RestoreOfflinePrivacyConsent();
        ResetStandardProvider();
    end;


    local procedure InitializeReportingPeriodAndForms(Year: Integer)
    var
        FormBox: Record "IRS 1099 Form Box";
        StartingDate: Date;
        EndingDate: Date;
    begin
        StartingDate := DMY2Date(1, 1, Year);
        EndingDate := CalcDate('<CY>', StartingDate);
        LibraryIRSReportingPeriod.CreateSpecificReportingPeriod(Format(Year), StartingDate, EndingDate);

        LibraryIRS1099FormBox.CreateSpecificFormInReportingPeriod(StartingDate, EndingDate, 'DIV');
        LibraryIRS1099FormBox.CreateSpecificFormBoxInReportingPeriod(StartingDate, EndingDate, 'DIV', 'DIV-01-A');

        LibraryIRS1099FormBox.CreateSpecificFormInReportingPeriod(StartingDate, EndingDate, 'INT');
        LibraryIRS1099FormBox.CreateSpecificFormBoxInReportingPeriod(StartingDate, EndingDate, 'INT', 'INT-01');

        LibraryIRS1099FormBox.CreateSpecificFormInReportingPeriod(StartingDate, EndingDate, 'MISC');
        LibraryIRS1099FormBox.CreateSpecificFormBoxInReportingPeriod(StartingDate, EndingDate, 'MISC', 'MISC-03');
        LibraryIRS1099FormBox.CreateSpecificFormBoxInReportingPeriod(StartingDate, EndingDate, 'MISC', 'MISC-07');
        FormBox.Get(Format(Year), 'MISC', 'MISC-07');
        FormBox.Validate("Minimum Reportable Amount", 5000);
        FormBox.Modify();

        LibraryIRS1099FormBox.CreateSpecificFormInReportingPeriod(StartingDate, EndingDate, 'NEC');
        LibraryIRS1099FormBox.CreateSpecificFormBoxInReportingPeriod(StartingDate, EndingDate, 'NEC', 'NEC-01');
        LibraryIRS1099FormBox.CreateSpecificFormBoxInReportingPeriod(StartingDate, EndingDate, 'NEC', 'NEC-02');
        LibraryIRS1099FormBox.CreateSpecificFormBoxInReportingPeriod(StartingDate, EndingDate, 'NEC', 'NEC-03');
        FormBox.Get(Format(Year), 'NEC', 'NEC-02');
        FormBox.Validate("Minimum Reportable Amount", 5000);
        FormBox.Modify();
        SetPeriodSchema(Format(Year), "XML Schema Version IRIS"::"2.0.3");
    end;

    local procedure InitXMLReader(var TempBlob: Codeunit "Temp Blob")
    begin
        LibraryXPathXMLReader.InitializeXml(TempBlob, 'n1', 'urn:us:gov:treasury:irs:ir');
    end;

    local procedure InitializeEmptySchemaPeriod()
    var
        ReportingPeriod: Record "IRS Reporting Period";
    begin
        if not ReportingPeriod.Get('2099') then
            LibraryIRSReportingPeriod.CreateSpecificReportingPeriod('2099', 20990101D, 20991231D);
        SetPeriodSchema('2099', "XML Schema Version IRIS"::" ");
    end;

    local procedure InitializeOfflineConfiguration()
    begin
        InitializeStandardProvider();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        EnvironmentInfoTestLibrary.SetTestabilitySandbox(true);
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-SoftwareID-2025', '25TEST0001');
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-SoftwareID-2026', '26TEST0001');
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-SoftwareDevTCC', 'TEST1');
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-TransmitterTCC', 'LIVE1');
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-ContactInfo', '{"ContactName":"Test Contact","ContactEmail":"test@example.com","ContactPhone":"1234567890"}');
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-SubmitEndpointTest', 'https://test.example/submit');
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-SubmitEndpointLive', 'https://production.example/submit');
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-GetStatusEndpointTest', 'https://test.example/status');
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-GetStatusEndpointLive', 'https://production.example/status');
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-AuthURLTest', 'https://test.example/auth');
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-AuthURLLive', 'https://production.example/auth');
    end;

    local procedure InitializeOfflineTransport(Transmission: Record "Transmission IRIS")
    begin
        OfflineTransmissionID := Transmission."Document ID";
        InitializeOfflineConfiguration();
        LibraryIRS1099IRIS.InitializeIRISUserID();
        LibraryIRS1099IRIS.InitializeOfflineAccessToken();
        OfflineOriginalPrivacyConsent := LibraryIRS1099IRIS.GetPrivacyConsent();
        OfflinePrivacyConsentSaved := true;
        LibraryIRS1099IRIS.SetPrivacyConsent(true);
        OfflineReceiptID := 'SIMULATED-RECEIPT';
        OfflineStatus := 'Accepted';
    end;

    local procedure InitializeStandardProvider()
    var
        IRSFormsSetup: Record "IRS Forms Setup";
    begin
        IRSFormsSetup.Get();
        IRSFormsSetup.Implementation := IRSFormsSetup.Implementation::Standard;
        IRSFormsSetup.Modify();
        MockAzureKeyVaultSecretProvider := MockAzureKeyVaultSecretProvider.MockAzureKeyVaultSecretProvider();
        AzureKeyVaultTestLibrary.SetAzureKeyVaultSecretProvider(MockAzureKeyVaultSecretProvider);
    end;

    local procedure InsertSupplementalStatement(BoxNo: Code[20]; LineNo: Integer; Description: Text[100])
    var
        StatementLine: Record "IRS 1099 Form Statement Line";
    begin
        StatementLine."Period No." := '2026';
        StatementLine."Form No." := 'NEC';
        StatementLine."Line No." := LineNo;
        StatementLine."Row No." := BoxNo;
        StatementLine.Description := Description;
        StatementLine."Value Source" := StatementLine."Value Source"::"Supplemental Line";
        StatementLine.Validate("Supplemental Box No.", BoxNo);
        StatementLine.Insert(true);
    end;


    local procedure InvokeAndDeclineSandboxDelete()
    var
        TransmissionPage: TestPage "Transmission IRIS";
    begin
        OpenSandboxTransmission(TransmissionPage);
        VerifySandboxActionVisibility(TransmissionPage, true);
        TransmissionPage.RemoveTransmissionAndDocuments.Invoke();
        TransmissionPage."Period No.".AssertEquals(SandboxTransmission."Period No.");
        TransmissionPage.Close();
    end;

    local procedure InvokeAndDeclineSandboxReset()
    var
        TransmissionPage: TestPage "Transmission IRIS";
    begin
        OpenSandboxTransmission(TransmissionPage);
        VerifySandboxActionVisibility(TransmissionPage, true);
        TransmissionPage.RemoveTransmissionAndResetDocuments.Invoke();
        TransmissionPage."Period No.".AssertEquals(SandboxTransmission."Period No.");
        TransmissionPage.Close();
    end;

    local procedure InvokeSandboxDelete(var TransmissionPage: TestPage "Transmission IRIS")
    begin
        OpenSandboxTransmission(TransmissionPage);
        TransmissionPage.RemoveTransmissionAndDocuments.Invoke();
    end;

    local procedure InvokeSandboxReset(var TransmissionPage: TestPage "Transmission IRIS")
    begin
        OpenSandboxTransmission(TransmissionPage);
        TransmissionPage.RemoveTransmissionAndResetDocuments.Invoke();
    end;

    local procedure MockOfflineAcknowledgmentResponse(var Response: TestHttpResponseMessage)
    begin
        OfflineAcknowledgment := CreateOfflineAcknowledgment();
        Response.Content.WriteFrom(OfflineAcknowledgment);
        Response.HttpStatusCode := OfflineStatusHttpStatus;
    end;

    local procedure OpenSandboxTransmission(var TransmissionPage: TestPage "Transmission IRIS")
    begin
        TransmissionPage.OpenEdit();
        TransmissionPage.GoToRecord(SandboxTransmission);
    end;

    local procedure QueueOfflineAcknowledgment()
    begin
        QueueOfflineTokenProbe();
        OfflineResponses.Enqueue('Acknowledgment');
        OfflineExpectedRequestKinds += '|status';
    end;

    local procedure QueueOfflineEditedAcknowledgment(DocumentID: Integer)
    begin
        QueueOfflineTokenProbe();
        OfflineResponses.Enqueue('EditedAcknowledgment');
        OfflineResponses.Enqueue(DocumentID);
        OfflineExpectedRequestKinds += '|status';
    end;

    local procedure QueueOfflineHistorylessAcknowledgment()
    begin
        QueueOfflineTokenProbe();
        OfflineResponses.Enqueue('HistorylessAcknowledgment');
        OfflineExpectedRequestKinds += '|status';
    end;

    local procedure QueueOfflineSend()
    begin
        QueueOfflineSubmission();
        QueueOfflineAcknowledgment();
    end;

    local procedure QueueOfflineSubmission()
    begin
        QueueOfflineTokenProbe();
        OfflineResponses.Enqueue('Submission');
        OfflineExpectedRequestKinds += '|submit';
    end;

    local procedure QueueOfflineSubmissionWithoutReceipt()
    begin
        QueueOfflineTokenProbe();
        OfflineResponses.Enqueue('SubmissionWithoutReceipt');
        OfflineExpectedRequestKinds += '|submit';
    end;

    local procedure QueueOfflineTokenProbe()
    begin
        OfflineResponses.Enqueue('TokenProbe');
        OfflineExpectedRequestKinds += '|status';
    end;

    local procedure ReadAttemptContent(var TransmissionLog: Record "Transmission Log IRIS"; FieldNumber: Integer): Text
    var
        Base64Convert: Codeunit "Base64 Convert";
    begin
        exit(Base64Convert.FromBase64(ReadAttemptContentBytes(TransmissionLog, FieldNumber)));
    end;

    local procedure ReadAttemptContentBytes(var TransmissionLog: Record "Transmission Log IRIS"; FieldNumber: Integer): Text
    var
        Base64Convert: Codeunit "Base64 Convert";
        Content: InStream;
    begin
        TransmissionLog.Get(TransmissionLog."Line ID");
        case FieldNumber of
            20:
                begin
                    TransmissionLog.CalcFields("Transmission Content");
                    TransmissionLog."Transmission Content".CreateInStream(Content, TextEncoding::UTF8);
                end;
            30:
                begin
                    TransmissionLog.CalcFields("Acceptance Response Content");
                    TransmissionLog."Acceptance Response Content".CreateInStream(Content, TextEncoding::UTF8);
                end;
            40:
                begin
                    TransmissionLog.CalcFields("Acknowledgement Content");
                    TransmissionLog."Acknowledgement Content".CreateInStream(Content, TextEncoding::UTF8);
                end;
        end;
        exit(Base64Convert.ToBase64(Content));
    end;


    local procedure RecreateSandboxRemovalTransmission(var StaleTransmission: Record "Transmission IRIS")
    begin
        StaleTransmission := SandboxTransmission;
        SandboxTransmission.Delete(false);
        Clear(SandboxTransmission);
        SandboxTransmission."Document ID" := StaleTransmission."Document ID";
        SandboxTransmission."Period No." := StaleTransmission."Period No.";
        SandboxTransmission.Status := SandboxTransmission.Status::Processing;
        SandboxTransmission."Receipt ID" := 'REPLACEMENT-RECEIPT';
        SandboxTransmission.Insert(true);
        SandboxTransmission.Get(SandboxTransmission."Document ID");
        Assert.AreNotEqual(StaleTransmission.SystemId, SandboxTransmission.SystemId, 'The new test transmission must reuse the numeric ID but have a different SystemId.');
        CaptureSandboxAllRecords(SandboxAllSnapshot);
    end;

    local procedure ResetStandardProvider()
    begin
        AzureKeyVaultTestLibrary.ClearSecrets();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        EnvironmentInfoTestLibrary.SetTestabilitySandbox(false);
    end;

    local procedure ReopenAndEditPendingCorrection(var IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header")
    var
        DocumentPage: TestPage "IRS 1099 Form Document";
    begin
        DocumentPage.OpenEdit();
        DocumentPage.GoToRecord(IRS1099FormDocHeader);
        DocumentPage.AllowCorrection.Invoke();
        DocumentPage.Reopen.Invoke();
        DocumentPage.Close();
        IRS1099FormDocHeader.Get(IRS1099FormDocHeader.ID);
        SetSupplementalValues(IRS1099FormDocHeader, 200, 50, '101', '000');
    end;

    local procedure RequestAcceptedCorrection(var Transmission: Record "Transmission IRIS")
    var
        TransmissionLog: Record "Transmission Log IRIS";
    begin
        OfflineStatus := 'Accepted';
        OfflineSubmissionStatuses.Set('1', 'Accepted');
        FindLastAttempt(Transmission, TransmissionLog);
        QueueOfflineAcknowledgment();
        LibraryIRS1099IRIS.RequestAcknowledgementAndUpdateTransmission(Transmission, Transmission."Receipt ID", TransmissionLog."Unique Transmission ID");
        Transmission.Get(Transmission."Document ID");
    end;

    local procedure RestoreOfflinePrivacyConsent()
    begin
        if not OfflinePrivacyConsentSaved then
            exit;
        LibraryIRS1099IRIS.SetPrivacyConsent(OfflineOriginalPrivacyConsent);
        Clear(OfflinePrivacyConsentSaved);
    end;

    local procedure SetCorrectionReference(var IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header")
    begin
        IRS1099FormDocHeader.Get(IRS1099FormDocHeader.ID);
        IRS1099FormDocHeader."IRIS Last Accepted Receipt ID" := 'ACCEPTED';
        IRS1099FormDocHeader."IRIS Submission ID" := '1';
        IRS1099FormDocHeader."IRIS Record ID" := '2';
        IRS1099FormDocHeader."IRIS Needs Correction" := true;
        IRS1099FormDocHeader.Modify();
    end;

    local procedure SetDocLineAmount(IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; BoxNo: Code[20]; Amount: Decimal; MinimumAmount: Decimal)
    var
        IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
    begin
        IRS1099FormDocLine.SetRange("Document ID", IRS1099FormDocHeader.ID);
        IRS1099FormDocLine.SetRange("Form Box No.", BoxNo);
        if not IRS1099FormDocLine.FindFirst() then begin
            IRS1099FormDocLine.Init();
            IRS1099FormDocLine."Period No." := IRS1099FormDocHeader."Period No.";
            IRS1099FormDocLine."Vendor No." := IRS1099FormDocHeader."Vendor No.";
            IRS1099FormDocLine."Form No." := IRS1099FormDocHeader."Form No.";
            IRS1099FormDocLine."Document ID" := IRS1099FormDocHeader.ID;
            IRS1099FormDocLine."Line No." := LibraryUtility.GetNewRecNo(IRS1099FormDocLine, IRS1099FormDocLine.FieldNo("Line No."));
            IRS1099FormDocLine."Form Box No." := BoxNo;
            IRS1099FormDocLine.Insert();
        end;
        IRS1099FormDocLine.Amount := Amount;
        IRS1099FormDocLine."Minimum Reportable Amount" := MinimumAmount;
        IRS1099FormDocLine.Modify();
        LibraryIRS1099Document.RecalculateIncludeIn1099(IRS1099FormDocHeader.ID);
    end;

    local procedure SetLifecycleReference(var IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; TransmissionID: Integer; SubmissionID: Text[20]; RecordID: Text[20]; SubmissionStatus: Enum "Transmission Status IRIS"; NeedsCorrection: Boolean)
    begin
        IRS1099FormDocHeader."IRIS Transmission Document ID" := TransmissionID;
        IRS1099FormDocHeader."IRIS Submission ID" := SubmissionID;
        IRS1099FormDocHeader."IRIS Record ID" := RecordID;
        IRS1099FormDocHeader."IRIS Last Receipt ID" := 'ACCEPTED';
        IRS1099FormDocHeader."IRIS Last Accepted Receipt ID" := 'ACCEPTED';
        IRS1099FormDocHeader."IRIS Submission Status" := SubmissionStatus;
        IRS1099FormDocHeader."IRIS Needs Correction" := NeedsCorrection;
        IRS1099FormDocHeader.Status := IRS1099FormDocHeader.Status::Submitted;
        IRS1099FormDocHeader.Modify();
    end;

    local procedure SetPeriodSchema(PeriodNo: Code[20]; SchemaVersion: Enum "XML Schema Version IRIS")
    var
        ReportingPeriod: Record "IRS Reporting Period";
    begin
        ReportingPeriod.Get(PeriodNo);
        ReportingPeriod.Validate("IRIS XML Schema Version Test", SchemaVersion);
        ReportingPeriod.Validate("IRIS XML Schema Version Live", SchemaVersion);
        ReportingPeriod.Modify();
    end;

    local procedure SetSupplementalLine(IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; BoxNo: Code[20]; Amount: Decimal; OccupationCode1: Text[3]; OccupationCode2: Text[3])
    var
        SupplementalBox: Record "IRS 1099 Suppl. Box";
        SupplementalLine: Record "IRS 1099 Doc. Suppl. Line";
    begin
        if not SupplementalBox.Get(IRS1099FormDocHeader."Period No.", IRS1099FormDocHeader."Form No.", BoxNo) then
            LibraryIRS1099Document.CreateSupplementalBox(IRS1099FormDocHeader."Period No.", IRS1099FormDocHeader."Form No.", BoxNo);
        if not SupplementalLine.Get(IRS1099FormDocHeader.ID, BoxNo) then begin
            SupplementalLine.Init();
            SupplementalLine."Document ID" := IRS1099FormDocHeader.ID;
            SupplementalLine.Validate("Supplemental Box No.", BoxNo);
            SupplementalLine.Insert(true);
        end;
        SupplementalLine.Validate(Amount, Amount);
        SupplementalLine.Validate("Occupation Code 1", OccupationCode1);
        SupplementalLine.Validate("Occupation Code 2", OccupationCode2);
        SupplementalLine.Modify(true);
    end;

    local procedure SetSupplementalValues(var IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; Tips: Decimal; Overtime: Decimal; OccupationCode1: Text[3]; OccupationCode2: Text[3])
    var
        SavedStatus: Enum "IRS 1099 Form Doc. Status";
    begin
        IRS1099FormDocHeader.Get(IRS1099FormDocHeader.ID);
        SavedStatus := IRS1099FormDocHeader.Status;
        IRS1099FormDocHeader.Status := IRS1099FormDocHeader.Status::Open;
        IRS1099FormDocHeader.Modify();
        if IRS1099FormDocHeader."Form No." = 'NEC' then begin
            SetSupplementalLine(IRS1099FormDocHeader, 'NEC-01B', Tips, '', '');
            SetSupplementalLine(IRS1099FormDocHeader, 'NEC-01C', 0, OccupationCode1, OccupationCode2);
            SetSupplementalLine(IRS1099FormDocHeader, 'NEC-01D', Overtime, '', '');
        end else begin
            SetSupplementalLine(IRS1099FormDocHeader, 'MISC-13A', Tips, '', '');
            SetSupplementalLine(IRS1099FormDocHeader, 'MISC-13B', 0, OccupationCode1, OccupationCode2);
            SetSupplementalLine(IRS1099FormDocHeader, 'MISC-14', Overtime, '', '');
        end;
        IRS1099FormDocHeader.Status := SavedStatus;
        IRS1099FormDocHeader.Modify();
    end;

    local procedure SetTransmissionUpdateAdjustment(DocHeader: Record "IRS 1099 Form Doc. Header"; BoxNo: Code[20]; Amount: Decimal)
    var
        Adjustment: Record "IRS 1099 Vendor Form Box Adj.";
    begin
        Adjustment.Validate("Period No.", DocHeader."Period No.");
        Adjustment.Validate("Vendor No.", DocHeader."Vendor No.");
        Adjustment.Validate("Form No.", DocHeader."Form No.");
        Adjustment.Validate("Form Box No.", BoxNo);
        Adjustment.Validate(Amount, Amount);
        Adjustment.Insert(true);
    end;

    local procedure SetSandboxFilingFields(var DocHeader: Record "IRS 1099 Form Doc. Header"; TransmissionID: Integer; DocumentStatus: Enum "IRS 1099 Form Doc. Status")
    begin
        DocHeader.Status := DocumentStatus;
        DocHeader."IRIS Transmission Document ID" := TransmissionID;
        DocHeader."IRIS Submission ID" := '1';
        DocHeader."IRIS Record ID" := '1';
        DocHeader."IRIS Last Receipt ID" := 'LAST';
        DocHeader."IRIS Last Accepted Receipt ID" := 'ACCEPTED';
        DocHeader."IRIS Submission Status" := DocHeader."IRIS Submission Status"::Accepted;
        DocHeader."IRIS Needs Correction" := true;
        DocHeader."IRIS Updated Not Sent" := true;
        DocHeader."IRIS Corrected" := true;
        DocHeader."IRIS Corrected to Zeros" := true;
        DocHeader."Allow Correction" := true;
        DocHeader.Modify();
    end;

    local procedure SetSandboxHistoricalYear()
    var
        Form: Record "IRS 1099 Form";
        ReportingPeriod: Record "IRS Reporting Period";
        PeriodNo: Code[20];
        ReportingDate: Date;
    begin
        ReportingPeriod.FindSet();
        ReportingDate := ReportingPeriod."Starting Date";
        repeat
            ReportingDate := LibraryERM.MinDate(ReportingDate, ReportingPeriod."Starting Date");
        until ReportingPeriod.Next() = 0;
        ReportingDate := CalcDate('<-1D>', ReportingDate);
        PeriodNo := LibraryIRSReportingPeriod.CreateOneDayReportingPeriod(ReportingDate);
        Form."Period No." := PeriodNo;
        Form."No." := SandboxAbandonedDocHeader."Form No.";
        Form.Insert(true);
        SandboxAbandonedDocHeader."Period No." := PeriodNo;
        SandboxAbandonedDocHeader.Modify();
    end;

    local procedure SetSandboxTransmissionProcessing()
    begin
        SandboxTransmission.Status := SandboxTransmission.Status::Processing;
        SandboxTransmission.Modify();
    end;

    local procedure UpdateCompanyContactInfo(ContactPerson: Text[50]; PhoneNo: Text[30]; Email: Text[80])
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation."Contact Person" := ContactPerson;
        CompanyInformation."Phone No." := PhoneNo;
        CompanyInformation."E-Mail" := Email;
        CompanyInformation.Modify();
    end;

    local procedure UpdateVendorProvinceOrState(VendorNo: Code[20]; ProvinceOrStateCode: Text[30])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        Vendor.County := ProvinceOrStateCode;
        Vendor.Modify();
    end;

    local procedure UpdateVendorFederalId(VendorNo: Code[20]; FederalId: Text[30])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        Vendor."Federal ID No." := FederalId;
        Vendor.Modify();
    end;

    local procedure SetUnsentCorrectionDuringAcknowledgment(DocumentID: Integer)
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
    begin
        DocHeader.Get(DocumentID);
        SetDocLineAmount(DocHeader, 'NEC-01', 6000, 2000);
        DocHeader."IRIS Updated Not Sent" := true;
        DocHeader."IRIS Needs Correction" := true;
        DocHeader.Modify();
    end;

    local procedure VerifyActualNonzeroCorrection(Year: Integer; FormNo: Code[20])
    var
        Transmission: Record "Transmission IRIS";
        OtherTransmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        UnselectedIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        TransmissionLog: Record "Transmission Log IRIS";
        IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
        Payload: Codeunit "Temp Blob";
        UnselectedModifiedAt: DateTime;
    begin
        CreateLifecycleTransmission(Transmission, IRS1099FormDocHeader, Year, FormNo);
        CreateLifecycleTransmission(OtherTransmission, UnselectedIRS1099FormDocHeader, Year, FormNo);
        SetLifecycleReference(IRS1099FormDocHeader, Transmission."Document ID", '1', '2', "Transmission Status IRIS"::Accepted, true);
        SetLifecycleReference(UnselectedIRS1099FormDocHeader, Transmission."Document ID", '1', '3', "Transmission Status IRIS"::Accepted, false);
        UnselectedModifiedAt := UnselectedIRS1099FormDocHeader.SystemModifiedAt;
        IRS1099FormDocLine.SetRange("Document ID", IRS1099FormDocHeader.ID);
        IRS1099FormDocLine.FindFirst();
        IRS1099FormDocLine.Amount := 6000;
        IRS1099FormDocLine."Manually Changed" := true;
        IRS1099FormDocLine.Modify();
        if Year = 2026 then
            SetSupplementalValues(IRS1099FormDocHeader, 120, 60, '101', '000');
        Transmission.Status := Transmission.Status::Accepted;
        Transmission."Receipt ID" := 'ACCEPTED';
        Transmission.Modify();
        InitializeOfflineTransport(Transmission);

        QueueOfflineSend();
        LibraryIRS1099IRIS.SendCorrection(Transmission, false);

        FindLastAttempt(Transmission, TransmissionLog);
        WriteTextBlob(Payload, ReadAttemptContent(TransmissionLog, 20));
        VerifyLifecycleAmounts(IRS1099FormDocHeader, Payload, '6000', '120', '60');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:TransmissionTypeCd', 'C');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:TotalRecipientFormCnt', '1');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:PrevSubmittedRecRecipientGrp/n1:OtherIntakeSystemInd/following-sibling::*[1][self::n1:UniqueRecordId]', 'ACCEPTED|1|2');
        IRS1099FormDocHeader.Get(IRS1099FormDocHeader.ID);
        Assert.AreEqual(IRS1099FormDocHeader.Status::Submitted, IRS1099FormDocHeader.Status, 'Nonzero correction is not abandoned.');
        Assert.IsFalse(IRS1099FormDocHeader."IRIS Corrected to Zeros", 'Nonzero correction is not a two-step zero.');
        Assert.AreEqual(OfflineReceiptID, IRS1099FormDocHeader."IRIS Last Accepted Receipt ID", 'Accepted correction advances the accepted receipt.');
        UnselectedIRS1099FormDocHeader.Get(UnselectedIRS1099FormDocHeader.ID);
        Assert.AreEqual(UnselectedModifiedAt, UnselectedIRS1099FormDocHeader.SystemModifiedAt, 'Unselected source is never written.');
        VerifyLifecycleSource(UnselectedIRS1099FormDocHeader, Year);
        if Year = 2026 then
            VerifySavedSupplementalValues(IRS1099FormDocHeader, 120, 60, '101', '000');
        FinishOfflineTransport();
    end;

    local procedure VerifyActualReplacement(Year: Integer; OverallStatus: Enum "Transmission Status IRIS"; Partial: Boolean)
    var
        Transmission: Record "Transmission IRIS";
        OtherTransmission: Record "Transmission IRIS";
        RejectedIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        OtherIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        TransmissionLog: Record "Transmission Log IRIS";
        Payload: Codeunit "Temp Blob";
        AcceptedModifiedAt: DateTime;
    begin
        CreateLifecycleTransmission(Transmission, RejectedIRS1099FormDocHeader, Year, 'NEC');
        CreateLifecycleTransmission(OtherTransmission, OtherIRS1099FormDocHeader, Year, 'MISC');
        SetLifecycleReference(RejectedIRS1099FormDocHeader, Transmission."Document ID", '1', '2', "Transmission Status IRIS"::Rejected, false);
        SetLifecycleReference(OtherIRS1099FormDocHeader, Transmission."Document ID", '2', '3', "Transmission Status IRIS"::Rejected, false);
        if Partial then begin
            OtherIRS1099FormDocHeader."IRIS Submission Status" := OtherIRS1099FormDocHeader."IRIS Submission Status"::Accepted;
            OtherIRS1099FormDocHeader.Status := OtherIRS1099FormDocHeader.Status::Released;
            OtherIRS1099FormDocHeader.Modify();
        end;
        AcceptedModifiedAt := OtherIRS1099FormDocHeader.SystemModifiedAt;
        Transmission.Status := OverallStatus;
        Transmission."Receipt ID" := 'ACCEPTED';
        if OverallStatus = OverallStatus::Accepted then
            Transmission."Receipt ID" := 'LATER-ACCEPTED';
        Transmission."Original Receipt ID" := 'ACCEPTED';
        Transmission.Modify();
        InitializeOfflineTransport(Transmission);

        CreateFilingAttempt(Transmission, "Transmission Type IRIS"::O, 'ACCEPTED', TransmissionLog);
        AddFilingAttemptDocument(TransmissionLog, RejectedIRS1099FormDocHeader, 1);
        AddFilingAttemptDocument(TransmissionLog, OtherIRS1099FormDocHeader, 2);
        QueueOfflineSend();
        LibraryIRS1099IRIS.SendReplacement(Transmission);

        FindLastAttempt(Transmission, TransmissionLog);
        WriteTextBlob(Payload, ReadAttemptContent(TransmissionLog, 20));
        InitXMLReader(Payload);
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:TransmissionTypeCd', 'R');
        LibraryXPathXMLReader.VerifyXmlNodeAbsence('//n1:PrevSubmittedRecRecipientGrp');
        if Partial then begin
            LibraryXPathXMLReader.VerifyXmlNodeAbsence('//n1:IRTransmissionManifest/n1:OriginalReceiptId');
            LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:IRSubmission1Header/n1:OriginalUniqueSubmissionId', 'ACCEPTED|1');
            LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:TotalRecipientFormCnt', '1');
            LibraryXPathXMLReader.VerifyXmlNodeAbsence('//n1:Form1099MISCDetail');
            OtherIRS1099FormDocHeader.Get(OtherIRS1099FormDocHeader.ID);
            Assert.AreEqual(AcceptedModifiedAt, OtherIRS1099FormDocHeader.SystemModifiedAt, 'Accepted submission must not be written or resent.');
        end else begin
            LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:IRTransmissionManifest/n1:OriginalReceiptId', 'ACCEPTED');
            LibraryXPathXMLReader.VerifyXmlNodeAbsence('//n1:IRSubmission1Header/n1:OriginalUniqueSubmissionId');
            LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:TotalRecipientFormCnt', '2');
        end;
        VerifyLifecycleAmounts(RejectedIRS1099FormDocHeader, Payload, '5000', '100', '50');
        VerifyLifecycleSource(RejectedIRS1099FormDocHeader, Year);
        VerifyLifecycleSource(OtherIRS1099FormDocHeader, Year);
        FinishOfflineTransport();
    end;

    local procedure VerifyActualTwoStep(Year: Integer; FormNo: Code[20])
    var
        Transmission: Record "Transmission IRIS";
        OtherTransmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        UnselectedIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        NewIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        ZeroedIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        TransmissionLog: Record "Transmission Log IRIS";
        Payload: Codeunit "Temp Blob";
        TransmissionPage: TestPage "Transmission IRIS";
        ZeroPayload: Text;
        UnselectedModifiedAt: DateTime;
    begin
        CreateLifecycleTransmission(Transmission, IRS1099FormDocHeader, Year, FormNo);
        CreateLifecycleTransmission(OtherTransmission, UnselectedIRS1099FormDocHeader, Year, FormNo);
        SetLifecycleReference(IRS1099FormDocHeader, Transmission."Document ID", '1', '2', "Transmission Status IRIS"::Accepted, true);
        SetLifecycleReference(UnselectedIRS1099FormDocHeader, Transmission."Document ID", '1', '3', "Transmission Status IRIS"::Accepted, false);
        UnselectedIRS1099FormDocHeader.Status := UnselectedIRS1099FormDocHeader.Status::Released;
        UnselectedIRS1099FormDocHeader.Modify();
        UnselectedModifiedAt := UnselectedIRS1099FormDocHeader.SystemModifiedAt;
        Transmission.Status := Transmission.Status::Accepted;
        Transmission."Receipt ID" := 'ACCEPTED';
        Transmission."Original Receipt ID" := 'ACCEPTED';
        Transmission.Modify();
        InitializeOfflineTransport(Transmission);

        QueueOfflineSend();
        LibraryIRS1099IRIS.SendCorrection(Transmission, true);

        FindLastAttempt(Transmission, TransmissionLog);
        ZeroPayload := ReadAttemptContent(TransmissionLog, 20);
        WriteTextBlob(Payload, ZeroPayload);
        InitXMLReader(Payload);
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:TransmissionTypeCd', 'C');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:TotalRecipientFormCnt', '1');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:CorrectedInd', '1');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:PrevSubmittedRecRecipientGrp/n1:OtherIntakeSystemInd/following-sibling::*[1][self::n1:UniqueRecordId]', 'ACCEPTED|1|2');
        VerifyLifecycleAmounts(IRS1099FormDocHeader, Payload, '0', '0', '0');
        IRS1099FormDocHeader.Get(IRS1099FormDocHeader.ID);
        Assert.AreEqual(IRS1099FormDocHeader.Status::Abandoned, IRS1099FormDocHeader.Status, 'Only accepted zeroed documents are abandoned.');
        Assert.IsTrue(IRS1099FormDocHeader."IRIS Corrected to Zeros", 'The actual correction path records accepted zero state.');
        Assert.AreEqual('1', IRS1099FormDocHeader."IRIS Submission ID", 'Accepted submission reference is retained.');
        Assert.AreEqual('2', IRS1099FormDocHeader."IRIS Record ID", 'Accepted record reference is retained.');
        ZeroedIRS1099FormDocHeader := IRS1099FormDocHeader;
        UnselectedIRS1099FormDocHeader.Get(UnselectedIRS1099FormDocHeader.ID);
        Assert.AreEqual(UnselectedModifiedAt, UnselectedIRS1099FormDocHeader.SystemModifiedAt, 'Unselected document is not written by correction.');
        Assert.AreEqual(UnselectedIRS1099FormDocHeader.Status::Released, UnselectedIRS1099FormDocHeader.Status, 'Unselected released documents are not marked In Progress.');
        Assert.AreEqual('ACCEPTED', UnselectedIRS1099FormDocHeader."IRIS Last Accepted Receipt ID", 'Unselected accepted reference is untouched.');
        VerifyLifecycleSource(IRS1099FormDocHeader, Year);
        VerifyLifecycleSource(UnselectedIRS1099FormDocHeader, Year);

        // A newly prepared replacement document is independent of the abandoned source.
        CreateLifecycleTransmission(OtherTransmission, NewIRS1099FormDocHeader, Year, FormNo);
        NewIRS1099FormDocHeader."IRIS Transmission Document ID" := Transmission."Document ID";
        NewIRS1099FormDocHeader.Modify();
        UnselectedIRS1099FormDocHeader.Status := UnselectedIRS1099FormDocHeader.Status::Open;
        UnselectedIRS1099FormDocHeader.Modify();
        OfflineReceiptID := 'SIMULATED-STEP2';
        TransmissionPage.OpenEdit();
        TransmissionPage.GoToRecord(Transmission);
        QueueOfflineSend();
        TransmissionPage.Step2SendCorrectedOriginal.Invoke();
        TransmissionPage.Close();

        Transmission.Get(Transmission."Document ID");
        Assert.AreEqual("Transmission Type IRIS"::O, Transmission."Last Type", 'The page chooses a new original, not another correction.');
        Assert.AreEqual(Transmission.Status::Accepted, Transmission.Status, 'Simulated final acknowledgment is processed, not inferred from HTTP.');
        FindLastAttempt(Transmission, TransmissionLog);
        WriteTextBlob(Payload, ReadAttemptContent(TransmissionLog, 20));
        InitXMLReader(Payload);
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:TransmissionTypeCd', 'O');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:CorrectedInd', '0');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:TotalRecipientFormCnt', '1');
        LibraryXPathXMLReader.VerifyXmlNodeAbsence('//n1:PrevSubmittedRecRecipientGrp');
        VerifyLifecycleAmounts(NewIRS1099FormDocHeader, Payload, '5000', '100', '50');
        IRS1099FormDocHeader.Get(IRS1099FormDocHeader.ID);
        Assert.AreEqual(ZeroedIRS1099FormDocHeader."IRIS Last Accepted Receipt ID", IRS1099FormDocHeader."IRIS Last Accepted Receipt ID", 'Step two does not overwrite the old accepted-zero reference.');
        Assert.AreEqual(ZeroedIRS1099FormDocHeader.SystemModifiedAt, IRS1099FormDocHeader.SystemModifiedAt, 'Step two never rewrites abandoned source headers.');
        Assert.AreEqual('1', IRS1099FormDocHeader."IRIS Submission ID", 'Source submission identity survives the new original.');
        Assert.AreEqual('2', IRS1099FormDocHeader."IRIS Record ID", 'Source record identity survives the new original.');
        VerifyLifecycleSource(IRS1099FormDocHeader, Year);
        VerifyLifecycleSource(NewIRS1099FormDocHeader, Year);
        Assert.AreEqual(8, OfflineRequestPaths.Count(), 'Two sends each use a validity probe, submission, validity probe and acknowledgment.');
        FinishOfflineTransport();
    end;

    local procedure VerifyAttemptContext(var TransmissionLog: Record "Transmission Log IRIS"; TestCode: Text; BCEnvironment: Text)
    begin
        TransmissionLog.Get(TransmissionLog."Line ID");
        Assert.AreEqual('5.0.7', TransmissionLog."XML Schema Version", 'History captures the actual XML schema.');
        Assert.AreEqual('ReportingPeriod', TransmissionLog."Schema Source", 'Generator source propagates through the facade var record to the actual attempt.');
        Assert.AreEqual(TestCode, TransmissionLog."XML Test Code", 'History captures actual TestCd.');
        Assert.AreEqual('26TEST0001', TransmissionLog."Software ID", 'History captures the document-year identity.');
        Assert.AreEqual(BCEnvironment, TransmissionLog."BC Environment", 'History records actual BC environment, not a harness or routing selector.');
    end;

    local procedure VerifyAttemptEnvironment(Attempt: Record "Transmission Log IRIS"; var Payload: Codeunit "Temp Blob"; TestCode: Text; TCC: Text; BCEnvironment: Text)
    begin
        InitXMLReader(Payload);
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:TestCd', TestCode);
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:TransmitterControlCd', TCC);
        Assert.IsTrue(Attempt."Unique Transmission ID".Contains(':IRIS:' + TCC + '::A'), 'UTID and transmitter must use the same pinned TCC.');
        Assert.AreEqual(BCEnvironment, Attempt."BC Environment", 'History captures the new attempt environment, never routing authority.');
    end;

    local procedure VerifyCancelledXmlCreationLeavesNoChanges(var IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; var TempIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header" temporary; var TempBlob: Codeunit "Temp Blob")
    var
        TransmissionLog: Record "Transmission Log IRIS";
        OriginalIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
    begin
        OriginalIRS1099FormDocHeader := IRS1099FormDocHeader;
        IRS1099FormDocHeader.Get(IRS1099FormDocHeader.ID);
        Assert.AreEqual(IRS1099FormDocHeader.Status::Released, IRS1099FormDocHeader.Status, 'Cancellation must preserve released status.');
        Assert.AreEqual(OriginalIRS1099FormDocHeader."IRIS Submission ID", IRS1099FormDocHeader."IRIS Submission ID", 'No new submission ID may be saved.');
        Assert.AreEqual(OriginalIRS1099FormDocHeader."IRIS Record ID", IRS1099FormDocHeader."IRIS Record ID", 'No new record ID may be saved.');
        Assert.AreEqual(OriginalIRS1099FormDocHeader.SystemModifiedAt, IRS1099FormDocHeader.SystemModifiedAt, 'The saved document must not be modified.');
        Assert.IsTrue(TempIRS1099FormDocHeader.IsEmpty(), 'No document generation may start.');
        Assert.IsFalse(TempBlob.HasValue(), 'No payload may be generated.');
        Assert.IsTrue(TransmissionLog.IsEmpty(), 'No attempt history may be written.');
    end;

    local procedure VerifyCapturedDownload(ExpectedBytes: Text; Prefix: Text; UTID: Text)
    var
        Payload: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        Content: InStream;
    begin
        LibraryFileMgtHandler.GetTempBlob(Payload);
        Payload.CreateInStream(Content);
        Assert.AreEqual(ExpectedBytes, Base64Convert.ToBase64(Content), 'The actual download request stream must equal the selected stored BLOB byte-for-byte.');
        Assert.AreEqual(Prefix + UTID + '.xml', LibraryFileMgtHandler.GetDownloadFromSreamToFileName(), 'Download is named for the selected attempt.');
    end;

    local procedure VerifyContractManifest(var TempBlob: Codeunit "Temp Blob"; TaxYear: Text; SoftwareId: Text; PriorYear: Text)
    begin
        InitXMLReader(TempBlob);
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:IRTransmissionManifest/n1:SchemaVersionNum', '5.0.7');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:IRTransmissionManifest/n1:TaxYr', TaxYear);
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:IRTransmissionManifest/n1:SoftwareId', SoftwareId);
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:IRTransmissionManifest/n1:PriorYearDataInd', PriorYear);
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:IRTransmissionManifest/n1:TestCd', 'T');
    end;

    local procedure VerifyDocLineAmount(IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; BoxNo: Code[20]; Amount: Decimal)
    var
        IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
    begin
        IRS1099FormDocLine.Get(IRS1099FormDocHeader."Period No.", IRS1099FormDocHeader."Vendor No.", IRS1099FormDocHeader."Form No.", IRS1099FormDocHeader.ID, 10000);
        Assert.AreEqual(BoxNo, IRS1099FormDocLine."Form Box No.", 'The financial parent is unchanged.');
        Assert.AreEqual(Amount, IRS1099FormDocLine.Amount, 'Zero correction does not change saved financial income.');
    end;

    local procedure VerifyInvalidTaxYear(TaxYear: Text)
    begin
        asserterror LibraryIRS1099IRIS.ValidateTaxYear(TaxYear);
        Assert.ExpectedError('must contain four digits and be between 2000 and 3000');
        Assert.ExpectedErrorCode('Dialog');
    end;

    local procedure VerifyLifecycleAmounts(IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; var Payload: Codeunit "Temp Blob"; Parent: Text; Tips: Text; Overtime: Text)
    begin
        if IRS1099FormDocHeader."Period No." = '2026' then
            VerifySupplementalXml(Payload, IRS1099FormDocHeader."Form No.", Parent, Tips, Overtime)
        else begin
            InitXMLReader(Payload);
            if IRS1099FormDocHeader."Form No." = 'NEC' then
                LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:Form1099NECDetail/n1:NonemployeeCompensationAmt', Parent)
            else
                LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:Form1099MISCDetail/n1:OtherIncomeAmt', Parent);
            VerifyNoSupplementalXml(Payload);
        end;
        if Parent = '0' then
            LibraryXPathXMLReader.VerifyXmlNodeAbsence('//n1:TreasuryTippedOccupationCd');
    end;

    local procedure VerifyLifecycleSource(IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; Year: Integer)
    begin
        if IRS1099FormDocHeader."Form No." = 'NEC' then
            VerifyDocLineAmount(IRS1099FormDocHeader, 'NEC-01', 5000)
        else
            VerifyDocLineAmount(IRS1099FormDocHeader, 'MISC-03', 5000);
        if Year = 2026 then
            VerifySavedSupplementalValues(IRS1099FormDocHeader, 100, 50, '101', '000');
    end;

    local procedure VerifyLifecycleStatus(var Transmission: Record "Transmission IRIS"; var IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; Status: Enum "Transmission Status IRIS"; DocumentStatus: Enum "IRS 1099 Form Doc. Status")
    begin
        Transmission.Get(Transmission."Document ID");
        IRS1099FormDocHeader.Get(IRS1099FormDocHeader.ID);
        Assert.AreEqual(Status, Transmission.Status, 'Actual acknowledgment determines the transmission state.');
        Assert.AreEqual(Status, IRS1099FormDocHeader."IRIS Submission Status", 'Submission state remains distinct.');
        Assert.AreEqual(DocumentStatus, IRS1099FormDocHeader.Status, 'Only final accepted submissions become Submitted.');
    end;

    local procedure VerifyMappingConfirmation(TaxYear: Text; MappingYear: Text; SchemaVersion: Text)
    var
        Question: Text;
    begin
        Question := LibraryVariableStorage.DequeueText();
        Assert.IsTrue(Question.Contains('Tax year ' + TaxYear + ' has not been verified'), 'The requested year must be explicit.');
        Assert.IsTrue(Question.Contains('form box mappings for tax year ' + MappingYear), 'The actual resource year must be explicit.');
        Assert.IsTrue(Question.Contains('IRIS XML schema ' + SchemaVersion), 'The exact wire version must be explicit.');
        Assert.IsTrue(Question.Contains('IRS acceptance does not guarantee that the reported information is correct'), 'Acceptance must not be presented as a correctness guarantee.');
    end;

    local procedure VerifyNoSupplementalXml(var TempBlob: Codeunit "Temp Blob")
    begin
        InitXMLReader(TempBlob);
        LibraryXPathXMLReader.VerifyXmlNodeAbsence('//n1:CashTipsAmt');
        LibraryXPathXMLReader.VerifyXmlNodeAbsence('//n1:OvertimeCompensationAmt');
        LibraryXPathXMLReader.VerifyXmlNodeAbsence('//n1:TreasuryTippedOccupationCd');
    end;

    local procedure VerifyOpenDocumentConfirmation()
    begin
        Assert.IsTrue(LibraryVariableStorage.DequeueText().Contains('open or abandoned'), 'The existing document-selection warning must run before preflight.');
    end;

    local procedure VerifyManualReceiptRecovery(var Transmission: Record "Transmission IRIS"; var DocHeader: Record "IRS 1099 Form Doc. Header")
    begin
        Transmission.Get(Transmission."Document ID");
        DocHeader.Get(DocHeader.ID);
        Assert.AreEqual(Transmission.Status::Accepted, Transmission.Status, 'The manually recovered transmission can be reconciled.');
        Assert.AreEqual(DocHeader.Status::Released, DocHeader.Status, 'Unproven document membership must not be inferred.');
        Assert.AreEqual('', DocHeader."IRIS Last Accepted Receipt ID", 'Recovery must not invent an accepted document reference.');
        Assert.IsFalse(DocHeader."IRIS Corrected", 'Incomplete history must not complete a correction.');
        Assert.AreEqual(1, OfflineRequestPaths.Count() - OfflineTokenProbeCount, 'Recovery must not submit or probe an unrelated attempt.');
        asserterror LibraryIRS1099IRIS.SendCorrection(Transmission, false);
        Assert.ExpectedError('no matching local submission history');
        Assert.ExpectedErrorCode('Dialog');
        Assert.AreEqual(1, OfflineRequestPaths.Count() - OfflineTokenProbeCount, 'Incomplete recovered history must block another filing.');
    end;

    local procedure VerifyPagesOpenWithoutSubmitEndpoint()
    var
        TransmissionPage: TestPage "Transmission IRIS";
        SetupPage: TestPage "IRS Forms Setup";
    begin
        TransmissionPage.OpenEdit();
        TransmissionPage.TestModeIndicator.AssertEquals('Production');
        TransmissionPage.Close();

        SetupPage.OpenEdit();
        SetupPage.IRISDestination.AssertEquals('Production');
        SetupPage.SubmissionEndpointURL.AssertEquals('');
        SetupPage.Close();

        asserterror LibraryIRS1099IRIS.GetSubmitEndpoint();
        Assert.ExpectedError('Submit Endpoint URL');
        Assert.ExpectedErrorCode('Dialog');
    end;

    local procedure VerifyProductionSendConfirmations()
    var
        Question: Text;
        ConfirmationNo: Integer;
    begin
        for ConfirmationNo := 1 to 6 do begin
            Question := LibraryVariableStorage.DequeueText();
            Assert.IsTrue(Question.Contains('tax year 2025'), 'The send confirmation must identify the reporting year.');
            Assert.IsTrue(Question.Contains('IRS Production'), 'The send confirmation must identify the Production destination.');
            Assert.IsTrue(Question.Contains('live submission'), 'The Production confirmation must explain that this is live.');
        end;
    end;

    local procedure VerifyRequestPaths(FirstIndex: Integer; LastIndex: Integer; ExpectedPath: Text)
    var
        Index: Integer;
    begin
        for Index := FirstIndex to LastIndex do
            Assert.AreEqual(ExpectedPath, OfflineRequestPaths.Get(Index), 'Every request, including token-validity probes, follows the current environment.');
    end;

    local procedure VerifyRequiredSchemaFailure()
    begin
        Assert.ExpectedError('Could not get IRIS XML Schema Version from Azure Key Vault.');
        Assert.ExpectedError('Try the operation again later.');
        Assert.ExpectedError('If the issue persists, open a Business Central support request.');
        Assert.ExpectedErrorCode('Dialog');
    end;

    local procedure VerifySavedSupplementalValues(IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; Tips: Decimal; Overtime: Decimal; OccupationCode1: Text[3]; OccupationCode2: Text[3])
    var
        SupplementalLine: Record "IRS 1099 Doc. Suppl. Line";
        ParentFormBoxNo: Code[20];
    begin
        if IRS1099FormDocHeader."Form No." = 'MISC' then begin
            ParentFormBoxNo := 'MISC-03';
            SupplementalLine.Get(IRS1099FormDocHeader.ID, 'MISC-13A');
        end else begin
            ParentFormBoxNo := 'NEC-01';
            SupplementalLine.Get(IRS1099FormDocHeader.ID, 'NEC-01B');
        end;
        Assert.AreEqual(Tips, SupplementalLine.Amount, 'Saved tips are not rewritten.');
        Assert.AreEqual(ParentFormBoxNo, SupplementalLine."Parent Form Box No.", 'The saved parent remains unchanged.');
        if IRS1099FormDocHeader."Form No." = 'MISC' then
            SupplementalLine.Get(IRS1099FormDocHeader.ID, 'MISC-13B')
        else
            SupplementalLine.Get(IRS1099FormDocHeader.ID, 'NEC-01C');
        Assert.AreEqual(OccupationCode1, SupplementalLine."Occupation Code 1", 'First saved text code remains unchanged.');
        Assert.AreEqual(OccupationCode2, SupplementalLine."Occupation Code 2", 'Second saved text code remains unchanged.');
        if IRS1099FormDocHeader."Form No." = 'MISC' then
            SupplementalLine.Get(IRS1099FormDocHeader.ID, 'MISC-14')
        else
            SupplementalLine.Get(IRS1099FormDocHeader.ID, 'NEC-01D');
        Assert.AreEqual(Overtime, SupplementalLine.Amount, 'Saved overtime is not rewritten.');
    end;

    local procedure VerifySchemaAttempt(var Payload: Codeunit "Temp Blob"; VersionText: Text; PriorYear: Text; Amount: Text; CorrectedIndicator: Text)
    begin
        InitXMLReader(Payload);
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:SchemaVersionNum', VersionText);
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:PriorYearDataInd', PriorYear);
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:TotalIssuerFormCnt', '1');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:TotalRecipientFormCnt', '1');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:Form1099NECDetail/n1:NonemployeeCompensationAmt', Amount);
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:CorrectedInd', CorrectedIndicator);
    end;

    local procedure VerifySendConfirmationDestination(IsTestDestination: Boolean)
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        TransmissionLog: Record "Transmission Log IRIS";
        TransmissionPage: TestPage "Transmission IRIS";
    begin
        CreateContractTransmission(Transmission, IRS1099FormDocHeader, 2025);
        InitializeOfflineConfiguration();
        EnvironmentInfoTestLibrary.SetTestabilitySandbox(IsTestDestination);
        TransmissionPage.OpenEdit();
        TransmissionPage.GoToRecord(Transmission);
        TransmissionPage.SendOriginal.Invoke();

        Transmission.Status := Transmission.Status::Rejected;
        Transmission.Modify();
        TransmissionPage.GoToRecord(Transmission);
        TransmissionPage.SendReplacement.Invoke();

        Transmission.Status := Transmission.Status::Accepted;
        Transmission.Modify();
        TransmissionPage.GoToRecord(Transmission);
        TransmissionPage.SendCorrection.Invoke();
        TransmissionPage.SendCorrectionToZero.Invoke();
        TransmissionPage.Step1CorrectionToZero.Invoke();
        TransmissionPage.Step2SendCorrectedOriginal.Invoke();
        TransmissionPage.Close();

        TransmissionLog.SetRange("Transmission Document ID", Transmission."Document ID");
        Assert.RecordIsEmpty(TransmissionLog);
        IRS1099FormDocHeader.Get(IRS1099FormDocHeader.ID);
        Assert.AreEqual(IRS1099FormDocHeader.Status::Released, IRS1099FormDocHeader.Status, 'Status must match the expected value.');
        Assert.AreEqual(false, IRS1099FormDocHeader."IRIS Needs Correction", 'IRIS Needs Correction must match the expected value.');
        ResetStandardProvider();
    end;

    local procedure VerifyStandardEnvironment(var TempBlob: Codeunit "Temp Blob"; TestCode: Text; SubmitEndpoint: Text; StatusEndpoint: Text; AuthEndpoint: Text)
    begin
        InitXMLReader(TempBlob);
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:IRTransmissionManifest/n1:SchemaVersionNum', '5.0.7');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:IRTransmissionManifest/n1:TestCd', TestCode);
        Assert.AreEqual(SubmitEndpoint, LibraryIRS1099IRIS.GetSubmitEndpoint(), 'Submit endpoint must follow current BC environment.');
        Assert.AreEqual(StatusEndpoint, LibraryIRS1099IRIS.GetStatusEndpoint(), 'Status endpoint must follow current BC environment.');
        Assert.AreEqual(AuthEndpoint, LibraryIRS1099IRIS.GetAuthEndpoint(), 'Auth endpoint must follow current BC environment.');
    end;

    local procedure VerifyStatusAction(var TransmissionPage: TestPage "Transmission IRIS"; var Transmission: Record "Transmission IRIS"; var IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; StatusText: Text; Status: Enum "Transmission Status IRIS"; DocumentStatus: Enum "IRS 1099 Form Doc. Status")
    begin
        OfflineStatus := StatusText;
        OfflineSubmissionStatuses.Set(IRS1099FormDocHeader."IRIS Submission ID", StatusText);
        QueueOfflineAcknowledgment();
        TransmissionPage.RequestTransmissionStatusByRID.Invoke();
        VerifyLifecycleStatus(Transmission, IRS1099FormDocHeader, Status, DocumentStatus);
    end;

    local procedure VerifySupplementalOrder(FormNo: Text)
    var
        DetailPath: Text;
        TotalPath: Text;
    begin
        DetailPath := StrSubstNo(XmlDetailPathTok, FormNo);
        TotalPath := StrSubstNo(XmlTotalPathTok, FormNo);
        LibraryXPathXMLReader.VerifyXmlNodeValue(DetailPath + 'n1:CashTipsAmt/following-sibling::*[1][self::n1:TreasuryTippedOccupationCd]', '101');
        LibraryXPathXMLReader.VerifyXmlNodeValue(DetailPath + 'n1:TreasuryTippedOccupationCd[1]/following-sibling::*[1][self::n1:TreasuryTippedOccupationCd]', '000');
        LibraryXPathXMLReader.VerifyXmlNodeValue(DetailPath + 'n1:TreasuryTippedOccupationCd[2]/following-sibling::*[1][self::n1:OvertimeCompensationAmt]', '50');
        if FormNo = 'NEC' then begin
            LibraryXPathXMLReader.VerifyXmlNodeValue(DetailPath + 'n1:NonemployeeCompensationAmt/following-sibling::*[1][self::n1:CashTipsAmt]', '100');
            LibraryXPathXMLReader.VerifyXmlNodeValue(DetailPath + 'n1:OvertimeCompensationAmt/following-sibling::*[1][self::n1:DirectSaleAboveThresholdInd]', '0');
            LibraryXPathXMLReader.VerifyXmlNodeValue(TotalPath + 'n1:NonemployeeCompensationAmt/following-sibling::*[1][self::n1:CashTipsAmt]', '100');
            LibraryXPathXMLReader.VerifyXmlNodeValue(TotalPath + 'n1:CashTipsAmt/following-sibling::*[1][self::n1:OvertimeCompensationAmt]', '50');
        end else begin
            LibraryXPathXMLReader.VerifyXmlNodeValue(DetailPath + 'n1:Section409ADeferralsAmt/following-sibling::*[1][self::n1:CashTipsAmt]', '100');
            LibraryXPathXMLReader.VerifyXmlNodeValue(DetailPath + 'n1:OvertimeCompensationAmt/following-sibling::*[1][self::n1:NonqlfyDeferredCompensationAmt]', '0');
            LibraryXPathXMLReader.VerifyXmlNodeValue(TotalPath + 'n1:FederalIncomeTaxWithheldAmt/following-sibling::*[1][self::n1:CashTipsAmt]', '100');
            LibraryXPathXMLReader.VerifyXmlNodeValue(TotalPath + 'n1:CashTipsAmt/following-sibling::*[1][self::n1:RentAmt]', '0');
            LibraryXPathXMLReader.VerifyXmlNodeValue(TotalPath + 'n1:Section409ADeferralsAmt/following-sibling::*[1][self::n1:OvertimeCompensationAmt]', '50');
        end;
    end;

    local procedure VerifySupplementalXml(var TempBlob: Codeunit "Temp Blob"; FormNo: Text; ParentAmount: Text; Tips: Text; Overtime: Text)
    var
        ParentElement: Text;
        DetailPath: Text;
        TotalPath: Text;
    begin
        InitXMLReader(TempBlob);
        ParentElement := 'NonemployeeCompensationAmt';
        if FormNo = 'MISC' then
            ParentElement := 'OtherIncomeAmt';
        DetailPath := StrSubstNo(XmlDetailPathTok, FormNo);
        TotalPath := StrSubstNo(XmlTotalPathTok, FormNo);
        LibraryXPathXMLReader.VerifyXmlNodeValue(DetailPath + 'n1:' + ParentElement, ParentAmount);
        LibraryXPathXMLReader.VerifyXmlNodeValue(TotalPath + 'n1:' + ParentElement, ParentAmount);
        LibraryXPathXMLReader.VerifyXmlNodeValue(DetailPath + 'n1:CashTipsAmt', Tips);
        LibraryXPathXMLReader.VerifyXmlNodeValue(TotalPath + 'n1:CashTipsAmt', Tips);
        LibraryXPathXMLReader.VerifyXmlNodeValue(DetailPath + 'n1:OvertimeCompensationAmt', Overtime);
        LibraryXPathXMLReader.VerifyXmlNodeValue(TotalPath + 'n1:OvertimeCompensationAmt', Overtime);
        LibraryXPathXMLReader.VerifyXmlNodeAbsence(TotalPath + 'n1:TreasuryTippedOccupationCd');
    end;

    local procedure VerifyTestDestinationMessage()
    var
        MessageText: Text;
    begin
        MessageText := LibraryVariableStorage.DequeueText();
        Assert.IsTrue(MessageText.Contains('IRIS Assurance Testing System (ATS)'), 'The explanation must say where test data is transmitted.');
        Assert.IsTrue(MessageText.Contains('not as a production filing'), 'The explanation must distinguish testing from production filing.');
    end;

    local procedure VerifyTestSendConfirmations()
    var
        Question: Text;
        ConfirmationNo: Integer;
    begin
        for ConfirmationNo := 1 to 6 do begin
            Question := LibraryVariableStorage.DequeueText();
            Assert.IsTrue(Question.Contains('tax year 2025'), 'The send confirmation must identify the reporting year.');
            Assert.IsTrue(Question.Contains('IRS Test'), 'The send confirmation must identify the Test destination.');
            Assert.IsTrue(Question.Contains('IRIS Assurance Testing System (ATS)'), 'The Test confirmation must identify ATS.');
            Assert.IsTrue(Question.Contains('not as a production filing'), 'The Test confirmation must explain that this is not production filing.');
        end;
    end;

    local procedure VerifyUnacceptedZeroCorrection(HttpStatus: Integer; StatusText: Text)
    var
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        TransmissionLog: Record "Transmission Log IRIS";
    begin
        CreateLifecycleTransmission(Transmission, IRS1099FormDocHeader, 2026, 'NEC');
        SetLifecycleReference(IRS1099FormDocHeader, Transmission."Document ID", '1', '2', "Transmission Status IRIS"::Accepted, true);
        Transmission.Status := Transmission.Status::Accepted;
        Transmission."Receipt ID" := 'ACCEPTED';
        Transmission.Modify();
        InitializeOfflineTransport(Transmission);
        OfflineSubmitHttpStatus := HttpStatus;
        OfflineStatus := StatusText;
        OfflineSubmissionStatuses.Add('1', StatusText);

        LibraryIRS1099IRIS.SendCorrection(Transmission, true);

        IRS1099FormDocHeader.Get(IRS1099FormDocHeader.ID);
        Assert.AreEqual(IRS1099FormDocHeader.Status::Submitted, IRS1099FormDocHeader.Status, 'Without a new accepted acknowledgment the source cannot be abandoned.');
        Assert.IsTrue(IRS1099FormDocHeader."IRIS Needs Correction", 'Unaccepted correction remains selected for follow-up.');
        Assert.IsFalse(IRS1099FormDocHeader."IRIS Corrected to Zeros", 'The previous accepted state is not current correction acceptance.');
        VerifyLifecycleSource(IRS1099FormDocHeader, 2026);
        FindLastAttempt(Transmission, TransmissionLog);
        Assert.AreEqual(HttpStatus, TransmissionLog."Response Http Status Code", 'History keeps the actual HTTP result.');
        if HttpStatus = 200 then begin
            OfflineStatus := 'Accepted';
            OfflineSubmissionStatuses.Set('1', 'Accepted');
            QueueOfflineAcknowledgment();
            LibraryIRS1099IRIS.RequestAcknowledgementAndUpdateTransmission(Transmission, Transmission."Receipt ID", TransmissionLog."Unique Transmission ID");
            IRS1099FormDocHeader.Get(IRS1099FormDocHeader.ID);
            Assert.AreEqual(IRS1099FormDocHeader.Status::Abandoned, IRS1099FormDocHeader.Status, 'A later terminal accepted acknowledgment completes the pending zero correction.');
            Assert.IsTrue(IRS1099FormDocHeader."IRIS Corrected to Zeros", 'The attempt history retains its zero mode for later acceptance.');
            Assert.IsFalse(IRS1099FormDocHeader."IRIS Needs Correction", 'Accepted correction is no longer pending.');
            VerifyLifecycleSource(IRS1099FormDocHeader, 2026);
        end;
        FinishOfflineTransport();
    end;

    local procedure VerifyPendingIntake(var Transmission: Record "Transmission IRIS"; var DocHeader: Record "IRS 1099 Form Doc. Header"; TransmissionType: Enum "Transmission Type IRIS")
    begin
        Transmission.Get(Transmission."Document ID");
        DocHeader.Get(DocHeader.ID);
        Assert.AreEqual(OfflineReceiptID, Transmission."Receipt ID", 'The successful intake receipt must persist before acknowledgment.');
        Assert.AreEqual(TransmissionType, Transmission."Last Type", 'The pending intake type must be recorded.');
        Assert.AreEqual(Transmission.Status::Processing, Transmission.Status, 'Unacknowledged intake must block another send.');
        Assert.AreEqual(OfflineReceiptID, DocHeader."IRIS Last Receipt ID", 'The sent document must retain its intake receipt.');
    end;

    local procedure VerifyPendingCorrectionEdits(Transmission: Record "Transmission IRIS"; var IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; ExpectedStatus: Enum "IRS 1099 Form Doc. Status")
    var
        TransmissionLog: Record "Transmission Log IRIS";
    begin
        IRS1099FormDocHeader.Get(IRS1099FormDocHeader.ID);
        Assert.AreEqual(ExpectedStatus, IRS1099FormDocHeader.Status, 'Acknowledgment must preserve the newer edit state.');
        Assert.IsTrue(IRS1099FormDocHeader."IRIS Needs Correction", 'Newer values must remain selected for correction.');
        Assert.IsFalse(IRS1099FormDocHeader."IRIS Corrected to Zeros", 'Acceptance of older values must not abandon the edited document.');
        VerifySavedSupplementalValues(IRS1099FormDocHeader, 200, 50, '101', '000');
        FindLastAttempt(Transmission, TransmissionLog);
        Assert.AreEqual(TransmissionLog."Transmission Status"::Accepted, TransmissionLog."Transmission Status", 'The sent attempt must still record its acceptance.');
    end;

    local procedure VerifyRecoveredNonzeroCorrection(Transmission: Record "Transmission IRIS"; var IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header")
    var
        TransmissionLog: Record "Transmission Log IRIS";
    begin
        Transmission.Get(Transmission."Document ID");
        IRS1099FormDocHeader.Get(IRS1099FormDocHeader.ID);
        Assert.AreEqual(OfflineReceiptID, Transmission."Receipt ID", 'The recovered receipt must identify the current attempt.');
        Assert.AreEqual(OfflineReceiptID, IRS1099FormDocHeader."IRIS Last Receipt ID", 'The sent document must retain the recovered receipt.');
        Assert.AreEqual(IRS1099FormDocHeader.Status::Submitted, IRS1099FormDocHeader.Status, 'A nonzero correction must not abandon its document.');
        Assert.IsTrue(IRS1099FormDocHeader."IRIS Corrected", 'The acknowledged nonzero correction must complete.');
        Assert.IsFalse(IRS1099FormDocHeader."IRIS Needs Correction", 'The accepted retry must no longer be pending.');
        Assert.IsFalse(IRS1099FormDocHeader."IRIS Corrected to Zeros", 'The rejected attempt must not supply the correction mode.');
        FindLastAttempt(Transmission, TransmissionLog);
        Assert.AreEqual(OfflineReceiptID, TransmissionLog."Receipt ID", 'History must persist the recovered receipt on its attempt.');
        VerifySavedSupplementalValues(IRS1099FormDocHeader, 100, 50, '101', '000');
    end;

    local procedure VerifyPendingTransmissionUpdate(var IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header")
    begin
        IRS1099FormDocHeader.Get(IRS1099FormDocHeader.ID);
        Assert.AreEqual(IRS1099FormDocHeader.Status::Submitted, IRS1099FormDocHeader.Status, 'A delayed acknowledgment must not abandon the updated document.');
        Assert.IsTrue(IRS1099FormDocHeader."IRIS Updated Not Sent", 'Direct recalculation must retain its unsent marker.');
        Assert.IsTrue(IRS1099FormDocHeader."IRIS Needs Correction", 'Direct recalculation must remain selected for correction.');
        Assert.IsFalse(IRS1099FormDocHeader."IRIS Corrected", 'The older acknowledgment cannot complete the new values.');
        Assert.IsFalse(IRS1099FormDocHeader."IRIS Corrected to Zeros", 'The updated source cannot be treated as corrected to zero.');
        VerifyDocLineAmount(IRS1099FormDocHeader, 'NEC-01', 6000);
        VerifySavedSupplementalValues(IRS1099FormDocHeader, 100, 50, '101', '000');
    end;

    local procedure VerifyAcceptedZeroCorrection(var DocHeader: Record "IRS 1099 Form Doc. Header")
    begin
        DocHeader.Get(DocHeader.ID);
        Assert.AreEqual(DocHeader.Status::Abandoned, DocHeader.Status, 'Accepted zero corrections remain abandoned.');
        Assert.IsTrue(DocHeader."IRIS Corrected to Zeros", 'The accepted zero-correction result must be retained.');
        Assert.IsFalse(DocHeader."IRIS Needs Correction", 'An accepted zero correction is no longer pending.');
    end;

    local procedure VerifyAcceptedUpdatedSource(var SourceDocHeader: Record "IRS 1099 Form Doc. Header"; var DocHeader: Record "IRS 1099 Form Doc. Header"; var Payload: Codeunit "Temp Blob"; AcceptedRecordReference: Text)
    begin
        InitXMLReader(Payload);
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:TransmissionTypeCd', 'C');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:UniqueRecordId', AcceptedRecordReference);
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:Form1099NECDetail/n1:ExcessParachutePaymentAmt', '7000');
        DocHeader.Get(DocHeader.ID);
        Assert.AreEqual(DocHeader.Status::Submitted, DocHeader.Status, 'The updated return must be submitted as a correction.');
        Assert.IsTrue(DocHeader."IRIS Corrected", 'The accepted correction must be completed.');
        Assert.IsFalse(DocHeader."IRIS Needs Correction", 'Accepted values no longer need correction.');
        Assert.IsFalse(DocHeader."IRIS Updated Not Sent", 'The updated values have been sent.');
        Assert.IsFalse(DocHeader."IRIS Corrected to Zeros", 'The updated return must not be zeroed.');
        SourceDocHeader.Get(SourceDocHeader.ID);
        Assert.AreEqual(SourceDocHeader.Status::Abandoned, SourceDocHeader.Status, 'The old local version remains abandoned.');
    end;

    local procedure VerifyPendingZeroCorrection(var DocHeader: Record "IRS 1099 Form Doc. Header")
    begin
        DocHeader.Get(DocHeader.ID);
        Assert.AreEqual(DocHeader.Status::Submitted, DocHeader.Status, 'Processing is not acceptance of the zero correction.');
        Assert.IsTrue(DocHeader."IRIS Needs Correction", 'Step 1 must retain the pending correction.');
        Assert.IsFalse(DocHeader."IRIS Corrected to Zeros", 'Processing cannot complete a zero correction.');
    end;

    local procedure VerifyUnsentReplacement(var ReplacementDocHeader: Record "IRS 1099 Form Doc. Header"; ExpectedModifiedAt: DateTime)
    begin
        ReplacementDocHeader.Get(ReplacementDocHeader.ID);
        Assert.AreEqual(ReplacementDocHeader.Status::Released, ReplacementDocHeader.Status, 'The replacement has not been submitted.');
        Assert.AreEqual(ReplacementDocHeader."IRIS Submission Status"::Accepted, ReplacementDocHeader."IRIS Submission Status", 'The replacement retains the accepted source filing status.');
        Assert.IsTrue(ReplacementDocHeader."IRIS Updated Not Sent", 'The replacement must retain its unsent values.');
        Assert.AreEqual(ExpectedModifiedAt, ReplacementDocHeader.SystemModifiedAt, 'An attempt must not write a document outside its logged membership.');
    end;

    local procedure VerifyBlockedCorrection(DocHeader: Record "IRS 1099 Form Doc. Header"; Transmission: Record "Transmission IRIS"; ExpectedRequestCount: Integer; ExpectedAttemptCount: Integer)
    var
        StoredDocHeader: Record "IRS 1099 Form Doc. Header";
        StoredTransmission: Record "Transmission IRIS";
        TransmissionLog: Record "Transmission Log IRIS";
    begin
        Assert.AreEqual(ExpectedRequestCount, OfflineRequestPaths.Count(), 'Correction validation must finish before any new HTTP request.');
        TransmissionLog.SetRange("Transmission Document ID", Transmission."Document ID");
        Assert.RecordCount(TransmissionLog, ExpectedAttemptCount);
        StoredDocHeader.Get(DocHeader.ID);
        Assert.AreEqual(DocHeader.Status, StoredDocHeader.Status, 'Rejecting a correction must preserve the document status.');
        Assert.AreEqual(DocHeader."IRIS Needs Correction", StoredDocHeader."IRIS Needs Correction", 'Rejecting a correction must preserve the selection.');
        Assert.AreEqual(DocHeader."IRIS Submission ID", StoredDocHeader."IRIS Submission ID", 'Correction validation must precede submission identifier changes.');
        Assert.AreEqual(DocHeader."IRIS Record ID", StoredDocHeader."IRIS Record ID", 'Correction validation must precede record identifier changes.');
        Assert.AreEqual(DocHeader.SystemModifiedAt, StoredDocHeader.SystemModifiedAt, 'Rejecting a correction must not rewrite the document.');
        StoredTransmission.Get(Transmission."Document ID");
        Assert.AreEqual(Transmission.Status, StoredTransmission.Status, 'Rejecting a correction must preserve transmission status.');
        Assert.AreEqual(Transmission."Receipt ID", StoredTransmission."Receipt ID", 'Rejecting a correction must preserve the previous receipt.');
    end;

    local procedure VerifySandboxActionVisibility(var TransmissionPage: TestPage "Transmission IRIS"; ExpectedVisible: Boolean)
    begin
        Assert.AreEqual(ExpectedVisible, TransmissionPage.RemoveTransmissionAndResetDocuments.Visible(), 'Reset visibility must require a sandbox.');
        Assert.AreEqual(ExpectedVisible, TransmissionPage.RemoveTransmissionAndDocuments.Visible(), 'Delete visibility must require a sandbox.');
    end;

    local procedure VerifySandboxCardClosed(var TransmissionPage: TestPage "Transmission IRIS")
    begin
        asserterror TransmissionPage.First();
        Assert.ExpectedError(TestPageClosedErr);
        Assert.ExpectedErrorCode('TestPageNotOpen');
    end;

    local procedure VerifySandboxConflict(DocumentID: Integer)
    begin
        Assert.ExpectedError(StrSubstNo(SandboxConflictTxt, DocumentID));
        Assert.ExpectedErrorCode('Dialog');
    end;

    local procedure VerifySandboxContentsUnchanged()
    var
        CurrentSnapshot: Dictionary of [Text, BigInteger];
    begin
        CaptureSandboxContentsSnapshot(CurrentSnapshot);
        VerifySandboxSnapshotValues(SandboxContentsSnapshot, CurrentSnapshot);
    end;

    local procedure VerifySandboxDocumentDeleted(DocumentID: Integer)
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        DocLine: Record "IRS 1099 Form Doc. Line";
        DocLineDetail: Record "IRS 1099 Form Doc. Line Detail";
        SupplLine: Record "IRS 1099 Doc. Suppl. Line";
        FormReport: Record "IRS 1099 Form Report";
    begin
        Assert.IsFalse(DocHeader.Get(DocumentID), 'The associated header must be deleted.');
        DocLine.SetRange("Document ID", DocumentID);
        Assert.RecordIsEmpty(DocLine);
        DocLineDetail.SetRange("Document ID", DocumentID);
        Assert.RecordIsEmpty(DocLineDetail);
        SupplLine.SetRange("Document ID", DocumentID);
        Assert.RecordIsEmpty(SupplLine);
        FormReport.SetRange("Document ID", DocumentID);
        Assert.RecordIsEmpty(FormReport);
    end;

    local procedure VerifySandboxRemovalCompleted()
    var
        Transmission: Record "Transmission IRIS";
        TransmissionLog: Record "Transmission Log IRIS";
        TransmissionLogLine: Record "Transmission Log Line IRIS";
        ErrorInformation: Record "Error Information IRIS";
    begin
        Assert.IsFalse(Transmission.Get(SandboxTransmission."Document ID"), 'Only the selected transmission must be removed.');
        TransmissionLog.SetRange("Transmission Document ID", SandboxTransmission."Document ID");
        Assert.RecordIsEmpty(TransmissionLog);
        TransmissionLogLine.SetRange("Transmission Log ID", SandboxHistoryID);
        Assert.RecordIsEmpty(TransmissionLogLine);
        TransmissionLogLine.Reset();
        TransmissionLogLine.SetRange("IRS 1099 Form Document ID", SandboxAbandonedDocHeader.ID);
        Assert.RecordIsEmpty(TransmissionLogLine);
        ErrorInformation.SetRange("Transmission Document ID", SandboxTransmission."Document ID");
        Assert.RecordIsEmpty(ErrorInformation);
        VerifySandboxUnrelatedRecordsUnchanged();
        Assert.AreEqual(0, OfflineRequestPaths.Count(), 'Sandbox removal must not make any HTTP request.');
    end;

    local procedure VerifySandboxRemovalConfirmation(ExpectedDocumentAction: Text)
    var
        Question: Text;
    begin
        Question := LibraryVariableStorage.DequeueText();
        Assert.IsTrue(Question.Contains(StrSubstNo(SandboxConfirmationIdentityTxt, SandboxTransmission."Document ID", SandboxTransmission."Period No.")), 'Confirmation must name ID and year.');
        Assert.IsTrue(Question.Contains(ExpectedDocumentAction), 'Confirmation must describe the document action and deduplicated document count.');
        Assert.IsTrue(Question.Contains('2 local history attempts and all errors'), 'Confirmation must count history and name error cleanup.');
        Assert.IsTrue(Question.Contains('local sandbox cleanup only'), 'Confirmation must state the local-only effect.');
        Assert.IsTrue(Question.Contains('does not cancel IRS/ATS submissions'), 'Confirmation must not imply IRS cancellation.');
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure VerifySandboxRemovalUnchanged()
    var
        CurrentSnapshot: Dictionary of [Text, BigInteger];
    begin
        CaptureSandboxAllRecords(CurrentSnapshot);
        VerifySandboxSnapshotValues(SandboxAllSnapshot, CurrentSnapshot);
    end;

    local procedure VerifySandboxRemovalVisibility(ExpectedVisible: Boolean)
    var
        TransmissionPage: TestPage "Transmission IRIS";
    begin
        OpenSandboxTransmission(TransmissionPage);
        VerifySandboxActionVisibility(TransmissionPage, ExpectedVisible);
        TransmissionPage.Close();
    end;

    local procedure VerifySandboxResetDocHeader(DocumentID: Integer; ExpectedStatus: Enum "IRS 1099 Form Doc. Status")
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
    begin
        DocHeader.Get(DocumentID);
        Assert.AreEqual(ExpectedStatus, DocHeader.Status, 'Only non-abandoned documents become Open.');
        Assert.AreEqual(0, DocHeader."IRIS Transmission Document ID", 'The transmission link must clear.');
        Assert.AreEqual('', DocHeader."IRIS Submission ID", 'The submission identifier must clear.');
        Assert.AreEqual('', DocHeader."IRIS Record ID", 'The record identifier must clear.');
        Assert.AreEqual('', DocHeader."IRIS Last Receipt ID", 'The latest receipt must clear.');
        Assert.AreEqual('', DocHeader."IRIS Last Accepted Receipt ID", 'The accepted receipt must clear.');
        Assert.AreEqual(DocHeader."IRIS Submission Status"::None, DocHeader."IRIS Submission Status", 'The submission status must clear.');
        Assert.IsFalse(DocHeader."IRIS Needs Correction", 'Correction selection must clear.');
        Assert.IsFalse(DocHeader."IRIS Updated Not Sent", 'The unsent update marker must clear.');
        Assert.IsFalse(DocHeader."IRIS Corrected", 'The correction marker must clear.');
        Assert.IsFalse(DocHeader."IRIS Corrected to Zeros", 'The zero correction marker must clear.');
        Assert.IsFalse(DocHeader."Allow Correction", 'Correction permission must clear.');
    end;

    local procedure VerifySandboxSnapshotValues(ExpectedSnapshot: Dictionary of [Text, BigInteger]; CurrentSnapshot: Dictionary of [Text, BigInteger])
    var
        RecordKey: Text;
    begin
        Assert.AreEqual(ExpectedSnapshot.Count(), CurrentSnapshot.Count(), 'Unrelated records must not be added or removed.');
        foreach RecordKey in ExpectedSnapshot.Keys() do begin
            Assert.IsTrue(CurrentSnapshot.ContainsKey(RecordKey), StrSubstNo(SandboxRecordRemainsTxt, RecordKey));
            Assert.AreEqual(ExpectedSnapshot.Get(RecordKey), CurrentSnapshot.Get(RecordKey), StrSubstNo(SandboxRecordUnchangedTxt, RecordKey));
        end;
    end;

    local procedure VerifySandboxUnrelatedRecordsUnchanged()
    var
        CurrentSnapshot: Dictionary of [Text, BigInteger];
    begin
        CaptureSandboxUnrelatedRecords(CurrentSnapshot);
        VerifySandboxSnapshotValues(SandboxSharedSnapshot, CurrentSnapshot);
    end;


    local procedure WriteTextBlob(var Payload: Codeunit "Temp Blob"; Content: Text)
    var
        Output: OutStream;
    begin
        Clear(Payload);
        Payload.CreateOutStream(Output, TextEncoding::UTF8);
        Output.WriteText(Content);
    end;

    [HttpClientHandler]
    procedure OfflineHttpHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        OfflineRequestPaths.Add(Request.Path);
        OfflineObservedRequestKinds += '|' + Request.Path.Replace('https://test.example/', '').Replace('https://production.example/', '');
        Response.HttpStatusCode := 503;
        Response.Content.WriteFrom('SIMULATED: unexpected request blocked');
        case Request.Path of
            'https://test.example/submit', 'https://production.example/submit',
            'https://test.example/status', 'https://production.example/status':
                case OfflineResponses.DequeueText() of
                    'TokenProbe':
                        begin
                            OfflineTokenProbeCount += 1;
                            Response.HttpStatusCode := 200;
                            Response.Content.WriteFrom('<StatusResponse/>');
                        end;
                    'Submission':
                        begin
                            OfflineResponse := '<IntakeA2AResponse><receiptId>' + OfflineReceiptID + '</receiptId></IntakeA2AResponse>';
                            Response.Content.WriteFrom(OfflineResponse);
                            Response.HttpStatusCode := OfflineSubmitHttpStatus;
                        end;
                    'SubmissionWithoutReceipt':
                        begin
                            OfflineResponse := '<IntakeA2AResponse/>';
                            Response.Content.WriteFrom(OfflineResponse);
                            Response.HttpStatusCode := OfflineSubmitHttpStatus;
                        end;
                    'Acknowledgment':
                        begin
                            CaptureLatestOfflinePayload();
                            MockOfflineAcknowledgmentResponse(Response);
                        end;
                    'EditedAcknowledgment':
                        begin
                            SetUnsentCorrectionDuringAcknowledgment(OfflineResponses.DequeueInteger());
                            CaptureLatestOfflinePayload();
                            MockOfflineAcknowledgmentResponse(Response);
                        end;
                    'HistorylessAcknowledgment':
                        MockOfflineAcknowledgmentResponse(Response);
                end;
        end;
        // Never allow any intercepted request, including unexpected destinations, onto the network.
        exit(false);
    end;

    [ConfirmHandler]
    procedure DeclineDestinationConfirmation(Question: Text[1024]; var Reply: Boolean)
    begin
        LibraryVariableStorage.Enqueue(Question);
        Reply := false;
    end;

    [MessageHandler]
    procedure TestDestinationMessageHandler(MessageText: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(MessageText);
    end;

    [ConfirmHandler]
    procedure ConfirmYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    procedure OfflineErrorMessageHandler(MessageText: Text[1024])
    begin
    end;

    [ModalPageHandler]
    procedure DeclineIRISPrivacyConsent(var ConsentPage: TestPage "Cust. Consent Confirmation")
    begin
        LibraryVariableStorage.Enqueue(ConsentPage.ConsentText.Value());
        ConsentPage.Cancel.Invoke();
    end;

    [ModalPageHandler]
    procedure RecoveredReceiptHandler(var TransmissionUpdate: TestPage "Transmission IRIS Update")
    begin
        TransmissionUpdate."Receipt ID".SetValue(OfflineReceiptID);
        TransmissionUpdate.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ChangeConfigurationDuringMappingConfirmation(Question: Text[1024]; var Reply: Boolean)
    var
        ReportingPeriod: Record "IRS Reporting Period";
        Transmission: Record "Transmission IRIS";
    begin
        Transmission.Get(OfflineTransmissionID);
        ReportingPeriod.Get(Transmission."Period No.");
        ReportingPeriod.Validate("IRIS XML Schema Version Test", "XML Schema Version IRIS"::" ");
        ReportingPeriod.Validate("IRIS XML Schema Version Live", "XML Schema Version IRIS"::" ");
        ReportingPeriod.Modify();
        InitializeOfflineConfiguration();
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-XmlSchemaVersionTest', '2.0.3');
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-XmlSchemaVersionLive', '2.0.3');
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-SoftwareID-2027', '27NEW0001');
        LibraryVariableStorage.Enqueue(Question);
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ChangeSchemaBeforePreflight(Question: Text[1024]; var Reply: Boolean)
    begin
        SetPeriodSchema('2026', "XML Schema Version IRIS"::"2.0.3");
        LibraryVariableStorage.Enqueue(Question);
        Reply := true;
    end;

    [ConfirmHandler]
    procedure DeclineAndChangeAttemptConfiguration(Question: Text[1024]; var Reply: Boolean)
    begin
        ChangeConfigurationDuringMappingConfirmation(Question, Reply);
        Reply := not Question.Contains('schema 5.0.7');
    end;

    [ConfirmHandler]
    procedure AcceptMappingConfirmation(Question: Text[1024]; var Reply: Boolean)
    begin
        LibraryVariableStorage.Enqueue(Question);
        Reply := true;
    end;

    [ConfirmHandler]
    procedure DeclineMappingConfirmation(Question: Text[1024]; var Reply: Boolean)
    begin
        LibraryVariableStorage.Enqueue(Question);
        Reply := false;
    end;

    [PageHandler]
    procedure ErrorMessagesPageHandler(var ErrorMessagesPage: TestPage "Error Messages")
    begin
        LibraryVariableStorage.Enqueue(ErrorMessagesPage.Description.Value);
        ErrorMessagesPage.Close();
    end;

    [PageHandler]
    procedure MultipleErrorMessagesPageHandler(var ErrorMessagesPage: TestPage "Error Messages")
    begin
        ErrorMessagesPage.First();
        repeat
            LibraryVariableStorage.Enqueue(ErrorMessagesPage.Description.Value);
        until not ErrorMessagesPage.Next();
        ErrorMessagesPage.Close();
    end;

    [ModalPageHandler]
    procedure SelectIncomeUpdateHandler(var UpdatePage: TestPage "IRS 1099 Form Doc. Update")
    var
        VendorNo: Text;
    begin
        VendorNo := LibraryVariableStorage.DequeueText();
        UpdatePage.First();
        repeat
            UpdatePage."Process Line".SetValue((UpdatePage."Form Box No.".Value = 'NEC-01') and
                (UpdatePage."Vendor No.".Value = VendorNo));
        until not UpdatePage.Next();
        UpdatePage.OK().Invoke();
    end;

    [MessageHandler]
    procedure UpdateTransmissionMessageHandler(MessageText: Text[1024])
    begin
    end;

    [ModalPageHandler]
    procedure SelectNewBoxUpdateHandler(var UpdatePage: TestPage "IRS 1099 Form Doc. Update")
    var
        VendorNo: Text;
    begin
        VendorNo := LibraryVariableStorage.DequeueText();
        UpdatePage.First();
        repeat
            UpdatePage."Process Line".SetValue((UpdatePage."Form Box No.".Value = 'NEC-03') and
                (UpdatePage."Vendor No.".Value = VendorNo));
        until not UpdatePage.Next();
        UpdatePage.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmSandboxRemoval(Question: Text[1024]; var Reply: Boolean)
    begin
        LibraryVariableStorage.Enqueue(Question);
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ChangeSandboxRemovalScope(Question: Text[1024]; var Reply: Boolean)
    var
        TransmissionLogLine: Record "Transmission Log Line IRIS";
    begin
        TransmissionLogLine.Get(SandboxHistoryID, 3);
        TransmissionLogLine.Delete();
        TransmissionLogLine."Line ID" := 4;
        TransmissionLogLine.Insert();
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ChangeSandboxRemovalDocument(Question: Text[1024]; var Reply: Boolean)
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
    begin
        DocHeader.Get(SandboxDocHeader.ID);
        DocHeader."IRIS Last Receipt ID" := 'NEW-RECEIPT';
        DocHeader.Modify();
        Reply := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transmission Log IRIS", OnBeforeDeleteEvent, '', false, false)]
    local procedure FailSandboxHistoryDeletion(var Rec: Record "Transmission Log IRIS"; RunTrigger: Boolean)
    begin
        if RunTrigger and (Rec."Line ID" = SandboxFailHistoryID) then
            Error(SandboxFailureErr);
    end;

}
