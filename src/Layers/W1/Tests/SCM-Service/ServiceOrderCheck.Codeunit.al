// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Test;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Setup;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Service.Ledger;
using Microsoft.Service.Loaner;
using Microsoft.Service.Maintenance;
using Microsoft.Service.Pricing;
using Microsoft.Service.Reports;

using System.TestLibraries.Utilities;

codeunit 136114 "Service Order Check"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Service]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryResource: Codeunit "Library - Resource";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryUtilityOnPrem: Codeunit "Library - Utility OnPrem";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        isInitialized: Boolean;
        ServiceOrderError: Label 'Service Order must not exist.';
        OrderNo: Code[20];
        InvoiceNo: Code[20];
        DocumentDimError: Label 'Dim Set ID on shipment: %1 is different from service Order: %2';
        CountError: Label '%1 %2 must exist.', Comment = '%1: Count of Lines;%2: Table Caption';
        PostingDateErr: Label 'Posting Date of Value Entry is incorrect';
        PostedShipmentDateTxt: Label 'Posted Shipment Date';
        VATDateMissingErr: Label 'VAT Date field must be filled for service order';
        ServiceLinesChangeMsg: Label 'You have changed %1 on the %2, but it has not been changed on the existing service lines.\You must update the existing service lines manually.';
        ServiceItemLineErr: Label 'Service Item Line must exist.';

    [Test]
    [Scope('OnPrem')]
    procedure CreationOfServiceOrder()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC1.1 - refer to TFS ID 21648
        // Check Order Creation.

        // 1. Setup
        Initialize();

        // 2. Exercise: Create Service Item, Service Order with Header and Service Item Line.
        CreateServiceOrder(ServiceHeader, ServiceItem, ServiceItemLine);

        // 3. Verify: Check that Service Order Exists.
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");

        // 3. Verify: VAT Date on Service Order
        Assert.AreNotEqual('', ServiceHeader."VAT Reporting Date", VATDateMissingErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateServiceItemWorksheet()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC1.2 - refer to TFS ID 21648
        // Check All fault code exist on Service Item Line after adding Service Line.

        // 1. Setup: Create Service Item, Service Order with Header and Service Item Line. Modify Service Item with Different Fault Code.
        Initialize();
        CreateServiceOrder(ServiceHeader, ServiceItem, ServiceItemLine);
        ModifyServiceItemLine(ServiceItemLine);

        // 2. Exercise: Create Service Line with Item.
        CreateServiceLineWithItem(ServiceLine, ServiceHeader, ServiceItem."No.");

        // 3. Verify: Check that different fault code exist after Creating Service Line with Item.
        ServiceLine.TestField("Fault Area Code", ServiceItemLine."Fault Area Code");
        ServiceLine.TestField("Fault Code", ServiceItemLine."Fault Code");
        ServiceLine.TestField("Symptom Code", ServiceItemLine."Symptom Code");
        ServiceLine.TestField("Fault Reason Code", ServiceItemLine."Fault Reason Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceItemWorksheetReport()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
        ServiceItemWorksheet: Report "Service Item Worksheet";
        FilePath: Text[1024];
    begin
        // Covers document number TC1.2 - refer to TFS ID 21648
        // Save Service Item Worksheet Report with Fault Code in XLSX> and XML Format and check data exist in Saved files.

        // 1. Setup: Create Service Item, Service Order with Header and Service Item Line. Modify Service Item with Different Fault Code.
        Initialize();
        CreateServiceOrder(ServiceHeader, ServiceItem, ServiceItemLine);
        ModifyServiceItemLine(ServiceItemLine);

        // 2. Exercise: Create Service Line with Item.
        CreateServiceLineWithItem(ServiceLine, ServiceHeader, ServiceItem."No.");

        // 3. Verify: Save ServiceItemWorksheet Report with different Fault Code in Service Tier with XLSX and C/Side with XML format.
        ServiceItemLine.SetRange("Document Type", ServiceItemLine."Document Type"::Order);
        ServiceItemLine.SetRange("Document No.", ServiceItemLine."Document No.");
        ServiceItemWorksheet.SetTableView(ServiceItemLine);
        FilePath := TemporaryPath + Format(ServiceItemLine."Document Type") + ServiceItemLine."Document No." + '.xlsx';
        ServiceItemWorksheet.SaveAsExcel(FilePath);

        // 4. Verify: Verify that Saved files have some data.
        LibraryUtilityOnPrem.CheckFileNotEmpty(FilePath);
    end;

    [Test]
    [HandlerFunctions('LoanerConfirmHandler')]
    [Scope('OnPrem')]
    procedure ServiceItemWithServiceLoaner()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        TempServiceItemLine: Record "Service Item Line" temporary;
        ServLoanerManagement: Codeunit ServLoanerManagement;
    begin
        // Covers document number TC1.3 - refer to TFS ID 21648
        // Loaner No. should be same after adding Service Line with Resource on Service Item Line.

        // 1. Setup: Create Service Item, Service Order with Header and three Service Item Line. Modify each Service Item Line with
        // Loaner No.
        Initialize();
        CreateServiceOrder(ServiceHeader, ServiceItem, ServiceItemLine);
        CreateServiceItemAndItemLine(ServiceItem, ServiceItemLine, ServiceHeader);
        CreateServiceItemAndItemLine(ServiceItem, ServiceItemLine, ServiceHeader);
        ModifyLoanerNoServiceItemLine(ServiceItemLine);
        SaveServiceItemLineInTempTable(TempServiceItemLine, ServiceItemLine);

        // 2. Exercise: Create three Service Line with Type Resource.
        CreateServiceLineWithResource(ServiceHeader, ServiceItem."No.");
        CreateServiceLineWithResource(ServiceHeader, ServiceItem."No.");
        CreateServiceLineWithResource(ServiceHeader, ServiceItem."No.");

        // 3. Verify: Check that Service Item Line has same Loaner No. after Creating Service Line with Resource.
        VerifyLoanerNoServiceItemLine(TempServiceItemLine);

        // 4. Cleanup: Receive Loaner from All the Service Item Line.
        ServiceItemLine.SetRange("Document Type", ServiceItemLine."Document Type"::Order);
        ServiceItemLine.SetRange("Document No.", ServiceItemLine."Document No.");
        ServiceItemLine.FindSet();
        repeat
            ServLoanerManagement.ReceiveLoaner(ServiceItemLine);
        until ServiceItemLine.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('LoanerConfirmHandler')]
    [Scope('OnPrem')]
    procedure ServiceReceivingLoaners()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC1.4 - refer to TFS ID 21648
        // Loaner No. should be blank after receiving loaner in Service Item Line.

        // 1. Setup: Create Service Item, Service Order with Header and Three Service Item Line. Modify Service Item Line with Loaner No.
        Initialize();
        CreateServiceOrder(ServiceHeader, ServiceItem, ServiceItemLine);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        ModifyLoanerNoServiceItemLine(ServiceItemLine);

        // 2. Exercise: Create three Service Line with Type Resource.
        CreateServiceLineWithResource(ServiceHeader, ServiceItem."No.");
        CreateServiceLineWithResource(ServiceHeader, ServiceItem."No.");
        CreateServiceLineWithResource(ServiceHeader, ServiceItem."No.");
        ReceiveLoanerOnServiceItemLine(ServiceItemLine);

        // 3. Verify: Check that "Loaner No." field becomes blank.
        VerifyBlankLoanerNo(ServiceItemLine);
    end;

    [Test]
    [HandlerFunctions('LoanerConfirmHandler')]
    [Scope('OnPrem')]
    procedure ServiceItemLog()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        Loaner: Record Loaner;
        ServLoanerManagement: Codeunit ServLoanerManagement;
    begin
        // Covers document number TC1.5 - refer to TFS ID 21648
        // Check Service Item Log Entry after Receive Loaner.

        // 1. Setup: Create Service Item, Service Order with Header and Service Item Line. Modify Service Item Line with Loaner No. and
        // create Service Line with Type Resource.
        Initialize();
        LibraryService.CreateLoaner(Loaner);
        CreateServiceOrder(ServiceHeader, ServiceItem, ServiceItemLine);
        ServiceItemLine.Validate("Loaner No.", Loaner."No.");
        ServiceItemLine.Modify(true);
        CreateServiceLineWithResource(ServiceHeader, ServiceItem."No.");

        // 2. Exercise: Receive Loaner on Service Item Line.
        ServiceItemLine.Get(ServiceItemLine."Document Type", ServiceItemLine."Document No.", ServiceItemLine."Line No.");
        ServLoanerManagement.ReceiveLoaner(ServiceItemLine);

        // 3. Verify: Check the Service Item Log entry after Receive Loaner.
        VerifyServiceItemLogEntry(ServiceItemLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceDeletionAfterPosting()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC1.6 - refer to TFS ID 21648
        // Service Order must not exist after ship and Invoice.

        // 1. Setup: Create Service Item, Service Order with Header and Service Item Line, Service Line with Type Resource.
        Initialize();
        CreateServiceOrder(ServiceHeader, ServiceItem, ServiceItemLine);
        CreateServiceLineWithResource(ServiceHeader, ServiceItem."No.");

        // 2. Exercise: Post Service Order as Ship and Invoice.
        ServiceItemLine.Get(ServiceItemLine."Document Type", ServiceItemLine."Document No.", ServiceItemLine."Line No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Check Service Order must not Exist after Post as Ship and Invoice.
        Assert.IsFalse(ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No."), ServiceOrderError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingServiceShipment()
    var
        ServiceLine: Record "Service Line";
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceShipmentHeader: Record "Service Shipment Header";
        ServiceDocumentLog: Record "Service Document Log";
        ServiceShipment: Report "Service - Shipment";
        FilePath: Text[1024];
    begin
        // Covers document number TC01115,TC01116,TC01117,TC01118,TC01119 and TC01120 - refer to TFS ID 21649
        // TC01115: Check that Created Service Order saved in XML and XLSX format with report Service Shipment.
        // TC01116: Check that Warranty Ledger Entry Created after Service Order Post as Ship.
        // TC01117: Check that Service Shipment Line Created after Service Order Post as Ship.
        // TC01118: Check Service Document Log Event after Service Order Post as Ship.
        // TC01119: Check Posted Document Dimensions is same after Service Order Post as Ship.
        // TC01120: Check Service Ledger entry and Warranty Ledger Entry for Posted Shipment.

        // 1. Setup: Create Service Item, Service Order with Header and Service Item Line, Service Line with Type Item.
        Initialize();
        CreateServiceOrder(ServiceHeader, ServiceItem, ServiceItemLine);
        CreateServiceLineWithItem(ServiceLine, ServiceHeader, ServiceItem."No.");

        // 2. Exercise: Post Service Order as Ship.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        ServiceShipmentHeader.SetRange("Order No.", ServiceHeader."No.");
        ServiceShipment.SetTableView(ServiceShipmentHeader);
        FilePath := TemporaryPath + Format(ServiceHeader."Document Type") + ServiceShipmentHeader."No." + '.xlsx';
        ServiceShipment.SaveAsExcel(FilePath);

        // 3. Verify: Check Service Ledger Entry, Warranty Ledger Entry, Service Shipment Line, Service Document Log Event, Document
        // Dimension for Posted Shipment and Save Service Shipment Report with XML and XLSX format also verify that Saved files have some data.
        LibraryUtilityOnPrem.CheckFileNotEmpty(FilePath);
        VerifyServiceLedgerEntry(ServiceLine);
        VerifyWarrantyLedgerEntry(ServiceLine);
        VerifyServiceShipmentLine(ServiceLine);
        VerifyServiceDocumentLogEvent(ServiceHeader."No.", ServiceDocumentLog."Document Type"::Order, 1);
        VerifyDocumentDimension(ServiceHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingServiceInvoice()
    var
        ServiceLine: Record "Service Line";
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceDocumentLog: Record "Service Document Log";
        ServiceInvoice: Report "Service - Invoice";
        FilePath: Text[1024];
    begin
        // Covers document number TC01123, TC01124 and TC01126 - refer to TFS ID 21650.
        // TC01123: Check that Created Service Invoice Header saved in XML and XLSX format with report Service Invoice.
        // TC01124: Check that Service Document Log Created after Service Order Post as Ship and Invoice.
        // TC01126: Check that G/L Entry, VAT Entry, Cust. Ledger Entry, Res. Ledger Entry and Service Ledger Entry created after
        // Posting Service Order as Ship and Invoice.

        // 1. Setup: Create Service Item, Service Order with Header, Service Item Line, Service Line with Type Resource and Update Partial Qty. to Ship on Service Line.
        Initialize();
        CreateServiceOrder(ServiceHeader, ServiceItem, ServiceItemLine);
        CreateServiceLineWithResource(ServiceHeader, ServiceItem."No.");
        UpdatePartialQtyToShip(ServiceHeader);

        // 2. Exercise: Post Service Order as Ship and Invoice, Save Service Invoice Report as XML and XLSX in local Temp folder.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        FindServiceInvoiceHeader(ServiceInvoiceHeader, ServiceHeader."No.");
        ServiceInvoice.SetTableView(ServiceInvoiceHeader);
        FilePath := TemporaryPath + Format(ServiceInvoiceHeader."No.") + ServiceInvoiceHeader."Order No." + '.xlsx';
        ServiceInvoice.SaveAsExcel(FilePath);

        // 3. Verify: Verify that Saved files have some data, Service Document log, G/L Entry, VAT Entry, Customer Ledger Entry, Resource Ledger Entry and Service Ledger Entry.
        GetServiceLines(ServiceLine, ServiceHeader."No.", ServiceHeader."Document Type");
        LibraryUtilityOnPrem.CheckFileNotEmpty(FilePath);
        VerifyServiceDocumentLogEvent(ServiceInvoiceHeader."No.", ServiceDocumentLog."Document Type"::"Posted Invoice", 9);
        VerifyGLEntry(ServiceInvoiceHeader);
        VerifyVATEntry(ServiceInvoiceHeader);
        VerifyCustomerLedgerEntry(ServiceInvoiceHeader);
        VerifyResourceLedgerEntry(ServiceInvoiceHeader);
        VerifyServiceLedgerEntry(ServiceLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemShipmentLineResourceError()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
    begin
        // Covers document number TC01123 - refer to TFS ID 21650.
        // Check that on Selection of Item Shipment Line with Type Resource on Posted Service Invoice application generates an error.

        // 1. Setup: Create Service Item, Service Order with Header, Service Item Line, Service Line with Type Resource.
        Initialize();
        CreateServiceOrder(ServiceHeader, ServiceItem, ServiceItemLine);
        CreateServiceLineWithResource(ServiceHeader, ServiceItem."No.");

        // 2. Exercise: Post Service Order as Ship and Invoice.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Verify error occurs "Type must be Item" on open Item Shipment Line of Type resource.
        VerifyShipmentLineError(ServiceHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceWarrantyShipAndInvoice()
    var
        ServiceLine: Record "Service Line";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceHeader: Record "Service Header";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // Covers document number TC001 refer to TFS ID 158079.
        // Test that Warranty Ledger Entry is correctly created on Posting of Service Order with Ship and Invoice Option.

        // 1. Setup: Create Service Item, Service Order - Service Header, Service Item Line and Service Line with Type Item.
        Initialize();
        CreateServiceOrder(ServiceHeader, ServiceItem, ServiceItemLine);
        CreateServiceLineWithItem(ServiceLine, ServiceHeader, ServiceItem."No.");

        // 2. Exercise: Post Service Order as Ship and Invoice.
        GetServiceLines(ServiceLine, ServiceHeader."No.", ServiceHeader."Document Type");
        CopyServiceLines(ServiceLine, TempServiceLine);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Check Warranty Ledger Entry is created correctly.
        VerifyWarrantyLedgerFullPost(TempServiceLine);
    end;

    [Test]
    [HandlerFunctions('FormHandlerGetShipment')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceGetShipment()
    var
        ServiceLine: Record "Service Line";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceHeader: Record "Service Header";
        ServiceGetShipment: Codeunit "Service-Get Shipment";
    begin
        // Covers document number TC001 refer to TFS ID 158079.
        // Test the Get Shipment Functionality on Service Invoice.

        // 1. Setup: Create Service Order. Create Service Line with Item.
        Initialize();
        CreateServiceOrder(ServiceHeader, ServiceItem, ServiceItemLine);
        CreateServiceLineWithItem(ServiceLine, ServiceHeader, ServiceItem."No.");

        // 2. Exercise: Post Service Order as Ship. Create Service Invoice. Perform Get Shipment Lines on Invoice.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        OrderNo := ServiceHeader."No.";

        Clear(ServiceHeader);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, ServiceLine."Customer No.");
        InvoiceNo := ServiceHeader."No.";

        Clear(ServiceLine);
        ServiceLine."Document Type" := ServiceHeader."Document Type";
        ServiceLine."Document No." := ServiceHeader."No.";
        ServiceGetShipment.Run(ServiceLine);

        // 3. Verify: Service Lines are correcly inserted into Invoice on Get Shipment Line.
        VerifyGetShipmentLines(OrderNo, ServiceHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderDiscounts()
    var
        Customer: Record Customer;
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
        ServiceCalcDisc: Codeunit "Service-Calc. Discount";
        ServiceItemNo: Code[20];
    begin
        // Covers document number TC001 refer to TFS ID 158079.
        // Test that Service Order Line Discount and Invoice Discounts are correctlty transfered to invoice on Posting of Service Order.

        // 1. Setup: Create Customer, Define Line Discount and Invoice Discount.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        CreateCustomerLineDiscount(Item, Customer."No.");
        CreateCustomerInvoiceDiscount(CustInvoiceDisc, Customer."No.", 0, 0);

        // 2. Exercise: Create Service Order, Calculate Invoice Discount. Post the Service Order as Ship and Invoice.
        ServiceItemNo := CreateServiceDocument(ServiceHeader, Customer."No.", Item."No.");
        UpdateServiceLine(ServiceLine, ServiceHeader."No.", ServiceItemNo, ServiceHeader."Posting Date");
        ServiceCalcDisc.Run(ServiceLine);

        GetServiceLines(ServiceLine, ServiceHeader."No.", ServiceHeader."Document Type");
        CopyServiceLines(ServiceLine, TempServiceLine);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Service Discounts are correctly transfered to Invoice.
        VerifyServiceInvoice(TempServiceLine);
    end;

    [Test]
    [HandlerFunctions('FormHandlerGetShipment')]
    [Scope('OnPrem')]
    procedure ServiceLineInvoiceWOItem()
    var
        ServiceLine: Record "Service Line";
    begin
        // Covers document number TC_PP_GSL_4_1, TC_PP_GSL_2_1 - refer to TFS ID 167960.
        // Test Service Lines on Service Invoice from Get Shipment after Post Service Line for Type Item fully and Other lines partly.

        ServiceInvoice(ServiceLine.Type::Item);
    end;

    [Test]
    [HandlerFunctions('FormHandlerGetShipment')]
    [Scope('OnPrem')]
    procedure ServiceLineInvoiceWOResource()
    var
        ServiceLine: Record "Service Line";
    begin
        // Covers document number TC_PP_GSL_4_2 - refer to TFS ID 167960.
        // Test Service Lines on Service Invoice from Get Shipment after Post Service Line for Type Resource fully and Other lines partly.

        ServiceInvoice(ServiceLine.Type::Resource);
    end;

    [Test]
    [HandlerFunctions('FormHandlerGetShipment')]
    [Scope('OnPrem')]
    procedure ServiceLineInvoiceWOCost()
    var
        ServiceLine: Record "Service Line";
    begin
        // Covers document number TC_PP_GSL_4_3 - refer to TFS ID 167960.
        // Test Service Lines on Service Invoice from Get Shipment after Post Service Line for Type Cost fully and Other lines partly.

        ServiceInvoice(ServiceLine.Type::Cost);
    end;

    [Test]
    [HandlerFunctions('FormHandlerGetShipment')]
    [Scope('OnPrem')]
    procedure ServiceLineInvoiceWOGLAccount()
    var
        ServiceLine: Record "Service Line";
    begin
        // Covers document number TC_PP_GSL_4_4, TC_PP_GSL_2_4 - refer to TFS ID 167960.
        // Test Service Lines on Service Invoice from Get Shipment after Post Service Line for Type G/L Account fully and Other lines partly.

        ServiceInvoice(ServiceLine.Type::"G/L Account");
    end;

    local procedure ServiceInvoice(Type: Enum "Service Line Type")
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceGetShipment: Codeunit "Service-Get Shipment";
        CustomerNo: Code[20];
    begin
        // 1. Setup: Create and Post Service Order with Service Line of Type Item, Resoure, Cost and G/L Account.
        Initialize();
        CreateServiceOrderWithLines(ServiceHeader);
        UpdateFullQtyToInvoice(ServiceHeader, Type);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        OrderNo := ServiceHeader."No.";  // Assign Global Variable for form handler.
        CustomerNo := ServiceHeader."Customer No.";

        // 2. Exercise: Create Service Invoice from Get Shipment Lines.
        Clear(ServiceHeader);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, CustomerNo);
        InvoiceNo := ServiceHeader."No.";  // Assign Global Variable for form handler.
        ServiceLine."Document Type" := ServiceHeader."Document Type";
        ServiceLine."Document No." := ServiceHeader."No.";
        ServiceGetShipment.Run(ServiceLine);

        // 3. Verify: Verify Service Lines on Created Service Invoice.
        VerifyServiceLineForInvoice(OrderNo, ServiceHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExtendedTextOnServiceInvoiceLine()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceTransferExtText: Codeunit "Service Transfer Ext. Text";
        Description: Text[50];
    begin
        // Check Extended Text on Service Invoice Line after posting Service Order with Extended Text on Service Line.

        // 1. Setup: Create Item, Extended Text for Item, Create Service Order and Insert Extended Text on Service Line.
        Initialize();
        LibraryInventory.CreateItem(Item);
        Description := CreateExtendedTextForItem(Item."No.");
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CreateCustomer());
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        CreateAndUpdateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.", ServiceItemLine."Line No.");
        ServiceTransferExtText.ServCheckIfAnyExtText(ServiceLine, true);
        ServiceTransferExtText.InsertServExtText(ServiceLine);

        // 2. Exercise.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Verify Extended Text on Service Invoice Line.
        VerifyExtendedText(ServiceHeader."No.", Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingDateOnUnpostedServiceLine()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        NewPostingDate: Date;
    begin
        // Check that Posting Date updates correctly on Service Line after updating it on Service Order.

        // 1. Setup.
        Initialize();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CreateCustomer());
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        CreateAndUpdateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, CreateItem(), ServiceItemLine."Line No.");

        // 2. Exercise: Update Posting Date on Service Order Header after creating Service Line.
        UpdatePostingDateOnServiceHeader(NewPostingDate, ServiceHeader);

        // 3. Verify: Verify that updated Posting Date reflected correctly on Service Line.
        ServiceLine.Get(ServiceHeader."Document Type", ServiceHeader."No.", ServiceLine."Line No.");
        ServiceLine.TestField("Posting Date", NewPostingDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingDateOnPostedServiceDocuments()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        NewPostingDate: Date;
        Counter: Integer;
    begin
        // Check that correct Posting Date is updated on Service Invoice Lines and on Service Shipment Lines after posting Service Order with updated Posting Date.

        // 1. Setup: Create Service Order with multiple Service Lines using Random.
        Initialize();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CreateCustomer());
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        for Counter := 1 to 1 + LibraryRandom.RandInt(5) do
            CreateAndUpdateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, CreateItem(), ServiceItemLine."Line No.");
        UpdatePostingDateOnServiceHeader(NewPostingDate, ServiceHeader);

        // 2. Exercise.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Verify Posting Date on Service Invoice and Service Shipment Lines after Posting Service Order as Ship and Invoice.
        VerifyPostingDateOnServiceInvoice(ServiceHeader."No.", NewPostingDate);
        VerifyPostingDateOnServiceShipment(ServiceHeader."No.", NewPostingDate);
    end;

    [Test]
    [HandlerFunctions('ServiceLinesPageHandler,StrMenuHandler')]
    [Scope('OnPrem')]
    procedure PostServiceLineForServiceOrder()
    var
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // Check that Service Order still exist after Posting Service Line for first Service Item Line.

        // 1. Setup: Create Service Order with Two Service Item Lines and One Service Line.
        Initialize();
        LibraryService.CreateServiceItem(ServiceItem, CreateCustomer());
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        CreateAndUpdateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, CreateItem(), ServiceItemLine."Line No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // 2. Exercise: Open Service Lines Page for first Service Line and Post Service Line using Page Handler.
        OpenServiceLinePage(ServiceHeader."No.");

        // 3. Verify: Verify that Service Order still exists after posting Service Line for first Service Item Line.
        ServiceHeader.Get(ServiceHeader."Document Type"::Order, ServiceHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlankLineForServiceOrder()
    var
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceShipmentLine: Record "Service Shipment Line";
        ServiceInvoiceLine: Record "Service Invoice Line";
        ServiceLineCount: Integer;
    begin
        // Check that text line on posted Service Documents exists after posting Service Order if it contains Type=Item and No=blank with some value on Description field.

        // 1. Setup: Create Service Order with 2 Service Lines, one contains Some Item and other is having Blank Item No. with Description.
        Initialize();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CreateCustomer());
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        CreateAndUpdateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, CreateItem(), ServiceItemLine."Line No.");
        CreateServiceLineWithDescriptionOnly(ServiceHeader, ServiceItemLine."Line No.");
        GetServiceLines(ServiceLine, ServiceHeader."No.", ServiceHeader."Document Type");
        ServiceLineCount := ServiceLine.Count();

        // 2. Exercise.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Verify that Blank Line included in Posted Service Documents.
        FindServiceShipmentLine(ServiceShipmentLine, ServiceHeader."No.");
        FindServiceInvoiceLine(ServiceInvoiceLine, ServiceHeader."No.");
        Assert.AreEqual(
          ServiceLineCount, ServiceShipmentLine.Count, StrSubstNo(CountError, ServiceLineCount, ServiceShipmentLine.TableCaption()));
        Assert.AreEqual(
          ServiceLineCount, ServiceInvoiceLine.Count, StrSubstNo(CountError, ServiceLineCount, ServiceInvoiceLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateServiceOrderInvoiceDiscountTwice()
    var
        CustInvoiceDisc: array[2] of Record "Cust. Invoice Disc.";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ChargeServiceLine: Record "Service Line";
        CustomerNo: Code[20];
        ServiceItemNo: Code[20];
    begin
        // [FEATURE] [Invoice Discount] [Service Charge]
        // [SCENARIO 216154] Service Order's service charge is not changed after running Calculate Invoice Discount twice
        Initialize();

        // [GIVEN] Sales & Receivables Setup "Calc. Inv. Discount" = FALSE
        LibrarySales.SetCalcInvDiscount(false);
        // [GIVEN] Customer with Invoice Discount setup:
        // [GIVEN] Line1: Minimum Amount = 0, Discount % = 10, Service Charge = 25
        // [GIVEN] Line1: Minimum Amount = 100, Discount % = 20, Service Charge = 50
        CustomerNo := LibrarySales.CreateCustomerNo();
        CreateCustomerInvoiceDiscount(CustInvoiceDisc[1], CustomerNo, 0, LibraryRandom.RandDecInRange(1000, 2000, 2));
        CreateCustomerInvoiceDiscount(
          CustInvoiceDisc[2], CustomerNo, LibraryRandom.RandDecInRange(1000, 2000, 2), LibraryRandom.RandDecInRange(1000, 2000, 2));

        // [GIVEN] Service Order with Item Service Line
        ServiceItemNo := CreateServiceDocument(ServiceHeader, CustomerNo, LibraryInventory.CreateItemNo());
        // [GIVEN] Service Line with Item, "Unit Price" = 99.99
        UpdateServiceLineCustomValues(
          ServiceLine, ServiceHeader."No.", ServiceItemNo, 1, CustInvoiceDisc[2]."Minimum Amount" - LibraryERM.GetAmountRoundingPrecision());

        // [GIVEN] Calculate Invoice Discount for Service Line
        VerifyServiceLineInvDiscAmount(ServiceLine, 0);
        RunServiceCalcDiscount(ServiceLine);

        // [GIVEN] Invoice Discount Amount = 10
        VerifyServiceLineInvDiscAmount(
          ServiceLine, Round(ServiceLine."Unit Price" * ServiceLine.Quantity * CustInvoiceDisc[1]."Discount %" / 100));

        // [GIVEN] Service Charge line has been created with Amount = 25 and "Inv. Discount Amount" = 0
        GetGLServiceLines(ChargeServiceLine, ServiceHeader."No.", ServiceHeader."Document Type");
        ChargeServiceLine.TestField(Amount, CustInvoiceDisc[1]."Service Charge");
        ChargeServiceLine.TestField("Inv. Discount Amount", 0);

        // [WHEN] Calculate Invoice Discount again for Service Line
        RunServiceCalcDiscount(ServiceLine);

        // [THEN] Invoice Discount Amount = 10
        VerifyServiceLineInvDiscAmount(
          ServiceLine, Round(ServiceLine."Unit Price" * ServiceLine.Quantity * CustInvoiceDisc[1]."Discount %" / 100));

        // [THEN] Service Charge remains Amount = 25 (and "Inv. Discount Amount" = 0) after recalculating Invoice Discount
        ChargeServiceLine.Find();
        ChargeServiceLine.TestField(Amount, CustInvoiceDisc[1]."Service Charge");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderInvoiceDiscountAfterPosting()
    var
        Customer: Record Customer;
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        Item: Record Item;
        TempServiceLine: Record "Service Line" temporary;
        ServiceItemNo: Code[20];
    begin
        // [FEATURE] [Invoice Discount] [Service Charge]
        // [SCENARIO] Invoice Discount after running Calculate Invoice Discount twice before Posting Service Order
        Initialize();

        // [GIVEN] Sales & Receivables Setup "Calc. Inv. Discount" = FALSE
        LibrarySales.SetCalcInvDiscount(false);
        // [GIVEN] Customer with Invoice Discount
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        CreateCustomerInvoiceDiscount(CustInvoiceDisc, Customer."No.", 0, LibraryRandom.RandDecInRange(1000, 2000, 2));
        // [GIVEN] Service Order
        ServiceItemNo := CreateServiceDocument(ServiceHeader, Customer."No.", Item."No.");
        UpdateServiceLine(ServiceLine, ServiceHeader."No.", ServiceItemNo, ServiceHeader."Posting Date");
        // [GIVEN] Calculate Invoice Discount for Service Line twice
        VerifyServiceLineInvDiscAmount(ServiceLine, 0);
        RunServiceCalcDiscount(ServiceLine);
        GetServiceLines(ServiceLine, ServiceHeader."No.", ServiceHeader."Document Type");
        RunServiceCalcDiscount(ServiceLine);
        CopyServiceLines(ServiceLine, TempServiceLine);

        // [WHEN] Post the Service Order
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Discount Entries are correct in GL Entry and Service Invoice
        VerifyGLEntries(TempServiceLine, CustInvoiceDisc, Customer."Customer Posting Group");
        VerifyServiceInvoice(TempServiceLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcServOrderInvDiscWithEmptyServiceItemAndWithoutServiceCharge()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Invoice Discount]
        // [SCENARIO 216154] Service Order's invoice discount is calculated after running Calculate Invoice Discount
        // [SCENARIO 216154] in case of Service Charge = 0, "Service Item No." = ""
        Initialize();

        // [GIVEN] Sales & Receivables Setup "Calc. Inv. Discount" = FALSE
        LibrarySales.SetCalcInvDiscount(false);
        // [GIVEN] Customer with Invoice Discount setup: Minimum Amount = 0, Discount % = 10, Service Charge = 0
        CustomerNo := LibrarySales.CreateCustomerNo();
        CreateCustomerInvoiceDiscount(CustInvoiceDisc, CustomerNo, 0, 0);

        // [GIVEN] Service Order with Item Service Line having "Service Item No." = "", "Item No." = "X"
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CustomerNo);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());

        // [GIVEN] Service Line for Item "X":  "Service Item No." = "", "No." = "X", "Unit Price" = 100
        UpdateServiceLine(ServiceLine, ServiceHeader."No.", '', WorkDate());

        // [WHEN] Calculate Invoice Discount for Service Line
        VerifyServiceLineInvDiscAmount(ServiceLine, 0);
        RunServiceCalcDiscount(ServiceLine);

        // [THEN] Invoice Discount Amount = 10
        VerifyServiceLineInvDiscAmount(
          ServiceLine, Round(ServiceLine."Unit Price" * ServiceLine.Quantity * CustInvoiceDisc."Discount %" / 100));
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler,MessgeHandler')]
    [Scope('OnPrem')]
    procedure ItemsOnServItemWorkSheetWithAscending()
    var
        SecondServiceLineItem: Record Item;
        FirstServiceLineItem: Record Item;
        ServiceLine: Record "Service Line";
    begin
        // Verify program does not messed up on Service Item Worksheet lines for Type Item using Ascending sorting while deleting the contract No on Service Item line.
        ServItemWorkSheetAfterDeletingContractNoOnServiceItemLine(ServiceLine.Type::Item,
          LibraryInventory.CreateItem(SecondServiceLineItem), LibraryInventory.CreateItem(FirstServiceLineItem), true);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler,MessgeHandler')]
    [Scope('OnPrem')]
    procedure ItemsOnServItemWorkSheetWithDecending()
    var
        SecondServiceLineItem: Record Item;
        FirstServiceLineItem: Record Item;
        ServiceLine: Record "Service Line";
    begin
        // Verify program does not messed up on Service Item Worksheet lines for Type Item using descending sorting while deleting the contract No on service Item line.
        ServItemWorkSheetAfterDeletingContractNoOnServiceItemLine(ServiceLine.Type::Item,
          LibraryInventory.CreateItem(SecondServiceLineItem), LibraryInventory.CreateItem(FirstServiceLineItem), false);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler,MessgeHandler')]
    [Scope('OnPrem')]
    procedure GLAccountsOnServItemWorkSheetWithAscending()
    var
        ServiceLine: Record "Service Line";
    begin
        // Verify program does not messed up on Service Item Worksheet lines for Type G/L Account using Ascending sorting while deleting the contract No on service Item line.
        ServItemWorkSheetAfterDeletingContractNoOnServiceItemLine(ServiceLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithSalesSetup(), LibraryERM.CreateGLAccountWithSalesSetup(), true);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler,MessgeHandler')]
    [Scope('OnPrem')]
    procedure GLAccountsOnServItemWorkSheetWithDecending()
    var
        ServiceLine: Record "Service Line";
    begin
        // Verify program does not messed up on Service Item Worksheet lines for Type G/L Account using Descending sorting while deleting the contract No on service Item line.
        ServItemWorkSheetAfterDeletingContractNoOnServiceItemLine(ServiceLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithSalesSetup(), LibraryERM.CreateGLAccountWithSalesSetup(), false);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler,MessgeHandler')]
    [Scope('OnPrem')]
    procedure ResourcesOnServItemWorkSheetWithAscending()
    var
        ServiceLine: Record "Service Line";
    begin
        // Verify program does not messed up on Service Item Worksheet lines for Type Resource using Ascending sorting while deleting the contract No on service Item line.
        ServItemWorkSheetAfterDeletingContractNoOnServiceItemLine(ServiceLine.Type::Resource,
          CreateResource(), CreateResource(), true);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler,MessgeHandler')]
    [Scope('OnPrem')]
    procedure ResourcesOnServiceItemWorkSheetLinesWithDecending()
    var
        ServiceLine: Record "Service Line";
    begin
        // Verify program does not messed up on Service Item Worksheet lines for Type Resource using Decending sorting while deleting the contract No on service Item line.
        ServItemWorkSheetAfterDeletingContractNoOnServiceItemLine(ServiceLine.Type::Resource,
          CreateResource(), CreateResource(), false);
    end;

    local procedure ServItemWorkSheetAfterDeletingContractNoOnServiceItemLine(Type: Enum "Service Line Type"; FirstItem: Code[20]; SecondItem: Code[20]; Value: Boolean)
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: array[10] of Record "Service Line";
        Counter: Integer;
    begin
        // Setup: Create Service Header with Signed Contract Service Item No. and Sort Service Item Line.
        Initialize();
        CreateServiceHeaderWithServiceItemLine(ServiceHeader, ServiceItemLine,
          CreateAndSignServiceContract(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract),
          ServiceContractHeader."Customer No.");
        CreateAndUpdateServiceLine(ServiceLine[1], ServiceHeader, Type, SecondItem, ServiceItemLine."Line No.");
        CreateAndUpdateServiceLine(ServiceLine[2], ServiceHeader, Type, FirstItem, ServiceItemLine."Line No.");
        ServiceItemLine.Ascending(Value);

        // Exercise: Delete Contract No. On Service Item Line.
        UpdateContractNoInServiceItemLine(ServiceItemLine, '');

        // Verify: Verify No. exist with Quantity on Service Lines.
        for Counter := 1 to 2 do
            VerifyValuesOnServiceLines(ServiceHeader, ServiceLine[Counter]."No.", ServiceLine[Counter].Quantity);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler,MessgeHandler')]
    [Scope('OnPrem')]
    procedure ServItemWorkSheetAscendingWithItemAfterInsertingContractNo()
    var
        SecondServiceLineItem: Record Item;
        FirstServiceLineItem: Record Item;
        ServiceLine: Record "Service Line";
    begin
        // Verify program does not messed up on Service Item Worksheet lines for Type Item using Ascending sorting while Inserting the contract No on service Item line.
        ServItemWorkSheetAfterInsertingContractNoOnServiceItemLine(ServiceLine.Type::Item,
          LibraryInventory.CreateItem(SecondServiceLineItem), LibraryInventory.CreateItem(FirstServiceLineItem), true);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler,MessgeHandler')]
    [Scope('OnPrem')]
    procedure ServItemWorkSheetDecendingWithItemAfterInsertingContractNo()
    var
        SecondServiceLineItem: Record Item;
        FirstServiceLineItem: Record Item;
        ServiceLine: Record "Service Line";
    begin
        // Verify program does not messed up on Service Item Worksheet lines for Type Item using Decending sorting while Inserting the contract No on service Item line.
        ServItemWorkSheetAfterInsertingContractNoOnServiceItemLine(ServiceLine.Type::Item,
          LibraryInventory.CreateItem(SecondServiceLineItem), LibraryInventory.CreateItem(FirstServiceLineItem), false);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler,MessgeHandler')]
    [Scope('OnPrem')]
    procedure ServItemWorkSheetAscendingWithGLAccountAfterInsertingContractNo()
    var
        ServiceLine: Record "Service Line";
    begin
        // Verify program does not messed up on Service Item Worksheet lines for Type G/L Account using Ascending sorting while Inserting the contract No on service Item line.
        ServItemWorkSheetAfterInsertingContractNoOnServiceItemLine(ServiceLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithSalesSetup(), LibraryERM.CreateGLAccountWithSalesSetup(), true);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler,MessgeHandler')]
    [Scope('OnPrem')]
    procedure ServItemWorkSheetDecendingWithGLAccountAfterInsertingContractNo()
    var
        ServiceLine: Record "Service Line";
    begin
        // Verify program does not messed up on Service Item Worksheet lines for Type G/L Account using Decending sorting while Inserting the contract No on service Item line.
        ServItemWorkSheetAfterInsertingContractNoOnServiceItemLine(ServiceLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithSalesSetup(), LibraryERM.CreateGLAccountWithSalesSetup(), false);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler,MessgeHandler')]
    [Scope('OnPrem')]
    procedure ServItemWorkSheetAscendingWithResourceAfterInsertingContractNo()
    var
        ServiceLine: Record "Service Line";
    begin
        // Verify program does not messed up on Service Item Worksheet lines for Type Resource using Ascending sorting while Inserting the contract No on service Item line.
        ServItemWorkSheetAfterInsertingContractNoOnServiceItemLine(ServiceLine.Type::Resource,
          CreateResource(), CreateResource(), true);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler,MessgeHandler')]
    [Scope('OnPrem')]
    procedure ServItemWorkSheetDecendingWithResourceAfterInsertingContractNo()
    var
        ServiceLine: Record "Service Line";
    begin
        // Verify program does not messed up on Service Item Worksheet lines for Type Resource using Decending sorting while Inserting the contract No on service Item line.
        ServItemWorkSheetAfterInsertingContractNoOnServiceItemLine(ServiceLine.Type::Resource,
          CreateResource(), CreateResource(), false);
    end;

    local procedure ServItemWorkSheetAfterInsertingContractNoOnServiceItemLine(Type: Enum "Service Line Type"; FirstItem: Code[20]; SecondItem: Code[20]; Value: Boolean)
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceLine: array[2] of Record "Service Line";
        Counter: Integer;
    begin
        // Setup: Create Service Header with Signed Contract Service Item No. and Sort Service Item Lines.
        Initialize();
        CreateServiceHeaderWithServiceItemLine(ServiceHeader, ServiceItemLine,
          CreateAndSignServiceContract(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract),
          ServiceContractHeader."Customer No.");
        CreateAndUpdateServiceLine(ServiceLine[1], ServiceHeader, Type, SecondItem, ServiceItemLine."Line No.");
        CreateAndUpdateServiceLine(ServiceLine[2], ServiceHeader, Type, FirstItem, ServiceItemLine."Line No.");
        ServiceItemLine.Ascending(Value);
        UpdateContractNoInServiceItemLine(ServiceItemLine, '');

        // Exercise: Insert Contract No. On Service Item Line.
        UpdateContractNoInServiceItemLine(ServiceItemLine, ServiceContractHeader."Contract No.");

        // Verify: Verify No. exist with Quantity on Service Lines.
        for Counter := 1 to 2 do
            VerifyValuesOnServiceLines(ServiceHeader, ServiceLine[Counter]."No.", ServiceLine[Counter].Quantity);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler,MessgeHandler')]
    [Scope('OnPrem')]
    procedure ItemsOnServiceLinesWithAscending()
    var
        SecondServiceLineItem: Record Item;
        FirstServiceLineItem: Record Item;
        ServiceLine: Record "Service Line";
    begin
        // Verify program does not messed up on Service lines for Type Item using Ascending sorting while Deleting the contract No on service Item line.
        ServiceLinesAfterDeletingContractNoOnServiceItemLine(ServiceLine.Type::Item,
          LibraryInventory.CreateItem(SecondServiceLineItem), LibraryInventory.CreateItem(FirstServiceLineItem), true);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler,MessgeHandler')]
    [Scope('OnPrem')]
    procedure ItemsOnServiceLinesWithDecending()
    var
        SecondServiceLineItem: Record Item;
        FirstServiceLineItem: Record Item;
        ServiceLine: Record "Service Line";
    begin
        // Verify program does not messed up on Service lines for Type Item using Decending sorting while Deleting the contract No on service Item line.
        ServiceLinesAfterDeletingContractNoOnServiceItemLine(ServiceLine.Type::Item,
          LibraryInventory.CreateItem(SecondServiceLineItem), LibraryInventory.CreateItem(FirstServiceLineItem), false);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler,MessgeHandler')]
    [Scope('OnPrem')]
    procedure GLAccountsOnServiceLinesWithAscending()
    var
        ServiceLine: Record "Service Line";
    begin
        // Verify program does not messed up on Service lines for Type G/L Account using Ascending sorting while Deleting the contract No on service Item line.
        ServiceLinesAfterDeletingContractNoOnServiceItemLine(ServiceLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithSalesSetup(), LibraryERM.CreateGLAccountWithSalesSetup(), true);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler,MessgeHandler')]
    [Scope('OnPrem')]
    procedure GLAccountsOnServiceLinesWithDecending()
    var
        ServiceLine: Record "Service Line";
    begin
        // Verify program does not messed up on Service lines for Type G/L Account using Decending sorting while Deleting the contract No on service Item line.
        ServiceLinesAfterDeletingContractNoOnServiceItemLine(ServiceLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithSalesSetup(), LibraryERM.CreateGLAccountWithSalesSetup(), false);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler,MessgeHandler')]
    [Scope('OnPrem')]
    procedure ResourcesOnServiceLinesWithAscending()
    var
        ServiceLine: Record "Service Line";
    begin
        // Verify program does not messed up on Service lines for Type Resource using Ascending sorting while Deleting the contract No on service Item line.
        ServiceLinesAfterDeletingContractNoOnServiceItemLine(ServiceLine.Type::Resource,
          CreateResource(), CreateResource(), true);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler,MessgeHandler')]
    [Scope('OnPrem')]
    procedure ResourcesOnServiceLinesWithDecending()
    var
        ServiceLine: Record "Service Line";
    begin
        // Verify program does not messed up on Service lines for Type Resource using Decending sorting while Deleting the contract No on service Item line.
        ServiceLinesAfterDeletingContractNoOnServiceItemLine(ServiceLine.Type::Resource,
          CreateResource(), CreateResource(), false);
    end;

    local procedure ServiceLinesAfterDeletingContractNoOnServiceItemLine(Type: Enum "Service Line Type"; FirstItem: Code[20]; SecondItem: Code[20]; Value: Boolean)
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceLine: array[2] of Record "Service Line";
        Counter: Integer;
    begin
        // Setup: Create Service Header with Signed Contract Service Item No. and Sort Service Lines.
        Initialize();
        CreateServiceHeaderWithServiceItemLine(ServiceHeader, ServiceItemLine,
          CreateAndSignServiceContract(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract),
          ServiceContractHeader."Customer No.");
        CreateAndUpdateServiceLine(ServiceLine[1], ServiceHeader, Type, SecondItem, ServiceItemLine."Line No.");
        CreateAndUpdateServiceLine(ServiceLine[2], ServiceHeader, Type, FirstItem, ServiceItemLine."Line No.");
        ServiceLine[1].Ascending(Value);

        // Exercise: Delete Contract No. On Service Item Line.
        UpdateContractNoInServiceItemLine(ServiceItemLine, '');

        // Verify: Verify No. exist with Quantity on Service Lines.
        for Counter := 1 to 2 do
            VerifyValuesOnServiceLines(ServiceHeader, ServiceLine[Counter]."No.", ServiceLine[Counter].Quantity);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler,MessgeHandler')]
    [Scope('OnPrem')]
    procedure ItemsOnServiceLinesWithAscendingAfterInsertingContractNo()
    var
        SecondServiceLineItem: Record Item;
        FirstServiceLineItem: Record Item;
        ServiceLine: Record "Service Line";
    begin
        // Verify program does not messed up on Service lines for Type Item using Ascending sorting while Inserting the contract No on Service Item line.
        ServiceLinesAfterInsertingContractNoOnServiceItemLine(ServiceLine.Type::Item,
          LibraryInventory.CreateItem(SecondServiceLineItem), LibraryInventory.CreateItem(FirstServiceLineItem), true);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler,MessgeHandler')]
    [Scope('OnPrem')]
    procedure ItemsOnServiceLinesWithDecendingAfterInsertingContractNo()
    var
        SecondServiceLineItem: Record Item;
        FirstServiceLineItem: Record Item;
        ServiceLine: Record "Service Line";
    begin
        // Verify program does not messed up on Service lines for Type Item using Decending sorting while Inserting the contract No on service Item line.
        ServiceLinesAfterInsertingContractNoOnServiceItemLine(ServiceLine.Type::Item,
          LibraryInventory.CreateItem(SecondServiceLineItem), LibraryInventory.CreateItem(FirstServiceLineItem), false);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler,MessgeHandler')]
    [Scope('OnPrem')]
    procedure GLAccountsOnServiceLinesWithAscendingAfterInsertingContractNo()
    var
        ServiceLine: Record "Service Line";
    begin
        // Verify program does not messed up on Service lines for Type G/L Account using Ascending sorting while Inserting the contract No on Service Item line.
        ServiceLinesAfterInsertingContractNoOnServiceItemLine(ServiceLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithSalesSetup(), LibraryERM.CreateGLAccountWithSalesSetup(), true);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler,MessgeHandler')]
    [Scope('OnPrem')]
    procedure GLAccountsOnServiceLinesWithDecendingAfterInsertingContractNo()
    var
        ServiceLine: Record "Service Line";
    begin
        // Verify program does not messed up on Service lines for Type G/L Account using Decending sorting while Inserting the contract No on Service Item line.
        ServiceLinesAfterInsertingContractNoOnServiceItemLine(ServiceLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithSalesSetup(), LibraryERM.CreateGLAccountWithSalesSetup(), false);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler,MessgeHandler')]
    [Scope('OnPrem')]
    procedure ResourceOnServiceLinesWithAscendingAfterInsertingContractNo()
    var
        ServiceLine: Record "Service Line";
    begin
        // Verify program does not messed up on Service lines for Type Resource using Ascending sorting while Inserting the contract No on Service Item line.
        ServiceLinesAfterInsertingContractNoOnServiceItemLine(ServiceLine.Type::Resource,
          CreateResource(), CreateResource(), true);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServContrctTemplateListHandler,MessgeHandler')]
    [Scope('OnPrem')]
    procedure ResourcesOnServiceLinesWithDecendingAfterInsertingContractNo()
    var
        ServiceLine: Record "Service Line";
    begin
        // Verify program does not messed up on Service lines for Type Resource using Decending sorting while Inserting the contract No on Service Item line.
        ServiceLinesAfterInsertingContractNoOnServiceItemLine(ServiceLine.Type::Resource,
          CreateResource(), CreateResource(), false);
    end;

    local procedure ServiceLinesAfterInsertingContractNoOnServiceItemLine(Type: Enum "Service Line Type"; FirstItem: Code[20]; SecondItem: Code[20]; Value: Boolean)
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceLine: array[2] of Record "Service Line";
        Counter: Integer;
    begin
        // Setup: Create Service Header with Signed Contract Service Item No. and Sort Service Lines.
        Initialize();
        CreateServiceHeaderWithServiceItemLine(ServiceHeader, ServiceItemLine,
          CreateAndSignServiceContract(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract),
          ServiceContractHeader."Customer No.");
        CreateAndUpdateServiceLine(ServiceLine[1], ServiceHeader, Type, SecondItem, ServiceItemLine."Line No.");
        CreateAndUpdateServiceLine(ServiceLine[2], ServiceHeader, Type, FirstItem, ServiceItemLine."Line No.");
        ServiceLine[1].Ascending(Value);
        UpdateContractNoInServiceItemLine(ServiceItemLine, '');

        // Exercise: Insert Contract No. On Service Item Line.
        UpdateContractNoInServiceItemLine(ServiceItemLine, ServiceContractHeader."Contract No.");

        // Verify: Verify No. exist with Quantity on Service Lines.
        for Counter := 1 to 2 do
            VerifyValuesOnServiceLines(ServiceHeader, ServiceLine[Counter]."No.", ServiceLine[Counter].Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServiceOrderWithUpdatingPostingDateOfServiceLine()
    var
        Customer: Record Customer;
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceItemNo: Code[20];
    begin
        // Setup: Create Customer and Item. Create Service Order and update the Posting Date of Service Line.
        // Posting Date should be different from Service Order Header Posting Date.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        ServiceItemNo := CreateServiceDocument(ServiceHeader, Customer."No.", Item."No.");
        UpdateServiceLine(
          ServiceLine, ServiceHeader."No.", ServiceItemNo,
          CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', ServiceHeader."Posting Date"));

        // Exercise: Post the Service Order as Ship and Invoice.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // Verify: Verify Posting Date of Value Entry.
        VerifyPostingDateOfValueEntry(Item."No.", ServiceHeader."Posting Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderWithInvoiceDiscountAndInvoiceRoundingInsertedOnPosting()
    var
        Customer: Record Customer;
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceInvoiceLine: Record "Service Invoice Line";
        ServiceItemNo: Code[20];
    begin
        // [FEATURE] [Invoice Rounding] [Invoice Discount] [Service Charge]
        // [SCENARIO 262418] You can post a service order when both "Calc. Inv. Discount" and "Inv. Rounding Precision" settings are enabled. The posting results in two additional lines in the invoice - for a service charge and a rounding precision amount.
        Initialize();

        // [GIVEN] Enable "Calc. Inv. Discount" and "Invoice Rounding" in Sales & Receivables Setup.
        LibrarySales.SetInvoiceRounding(true);
        LibrarySales.SetCalcInvDiscount(true);

        // [GIVEN] Set "Inv. Rounding Precision (LCY)" = 0.5 LCY in G/L Setup.
        LibraryERM.SetInvRoundingPrecisionLCY(0.5);

        // [GIVEN] Set up service charge for 1 LCY in sales invoice discount for a customer.
        LibrarySales.CreateCustomer(Customer);
        CreateCustomerInvoiceDiscount(CustInvoiceDisc, Customer."No.", 0, 1.0);

        // [GIVEN] Service order with one service line for an item. The amount on the service line = 10.1 LCY.
        ServiceItemNo := CreateServiceDocument(ServiceHeader, Customer."No.", LibraryInventory.CreateItemNo());
        UpdateServiceLineCustomValues(ServiceLine, ServiceHeader."No.", ServiceItemNo, 10, 1.01);

        // [WHEN] Post the Service Order as Ship and Invoice.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] The posted invoice contains three lines - the item, the service charge and the invoice rounding.
        FindServiceInvoiceLine(ServiceInvoiceLine, ServiceHeader."No.");
        Assert.RecordCount(ServiceInvoiceLine, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceLineRevalidateLineDiscountOnQtyToInvValidate()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceItem: Record "Service Item";
    begin
        // [FEATURE] [Line Discount]
        // [SCENARIO] "Line Discount Amount" is updated on "Qty. to Invoice" validation on Service Line
        Initialize();

        // [GIVEN] Service Order "SEO01"
        CreateServiceOrder(ServiceHeader, ServiceItem, ServiceItemLine);

        // [GIVEN] Service Line for "SEO01" with Amount = 60 and Quantity = 30
        CreateAndUpdateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, CreateItem(), ServiceItemLine."Line No.");

        // [GIVEN] "Line Discount %" = 15 on the Service Line ("Line Discount Amount" = 9)
        ServiceLine.Validate("Line Discount %", LibraryRandom.RandDec(100, 2));
        VerifyServiceLineLineDiscAmount(ServiceLine);

        // [GIVEN] "Qty. to Consume" = 10 ("Line Discount Amount" = 6)
        ServiceLine.Validate("Qty. to Consume", ServiceLine.Quantity / 3);
        VerifyServiceLineLineDiscAmount(ServiceLine);

        // [WHEN] Set "Qty. to Invoice" = 10
        ServiceLine.Validate("Qty. to Invoice", ServiceLine.Quantity / 3);

        // [THEN] "Line Discount Amount" = 9
        VerifyServiceLineLineDiscAmount(ServiceLine);
    end;

    [Test]
    [HandlerFunctions('ServiceInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReportServiceInvoiceCheckPostedShipmentDates()
    var
        Customer: Record Customer;
        Item: array[2] of Record Item;
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ColNo: Integer;
        RowNo: Integer;
    begin
        // [SCENARIO 392345] Printing posted Service Invoice with multiple lines with the same Item gives correct dates.
        Initialize();

        // [GIVEN] Service Order with service lines with items "Item1" and "Item2" shipped on "01.03.21".
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        ServiceHeader.Validate("Payment Terms Code", '');
        ServiceHeader.Validate("Posting Date", WorkDate());
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        LibraryInventory.CreateItem(Item[1]);
        CreateServiceLine(ServiceHeader, ServiceLine.Type::Item, Item[1]."No.", ServiceItemLine."Line No.");
        LibraryInventory.CreateItem(Item[2]);
        CreateServiceLine(ServiceHeader, ServiceLine.Type::Item, Item[2]."No.", ServiceItemLine."Line No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // [GIVEN] Service line with item "Item1" shipped on "02.03.21"
        ServiceHeader.Find();
        CreateServiceLine(ServiceHeader, ServiceLine.Type::Item, Item[1]."No.", ServiceItemLine."Line No.");
        ServiceHeader.Validate("Posting Date", WorkDate() + 1);
        ServiceHeader.Modify(true);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // [GIVEN] Service Order is invoiced.
        LibraryService.PostServiceOrder(ServiceHeader, false, false, true);

        // [WHEN] "Service - Invoice" report is run.
        FindServiceInvoiceHeader(ServiceInvoiceHeader, ServiceHeader."No.");
        ServiceInvoiceHeader.SetRecFilter();
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        Commit();
        REPORT.Run(REPORT::"Service - Invoice", true, true, ServiceInvoiceHeader);

        // [THEN] In resulting dataset Item1 has "01.03.21" Posted Shipment Date;
        // [THEN] Item2 has "01.03.21" Posted Shipment Date;
        // [THEN] Item1 has "02.03.21" Posted Shipment Date.
        LibraryReportValidation.OpenExcelFile();
        ColNo := LibraryReportValidation.FindColumnNoFromColumnCaption(PostedShipmentDateTxt);
        RowNo := LibraryReportValidation.FindRowNoFromColumnNoAndValue(ColNo, Format(WorkDate()));
        LibraryReportValidation.VerifyCellValue(RowNo + 1, ColNo, Format(WorkDate()));
        LibraryReportValidation.VerifyCellValue(RowNo + 2, ColNo, Format(WorkDate() + 1));
    end;

    [Test]
    [HandlerFunctions('ServiceInvoiceRequestPageHandlerDataset')]
    [Scope('OnPrem')]
    procedure ReportServiceInvoiceCompanyBankBranchNo()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        CompanyInformation: Record "Company Information";
        RequestPageXML: Text;
    begin
        // [SCENARIO 428309] Report Service Invoice prints company bank branch no.
        Initialize();

        // [GIVEN] Company information with "Bank Branch No." = "XXX"
        CompanyInformation.Get();
        CompanyInformation."Bank Branch No." := LibraryUtility.GenerateRandomNumericText(MaxStrLen(CompanyInformation."Bank Branch No."));
        CompanyInformation.Modify();

        // [GIVEN] Service Order with service lines with items "Item1" and "Item2" shipped on "01.03.21".
        CreateServiceOrder(ServiceHeader, ServiceItem, ServiceItemLine);
        CreateServiceLineWithResource(ServiceHeader, ServiceItem."No.");

        // [GIVEN] Service Order is invoiced.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [WHEN] "Service - Invoice" report is run.
        FindServiceInvoiceHeader(ServiceInvoiceHeader, ServiceHeader."No.");
        ServiceInvoiceHeader.SetRecFilter();
        Commit();
        RequestPageXML := Report.RunRequestPage(Report::"Service - Invoice", RequestPageXML);
        LibraryReportDataset.RunReportAndLoad(Report::"Service - Invoice", ServiceInvoiceHeader, RequestPageXML);

        // [THEN] Report dataset contains "Bank Branch No." value "XXX"
        LibraryReportDataset.AssertElementWithValueExists('CompanyBankBranchNo', CompanyInformation."Bank Branch No.");
    end;

    [Test]
    [HandlerFunctions('ServiceLinesExistMessageHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceDiscGroupCode()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [SCENARIO 434818] System shows warning messages when OnValidate is triggered on "Invoice Disc. Code" field.

        // [GIVEN] Create Service Item, Service Order with Header ,Service Item Line and Service line.
        Initialize();
        CreateServiceOrder(ServiceHeader, ServiceItem, ServiceItemLine);
        CreateServiceItemAndItemLine(ServiceItem, ServiceItemLine, ServiceHeader);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());

        // [WHEN] Exercise: Update Invoice Disc. Group code
        ServiceHeader.Validate("Invoice Disc. Code", LibraryRandom.RandText(20));

        // [THEN] Message is called when OnValidate is called for Invoice Disc. Code.
        Assert.ExpectedMessage(StrSubstNo(ServiceLinesChangeMsg, ServiceHeader.FieldCaption("Invoice Disc. Code"), ServiceHeader.TableCaption), LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseStatusCheckOnInvoiceDiscGroupCodeUpdate()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ReleaseServiceDocument: Codeunit "Release Service Document";
    begin
        // [SCENARIO 434818] To validate that Invoice Disc. Group Code can only be updated it Release Status is open.

        // [GIVEN] Create Service Item, Service Order with Header ,Service Item Line and Service Line and update quantity to 1 and release service order to ship.
        Initialize();
        CreateServiceOrder(ServiceHeader, ServiceItem, ServiceItemLine);
        CreateServiceItemAndItemLine(ServiceItem, ServiceItemLine, ServiceHeader);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        ServiceLine.Validate(Quantity, 1);
        ServiceLine.Modify(true);
        ReleaseServiceDocument.Run(ServiceHeader);

        // [WHEN] Update Invoice Disc. Group code
        asserterror ServiceHeader.Validate("Invoice Disc. Code", LibraryRandom.RandText(20));

        // [THEN] it throws an error message because Release status is not Open.
        Assert.ExpectedTestFieldError(ServiceHeader.FieldCaption("Release Status"), Format(ServiceHeader."Release Status"::Open));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServOrderCheckResponseTimeThrowsErrorIfDefaultServiceHoursAreNotSet()
    var
        ServiceHour: Record "Service Hour";
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
    begin
        // [SCENARIO] ServOrderCheckResponseTime throws error if Default Service hours are not set

        // [GIVEN] An empty Service Hour table and a pending Service Order
        Initialize();
        ServiceHour.DeleteAll();
        CreateServiceOrder(ServiceHeader, ServiceItem, ServiceItemLine);
        ServiceHeader.Validate(Status, ServiceHeader.Status::Pending);

        // [WHEN] Codeunit "ServOrder-Check Response Time" is run
        asserterror Codeunit.Run(Codeunit::"ServOrder-Check Response Time");

        // [THEN] Error is thrown indicating the Defualt Service Hours are not setup
        Assert.ExpectedError('not setup');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('LoanerConfirmHandler')]
    procedure LoanerNotBlankOnServiceItemLineWithoutReceiveOnLoanerCard()
    var
        Loaner: Record Loaner;
        Loaner1: Record Loaner;
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        ServLoanerManagement: Codeunit ServLoanerManagement;
    begin
        // [SCENARIO 485993] Service order field validations
        Initialize();

        // [GIVEN] Create two loaners.
        LibraryService.CreateLoaner(Loaner);
        LibraryService.CreateLoaner(Loaner1);

        // [GIVEN] Create a Service Order.
        CreateServiceOrder(ServiceHeader, ServiceItem, ServiceItemLine);

        // [GIVEN] Open Service Order Subform Page and assign Loaner No. value.
        OpenServiceOrderSubformAndAssignLoanerNo(ServiceItemLine, Loaner);

        // [VERIFY] Verify that the Loaner number is not blank in the Service Item Line.
        VerifyLoanerExistsOnServiceItemLine(ServiceHeader, Loaner);

        // [GIVEN] Received the loaner and no error occurred.
        ServiceItemLine.Get(ServiceItemLine."Document Type", ServiceItemLine."Document No.", ServiceItemLine."Line No.");
        ServLoanerManagement.ReceiveLoaner(ServiceItemLine);

        // [VERIFY] Verify that after receiving on the Loaner Page, Loaner No. Blank is on the Service Item Line.
        VerifyBlankLoanerNo(ServiceItemLine);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Order Check");
        Clear(LibraryService);
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Service Order Check");

        // Setup demonstration data
        LibrarySales.DisableWarningOnCloseUnpostedDoc();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateAccountInServiceCosts();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryService.SetupServiceMgtNoSeries();
        UpdateInventorySetup();

        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Service Order Check");
    end;

    local procedure CopyServiceLines(var FromServiceLine: Record "Service Line"; var ToTempServiceLine: Record "Service Line" temporary)
    begin
        FromServiceLine.FindSet();
        repeat
            ToTempServiceLine.Init();
            ToTempServiceLine := FromServiceLine;
            ToTempServiceLine.Insert();
        until FromServiceLine.Next() = 0
    end;

    local procedure CreateAndUpdateServiceLine(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; Type: Enum "Service Line Type"; ItemNo: Code[20]; ServiceItemLineNo: Integer)
    begin
        // Take Random Quantity and Unit Price.
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, Type, ItemNo);
        ServiceLine.Validate("Service Item Line No.", ServiceItemLineNo);
        ServiceLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ServiceLine.Modify(true);
    end;

    local procedure CreateCustomerLineDiscount(Item: Record Item; CustomerNo: Code[20])
    var
        SalesLineDiscount: Record "Sales Line Discount";
    begin
        // Use Random because value is not important.
        LibraryERM.CreateLineDiscForCustomer(
          SalesLineDiscount, SalesLineDiscount.Type::Item, Item."No.", SalesLineDiscount."Sales Type"::Customer, CustomerNo, WorkDate(), '', '',
          Item."Base Unit of Measure", LibraryRandom.RandInt(10));
        SalesLineDiscount.Validate("Line Discount %", LibraryRandom.RandInt(10));
        SalesLineDiscount.Modify(true);
    end;

    local procedure CreateCustomerInvoiceDiscount(var CustInvoiceDisc: Record "Cust. Invoice Disc."; CustomerNo: Code[20]; MinimumAmount: Decimal; ServiceCharge: Decimal)
    begin
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, CustomerNo, '', MinimumAmount);
        CustInvoiceDisc.Validate("Discount %", LibraryRandom.RandIntInRange(10, 20));
        CustInvoiceDisc.Validate("Service Charge", ServiceCharge);
        CustInvoiceDisc.Modify(true);
    end;

    local procedure CreateDimensionOnCustomer(Customer: Record Customer)
    var
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        Dimension: Record Dimension;
        LibraryDimension: Codeunit "Library - Dimension";
    begin
        DefaultDimension.SetRange("Table ID", DATABASE::Customer);
        DefaultDimension.SetRange("No.", Customer."No.");
        if DefaultDimension.FindFirst() then
            exit;

        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension, Customer."No.", Dimension.Code, DimensionValue.Code);
    end;

    local procedure CreateExtendedTextForItem(ItemNo: Code[20]): Text[50]
    var
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
    begin
        LibraryInventory.CreateExtendedTextHeaderItem(ExtendedTextHeader, ItemNo);
        ExtendedTextHeader.Validate("Starting Date", WorkDate());
        ExtendedTextHeader.Validate("All Language Codes", true);
        ExtendedTextHeader.Modify(true);

        LibraryInventory.CreateExtendedTextLineItem(ExtendedTextLine, ExtendedTextHeader);
        ExtendedTextLine.Validate(Text, LibraryUtility.GenerateRandomCode(ExtendedTextLine.FieldNo(Text), DATABASE::"Extended Text Line"));
        ExtendedTextLine.Modify(true);
        exit(ExtendedTextLine.Text);
    end;

    local procedure CreateResource(): Code[20]
    begin
        exit(LibraryResource.CreateResourceNo());
    end;

    local procedure CreateServiceDocument(var ServiceHeader: Record "Service Header"; CustomerNo: Code[20]; ItemNo: Code[20]) ServiceItemNo: Code[20]
    var
        ServiceItem: Record "Service Item";
        ServiceLine: Record "Service Line";
        ServiceItemLine: Record "Service Item Line";
    begin
        // Create Service Order - Service Header, Service Item Line, Service Line of Type Item.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CustomerNo);
        LibraryService.CreateServiceItem(ServiceItem, CustomerNo);
        ServiceItemNo := ServiceItem."No.";
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
    end;

    local procedure CreateServiceHeaderWithServiceItemLine(var ServiceHeader: Record "Service Header"; var ServiceItemLine: Record "Service Item Line"; ServiceItemNo: Code[20]; CustomerNo: Code[20])
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CustomerNo);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItemNo);
    end;

    local procedure CreateServiceLineWithDescriptionOnly(ServiceHeader: Record "Service Header"; ServiceItemLineNo: Integer)
    var
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::" ", '');
        ServiceLine.Validate("Service Item Line No.", ServiceItemLineNo);
        ServiceLine.Validate(Description, ServiceHeader."No.");  // Enter Service Order No. for Description, Value is not important for test.
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceLineWithItem(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; ServiceItemNo: Code[20])
    var
        Counter: Integer;
    begin
        // Create 2 to 10 Service Lines with Type Item - Boundary 2 is important.
        for Counter := 2 to 2 + LibraryRandom.RandInt(8) do begin
            LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, CreateItem());
            ServiceLine.Validate("Service Item No.", ServiceItemNo);
            ServiceLine.Validate(Quantity, LibraryRandom.RandInt(100));  // Required field - value is not important to test case.
            ServiceLine.Modify(true);
        end;
    end;

    local procedure CreateServiceLineWithResource(ServiceHeader: Record "Service Header"; ServiceItemNo: Code[20])
    var
        ServiceLine: Record "Service Line";
        LibraryResource: Codeunit "Library - Resource";
        Counter: Integer;
        ResourceNo: Code[20];
    begin
        // Create 2 to 10 Service Lines with Type Resource - Boundary 2 is important.
        ResourceNo := LibraryResource.CreateResourceNo();
        for Counter := 2 to 2 + LibraryRandom.RandInt(8) do begin
            LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Resource, ResourceNo);
            ServiceLine.Validate("Service Item No.", ServiceItemNo);
            ServiceLine.Validate(Quantity, LibraryRandom.RandInt(100));  // Required field - value is not important to test case.
            ServiceLine.Modify(true);
        end;
    end;

    local procedure CreateServiceOrder(var ServiceHeader: Record "Service Header"; var ServiceItem: Record "Service Item"; var ServiceItemLine: Record "Service Item Line")
    var
        Customer: Record Customer;
    begin
        // Create Service Item, Service Header and Service Item Line.
        LibrarySales.CreateCustomer(Customer);
        CreateDimensionOnCustomer(Customer);
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        ServiceItem.Validate("Warranty Starting Date (Parts)", WorkDate());
        ServiceItem.Validate("Warranty Ending Date (Parts)", WorkDate());
        ServiceItem.Validate("Warranty Starting Date (Labor)", WorkDate());
        ServiceItem.Validate("Warranty Ending Date (Labor)", WorkDate());
        ServiceItem.Modify(true);

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
    end;

    local procedure CreateServiceOrderWithLines(var ServiceHeader: Record "Service Header")
    var
        Customer: Record Customer;
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceCost: Record "Service Cost";
        LibraryResource: Codeunit "Library - Resource";
    begin
        // Service Header, Service Item Line, Service Line with Type Item, Resource, Cost and G/L Account.
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        LibraryService.FindServiceCost(ServiceCost);
        CreateServiceLine(ServiceHeader, ServiceLine.Type::Item, CreateItem(), ServiceItemLine."Line No.");
        CreateServiceLine(ServiceHeader, ServiceLine.Type::Resource, LibraryResource.CreateResourceNo(), ServiceItemLine."Line No.");
        CreateServiceLine(ServiceHeader, ServiceLine.Type::Cost, ServiceCost.Code, ServiceItemLine."Line No.");
        CreateServiceLine(
          ServiceHeader, ServiceLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), ServiceItemLine."Line No.");
    end;

    local procedure CreateServiceItemAndItemLine(var ServiceItem: Record "Service Item"; var ServiceItemLine: Record "Service Item Line"; ServiceHeader: Record "Service Header")
    begin
        Clear(ServiceItem);
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
    end;

    local procedure CreateServiceLine(ServiceHeader: Record "Service Header"; Type: Enum "Service Line Type"; No: Code[20]; ServiceItemLineNo: Integer)
    var
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, Type, No);
        ServiceLine.Validate("Service Item Line No.", ServiceItemLineNo);
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(100));  // Use Random because value is not important.
        ServiceLine.Validate("Qty. to Invoice", ServiceLine.Quantity * LibraryUtility.GenerateRandomFraction());
        ServiceLine.Modify(true);
    end;

    local procedure CreateAndSignServiceContract(var ServiceContractHeader: Record "Service Contract Header"; ContractType: Enum "Service Contract Type"): Code[20]
    var
        ServiceContractLine: Record "Service Contract Line";
        ServiceItem: Record "Service Item";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ContractType, CreateCustomer());
        LibraryService.CreateServiceItem(ServiceItem, ServiceContractHeader."Customer No.");
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Cost", 1000 * LibraryRandom.RandInt(10));
        ServiceContractLine.Validate("Line Value", 1000 * LibraryRandom.RandInt(10));
        ServiceContractLine.Validate("Service Period", ServiceContractHeader."Service Period");
        ServiceContractLine.Modify(true);
        ModifyAnnualAmountOnServiceContractHeader(ServiceContractHeader);
        SignServContractDoc.SignContract(ServiceContractHeader);
        exit(ServiceItem."No.");
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindFirst();
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        exit(Item."No.");
    end;

    local procedure FindServiceInvoiceHeader(var ServiceInvoiceHeader: Record "Service Invoice Header"; OrderNo: Code[20])
    begin
        ServiceInvoiceHeader.SetRange("Order No.", OrderNo);
        ServiceInvoiceHeader.FindFirst();
    end;

    local procedure FindServiceInvoiceLine(var ServiceInvoiceLine: Record "Service Invoice Line"; OrderNo: Code[20])
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        FindServiceInvoiceHeader(ServiceInvoiceHeader, OrderNo);
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
    end;

    local procedure FindServiceShipmentLine(var ServiceShipmentLine: Record "Service Shipment Line"; OrderNo: Code[20])
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
    begin
        ServiceShipmentHeader.SetRange("Order No.", OrderNo);
        ServiceShipmentHeader.FindFirst();
        ServiceShipmentLine.SetRange("Document No.", ServiceShipmentHeader."No.");
    end;

    local procedure GetServiceLines(var ServiceLine: Record "Service Line"; DocumentNo: Code[20]; DocumentType: Enum "Service Document Type")
    begin
        ServiceLine.SetRange("Document Type", DocumentType);
        ServiceLine.SetRange("Document No.", DocumentNo);
        ServiceLine.FindSet();
    end;

    local procedure GetGLServiceLines(var ServiceLine: Record "Service Line"; DocumentNo: Code[20]; DocumentType: Enum "Service Document Type")
    begin
        ServiceLine.SetRange("Document Type", DocumentType);
        ServiceLine.SetRange("Document No.", DocumentNo);
        ServiceLine.SetRange(Type, ServiceLine.Type::"G/L Account");
        ServiceLine.FindFirst();
    end;

    local procedure GetServiceLinesForShipment(var ServiceLine: Record "Service Line"; DocumentNo: Code[20])
    begin
        ServiceLine.SetFilter("Qty. to Invoice", '<>0');
        GetServiceLines(ServiceLine, DocumentNo, ServiceLine."Document Type"::Order);
    end;

    local procedure ModifyServiceItemLine(var ServiceItemLine: Record "Service Item Line")
    var
        FaultArea: Record "Fault Area";
        FaultReasonCode: Record "Fault Reason Code";
        FaultCode: Record "Fault Code";
        SymptomCode: Record "Symptom Code";
    begin
        LibraryService.CreateFaultArea(FaultArea);
        LibraryService.CreateSymptomCode(SymptomCode);
        LibraryService.CreateFaultCode(FaultCode, FaultArea.Code, SymptomCode.Code);
        LibraryService.CreateFaultReasonCode(FaultReasonCode, true, true);
        ServiceItemLine.Validate("Fault Reason Code", FaultReasonCode.Code);
        ServiceItemLine.Validate("Fault Area Code", FaultCode."Fault Area Code");
        ServiceItemLine.Validate("Symptom Code", FaultCode."Symptom Code");
        ServiceItemLine.Validate("Fault Code", FaultCode.Code);
        ServiceItemLine.Modify(true);
    end;

    local procedure ModifyLoanerNoServiceItemLine(var ServiceItemLine: Record "Service Item Line")
    var
        Loaner: Record Loaner;
    begin
        Loaner.FindSet();
        ServiceItemLine.SetRange("Document Type", ServiceItemLine."Document Type"::Order);
        ServiceItemLine.SetRange("Document No.", ServiceItemLine."Document No.");
        ServiceItemLine.FindSet();
        repeat
            ServiceItemLine.Validate("Loaner No.", Loaner."No.");
            ServiceItemLine.Modify(true);
            Loaner.Next();
        until ServiceItemLine.Next() = 0;
    end;

    local procedure ModifyAnnualAmountOnServiceContractHeader(var ServiceContractHeader: Record "Service Contract Header")
    begin
        ServiceContractHeader.CalcFields("Calcd. Annual Amount");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractHeader."Calcd. Annual Amount");
        ServiceContractHeader.Validate("Starting Date", WorkDate());
        ServiceContractHeader.Validate("Price Update Period", ServiceContractHeader."Service Period");
        ServiceContractHeader.Modify(true);
    end;

    local procedure OpenServiceLinePage(No: Code[20])
    var
        ServiceOrder: TestPage "Service Order";
    begin
        ServiceOrder.OpenEdit();
        ServiceOrder.FILTER.SetFilter("No.", No);
        ServiceOrder.ServItemLines."Service Lines".Invoke();
        ServiceOrder.OK().Invoke();
    end;

    local procedure ReceiveLoanerOnServiceItemLine(ServiceItemLine: Record "Service Item Line")
    var
        ServLoanerManagement: Codeunit ServLoanerManagement;
    begin
        ServiceItemLine.SetRange("Document Type", ServiceItemLine."Document Type"::Order);
        ServiceItemLine.SetRange("Document No.", ServiceItemLine."Document No.");
        ServiceItemLine.FindSet();
        repeat
            ServLoanerManagement.ReceiveLoaner(ServiceItemLine);
        until ServiceItemLine.Next() = 0;
    end;

    local procedure RunServiceCalcDiscount(ServiceLine: Record "Service Line")
    var
        ServiceCalcDisc: Codeunit "Service-Calc. Discount";
    begin
        Clear(ServiceCalcDisc);
        ServiceCalcDisc.Run(ServiceLine);
    end;

    local procedure SaveServiceItemLineInTempTable(var TempServiceItemLine: Record "Service Item Line" temporary; ServiceItemLine: Record "Service Item Line")
    begin
        ServiceItemLine.SetRange("Document Type", ServiceItemLine."Document Type"::Order);
        ServiceItemLine.SetRange("Document No.", ServiceItemLine."Document No.");
        ServiceItemLine.FindSet();
        repeat
            TempServiceItemLine := ServiceItemLine;
            TempServiceItemLine.Insert();
        until ServiceItemLine.Next() = 0;
    end;

    local procedure UpdateFullQtyToInvoice(ServiceHeader: Record "Service Header"; Type: Enum "Service Line Type")
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange(Type, Type);
        GetServiceLines(ServiceLine, ServiceHeader."No.", ServiceHeader."Document Type");
        ServiceLine.Validate("Qty. to Invoice", ServiceLine.Quantity);
        ServiceLine.Modify(true);
    end;

    local procedure UpdatePartialQtyToShip(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
    begin
        GetServiceLines(ServiceLine, ServiceHeader."No.", ServiceHeader."Document Type");
        repeat
            ServiceLine.Validate("Qty. to Ship", ServiceLine.Quantity * LibraryUtility.GenerateRandomFraction());
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    local procedure UpdatePostingDateOnServiceHeader(var PostingDate: Date; ServiceHeader: Record "Service Header")
    begin
        PostingDate := CalcDate('<-' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate());  // Take a Random Date.
        ServiceHeader.Validate("Posting Date", PostingDate);
        ServiceHeader.Modify(true);
    end;

    local procedure UpdateServiceLine(var ServiceLine: Record "Service Line"; ServiceOrderNo: Code[20]; ServiceItemNo: Code[20]; PostingDate: Date)
    begin
        GetServiceLines(ServiceLine, ServiceOrderNo, ServiceLine."Document Type"::Order);
        ServiceLine.Validate("Service Item No.", ServiceItemNo);
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));
        // Use Random because value is not important.
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        ServiceLine.Validate("Posting Date", PostingDate);
        ServiceLine.Modify(true);
    end;

    local procedure UpdateServiceLineCustomValues(var ServiceLine: Record "Service Line"; ServiceOrderNo: Code[20]; ServiceItemNo: Code[20]; NewQuantity: Decimal; UnitPrice: Decimal)
    begin
        GetServiceLines(ServiceLine, ServiceOrderNo, ServiceLine."Document Type"::Order);
        ServiceLine.Validate("Service Item No.", ServiceItemNo);
        ServiceLine.Validate(Quantity, NewQuantity);
        ServiceLine.Validate("Unit Price", UnitPrice);
        ServiceLine.Modify(true);
    end;

    local procedure UpdateContractNoInServiceItemLine(ServiceItemLine: Record "Service Item Line"; ContractNo: Code[20])
    begin
        ServiceItemLine.Validate("Contract No.", ContractNo);
        ServiceItemLine.Modify(true);
    end;

    local procedure VerifyAmountOnGLEntry(DocumentNo: Code[20]; GLAccountNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        FindGLEntry(GLEntry, GLEntry."Document Type"::Invoice, DocumentNo);
        GLEntry.TestField(Amount, Amount);
    end;

    local procedure VerifyCustomerLedgerEntry(ServiceInvoiceHeader: Record "Service Invoice Header")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Document No.", ServiceInvoiceHeader."No.");
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.TestField("Posting Date", ServiceInvoiceHeader."Posting Date");
    end;

    local procedure VerifyExtendedText(OrderNo: Code[20]; Description: Text[50])
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        FindServiceInvoiceHeader(ServiceInvoiceHeader, OrderNo);
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        ServiceInvoiceLine.SetRange(Type, ServiceInvoiceLine.Type::" ");
        ServiceInvoiceLine.FindFirst();
        ServiceInvoiceLine.TestField(Description, Description);
    end;

    local procedure VerifyGetShipmentLines(ServiceOrderNo: Code[20]; ServiceInvoiceNo: Code[20])
    var
        ServiceLine: Record "Service Line";
        ServiceLine2: Record "Service Line";
    begin
        GetServiceLines(ServiceLine, ServiceOrderNo, ServiceLine."Document Type"::Order);
        repeat
            // Service Line added by 10000 as the first line has the Shipment No.
            ServiceLine2.Get(ServiceLine2."Document Type"::Invoice, ServiceInvoiceNo, ServiceLine."Line No." + 10000);
            ServiceLine2.TestField(Type, ServiceLine.Type);
            ServiceLine2.TestField("No.", ServiceLine."No.");
            ServiceLine2.TestField("Line Discount %", ServiceLine."Line Discount %");
            ServiceLine2.TestField("Warranty Disc. %", ServiceLine."Warranty Disc. %");
            ServiceLine2.TestField("Contract Disc. %", ServiceLine."Contract Disc. %");
            ServiceLine2.TestField("Line Discount Type", ServiceLine."Line Discount Type");
            ServiceLine2.TestField("Line Discount Amount", ServiceLine."Line Discount Amount");
        until ServiceLine.Next() = 0;
    end;

    local procedure VerifyGLEntries(var TempServiceLine: Record "Service Line" temporary; CustInvoiceDisc: Record "Cust. Invoice Disc."; CustomerPostingGroupCode: Code[20])
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        Amount: Decimal;
    begin
        CustomerPostingGroup.Get(CustomerPostingGroupCode);
        TempServiceLine.SetRange(Type, TempServiceLine.Type::Item);
        TempServiceLine.FindFirst();
        Amount := Round(TempServiceLine."Line Discount Amount" + (TempServiceLine."Line Amount" * CustInvoiceDisc."Discount %" / 100));
        GeneralPostingSetup.Get(TempServiceLine."Gen. Bus. Posting Group", TempServiceLine."Gen. Prod. Posting Group");
        FindServiceInvoiceHeader(ServiceInvoiceHeader, TempServiceLine."Document No.");
        VerifyAmountOnGLEntry(ServiceInvoiceHeader."No.", GeneralPostingSetup."Sales Inv. Disc. Account", Amount);
        VerifyAmountOnGLEntry(ServiceInvoiceHeader."No.", CustomerPostingGroup."Service Charge Acc.", -CustInvoiceDisc."Service Charge");
    end;

    local procedure VerifyGLEntry(ServiceInvoiceHeader: Record "Service Invoice Header")
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("Document No.", ServiceInvoiceHeader."No.");
        GLEntry.SetRange("Source Type", GLEntry."Source Type"::Customer);
        GLEntry.FindSet();
        repeat
            GLEntry.TestField("Source No.", ServiceInvoiceHeader."Bill-to Customer No.");
            GLEntry.TestField("Posting Date", ServiceInvoiceHeader."Posting Date");
        until GLEntry.Next() = 0;
    end;

    local procedure VerifyResourceLedgerEntry(ServiceInvoiceHeader: Record "Service Invoice Header")
    var
        ServiceInvoiceLine: Record "Service Invoice Line";
        ResLedgerEntry: Record "Res. Ledger Entry";
    begin
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        ServiceInvoiceLine.FindSet();
        ResLedgerEntry.SetRange("Document No.", ServiceInvoiceLine."Document No.");
        repeat
            ResLedgerEntry.SetRange("Order Line No.", ServiceInvoiceLine."Line No.");
            ResLedgerEntry.FindFirst();
            ResLedgerEntry.TestField("Posting Date", ServiceInvoiceHeader."Posting Date");
            ResLedgerEntry.TestField("Order Type", ResLedgerEntry."Order Type"::Service);
            ResLedgerEntry.TestField("Order No.", ServiceInvoiceHeader."Order No.");
            ResLedgerEntry.TestField("Resource No.", ServiceInvoiceLine."No.");
        until ServiceInvoiceLine.Next() = 0;
    end;

    local procedure VerifyServiceItemLogEntry(ServiceItemLine: Record "Service Item Line")
    var
        ServiceItemLog: Record "Service Item Log";
    begin
        // Verify Service Item Log entry that occurred due to a certain action.
        ServiceItemLog.SetRange("Document No.", ServiceItemLine."Document No.");
        ServiceItemLog.SetRange("Service Item No.", ServiceItemLine."Service Item No.");
        ServiceItemLog.FindFirst();
    end;

    local procedure VerifyLoanerNoServiceItemLine(var TempServiceItemLine: Record "Service Item Line" temporary)
    var
        ServiceItemLine: Record "Service Item Line";
    begin
        TempServiceItemLine.FindSet();
        repeat
            ServiceItemLine.Get(TempServiceItemLine."Document Type", TempServiceItemLine."Document No.", TempServiceItemLine."Line No.");
            ServiceItemLine.TestField("Loaner No.", TempServiceItemLine."Loaner No.");
        until TempServiceItemLine.Next() = 0;
    end;

    local procedure VerifyBlankLoanerNo(ServiceItemLine: Record "Service Item Line")
    begin
        ServiceItemLine.SetRange("Document Type", ServiceItemLine."Document Type"::Order);
        ServiceItemLine.SetRange("Document No.", ServiceItemLine."Document No.");
        ServiceItemLine.FindSet();
        repeat
            ServiceItemLine.TestField("Loaner No.", '');
        until ServiceItemLine.Next() = 0;
    end;

    local procedure VerifyServiceLedgerEntry(ServiceLine: Record "Service Line")
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        GetServiceLines(ServiceLine, ServiceLine."Document No.", ServiceLine."Document Type"::Order);
        ServiceLedgerEntry.SetRange("Document Type", ServiceLedgerEntry."Document Type"::Shipment);
        ServiceLedgerEntry.SetRange("Service Order No.", ServiceLine."Document No.");
        ServiceLedgerEntry.FindSet();
        repeat
            ServiceLedgerEntry.TestField("Customer No.", ServiceLine."Customer No.");
            ServiceLedgerEntry.TestField(Quantity, ServiceLine."Qty. Shipped (Base)");
            ServiceLedgerEntry.Next();
        until ServiceLine.Next() = 0;
    end;

    local procedure VerifyServiceLineForInvoice(OrderNo2: Code[20]; DocumentNo: Code[20])
    var
        ServiceLine: Record "Service Line";
        ServiceLine2: Record "Service Line";
    begin
        GetServiceLinesForShipment(ServiceLine2, OrderNo2);
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Invoice);
        ServiceLine.SetRange("Document No.", DocumentNo);
        repeat
            ServiceLine.SetRange("Shipment Line No.", ServiceLine2."Line No.");
            ServiceLine.FindFirst();
            ServiceLine.TestField(Type, ServiceLine2.Type);
            ServiceLine.TestField("No.", ServiceLine2."No.");
            ServiceLine.TestField(Quantity, ServiceLine2."Qty. to Invoice");
            ServiceLine.TestField("Unit Price", ServiceLine2."Unit Price");
        until ServiceLine2.Next() = 0;
    end;

    local procedure VerifyWarrantyLedgerEntry(ServiceLine: Record "Service Line")
    var
        WarrantyLedgerEntry: Record "Warranty Ledger Entry";
    begin
        WarrantyLedgerEntry.SetRange("Service Order No.", ServiceLine."Document No.");
        WarrantyLedgerEntry.FindSet();
        GetServiceLines(ServiceLine, ServiceLine."Document No.", ServiceLine."Document Type"::Order);
        repeat
            WarrantyLedgerEntry.TestField("Customer No.", ServiceLine."Customer No.");
            WarrantyLedgerEntry.TestField(Quantity, ServiceLine.Quantity);
            ServiceLine.Next();
        until WarrantyLedgerEntry.Next() = 0;
    end;

    local procedure VerifyWarrantyLedgerFullPost(var ServiceLine: Record "Service Line")
    var
        WarrantyLedgerEntry: Record "Warranty Ledger Entry";
    begin
        WarrantyLedgerEntry.SetRange("Service Order No.", ServiceLine."Document No.");
        WarrantyLedgerEntry.FindSet();
        GetServiceLines(ServiceLine, ServiceLine."Document No.", ServiceLine."Document Type"::Order);
        repeat
            WarrantyLedgerEntry.TestField("Customer No.", ServiceLine."Customer No.");
            WarrantyLedgerEntry.TestField(Quantity, ServiceLine.Quantity);
            ServiceLine.Next();
        until WarrantyLedgerEntry.Next() = 0;
    end;

    local procedure VerifyVATEntry(ServiceInvoiceHeader: Record "Service Invoice Header")
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.SetRange("Document No.", ServiceInvoiceHeader."No.");
        VATEntry.FindSet();
        repeat
            VATEntry.TestField("Posting Date", ServiceInvoiceHeader."Posting Date");
            VATEntry.TestField("Bill-to/Pay-to No.", ServiceInvoiceHeader."Bill-to Customer No.");
        until VATEntry.Next() = 0;
    end;

    local procedure VerifyServiceInvoice(var TempServiceLine: Record "Service Line" temporary)
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        // Verify fields Invoice Discount and Line Discount of Service Invoice Line are equal to the value of the field Invoice Discount and Line Discount of the relevant Service Line.
        TempServiceLine.FindSet();
        FindServiceInvoiceHeader(ServiceInvoiceHeader, TempServiceLine."Document No.");
        repeat
            ServiceInvoiceLine.Get(ServiceInvoiceHeader."No.", TempServiceLine."Line No.");
            ServiceInvoiceLine.TestField(Type, TempServiceLine.Type);
            ServiceInvoiceLine.TestField("No.", TempServiceLine."No.");
            ServiceInvoiceLine.TestField("Line Discount %", TempServiceLine."Line Discount %");
            ServiceInvoiceLine.TestField("Line Discount Amount", TempServiceLine."Line Discount Amount");
            ServiceInvoiceLine.TestField("Inv. Discount Amount", TempServiceLine."Inv. Discount Amount");
        until TempServiceLine.Next() = 0;
    end;

    local procedure VerifyServiceShipmentLine(ServiceLine: Record "Service Line")
    var
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        ServiceLine.SetRange(Type, ServiceLine.Type::Item);
        GetServiceLines(ServiceLine, ServiceLine."Document No.", ServiceLine."Document Type"::Order);
        ServiceShipmentLine.SetRange("Order No.", ServiceLine."Document No.");
        ServiceShipmentLine.SetRange(Type, ServiceShipmentLine.Type::Item);
        ServiceShipmentLine.FindSet();
        repeat
            ServiceShipmentLine.TestField("Customer No.", ServiceLine."Customer No.");
            ServiceShipmentLine.TestField(Quantity, ServiceLine.Quantity);
            ServiceShipmentLine.Next();
        until ServiceLine.Next() = 0;
    end;

    local procedure VerifyServiceDocumentLogEvent(DocumentNo: Code[20]; DocumentType: Enum "Service Log Document Type"; EventNo: Integer)
    var
        ServiceDocumentLog: Record "Service Document Log";
    begin
        // Verify Service Document Log entry for Event No. that corresponds to the event that occurred due to a certain action.
        ServiceDocumentLog.SetRange("Document Type", DocumentType);
        ServiceDocumentLog.SetRange("Document No.", DocumentNo);
        ServiceDocumentLog.FindLast();
        ServiceDocumentLog.TestField("Event No.", EventNo);
    end;

    local procedure VerifyShipmentLineError(ServiceOrderNo: Code[20])
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
        PostedServiceInvoice: TestPage "Posted Service Invoice";
    begin
        FindServiceInvoiceHeader(ServiceInvoiceHeader, ServiceOrderNo);
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        ServiceInvoiceLine.FindFirst();

        PostedServiceInvoice.OpenEdit();
        PostedServiceInvoice.FILTER.SetFilter("No.", ServiceInvoiceHeader."No.");

        asserterror PostedServiceInvoice.ServInvLines.ItemShipmentLines.Invoke();
        Assert.ExpectedTestFieldError(ServiceInvoiceLine.FieldCaption(Type), Format(ServiceInvoiceLine.Type::Item));
    end;

    local procedure VerifyDocumentDimension(DocumentNo: Code[20])
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
        ServiceHeader: Record "Service Header";
        OrderDimSetID: Integer;
        ShipmentDimSetID: Integer;
    begin
        // Get Dimension Set ID on Service Header.
        ServiceHeader.SetRange("No.", DocumentNo);
        ServiceHeader.FindFirst();
        OrderDimSetID := ServiceHeader."Dimension Set ID";

        // Get Dimension Set ID on Service Shipment Header.
        ServiceShipmentHeader.SetRange("Order No.", DocumentNo);
        ServiceShipmentHeader.FindFirst();
        ShipmentDimSetID := ServiceShipmentHeader."Dimension Set ID";

        Assert.AreEqual(OrderDimSetID, ShipmentDimSetID, StrSubstNo(DocumentDimError, ServiceShipmentHeader."No.", ServiceHeader."No."));
    end;

    local procedure VerifyPostingDateOnServiceShipment(OrderNo: Code[20]; PostingDate: Date)
    var
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        FindServiceShipmentLine(ServiceShipmentLine, OrderNo);
        ServiceShipmentLine.FindSet();
        repeat
            ServiceShipmentLine.TestField("Posting Date", PostingDate);
        until ServiceShipmentLine.Next() = 0;
    end;

    local procedure VerifyPostingDateOnServiceInvoice(OrderNo: Code[20]; PostingDate: Date)
    var
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        FindServiceInvoiceLine(ServiceInvoiceLine, OrderNo);
        ServiceInvoiceLine.FindSet();
        repeat
            ServiceInvoiceLine.TestField("Posting Date", PostingDate);
        until ServiceInvoiceLine.Next() = 0;
    end;

    local procedure VerifyValuesOnServiceLines(ServiceHeader: Record "Service Header"; ItemNo: Code[20]; Quantity: Decimal)
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Customer No.", ServiceHeader."Customer No.");
        ServiceLine.SetRange("No.", ItemNo);
        ServiceLine.FindFirst();
        ServiceLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyPostingDateOfValueEntry(ItemNo: Code[20]; PostingDate: Date)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Service Invoice");
        ValueEntry.FindFirst();
        Assert.AreEqual(PostingDate, ValueEntry."Posting Date", PostingDateErr);
    end;

    local procedure VerifyServiceLineInvDiscAmount(var ServiceLine: Record "Service Line"; ExpectedAmount: Decimal)
    begin
        ServiceLine.Find();
        Assert.AreEqual(ExpectedAmount, ServiceLine."Inv. Discount Amount", ServiceLine.FieldCaption("Inv. Discount Amount"));
    end;

    local procedure VerifyServiceLineLineDiscAmount(ServiceLine: Record "Service Line")
    var
        Currency: Record Currency;
        ExpectedAmt: Decimal;
        Precision: Decimal;
    begin
        Currency.Initialize('');
        Precision := Currency."Amount Rounding Precision";
        ExpectedAmt := Round((ServiceLine.Quantity - ServiceLine."Qty. to Consume" - ServiceLine."Quantity Consumed") * ServiceLine."Unit Price", Precision);
        ExpectedAmt := Round(ExpectedAmt * ServiceLine."Line Discount %" / 100, Precision);
        ServiceLine.TestField("Line Discount Amount", ExpectedAmt);
    end;

    local procedure OpenServiceOrderSubformAndAssignLoanerNo(ServiceItemLine: Record "Service Item Line"; Loaner: Record Loaner)
    var
        ServiceOrderSubform: TestPage "Service Order Subform";
    begin
        ServiceOrderSubform.OpenEdit();
        ServiceOrderSubform.GoToRecord(ServiceItemLine);
        ServiceOrderSubform."Loaner No.".SetValue(Loaner."No.");
        ServiceOrderSubform.Close();
    end;

    local procedure VerifyLoanerExistsOnServiceItemLine(ServiceHeader: Record "Service Header"; Loaner: Record Loaner)
    var
        ServiceItemLine: Record "Service Item Line";
    begin
        ServiceItemLine.SetRange("Document Type", ServiceItemLine."Document Type"::Order);
        ServiceItemLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceItemLine.SetRange("Loaner No.", Loaner."No.");
        Assert.IsTrue(ServiceItemLine.FindFirst(), ServiceItemLineErr);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure LoanerConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure FormHandlerGetShipment(var GetServiceShipmentLines: Page "Get Service Shipment Lines"; var Response: Action)
    var
        ServiceHeader: Record "Service Header";
        ServiceShipmentLine: Record "Service Shipment Line";
        ServiceGetShipment: Codeunit "Service-Get Shipment";
    begin
        ServiceHeader.Get(ServiceHeader."Document Type"::Invoice, InvoiceNo);
        ServiceGetShipment.SetServiceHeader(ServiceHeader);

        ServiceShipmentLine.SetRange("Order No.", OrderNo);
        ServiceShipmentLine.FindFirst();
        ServiceGetShipment.CreateInvLines(ServiceShipmentLine);
    end;

    local procedure UpdateInventorySetup()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Automatic Cost Posting", false);
        InventorySetup.Modify(true);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceInvoiceRequestPageHandler(var ServiceInvoice: TestRequestPage "Service - Invoice")
    begin
        ServiceInvoice.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceInvoiceRequestPageHandlerDataset(var ServiceInvoice: TestRequestPage "Service - Invoice")
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceLinesPageHandler(var ServiceLines: TestPage "Service Lines")
    begin
        ServiceLines.Post.Invoke();
        ServiceLines.OK().Invoke();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandler(Option: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 3;  // Supplying 3 to select Third Posting Option: Ship and Invoice for Service Order.
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure SignContractConfirmHandler(SignContractMessage: Text[1024]; var Result: Boolean)
    begin
        Result := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServContrctTemplateListHandler(var ServiceContractTemplateList: Page "Service Contract Template List"; var Response: Action)
    begin
        Response := ACTION::LookupOK;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessgeHandler(MessageTest: Text[1024])
    begin
        // Dummy Message Handler.
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ServiceLinesExistMessageHandler(MessageTest: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(MessageTest);
    end;
}

