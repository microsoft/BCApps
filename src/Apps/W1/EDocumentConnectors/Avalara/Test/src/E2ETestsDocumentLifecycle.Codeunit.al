// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.NoSeries;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Setup;
using System.Utilities;

codeunit 133624 "E2E Tests - Document Lifecycle"
{
    Subtype = Test;
    TestHttpRequestPolicy = AllowOutboundFromHandler;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    var
        Customer: Record Customer;
        EDocumentService: Record "E-Document Service";
        Assert: Codeunit Assert;
        LibraryEDocument: Codeunit "Library - E-Document";
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('HttpSubmitHandler')]
    procedure TestServiceStatusLog_CreatesLogEntries()
    var
        EDocument: Record "E-Document";
        EDocumentServiceStatus: Record "E-Document Service Status";
    begin
        // [SCENARIO] Service status changes create log entries

        // [GIVEN] Configured E-Document service
        Initialize();

        // [WHEN] Processing a document through various states
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);

        // [THEN] Service status log entries should be created
        EDocumentServiceStatus.SetRange("E-Document Entry No", EDocument."Entry No");
        Assert.RecordIsNotEmpty(EDocumentServiceStatus);
    end;

    local procedure Initialize()
    var
        CompanyInformation: Record "Company Information";
        ConnectionSetup: Record "Connection Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
        AvalaraAuth: Codeunit Authenticator;
        KeyGuid: Guid;
    begin
        CompanyInformation.Get();
        if CompanyInformation.Name = '' then begin
            CompanyInformation.Name := 'Test Company';
            CompanyInformation.Modify();
        end;

        // Ensure LCY Code is set
        GeneralLedgerSetup.Get();
        if GeneralLedgerSetup."LCY Code" = '' then begin
            GeneralLedgerSetup."LCY Code" := 'GBP';
            GeneralLedgerSetup.Modify();
        end;

        // Disable VAT Reporting Date to avoid VAT Period requirement
        if GeneralLedgerSetup."VAT Reporting Date Usage" <> Enum::"VAT Reporting Date Usage"::Disabled then begin
            GeneralLedgerSetup."VAT Reporting Date Usage" := Enum::"VAT Reporting Date Usage"::Disabled;
            GeneralLedgerSetup.Modify();
        end;

        // Ensure Sales & Receivables Setup has Invoice Nos.
        EnsureSalesSetup();

        // Verify Customer still exists (may have been rolled back between tests)
        if IsInitialized then
            if not Customer.Get(Customer."No.") then
                IsInitialized := false;

        if IsInitialized then
            exit;

        EnsureVATBusinessPostingGroup();
        LibraryEDocument.SetupStandardVAT();
        LibraryEDocument.SetupStandardSalesScenario(Customer, EDocumentService, Enum::"E-Document Format"::"PEPPOL BIS 3.0", Enum::"Service Integration"::Avalara);
        EDocumentService."Avalara Mandate" := 'GB-TEST';
        EDocumentService.Modify();

        if not ConnectionSetup.Get() then begin
            AvalaraAuth.CreateConnectionSetupRecord();
            ConnectionSetup.Get();
        end;

        AvalaraAuth.SetClientId(KeyGuid, SecretText.SecretStrSubstNo('mock-client-id'));
        ConnectionSetup."Client Id - Key" := KeyGuid;
        AvalaraAuth.SetClientSecret(KeyGuid, SecretText.SecretStrSubstNo('mock-client-secret'));
        ConnectionSetup."Client Secret - Key" := KeyGuid;
        ConnectionSetup."Company Id" := 'test-company-id';
        ConnectionSetup.Modify(true);

        CreateActivationMandate();

        IsInitialized := true;
    end;

    local procedure CreateActivationMandate()
    var
        ActivationMandate: Record "Activation Mandate";
    begin
        ActivationMandate.Init();
        ActivationMandate."Activation ID" := CreateGuid();
        ActivationMandate."Country Mandate" := 'GB-TEST';
        ActivationMandate."Country Code" := 'GB';
        ActivationMandate."Mandate Type" := '';
        ActivationMandate."Company Id" := 'test-company-id';
        ActivationMandate.Activated := true;
        ActivationMandate.Blocked := false;
        if not ActivationMandate.Insert() then
            ActivationMandate.Modify();
    end;

    [ModalPageHandler]
    procedure EDocServicesPageHandler(var EDocServicesPage: TestPage "E-Document Services")
    begin
        EDocServicesPage.Filter.SetFilter(Code, EDocumentService.Code);
        EDocServicesPage.OK().Invoke();
    end;

    [HttpClientHandler]
    internal procedure HttpSubmitHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        Regex: Codeunit Regex;
        ConnectTokenFileTok: Label 'ConnectToken.txt', Locked = true;
        GetResponseCompleteFileTok: Label 'GetResponseComplete.txt', Locked = true;
        GetResponseErrorFileTok: Label 'GetResponseError.txt', Locked = true;
        GetResponsePendingFileTok: Label 'GetResponsePending.txt', Locked = true;
        SubmitDocumentFileTok: Label 'SubmitDocument.txt', Locked = true;
    begin
        case true of
            Regex.IsMatch(Request.Path, 'https?://.+/connect/token'):
                LoadResourceIntoHttpResponse(ConnectTokenFileTok, Response);

            Regex.IsMatch(Request.Path, 'https?://.+/einvoicing/documents/.+/status'):
                case DocumentStatus of
                    DocumentStatus::Completed:
                        LoadResourceIntoHttpResponse(GetResponseCompleteFileTok, Response);
                    DocumentStatus::Pending:
                        LoadResourceIntoHttpResponse(GetResponsePendingFileTok, Response);
                    DocumentStatus::Error:
                        LoadResourceIntoHttpResponse(GetResponseErrorFileTok, Response);
                end;

            Regex.IsMatch(Request.Path, 'https?://.+/einvoicing/documents'):
                LoadResourceIntoHttpResponse(SubmitDocumentFileTok, Response);
        end;
        exit(true);
    end;

    local procedure LoadResourceIntoHttpResponse(ResourceText: Text; var Response: TestHttpResponseMessage)
    begin
        Response.Content.WriteFrom(NavApp.GetResourceAsText(ResourceText, TextEncoding::UTF8));
        Response.HttpStatusCode := 200;
    end;

    local procedure EnsureSalesSetup()
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        if not SalesSetup.Get() then
            SalesSetup.Insert(true);
        if SalesSetup."Invoice Nos." = '' then begin
            SalesSetup."Invoice Nos." := CreateTestNoSeries('SINV', 'SI00001', 'SI99999');
            SalesSetup.Modify(true);
        end;
        if SalesSetup."Posted Invoice Nos." = '' then begin
            SalesSetup."Posted Invoice Nos." := CreateTestNoSeries('PSINV', 'PSI0001', 'PSI9999');
            SalesSetup.Modify(true);
        end;
    end;

    local procedure CreateTestNoSeries(SeriesCode: Code[20]; StartNo: Code[20]; EndNo: Code[20]): Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        if NoSeries.Get(SeriesCode) then
            exit(SeriesCode);

        NoSeries.Init();
        NoSeries.Code := SeriesCode;
        NoSeries.Description := SeriesCode;
        NoSeries."Default Nos." := true;
        NoSeries."Manual Nos." := true;
        NoSeries.Insert();

        NoSeriesLine.Init();
        NoSeriesLine."Series Code" := SeriesCode;
        NoSeriesLine."Line No." := 10000;
        NoSeriesLine."Starting No." := StartNo;
        NoSeriesLine."Ending No." := EndNo;
        NoSeriesLine."Increment-by No." := 1;
        NoSeriesLine.Insert();

        exit(SeriesCode);
    end;

    local procedure EnsureVATBusinessPostingGroup()
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        if not VATBusinessPostingGroup.IsEmpty() then
            exit;

        VATBusinessPostingGroup.Init();
        VATBusinessPostingGroup.Code := 'DOMESTIC';
        VATBusinessPostingGroup.Description := 'Domestic';
        VATBusinessPostingGroup.Insert(false);

        if VATProductPostingGroup.IsEmpty() then begin
            VATProductPostingGroup.Init();
            VATProductPostingGroup.Code := 'STANDARD';
            VATProductPostingGroup.Description := 'Standard';
            VATProductPostingGroup.Insert(false);
        end else
            VATProductPostingGroup.FindFirst();

        if not VATPostingSetup.Get('DOMESTIC', VATProductPostingGroup.Code) then begin
            VATPostingSetup.Init();
            VATPostingSetup."VAT Bus. Posting Group" := 'DOMESTIC';
            VATPostingSetup."VAT Prod. Posting Group" := VATProductPostingGroup.Code;
            VATPostingSetup."VAT %" := 0;
            VATPostingSetup.Insert(false);
        end;
    end;

    var
        DocumentStatus: Option Completed,Pending,Error;
}
