// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Intrastat;

using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Document;
using System.IO;

codeunit 148700 "Intrastat Report Test DE"
{
    Subtype = Test;
    TestType = Uncategorized;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Intrastat DE]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryIntrastat: Codeunit "Library - Intrastat";
        IntrastatReportMgt: Codeunit IntrastatReportManagement;
        IsInitialized: Boolean;
        DataExchFileContentMissingErr: Label 'Data Exch File Content must not be empty';
        EnvelopeIdNotFoundErr: Label 'envelopeId element was not found in the exported XML.';
        DataExchNotFoundErr: Label 'No Data Exch. entry was found for the Intrastat DE export.';
        IDEVRequiresMaterialNoErr: Label 'To export without a Material No., set the Submission Channel to eSTATISTIK.CORE. The IDEV format requires the Material No. (Company No.) in the Company Information.';
        MaterialNoTok: Label 'MAT123', Locked = true;
        CurrencyIdentifierTok: Label 'EUR', Locked = true;
        IntrastatDEDataExchDefCodeTok: Label 'INTRA-2022-DE', Locked = true;

    [Test]
    [HandlerFunctions('IntrastatReportGetLinesPageHandler')]
    procedure ExportXMLWithCoreChannelSucceeds()
    var
        EnvelopeId: Text;
    begin
        // [FEATURE] [eSTATISTIK.CORE]
        // [SCENARIO] The DE Intrastat XML export succeeds for the eSTATISTIK.CORE channel without a Material No.
        // [GIVEN] Company Information without a "Company No." (Material No.) value
        Initialize();
        SetupCompanyInformationDE('');

        // [WHEN] Creating the Intrastat report XML file with the eSTATISTIK.CORE submission channel
        EnvelopeId := CreateReportAndExportXML("Intrastat Submission Channel DE"::eStatistikCore);

        // [THEN] The file is created and the envelopeId carries no material-number prefix (no leading '-')
        Assert.AreNotEqual('-', CopyStr(EnvelopeId, 1, 1), 'envelopeId must not start with a dash for eSTATISTIK.CORE.');
        Assert.IsTrue(EnvelopeId[1] in ['0' .. '9'], 'envelopeId must start with the statistics period for eSTATISTIK.CORE.');
    end;

    [Test]
    [HandlerFunctions('IntrastatReportGetLinesPageHandler')]
    procedure ExportXMLWithIDEVKeepsMaterialNoInId()
    var
        EnvelopeId: Text;
    begin
        // [FEATURE] [IDEV]
        // [SCENARIO] The IDEV channel prefixes the Material No. into the message ID (backward compatibility).
        // [GIVEN] Company Information with a "Company No." (Material No.) value
        Initialize();
        SetupCompanyInformationDE(MaterialNoTok);

        // [WHEN] Creating the Intrastat report XML file with the IDEV submission channel
        EnvelopeId := CreateReportAndExportXML("Intrastat Submission Channel DE"::IDEV);

        // [THEN] The envelopeId is prefixed with the material number followed by a dash
        Assert.AreEqual(MaterialNoTok + '-', CopyStr(EnvelopeId, 1, StrLen(MaterialNoTok) + 1), 'envelopeId must start with the material number prefix for IDEV.');
    end;

    [Test]
    [HandlerFunctions('IntrastatReportGetLinesPageHandler')]
    procedure ExportXMLWithIDEVAndNoMaterialNoFails()
    begin
        // [FEATURE] [IDEV]
        // [SCENARIO] The IDEV channel requires a Material No.; exporting without one fails and promotes eSTATISTIK.CORE.
        // [GIVEN] Company Information without a "Company No." (Material No.) value
        Initialize();
        SetupCompanyInformationDE('');

        // [WHEN] Creating the Intrastat report XML file with the IDEV submission channel
        asserterror CreateReportAndExportXML("Intrastat Submission Channel DE"::IDEV);

        // [THEN] The export fails with a message that promotes the eSTATISTIK.CORE channel
        Assert.ExpectedError(IDEVRequiresMaterialNoErr);
    end;

    [Test]
    [HandlerFunctions('IntrastatReportGetLinesPageHandler')]
    procedure ExportXMLWithCoreIgnoresMaterialNo()
    var
        EnvelopeId: Text;
    begin
        // [FEATURE] [eSTATISTIK.CORE]
        // [SCENARIO] The eSTATISTIK.CORE channel ignores a Material No. that is still set in Company Information.
        // [GIVEN] Company Information with a "Company No." (Material No.) value
        Initialize();
        SetupCompanyInformationDE(MaterialNoTok);

        // [WHEN] Creating the Intrastat report XML file with the eSTATISTIK.CORE submission channel
        EnvelopeId := CreateReportAndExportXML("Intrastat Submission Channel DE"::eStatistikCore);

        // [THEN] The envelopeId carries no material-number prefix (the Material No. is ignored)
        Assert.AreNotEqual('-', CopyStr(EnvelopeId, 1, 1), 'envelopeId must not start with a dash for eSTATISTIK.CORE.');
        Assert.IsTrue(EnvelopeId[1] in ['0' .. '9'], 'envelopeId must start with the statistics period when the Material No. is ignored.');
    end;

    [Test]
    procedure NewReportDefaultsSubmissionChannelFromSetup()
    var
        IntrastatReportSetup: Record "Intrastat Report Setup";
        IntrastatReportHeader: Record "Intrastat Report Header";
        InvoiceDate: Date;
        IntrastatReportNo: Code[20];
    begin
        // [FEATURE] [eSTATISTIK.CORE]
        // [SCENARIO] A new Intrastat report inherits the Default Submission Channel from the Intrastat Report Setup.
        // [GIVEN] The Default Submission Channel in the setup is eSTATISTIK.CORE
        Initialize();
        IntrastatReportSetup.Get();
        IntrastatReportSetup.Validate("Default Submission Channel", "Intrastat Submission Channel DE"::eStatistikCore);
        IntrastatReportSetup.Modify(true);

        // [WHEN] Creating a new Intrastat report
        InvoiceDate := CalcDate('<5Y>', WorkDate());
        LibraryIntrastat.CreateIntrastatReport(InvoiceDate, IntrastatReportNo);

        // [THEN] The new report's Submission Channel defaults to eSTATISTIK.CORE
        IntrastatReportHeader.Get(IntrastatReportNo);
        Assert.AreEqual(
            "Intrastat Submission Channel DE"::eStatistikCore, IntrastatReportHeader."Submission Channel",
            'New Intrastat report must inherit the Default Submission Channel from the setup.');
    end;

    [Test]
    procedure DataExchDefinitionGroupsDetailLinesByCountryOfOrigin()
    var
        DataExchFieldGrouping: Record "Data Exch. Field Grouping";
    begin
        // [SCENARIO 624364] The INTRA-2022-DE detail line definitions group by Country/Region of Origin (Field ID 24)
        // so detail lines with the same tariff but different origin country are not merged into one.
        Initialize();

        // [THEN] The receipt detail line definition groups by Country/Region of Origin (Field ID 24)
        DataExchFieldGrouping.SetRange("Data Exch. Def Code", IntrastatDEDataExchDefCodeTok);
        DataExchFieldGrouping.SetRange("Data Exch. Line Def Code", '7-RCPTDETAIL');
        DataExchFieldGrouping.SetRange("Field ID", 24);
        Assert.IsFalse(DataExchFieldGrouping.IsEmpty(), 'Receipt detail must group by Country/Region of Origin (Field ID 24).');

        // [THEN] The shipment detail line definition groups by Country/Region of Origin (Field ID 24)
        DataExchFieldGrouping.SetRange("Data Exch. Line Def Code", '8-SHPTDETAIL');
        Assert.IsFalse(DataExchFieldGrouping.IsEmpty(), 'Shipment detail must group by Country/Region of Origin (Field ID 24).');
    end;

    local procedure Initialize()
    var
        IntrastatReportSetup: Record "Intrastat Report Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Intrastat Report Test DE");

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Intrastat Report Test DE");

        LibraryIntrastat.UpdateIntrastatCodeInCountryRegion();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        // InitSetup triggers the Intrastat DE subscribers that create the
        // 'INTRA-2022-DE' data exchange definition and the DE checklist.
        IntrastatReportMgt.InitSetup(IntrastatReportSetup);
        LibraryIntrastat.SetIntrastatContact(
            "Intrastat Report Contact Type"::Contact, LibraryIntrastat.CreateIntrastatContact("Intrastat Report Contact Type"::Contact));

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Intrastat Report Test DE");
    end;

    local procedure SetupCompanyInformationDE(MaterialNo: Code[10])
    var
        CompanyInformation: Record "Company Information";
        CountryRegion: Record "Country/Region";
    begin
        CompanyInformation.Get();
        if CompanyInformation."Country/Region Code" = '' then begin
            CountryRegion.FindFirst();
            CompanyInformation."Country/Region Code" := CountryRegion.Code;
        end;
        if CompanyInformation.Address = '' then
            CompanyInformation.Address := 'Test Street 1';
        if CompanyInformation."Post Code" = '' then
            CompanyInformation."Post Code" := '10115';
        if CompanyInformation.City = '' then
            CompanyInformation.City := 'Berlin';
        CompanyInformation."Registration No." := 'DE123456789';
        CompanyInformation.Area := '99';
        CompanyInformation."Agency No." := '900';
        CompanyInformation."Company No." := MaterialNo;
        CompanyInformation.Modify();
    end;

    local procedure CreateReportAndExportXML(SubmissionChannel: Enum "Intrastat Submission Channel DE") EnvelopeId: Text
    var
        SalesLine: Record "Sales Line";
        IntrastatReportHeader: Record "Intrastat Report Header";
        InvoiceDate: Date;
        IntrastatReportNo: Code[20];
    begin
        InvoiceDate := CalcDate('<5Y>', WorkDate());
        LibraryIntrastat.CreateAndPostSalesOrder(SalesLine, InvoiceDate);

        LibraryIntrastat.CreateIntrastatReport(InvoiceDate, IntrastatReportNo);
        InvokeSuggestLines(IntrastatReportNo);

        IntrastatReportHeader.Get(IntrastatReportNo);
        IntrastatReportHeader.Validate("Currency Identifier", CurrencyIdentifierTok);
        IntrastatReportHeader.Validate("Submission Channel", SubmissionChannel);
        IntrastatReportHeader.Modify(true);
        Commit();

        IntrastatReportMgt.ExportWithDataExch(IntrastatReportHeader, 0);

        EnvelopeId := GetEnvelopeIdFromLastDataExch();
    end;

    local procedure InvokeSuggestLines(IntrastatReportNo: Code[20])
    var
        IntrastatReport: TestPage "Intrastat Report";
    begin
        IntrastatReport.OpenEdit();
        IntrastatReport.Filter.SetFilter("No.", IntrastatReportNo);
        IntrastatReport.GetEntries.Invoke();
        IntrastatReport.Close();
    end;

    local procedure GetEnvelopeIdFromLastDataExch(): Text
    var
        DataExch: Record "Data Exch.";
        InStr: InStream;
        Content: Text;
        Line: Text;
        StartTag: Text;
        EndTag: Text;
        StartPos: Integer;
        EndPos: Integer;
    begin
        DataExch.SetRange("Data Exch. Def Code", IntrastatDEDataExchDefCodeTok);
        Assert.IsTrue(DataExch.FindLast(), DataExchNotFoundErr);
        DataExch.CalcFields("File Content");
        Assert.IsTrue(DataExch."File Content".HasValue(), DataExchFileContentMissingErr);

        DataExch."File Content".CreateInStream(InStr, TextEncoding::UTF8);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            Content += Line;
        end;

        StartTag := '<envelopeId>';
        EndTag := '</envelopeId>';
        StartPos := StrPos(Content, StartTag);
        Assert.IsTrue(StartPos > 0, EnvelopeIdNotFoundErr);
        StartPos += StrLen(StartTag);
        EndPos := StrPos(CopyStr(Content, StartPos), EndTag);
        Assert.IsTrue(EndPos > 0, EnvelopeIdNotFoundErr);
        exit(CopyStr(Content, StartPos, EndPos - 1));
    end;

    [RequestPageHandler]
    procedure IntrastatReportGetLinesPageHandler(var RequestPage: TestRequestPage "Intrastat Report Get Lines")
    begin
        RequestPage.OK().Invoke();
    end;
}
