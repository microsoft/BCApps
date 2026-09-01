// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Reporting;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Service.Document;
using Microsoft.Service.Setup;
using Microsoft.Service.Test;
using System.IO;
using System.TestLibraries.Utilities;

codeunit 139519 "E-Doc. Format Tests"
{
    Subtype = Test;
    TestType = IntegrationTest;

    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        EDocumentService: Record "E-Document Service";
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryEDoc: Codeunit "Library - E-Document";
        EDocImplState: Codeunit "E-Doc. Impl. State";
        LibraryLowerPermission: Codeunit "Library - Lower Permissions";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryService: Codeunit "Library - Service";
        LibraryERMGlobal: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        IsInitialized: Boolean;
        UnexpectedMessageErr: Label 'The actual message is: [%1], while the expected message is: [%2].', Comment = '%1 - Last error message, %2 - expected message';

    [Test]
    procedure CheckEDocumentServiceOrderErrorForYourReferance()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        ServiceHeader: Record "Service Header";
        ServiceMngmtSetup: Record "Service Mgt. Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        ExpectedErr: Text;
        WorkflowCode: Code[20];
    begin
        // [SCENARIO 608765] E-Documents: Check 'Your reference' not available in service documents in Belgian localisation
        Initialize(Enum::"Service Integration"::Mock);

        // [WHEN] Team member create invoice and update company information.
        UpdateCompanyInformation();
        LibraryLowerPermission.SetTeamMember();
        LibraryLowerPermission.SetOutsideO365Scope();
        LibraryLowerPermission.AddO365BusFull();
        this.LibraryEDoc.AddEDocServiceSupportedType(this.EDocumentService, Enum::"E-Document Type"::"Service Order");

        // [GIVEN] Setup E-Document service for sending shipment
        this.EDocumentService."Document Format" := Enum::"E-Document Format"::"PEPPOL BIS 3.0";
        this.EDocumentService.Modify(false);
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.RemoveBlankGenJournalTemplate();
        LibraryService.SetupServiceMgtNoSeries();
        ServiceMngmtSetup.Get();
        ServiceMngmtSetup.Validate("Link Service to Service Item", false);
        ServiceMngmtSetup.Modify();
        LibraryEDoc.CreateDocSendingProfile(DocumentSendingProfile);
        WorkflowCode := LibraryEDoc.CreateFlowWithServices(DocumentSendingProfile.Code, EDocumentService.Code, '');
        DocumentSendingProfile."Electronic Document" := DocumentSendingProfile."Electronic Document"::"Extended E-Document Service Flow";
        DocumentSendingProfile."Electronic Service Flow" := WorkflowCode;
        DocumentSendingProfile.Modify();
        Customer."Document Sending Profile" := DocumentSendingProfile.Code;
        Customer.Modify();
        EDocImplState.EnableOnCheckEvent();
        BindSubscription(EDocImplState);
        LibraryVariableStorage.AssertEmpty();
        EDocImplState.SetVariableStorage(LibraryVariableStorage);

        // [GIVEN] Create service order with empty Your Reference.
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Order);

        // [WHEN] Posting service order
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // [THEN] Check Your Reference error message
        ExpectedErr := 'Your Reference must have a value';
        Assert.IsTrue(StrPos(GetLastErrorText, ExpectedErr) > 0,
            StrSubstNo(UnexpectedMessageErr, GetLastErrorText, ExpectedErr));
    end;

    local procedure Initialize(Integration: Enum "Service Integration")
    var
        TransformationRule: Record "Transformation Rule";
        EDocument: Record "E-Document";
        EDocDataStorage: Record "E-Doc. Data Storage";
        EDocumentServiceStatus: Record "E-Document Service Status";
        EDocPurchLineFieldSetup: Record "ED Purchase Line Field Setup";
        PurchInvHeader: Record "Purch. Inv. Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryLowerPermission.SetOutsideO365Scope();
        LibraryVariableStorage.Clear();
        Clear(EDocImplState);
        EDocPurchLineFieldSetup.DeleteAll();

        PurchInvHeader.DeleteAll();
        VendorLedgerEntry.DeleteAll();

        if IsInitialized then
            exit;

        GLSetup.GetRecordOnce();
        GLSetup."VAT Reporting Date Usage" := GLSetup."VAT Reporting Date Usage"::Disabled;
        GLSetup.Modify();

        // Set a currency that can be used across all localizations
        Currency.Init();
        Currency.Validate(Code, 'XYZ');
        if Currency.Insert(true) then
            LibraryERM.CreateExchangeRate(Currency.Code, WorkDate(), 1.0, 1.0);

        EDocument.DeleteAll();
        EDocumentServiceStatus.DeleteAll();
        EDocumentService.DeleteAll();
        EDocDataStorage.DeleteAll();

        LibraryEDoc.SetupStandardVAT();
        LibraryEDoc.SetupStandardSalesScenario(Customer, EDocumentService, Enum::"E-Document Format"::Mock, Integration);
        LibraryEDoc.SetupStandardPurchaseScenario(Vendor, EDocumentService, Enum::"E-Document Format"::Mock, Integration);
        EDocumentService."Import Process" := "E-Document Import Process"::"Version 2.0";
        EDocumentService."Read into Draft Impl." := "E-Doc. Read into Draft"::PEPPOL;
        EDocumentService.Modify();

        TransformationRule.DeleteAll();
        TransformationRule.CreateDefaultTransformations();

        IsInitialized := true;
    end;

    local procedure CreateServiceDocument(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type")
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, Customer."No.");
        ServiceHeader.Validate("Your Reference", '');
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        CreateServiceLineWithItem(ServiceLine, ServiceHeader);
        VATPostingSetup.Get(ServiceLine."VAT Bus. Posting Group", ServiceLine."VAT Prod. Posting Group");
        VATPostingSetup.Validate("Tax Category", 'AA');
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateServiceLineWithItem(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header")
    var
        Item: Record Item;
    begin
        CreateItem(Item);
        Item.Validate("Last Direct Cost", LibraryRandom.RandInt(100));
        Item.Modify(true);

        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));
        ServiceLine.Modify(true);
    end;

    local procedure CreateItem(var Item: Record Item)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        FindVATPostingSetup(VATPostingSetup);
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);
    end;

    local procedure FindVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.SetRange("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
        LibraryERMGlobal.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
    end;

    local procedure UpdateCompanyInformation()
    var
        CompInfo: Record "Company Information";
        CountryRegion: Record "Country/Region";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        LibraryERMGlobal.UpdateCompanyAddress();
        LibraryERMGlobal.FindCountryRegion(CountryRegion);
        CompInfo.Get();
        CompInfo.Validate(Name, LibraryUtility.GenerateRandomText(MaxStrLen(CompInfo.Name)));
        CompInfo.Validate(IBAN, 'GB33BUKB20201555555555');
        CompInfo.Validate("SWIFT Code", 'MIDLGB22Z0K');
        CompInfo.Validate("Bank Branch No.", '1234');
        CompInfo.Validate("City", CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(CompInfo."City")), 1, MaxStrLen(CompInfo."Post Code")));
        CompInfo."Country/Region Code" := CountryRegion.Code;

        if CompInfo."VAT Registration No." = '' then
            CompInfo."VAT Registration No." := LibraryERMGlobal.GenerateVATRegistrationNo(CompInfo."Country/Region Code");

        CompInfo.Modify(true);
    end;
}
