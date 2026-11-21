// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Foundation.Company;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
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

    var
        Assert: Codeunit Assert;
        LibraryIRSReportingPeriod: Codeunit "Library IRS Reporting Period";
        LibraryIRS1099FormBox: Codeunit "Library IRS 1099 Form Box";
        LibraryIRS1099Document: Codeunit "Library IRS 1099 Document";
        LibraryIRS1099IRIS: Codeunit "Library - IRS 1099 IRIS";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryFileMgtHandler: Codeunit "Library - File Mgt Handler";
        AzureKeyVaultTestLibrary: Codeunit "Azure Key Vault Test Library";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        MockAzureKeyVaultSecretProvider: DotNet MockAzureKeyVaultSecretProvider;
        IsInitialized: Boolean;
        XmlDetailPathTok: Label '//n1:Form1099%1Detail/', Locked = true;
        XmlTotalPathTok: Label '//n1:Form1099%1TotalAmtGrp/', Locked = true;
        UnknownSupplementalErr: Label 'Document %1, supplemental box CUSTOM', Locked = true;
        LegacySupplementalErr: Label 'Document %1 contains supplemental lines', Locked = true;
        OfflineRequestPaths: List of [Text];
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
        OfflineTransmissionID: Integer;

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
        // [SCENARIO 653992] Period overrides are independent and entry does not require a verified tax year.
        Initialize();

        // [GIVEN] Period "P" for an unverified year with different TEST and production overrides.
        LibraryIRSReportingPeriod.CreateSpecificReportingPeriod('2099', 20990101D, 20991231D);
        ReportingPeriod.Get('2099');
        ReportingPeriod.Validate("IRIS XML Schema Version Test", "XML Schema Version IRIS"::"5.0.7");
        ReportingPeriod.Validate("IRIS XML Schema Version Live", "XML Schema Version IRIS"::"2.0.3");
        ReportingPeriod.Modify(true);

        // [WHEN] Resolving each environment independently.

        // [THEN] Each selected override wins without reading Key Vault or the other slot.
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
        // [SCENARIO 653992] An empty effective setting fails instead of selecting the older XML contract.
        Initialize();

        // [GIVEN] The effective wire version is empty.

        // [WHEN] The selected provider returns an empty effective schema.
        asserterror LibraryIRS1099IRIS.ParseSchemaVersion('');

        // [THEN] The error names supported actual XML versions.
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
        // [SCENARIO 653992] An unimplemented enum selection cannot be saved as a supported override.
        Initialize();

        // [GIVEN] A reporting period record.
        ReportingPeriod.Init();

        // [WHEN] A value without standard implementation is selected.
        asserterror ReportingPeriod.Validate("IRIS XML Schema Version Test", "XML Schema Version IRIS".FromInteger(100000));

        // [THEN] Entry fails rather than falling back.
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
        // [SCENARIO 653992] An enum extension without an implementation cannot become an effective schema.
        Initialize();

        // [GIVEN] P has an unimplemented enum value assigned without field validation.
        InitializeEmptySchemaPeriod();
        ReportingPeriod.Get('2099');
        ReportingPeriod."IRIS XML Schema Version Test" := "XML Schema Version IRIS"::"Unimplemented Test";
        ReportingPeriod.Modify();

        // [WHEN] The standard resolver uses that override.
        asserterror LibraryIRS1099IRIS.ResolveSchemaVersion('2099', Source);

        // [THEN] The missing implementation fails rather than falling back.
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
        // [SCENARIO 653992] Alternating schemas on the same adapter retains no XML, counters or zero-correction state.
        Initialize();

        // [GIVEN] T contains an accepted 2025 document available under both contracts.
        CreateContractTransmission(Transmission, IRS1099FormDocHeader, 2025);
        SetCorrectionReference(IRS1099FormDocHeader);

        // [WHEN] The adapter generates a zero correction with 5.0.7.
        IRSFormsFacade.CreateTransmissionXmlContent(
            Transmission, "Transmission Type IRIS"::C, true, UniqueTransmissionId, TempIRS1099FormDocHeader, Payload);

        // [THEN] Only that attempt uses zero amounts and the new correction reference.
        VerifySchemaAttempt(Payload, '5.0.7', '1', '0', '1');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:OtherIntakeSystemInd', '0');
        PreviousTransmissionId := UniqueTransmissionId;

        // [WHEN] The same adapter generates an ordinary transmission with 2.0.3.
        SetPeriodSchema('2025', "XML Schema Version IRIS"::"2.0.3");
        Clear(Payload);
        IRSFormsFacade.CreateTransmissionXmlContent(
            Transmission, "Transmission Type IRIS"::O, false, UniqueTransmissionId, TempIRS1099FormDocHeader, Payload);

        // [THEN] It has its own XML and counters, reports income and contains no correction group.
        VerifySchemaAttempt(Payload, '2.0.3', '0', '5000', '0');
        LibraryXPathXMLReader.VerifyXmlNodeAbsence('//n1:PrevSubmittedRecRecipientGrp');
        Assert.AreNotEqual(PreviousTransmissionId, UniqueTransmissionId, 'Each attempt needs its own UTID.');
        PreviousTransmissionId := UniqueTransmissionId;

        // [WHEN] The adapter switches back to 5.0.7 for another ordinary transmission.
        SetPeriodSchema('2025', "XML Schema Version IRIS"::"5.0.7");
        Clear(Payload);
        IRSFormsFacade.CreateTransmissionXmlContent(
            Transmission, "Transmission Type IRIS"::O, false, UniqueTransmissionId, TempIRS1099FormDocHeader, Payload);

        // [THEN] The new contract is restored without reviving its previous zero-correction state.
        VerifySchemaAttempt(Payload, '5.0.7', '1', '5000', '0');
        LibraryXPathXMLReader.VerifyXmlNodeAbsence('//n1:PrevSubmittedRecRecipientGrp');
        Assert.AreNotEqual(PreviousTransmissionId, UniqueTransmissionId, 'Each attempt needs its own UTID.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure TaxYearValidationAcceptsInclusiveBoundaries()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] The first and last allowed tax years both pass validation.
        Initialize();

        // [GIVEN] The supplied years are the inclusive reporting boundaries.

        // [WHEN] Validating both boundaries.
        LibraryIRS1099IRIS.ValidateTaxYear('2000');
        LibraryIRS1099IRIS.ValidateTaxYear('3000');

        // [THEN] Neither boundary raises a validation error.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure TaxYearValidationRejectsOutOfRangeYears()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Four-digit years immediately outside the allowed range fail validation.
        Initialize();

        // [GIVEN] The supplied years lie outside the reporting boundaries.

        // [WHEN] Validating years immediately outside both boundaries.

        // [THEN] Each year fails with the shared tax-year validation error.
        VerifyInvalidTaxYear('1999');
        VerifyInvalidTaxYear('3001');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure TaxYearValidationRejectsMalformedYears()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A tax year must contain exactly four digits without signs or whitespace.
        Initialize();

        // [GIVEN] The supplied year strings have invalid length or characters.

        // [WHEN] Validating empty, short, long, signed and nonnumeric input.

        // [THEN] Each input fails with the shared tax-year validation error.
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
        // [SCENARIO 653992] Software identity resolution rejects an invalid year before reading configuration.
        Initialize();

        // [GIVEN] The Software ID is requested for a year outside the reporting boundaries.

        // [WHEN] Resolving the Software ID for a year above the allowed range.
        asserterror LibraryIRS1099IRIS.ResolveSoftwareId('3001');

        // [THEN] The shared year validation fails before Software ID validation.
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
        // [SCENARIO 653992] Resource fallback cannot bypass the allowed tax-year range.
        Initialize();

        // [GIVEN] Mappings are requested for a year outside the reporting boundaries.

        // [WHEN] Looking up mappings for a year above the allowed range.
        asserterror AmountXmlElements := LibraryIRS1099IRIS.GetAmountXmlElements('3001');

        // [THEN] The shared year validation fails instead of reusing an earlier resource.
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
        // [SCENARIO 653992] An original-interface extension cannot use a newer Software ID for an older year.
        Initialize();

        // [GIVEN] An original-interface implementation returning an approved-format 2026 ID.
        MockKeyVaultClientIRIS.SetSoftwareId('26TEST0001');

        // [WHEN] The extension's shared ID is requested for 2025.
        asserterror LibraryIRS1099IRIS.ResolveSoftwareId('2025');

        // [THEN] The mismatch fails locally and identifies the requested year and prefix.
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
        // [SCENARIO 653992] Both released facade methods invoke the selected nonstandard XML implementation.
        Initialize();

        // [GIVEN] A selected partner implementation.
        IRSFormsSetup.Get();
        IRSFormsSetup.Implementation := IRSFormsSetup.Implementation::"Mock XML Test";
        IRSFormsSetup.Modify();

        // [WHEN] Status XML is requested through the facade.
        IRSFormsFacade.CreateGetStatusRequestXmlContent("Search Param Type IRIS"::RID, 'RECEIPT', TempBlob);

        // [THEN] The result was produced by the partner, not the standard generator.
        TempBlob.CreateInStream(ContentStream, TextEncoding::UTF8);
        ContentStream.ReadText(Content);
        Assert.AreEqual('PartnerStatus:RECEIPT', Content, 'The partner status implementation must be called.');

        // [WHEN] Acknowledgment XML is requested through the same facade.
        Clear(TempBlob);
        IRSFormsFacade.CreateAcknowledgmentRequestXmlContent("Search Param Type IRIS"::UTID, 'UTID', TempBlob);

        // [THEN] The partner acknowledgment implementation is called too.
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
        // [SCENARIO 653992] New-contract IRIS corrections identify the intake system before the accepted reference.
        Initialize();

        // [GIVEN] A selected accepted TY2026 record to correct.
        CreateContractTransmission(Transmission, IRS1099FormDocHeader, 2026);
        IRS1099FormDocHeader."IRIS Needs Correction" := true;
        IRS1099FormDocHeader."IRIS Last Accepted Receipt ID" := 'ACCEPTED';
        IRS1099FormDocHeader."IRIS Submission ID" := '1';
        IRS1099FormDocHeader."IRIS Record ID" := '2';
        IRS1099FormDocHeader.Modify();

        // [WHEN] A correction is generated.
        LibraryIRS1099IRIS.CreateTransmissionXmlContent(Transmission, "Transmission Type IRIS"::C, false, UniqueTransmissionId, TempIRS1099FormDocHeader, TempBlob);

        // [THEN] Both new-contract reference elements are present in order.
        VerifyContractManifest(TempBlob, '2026', '26TEST0001', '0');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:PrevSubmittedRecRecipientGrp/*[1]', '0');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:PrevSubmittedRecRecipientGrp/*[2]', 'ACCEPTED|1|2');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure StandardSoftwareIdsAlternateWithoutSharedIdChanges()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Standard uses only the requested year's key, including a supported earlier year.
        Initialize();

        // [GIVEN] All year IDs exist together with a deliberately incompatible legacy shared ID.
        InitializeStandardProvider();
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-SoftwareID-2024', '24TEST0001');
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-SoftwareID-2025', '25TEST0001');
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-SoftwareID-2026', '26TEST0001');
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-SoftwareID', '99SHARED');

        // [WHEN] Supported years alternate without reconfiguring the provider.

        // [THEN] Each lookup selects its own identity, never the shared or newest ID.
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
        // [SCENARIO 653992] Neither a legacy shared ID nor a newer ID satisfies a missing year key.
        Initialize();

        // [GIVEN] Only shared and TY2026 IDs are configured.
        InitializeStandardProvider();
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-SoftwareID', '25SHARED');
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-SoftwareID-2026', '26TEST0001');

        // [WHEN] TY2025 is requested.
        asserterror LibraryIRS1099IRIS.ResolveSoftwareId('2025');

        // [THEN] The missing identity blocks the operation without using a shared or newer ID.
        Assert.ExpectedError('Software ID');
        Assert.ExpectedErrorCode('Dialog');
        ResetStandardProvider();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure MismatchedStandardYearIdFailsLocally()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A valid-looking but wrong-year Standard identity is not accepted.
        Initialize();

        // [GIVEN] TY2025 is accidentally provisioned with a TY2026 identity.
        InitializeStandardProvider();
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-SoftwareID-2025', '26TEST0001');

        // [WHEN] TY2025 is requested.
        asserterror LibraryIRS1099IRIS.ResolveSoftwareId('2025');

        // [THEN] The required year prefix is reported before submission.
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
        // [SCENARIO 653992] The active empty slot uses its provider and ignores an unsupported inactive slot.
        Initialize();

        // [GIVEN] Independent provider defaults and a default-empty period.
        InitializeStandardProvider();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        EnvironmentInfoTestLibrary.SetTestabilitySandbox(true);
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-XmlSchemaVersionTest', '5.0.7');
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-XmlSchemaVersionLive', '2.0.3');
        InitializeEmptySchemaPeriod();
        ReportingPeriod.Get('2099');
        ReportingPeriod."IRIS XML Schema Version Live" := "XML Schema Version IRIS".FromInteger(100000);
        ReportingPeriod.Modify();

        // [WHEN] The active TEST slot is empty.

        // [THEN] Provider TEST configuration applies despite the inactive unsupported slot.
        Assert.AreEqual("XML Schema Version IRIS"::"5.0.7", LibraryIRS1099IRIS.ResolveSchemaVersion('2099', Source), 'Use TEST provider.');
        Assert.AreEqual('KeyVault', Source, 'Provider source must be retained.');

        // [WHEN] TEST is overridden and then cleared again.
        ReportingPeriod.Validate("IRIS XML Schema Version Test", "XML Schema Version IRIS"::"2.0.3");
        ReportingPeriod.Modify();
        Assert.AreEqual("XML Schema Version IRIS"::"2.0.3", LibraryIRS1099IRIS.ResolveSchemaVersion('2099', Source), 'Explicit older contract remains supported.');
        ReportingPeriod.Validate("IRIS XML Schema Version Test", "XML Schema Version IRIS"::" ");
        ReportingPeriod.Validate("IRIS XML Schema Version Live", "XML Schema Version IRIS"::" ");
        ReportingPeriod.Modify();

        // [THEN] Each default is restored independently.
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
        // [SCENARIO 653992] Missing new configuration cannot use retired settings or downgrade.
        Initialize();

        // [GIVEN] Only a retired setting exists.
        InitializeStandardProvider();
        InitializeEmptySchemaPeriod();
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-ReleaseProfileLive', 'Legacy');

        // [WHEN] The selected production setting cannot be obtained.
        asserterror LibraryIRS1099IRIS.ResolveSchemaVersion('2099', Source);

        // [THEN] The operation stops rather than downgrading.
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
        // [SCENARIO 653992] Empty retrieval has the same truthful fail-closed diagnostic as missing configuration.
        Initialize();

        // [GIVEN] An explicitly empty selected setting.
        InitializeStandardProvider();
        InitializeEmptySchemaPeriod();
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-XmlSchemaVersionLive', '');

        // [WHEN] The effective production version is requested.
        asserterror LibraryIRS1099IRIS.ResolveSchemaVersion('2099', Source);

        // [THEN] No fallback is applied or retrieval cause invented.
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
        // [SCENARIO 653992] A retrieved alias is not accepted as a wire version.
        Initialize();

        // [GIVEN] A retired value in the new key.
        InitializeStandardProvider();
        InitializeEmptySchemaPeriod();
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-XmlSchemaVersionLive', 'PY2027');

        // [WHEN] The production version is resolved.
        asserterror LibraryIRS1099IRIS.ResolveSchemaVersion('2099', Source);

        // [THEN] Standard parsing rejects the alias explicitly.
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
        // [SCENARIO 653992] Use-time validation rejects an unsupported stored value even with a valid provider.
        Initialize();

        // [GIVEN] An unsupported value inserted without entry validation.
        InitializeStandardProvider();
        InitializeEmptySchemaPeriod();
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-XmlSchemaVersionLive', '2.0.3');
        ReportingPeriod.Get('2099');
        ReportingPeriod."IRIS XML Schema Version Live" := "XML Schema Version IRIS".FromInteger(100000);
        ReportingPeriod.Modify();

        // [WHEN] The active override is resolved.
        asserterror LibraryIRS1099IRIS.ResolveSchemaVersion('2099', Source);

        // [THEN] The unsupported override is not reinterpreted as an empty/default request.
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
        // [SCENARIO 653992] The card and setup show the destination and endpoint used by the sender, independently of schema selection.
        Initialize();

        // [GIVEN] Standard identities and distinct non-routable endpoint slots.
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

        // [WHEN] The same schema is generated in sandbox.
        IRSFormsFacade.CreateTransmissionXmlContent(Transmission, "Transmission Type IRIS"::O, false, UniqueTransmissionId, TempIRS1099FormDocHeader, TempBlob);
        TransmissionPage.OpenEdit();
        TransmissionPage.GoToRecord(Transmission);

        // [THEN] Actual XML, endpoints and visible destination are Test.
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

        // [WHEN] BC is production with the same period/schema.
        EnvironmentInfoTestLibrary.SetTestabilitySandbox(false);
        IRSFormsFacade.CreateTransmissionXmlContent(Transmission, "Transmission Type IRIS"::O, false, UniqueTransmissionId, TempIRS1099FormDocHeader, TempBlob);
        TransmissionPage.OpenEdit();
        TransmissionPage.GoToRecord(Transmission);

        // [THEN] Production is stated explicitly without changing schema.
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
        // [SCENARIO 653992] Transmission And Setup Open When Submit Endpoint Is Missing.
        Initialize();

        // [GIVEN] The standard provider has no production submission endpoint.
        InitializeStandardProvider();
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-ClientID', '11111111-2222-4333-8444-555555555555');

        // [WHEN] The requested operation is executed through its existing entry point.

        // [THEN] The expected result and preserved data are verified.
        VerifyPagesOpenWithoutSubmitEndpoint();
        ResetStandardProvider();

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure TransmissionAndSetupOpenWhenSubmitEndpointIsEmpty()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Transmission And Setup Open When Submit Endpoint Is Empty.
        Initialize();

        // [GIVEN] The standard provider has an empty production submission endpoint.
        InitializeStandardProvider();
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-ClientID', '11111111-2222-4333-8444-555555555555');
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-SubmitEndpointLive', '');

        // [WHEN] The requested operation is executed through its existing entry point.

        // [THEN] The expected result and preserved data are verified.
        VerifyPagesOpenWithoutSubmitEndpoint();
        ResetStandardProvider();

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('DeclineDestinationConfirmation')]
    procedure TestSendConfirmationsDescribeAtsAndAllowCancellation()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Test Send Confirmations Describe Ats And Allow Cancellation.
        Initialize();

        // [GIVEN] T uses the sandbox destination for TY2025.

        // [WHEN] The requested operation is executed through its existing entry point.
        VerifySendConfirmationDestination(true);

        // [THEN] The expected result and preserved data are verified.
        VerifyTestSendConfirmations();

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('DeclineDestinationConfirmation')]
    procedure ProductionSendConfirmationsDescribeLiveSubmissionAndAllowCancellation()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Production Send Confirmations Describe Live Submission And Allow Cancellation.
        Initialize();

        // [GIVEN] T uses the production destination for TY2025.

        // [WHEN] The requested operation is executed through its existing entry point.
        VerifySendConfirmationDestination(false);

        // [THEN] The expected result and preserved data are verified.
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
        // [SCENARIO 653992] History names come from each attempt, and missing historical context is not guessed.
        Initialize();

        // [GIVEN] Attempts A, B and C have Test, Production and missing destination evidence.
        TestAttempt."XML Test Code" := 'T';
        TestAttempt.Insert(true);
        ProductionAttempt."XML Test Code" := 'P';
        ProductionAttempt.Insert(true);
        EarlierAttempt.Insert(true);

        // [WHEN] The requested operation is executed through its existing entry point.
        EnvironmentInfoTestLibrary.SetTestabilitySandbox(false);
        HistoryPage.OpenView();
        HistoryPage.GoToRecord(TestAttempt);

        // [THEN] The expected result and preserved data are verified.
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
        // [SCENARIO 653992] NEC disclosures remain breakdowns and occupation codes appear between tips and overtime.
        Initialize();

        // [GIVEN] Document D contains compensation 5000, tips 100, overtime 50 and codes 101 and 000.
        CreateSupplementalTransmission(Transmission, IRS1099FormDocHeader, 'NEC');

        // [WHEN] An original is generated through the existing facade.
        CreateSupplementalXml(Transmission, "Transmission Type IRIS"::O, false, TempBlob);

        // [THEN] Financial income is unchanged and detail/total sequences follow the schema.
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
        // [SCENARIO 653992] MISC places detail disclosures after deferrals but total tips immediately after withholding.
        Initialize();

        // [GIVEN] Document D has MISC disclosures included in other income.
        CreateSupplementalTransmission(Transmission, IRS1099FormDocHeader, 'MISC');

        // [WHEN] The original XML is generated.
        CreateSupplementalXml(Transmission, "Transmission Type IRIS"::O, false, TempBlob);

        // [THEN] Details and totals retain their independently specified ordering.
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
        // [SCENARIO 653992] Submission totals sum rounded recipient values independently for tips and overtime.
        Initialize();

        // [GIVEN] D and E are different recipients with tips 0.006 and overtime 0.004 each.
        CreateSupplementalTransmission(Transmission, IRS1099FormDocHeader, 'NEC');
        AddSupplementalHeader(IRS1099FormDocHeader, SecondIRS1099FormDocHeader, false);
        SetSupplementalValues(IRS1099FormDocHeader, 0.006, 0.004, '101', '000');
        SetSupplementalValues(SecondIRS1099FormDocHeader, 0.006, 0.004, '102', '');

        // [WHEN] Original XML is generated.
        CreateSupplementalXml(Transmission, "Transmission Type IRIS"::O, false, TempBlob);

        // [THEN] Each recipient contributes its outgoing cents, never the rounded raw submission sum.
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
        // [SCENARIO 653992] Raw sub-cent sources combine before rounding and retain all eligible text codes.
        Initialize();

        // [GIVEN] D and E form one recipient with tips 0.004, overtime 0.006 and the same two codes.
        CreateSupplementalTransmission(Transmission, IRS1099FormDocHeader, 'NEC');
        AddSupplementalHeader(IRS1099FormDocHeader, SecondIRS1099FormDocHeader, true);
        SetSupplementalValues(IRS1099FormDocHeader, 0.004, 0.006, '000', '101');
        SetSupplementalValues(SecondIRS1099FormDocHeader, 0.004, 0.006, '101', '000');

        // [WHEN] Original XML is generated.
        CreateSupplementalXml(Transmission, "Transmission Type IRIS"::O, false, TempBlob);

        // [THEN] Both money elements round once at the recipient boundary and codes remain deduplicated text.
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
        // [SCENARIO 653992] Outgoing zero tips suppress codes without changing raw values or independent overtime.
        Initialize();

        // [GIVEN] D has positive raw tips that round to zero and overtime that rounds up.
        CreateSupplementalTransmission(Transmission, IRS1099FormDocHeader, 'MISC');
        SetSupplementalValues(IRS1099FormDocHeader, 0.004, 0.006, '101', '000');

        // [WHEN] Original XML is generated.
        CreateSupplementalXml(Transmission, "Transmission Type IRIS"::O, false, TempBlob);

        // [THEN] Only outgoing tips control code suppression, and the source remains unchanged.
        VerifySupplementalXml(TempBlob, 'MISC', '5000', '0', '0.01');
        LibraryXPathXMLReader.VerifyXmlNodeAbsence('//n1:TreasuryTippedOccupationCd');
        VerifySavedSupplementalValues(IRS1099FormDocHeader, 0.004, 0.006, '101', '000');
        VerifyDocLineAmount(IRS1099FormDocHeader, 'MISC-03', 5000);

        // [GIVEN] D's tips increase to a positive outgoing cent.
        SetSupplementalValues(IRS1099FormDocHeader, 0.006, 0.004, '101', '000');

        // [WHEN] The original is regenerated.
        CreateSupplementalXml(Transmission, "Transmission Type IRIS"::O, false, TempBlob);

        // [THEN] Saved codes are available again and overtime rounds independently to zero.
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
        // [SCENARIO 653992] The recipient code limit applies only when its combined outgoing tips are positive.
        Initialize();

        // [GIVEN] D and E have a three-code union but combined tips still round to zero.
        CreateSupplementalTransmission(Transmission, IRS1099FormDocHeader, 'NEC');
        AddSupplementalHeader(IRS1099FormDocHeader, SecondIRS1099FormDocHeader, true);
        SetSupplementalValues(IRS1099FormDocHeader, 0.001, 0.004, '101', '000');
        SetSupplementalValues(SecondIRS1099FormDocHeader, 0.001, 0.004, '101', '102');

        // [WHEN] Original XML is generated.
        CreateSupplementalXml(Transmission, "Transmission Type IRIS"::O, false, TempBlob);

        // [THEN] All codes are suppressed without rejecting or rewriting the saved raw contributors.
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
        // [SCENARIO 653992] Legal raw submission sums can still exceed the bound after recipient rounding.
        Initialize();

        // [GIVEN] D and E have legal raw tips summing to the maximum, but their outgoing cents exceed it.
        CreateSupplementalTransmission(Transmission, IRS1099FormDocHeader, 'NEC');
        AddSupplementalHeader(IRS1099FormDocHeader, SecondIRS1099FormDocHeader, false);
        SetDocLineAmount(IRS1099FormDocHeader, 'NEC-01', 499999999999999.995, 2000);
        SetDocLineAmount(SecondIRS1099FormDocHeader, 'NEC-01', 499999999999999.995, 2000);
        SetSupplementalValues(IRS1099FormDocHeader, 499999999999999.995, 0, '101', '');
        SetSupplementalValues(SecondIRS1099FormDocHeader, 499999999999999.995, 0, '102', '');

        // [WHEN] The original is generated.
        asserterror CreateSupplementalXml(Transmission, "Transmission Type IRIS"::O, false, TempBlob);

        // [THEN] The rounded submission sum is rejected explicitly, with both contributing documents.
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
        // [SCENARIO 653992] Only selected correction documents contribute amounts, codes and recipient counts.
        Initialize();

        // [GIVEN] Selected document D and unselected document U belong to the same transmission.
        CreateSupplementalTransmission(Transmission, IRS1099FormDocHeader, 'NEC');
        AddSupplementalHeader(IRS1099FormDocHeader, UnselectedIRS1099FormDocHeader, false);
        SetSupplementalValues(IRS1099FormDocHeader, 0.006, 0.004, '101', '000');
        SetSupplementalValues(UnselectedIRS1099FormDocHeader, 200, 75, '102', '103');
        SetCorrectionReference(IRS1099FormDocHeader);

        // [WHEN] An ordinary correction is generated.
        CreateSupplementalXml(Transmission, "Transmission Type IRIS"::C, false, TempBlob);

        // [THEN] U contributes neither a recipient nor disclosures.
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
        // [SCENARIO 653992] Eligible rents and zero withholding cannot qualify other-income disclosures; positive withholding can.
        Initialize();

        // [GIVEN] D has rent 2500, other income 500 and saved valid disclosures.
        CreateSupplementalTransmission(Transmission, IRS1099FormDocHeader, 'MISC');
        SetDocLineAmount(IRS1099FormDocHeader, 'MISC-03', 500, 2000);
        SetDocLineAmount(IRS1099FormDocHeader, 'MISC-01', 2500, 2000);
        SetDocLineAmount(IRS1099FormDocHeader, 'MISC-04', 0, 0);

        // [WHEN] XML is generated without positive backup withholding.
        CreateSupplementalXml(Transmission, "Transmission Type IRIS"::O, false, TempBlob);

        // [THEN] Only the saved parent's eligibility controls the disclosures.
        VerifySupplementalXml(TempBlob, 'MISC', '0', '0', '0');
        LibraryXPathXMLReader.VerifyXmlNodeValue('//n1:Form1099MISCDetail/n1:RentAmt', '2500');
        LibraryXPathXMLReader.VerifyXmlNodeAbsence('//n1:TreasuryTippedOccupationCd');

        // [GIVEN] Positive withholding makes the nonzero parent reportable.
        SetDocLineAmount(IRS1099FormDocHeader, 'MISC-04', 25, 0);

        // [WHEN] XML is regenerated after the shared financial eligibility refresh.
        CreateSupplementalXml(Transmission, "Transmission Type IRIS"::O, false, TempBlob);

        // [THEN] Retained disclosures and codes are restored without additional income.
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
        // [SCENARIO 653992] Zero-tip codes remain stored but are emitted only after positive reportable tips return.
        Initialize();

        // [GIVEN] D has zero tips and retains its two text codes.
        CreateSupplementalTransmission(Transmission, IRS1099FormDocHeader, 'NEC');
        SetSupplementalValues(IRS1099FormDocHeader, 0, 50, '101', '000');

        // [WHEN] The original is generated.
        CreateSupplementalXml(Transmission, "Transmission Type IRIS"::O, false, TempBlob);

        // [THEN] Overtime is emitted, but occupation elements are absent.
        VerifySupplementalXml(TempBlob, 'NEC', '5000', '0', '50');
        LibraryXPathXMLReader.VerifyXmlNodeAbsence('//n1:TreasuryTippedOccupationCd');
        VerifySavedSupplementalValues(IRS1099FormDocHeader, 0, 50, '101', '000');

        // [GIVEN] Positive tips are restored using the retained codes.
        SetSupplementalValues(IRS1099FormDocHeader, 125, 50, '101', '000');

        // [WHEN] Another original is generated.
        CreateSupplementalXml(Transmission, "Transmission Type IRIS"::O, false, TempBlob);

        // [THEN] The leading-zero code reappears.
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
        // [SCENARIO 653992] The recipient limit applies across all contributing headers and identifies those documents.
        Initialize();

        // [GIVEN] D and E each have valid codes but their recipient union contains three.
        CreateSupplementalTransmission(Transmission, IRS1099FormDocHeader, 'NEC');
        AddSupplementalHeader(IRS1099FormDocHeader, SecondIRS1099FormDocHeader, true);
        SetSupplementalValues(IRS1099FormDocHeader, 0.004, 0.006, '101', '000');
        SetSupplementalValues(SecondIRS1099FormDocHeader, 0.004, 0.006, '101', '102');

        // [WHEN] XML is generated.
        asserterror CreateSupplementalXml(Transmission, "Transmission Type IRIS"::O, false, TempBlob);

        // [THEN] No truncation hides the third code and the error identifies both contributors.
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
        // [SCENARIO 653992] A custom definition is not silently treated as an implemented XML mapping.
        Initialize();

        // [GIVEN] D has a populated unmapped custom supplemental row.
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

        // [WHEN] An original is generated.
        asserterror CreateSupplementalXml(Transmission, "Transmission Type IRIS"::O, false, TempBlob);

        // [THEN] The document and unsupported disclosure are identified explicitly.
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
        // [SCENARIO 653992] An explicit legacy contract cannot silently omit populated 2026 disclosures.
        Initialize();

        // [GIVEN] D has disclosures but its period explicitly selects the legacy schema.
        CreateSupplementalTransmission(Transmission, IRS1099FormDocHeader, 'NEC');
        SetPeriodSchema('2026', "XML Schema Version IRIS"::"2.0.3");

        // [WHEN] Generation is attempted.
        asserterror CreateSupplementalXml(Transmission, "Transmission Type IRIS"::O, false, TempBlob);

        // [THEN] The incompatible schema is actionable rather than an implicit downgrade.
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
        // [SCENARIO 653992] A selected zero correction zeros outbound financial/disclosure values without altering saved source.
        Initialize();

        // [GIVEN] Selected D has accepted references; U must remain excluded.
        CreateSupplementalTransmission(Transmission, IRS1099FormDocHeader, 'NEC');
        AddSupplementalHeader(IRS1099FormDocHeader, UnselectedIRS1099FormDocHeader, false);
        SetSupplementalValues(UnselectedIRS1099FormDocHeader, 200, 75, '102', '103');
        SetCorrectionReference(IRS1099FormDocHeader);

        // [WHEN] A zero correction is generated.
        CreateSupplementalXml(Transmission, "Transmission Type IRIS"::C, true, TempBlob);

        // [THEN] Outbound values are zero, codes absent and original source/reference values unchanged.
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
        // [SCENARIO 653992] A zero correction cannot invent an accepted original reference.
        Initialize();

        // [GIVEN] D is selected for correction without an accepted reference.
        CreateSupplementalTransmission(Transmission, IRS1099FormDocHeader, 'MISC');
        IRS1099FormDocHeader."IRIS Needs Correction" := true;
        IRS1099FormDocHeader.Modify();

        // [WHEN] A zero correction is generated.
        asserterror CreateSupplementalXml(Transmission, "Transmission Type IRIS"::C, true, TempBlob);

        // [THEN] The missing accepted reference prevents the correction.
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
        // [SCENARIO 653992] Step two uses original semantics even when the document retains its previous accepted reference.
        Initialize();

        // [GIVEN] D has a previously accepted zero correction and is released for step two.
        CreateSupplementalTransmission(Transmission, IRS1099FormDocHeader, 'MISC');
        SetCorrectionReference(IRS1099FormDocHeader);
        IRS1099FormDocHeader."IRIS Corrected to Zeros" := true;
        IRS1099FormDocHeader.Modify();

        // [WHEN] Step two generates a new original.
        CreateSupplementalXml(Transmission, "Transmission Type IRIS"::O, false, TempBlob);

        // [THEN] Original semantics restore disclosures without a previous-recipient group.
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
        // [SCENARIO 653992] Configuring overtime first in a statement does not move it before tips in actual XML.
        Initialize();

        // [GIVEN] D has a user-configured statement with overtime before tips.
        CreateSupplementalTransmission(Transmission, IRS1099FormDocHeader, 'NEC');
        StatementLine.SetRange("Period No.", '2026');
        StatementLine.SetRange("Form No.", 'NEC');
        StatementLine.DeleteAll(true);
        InsertSupplementalStatement('NEC-01D', 1, 'Overtime first');
        InsertSupplementalStatement('NEC-01C', 2, 'Codes second');
        InsertSupplementalStatement('NEC-01B', 3, 'Tips last');

        // [WHEN] Both the statement dataset and actual transmission XML are generated.
        Lines := LibraryIRS1099Document.GetStatementDataset(IRS1099FormDocHeader);
        CreateSupplementalXml(Transmission, "Transmission Type IRIS"::O, false, TempBlob);

        // [THEN] The statement follows setup while XML independently follows the XSD.
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
        // [SCENARIO 653992] Both 2025 contracts retain their financial mappings without new disclosure elements.
        Initialize();

        // [GIVEN] A 2025 document uses the new supported contract.
        CreateContractTransmission(Transmission, IRS1099FormDocHeader, 2025);

        // [WHEN] New-contract XML is generated.
        CreateSupplementalXml(Transmission, "Transmission Type IRIS"::O, false, TempBlob);

        // [THEN] No 2026 fields leak into 2025 details or totals.
        VerifyNoSupplementalXml(TempBlob);
        VerifyContractManifest(TempBlob, '2025', '25TEST0001', '1');

        // [GIVEN] The same period explicitly selects the legacy contract.
        SetPeriodSchema('2025', "XML Schema Version IRIS"::"2.0.3");

        // [WHEN] Legacy XML is generated.
        CreateSupplementalXml(Transmission, "Transmission Type IRIS"::O, false, TempBlob);

        // [THEN] Its ordinary financial values remain unchanged and disclosures remain absent.
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
        // [SCENARIO 653992] Future-year disclosures reuse the available mapping only after confirmation.
        Initialize();

        // [GIVEN] T contains a TY2027 document D with supplemental disclosures.

        CreateContractTransmission(Transmission, IRS1099FormDocHeader, 2027);
        SetSupplementalValues(IRS1099FormDocHeader, 100, 50, '101', '000');

        // [WHEN] The requested operation is executed through its existing entry point.
        CreateSupplementalXml(Transmission, "Transmission Type IRIS"::O, false, TempBlob);

        // [THEN] The expected result and preserved data are verified.
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
        // [SCENARIO 653992] A year before supplemental reporting has no mapping, even for a known supplemental box.
        Initialize();

        // [GIVEN] The available supplemental resource is for TY2026.

        // [WHEN] The requested operation is executed through its existing entry point.

        // [THEN] The expected result and preserved data are verified.
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
        // [SCENARIO 653992] Configuration edited during consent affects the next attempt, not the current identity.
        Initialize();

        // [GIVEN] An unverified-year attempt starts with a period override and its original year ID.
        CreateContractTransmission(Transmission, IRS1099FormDocHeader, 2027);
        InitializeOfflineTransport(Transmission);
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-SoftwareID-2027', '27TEST0001');

        // [WHEN] Consent edits the actual period and replaces the existing mock provider configuration.
        LibraryIRS1099IRIS.SendOriginal(Transmission);

        // [THEN] Actual persisted XML/history retain the context selected before the edit.
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

        // [WHEN] A later attempt resolves the cleared override and changed provider.
        LibraryIRS1099IRIS.SendOriginal(Transmission);

        // [THEN] It uses the new configuration without rewriting the earlier payload.
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
        // [SCENARIO 653992] Preflight and XML generation read the schema selected after the document warning.
        Initialize();

        // [GIVEN] T uses 5.0.7 for 2026 without contact email and includes an open document warning.
        CreateContractTransmission(Transmission, IRS1099FormDocHeader, 2026);
        AddOpenTransmissionDocument(IRS1099FormDocHeader);
        InitializeOfflineTransport(Transmission);
        UpdateCompanyContactInfo('Test Contact', '1234567890', '');
        Commit();

        // [WHEN] The warning changes the real period to 2.0.3 before contact preflight.
        LibraryIRS1099IRIS.SendOriginal(Transmission);

        // [THEN] Both reads use 2.0.3, where email is optional, without a failed send or retry.
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
        // [SCENARIO 653992] Retrying a cancelled send reads current configuration and requires fresh consent.
        Initialize();

        // [GIVEN] T starts in sandbox for unverified 2027 with the new schema.
        CreateContractTransmission(Transmission, IRS1099FormDocHeader, 2027);
        InitializeOfflineTransport(Transmission);
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-SoftwareID-2027', '27TEST0001');
        Commit();

        // [WHEN] The warning changes the configuration and is declined.
        asserterror LibraryIRS1099IRIS.SendOriginal(Transmission);

        // [THEN] Cancellation writes no attempt and sends no request.
        Assert.AreEqual('', GetLastErrorText(), 'Declining cancels the send.');
        Assert.ExpectedErrorCode('Dialog');
        VerifyMappingConfirmation('2027', '2026', '5.0.7');
        Assert.IsTrue(Attempt.IsEmpty(), 'No cancelled attempt may be stored.');
        Assert.AreEqual(0, OfflineRequestPaths.Count(), 'Cancellation precedes all HTTP requests.');

        // [GIVEN] The next operation explicitly selects a different contract after database rollback.
        SetPeriodSchema('2027', "XML Schema Version IRIS"::"2.0.3");

        // [WHEN] The same record is sent again and this operation is accepted.
        LibraryIRS1099IRIS.SendOriginal(Transmission);

        // [THEN] A fresh warning and actual payload use the new schema and Software ID.
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
        // [SCENARIO 653992] Preflight and several documents require one consent, never a saved waiver.
        Initialize();

        // [GIVEN] Two documents for unverified TY2027 using the available TY2026 resource.
        CreateContractTransmission(Transmission, IRS1099FormDocHeader, 2027);
        SecondIRS1099FormDocHeader := IRS1099FormDocHeader;
        SecondIRS1099FormDocHeader.ID := 0;
        SecondIRS1099FormDocHeader.Insert();
        IRS1099FormDocLine.SetRange("Document ID", IRS1099FormDocHeader.ID);
        IRS1099FormDocLine.FindFirst();
        IRS1099FormDocLine."Document ID" := SecondIRS1099FormDocHeader.ID;
        IRS1099FormDocLine.Insert();

        // [WHEN] Preflight runs twice and the operation generates both documents.
        IRSFormsFacade.CheckDataToReport(Transmission);
        IRSFormsFacade.CheckDataToReport(Transmission);
        IRSFormsFacade.CreateTransmissionXmlContent(Transmission, "Transmission Type IRIS"::O, false, UniqueTransmissionId, TempIRS1099FormDocHeader, TempBlob);

        // [THEN] One explicit warning names the real mapping and retains the requested identity.
        VerifyMappingConfirmation('2027', '2026', '5.0.7');
        VerifyContractManifest(TempBlob, '2027', '27TEST0001', '0');
        Assert.AreEqual(2, TempIRS1099FormDocHeader.Count(), 'Both selected documents must use the same consent.');

        // [WHEN] A new operation uses the same record and generator.
        Clear(TempBlob);
        IRSFormsFacade.CreateTransmissionXmlContent(Transmission, "Transmission Type IRIS"::O, false, UniqueTransmissionId, TempIRS1099FormDocHeader, TempBlob);

        // [THEN] It needs a new consent even though the context is unchanged.
        VerifyMappingConfirmation('2027', '2026', '5.0.7');

        // [WHEN] A later operation changes the selected schema.
        SetPeriodSchema('2027', "XML Schema Version IRIS"::"2.0.3");
        Clear(TempBlob);
        IRSFormsFacade.CreateTransmissionXmlContent(Transmission, "Transmission Type IRIS"::O, false, UniqueTransmissionId, TempIRS1099FormDocHeader, TempBlob);

        // [THEN] The new warning identifies the changed exact version.
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
        // [SCENARIO 653992] Declining mapping reuse cancels before attempt IDs, payload or document writes.
        Initialize();

        // [GIVEN] A released unverified-year document without attempt IDs.
        CreateContractTransmission(Transmission, IRS1099FormDocHeader, 2027);
        UniqueTransmissionId := 'UNCHANGED';
        Commit();

        // [WHEN] The user declines generation.
        asserterror IRSFormsFacade.CreateTransmissionXmlContent(Transmission, "Transmission Type IRIS"::O, false, UniqueTransmissionId, TempIRS1099FormDocHeader, TempBlob);

        // [THEN] No attempt is generated and the released source stays unchanged.
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
        // [SCENARIO 653992] A missing requested-year identity fails before asking to reuse an available mapping.
        Initialize();

        // [GIVEN] TY2027 has a mapping but only TY2026 has an ID.
        CreateContractTransmission(Transmission, IRS1099FormDocHeader, 2027);
        InitializeStandardProvider();
        MockAzureKeyVaultSecretProvider.AddSecretMapping('IRS1099IRIS-SoftwareID-2026', '26TEST0001');
        Commit();

        // [WHEN] Generation resolves the operation's identity before requesting consent.
        asserterror IRSFormsFacade.CreateTransmissionXmlContent(Transmission, "Transmission Type IRIS"::O, false, UniqueTransmissionId, TempIRS1099FormDocHeader, TempBlob);

        // [THEN] The missing requested-year configuration still blocks generation.
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
        // [SCENARIO 653992] An existing older resource is named instead of assuming the newest mapping.
        Initialize();

        // [GIVEN] The new schema is selected for unverified TY2024.
        CreateContractTransmission(Transmission, IRS1099FormDocHeader, 2024);

        // [WHEN] Its actual resource is accepted.
        CreateSupplementalXml(Transmission, "Transmission Type IRIS"::O, false, TempBlob);

        // [THEN] The warning and payload retain the older requested year and matching ID.
        VerifyMappingConfirmation('2024', '2024', '5.0.7');
        VerifyContractManifest(TempBlob, '2024', '24TEST0001', '0');
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
        // [SCENARIO 653992] An unavailable mapping fails explicitly without offering a waiver.
        Initialize();

        // [GIVEN] No resource exists for TY2023 or an earlier usable year.
        CreateContractTransmission(Transmission, IRS1099FormDocHeader, 2023);

        // [WHEN] Generation is attempted without a confirmation handler.
        asserterror CreateSupplementalXml(Transmission, "Transmission Type IRIS"::O, false, TempBlob);

        // [THEN] A missing-resource error replaces neither the mapping nor ordinary validation.
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
        // [SCENARIO 653992] Actual submission preflight reports missing TY2026 email through structured errors.
        Initialize();

        // [GIVEN] Valid TY2026 contact name and phone but no email.
        CreateContractTransmission(Transmission, IRS1099FormDocHeader, 2026);
        UpdateCompanyContactInfo('Test Contact', '1234567890', '');

        // [WHEN] The public preflight is invoked.
        asserterror IRSFormsFacade.CheckDataToReport(Transmission);

        // [THEN] The existing Error Messages page captures the missing email field.
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
        // [SCENARIO 653992] Central contact requirements do not introduce a TY2025 email requirement.
        Initialize();

        // [GIVEN] TY2025 uses the new schema with no contact email.
        CreateContractTransmission(Transmission, IRS1099FormDocHeader, 2025);
        UpdateCompanyContactInfo('Test Contact', '1234567890', '');

        // [WHEN] Actual submission preflight runs.
        IRSFormsFacade.CheckDataToReport(Transmission);

        // [THEN] No contact error was raised.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler,ConfirmYes')]
    procedure ActualTwoStep2026NecPreservesSupplementalSource()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Accepted selected zero correction is followed by the actual Send Corrected original action.
        Initialize();

        // [GIVEN] T contains an accepted TY2026 NEC document D and an unselected document U.

        // [WHEN] Both steps execute through the product orchestrator with simulated HTTP responses.
        VerifyActualTwoStep(2026, 'NEC');

        // [THEN] The expected result and preserved data are verified.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler,ConfirmYes')]
    procedure ActualTwoStep2026MiscPreservesSupplementalSource()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] MISC zero correction retains its separate disclosures through the second-step original.
        Initialize();

        // [GIVEN] T contains an accepted TY2026 MISC document D and an unselected document U.

        // [WHEN] Both steps execute through the product orchestrator with simulated HTTP responses.
        VerifyActualTwoStep(2026, 'MISC');

        // [THEN] The expected result and preserved data are verified.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler,ConfirmYes')]
    procedure ActualTwoStep2025NecRetainsOriginalSemantics()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] The supported earlier-year NEC flow uses the same two-step orchestration without disclosures.
        Initialize();

        // [GIVEN] T contains an accepted TY2025 NEC document D and an unselected document U.

        // [WHEN] Both steps execute through the product orchestrator with simulated HTTP responses.
        VerifyActualTwoStep(2025, 'NEC');

        // [THEN] The expected result and preserved data are verified.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler')]
    procedure ActualWholeReplacementReferencesRejectedReceipt()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Replacing a wholly rejected transmission has only a manifest-level reference.
        Initialize();

        // [GIVEN] T contains rejected and original-receipt submission references for TY2026.

        // [WHEN] Rejected NEC and MISC submissions are replaced together.
        VerifyActualReplacement(2026, "Transmission Status IRIS"::Rejected, false);

        // [THEN] The expected result and preserved data are verified.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler')]
    procedure ActualPartialReplacementExcludesAcceptedSubmission()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A partial replacement includes only the rejected submission and its saved disclosures.
        Initialize();

        // [GIVEN] T contains rejected and original-receipt submission references for TY2026.

        // [WHEN] Only the rejected submission is replaced.
        VerifyActualReplacement(2026, "Transmission Status IRIS"::"Partially Accepted", true);

        // [THEN] The expected result and preserved data are verified.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler')]
    procedure ActualReplacementAfterAcceptedCorrectionExcludesAcceptedSubmission()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] An accepted correction must not cause another accepted submission to be resent by replacement.
        Initialize();

        // [GIVEN] T contains rejected and original-receipt submission references for TY2026.

        // [WHEN] A previously rejected submission remains after another submission was corrected and accepted.
        VerifyActualReplacement(2026, "Transmission Status IRIS"::Accepted, true);

        // [THEN] The expected result and preserved data are verified.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler')]
    procedure Actual2025WholeReplacementPreservesReferences()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Actual2025 Whole Replacement Preserves References.
        Initialize();

        // [GIVEN] T contains rejected and original-receipt submission references for TY2025.

        // [WHEN] The requested operation is executed through its existing entry point.
        VerifyActualReplacement(2025, "Transmission Status IRIS"::Rejected, false);

        // [THEN] The expected result and preserved data are verified.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler')]
    procedure Actual2025PartialReplacementExcludesAcceptedSubmission()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Actual2025 Partial Replacement Excludes Accepted Submission.
        Initialize();

        // [GIVEN] T contains rejected and original-receipt submission references for TY2025.

        // [WHEN] The requested operation is executed through its existing entry point.
        VerifyActualReplacement(2025, "Transmission Status IRIS"::"Partially Accepted", true);

        // [THEN] The expected result and preserved data are verified.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler')]
    procedure Actual2026NecManualCorrectionPreservesUnselectedSource()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Actual2026 Nec Manual Correction Preserves Unselected Source.
        Initialize();

        // [GIVEN] T contains selected TY2026 NEC document D and unselected document U.

        // [WHEN] The requested operation is executed through its existing entry point.
        VerifyActualNonzeroCorrection(2026, 'NEC');

        // [THEN] The expected result and preserved data are verified.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler')]
    procedure Actual2026MiscManualCorrectionPreservesUnselectedSource()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Actual2026 Misc Manual Correction Preserves Unselected Source.
        Initialize();

        // [GIVEN] T contains selected TY2026 MISC document D and unselected document U.

        // [WHEN] The requested operation is executed through its existing entry point.
        VerifyActualNonzeroCorrection(2026, 'MISC');

        // [THEN] The expected result and preserved data are verified.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler')]
    procedure Actual2025NecManualCorrectionPreservesUnselectedSource()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Actual2025 Nec Manual Correction Preserves Unselected Source.
        Initialize();

        // [GIVEN] T contains selected TY2025 NEC document D and unselected document U.

        // [WHEN] The requested operation is executed through its existing entry point.
        VerifyActualNonzeroCorrection(2025, 'NEC');

        // [THEN] The expected result and preserved data are verified.
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
        // [SCENARIO 653992] Actual History Downloads Selected Attempt Bytes Without Regeneration.
        Initialize();

        // [GIVEN] T contains a TY2026 NEC document D.
        CreateLifecycleTransmission(Transmission, IRS1099FormDocHeader, 2026, 'NEC');
        InitializeOfflineTransport(Transmission);

        // [WHEN] The requested operation is executed through its existing entry point.
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

        // [THEN] The expected result and preserved data are verified.
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
        // [SCENARIO 653992] Actual Record Error Acknowledgment Retains Supplemental Source.
        Initialize();

        // [GIVEN] T contains a TY2026 NEC document D with saved disclosures.
        CreateLifecycleTransmission(Transmission, IRS1099FormDocHeader, 2026, 'NEC');
        InitializeOfflineTransport(Transmission);
        OfflineStatus := 'Accepted with Errors';
        OfflineSubmissionStatuses.Add('1', OfflineStatus);
        OfflineRecordError := true;

        // [WHEN] The requested operation is executed through its existing entry point.
        LibraryIRS1099IRIS.SendOriginal(Transmission);

        // [THEN] The expected result and preserved data are verified.
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
        // [SCENARIO 653992] Production-origin history is diagnostic only when queried from a sandbox.
        Initialize();

        // [GIVEN] An actual orchestrated production-environment attempt using only intercepted synthetic endpoints.
        CreateLifecycleTransmission(Transmission, IRS1099FormDocHeader, 2026, 'NEC');
        InitializeOfflineTransport(Transmission);
        EnvironmentInfoTestLibrary.SetTestabilitySandbox(false);
        LibraryIRS1099IRIS.SendOriginal(Transmission);
        FindLastAttempt(Transmission, TransmissionLog);
        VerifyAttemptContext(TransmissionLog, 'P', 'Production');
        StoredPayload := ReadAttemptContentBytes(TransmissionLog, 20);
        StoredResponse := ReadAttemptContentBytes(TransmissionLog, 30);

        // [WHEN] Current schema configuration becomes unavailable and status is requested in a sandbox by receipt and UTID.
        EnvironmentInfoTestLibrary.SetTestabilitySandbox(true);
        SetPeriodSchema('2026', "XML Schema Version IRIS"::" ");
        OfflineStatus := 'Not Found';
        LibraryIRS1099IRIS.RequestStatus(TransmissionLog."Receipt ID", TransmissionLog."Unique Transmission ID", StatusText);
        Assert.AreEqual('Not Found', StatusText, 'A not-found response does not trigger a production retry.');
        LibraryIRS1099IRIS.RequestStatus('', TransmissionLog."Unique Transmission ID", StatusText);

        // [THEN] All probes and requests use only the current sandbox slot; historical payload bytes and source remain unchanged.
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
        // [SCENARIO 653992] Receipt, processing, rejection, partial acceptance and final acceptance are distinct states.
        Initialize();

        // [GIVEN] HTTP receipt with a nonterminal acknowledgment.
        CreateLifecycleTransmission(Transmission, IRS1099FormDocHeader, 2026, 'NEC');
        InitializeOfflineTransport(Transmission);
        OfflineStatus := 'Processing';
        OfflineSubmissionStatuses.Add('1', 'Processing');
        LibraryIRS1099IRIS.SendOriginal(Transmission);
        VerifyLifecycleStatus(Transmission, IRS1099FormDocHeader, "Transmission Status IRIS"::Processing, "IRS 1099 Form Doc. Status"::"In Progress");
        TransmissionPage.OpenEdit();
        TransmissionPage.GoToRecord(Transmission);

        // [WHEN] The real Request Status action processes each simulated acknowledgment.
        VerifyStatusAction(TransmissionPage, Transmission, IRS1099FormDocHeader, 'Rejected', "Transmission Status IRIS"::Rejected, "IRS 1099 Form Doc. Status"::"In Progress");
        VerifyStatusAction(TransmissionPage, Transmission, IRS1099FormDocHeader, 'Partially Accepted', "Transmission Status IRIS"::"Partially Accepted", "IRS 1099 Form Doc. Status"::"In Progress");
        VerifyStatusAction(TransmissionPage, Transmission, IRS1099FormDocHeader, 'Accepted with Errors', "Transmission Status IRIS"::"Accepted with Errors", "IRS 1099 Form Doc. Status"::"In Progress");
        VerifyStatusAction(TransmissionPage, Transmission, IRS1099FormDocHeader, 'Accepted', "Transmission Status IRIS"::Accepted, "IRS 1099 Form Doc. Status"::Submitted);

        // [THEN] Status polling never submits a new payload or destroys saved disclosures.
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
        // [SCENARIO 653992] Pre-receipt validation preserves UTID history and permits explicit receipt assignment without resend.
        Initialize();

        // [GIVEN] The actual sender receives a simulated pre-receipt schema failure.
        CreateLifecycleTransmission(Transmission, IRS1099FormDocHeader, 2026, 'NEC');
        InitializeOfflineTransport(Transmission);
        OfflinePreReceiptError := true;
        OfflineStatus := 'Rejected';
        LibraryIRS1099IRIS.SendOriginal(Transmission);
        FindLastAttempt(Transmission, TransmissionLog);
        StoredPayload := ReadAttemptContent(TransmissionLog, 20);

        // [THEN] HTTP receipt is not accepted as a final document or transmission status.
        Assert.AreEqual('', Transmission."Receipt ID", 'Pre-receipt failure cannot assign a usable receipt.');
        Assert.AreEqual("Transmission Status IRIS"::None, Transmission.Status, 'Pre-receipt failure is not ordinary rejection.');
        ErrorInformation.SetRange("Transmission Document ID", Transmission."Document ID");
        ErrorInformation.SetRange("Error Code", 'XML Schema Validation Error');
        Assert.RecordIsNotEmpty(ErrorInformation);

        // [WHEN] Status by UTID and explicit manual receipt assignment are used through the real page.
        TransmissionPage.OpenEdit();
        TransmissionPage.GoToRecord(Transmission);
        TransmissionPage.RequestTransmissionStatusByUTID.Invoke();
        OfflinePreReceiptError := false;
        OfflineStatus := 'Processing';
        TransmissionPage.AssignReceiptIDManually.Invoke();
        TransmissionPage.RequestTransmissionStatusByRID.Invoke();

        // [THEN] Requests retain their identity and source bytes, without blind resubmission.
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
        // [SCENARIO 653992] An HTTP failure cannot be confused with the previous accepted submission.
        Initialize();

        // [GIVEN] D was accepted before its selected zero-correction attempt.

        // [WHEN] A selected zero correction receives a simulated service-unavailable response.
        VerifyUnacceptedZeroCorrection(503, 'Accepted');

        // [THEN] The expected result and preserved data are verified.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OfflineHttpHandler')]
    procedure ProcessingZeroCorrectionCompletesOnlyAfterAcceptedPoll()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Processing cannot complete a zero correction; a later accepted acknowledgment completes it once.
        Initialize();

        // [GIVEN] D was accepted before its selected zero-correction attempt.

        // [WHEN] The selected correction receives Processing, then actual Request Status receives acceptance.
        VerifyUnacceptedZeroCorrection(200, 'Processing');

        // [THEN] The expected result and preserved data are verified.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure NormalOnPremStillRejectsAllThreeSendOperations()
    var
        Transmission: Record "Transmission IRIS";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Ordinary OnPrem guards remain ahead of authentication and transport.
        Initialize();

        // [GIVEN] The current environment is ordinary OnPrem, not simulated SaaS.

        // [WHEN] Every supported send operation is attempted without simulating SaaS.
        asserterror LibraryIRS1099IRIS.SendOriginal(Transmission);

        // [THEN] The released SaaS-only error remains for all three paths.
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

    local procedure Initialize()
    var
        MockKeyVaultClientIRIS: Codeunit "Mock Key Vault Client IRIS";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"IRS 1099 IRIS Tests");
        LibraryVariableStorage.Clear();
        Clear(LibraryFileMgtHandler);
        LibraryIRS1099IRIS.RestoreOfflineAccessToken();
        Clear(OfflineRequestPaths);
        Clear(OfflineSubmissionStatuses);
        Clear(OfflinePayload);
        Clear(OfflinePreReceiptError);
        Clear(OfflineRecordError);
        OfflineSubmitHttpStatus := 200;
        AzureKeyVaultTestLibrary.ClearSecrets();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        EnvironmentInfoTestLibrary.SetTestabilitySandbox(false);

        LibrarySetupStorage.Restore();
        LibraryIRS1099IRIS.RestoreIRISUserID();
        LibraryIRS1099IRIS.DeleteAllTransmissions();
        LibraryIRS1099Document.DeleteFormDocuments();
        MockKeyVaultClientIRIS.SetDefaultValues();
        MockKeyVaultClientIRIS.SetSoftwareId(CopyStr(Format(Date2DMY(WorkDate(), 3)), 3, 2) + 'TEST0001');
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"IRS 1099 IRIS Tests");

        LibraryIRS1099IRIS.InitializeCompanyInformation();
        LibraryIRS1099IRIS.InitializeIRSFormsSetup();
        LibraryIRS1099IRIS.SaveIRISUserID();
        LibraryIRS1099IRIS.InitializeIRISUserID();
        InitializeReportingPeriodAndForms(Date2DMY(WorkDate(), 3));

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

    local procedure FindLastAttempt(Transmission: Record "Transmission IRIS"; var TransmissionLog: Record "Transmission Log IRIS")
    begin
        TransmissionLog.Reset();
        TransmissionLog.SetRange("Transmission Document ID", Transmission."Document ID");
        Assert.IsTrue(TransmissionLog.FindLast(), 'An actual orchestrated attempt must be logged.');
    end;

    local procedure FinishOfflineTransport()
    begin
        LibraryIRS1099IRIS.RestoreOfflineAccessToken();
        LibraryIRS1099IRIS.RestoreIRISUserID();
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

    local procedure ResetStandardProvider()
    begin
        AzureKeyVaultTestLibrary.ClearSecrets();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        EnvironmentInfoTestLibrary.SetTestabilitySandbox(false);
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
        Assert.IsTrue(LibraryVariableStorage.DequeueText().Contains('opened or/and abandoned'), 'The existing document-selection warning must run before preflight.');
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
        TransmissionPage: TestPage "Transmission IRIS";
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
            TransmissionPage.OpenEdit();
            TransmissionPage.GoToRecord(Transmission);
            TransmissionPage.RequestTransmissionStatusByRID.Invoke();
            IRS1099FormDocHeader.Get(IRS1099FormDocHeader.ID);
            Assert.AreEqual(IRS1099FormDocHeader.Status::Abandoned, IRS1099FormDocHeader.Status, 'A later terminal accepted acknowledgment completes the pending zero correction.');
            Assert.IsTrue(IRS1099FormDocHeader."IRIS Corrected to Zeros", 'The attempt history retains its zero mode for later acceptance.');
            Assert.IsFalse(IRS1099FormDocHeader."IRIS Needs Correction", 'Accepted correction is no longer pending.');
            VerifyLifecycleSource(IRS1099FormDocHeader, 2026);
            TransmissionPage.Close();
        end;
        FinishOfflineTransport();
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
        Response.HttpStatusCode := 503;
        Response.Content.WriteFrom('SIMULATED: unexpected request blocked');
        case Request.Path of
            'https://test.example/submit', 'https://production.example/submit':
                begin
                    OfflineResponse := '<IntakeA2AResponse><receiptId>' + OfflineReceiptID + '</receiptId></IntakeA2AResponse>';
                    Response.Content.WriteFrom(OfflineResponse);
                    Response.HttpStatusCode := OfflineSubmitHttpStatus;
                end;
            'https://test.example/status', 'https://production.example/status':
                begin
                    CaptureLatestOfflinePayload();
                    OfflineAcknowledgment := CreateOfflineAcknowledgment();
                    Response.Content.WriteFrom(OfflineAcknowledgment);
                    Response.HttpStatusCode := 200;
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
}
