// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Test;

using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Foundation.Navigate;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Ledger;

codeunit 136128 "Service Navigate Form"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Navigate] [Service]
        IsInitialized := false;
    end;

    var
        TempDocumentEntry: Record "Document Entry" temporary;
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        PostingDate: Date;
        DocumentNo: Code[20];
        ExpectedConfirm: Label 'The Credit Memo doesn''t have a Corrected Invoice No. Do you want to continue?';

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Navigate Form");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Service Navigate Form");

        LibrarySales.SetCreditWarningsToNoWarnings();

        LibraryService.SetupServiceMgtNoSeries();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Service Navigate Form");
    end;

    [Test]
    [HandlerFunctions('NavigateFormHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoice()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number 128923 refer to Test Suite ID 166761.
        // This test case checks the Navigate functionality for Posted Service Invoice.

        // 1. Setup: Create Service Header, Service Item Line, Service Line, Customer and Item.
        Initialize();
        InitGlobalVariables();
        CreateServiceOrder(ServiceHeader);

        // 2. Exercise: Post the Service Order as Invoice and open Navigate form.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        ServiceInvoiceHeader.SetRange("Order No.", ServiceHeader."No.");
        ServiceInvoiceHeader.FindFirst();

        // Set global variable for form handler.
        PostingDate := ServiceInvoiceHeader."Posting Date";
        DocumentNo := ServiceInvoiceHeader."No.";

        ServiceInvoiceHeader.Navigate();

        // 3. Verify: Verify No of entries for all related tables.
        VerifyInvoiceAndCrMemo(ServiceInvoiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('NavigateFormHandler')]
    [Scope('OnPrem')]
    procedure ServiceShipment()
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number 128922 refer to Test Suite ID 166761.
        // This test case checks the Navigate functionality for Posted Service Shipment.

        // 1. Setup: Create Service Header, Service Item Line, Service Line, Customer and Item.
        Initialize();
        InitGlobalVariables();
        CreateServiceOrder(ServiceHeader);

        // 2. Exercise: Post the Service Order as Ship and open Navigate form.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        ServiceShipmentHeader.SetRange("Order No.", ServiceHeader."No.");
        ServiceShipmentHeader.FindFirst();

        // Set global variable for form handler.
        PostingDate := ServiceShipmentHeader."Posting Date";
        DocumentNo := ServiceShipmentHeader."No.";

        ServiceShipmentHeader.Navigate();

        // 3. Verify: Verify No of entries for all related tables.
        VerifyShipment(ServiceShipmentHeader."No.");
    end;

    [Test]
    [HandlerFunctions('NavigateFormHandler,InvoiceESConfirmHandler')]
    [Scope('OnPrem')]
    procedure ServiceCreditMemo()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number 128924 refer to Test Suite ID 166761.
        // This test case checks the Navigate functionality for posted Service Credit Memo.

        // 1. Setup: Create Service Header, Service Line, Customer and Item.
        Initialize();
        InitGlobalVariables();
        CreateServiceCreditMemo(ServiceHeader);

        // 2. Exercise: Post the Service Credit Memo and open Navigate form.
        ExecuteConfirmHandlerInvoiceES();
        LibraryService.PostServiceOrder(ServiceHeader, false, false, false);
        ServiceCrMemoHeader.SetRange("Pre-Assigned No.", ServiceHeader."No.");
        ServiceCrMemoHeader.FindFirst();

        // Set global variable for form handler.
        PostingDate := ServiceCrMemoHeader."Posting Date";
        DocumentNo := ServiceCrMemoHeader."No.";

        ServiceCrMemoHeader.Navigate();

        // 3. Verify: Verify No of entries for all related tables.
        VerifyInvoiceAndCrMemo(ServiceCrMemoHeader."No.");
    end;

    local procedure CreateServiceCreditMemo(var ServiceHeader: Record "Service Header")
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", Customer."No.");
        CreateServiceLine(ServiceHeader, 0);
    end;

    local procedure CreateServiceOrder(var ServiceHeader: Record "Service Header")
    var
        ServiceItemLine: Record "Service Item Line";
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        CreateServiceLine(ServiceHeader, ServiceItemLine."Line No.");
    end;

    local procedure CreateServiceLine(var ServiceHeader: Record "Service Header"; LineNo: Integer)
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
    begin
        CreateItem(Item);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(100));  // Using RANDOM value for Quantity.
        ServiceLine.Validate("Service Item Line No.", LineNo);
        ServiceLine.Modify(true);
    end;

    local procedure CreateItem(var Item: Record Item)
    var
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandInt(10));  // Using RANDOM value for Unit Price.
        Item.Modify(true);
    end;

    [Normal]
    local procedure ExecuteConfirmHandlerInvoiceES()
    begin
        if Confirm(StrSubstNo(ExpectedConfirm)) then;
    end;

    local procedure InitGlobalVariables()
    begin
        Clear(TempDocumentEntry);
        Clear(PostingDate);
        DocumentNo := '';
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure NavigateFormHandler(var Navigate: Page Navigate)
    begin
        Navigate.SetDoc(PostingDate, DocumentNo);
        Navigate.UpdateNavigateForm(false);
        Navigate.FindRecordsOnOpen();

        TempDocumentEntry.DeleteAll();
        Navigate.ReturnDocumentEntry(TempDocumentEntry);
    end;

    local procedure VerifyInvoiceAndCrMemo(DocumentNo2: Code[20])
    var
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        ValueEntry: Record "Value Entry";
        ServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo2);
        VerifyNavigateRecords(TempDocumentEntry, DATABASE::"G/L Entry", GLEntry.Count);

        VATEntry.SetRange("Document No.", DocumentNo2);
        VerifyNavigateRecords(TempDocumentEntry, DATABASE::"VAT Entry", VATEntry.Count);

        CustLedgerEntry.SetRange("Document No.", DocumentNo2);
        VerifyNavigateRecords(TempDocumentEntry, DATABASE::"Cust. Ledger Entry", CustLedgerEntry.Count);

        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo2);
        VerifyNavigateRecords(TempDocumentEntry, DATABASE::"Detailed Cust. Ledg. Entry", DetailedCustLedgEntry.Count);

        ValueEntry.SetRange("Document No.", DocumentNo2);
        VerifyNavigateRecords(TempDocumentEntry, DATABASE::"Value Entry", ValueEntry.Count);

        ServiceLedgerEntry.SetRange("Document No.", DocumentNo2);
        VerifyNavigateRecords(TempDocumentEntry, DATABASE::"Service Ledger Entry", ServiceLedgerEntry.Count);
    end;

    local procedure VerifyShipment(DocumentNo2: Code[20])
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ServiceLedgerEntry.SetRange("Document No.", DocumentNo2);
        VerifyNavigateRecords(TempDocumentEntry, DATABASE::"Service Ledger Entry", ServiceLedgerEntry.Count);

        ItemLedgerEntry.SetRange("Document No.", DocumentNo2);
        VerifyNavigateRecords(TempDocumentEntry, DATABASE::"Item Ledger Entry", ItemLedgerEntry.Count);
    end;

    local procedure VerifyNavigateRecords(var TempDocumentEntry2: Record "Document Entry" temporary; TableID: Integer; NoOfRecords: Integer)
    begin
        TempDocumentEntry2.SetRange("Table ID", TableID);
        TempDocumentEntry2.FindFirst();
        TempDocumentEntry2.TestField("No. of Records", NoOfRecords);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure InvoiceESConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := (Question = ExpectedConfirm);
    end;
}

