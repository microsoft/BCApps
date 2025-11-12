// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Test;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Reporting;
using Microsoft.CRM.Team;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Service.Ledger;
using Microsoft.Service.Posting;
using Microsoft.Service.Pricing;
using Microsoft.Service.Setup;
using Microsoft.Utilities;
using System.Email;
using System.TestLibraries.Email;
using System.TestLibraries.Reflection;
using System.TestLibraries.Utilities;

codeunit 136108 "Service Posting - Invoice"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Service]
        isInitialized := false;
    end;

    var
        UnknownError: Label 'Unknown Error';
        WarningMsg: Label 'The field Automatic Cost Posting should not be set to Yes if field Use Legacy G/L Entry Locking in General Ledger Setup table is set to No because of possibility of deadlocks.';
        ExpectedMsg: Label 'Expected Cost Posting to G/L has been changed';
        ExpectedConfirm: Label 'If you change the Expected Cost Posting to G/L';
        UndoShipmentConfirm: Label 'Do you want to undo the selected shipment line(s)?';
        Assert: Codeunit Assert;
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryResource: Codeunit "Library - Resource";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        OrderNotExist: Label 'Service Order must not exist.';
        BaseAmountError: Label 'Base Amount must be %1';
        AmountsMustMatchError: Label '%1 must be %2 in %3.';
        PostingDateBlankError: Label 'Enter the posting date.';
        ConfirmCreateEmptyPostedInvMsg: Label 'Deleting this document will cause a gap in the number series for posted invoices. An empty posted invoice %1 will be created', Comment = '%1 - Invoice No.';
        ReservationEntryNotFoundErr: Label 'Reservation Entry should be deleted.';

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure QuantityToInvoiceZero()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
        ServiceHeader2: Record "Service Header";
        Type: Option " ",Item,Resource,Both;
    begin
        // Covers document number TC-PP-I-1 - refer to TFS ID 20887
        // The test case checks that on posting Service Order the application generates an error when Qty. to Invoice is zero.

        // 1 Setup: Setup Automatic Cost Posting as FALSE and Expected Cost Posting to G/L as FALSE on Inventory Setup.
        // Create Two Service Orders - Service Item, Service Header, Service Line with Type as Item, Resource and Cost.
        Initialize();
        ModifyCostPostngInventorySetup(false, false);
        CreateServiceOrder(ServiceHeader, ServiceItemLine, ServiceLine, ServiceItem, Type::Item);

        LibraryService.CreateServiceHeader(ServiceHeader2, ServiceHeader2."Document Type"::Order, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader2, ServiceItem."No.");
        CreateServiceLineWithResource(ServiceLine, ServiceHeader2, ServiceItem."No.");
        CreateServiceLineWithCost(ServiceLine, ServiceHeader2, ServiceItem."No.");

        // 2. Exercise: Post both Service Orders as Ship and modify Qty. to Invoice as zero on Service Line.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        LibraryService.PostServiceOrder(ServiceHeader2, true, false, false);
        ModifyQtyToInvoiceZero(ServiceHeader."No.");
        ModifyQtyToInvoiceZero(ServiceHeader2."No.");

        // 3. Verify: Check that on posting Service Order the application generates an error when Qty. to Invoice is zero on
        // both Service Orders.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        Assert.AreEqual(StrSubstNo(DocumentErrorsMgt.GetNothingToPostErrorMsg()), GetLastErrorText, UnknownError);
        asserterror LibraryService.PostServiceOrder(ServiceHeader2, true, false, false);
        Assert.AreEqual(StrSubstNo(DocumentErrorsMgt.GetNothingToPostErrorMsg()), GetLastErrorText, UnknownError);
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure PostLineByLine()
    var
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceLine2: Record "Service Line";
        ServiceHeader: Record "Service Header";
        ServiceHeader2: Record "Service Header";
        Type: Option " ",Item,Resource,Both;
    begin
        // Covers document number TC-PP-I-2 - refer to TFS ID 20887.
        // The test case checks posting of lines one at a time.

        // 1. Setup: Setup Automatic Cost Posting as FALSE and Expected Cost Posting to G/L as FALSE on Inventory Setup.
        // Create Two Service Order - Service Item, Service Header, Service Line with Type as Item, Resource, Cost and G/L Account.
        Initialize();
        ModifyCostPostngInventorySetup(false, false);
        CreateServiceOrder(ServiceHeader, ServiceItemLine, ServiceLine, ServiceItem, Type::Item);

        LibraryService.CreateServiceHeader(ServiceHeader2, ServiceHeader2."Document Type"::Order, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader2, ServiceItem."No.");
        CreateServiceLineWithResource(ServiceLine2, ServiceHeader2, ServiceItem."No.");
        CreateServiceLineWithCost(ServiceLine2, ServiceHeader2, ServiceItem."No.");
        CreateServiceLineWithGLAccount(ServiceLine2, ServiceHeader2, ServiceItem."No.");

        // 2. Exercise: Post both Service Order as Ship and Invoice Line by Line.
        PostServiceOrderLinebyLine(ServiceHeader);
        PostServiceOrderLinebyLine(ServiceHeader2);

        // 3. Verify: Check Item Ledger Entry, Values Entries, Service Ledger Entry after posting Line by Line.
        VerifyOrderItemLedgerEntry(ServiceLine);
        VerifyServiceOrderValueEntry(ServiceHeader."No.");
        VerifyServiceLedgerEntry(ServiceHeader."No.", ServiceHeader."Customer No.");
        VerifyServiceLedgerEntry(ServiceHeader2."No.", ServiceHeader2."Customer No.");
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure PostServInvoiceWithAllowPostingPeriod()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        Type: Option ,Item,Resource,Both;
    begin
        // 1 Setup: Setup Automatic Cost Posting as FALSE and Expected Cost Posting to G/L as FALSE on Inventory Setup.
        Initialize();
        ModifyCostPostngInventorySetup(false, false);
        LibraryERM.SetAllowPostingFromTo(WorkDate(), WorkDate());

        // 2. Exercise: Post Service Order with two line, one with blank Type and Posting Date.
        CreateServiceOrder(ServiceHeader, ServiceItemLine, ServiceLine, ServiceItem, Type::Item);
        CreateEmptyServiceLine(ServiceHeader);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Check Service Order is posted.
        VerifyPostedServiceOrder(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure ShippedQuantityZero()
    var
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
        Type: Option " ",Item,Resource,Both;
    begin
        // Covers document number TC-PP-I-3 - refer to TFS ID 20887.
        // The test case checks that on posting the Service Order the application generates an error if Quantity Shipped is Zero.

        // 1. Setup: Setup Automatic Cost Posting as FALSE and Expected Cost Posting to G/L as FALSE on Inventory Setup.
        Initialize();
        ModifyCostPostngInventorySetup(false, false);

        // 2. Exercise: Create Service Order - Service Item, Service Header, Service Line with Type Item, Resource, Cost and G/L Account.
        CreateServiceOrder(ServiceHeader, ServiceItemLine, ServiceLine, ServiceItem, Type::Both);

        // 3. Verify: Check that on posting the Service Order the application generates an error if Quantity Shipped is Zero.
        VerifyQtyShippedOnServiceLine(ServiceHeader."No.");
        asserterror LibraryService.PostServiceOrder(ServiceHeader, false, false, true);
        Assert.AreEqual(StrSubstNo(DocumentErrorsMgt.GetNothingToPostErrorMsg()), GetLastErrorText, UnknownError);
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure ShipPartInvoiceManual()
    var
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-PP-I-4 - refer to TFS ID 20887.
        // The test case checks posting with full shipment and partial invoice with Manual cost posting with Type as Item.

        // Setup: Setup Automatic Cost Posting and Expected Cost Posting to G/L as parameter passed in Inventory Setup.
        ShipPartInvoice(ServiceHeader, ServiceLine, false, false);

        // Verify: Check G/L Entries, Item Ledger Entry and Service Ledger Entry created after posting.
        VerifyServiceOrderGLEntry(ServiceHeader."No.");
        VerifyOrderItemLedgerEntry(ServiceLine);
        VerifyServiceLedgerEntry(ServiceHeader."No.", ServiceHeader."Customer No.");
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure ShipPartInvoiceAutoExpected()
    var
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-PP-I-4 - refer to TFS ID 20887.
        // The test case check posting with full shipment and partial invoice with Automatic and Expected Cost Posting as TRUE with Type as
        // Item.

        // Setup: Setup Automatic Cost Posting and Expected Cost Posting to G/L as parameter passed in Inventory Setup.
        ShipPartInvoice(ServiceHeader, ServiceLine, true, true);

        // Verify: Check Item Ledger Entry, VAT Entries, Value Entries, Detailed Cust. Ledger Entry and Service Ledger Entry.
        VerifyOrderItemLedgerEntry(ServiceLine);
        VerifyServiceOrderVATEntry(ServiceHeader."No.");
        VerifyServiceOrderValueEntry(ServiceHeader."No.");
        VerifyDetailedCustLedgerEntry(ServiceHeader."No.", CalculateTotlAmountShippedLine(ServiceHeader."No."));
        VerifyServiceLedgerEntry(ServiceHeader."No.", ServiceHeader."Customer No.");
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure ShipPartInvoiceAuto()
    var
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-PP-I-4 - refer to TFS ID 20887.
        // The test case checks posting with full shipment and partial invoice with Automatic Cost Posting with Type as Item.

        // Setup: Setup Automatic Cost Posting and Expected Cost Posting to G/L as parameter passed in Inventory Setup.
        ShipPartInvoice(ServiceHeader, ServiceLine, true, false);

        // Verify: Check G/L Entries, Item Ledger Entry, Detail Cust. Ledger Entry, Value Entries after posting.
        VerifyServiceOrderGLEntry(ServiceHeader."No.");
        VerifyOrderItemLedgerEntry(ServiceLine);
        VerifyDetailedCustLedgerEntry(ServiceHeader."No.", CalculateTotlAmountShippedLine(ServiceHeader."No."));
        VerifyServiceOrderValueEntry(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure ShipPartInvoiceExpected()
    var
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-PP-I-4 - refer to TFS ID 20887.
        // The test case checks posting with full shipment and partial invoice with Expected Cost Posting with Type as Item.

        // Setup: Setup Automatic Cost Posting and Expected Cost Posting to G/L as parameter passed in Inventory Setup.
        ShipPartInvoice(ServiceHeader, ServiceLine, false, true);

        // Verify: Check Item Ledger Entry, Detailed Cust. Ledger Entry, Value Entry, Service Ledger Entry after posting.
        VerifyOrderItemLedgerEntry(ServiceLine);
        VerifyDetailedCustLedgerEntry(ServiceHeader."No.", CalculateTotlAmountShippedLine(ServiceHeader."No."));
        VerifyServiceOrderValueEntry(ServiceHeader."No.");
        VerifyServiceLedgerEntry(ServiceHeader."No.", ServiceHeader."Customer No.");
    end;

    local procedure ShipPartInvoice(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; AutomaticCostPosting: Boolean; ExpectedCostPosting: Boolean)
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        Type: Option ,Item,Resource,Both;
    begin
        // Setup: Setup Automatic Cost Posting as FALSE and Expected Cost Posting to G/L as FALSE on Inventory Setup,
        // Create Service Order - Service Item, Service Header, Service Line with Type as Item and Post with Ship Option.
        Initialize();
        ModifyCostPostngInventorySetup(AutomaticCostPosting, ExpectedCostPosting);
        CreateServiceOrder(ServiceHeader, ServiceItemLine, ServiceLine, ServiceItem, Type::Item);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // Exercise: Modify Qty. to Invoice field on Service Line and Post as Invoice.
        ModifyQtyToInvoiceServiceLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, false, false, true);
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure ShipInvoiceResourceManual()
    var
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
        Type: Option " ",Item,Resource,Both;
    begin
        // Covers document number TC-PP-I-5 - refer to TFS ID 20887.
        // The test case checks posting with full shipment and full invoice with Manual cost posting with type as Resource, Cost
        // and G/L Account.

        // 1. Setup: Setup Automatic Cost Posting as FALSE and Expected Cost Posting to G/L as FALSE on Inventory Setup,
        // Create Service Order - Service Item, Service Header, Service Line with Type as Resource, Cost and G/L Account.
        Initialize();
        ModifyCostPostngInventorySetup(false, false);
        CreateServiceOrder(ServiceHeader, ServiceItemLine, ServiceLine, ServiceItem, Type::Both);

        // 2. Exercise: Post Service Order as Ship and Invoice.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Check Quantity on Service Shipment Line. Check Service Ledger Entry, G/L Entry, Detailed Cust. Ledger Entry
        // and Resource Ledger Entry after posting.
        VerifyQtyOnServiceShipmentLine(ServiceHeader."No.");
        VerifyServiceLedgerEntry(ServiceHeader."No.", ServiceHeader."Customer No.");
        VerifyServiceOrderGLEntry(ServiceHeader."No.");
        VerifyDetailedCustLedgerEntry(ServiceHeader."No.", CalculateTotlAmountShippedLine(ServiceHeader."No."));
        VerifyResourceLedgerEntry(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure InvoiceResourceManual()
    var
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
        Type: Option " ",Item,Resource,Both;
    begin
        // Covers document number TC-PP-I-6 - refer to TFS ID 20887.
        // The test checks posting with invoice with Manual Cost Posting with type as Resource, Cost and G/L Account.

        // 1. Setup: Setup Automatic Cost Posting as FALSE and Expected Cost Posting to G/L as FALSE on Inventory Setup,
        // Create Service Order - Service Item, Service Header, Service Line with Type as Resource, Cost and G/L Account,
        // Post Service Order as Ship.
        Initialize();
        ModifyCostPostngInventorySetup(false, false);
        CreateServiceOrder(ServiceHeader, ServiceItemLine, ServiceLine, ServiceItem, Type::Both);

        PostSrvOrderAsShipForResource(ServiceHeader);
        PostOrderAsShipForItemGLAccont(ServiceHeader);

        // 2. Exercise: Modify "Qty. to Invoice" on Service Line and Post as Invoice.
        ModifyQtyToInvoiceServiceLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, false, false, true);

        // 3. Verify: Check Service Ledger Entry, Customer Ledger Entry, Resource Ledger Entry, Detailed Cust. Ledger Entry after
        // posting.
        VerifyServiceLedgerEntry(ServiceHeader."No.", ServiceHeader."Customer No.");
        VerifyCustomerLedgerEntry(ServiceHeader."No.");
        VerifyResourceLedgerEntry(ServiceHeader."No.");
        VerifyDetailedCustLedgerEntry(ServiceHeader."No.", CalculateTotlAmountShippedLine(ServiceHeader."No."));
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure OrderDeletionFullInvoiceItem()
    var
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
        Type: Option " ",Item,Resource,Both;
    begin
        // Covers document number TC-PP-I-7 - refer to TFS ID 20887.
        // The test case checks order deletion after posting with full invoice with no cost posting with Type as Item.

        // 1. Setup: Setup Automatic Cost Posting as FALSE and Expected Cost Posting to G/L as FALSE on Inventory Setup,
        // Create Service Order - Service Item, Service Header, Service Line with Type as Item and Post as Ship.
        Initialize();
        ModifyCostPostngInventorySetup(false, false);
        CreateServiceOrder(ServiceHeader, ServiceItemLine, ServiceLine, ServiceItem, Type::Item);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 2. Exercise: Modify Qty. to Invoice field on Service Line and Post as Invoice.
        ValidateQtyToInvoiceServicLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, false, false, true);

        // 3. Verify: Check Service Ledger Entry, Item Ledger Entry, Value Entry, Customer Ledger Entry, Detailed Cust. Ledger Entry after
        // posting and Check that the Service Order does not exist.
        VerifyServiceLedgerEntry(ServiceHeader."No.", ServiceHeader."Customer No.");
        VerifyOrderItemLedgerEntry(ServiceLine);
        VerifyServiceOrderValueEntry(ServiceHeader."No.");
        VerifyCustomerLedgerEntry(ServiceHeader."No.");
        VerifyDetailedCustLedgerEntry(ServiceHeader."No.", CalculateTotlAmountShippedLine(ServiceHeader."No."));
        Assert.IsFalse(ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No."), OrderNotExist);
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure OrderDeletionFullInvoiceManual()
    var
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-PP-I-8 - refer to TFS ID 20887.
        // The test case checks order deletion after posting with full invoice with manual cost posting with Type as Item.

        // Setup: Setup Automatic Cost Posting and Expected Cost Posting to G/L as parameter passed in Inventory Setup.
        OrderDeletionFullInvoice(ServiceHeader, ServiceLine, false, false);

        // Verify: Check that Service Order not exist after Post Ship and Invoice and Service Ledger Entry, Value Entry for Valued
        // Quantity.
        Assert.IsFalse(ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No."), OrderNotExist);
        VerifyServiceLedgerEntry(ServiceHeader."No.", ServiceHeader."Customer No.");
        VerifyDetailedCustLedgerEntry(ServiceHeader."No.", CalculateTotlAmountShippedLine(ServiceHeader."No."));
        VerifyServiceOrderValueEntry(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure OrderDeletionFullInvoiceAutoEx()
    var
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-PP-I-8 - refer to TFS ID 20887.
        // The test case checks order deletion after posting with full invoice with both automatic and expected cost posting with Type as
        // Item.

        // Setup: Setup Automatic Cost Posting and Expected Cost Posting to G/L as parameter passed in Inventory Setup.
        OrderDeletionFullInvoice(ServiceHeader, ServiceLine, true, true);

        // Verify: Check that Service Order not exist after Post Ship and Invoice and Service Ledger Entry, Value Entry for Valued
        // Quantity.
        Assert.IsFalse(ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No."), OrderNotExist);
        VerifyOrderItemLedgerEntry(ServiceLine);
        VerifyDetailedCustLedgerEntry(ServiceHeader."No.", CalculateTotlAmountShippedLine(ServiceHeader."No."));
        VerifyServiceOrderValueEntry(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure OrderDeletionFullInvoiceAuto()
    var
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-PP-I-8 - refer to TFS ID 20887.
        // The test case checks order deletion after posting with full invoice with automatic cost posting with Type as Item.

        // Setup: Setup Automatic Cost Posting and Expected Cost Posting to G/L as parameter passed in Inventory Setup.
        OrderDeletionFullInvoice(ServiceHeader, ServiceLine, true, false);

        // Verify: Check that Service Order not exist after Post Ship and Invoice and Service Ledger Entry, Value Entry for Valued
        // Quantity.
        Assert.IsFalse(ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No."), OrderNotExist);
        VerifyOrderItemLedgerEntry(ServiceLine);
        VerifyDetailedCustLedgerEntry(ServiceHeader."No.", CalculateTotlAmountShippedLine(ServiceHeader."No."));
        VerifyServiceOrderValueEntry(ServiceHeader."No.");
        VerifyCustomerLedgerEntry(ServiceHeader."No.");
        VerifyServiceOrderGLEntry(ServiceHeader."No.");
    end;

    local procedure OrderDeletionFullInvoice(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; AutomaticCostPosting: Boolean; ExpectedCostPosting: Boolean)
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        Type: Option " ",Item,Resource,Both;
    begin
        // Setup: Modify Inventory Setup, Create Service Order, Service Line with Type Item and Modify Qty. to Invoice field
        // on Service Line.
        Initialize();
        ModifyCostPostngInventorySetup(AutomaticCostPosting, ExpectedCostPosting);
        CreateServiceOrder(ServiceHeader, ServiceItemLine, ServiceLine, ServiceItem, Type::Item);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        ModifyQtyToInvoiceServiceLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, false, false, true);

        // Exercise: Post Service Order with Invoice.
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, false, false, true);
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure OrderDeletionShipInvoiceManual()
    var
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-PP-I-9 - refer to TFS ID 20887.
        // The test case checks order deletion after posting with full ship and invoice with manual cost posting with Type as Item.

        // Setup: Setup Automatic Cost Posting and Expected Cost Posting to G/L as parameter passed in Inventory Setup.
        OrderDeletionShipInvoice(ServiceHeader, ServiceLine, false, false);
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure OrderDeletionShipInvoiceAutoEx()
    var
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-PP-I-9 - refer to TFS ID 20887.
        // The test case checks order deletion after posting with full ship and invoice with automatic and expected cost posting with Type
        // as Item.

        // Setup: Setup Automatic Cost Posting and Expected Cost Posting to G/L as parameter passed in Inventory Setup.
        OrderDeletionShipInvoice(ServiceHeader, ServiceLine, true, true);
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure OrderDeletionShipInvoiceAuto()
    var
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-PP-I-9 - refer to TFS ID 20887.
        // The test case checks order deletion after posting with full ship and invoice with automatic cost posting with Type as Item.

        // Setup: Setup Automatic Cost Posting and Expected Cost Posting to G/L as parameter passed in Inventory Setup.
        OrderDeletionShipInvoice(ServiceHeader, ServiceLine, true, false);
    end;

    local procedure OrderDeletionShipInvoice(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; AutomaticCostPosting: Boolean; ExpectedCostPosting: Boolean)
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        Type: Option " ",Item,Resource,Both;
    begin
        // Setup: Modify Inventory Setup, Create Service Order, Service Line with Type Item and Modify Qty. to Invoice field
        // on Service Line.
        Initialize();
        ModifyCostPostngInventorySetup(AutomaticCostPosting, ExpectedCostPosting);
        CreateServiceOrder(ServiceHeader, ServiceItemLine, ServiceLine, ServiceItem, Type::Item);

        // Exercise: Post Service Order with Ship and Invoice.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // Verify: Check that Service Order not exist after Post Ship and Invoice and Service Ledger Entry, Customer Ledger Entry,
        // Detailed Cust. Ledger Entry, Value Entry for Valued Quantity.
        Assert.IsFalse(ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No."), OrderNotExist);
        VerifyOrderItemLedgerEntry(ServiceLine);
        VerifyServiceLedgerEntry(ServiceHeader."No.", ServiceHeader."Customer No.");
        VerifyServiceOrderGLEntry(ServiceHeader."No.");
        VerifyCustomerLedgerEntry(ServiceHeader."No.");
        VerifyDetailedCustLedgerEntry(ServiceHeader."No.", CalculateTotlAmountShippedLine(ServiceHeader."No."));
        VerifyServiceOrderValueEntry(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure ShipInvoiceQtyToInvoiceZero()
    var
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
        Type: Option " ",Item,Resource,Both;
    begin
        // Covers document number TC-PP-I-10 - refer to TFS ID 20887.
        // The test case checks posting with full Ship with Qty. to Invoice zero and then invoice with type as Resource, Cost and G/L
        // Account.

        // 1. Setup: Modify Inventory Setup. Create Service Order - Service Line with Type as Item, Resource, Cost and G/L Account.
        Initialize();
        ModifyCostPostngInventorySetup(false, false);
        CreateServiceOrder(ServiceHeader, ServiceItemLine, ServiceLine, ServiceItem, Type::Both);

        ModifyQtyToInvoiceZero(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 2. Exercise: Modify Qty. to Invoice and Post Service Order as Invoice.
        ModifyQtyToInvoiceServiceLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, false, false, true);
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, false, false, true);

        // 3. Verify: Check that Service Order not Exist and Entries for Service Ledger Entry, Customer Ledger Entry, Detailed Cust.
        // Ledger Entry and Resource Ledger Entry.
        Assert.IsFalse(ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No."), OrderNotExist);
        VerifyServiceLedgerEntry(ServiceHeader."No.", ServiceHeader."Customer No.");
        VerifyServiceOrderGLEntry(ServiceHeader."No.");
        VerifyDetailedCustLedgerEntry(ServiceHeader."No.", CalculateTotlAmountShippedLine(ServiceHeader."No."));
        VerifyResourceLedgerEntry(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure ShipTwiceFullInvoice()
    var
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
        Type: Option " ",Item,Resource,Both;
    begin
        // Covers document number TC-PP-I-12 - refer to TFS ID 20887.
        // The test case checks posting with ship partially in two parts and then Invoice with type as Resource, Cost and G/L Account.

        // 1. Setup: Modify Inventory Setup. Create Service Order - Service Line with Type as Item, Resource, Cost and G/L Account.
        Initialize();
        ModifyCostPostngInventorySetup(false, false);
        CreateServiceOrder(ServiceHeader, ServiceItemLine, ServiceLine, ServiceItem, Type::Resource);

        ModifyQtyToShipOnServiceLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        ModifyQtyToShipOnServiceLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 2. Exercise: Modify Qty. to Invoice and Post Service Order as Invoice.
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, false, false, true);

        // 3. Verify: Check that Service Order Entries after partial ship for Service Ledger Entry, Customer Ledger Entry,
        // Detailed Cust. Ledger Entry, VAT Entry and Resource Ledger Entry.
        VerifyServiceLedgerEntry(ServiceHeader."No.", ServiceHeader."Customer No.");
        VerifyServiceOrderGLEntry(ServiceHeader."No.");
        VerifyServiceOrderVATEntry(ServiceHeader."No.");
        VerifyDetailedCustLedgerEntry(ServiceHeader."No.", CalculateTotlAmountShippedLine(ServiceHeader."No."));
        VerifyResourceLedgerEntry(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure ShipTwiceInvoiceManual()
    var
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-PP-I-13 - refer to TFS ID 20887.
        // The test case checks posting with ship partially in two parts and then Invoice with manual cost posting with Type as Item.

        // Setup: Setup Automatic Cost Posting and Expected Cost Posting to G/L as parameter passed in Inventory Setup.
        ShipTwiceInvoice(ServiceHeader, ServiceLine, false, false);

        // Verify: Check that Service Order Entries after partial ship for Service Ledger Entry, GL Entry,
        // and Values entry for valued Quantity.
        VerifyServiceLedgerEntry(ServiceHeader."No.", ServiceHeader."Customer No.");
        VerifyServiceOrderValueEntry(ServiceHeader."No.");
        VerifyDetailedCustLedgerEntry(ServiceHeader."No.", CalculateTotlAmountShippedLine(ServiceHeader."No."));
        VerifyServiceOrderGLEntry(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure ShipTwiceInvoiceAutoExpected()
    var
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-PP-I-13 - refer to TFS ID 20887.
        // The test case checks posting with ship partially in two parts and then Invoice with automatic and expected cost posting with Type
        // as Item.

        // Setup: Setup Automatic Cost Posting and Expected Cost Posting to G/L as parameter passed in Inventory Setup.
        ShipTwiceInvoice(ServiceHeader, ServiceLine, true, true);

        // Verify: Check that Service Order Entries after partial ship for Service Ledger Entry, GL Entry,
        // and Values entry for valued Quantity.
        VerifyServiceLedgerEntry(ServiceHeader."No.", ServiceHeader."Customer No.");
        VerifyServiceOrderValueEntry(ServiceHeader."No.");
        VerifyServiceOrderGLEntry(ServiceHeader."No.");
        VerifyDetailedCustLedgerEntry(ServiceHeader."No.", CalculateTotlAmountShippedLine(ServiceHeader."No."));
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure ShipTwiceInvoiceAuto()
    var
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-PP-I-13 - refer to TFS ID 20887.
        // The test case checks posting with ship partially in two parts and then Invoice with automatic cost posting with Type as Item.

        // Setup: Setup Automatic Cost Posting and Expected Cost Posting to G/L as parameter passed in Inventory Setup.
        ShipTwiceInvoice(ServiceHeader, ServiceLine, true, false);

        // Verify: Check that Service Order Entries after partial ship for Service Ledger Entry, GL Entry,
        // and Values entry for valued Quantity.
        VerifyServiceLedgerEntry(ServiceHeader."No.", ServiceHeader."Customer No.");
        VerifyServiceOrderValueEntry(ServiceHeader."No.");
        VerifyServiceOrderGLEntry(ServiceHeader."No.");
        VerifyDetailedCustLedgerEntry(ServiceHeader."No.", CalculateTotlAmountShippedLine(ServiceHeader."No."));
        VerifyCustomerLedgerEntry(ServiceHeader."No.");
    end;

    local procedure ShipTwiceInvoice(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; AutomaticCostPosting: Boolean; ExpectedCostPosting: Boolean)
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        Type: Option " ",Item,Resource,Both;
    begin
        // Setup: Modify Inventory Setup. Create Service Order - Service Line with Type as Item, Modify Qty. to Ship
        // and Post partially as Ship.
        Initialize();
        ModifyCostPostngInventorySetup(AutomaticCostPosting, ExpectedCostPosting);
        CreateServiceOrder(ServiceHeader, ServiceItemLine, ServiceLine, ServiceItem, Type::Item);

        ModifyQtyToShipOnServiceLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        ModifyQtyToShipOnServiceLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // Exercise: Modify Qty. to Invoice and Post Service Order as Invoice.
        ModifyQtyToInvoiceServiceLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, false, false, true);
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure ShipTwiceInvoiceResource()
    var
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
        Type: Option " ",Item,Resource,Both;
    begin
        // Covers document number TC-PP-I-14 - refer to TFS ID 20887.
        // The test case checks posting with ship partially in two parts and then Invoice with manual cost posting with Type as Resource,
        // Cost and G/L Account.

        // 1. Setup: Modify Inventory Setup. Create Service Order - Service Line with Type as Item, Modify Qty. to Ship
        // and Post partially as Ship.
        Initialize();
        ModifyCostPostngInventorySetup(false, false);
        CreateServiceOrder(ServiceHeader, ServiceItemLine, ServiceLine, ServiceItem, Type::Resource);

        ModifyQtyToShipOnServiceLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        ModifyQtyToShipOnServiceLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 2. Exercise: Modify Qty. to Invoice and Post Service Order as Invoice.
        ModifyQtyToShipOnServiceLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, false, false, true);

        // 3. Verify: Check that Service Order Entries after partial ship for Service Ledger Entry, GL Entry,
        // Detailed Customer Ledger Entry, Customer Ledger Entry and Resource Ledger Entry.
        VerifyServiceLedgerEntry(ServiceHeader."No.", ServiceHeader."Customer No.");
        VerifyServiceOrderGLEntry(ServiceHeader."No.");
        VerifyDetailedCustLedgerEntry(ServiceHeader."No.", CalculateTotlAmountShippedLine(ServiceHeader."No."));
        VerifyCustomerLedgerEntry(ServiceHeader."No.");
        VerifyResourceLedgerEntry(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure ShipFollowShipAndInvoiceManual()
    var
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-PP-I-15 - refer to TFS ID 20887.
        // The test case checks posting partially with ship and then again with ship and invoice with manual cost posting with Type as Item.

        // Setup: Setup Automatic Cost Posting and Expected Cost Posting to G/L as parameter passed in Inventory Setup.
        ShipFollowShipAndInvoice(ServiceHeader, ServiceLine, true, false);

        // Verify: Check that Service Order Entries created for Service Ledger Entry, GL Entry and Value entry for valued quantity.
        VerifyServiceLedgerEntry(ServiceHeader."No.", ServiceHeader."Customer No.");
        VerifyServiceOrderValueEntry(ServiceHeader."No.");
        VerifyServiceOrderGLEntry(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure ShipFollowShipAndInvoiceAutoEx()
    var
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-PP-I-15 - refer to TFS ID 20887.
        // The test case checks posting partially with ship and then again with ship and invoice with automatic and expected cost posting
        // with Type as Item.

        // Setup: Setup Automatic Cost Posting and Expected Cost Posting to G/L as parameter passed in Inventory Setup.
        ShipFollowShipAndInvoice(ServiceHeader, ServiceLine, true, false);

        // Verify: Check that Service Order Entries created for Service Ledger Entry, GL Entry, Detailed
        // Cust. Ledger Entry and Value entry for valued quantity.
        VerifyServiceLedgerEntry(ServiceHeader."No.", ServiceHeader."Customer No.");
        VerifyServiceOrderValueEntry(ServiceHeader."No.");
        VerifyServiceOrderGLEntry(ServiceHeader."No.");
        VerifyDetailedCustLedgerEntry(ServiceHeader."No.", CalculateTotlAmountShippedLine(ServiceHeader."No."));
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure ShipFollowShipAndInvoiceAuto()
    var
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-PP-I-15 - refer to TFS ID 20887.
        // The test case checks posting partially with ship and then again with ship and invoice with automatic cost posting with Type
        // as Item.

        // Setup: Setup Automatic Cost Posting and Expected Cost Posting to G/L as parameter passed in Inventory Setup.
        ShipFollowShipAndInvoice(ServiceHeader, ServiceLine, true, false);

        // Verify: Check that Service Order Entries created for Service Ledger Entry, Item Ledger Entry, GL Entry, Detailed
        // Cust. Ledger Entry, Customer Ledger Entry and Value entry for valued quantity.
        VerifyServiceLedgerEntry(ServiceHeader."No.", ServiceHeader."Customer No.");
        VerifyInvoiceQtyItemLedger(ServiceHeader."No.");
        VerifyServiceOrderValueEntry(ServiceHeader."No.");
        VerifyServiceOrderGLEntry(ServiceHeader."No.");
        VerifyDetailedCustLedgerEntry(ServiceHeader."No.", CalculateTotlAmountShippedLine(ServiceHeader."No."));
        VerifyCustomerLedgerEntry(ServiceHeader."No.");
    end;

    local procedure ShipFollowShipAndInvoice(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; AutomaticCostPosting: Boolean; ExpectedCostPosting: Boolean)
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        Type: Option " ",Item,Resource,Both;
    begin
        // Setup: Modify Inventory Setup. Create Service Order - Service Line with Type as Item, Modify Qty. to Ship
        // and Post partially as Ship.
        Initialize();
        ModifyCostPostngInventorySetup(AutomaticCostPosting, ExpectedCostPosting);
        CreateServiceOrder(ServiceHeader, ServiceItemLine, ServiceLine, ServiceItem, Type::Item);

        ModifyQtyToShipOnServiceLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // Exercise: Modify Qty. to ship and Qty. to Invoice and Post Service Order as Ship and Invoice.
        ModifyQtyToShipOnServiceLine(ServiceHeader."No.");
        ModifyQtyToInvoiceServiceLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure ShipFollowShipInvoiceResource()
    var
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
        Type: Option " ",Item,Resource,Both;
    begin
        // Covers document number TC-PP-I-16 - refer to TFS ID 20887.
        // The test case checks posting partially with ship and then again with ship and invoice with manual cost posting with Type as
        // Resource, Cost and G/L Account.

        // 1. Setup: Modify Inventory Setup. Create Service Order - Service Line with Type as Item, Modify Qty. to Ship
        // and Post partially as Ship.
        Initialize();
        ModifyCostPostngInventorySetup(false, false);
        CreateServiceOrder(ServiceHeader, ServiceItemLine, ServiceLine, ServiceItem, Type::Resource);

        ModifyQtyToShipOnServiceLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 2. Exercise: Modify Qty. to ship and Qty. to Invoice and Post Service Order as Ship and Invoice.
        ModifyQtyToShipOnServiceLine(ServiceHeader."No.");
        ModifyQtyToInvoiceServiceLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Check that Service Order Entries created for Service Ledger Entry, Item Ledger Entry, GL Entry, Detailed
        // Cust. Ledger Entry, Customer Ledger Entry.
        VerifyServiceLedgerEntry(ServiceHeader."No.", ServiceHeader."Customer No.");
        VerifyServiceOrderGLEntry(ServiceHeader."No.");
        VerifyDetailedCustLedgerEntry(ServiceHeader."No.", CalculateTotlAmountShippedLine(ServiceHeader."No."));
        VerifyCustomerLedgerEntry(ServiceHeader."No.");
        VerifyResourceLedgerEntry(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure ShipInvoiceTwiceResource()
    var
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
        Type: Option " ",Item,Resource,Both;
    begin
        // Covers document number TC-PP-I-17 - refer to TFS ID 20887.
        // The test case checks posting with ship and invoice partially in two parts with manual cost posting with Type as Resource,
        // Cost and G/L Account.

        // 1. Setup: Modify Inventory Setup. Create Service Order-Service Line with Type as Resource, Cost and G/L Account, Modify Qty.
        // to Ship and Post as Ship and Invoice.
        Initialize();
        ModifyCostPostngInventorySetup(false, false);
        CreateServiceOrder(ServiceHeader, ServiceItemLine, ServiceLine, ServiceItem, Type::Resource);
        ModifyQtyToShipOnServiceLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        ModifyQtyToInvoiceServiceLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, false, false, true);

        // 2. Exercise: Modify Qty. to Invoice and Post Service Order as Invoice.
        ModifyQtyToInvoiceServiceLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, false, false, true);

        // 3. Verify: Check that Service Order Entries created for Service Ledger Entry, VAT Entry, GL Entry, Detailed Cust. Ledger Entry,
        // Customer Ledger Entry, Resource Ledger Entry.
        VerifyServiceLedgerEntry(ServiceHeader."No.", ServiceHeader."Customer No.");
        VerifyServiceOrderVATEntry(ServiceHeader."No.");
        VerifyServiceOrderGLEntry(ServiceHeader."No.");
        VerifyDetailedCustLedgerEntry(ServiceHeader."No.", CalculateTotlAmountShippedLine(ServiceHeader."No."));
        VerifyCustomerLedgerEntry(ServiceHeader."No.");
        VerifyResourceLedgerEntry(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure ShipInvoiceTwiceItemManual()
    var
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-PP-I-18 - refer to TFS ID 20887.
        // The test case checks posting with ship and invoice partially in two parts with manual cost posting with Type as Item.

        // Setup: Setup Automatic Cost Posting and Expected Cost Posting to G/L as parameter passed in Inventory Setup.
        ShipInvoiceTwiceItem(ServiceHeader, ServiceLine, false, false);

        // Verify: Check that Service Order Entries created for Service Ledger Entry, Detailed Cust. Ledger Entry,
        // Item Ledger Entry, Customer Ledger Entry, Resource Ledger Entry and Value entry for valued quantity.
        VerifyServiceLedgerEntry(ServiceHeader."No.", ServiceHeader."Customer No.");
        VerifyInvoiceQtyItemLedger(ServiceHeader."No.");
        VerifyServiceOrderValueEntry(ServiceHeader."No.");
        VerifyDetailedCustLedgerEntry(ServiceHeader."No.", CalculateTotlAmountShippedLine(ServiceHeader."No."));
        VerifyCustomerLedgerEntry(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure ShipInvoiceTwiceAutoExpected()
    var
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-PP-I-18 - refer to TFS ID 20887.
        // The test case checks posting with ship and invoice partially in two parts with automatic and expected cost posting with
        // type as Item.

        // Setup: Setup Automatic Cost Posting and Expected Cost Posting to G/L as parameter passed in Inventory Setup.
        ShipInvoiceTwiceItem(ServiceHeader, ServiceLine, true, true);

        // Verify: Check that Service Order Entries created for Service Ledger Entry, VAT Entry, GL Entry, Detailed Cust. Ledger Entry,
        // Item Ledger Entry, Customer Ledger Entry, Resource Ledger Entry and Value entry for valued quantity.
        VerifyServiceLedgerEntry(ServiceHeader."No.", ServiceHeader."Customer No.");
        VerifyServiceOrderGLEntry(ServiceHeader."No.");
        VerifyInvoiceQtyItemLedger(ServiceHeader."No.");
        VerifyServiceOrderVATEntry(ServiceHeader."No.");
        VerifyServiceOrderValueEntry(ServiceHeader."No.");
        VerifyDetailedCustLedgerEntry(ServiceHeader."No.", CalculateTotlAmountShippedLine(ServiceHeader."No."));
        VerifyCustomerLedgerEntry(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure ShipInvoiceTwiceAuto()
    var
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-PP-I-18 - refer to TFS ID 20887.
        // The test case checks posting with ship and invoice partially in two parts with automatic cost posting with Type as Item.

        // Setup: Setup Automatic Cost Posting and Expected Cost Posting to G/L as parameter passed in Inventory Setup.
        ShipInvoiceTwiceItem(ServiceHeader, ServiceLine, true, false);

        // Verify: Check that Service Order Entries created for Service Ledger Entry, VAT Entry, Detailed Cust. Ledger Entry,
        // Item Ledger Entry, Customer Ledger Entry and Value entry for valued quantity.
        VerifyServiceLedgerEntry(ServiceHeader."No.", ServiceHeader."Customer No.");
        VerifyInvoiceQtyItemLedger(ServiceHeader."No.");
        VerifyServiceOrderVATEntry(ServiceHeader."No.");
        VerifyServiceOrderValueEntry(ServiceHeader."No.");
        VerifyDetailedCustLedgerEntry(ServiceHeader."No.", CalculateTotlAmountShippedLine(ServiceHeader."No."));
        VerifyCustomerLedgerEntry(ServiceHeader."No.");
    end;

    local procedure ShipInvoiceTwiceItem(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; AutomaticCostPosting: Boolean; ExpectedCostPosting: Boolean)
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        Type: Option " ",Item,Resource,Both;
    begin
        // Setup: Modify Inventory Setup. Create Service Order-Service Line with Type as Item and Post as Ship and Modify Qty. to Invoice
        // Post with Invoice.
        Initialize();
        ModifyCostPostngInventorySetup(AutomaticCostPosting, ExpectedCostPosting);
        CreateServiceOrder(ServiceHeader, ServiceItemLine, ServiceLine, ServiceItem, Type::Item);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        ModifyQtyToInvoiceServiceLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, false, false, true);

        // Exercise: Modify Qty. to Invoice and Post Service Order as Invoice.
        ModifyQtyToInvoiceServiceLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, false, false, true);
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure ShipAndInvoiceTwiceResource()
    var
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-PP-I-19 - refer to TFS ID 20887.
        // The test case checks posting with ship and invoice partially in two parts with manual cost posting with Type as
        // Resource, Cost and G/L Account.

        // 1. Setup: Setup Automatic Cost Posting and Expected Cost Posting to G/L as parameter passed in Inventory Setup.
        ShipAndInvoiceTwice(ServiceHeader, ServiceLine, false, false);

        // 2. Exercise: Modify Qty. to Invoice and Post Service Order as Invoice.
        ModifyQtyToInvoiceServiceLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, false, false, true);

        // 3. Verify: Check that Service Order Entries created for Service Ledger Entry, VAT Entry, GL Entry, Detailed Cust. Ledger Entry,
        // Customer Ledger Entry, Resource Ledger Entry.
        VerifyServiceLedgerEntry(ServiceHeader."No.", ServiceHeader."Customer No.");
        VerifyServiceOrderVATEntry(ServiceHeader."No.");
        VerifyServiceOrderGLEntry(ServiceHeader."No.");
        VerifyDetailedCustLedgerEntry(ServiceHeader."No.", CalculateTotlAmountShippedLine(ServiceHeader."No."));
        VerifyCustomerLedgerEntry(ServiceHeader."No.");
        VerifyResourceLedgerEntry(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure ShipAndInvoiceTwiceManual()
    var
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-PP-I-20 - refer to TFS ID 20887.
        // The test case checks posting with partial ship and invoice partially in two parts with manual cost posting with Type as
        // Resource, Cost and G/L Account.

        // 1. Setup: Setup Automatic Cost Posting and Expected Cost Posting to G/L as parameter passed in Inventory Setup.
        ShipAndInvoiceTwice(ServiceHeader, ServiceLine, true, true);

        // 2. Exercise: Modify Qty. to Ship and Qty. to Invoice and Post Service Order as Ship and Invoice.
        ModifyQtyToShipOnServiceLine(ServiceHeader."No.");
        ModifyQtyToInvoiceServiceLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Check that Service Order Entries created for Service Ledger Entry, VAT Entry, GL Entry, Detailed Cust. Ledger Entry,
        // Customer Ledger Entry, Resource Ledger Entry.
        VerifyServiceLedgerEntry(ServiceHeader."No.", ServiceHeader."Customer No.");
        VerifyServiceOrderVATEntry(ServiceHeader."No.");
        VerifyServiceOrderGLEntry(ServiceHeader."No.");
        VerifyDetailedCustLedgerEntry(ServiceHeader."No.", CalculateTotlAmountShippedLine(ServiceHeader."No."));
        VerifyCustomerLedgerEntry(ServiceHeader."No.");
        VerifyResourceLedgerEntry(ServiceHeader."No.");
    end;

    local procedure ShipAndInvoiceTwice(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; AutomaticCostPosting: Boolean; ExpectedCostPosting: Boolean)
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        Type: Option " ",Item,Resource,Both;
    begin
        // Setup: Modify Inventory Setup. Create Service Order-Service Line with Type as Resource, Cost and G/L Account, Modify Qty. to
        // Ship and Post partially as Ship and Invoice.
        Initialize();
        ModifyCostPostngInventorySetup(AutomaticCostPosting, ExpectedCostPosting);
        CreateServiceOrder(ServiceHeader, ServiceItemLine, ServiceLine, ServiceItem, Type::Resource);
        ModifyQtyToShipOnServiceLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        ModifyQtyToInvoiceServiceLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, false, false, true);
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure FullShipAndInvoiceTwiceManual()
    var
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-PP-I-21 - refer to TFS ID 20887.
        // The test case checks posting with partial ship and invoice partially in two parts with manual cost posting with Type as Resource,
        // Cost and G/L Account.

        // 1. Setup: Setup Automatic Cost Posting and Expected Cost Posting to G/L as parameter passed in Inventory Setup.
        ShipAndInvoiceTwice(ServiceHeader, ServiceLine, true, false);

        // 2. Exercise: Modify Qty. to Ship and Post Service Order as Ship and Invoice.
        ModifyQtyToShipOnServiceLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Check that Service Order Entries created for Service Ledger Entry, VAT Entry, GL Entry, Detailed Cust. Ledger Entry,
        // Customer Ledger Entry, Resource Ledger Entry.
        VerifyServiceLedgerEntry(ServiceHeader."No.", ServiceHeader."Customer No.");
        VerifyServiceOrderVATEntry(ServiceHeader."No.");
        VerifyServiceOrderGLEntry(ServiceHeader."No.");
        VerifyDetailedCustLedgerEntry(ServiceHeader."No.", CalculateTotlAmountShippedLine(ServiceHeader."No."));
        VerifyCustomerLedgerEntry(ServiceHeader."No.");
        VerifyResourceLedgerEntry(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure AutoShipPartialInvoiceItem()
    var
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-PP-I-22 - refer to TFS ID 20887.
        // The test case checks posting with ship and invoice and then again invoice with manual cost posting with Type as Item.

        // Setup: Setup Automatic Cost Posting and Expected Cost Posting to G/L as parameter passed in Inventory Setup.
        AutoShipPartialInvoice(ServiceHeader, ServiceLine, false, false);

        // Verify: Check that Service Order Entries created for Service Ledger Entry, Detailed Cust. Ledger Entry,
        // Item Ledger Entry, Customer Ledger Entry and Value entry for valued quantity.
        VerifyServiceLedgerEntry(ServiceHeader."No.", ServiceHeader."Customer No.");
        VerifyInvoiceQtyItemLedger(ServiceHeader."No.");
        VerifyServiceOrderValueEntry(ServiceHeader."No.");
        VerifyDetailedCustLedgerEntry(ServiceHeader."No.", CalculateTotlAmountShippedLine(ServiceHeader."No."));
        VerifyCustomerLedgerEntry(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure AutoShipPartialInvoiceAutoEx()
    var
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-PP-I-22 - refer to TFS ID 20887.
        // The test case checks posting with ship and invoice and then again invoice with automatic and expected cost posting
        // with Type as Item.

        // Setup: Setup Automatic Cost Posting and Expected Cost Posting to G/L as parameter passed in Inventory Setup.
        AutoShipPartialInvoice(ServiceHeader, ServiceLine, true, true);

        // Verify: Check that Service Order Entries created for Service Ledger Entry, VAT Entry, Detailed Cust. Ledger Entry,
        // Item Ledger Entry, GL Entry, Customer Ledger Entry and Value entry for valued quantity.
        VerifyServiceLedgerEntry(ServiceHeader."No.", ServiceHeader."Customer No.");
        VerifyInvoiceQtyItemLedger(ServiceHeader."No.");
        VerifyServiceOrderGLEntry(ServiceHeader."No.");
        VerifyServiceOrderVATEntry(ServiceHeader."No.");
        VerifyServiceOrderValueEntry(ServiceHeader."No.");
        VerifyDetailedCustLedgerEntry(ServiceHeader."No.", CalculateTotlAmountShippedLine(ServiceHeader."No."));
        VerifyCustomerLedgerEntry(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure AutoShipPartialInvoiceAuto()
    var
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-PP-I-22 - refer to TFS ID 20887.
        // The test case checks posting with ship and invoice and then again invoice with automatic cost posting with Type as Item.

        // Setup: Setup Automatic Cost Posting and Expected Cost Posting to G/L as parameter passed in Inventory Setup.
        AutoShipPartialInvoice(ServiceHeader, ServiceLine, true, false);

        // Verify: Check that Service Order Entries created for Service Ledger Entry, VAT Entry, Detailed Cust. Ledger Entry,
        // Item Ledger Entry, GL Entry, Customer Ledger Entry and Value entry for valued quantity.
        VerifyServiceLedgerEntry(ServiceHeader."No.", ServiceHeader."Customer No.");
        VerifyInvoiceQtyItemLedger(ServiceHeader."No.");
        VerifyServiceOrderGLEntry(ServiceHeader."No.");
        VerifyServiceOrderVATEntry(ServiceHeader."No.");
        VerifyServiceOrderValueEntry(ServiceHeader."No.");
        VerifyDetailedCustLedgerEntry(ServiceHeader."No.", CalculateTotlAmountShippedLine(ServiceHeader."No."));
        VerifyCustomerLedgerEntry(ServiceHeader."No.");
    end;

    local procedure AutoShipPartialInvoice(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; AutomaticCostPosting: Boolean; ExpectedCostPosting: Boolean)
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        Type: Option " ",Item,Resource,Both;
    begin
        // Setup: Modify Inventory Setup. Create Service Order-Service Line with Type as Item and Post as Ship and Modify Qty. to Invoice
        // Post with Invoice.
        Initialize();
        ModifyCostPostngInventorySetup(AutomaticCostPosting, ExpectedCostPosting);
        CreateServiceOrder(ServiceHeader, ServiceItemLine, ServiceLine, ServiceItem, Type::Item);
        ModifyQtyToShipOnServiceLine(ServiceHeader."No.");
        ModifyQtyToInvoiceServiceLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // Exercise: Modify Qty. to Invoice and Post Service Order as Invoice.
        ModifyQtyToInvoiceServiceLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, false, false, true);
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure AutoShipPartialInvoiceResource()
    var
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
        Type: Option " ",Item,Resource,Both;
    begin
        // Covers document number TC-PP-I-23 - refer to TFS ID 20887.
        // The test case checks posting with ship and invoice and then again invoice with manual cost posting with Type as
        // Resource, Cost and G/L Account.

        // 1. Setup: Modify Inventory Setup. Create Service Order-Service Line with Type as Resource, Cost and G/L Account, Modify Qty. to
        // Ship and Post partially as Ship and Invoice.
        Initialize();
        ModifyCostPostngInventorySetup(false, false);
        CreateServiceOrder(ServiceHeader, ServiceItemLine, ServiceLine, ServiceItem, Type::Resource);
        ModifyQtyToShipOnServiceLine(ServiceHeader."No.");
        ModifyQtyToInvoiceServiceLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 2. Exercise: Modify Qty. to Invoice and Post Service Order as Invoice.
        ModifyQtyToInvoiceServiceLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, false, false, true);

        // 3. Verify: Check that Service Order Entries created for Service Ledger Entry, VAT Entry, GL Entry, Detailed Cust. Ledger Entry,
        // Customer Ledger Entry, Resource Ledger Entry.
        VerifyServiceLedgerEntry(ServiceHeader."No.", ServiceHeader."Customer No.");
        VerifyServiceOrderVATEntry(ServiceHeader."No.");
        VerifyServiceOrderGLEntry(ServiceHeader."No.");
        VerifyDetailedCustLedgerEntry(ServiceHeader."No.", CalculateTotlAmountShippedLine(ServiceHeader."No."));
        VerifyCustomerLedgerEntry(ServiceHeader."No.");
        VerifyResourceLedgerEntry(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure PartShipPartInvoiceManual()
    var
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-PP-I-24 - refer to TFS ID 20887.
        // The test case checks posting with partial ship and partial invoice with manual cost posting with Type as Item.

        // Setup: Setup Automatic Cost Posting and Expected Cost Posting to G/L as parameter passed in Inventory Setup.
        PartShipPartInvoice(ServiceHeader, ServiceLine, false, false);

        // Verify: Check that Service Order Entries created for Service Ledger Entry, VAT Entry, Detailed Cust. Ledger Entry,
        // Item Ledger Entry, Customer Ledger Entry and Value entry for valued quantity.
        VerifyServiceLedgerEntry(ServiceHeader."No.", ServiceHeader."Customer No.");
        VerifyInvoiceQtyItemLedger(ServiceHeader."No.");
        VerifyVATEntry(ServiceHeader."No.");
        VerifyServiceOrderValueEntry(ServiceHeader."No.");
        VerifyDetailedCustLedgerEntry(ServiceHeader."No.", CalculateTotlAmountShippedLine(ServiceHeader."No."));
        VerifyCustomerLedgerEntry(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure PartShipPartInvoiceAutoEx()
    var
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-PP-I-24 - refer to TFS ID 20887.
        // The test case checks posting with partial ship and partial invoice with automatic and expected cost posting with Type as Item.

        // Setup: Setup Automatic Cost Posting and Expected Cost Posting to G/L as parameter passed in Inventory Setup.
        PartShipPartInvoice(ServiceHeader, ServiceLine, true, true);

        // Verify: Check that Service Order Entries created for Service Ledger Entry, VAT Entry, Detailed Cust. Ledger Entry,
        // Item Ledger Entry, GL Entry, Customer Ledger Entry and Value entry for valued quantity.
        VerifyServiceLedgerEntry(ServiceHeader."No.", ServiceHeader."Customer No.");
        VerifyInvoiceQtyItemLedger(ServiceHeader."No.");
        VerifyServiceOrderGLEntry(ServiceHeader."No.");
        VerifyVATEntry(ServiceHeader."No.");
        VerifyServiceOrderValueEntry(ServiceHeader."No.");
        VerifyDetailedCustLedgerEntry(ServiceHeader."No.", CalculateTotlAmountShippedLine(ServiceHeader."No."));
        VerifyCustomerLedgerEntry(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure PartShipPartInvoiceAuto()
    var
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-PP-I-24 - refer to TFS ID 20887.
        // The test case checks posting with partial ship and partial invoice with automatic cost posting with Type as Item.

        // Setup: Setup Automatic Cost Posting and Expected Cost Posting to G/L as parameter passed in Inventory Setup.
        PartShipPartInvoice(ServiceHeader, ServiceLine, true, false);

        // Verify: Check that Service Order Entries created for Service Ledger Entry, VAT Entry, Detailed Cust. Ledger Entry,
        // Item Ledger Entry, GL Entry, Customer Ledger Entry and Value entry for valued quantity.
        VerifyServiceLedgerEntry(ServiceHeader."No.", ServiceHeader."Customer No.");
        VerifyDetailedCustLedgerEntry(ServiceHeader."No.", CalculateTotlAmountShippedLine(ServiceHeader."No."));
        VerifyInvoiceQtyItemLedger(ServiceHeader."No.");
        VerifyServiceOrderGLEntry(ServiceHeader."No.");
        VerifyVATEntry(ServiceHeader."No.");
        VerifyServiceOrderValueEntry(ServiceHeader."No.");
        VerifyCustomerLedgerEntry(ServiceHeader."No.");
    end;

    local procedure PartShipPartInvoice(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; AutomaticCostPosting: Boolean; ExpectedCostPosting: Boolean)
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        Type: Option " ",Item,Resource,Both;
    begin
        // Setup: Modify Inventory Setup. Create Service Order-Service Line with Type as Item and Post as Ship and Invoice with
        // Modification on Qty. to Ship and Qty. to Invoice field.
        Initialize();
        ModifyCostPostngInventorySetup(AutomaticCostPosting, ExpectedCostPosting);
        CreateServiceOrder(ServiceHeader, ServiceItemLine, ServiceLine, ServiceItem, Type::Item);
        ModifyQtyToShipOnServiceLine(ServiceHeader."No.");
        ModifyQtyToInvoiceServiceLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // Exercise: Modify Qty. to Invoice and Qty. to Ship and Post Service Order as Invoice.
        ModifyQtyToShipOnServiceLine(ServiceHeader."No.");
        ModifyQtyToInvoiceServiceLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, false, false, true);
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure ConsumeAndInvoiceManual()
    var
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-PP-I-25 - refer to TFS ID 20887.
        // The test case checks posting with consume and invoice with manual cost posting with Type as Item.

        // Setup: Setup Automatic Cost Posting and Expected Cost Posting to G/L as parameter passed in Inventory Setup.
        ConsumeAndInvoice(ServiceHeader, ServiceLine, false, false);

        // Verify: Check that Service Order Entries created for Service Ledger Entry, GL Entry, Detailed Cust.
        // Ledger Entry, Customer Ledger Entry.
        VerifyServiceLedgerEntry(ServiceHeader."No.", ServiceHeader."Customer No.");
        VerifyServiceOrderGLEntry(ServiceHeader."No.");
        VerifyDetailedCustLedgerEntry(ServiceHeader."No.", CalculateTotlAmountShippedLine(ServiceHeader."No."));
        VerifyCustomerLedgerEntry(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure ConsumeAndInvoiceAutoEx()
    var
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-PP-I-25 - refer to TFS ID 20887.
        // The test case checks posting with consume and invoice with expected and automatic cost posting with Type as Item.

        // Setup: Setup Automatic Cost Posting and Expected Cost Posting to G/L as parameter passed in Inventory Setup.
        ConsumeAndInvoice(ServiceHeader, ServiceLine, true, true);

        // Verify: Check that Service Order Entries created for Service Ledger Entry, GL Entry, Detailed Cust. Ledger Entry,
        // Customer Ledger Entry.
        VerifyServiceLedgerEntry(ServiceHeader."No.", ServiceHeader."Customer No.");
        VerifyServiceOrderGLEntry(ServiceHeader."No.");
        VerifyDetailedCustLedgerEntry(ServiceHeader."No.", CalculateTotlAmountShippedLine(ServiceHeader."No."));
        VerifyCustomerLedgerEntry(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure ConsumeAndInvoiceAuto()
    var
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-PP-I-25 - refer to TFS ID 20887.
        // The test case checks posting with consume and invoice with automatic cost posting with Type as Item.

        // Setup: Setup Automatic Cost Posting and Expected Cost Posting to G/L as parameter passed in Inventory Setup.
        ConsumeAndInvoice(ServiceHeader, ServiceLine, true, false);

        // Verify: Check that Service Order Entries created for Service Ledger Entry, GL Entry, Detailed Cust.
        // Ledger Entry, Customer Ledger Entry and Value Entry for Values Quantity.
        VerifyServiceLedgerEntry(ServiceHeader."No.", ServiceHeader."Customer No.");
        VerifyServiceOrderValueEntry(ServiceHeader."No.");
        VerifyServiceOrderGLEntry(ServiceHeader."No.");
        VerifyDetailedCustLedgerEntry(ServiceHeader."No.", CalculateTotlAmountShippedLine(ServiceHeader."No."));
        VerifyCustomerLedgerEntry(ServiceHeader."No.");
    end;

    local procedure ConsumeAndInvoice(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; AutomaticCostPosting: Boolean; ExpectedCostPosting: Boolean)
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        Type: Option " ",Item,Resource,Both;
    begin
        // Setup: Modify Inventory Setup. Create Service Order-Service Line with Type as Resource, Cost and G/L Account, Modify Qty. to
        // Ship and Post partially as Ship and Invoice.
        Initialize();
        ModifyCostPostngInventorySetup(AutomaticCostPosting, ExpectedCostPosting);
        CreateServiceOrder(ServiceHeader, ServiceItemLine, ServiceLine, ServiceItem, Type::Item);
        ModifyQtyToShipOnServiceLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        ModifyQtyToShipOnServiceLine(ServiceHeader."No.");
        ModifyQtyToConsumeServiceLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // Exercise: Modify Qty. to Invoice and Post Service Order as Invoice.
        ModifyQtyToInvoiceServiceLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, false, false, true);
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure ConsumeAndInvoiceResource()
    var
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
        Type: Option " ",Item,Resource,Both;
    begin
        // Covers document number TC-PP-I-26 - refer to TFS ID 20887.
        // The test case checks entries for posting with consume and then invoice with manual cost posting with Type as Resource.

        // 1. Setup: Create Service Order having Service Line with Type as Resource, Modify Qty. to Ship field and Post as Ship, Modify Qty.
        // to Ship, Qty. to Consume and Post as Ship and Consume.
        Initialize();
        ModifyCostPostngInventorySetup(false, false);
        CreateServiceOrder(ServiceHeader, ServiceItemLine, ServiceLine, ServiceItem, Type::" ");
        CreateServiceLineWithResource(ServiceLine, ServiceHeader, ServiceItem."No.");

        ModifyQtyToShipOnServiceLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        ModifyQtyToShipOnServiceLine(ServiceHeader."No.");
        ModifyQtyToConsumeServiceLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 2. Exercise: Modify Qty. to Invoice and Post Service Order as Invoice.
        ModifyQtyToInvoiceServiceLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, false, false, true);

        // 3. Verify: Check that Service Order Entries created for Service Ledger Entry, GL Entry, Detailed Cust.
        // Ledger Entry, Customer Ledger Entry and Resource Ledger Entry.
        VerifyServiceLedgerEntry(ServiceHeader."No.", ServiceHeader."Customer No.");
        VerifyServiceOrderGLEntry(ServiceHeader."No.");
        VerifyDetailedCustLedgerEntry(ServiceHeader."No.", CalculateTotlAmountShippedLine(ServiceHeader."No."));
        VerifyCustomerLedgerEntry(ServiceHeader."No.");
        VerifyResourceLedgerEntry(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure ConsumeFollowShipAndInvoice()
    var
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
        Type: Option " ",Item,Resource,Both;
    begin
        // Covers document number TC-PP-I-28 - refer to TFS ID 20887.
        // The test case checks entries for posting with consume and then ship and invoice with manual cost posting with Type as Resource.

        // 1. Setup: Create Service Order having Service Line with Type as Resource, Modify Qty. to Ship field and Post as Ship, Modify Qty.
        // to Ship, Qty. to Consume and Post as Ship and Consume.
        Initialize();
        ModifyCostPostngInventorySetup(false, false);
        CreateServiceOrder(ServiceHeader, ServiceItemLine, ServiceLine, ServiceItem, Type::" ");
        CreateServiceLineWithResource(ServiceLine, ServiceHeader, ServiceItem."No.");

        ModifyQtyToShipOnServiceLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        ModifyQtyToShipOnServiceLine(ServiceHeader."No.");
        ModifyQtyToConsumeServiceLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 2. Exercise: Modify Qty. to Ship and Post Service Order as Ship and Invoice.
        ModifyQtyToShipOnServiceLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Check that Service Order Entries created for Service Ledger Entry, GL Entry, Detailed Cust.
        // Ledger Entry, Customer Ledger Entry and Resource Ledger Entry.
        VerifyServiceLedgerEntry(ServiceHeader."No.", ServiceHeader."Customer No.");
        VerifyServiceOrderGLEntry(ServiceHeader."No.");
        VerifyDetailedCustLedgerEntry(ServiceHeader."No.", CalculateTotlAmountShippedLine(ServiceHeader."No."));
        VerifyCustomerLedgerEntry(ServiceHeader."No.");
        VerifyResourceLedgerEntry(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure UndoServiceShipment()
    var
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
        ServiceShipmentLine: Record "Service Shipment Line";
        UndoServiceShipmentLine: Codeunit "Undo Service Shipment Line";
        Type: Option " ",Item,Resource,Both;
    begin
        // Covers document number TC-PP-I-33 - refer to TFS ID 20887.
        // The test case checks that the application generates an error on posting an order when there is no Qty. Shipped not invoiced
        // field is zero.

        // 1.Setup: Create Service Order having Service Line with Type as Resource, Modify Sales and Receivables setup for Cal. Inv
        // Discount field as False and Automatic Cost Posting as False and Expected Cost Posting to G/L as False on Inventory Setup and
        // Modify Qty. to Ship on Service Line and Post as Ship.
        Initialize();
        ModifyInvoiceDiscount();
        ModifyCostPostngInventorySetup(false, false);
        CreateServiceOrder(ServiceHeader, ServiceItemLine, ServiceLine, ServiceItem, Type::" ");
        CreateServiceLineWithResource(ServiceLine, ServiceHeader, ServiceItem."No.");

        ModifyQtyToShipOnServiceLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 2. Exercise: Modify Qty. to Consume and Post Service Order as Ship and Consume.
        ModifyQtyToConsumeServiceLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 3. Verify: Try to Undo Service Shipment Line and Check that Error raised when there is no Qty. Shipped not invoiced field is
        // Zero.
        ServiceShipmentLine.SetRange("Order No.", ServiceHeader."No.");
        ServiceShipmentLine.SetRange("Qty. Shipped Not Invoiced", 0);
        ServiceShipmentLine.FindFirst();
        asserterror UndoServiceShipmentLine.Run(ServiceShipmentLine);
        Assert.ExpectedTestFieldError(ServiceShipmentLine.FieldCaption("Qty. Shipped Not Invoiced"), Format(ServiceShipmentLine.Quantity));
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure UndoServiceConsumption()
    var
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
        ServiceShipmentLine: Record "Service Shipment Line";
        UndoServiceConsumptionLine: Codeunit "Undo Service Consumption Line";
        Type: Option " ",Item,Resource,Both;
    begin
        // Covers document number TC-PP-I-33 - refer to TFS ID 20887.
        // The test case checks the functionality of undo consumption.

        // 1. Setup: Create Service Order having Service Line with Type as Resource, Modify Sales and Receivables setup for Cal. Inv
        // Discount field as False and Automatic Cost Posting as False and Expected Cost Posting to G/L as False on Inventory Setup and
        // Modify Qty. to Ship on Service Line and Post as Ship.
        Initialize();
        ModifyInvoiceDiscount();
        ModifyCostPostngInventorySetup(false, false);
        CreateServiceOrder(ServiceHeader, ServiceItemLine, ServiceLine, ServiceItem, Type::" ");
        CreateServiceLineWithResource(ServiceLine, ServiceHeader, ServiceItem."No.");

        ModifyQtyToShipOnServiceLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 2. Exercise: Modify Qty. to Consume and Post Service Order as Ship and Consume.
        ModifyQtyToConsumeServiceLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 3. Verify: Undo Consume on Service Shipment Line and Check that no error comes on undo consumption.
        ServiceShipmentLine.SetRange("Order No.", ServiceHeader."No.");
        ServiceShipmentLine.SetFilter("Quantity Consumed", '>0');
        ServiceShipmentLine.FindLast();
        UndoServiceConsumptionLine.Run(ServiceShipmentLine);
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure ShipAndUndoShipment()
    var
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
        ServiceShipmentLine: Record "Service Shipment Line";
        UndoServiceShipmentLine: Codeunit "Undo Service Shipment Line";
        Type: Option " ",Item,Resource,Both;
    begin
        // Covers document number TC-PP-I-33 - refer to TFS ID 20887.
        // The test case checks that the application generates an error on posting the Service Order as Invoice while there is no Qty. in
        // Invoice field.

        // 1. Setup: Create Service Order having Service Line with Type as Resource, Modify Sales and Receivables setup for Cal. Inv
        // Discount field as False and Automatic Cost Posting as False and Expected Cost Posting to G/L as False on Inventory Setup and
        // Modify Qty. to Ship on Service Line and Post as Ship.
        Initialize();
        ModifyInvoiceDiscount();
        ModifyCostPostngInventorySetup(false, false);
        CreateServiceOrder(ServiceHeader, ServiceItemLine, ServiceLine, ServiceItem, Type::" ");
        CreateServiceLineWithResource(ServiceLine, ServiceHeader, ServiceItem."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 2. Exercise: Undo Service Shipment Line.
        ServiceShipmentLine.SetRange("Order No.", ServiceHeader."No.");
        ServiceShipmentLine.FindFirst();
        UndoServiceShipmentLine.Run(ServiceShipmentLine);

        // 3. Verify: Try to post the Service Order as Invoice while there is no Qty. in Invoice field.
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        asserterror LibraryService.PostServiceOrder(ServiceHeader, false, false, true);
        Assert.AreEqual(StrSubstNo(DocumentErrorsMgt.GetNothingToPostErrorMsg()), GetLastErrorText, UnknownError);
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure ShipAndInvoiceLedgerEntries()
    var
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
        Type: Option " ",Item,Resource,Both;
    begin
        // Covers document number TC-PP-I-34 - refer to TFS ID 20887.
        // The test case checks entries for posting with ship and invoice with manual cost posting with Type as Resource.

        // 1. Setup: Create Service Order having Service Line with Type as Resource, Modify Sales and Receivables setup for Cal. Inv
        // Discount field as False and Automatic Cost Posting as False and Expected Cost Posting to G/L as False on Inventory Setup and
        // Modify Qty. to Ship on Service Line and Post as Ship.
        Initialize();
        ModifyInvoiceDiscount();
        ModifyCostPostngInventorySetup(false, false);
        CreateServiceOrder(ServiceHeader, ServiceItemLine, ServiceLine, ServiceItem, Type::" ");
        CreateServiceLineWithResource(ServiceLine, ServiceHeader, ServiceItem."No.");

        ModifyQtyToShipOnServiceLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 2. Exercise: Post Service Order as Ship and Invoice.
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Check that Service Order Entries created for Service Ledger Entry, GL Entry, Detailed Cust.
        // Ledger Entry, Customer Ledger Entry and Resource Ledger Entry.
        VerifyServiceLedgerEntry(ServiceHeader."No.", ServiceHeader."Customer No.");
        VerifyServiceOrderGLEntry(ServiceHeader."No.");
        VerifyDetailedCustLedgerEntry(ServiceHeader."No.", CalculateTotlAmountShippedLine(ServiceHeader."No."));
        VerifyCustomerLedgerEntry(ServiceHeader."No.");
        VerifyResourceLedgerEntry(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,ExpectedCostMsgHandler')]
    [Scope('OnPrem')]
    procedure ShipConsumeUndoConsumption()
    var
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
        ServiceShipmentLine: Record "Service Shipment Line";
        TempServiceLineBeforePosting: Record "Service Line" temporary;
        UndoServiceConsumptionLine: Codeunit "Undo Service Consumption Line";
        Type: Option " ",Item,Resource,Both;
    begin
        // Covers document number TC-PP-I-35 - refer to TFS ID 20887.
        // The test case checks entries created for Service Order posted with Ship and consume and for which undo consumption is then done.

        // 1. Setup: Create Service Order having Service Line with Type as Resource and Item, Modify Sales and Receivables setup for
        // Cal. Inv Discount field as False and Automatic Cost Posting as False and Expected Cost Posting to G/L as False on
        // Inventory Setup and Modify Qty. to Ship on Service Line and Post as Ship.
        Initialize();
        ModifyInvoiceDiscount();
        ModifyCostPostngInventorySetup(false, false);
        CreateServiceOrder(ServiceHeader, ServiceItemLine, ServiceLine, ServiceItem, Type::" ");
        CreateServiceLineWithResource(ServiceLine, ServiceHeader, ServiceItem."No.");
        CreateServiceLineWithItem(ServiceLine, ServiceHeader, ServiceItem."No.");

        ModifyQtyToShipOnServiceLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // Modify Qty. to Ship and Qty. to Consume and Post as Ship and Consume.
        ModifyQtyToShipOnServiceLine(ServiceHeader."No.");
        ModifyQtyToConsumeServiceLine(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        SaveServiceLineInTempTable(TempServiceLineBeforePosting, ServiceLine);
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // Undo Service Consumption.
        ServiceShipmentLine.SetRange("Order No.", ServiceHeader."No.");
        ServiceShipmentLine.SetFilter("Quantity Consumed", '>0');
        ServiceShipmentLine.FindLast();
        UndoServiceConsumptionLine.Run(ServiceShipmentLine);
        VerifyItemLedgerAndValueEntriesAfterUndoConsumption(TempServiceLineBeforePosting);

        // 2. Exercise: Post Service Order as Invoice.
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, false, false, true);

        // 3. Verify: Check that Service Order Entries created for Service Ledger Entry, GL Entry, Detailed Cust. Ledger Entry, Customer
        // Ledger Entry and Resource Ledger Entry.
        VerifyServiceLedgerEntry(ServiceHeader."No.", ServiceHeader."Customer No.");
        VerifyServiceOrderGLEntry(ServiceHeader."No.");
        VerifyDetailedCustLedgerEntry(ServiceHeader."No.", CalculateTotlAmountShippedLine(ServiceHeader."No."));
        VerifyCustomerLedgerEntry(ServiceHeader."No.");
        VerifyResourceLedgerEntry(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ReplaceDatesAsFalse()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        PostingDate: Date;
    begin
        // Test that the Posting and Document Dates are not replaced on running report Batch Post Service Invoice
        // without the option Replace Posting Date, Replace Document Date.

        // 1. Setup: Create Service Invoice - Service Header, multiple Service Lines with Type as Item.
        Initialize();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        CreateMultipleServiceLines(ServiceHeader, '');
        Commit();  // Commit is required to run the batch job.

        // 2. Exercise: Run the Batch Post Service Invoices with any random date greater than work date.
        PostingDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        BatchPostServiceInvoices(ServiceHeader, PostingDate, false, false, false);

        // 3. Verify: Check that the posted Service Invoice different date from that inputted in report.
        FindServiceInvoiceHeader(ServiceInvoiceHeader, ServiceHeader."No.");
        ServiceInvoiceHeader.TestField("Posting Date", WorkDate());
        ServiceInvoiceHeader.TestField("Document Date", WorkDate());
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ReplacePostingDateAsTrue()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        PostingDate: Date;
    begin
        // Test that the Posting Date is replaced on running the report Batch Post Service Invoice with the option Replace Posting Date.

        // 1. Setup: Create Service Invoice - Service Header, multiple Service Lines with Type as Item.
        Initialize();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        CreateMultipleServiceLines(ServiceHeader, '');
        Commit();  // Commit is required to run the batch job.

        // 2. Exercise: Run the Batch Post Service Invoices with any random date greater than work date.
        PostingDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        BatchPostServiceInvoices(ServiceHeader, PostingDate, true, false, false);

        // 3. Verify: Check that the posted Service Invoice has the same date as inputted in report.
        FindServiceInvoiceHeader(ServiceInvoiceHeader, ServiceHeader."No.");
        ServiceInvoiceHeader.TestField("Posting Date", PostingDate);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ReplaceDocumentDateAsTrue()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        PostingDate: Date;
    begin
        // Test that the Document Date is replaced on running the report Batch Post Service Invoice with the option Replace Document Date.

        // 1. Setup: Create Service Invoice - Service Header, multiple Service Lines with Type as Item.
        Initialize();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        CreateMultipleServiceLines(ServiceHeader, '');
        Commit();  // Commit is required to run the batch job.

        // 2. Exercise: Run the Batch Post Service Invoices with any random date less than work date.
        PostingDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        BatchPostServiceInvoices(ServiceHeader, PostingDate, false, true, false);

        // 3. Verify: Check that the posted Service Invoice has the same date as inputted in report.
        FindServiceInvoiceHeader(ServiceInvoiceHeader, ServiceHeader."No.");
        ServiceInvoiceHeader.TestField("Document Date", PostingDate);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CalculateInvoiceDiscountFalse()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        PostingDate: Date;
    begin
        // Test that the Invoice Discount is not calculated on running the report Batch Post Service Invoice with the
        // option Calculate Invoice Discount as False.

        // 1. Setup: Setup Invoice Discount. Create a new Customer, Customer Invoice Discount. Input non-zero percent in line.
        // Create Service Invoice - Service Header, Service Line with Type as Item.
        Initialize();
        CreateMultipleServiceLineAndInvoiceDiscount(ServiceHeader, CustInvoiceDisc, ServiceHeader."Document Type"::Invoice);

        // 2. Exercise: Run the Batch Post Service Invoices with any random date greater than work date.
        PostingDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        BatchPostServiceInvoices(ServiceHeader, PostingDate, false, false, false);

        // 3. Verify: Check that the posted Service Invoice has zero Invoice Discount Amount on Service Lines.
        FindServiceInvoiceHeader(ServiceInvoiceHeader, ServiceHeader."No.");
        VerifyZeroDiscountInLines(ServiceInvoiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CalculateInvoiceDiscountAsTrue()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        PostingDate: Date;
    begin
        // Test that the Invoice Discount is calculated correctly on running the report Batch Post Service Invoice with the
        // option Calculate Invoice Discount as True.

        // 1. Setup: Setup Invoice Discount. Create a new Customer, Customer Invoice Discount. Input non-zero percent in line.
        // Create Service Invoice - Service Header, Service Line with Type as Item.
        Initialize();
        CreateMultipleServiceLineAndInvoiceDiscount(ServiceHeader, CustInvoiceDisc, ServiceHeader."Document Type"::Invoice);

        // 2. Exercise: Run the Batch Post Service Invoices with any random date greater than work date.
        PostingDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        BatchPostServiceInvoices(ServiceHeader, PostingDate, false, false, true);

        // 3. Verify: Check that the posted Service Invoice has non-zero Invoice Discount Amount on Service Lines.
        FindServiceInvoiceHeader(ServiceInvoiceHeader, ServiceHeader."No.");
        VerifyNonZeroDiscountInLines(ServiceInvoiceHeader."No.", CustInvoiceDisc."Discount %");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ReplaceDatesAsFalseCreditMemo()
    var
        ServiceHeader: Record "Service Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        PostingDate: Date;
    begin
        // Test that the Posting and Document Dates are not replaced on running report Batch Post Service Cr. Memos
        // without the option Replace Posting Date, Replace Document Date.

        // 1. Setup: Create Service Credit Memo - Service Header, multiple Service Lines with Type as Item.
        Initialize();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo());
        CreateMultipleServiceLines(ServiceHeader, '');
        Commit();  // Commit is required to run the batch job.

        // 2. Exercise: Run the Batch Post Service Cr. Memos with any random date greater than work date.
        PostingDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        BatchPostServiceCreditMemos(ServiceHeader, PostingDate, false, false, false);

        // 3. Verify: Check that the posted Service Credit Memo Header has different date from that inputted in report.
        FindServiceCreditMemoHeader(ServiceCrMemoHeader, ServiceHeader."No.");
        ServiceCrMemoHeader.TestField("Posting Date", WorkDate());
        ServiceCrMemoHeader.TestField("Document Date", WorkDate());
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ReplacePostingDateAsTrueCredit()
    var
        ServiceHeader: Record "Service Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        PostingDate: Date;
    begin
        // Test that the Posting Date is replaced on running the report Batch Post Service Cr. Memos with the option Replace Posting Date.

        // 1. Setup: Create Service Credit Memo - Service Header, multiple Service Lines with Type as Item.
        Initialize();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo());
        CreateMultipleServiceLines(ServiceHeader, '');
        Commit();  // Commit is required to run the batch job.

        // 2. Exercise: Run the Batch Post Service Cr. Memos with any random date greater than work date.
        PostingDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        BatchPostServiceCreditMemos(ServiceHeader, PostingDate, true, false, false);

        // 3. Verify: Check that the posted Service Credit Memo has the same date as inputted in report.
        FindServiceCreditMemoHeader(ServiceCrMemoHeader, ServiceHeader."No.");
        ServiceCrMemoHeader.TestField("Posting Date", PostingDate);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ReplaceDocumentDateTrueCredit()
    var
        ServiceHeader: Record "Service Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        PostingDate: Date;
    begin
        // Test that the Document Date is replaced on running the report Batch Post Service Cr. Memos with the option Replace Document Date.

        // 1. Setup: Create Service Credit Memo - Service Header, multiple Service Lines with Type as Item.
        Initialize();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo());
        CreateMultipleServiceLines(ServiceHeader, '');
        Commit();  // Commit is required to run the batch job.

        // 2. Exercise: Run the Batch Post Service Cr. Memos with any random date less than work date.
        PostingDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        BatchPostServiceCreditMemos(ServiceHeader, PostingDate, false, true, false);

        // 3. Verify: Check that the posted Service Credit Memo has the same date as inputted in report.
        FindServiceCreditMemoHeader(ServiceCrMemoHeader, ServiceHeader."No.");
        ServiceCrMemoHeader.TestField("Document Date", PostingDate);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CalculateDiscountFalseCredit()
    var
        ServiceHeader: Record "Service Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        PostingDate: Date;
    begin
        // Test that the Invoice Discount is not calculated on running the report Batch Post Service Cr. Memos with the
        // option Calculate Invoice Discount as False.

        // 1. Setup: Setup Invoice Discount. Create a new Customer, Customer Invoice Discount. Input non-zero percent in line.
        // Create Service Credit Memo - Service Header, Service Line with Type as Item.
        Initialize();
        CreateMultipleServiceLineAndInvoiceDiscount(ServiceHeader, CustInvoiceDisc, ServiceHeader."Document Type"::"Credit Memo");

        // 2. Exercise: Run the Batch Post Service Cr. Memos with any random date greater than work date.
        PostingDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        BatchPostServiceCreditMemos(ServiceHeader, PostingDate, false, false, false);

        // 3. Verify: Check that the posted Service Credit Memo has zero Invoice Discount Amount on Service Lines.
        FindServiceCreditMemoHeader(ServiceCrMemoHeader, ServiceHeader."No.");
        VerifyZeroDiscountCreditLines(ServiceCrMemoHeader."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CalculateDiscountTrueCredit()
    var
        ServiceHeader: Record "Service Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        PostingDate: Date;
    begin
        // Test that the Invoice Discount is calculated correctly on running the report Batch Post Service Cr. Memos with the
        // option Calculate Invoice Discount as True.

        // 1. Setup: Setup Invoice Discount. Create a new Customer, Customer Invoice Discount. Input non-zero percent in line.
        // Create Service Credit Memo - Service Header, Service Line with Type as Item.
        Initialize();
        CreateMultipleServiceLineAndInvoiceDiscount(ServiceHeader, CustInvoiceDisc, ServiceHeader."Document Type"::"Credit Memo");

        // 2. Exercise: Run the Batch Post Service Cr. Memos with any random date greater than work date.
        PostingDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        BatchPostServiceCreditMemos(ServiceHeader, PostingDate, false, false, true);

        // 3. Verify: Check that the posted Credit Memo has non-zero Invoice Discount Amount on Service Lines.
        FindServiceCreditMemoHeader(ServiceCrMemoHeader, ServiceHeader."No.");
        VerifyNonZeroDiscountInCredit(ServiceCrMemoHeader."No.", CustInvoiceDisc."Discount %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplacePostingDateErrorCredit()
    var
        ServiceHeader: Record "Service Header";
        PostingDate: Date;
    begin
        // Test that the application generates an error as 'Please enter the posting date' on running the report Batch Post
        // Service Cr. Memos with the option Replace Posting Date and blank posting date.

        // 1. Setup: Create Service Credit Memo - Service Header, multiple Service Lines with Type as Item.
        Initialize();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo());
        CreateMultipleServiceLines(ServiceHeader, '');
        Commit();  // Commit is required to run the batch job.

        // 2. Exercise: Run the Batch Post Service Cr. Memos with blank date.
        PostingDate := PostingDate;  // Used to initialize the variable.
        asserterror BatchPostServiceCreditMemos(ServiceHeader, PostingDate, true, false, false);

        // 3. Verify: Check that the application generates an error as 'Please enter the posting date'.
        Assert.AreEqual(StrSubstNo(PostingDateBlankError), GetLastErrorText, UnknownError);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ReplaceDatesAsFalseOrder()
    var
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceShipmentHeader: Record "Service Shipment Header";
        PostingDate: Date;
    begin
        // Test that the Posting and Document Dates are not replaced on running report Batch Post Service Orders
        // without the option Replace Posting Date, Replace Document Date.

        // 1. Setup: Create Service Order - Service Item, Service Header, Service Item Line, multiple Service Lines with Type as Item.
        Initialize();
        LibraryService.CreateServiceItem(ServiceItem, LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        CreateMultipleServiceLines(ServiceHeader, ServiceItem."No.");
        Commit();  // Commit is required to run the batch job.

        // 2. Exercise: Run the Batch Post Service Orders with any random date greater than work date.
        PostingDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        BatchPostServiceOrder(ServiceHeader, PostingDate, false, false, false);

        // 3. Verify: Check that the posted Service Invoice/Shipment Headers have different date from that inputted in report.
        FindServiceInvoiceFromOrder(ServiceInvoiceHeader, ServiceHeader."No.");
        ServiceInvoiceHeader.TestField("Posting Date", ServiceHeader."Posting Date");
        ServiceInvoiceHeader.TestField("Document Date", ServiceHeader."Document Date");

        FindServiceShipmentHeader(ServiceShipmentHeader, ServiceHeader."No.");
        ServiceShipmentHeader.TestField("Posting Date", ServiceHeader."Posting Date");
        ServiceShipmentHeader.TestField("Document Date", ServiceHeader."Document Date");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ReplacePostingDateAsTrueOrder()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceShipmentHeader: Record "Service Shipment Header";
        PostingDate: Date;
    begin
        // Test that the Posting Date is replaced on running the report Batch Post Service Orders with the option Replace Posting Date.
        // 1. Setup: Create Service Order - Service Item, Service Header, Service Item Line, multiple Service Lines with Type as Item.
        Initialize();
        CreateServiceHeaderWithMultipleLines(ServiceHeader);

        // 2. Exercise: Run the Batch Post Service Orders with any random date greater than work date.
        PostingDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        BatchPostServiceOrder(ServiceHeader, PostingDate, true, false, false);

        // 3. Verify: Check that the posted Service Invoice/Shipment have the same date as inputted in report.
        FindServiceInvoiceFromOrder(ServiceInvoiceHeader, ServiceHeader."No.");
        ServiceInvoiceHeader.TestField("Posting Date", PostingDate);

        FindServiceShipmentHeader(ServiceShipmentHeader, ServiceHeader."No.");
        ServiceShipmentHeader.TestField("Posting Date", PostingDate);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ReplaceDocumentDateTrueOrder()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceShipmentHeader: Record "Service Shipment Header";
        PostingDate: Date;
    begin
        // Test that the Document Date is replaced on running the report Batch Post Service Orders with the option Replace Document Date.
        // 1. Setup: Create Service Order - Service Item, Service Header, Service Item Line, multiple Service Lines with Type as Item.
        Initialize();
        CreateServiceHeaderWithMultipleLines(ServiceHeader);

        // 2. Exercise: Run the Batch Post Service Orders with any random date less than work date.
        PostingDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        BatchPostServiceOrder(ServiceHeader, PostingDate, false, true, false);

        // 3. Verify: Check that the posted Service Invoice/Shipment has the same date as inputted in report.
        FindServiceInvoiceFromOrder(ServiceInvoiceHeader, ServiceHeader."No.");
        ServiceInvoiceHeader.TestField("Document Date", PostingDate);

        FindServiceShipmentHeader(ServiceShipmentHeader, ServiceHeader."No.");
        ServiceShipmentHeader.TestField("Document Date", PostingDate);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CalculateDiscountFalseOrder()
    var
        Customer: Record Customer;
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        PostingDate: Date;
    begin
        // Test that the Invoice Discount is not calculated on running the report Batch Post Service Orders with the
        // option Calculate Invoice Discount as False.

        // 1. Setup: Setup Invoice Discount. Create a new Customer, Customer Invoice Discount. Input non-zero percent in line.
        // Create Service Order - Service Item, Service Header, Service Item Line, multiple Service Lines with Type as Item.
        Initialize();
        ModifyInvoiceDiscount();
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, Customer."No.", '', 0);  // Minimum amount is 0.
        UpdateCustomerInvoiceDiscount(CustInvoiceDisc);

        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        CreateMultipleServiceLines(ServiceHeader, ServiceItem."No.");
        Commit();  // Commit is required to run the batch job.

        // 2. Exercise: Run the Batch Post Service Orders with any random date greater than work date.
        PostingDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        BatchPostServiceOrder(ServiceHeader, PostingDate, false, false, false);

        // 3. Verify: Check that the posted Service Invoice has zero Invoice Discount Amount on Service Lines.
        FindServiceInvoiceFromOrder(ServiceInvoiceHeader, ServiceHeader."No.");
        VerifyZeroDiscountInLines(ServiceInvoiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CalculateDiscountTrueOrder()
    var
        Customer: Record Customer;
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        PostingDate: Date;
    begin
        // Test that the Invoice Discount is calculated correctly on running the report Batch Post Service Orders with the
        // option Calculate Invoice Discount as True.

        // 1. Setup: Setup Invoice Discount. Create a new Customer, Customer Invoice Discount. Input non-zero percent in line.
        // Create Service Order - Service Item, Service Header, Service Item Line, multiple Service Lines with Type as Item.
        Initialize();
        ModifyInvoiceDiscount();
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, Customer."No.", '', 0);  // Minimum amount is 0.
        UpdateCustomerInvoiceDiscount(CustInvoiceDisc);

        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        CreateMultipleServiceLines(ServiceHeader, ServiceItem."No.");
        Commit();  // Commit is required to run the batch job.

        // 2. Exercise: Run the Batch Post Service Orders with any random date greater than work date.
        PostingDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        BatchPostServiceOrder(ServiceHeader, PostingDate, false, false, true);

        // 3. Verify: Check that the posted Invoice has non-zero Invoice Discount Amount on Service Lines.
        FindServiceInvoiceFromOrder(ServiceInvoiceHeader, ServiceHeader."No.");
        VerifyNonZeroDiscountInLines(ServiceInvoiceHeader."No.", CustInvoiceDisc."Discount %");
    end;

    [Test]
    [HandlerFunctions('ExpectedCostConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReplacePostingDateErrorOrder()
    var
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        PostingDate: Date;
    begin
        // Test that the application generates an error as 'Please enter the posting date' on running the report Batch Post
        // Service Orders with the option Replace Posting Date and blank posting date.

        // 1. Setup: Create Service Order - Service Item, Service Header, Service Item Line, multiple Service Lines with Type as Item.
        Initialize();
        LibraryService.CreateServiceItem(ServiceItem, LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        CreateMultipleServiceLines(ServiceHeader, ServiceItem."No.");
        Commit();  // Commit is required to run the batch job.

        // 2. Exercise: Run the Batch Post Orders with blank date.
        PostingDate := 0D;  // Used to initialize the variable.
        ExecuteUIHandlers();
        asserterror BatchPostServiceOrder(ServiceHeader, PostingDate, true, false, false);

        // 3. Verify: Check that the application generates an error as 'Please enter the posting date'.
        Assert.AreEqual(StrSubstNo(PostingDateBlankError), GetLastErrorText, UnknownError);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CheckSourceNoOnValueEntry()
    var
        Customer: Record Customer;
        BillToCustomer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        Item: Record Item;
    begin
        // Verify that source no is correct in value entry when bill-to customer no is defined.

        // Setup: Create Service Invoce with Bill-to Customer No.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomer(BillToCustomer);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, Customer."No.");
        ServiceHeader.Validate("Bill-to Customer No.", BillToCustomer."No.");
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItem(Item));
        ServiceLine.Validate(Quantity, LibraryRandom.RandDec(100, 2));
        ServiceLine.Modify(true);

        // Exercise: Post Service Invoice.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // Verify: Verify Souce No on Value Entry.
        VerifySourceNoOnValueEntry(ServiceLine."No.", BillToCustomer."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentMehodCodeAfterServiceInvoicePosting()
    var
        ServiceHeader: Record "Service Header";
        PaymentMethod: Record "Payment Method";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Invoice] [Payment Method]
        // [SCENARIO 363865] Payment Method is populated from posted Service Invoice to Customer Ledger Entry
        Initialize();
        LibraryERM.CreatePaymentMethod(PaymentMethod);

        // [GIVEN] Service Invoice with "Payment Method Code" = "PM"
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, '');
        ServiceHeader.Validate("Payment Method Code", PaymentMethod.Code);
        ServiceHeader.Modify();
        CreateServiceLine(ServiceHeader);

        // [WHEN] Post Service Invoice
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] "Customer Ledger Entry"."Payment Method Code" = "PM"
        CustLedgerEntry.SetRange("Customer No.", ServiceHeader."Customer No.");
        CustLedgerEntry.FindFirst();
        Assert.AreEqual(
          PaymentMethod.Code, CustLedgerEntry."Payment Method Code", CustLedgerEntry.FieldCaption("Payment Method Code"));
    end;

    [Test]
    [HandlerFunctions('HandleStrMenu')]
    [Scope('OnPrem')]
    procedure PostServiceLinesWithEmptyTypeAndAllowedDates()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
        ServPostYesNo: Codeunit "Service-Post (Yes/No)";
    begin
        // [SCENARIO 376766] Service Order with Text Service Line that have empty Posting Date should be posted when Allowed Posting Dates are defined
        Initialize();

        // [GIVEN] Set Allowed Posting Dates in GLSetup
        LibraryERM.SetAllowPostingFromTo(CalcDate('<-CY>', WorkDate()), CalcDate('<CY>', WorkDate()));

        // [GIVEN] New Service Order with Service Item Line
        CreateServiceDocument(ServiceHeader, ServiceItemLine, LibrarySales.CreateCustomerNo());
        CreateServiceLineWithItem(ServiceLine, ServiceHeader, ServiceItemLine."Item No.");
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Modify(true);
        TempServiceLine := ServiceLine;
        TempServiceLine.Insert();

        // [GIVEN] Second Service Line with empty Type and Description = "D"
        ServiceLine.Init();
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::" ", '');
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate("Service Item No.", ServiceItemLine."Service Item No.");
        ServiceLine.Description := ServiceItemLine."Service Item No.";
        ServiceLine.Modify(true);
        TempServiceLine := ServiceLine;
        TempServiceLine.Insert();

        // [WHEN] Post Service Order
        // Select Ship and Invoice in HandleStrMenu
        LibraryVariableStorage.Enqueue(3);
        ServPostYesNo.PostDocumentWithLines(ServiceHeader, TempServiceLine);

        // [THEN] Posted Service Shipment Line with empty type has Description = "D"
        ServiceInvoiceHeader.SetRange("Order No.", ServiceHeader."No.");
        ServiceInvoiceHeader.FindFirst();
        ServiceInvoiceLine.SetRange(Type, ServiceInvoiceLine.Type::" ");
        FindServiceInvoiceLines(ServiceInvoiceLine, ServiceInvoiceHeader."No.");
        ServiceInvoiceLine.TestField(Description, ServiceItemLine."Service Item No.");
    end;

    [Test]
    [HandlerFunctions('PostedServiceInvoicePH')]
    [Scope('OnPrem')]
    procedure ShowPostedDocumentForPostedServiceInvoice()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Invoice] [Customer]
        // [SCENARIO 377063] Posted Service Invoice is shown after "Show Posted Document" action from customer ledger entry

        // [GIVEN] Posted Service Invoice
        ServiceInvoiceHeader.Get(CreatePostServiceInvoice(LibrarySales.CreateCustomerNo()));

        // [GIVEN] Customer ledger entry linked to the posted Service Invoice
        FindCustLedgEntry(CustLedgerEntry, ServiceInvoiceHeader."No.", ServiceInvoiceHeader."Customer No.");

        // [WHEN] Perform "Show Posted Document" action
        // [THEN] Page "Posted Service Invoice" is opened for the posted Service Invoice
        // [THEN] CustLedgerEntry.ShowDoc() return TRUE
        LibraryVariableStorage.Enqueue(ServiceInvoiceHeader."No."); // used in PostedServiceInvoicePH
        LibraryVariableStorage.Enqueue(ServiceInvoiceHeader."Customer No."); // used in PostedServiceInvoicePH
        Assert.IsTrue(CustLedgerEntry.ShowDoc(), ServiceInvoiceHeader.TableCaption());
        // Verify values in PostedServiceInvoicePH
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJournalLine_CopyFromServiceHeader_SalespersonCode()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 220803] Service Header's "Salesperson Code" is copied when perform GenJournalLine.CopyFromServiceHeader()
        ServiceHeader.Init();
        GenJournalLine.Init();
        ServiceHeader."Salesperson Code" := LibraryUtility.GenerateGUID();

        ServiceHeader.CopyToGenJournalLine(GenJournalLine);

        GenJournalLine.TestField("Salespers./Purch. Code", ServiceHeader."Salesperson Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerLedgerEntryHasSalespersonCodeAfterPostServiceInvoice()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ServiceInvoiceNo: Code[20];
    begin
        // [FEATURE] [Customer]
        // [SCENARIO 220803] Customer Ledger Entry's "Salesperson Code" has a value after post Service Invoice for a customer with "Salesperson Code"
        Initialize();

        // [GIVEN] Customer with "Salesperson Code" = "X"
        CreateCustomerWithSalesPersonCode(Customer);

        // [WHEN] Post service invoice
        ServiceInvoiceNo := CreatePostServiceInvoice(Customer."No.");

        // [THEN] Customer ledger entry related to the posted service invoice has "Salesperson Code" = "X"
        FindCustLedgEntry(CustLedgerEntry, ServiceInvoiceNo, Customer."No.");
        CustLedgerEntry.TestField("Salesperson Code", Customer."Salesperson Code");
    end;

    [Test]
    [HandlerFunctions('CreateEmptyPostedInvConfirmHandler')]
    [Scope('OnPrem')]
    procedure EmptyPostedDocCreationConfirmOnServiceInvoiceDeletion()
    var
        ServiceHeader: Record "Service Header";
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        // [FEATURE] [Invoice] [Deletion]
        // [SCENARIO 226743] If "Posted Service Invoice Nos." and "Invoice Nos." No. Series are the same, then on deletion of Service Invoice before posting, then confirmation for creation of empty posted invoice must appear

        // [GIVEN] "Posted Invoice Nos." and "Service Invoice Nos." No. Series are the same
        ServiceMgtSetup.Get();
        ServiceMgtSetup.Validate("Service Invoice Nos.", ServiceMgtSetup."Posted Service Invoice Nos.");
        ServiceMgtSetup.Modify(true);

        // [GIVEN] Sales Invoice with "No." = 1111
        ServiceHeader.Init();
        ServiceHeader.Validate("Document Type", ServiceHeader."Document Type"::Invoice);
        ServiceHeader.Validate("Customer No.", LibrarySales.CreateCustomerNo());
        ServiceHeader.Insert(true);

        ServiceHeader.Validate("Posting No. Series", ServiceHeader."No. Series");
        ServiceHeader.Modify(true);

        LibraryVariableStorage.Enqueue(
          StrSubstNo(ConfirmCreateEmptyPostedInvMsg, ServiceHeader."No."));

        // [WHEN] Delete Sales Invoice
        ServiceHeader.ConfirmDeletion();

        // [THEN] "Deleting this document will cause a gap in the number series for posted invoices. An empty posted invoice 1111 will be created" error appear
        // Checked within CreateEmptyPostedInvConfirmHandler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostWithShipmentCreatesResLedgerEntryTypeUsage()
    var
        ServiceHeader: Record "Service Header";
        ResourceNo: Code[20];
    begin
        // [SCENARIO 230253] When "Shipment on Invoice" is TRUE in Service Setup and Service Invoice is posted, then entry Type "Usage" is created in Res. Ledger Entry for Posted Service Shipment
        Initialize();

        // [GIVEN] Enable "Shipment on Invoice" in Service Mgt. Setup
        LibraryService.SetShipmentOnInvoice(true);

        // [GIVEN] Service Invoice with Resource
        ResourceNo := LibraryResource.CreateResourceNo();
        CreateServiceInvoiceWithResource(ServiceHeader, ResourceNo);

        // [WHEN] Post Service Invoice
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Resource Ledger Entry with type "Usage" is created with "Document No" = Posted Service Shipment "No."
        VerifyResourceLedgerEntryTypeUsage(ServiceHeader."Last Shipping No.", ResourceNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostWithoutShipmentCreatesResLedgerEntryTypeUsage()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ResourceNo: Code[20];
        PreAssignedNo: Code[20];
    begin
        // [SCENARIO 230253] When "Shipment on Invoice" is FALSE in Service Setup and Service Invoice is posted, then entry Type "Usage" is created in Res. Ledger Entry for Posted Service Invoice
        Initialize();

        // [GIVEN] Disable "Shipment on Invoice" in Service Mgt. Setup
        LibraryService.SetShipmentOnInvoice(false);

        // [GIVEN] Service Invoice with Resource
        ResourceNo := LibraryResource.CreateResourceNo();
        PreAssignedNo := CreateServiceInvoiceWithResource(ServiceHeader, ResourceNo);

        // [WHEN] Post Service Invoice
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Resource Ledger Entry with with type "Usage" is created with "Document No" = Posted Service Invoice "No."
        ServiceInvoiceHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        Assert.RecordCount(ServiceInvoiceHeader, 1);
        ServiceInvoiceHeader.FindFirst();
        VerifyResourceLedgerEntryTypeUsage(ServiceInvoiceHeader."No.", ResourceNo);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostServInvoiceWithReplacePostingDate()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        Type: Option ,Item,Resource,Both;
    begin
        // [FEATURE] [Batch Posting] [Allowed Posting Period]
        // [SCENARIO 276974] "Replace Posting Date" is TRUE, posting date of document is replaced and document is posted correctly, because new posting date is inside allowed posting date period
        Initialize();

        // [GIVEN] A service order with a line
        CreateServiceOrder(ServiceHeader, ServiceItemLine, ServiceLine, ServiceItem, Type::Item);
        // [GIVEN] Workdate is 15-01. This service order has Posting Date = 14-01
        ServiceHeader.SetHideValidationDialog(true);
        ServiceHeader.Validate("Posting Date", WorkDate() - 1);
        ServiceHeader.SetHideValidationDialog(false);
        // [GIVEN] Allowed Posting Date is 15-01 to 25-01
        LibraryERM.SetAllowPostingFromTo(WorkDate(), LibraryRandom.RandDate(10));
        Commit();

        // [WHEN] Batch Post Service order report is invoked with ReplacePostingDate enabled and new PostDate = 16-01
        BatchPostServiceOrder(ServiceHeader, WorkDate() + 1, true, false, false);

        // [THEN] Service Order is posted successfully
        VerifyPostedServiceOrder(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CannotPostServInvoiceWithReplacePostingDate()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        Type: Option ,Item,Resource,Both;
    begin
        // [FEATURE] [Batch Posting] [Allowed Posting Period]
        // [SCENARIO 276974] "Replace Posting Date" is TRUE, posting date of document is replaced and document is not posted, because new posting date is outside of allowed posting date period
        Initialize();

        // [GIVEN] A service order with a line
        CreateServiceOrder(ServiceHeader, ServiceItemLine, ServiceLine, ServiceItem, Type::Item);
        // [GIVEN] Workdate is 15-01. This service order has Posting Date = 16-01
        ServiceHeader.SetHideValidationDialog(true);
        ServiceHeader.Validate("Posting Date", WorkDate() + 1);
        ServiceHeader.SetHideValidationDialog(false);
        // [GIVEN] Allowed Posting Date is 15-01 to 25-01
        LibraryERM.SetAllowPostingFromTo(WorkDate(), LibraryRandom.RandDate(10));
        Commit();

        // [WHEN] Batch Post Service order report is invoked with ReplacePostingDate enabled and new PostDate = 14-01
        BatchPostServiceOrder(ServiceHeader, WorkDate() - 1, true, false, false);

        // [THEN] Service Order is not posted
        VerifyNotPostedServiceOrder(ServiceHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExternalDocNoWhenExtDocNoMandatoryNo()
    var
        ServiceHeader: Record "Service Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [External Document No.]
        // [SCENARIO 287958] External Document No. processing does not depend on SalesSetup.Ext. Doc. No. Mandatory
        Initialize();

        // [GIVEN] Set SalesSetup.Ext. Doc. No. Mandatory = No
        SetSalesSetupExtDocNoMandatory(false);

        // [GIVEN] Create sales invoice with line
        CustomerNo := LibrarySales.CreateCustomerNo();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, CustomerNo);
        CreateServiceLine(ServiceHeader);

        // [WHEN] Service invoice is being posted
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Created customer ledger entry has External Document No. = ServiceHeader."No."
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.TestField("External Document No.", ServiceHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckExternalDocNoOnPostedServiceInvoice()
    var
        ServiceHeader: Record "Service Header";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [External Document No.]
        // [SCENARIO 348592] External Document No. same logic like it is on Sales documents
        Initialize();

        // [GIVEN] Create sales invoice with line
        CustomerNo := LibrarySales.CreateCustomerNo();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, CustomerNo);
        ServiceHeader."External Document No." := LibraryUtility.GenerateRandomText(35);
        ServiceHeader.Modify();
        CreateServiceLine(ServiceHeader);

        // [WHEN] Service invoice is being posted
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Posted Documents and Ledger Entries containes External Document No.
        CheckExternalDocumentNoCopied(CustomerNo, ServiceHeader."Document Type", ServiceHeader."No.", ServiceHeader."External Document No.")
    end;

    local procedure CheckExternalDocumentNoCopied(CustomerNo: Code[20]; ServiceDocumentType: Enum "Service Document Type"; ServiceDocumentNo: Code[20]; ExternalDocumentNo: Code[35])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.TestField("External Document No.", ExternalDocumentNo);

        ServiceInvoiceHeader.SetRange("Customer No.", CustomerNo);
        case ServiceDocumentType of
            ServiceDocumentType::Order:
                ServiceInvoiceHeader.SetRange("Order No.", ServiceDocumentNo);
            ServiceDocumentType::Invoice:
                ServiceInvoiceHeader.SetRange("Pre-Assigned No.", ServiceDocumentNo);
        end;

        ServiceInvoiceHeader.FindFirst();
        ServiceInvoiceHeader.TestField("External Document No.", ExternalDocumentNo);
    end;

    [Test]
    [HandlerFunctions('PostBatchRequestValuesHandler1,MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure BatchPostServiceCrMemosRequestValuesNotOverriddenWhenRunInBackground()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        RequestPageXML: Text;
    begin
        // [SCENARIO] Saved Request page values are not overridden when running the batch job in background.

        // [GIVEN] Saved request page values.
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryVariableStorage.Enqueue(true);
        BindSubscription(TestClientTypeSubscriber);
        TestClientTypeSubscriber.SetClientType(ClientType::Desktop);
        RequestPageXML := Report.RunRequestPage(Report::"Batch Post Service Cr. Memos", RequestPageXML);

        // [WHEN] Running the request page in the background.
        LibraryVariableStorage.Enqueue(false);
        TestClientTypeSubscriber.SetClientType(ClientType::Background);
        RequestPageXML := Report.RunRequestPage(Report::"Batch Post Service Cr. Memos", RequestPageXML);

        // [THEN] The saved request page values are not overriden (see PostBatchRequestValuesHandler1).

        // [WHEN] Running the request page as desktop.
        LibraryVariableStorage.Enqueue(false);
        TestClientTypeSubscriber.SetClientType(ClientType::Desktop);
        asserterror RequestPageXML := Report.RunRequestPage(Report::"Batch Post Service Cr. Memos", RequestPageXML);

        // [THEN] The saved request page values are overridden.
    end;

    [Test]
    [HandlerFunctions('PostBatchRequestValuesHandler2,MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure BatchPostServiceInvoicesRequestValuesNotOverriddenWhenRunInBackground()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        RequestPageXML: Text;
    begin
        // [SCENARIO] Saved Request page values are not overridden when running the batch job in background.

        // [GIVEN] Saved request page values.
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryVariableStorage.Enqueue(true);
        BindSubscription(TestClientTypeSubscriber);
        TestClientTypeSubscriber.SetClientType(ClientType::Desktop);
        RequestPageXML := Report.RunRequestPage(Report::"Batch Post Service Invoices", RequestPageXML);

        // [WHEN] Running the request page in the background.
        LibraryVariableStorage.Enqueue(false);
        TestClientTypeSubscriber.SetClientType(ClientType::Background);
        RequestPageXML := Report.RunRequestPage(Report::"Batch Post Service Invoices", RequestPageXML);

        // [THEN] The saved request page values are not overriden (see PostBatchRequestValuesHandler2).

        // [WHEN] Running the request page as desktop.
        LibraryVariableStorage.Enqueue(false);
        TestClientTypeSubscriber.SetClientType(ClientType::Desktop);
        asserterror RequestPageXML := Report.RunRequestPage(Report::"Batch Post Service Invoices", RequestPageXML);

        // [THEN] The saved request page values are overridden.
    end;

    [Test]
    [HandlerFunctions('PostBatchRequestValuesHandler3,MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure BatchPostServiceOrdersRequestValuesNotOverriddenWhenRunInBackground()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        RequestPageXML: Text;
    begin
        // [SCENARIO] Saved Request page values are not overridden when running the batch job in background.

        // [GIVEN] Saved request page values.
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryVariableStorage.Enqueue(true);
        BindSubscription(TestClientTypeSubscriber);
        TestClientTypeSubscriber.SetClientType(ClientType::Desktop);
        RequestPageXML := Report.RunRequestPage(Report::"Batch Post Service Orders", RequestPageXML);

        // [WHEN] Running the request page in the background.
        LibraryVariableStorage.Enqueue(false);
        TestClientTypeSubscriber.SetClientType(ClientType::Background);
        RequestPageXML := Report.RunRequestPage(Report::"Batch Post Service Orders", RequestPageXML);

        // [THEN] The saved request page values are not overriden (see PostBatchRequestValuesHandler3).

        // [WHEN] Running the request page as desktop.
        LibraryVariableStorage.Enqueue(false);
        TestClientTypeSubscriber.SetClientType(ClientType::Desktop);
        asserterror RequestPageXML := Report.RunRequestPage(Report::"Batch Post Service Orders", RequestPageXML);

        // [THEN] The saved request page values are overridden.
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ModalEmailEditorHandler,ModalEmailRelationPickerHandler,CancelMailSendingStrMenuHandler')]
    procedure PostServiceInvoiceAndSendViaMail()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ResourceNo: Code[20];
    begin
        // [SCENARIO 466584] When Posted Service Invoice is sent via mail in EMail Related Records system should store data about Customer
        Initialize();

        // [WHEN] A connector is installed and an account is added
        InstallConnectorAndAddAccount();

        // [GIVEN] Create Service Invoice with Resource
        ResourceNo := LibraryResource.CreateResourceNo();
        CreateServiceInvoiceWithResource(ServiceHeader, ResourceNo);

        // [GIVEN] Post Service Invoice
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        ServiceInvoiceHeader.Get(ServiceHeader."Last Posting No.");

        // [WHEN] Posted Service Invoice is sent to a customer (discarded mail)
        CustomReportSelectionPrint(ServiceInvoiceHeader, Enum::"Report Selection Usage"::"SM.Invoice", 2);

        // [THEN] Reservation entry should be deleted for Non-Inventory Item and not exist in Reservation Entry table.
        CheckCustomerAddedToMailRelation(ServiceInvoiceHeader."Customer No.");

        LibraryVariableStorage.Clear();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReservationEntryDeletedAfterPostingNonInventoryServiceInvoice()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ReservationEntry: Record "Reservation Entry";
        ItemNo: Code[20];
        CustomerNo: Code[20];
        ServiceItemNo: Code[20];
        SerialNo: Code[50];
    begin
        // [SCENARIO 498734] No Orphaned surplus entry when doing a Service Credit Memo on a non-inventory item with serial number
        Initialize();

        // [GIVEN] Create Customer 
        CustomerNo := CreateCustomer();

        // [GIVEN] Create Service Invoice Header
        CreateServiceInvoiceHeader(ServiceHeader, CustomerNo);

        // [GIVEN] Create Non-Inventory Item with Service Item
        CreateNonInventoryItemWithServiceItem(CustomerNo, ItemNo, ServiceItemNo);

        // [GIVEN] Create SerialNo and Enqueue
        SerialNo := Format(LibraryRandom.RandText(50));
        LibraryVariableStorage.Enqueue(SerialNo);

        // [GIVEN] Add Service Item in Service Line with new Serial No.
        CreateServiceLineReplacement(ServiceLine, ServiceHeader, ItemNo, ServiceItemNo);

        // [WHEN] Post Service Invoice
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Find the Reservation Entry 
        ReservationEntry.SetRange("Item No.", ServiceItemNo);
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
        ReservationEntry.SetRange("Source Type", Database::"Service Line");
        ReservationEntry.SetRange("Source ID", ServiceHeader."No.");
        ReservationEntry.SetRange("Serial No.", SerialNo);

        // [THEN] Reservation entry should be deleted for Non-Inventory Item and not exist in Reservation Entry table.
        Assert.IsTrue(ReservationEntry.IsEmpty(), ReservationEntryNotFoundErr);

        LibraryVariableStorage.Clear();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestPostedServiceInvoiceWorkDescription()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        WorkDescription: Text;
    begin
        // [SCCENARIO 568647] Verify "Work Description" is copied to Service Invoice Header
        Initialize();

        // [GIVEN] Create Service Order
        CreateServiceHeaderWithMultipleLines(ServiceHeader);

        // [GIVEN] Service Order with non-empty "Work Description"
        ServiceHeader.Find('=');
        WorkDescription := LibraryRandom.RandText(10);
        ServiceHeader.SetWorkDescription(WorkDescription);
        Assert.AreEqual(WorkDescription, ServiceHeader.GetWorkDescription(), '');
        Commit();

        // [WHEN] Batch Post Service order report is invoked
        BatchPostServiceOrder(ServiceHeader, WorkDate(), true, false, false);

        // [THEN] Verify "Work Description" is copied to Service Invoice Header
        FindServiceInvoiceFromOrder(ServiceInvoiceHeader, ServiceHeader."No.");
        Assert.AreEqual(WorkDescription, ServiceInvoiceHeader.GetWorkDescription(), '');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestPostedServiceShipmentWorkDescription()
    var
        ServiceHeader: Record "Service Header";
        ServiceShipmentHeader: Record "Service Shipment Header";
        WorkDescription: Text;
    begin
        // [SCCENARIO 568647] Verify "Work Description" is copied to Service Shipment Header
        Initialize();

        // [GIVEN] Create Service Order
        CreateServiceHeaderWithMultipleLines(ServiceHeader);

        // [GIVEN] Service Order with non-empty "Work Description"
        ServiceHeader.Find('=');
        WorkDescription := LibraryRandom.RandText(10);
        ServiceHeader.SetWorkDescription(WorkDescription);
        Assert.AreEqual(WorkDescription, ServiceHeader.GetWorkDescription(), '');
        Commit();

        // [WHEN] Batch Post Service order report is invoked
        BatchPostServiceOrder(ServiceHeader, WorkDate(), true, false, false);

        // [THEN] Verify "Work Description" is copied to Service Shipment Header
        FindServiceShipmentHeader(ServiceShipmentHeader, ServiceHeader."No.");
        Assert.AreEqual(WorkDescription, ServiceShipmentHeader.GetWorkDescription(), '');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestPostedServiceCrMemoWorkDescription()
    var
        ServiceHeader: Record "Service Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        WorkDescription: Text;
    begin
        // [SCCENARIO 568647] Verify "Work Description" is copied to Service Cr.Memo Header
        Initialize();

        // [GIVEN] Create Service Cr.Memo
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo());
        CreateMultipleServiceLines(ServiceHeader, '');

        // [GIVEN] Service Order with non-empty "Work Description"
        ServiceHeader.Find('=');
        WorkDescription := LibraryRandom.RandText(10);
        ServiceHeader.SetWorkDescription(WorkDescription);
        Assert.AreEqual(WorkDescription, ServiceHeader.GetWorkDescription(), '');
        Commit();

        // [WHEN] Batch Post Service Cr.Memo report is invoked
        BatchPostServiceCreditMemos(ServiceHeader, WorkDate(), false, false, false);

        // [THEN] Verify "Work Description" is copied to Service Cr.Memo Header
        FindServiceCreditMemoHeader(ServiceCrMemoHeader, ServiceHeader."No.");
        Assert.AreEqual(WorkDescription, ServiceCrMemoHeader.GetWorkDescription(), '');
    end;

    [Test]
    procedure TestYourReferenceTransferredToCustomerLedgerEntryFromInvoice()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        YourReference: Text[35];
    begin
        // [SCENARIO] Verify "Your Reference" is transferred from Service Invoice to Customer Ledger Entry
        Initialize();

        // [GIVEN] Create Service Invoice with "Your Reference" field populated
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        YourReference := CopyStr(LibraryRandom.RandText(MaxStrLen(ServiceHeader."Your Reference")),
            1, MaxStrLen(ServiceHeader."Your Reference"));
        ServiceHeader."Your Reference" := YourReference;
        ServiceHeader.Modify(true);

        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup());
        ServiceLine.Validate(Quantity, 1);
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ServiceLine.Modify(true);

        // [WHEN] Post the Service Invoice
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Verify "Your Reference" is transferred to Customer Ledger Entry
        FindServiceInvoiceHeader(ServiceInvoiceHeader, ServiceHeader."No.");

        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Document No.", ServiceInvoiceHeader."No.");
        CustLedgerEntry.SetRange("Customer No.", ServiceHeader."Bill-to Customer No.");
        CustLedgerEntry.FindFirst();

        Assert.AreEqual(YourReference, CustLedgerEntry."Your Reference",
            'Your Reference should be transferred from Service Header to Customer Ledger Entry');
    end;

    [Test]
    procedure TestYourReferenceTransferredToCustomerLedgerEntryFromCreditMemo()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        YourReference: Text[35];
    begin
        // [SCENARIO] Verify "Your Reference" is transferred from Service Credit Memo to Customer Ledger Entry
        Initialize();

        // [GIVEN] Create Service Credit Memo with "Your Reference" field populated
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo());
        YourReference := CopyStr(LibraryRandom.RandText(MaxStrLen(ServiceHeader."Your Reference")),
            1, MaxStrLen(ServiceHeader."Your Reference"));
        ServiceHeader."Your Reference" := YourReference;
        ServiceHeader.Modify(true);

        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup());
        ServiceLine.Validate(Quantity, 1);
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ServiceLine.Modify(true);

        // [WHEN] Post the Service Credit Memo
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Verify "Your Reference" is transferred to Customer Ledger Entry
        FindServiceCreditMemoHeader(ServiceCrMemoHeader, ServiceHeader."No.");

        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::"Credit Memo");
        CustLedgerEntry.SetRange("Document No.", ServiceCrMemoHeader."No.");
        CustLedgerEntry.SetRange("Customer No.", ServiceHeader."Bill-to Customer No.");
        CustLedgerEntry.FindFirst();

        Assert.AreEqual(YourReference, CustLedgerEntry."Your Reference",
            'Your Reference should be transferred from Service Credit Memo to Customer Ledger Entry');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Posting - Invoice");
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Service Posting - Invoice");

        // Setup demonstration data.
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateAccountInServiceCosts();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryService.SetupServiceMgtNoSeries();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        isInitialized := true;
        Commit();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Service Mgt. Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Service Posting - Invoice");
    end;

    local procedure BatchPostServiceCreditMemos(ServiceHeader: Record "Service Header"; PostingDate: Date; ReplacePostingDate: Boolean; ReplaceDocumentDate: Boolean; CalculateInvoiceDiscount: Boolean)
    var
        BatchPostServiceCrMemos: Report "Batch Post Service Cr. Memos";
    begin
        ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceHeader.SetRange("No.", ServiceHeader."No.");
        Clear(BatchPostServiceCrMemos);
        BatchPostServiceCrMemos.SetTableView(ServiceHeader);
        BatchPostServiceCrMemos.InitializeRequest(PostingDate, ReplacePostingDate, ReplaceDocumentDate, CalculateInvoiceDiscount);
        BatchPostServiceCrMemos.UseRequestPage(false);
        BatchPostServiceCrMemos.Run();
    end;

    local procedure BatchPostServiceInvoices(ServiceHeader: Record "Service Header"; PostingDate: Date; ReplacePostingDate: Boolean; ReplaceDocumentDate: Boolean; CalculateInvoiceDiscount: Boolean)
    var
        BatchPostServiceInvoices: Report "Batch Post Service Invoices";
    begin
        ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceHeader.SetRange("No.", ServiceHeader."No.");
        Clear(BatchPostServiceInvoices);
        BatchPostServiceInvoices.SetTableView(ServiceHeader);
        BatchPostServiceInvoices.InitializeRequest(PostingDate, ReplacePostingDate, ReplaceDocumentDate, CalculateInvoiceDiscount);
        BatchPostServiceInvoices.UseRequestPage(false);
        BatchPostServiceInvoices.Run();
    end;

    local procedure BatchPostServiceOrder(ServiceHeader: Record "Service Header"; PostingDate: Date; ReplacePostingDate: Boolean; ReplaceDocumentDate: Boolean; CalculateInvoiceDiscount: Boolean)
    var
        BatchPostServiceOrders: Report "Batch Post Service Orders";
    begin
        ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceHeader.SetRange("No.", ServiceHeader."No.");
        Clear(BatchPostServiceOrders);
        BatchPostServiceOrders.SetTableView(ServiceHeader);
        BatchPostServiceOrders.InitializeRequest(true, true, PostingDate, ReplacePostingDate, ReplaceDocumentDate, CalculateInvoiceDiscount);
        BatchPostServiceOrders.UseRequestPage(false);
        BatchPostServiceOrders.Run();
    end;

    local procedure CalculateTotlAmountShippedLine(OrderNo: Code[20]) TotalAmount: Decimal
    var
        ServiceInvoiceLine: Record "Service Invoice Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        ServiceInvoiceHeader.SetRange("Order No.", OrderNo);
        ServiceInvoiceHeader.FindFirst();
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        ServiceInvoiceLine.FindSet();
        repeat
            TotalAmount += ServiceInvoiceLine."Amount Including VAT";
        until ServiceInvoiceLine.Next() = 0;
    end;

    local procedure CreateMultipleServiceLines(ServiceHeader: Record "Service Header"; ServiceItemNo: Code[20])
    var
        ServiceLine: Record "Service Line";
        Counter: Integer;
    begin
        // Create 2 to random number of lines.
        for Counter := 1 to 1 + LibraryRandom.RandInt(10) do begin
            CreateServiceLineWithItem(ServiceLine, ServiceHeader, ServiceItemNo);
            ServiceLine.Validate("Unit Price", 10 * LibraryRandom.RandDec(100, 2));  // Input random decimal quantity.
            ServiceLine.Modify(true);
        end;
    end;

    local procedure CreateServiceLine(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        ServiceLine.Validate(Quantity, LibraryRandom.RandDec(100, 2));
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceLineWithCost(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; ServiceItemNo: Code[20])
    var
        ServiceCost: Record "Service Cost";
    begin
        LibraryService.FindServiceCost(ServiceCost);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Cost, ServiceCost.Code);
        ServiceLine.Validate("Service Item No.", ServiceItemNo);
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(100));  // Required field - value is not important to test case.
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceLineWithGLAccount(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; ServiceItemNo: Code[20])
    begin
        LibraryService.CreateServiceLine(
          ServiceLine, ServiceHeader, ServiceLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup());
        ServiceLine.Validate("Service Item No.", ServiceItemNo);
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(100));  // Required field - value is not important to test case.
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceLineWithItem(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; ServiceItemNo: Code[20])
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, CreateItem());
        ServiceLine.Validate("Service Item No.", ServiceItemNo);
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(100));  // Required field - value is not important to test case.
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceLineWithResource(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; ServiceItemNo: Code[20])
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Resource, CreateResource());
        ServiceLine.Validate("Service Item No.", ServiceItemNo);
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(100));  // Required field - value is not important to test case.
        ServiceLine.Modify(true);
    end;

    local procedure CreateEmptyServiceLine(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.Init();
        ServiceLine.Validate("Document Type", ServiceHeader."Document Type");
        ServiceLine.Validate("Document No.", ServiceHeader."No.");
        ServiceLine.Insert(true);
    end;

    local procedure CreateServiceOrder(var ServiceHeader: Record "Service Header"; var ServiceItemLine: Record "Service Item Line"; var ServiceLine: Record "Service Line"; var ServiceItem: Record "Service Item"; Type: Option ,Item,Resource,Both)
    var
        Customer: Record Customer;
    begin
        // Create Service Order - Service Item, Service Header, Service Line with Type as Item.
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        if Type in [Type::Item, Type::Both] then
            CreateServiceLineWithItem(ServiceLine, ServiceHeader, ServiceItem."No.");
        if Type in [Type::Resource, Type::Both] then begin
            CreateServiceLineWithResource(ServiceLine, ServiceHeader, ServiceItem."No.");
            CreateServiceLineWithCost(ServiceLine, ServiceHeader, ServiceItem."No.");
            CreateServiceLineWithGLAccount(ServiceLine, ServiceHeader, ServiceItem."No.");
        end;
    end;

    local procedure CreatePostServiceInvoice(CustomerNo: Code[20]): Code[20]
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, CustomerNo);
        CreateServiceLine(ServiceHeader);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        FindServiceInvoiceHeader(ServiceInvoiceHeader, ServiceHeader."No.");
        exit(ServiceInvoiceHeader."No.");
    end;

    local procedure CreateItem(): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Item: Record Item;
    begin
        FindVATPostingSetup(VATPostingSetup);
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateResource(): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Resource: Record Resource;
    begin
        FindVATPostingSetup(VATPostingSetup);
        LibraryResource.CreateResource(Resource, VATPostingSetup."VAT Bus. Posting Group");
        Resource.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Resource.Modify(true);
        exit(Resource."No.");
    end;

    local procedure CreateServiceHeaderWithMultipleLines(var ServiceHeader: Record "Service Header")
    var
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
    begin
        LibraryService.CreateServiceItem(ServiceItem, LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        CreateMultipleServiceLines(ServiceHeader, ServiceItem."No.");
        Commit();  // Commit is required to run the batch job.
    end;

    local procedure CreateMultipleServiceLineAndInvoiceDiscount(var ServiceHeader: Record "Service Header"; var CustInvoiceDisc: Record "Cust. Invoice Disc."; DocumentType: Enum "Service Document Type")
    var
        Customer: Record Customer;
    begin
        ModifyInvoiceDiscount();
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, Customer."No.", '', 0);  // Minimum amount is 0.
        UpdateCustomerInvoiceDiscount(CustInvoiceDisc);

        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, Customer."No.");
        CreateMultipleServiceLines(ServiceHeader, '');
        Commit();  // Commit is required to run the batch job.
    end;

    local procedure CreateServiceDocument(var ServiceHeader: Record "Service Header"; var ServiceItemLine: Record "Service Item Line"; CustomerNo: Code[20])
    var
        ServiceItem: Record "Service Item";
    begin
        LibraryService.CreateServiceItem(ServiceItem, CustomerNo);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CustomerNo);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
    end;

    local procedure CreateServiceInvoiceWithResource(var ServiceHeader: Record "Service Header"; ResourceNo: Code[20]): Code[20]
    var
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceLineWithQuantity(
          ServiceLine, ServiceHeader, ServiceLine.Type::Resource, ResourceNo, LibraryRandom.RandIntInRange(10, 20));
        exit(ServiceHeader."No.");
    end;

    local procedure CreateCustomerWithSalesPersonCode(var Customer: Record Customer)
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Salesperson Code", SalespersonPurchaser.Code);
        Customer.Modify(true);
    end;

    local procedure FindServiceCreditMemoHeader(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; PreAssignedNo: Code[20])
    begin
        ServiceCrMemoHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        ServiceCrMemoHeader.FindFirst();
    end;

    local procedure FindServiceCreditMemoLines(var ServiceCrMemoLine: Record "Service Cr.Memo Line"; DocumentNo: Code[20])
    begin
        ServiceCrMemoLine.SetRange("Document No.", DocumentNo);
        ServiceCrMemoLine.FindSet();
    end;

    local procedure FindServiceInvoiceFromOrder(var ServiceInvoiceHeader: Record "Service Invoice Header"; OrderNo: Code[20])
    begin
        ServiceInvoiceHeader.SetRange("Order No.", OrderNo);
        ServiceInvoiceHeader.FindFirst();
    end;

    local procedure FindServiceInvoiceHeader(var ServiceInvoiceHeader: Record "Service Invoice Header"; PreAssignedNo: Code[20])
    begin
        ServiceInvoiceHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        ServiceInvoiceHeader.FindFirst();
    end;

    local procedure FindServiceInvoiceLines(var ServiceInvoiceLine: Record "Service Invoice Line"; DocumentNo: Code[20])
    begin
        ServiceInvoiceLine.SetRange("Document No.", DocumentNo);
        ServiceInvoiceLine.FindSet();
    end;

    local procedure FindServiceShipmentHeader(var ServiceShipmentHeader: Record "Service Shipment Header"; OrderNo: Code[20])
    begin
        ServiceShipmentHeader.SetRange("Order No.", OrderNo);
        ServiceShipmentHeader.FindFirst();
    end;

    local procedure FindVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.SetRange("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
    end;

    local procedure FindCustLedgEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocumentNo: Code[20]; CustomerNo: Code[20])
    begin
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.FindFirst();
    end;

    local procedure ModifyCostPostngInventorySetup(AutomaticCostPosting: Boolean; ExpectedCostPostingtoGL: Boolean)
    var
        InventorySetup: Record "Inventory Setup";
    begin
        // Sometimes this function triggers a message and a confirm dialog
        // This is to make sure the corresponding handlers are always executed
        // (otherwise tests would fail)
        ExecuteUIHandlers();

        InventorySetup.Get();
        InventorySetup.Validate("Automatic Cost Posting", AutomaticCostPosting);
        InventorySetup.Validate("Expected Cost Posting to G/L", ExpectedCostPostingtoGL);
        InventorySetup.Modify(true);
    end;

    local procedure ModifyInvoiceDiscount()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Calc. Inv. Discount", false);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure ModifyQtyToInvoiceServiceLine(DocumentNo: Code[20])
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Order);
        ServiceLine.SetRange("Document No.", DocumentNo);
        ServiceLine.FindSet();
        repeat
            // Division by 2 ensures Qty. to Invoice is less than Quantity Shipped.
            ServiceLine.Validate("Qty. to Invoice", ServiceLine."Quantity Shipped" / 2);
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    local procedure ModifyQtyToShipOnServiceLine(DocumentNo: Code[20])
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Order);
        ServiceLine.SetRange("Document No.", DocumentNo);
        ServiceLine.FindSet();
        repeat
            ServiceLine.Validate("Qty. to Ship", ServiceLine."Qty. to Ship" * LibraryUtility.GenerateRandomFraction());
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    local procedure ModifyQtyToConsumeServiceLine(DocumentNo: Code[20])
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Order);
        ServiceLine.SetRange("Document No.", DocumentNo);
        ServiceLine.FindSet();
        repeat
            ServiceLine.Validate("Qty. to Consume", ServiceLine."Qty. to Ship" * LibraryUtility.GenerateRandomFraction());
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    local procedure ModifyQtyToInvoiceZero(DocumentNo: Code[20])
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Order);
        ServiceLine.SetRange("Document No.", DocumentNo);
        ServiceLine.FindSet();
        repeat
            ServiceLine.Validate("Qty. to Invoice", 0);  // Validate Qty. to Invoice as 0 - value 0 is important to test case.
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    local procedure PostServiceOrderLinebyLine(ServiceHeader: Record "Service Header")
    var
        TempServiceLine: Record "Service Line" temporary;
        ServiceLine: Record "Service Line";
        ServicePost: Codeunit "Service-Post";
        Ship: Boolean;
        Consume: Boolean;
        Invoice: Boolean;
    begin
        Ship := true;
        Invoice := true;
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.SetRange("Quantity Shipped", 0);
        ServiceLine.FindSet();
        repeat
            TempServiceLine := ServiceLine;
            TempServiceLine.Insert();
            ServiceHeader.Get(TempServiceLine."Document Type", TempServiceLine."Document No.");
            ServicePost.PostWithLines(ServiceHeader, TempServiceLine, Ship, Consume, Invoice);
            TempServiceLine.Delete();
        until ServiceLine.Next() = 0;
    end;

    local procedure PostSrvOrderAsShipForResource(ServiceHeader: Record "Service Header")
    var
        TempServiceLine: Record "Service Line" temporary;
        ServiceLine: Record "Service Line";
        ServicePost: Codeunit "Service-Post";
        Ship: Boolean;
        Consume: Boolean;
        Invoice: Boolean;
    begin
        Ship := true;
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.SetRange(Type, ServiceLine.Type::Resource);
        ServiceLine.FindFirst();
        TempServiceLine := ServiceLine;
        TempServiceLine.Insert();
        ServicePost.PostWithLines(ServiceHeader, TempServiceLine, Ship, Consume, Invoice);
    end;

    local procedure PostOrderAsShipForItemGLAccont(ServiceHeader: Record "Service Header")
    var
        TempServiceLine: Record "Service Line" temporary;
        ServiceLine: Record "Service Line";
        ServicePost: Codeunit "Service-Post";
        Ship: Boolean;
        Consume: Boolean;
        Invoice: Boolean;
    begin
        Ship := true;
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.SetFilter(Type, '<>%1', ServiceLine.Type::Resource);
        ServiceLine.SetRange("Quantity Shipped", 0);
        ServiceLine.FindSet();
        repeat
            TempServiceLine := ServiceLine;
            TempServiceLine.Insert();
            ServiceHeader.Get(TempServiceLine."Document Type", TempServiceLine."Document No.");
            ServicePost.PostWithLines(ServiceHeader, TempServiceLine, Ship, Consume, Invoice);
            TempServiceLine.Delete();
        until ServiceLine.Next() = 0;
    end;

    local procedure SaveServiceLineInTempTable(var TempServiceLine: Record "Service Line" temporary; ServiceLine: Record "Service Line")
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type");
        ServiceLine.SetRange("Document No.", ServiceLine."Document No.");
        ServiceLine.FindSet();
        repeat
            TempServiceLine := ServiceLine;
            TempServiceLine.Insert();
        until ServiceLine.Next() = 0;
    end;

    local procedure SetSalesSetupExtDocNoMandatory(ExtDocNoMandatory: Boolean)
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        SalesSetup.Validate("Ext. Doc. No. Mandatory", ExtDocNoMandatory);
        SalesSetup.Modify(true);
    end;

    local procedure UpdateCustomerInvoiceDiscount(var CustInvoiceDisc: Record "Cust. Invoice Disc.")
    begin
        // Input any random Discount percentage.
        CustInvoiceDisc.Validate("Discount %", LibraryRandom.RandDec(10, 2));
        CustInvoiceDisc.Modify(true);
    end;

    local procedure ValidateQtyToInvoiceServicLine(DocumentNo: Code[20])
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Order);
        ServiceLine.SetRange("Document No.", DocumentNo);
        ServiceLine.FindSet();
        repeat
            ServiceLine.Validate("Qty. to Invoice", ServiceLine."Quantity Shipped");
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    local procedure VerifyCustomerLedgerEntry(OrderNo: Code[20])
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        ServiceInvoiceHeader.SetRange("Order No.", OrderNo);
        ServiceInvoiceHeader.FindFirst();
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Document No.", ServiceInvoiceHeader."No.");
        CustLedgerEntry.FindFirst();
    end;

    local procedure VerifyDetailedCustLedgerEntry(OrderNo: Code[20]; TotalAmount: Decimal)
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        ServiceInvoiceHeader.SetRange("Order No.", OrderNo);
        ServiceInvoiceHeader.FindFirst();
        DetailedCustLedgEntry.SetRange("Document Type", DetailedCustLedgEntry."Document Type"::Invoice);
        DetailedCustLedgEntry.SetRange("Document No.", ServiceInvoiceHeader."No.");
        DetailedCustLedgEntry.FindSet();
        repeat
            DetailedCustLedgEntry.TestField(Amount, TotalAmount);
        until DetailedCustLedgEntry.Next() = 0;
    end;

    local procedure VerifyNonZeroDiscountInCredit(DocumentNo: Code[20]; InvoiceDiscountPct: Decimal)
    var
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        FindServiceCreditMemoLines(ServiceCrMemoLine, DocumentNo);
        repeat
            Assert.AreNearlyEqual(
              Round(ServiceCrMemoLine."Line Amount" * InvoiceDiscountPct / 100, GeneralLedgerSetup."Amount Rounding Precision"),
              ServiceCrMemoLine."Inv. Discount Amount",
              GeneralLedgerSetup."Amount Rounding Precision",
              StrSubstNo(
                AmountsMustMatchError,
                ServiceCrMemoLine.FieldCaption("Inv. Discount Amount"),
                ServiceCrMemoLine."Line Amount" * InvoiceDiscountPct / 100,
                ServiceCrMemoLine.TableCaption()));
        until ServiceCrMemoLine.Next() = 0;
    end;

    local procedure VerifyNonZeroDiscountInLines(DocumentNo: Code[20]; InvoiceDiscountPct: Decimal)
    var
        ServiceInvoiceLine: Record "Service Invoice Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        FindServiceInvoiceLines(ServiceInvoiceLine, DocumentNo);
        repeat
            Assert.AreNearlyEqual(
              Round(ServiceInvoiceLine."Line Amount" * InvoiceDiscountPct / 100, GeneralLedgerSetup."Amount Rounding Precision"),
              ServiceInvoiceLine."Inv. Discount Amount",
              GeneralLedgerSetup."Amount Rounding Precision",
              StrSubstNo(
                AmountsMustMatchError,
                ServiceInvoiceLine.FieldCaption("Inv. Discount Amount"),
                ServiceInvoiceLine."Line Amount" * InvoiceDiscountPct / 100,
                ServiceInvoiceLine.TableCaption()));
        until ServiceInvoiceLine.Next() = 0;
    end;

    local procedure VerifyQtyOnServiceShipmentLine(OrderNo: Code[20])
    var
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        ServiceShipmentLine.SetRange("Order No.", OrderNo);
        ServiceShipmentLine.FindSet();
        repeat
            ServiceShipmentLine.TestField(Quantity, ServiceShipmentLine."Quantity Invoiced");
        until ServiceShipmentLine.Next() = 0;
    end;

    local procedure VerifyQtyShippedOnServiceLine(DocumentNo: Code[20])
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Order);
        ServiceLine.SetRange("Document No.", DocumentNo);
        ServiceLine.FindSet();
        repeat
            ServiceLine.TestField("Quantity Shipped", 0);
        until ServiceLine.Next() = 0;
    end;

    local procedure VerifyResourceLedgerEntry(OrderNo: Code[20])
    var
        ServiceInvoiceLine: Record "Service Invoice Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ResLedgerEntry: Record "Res. Ledger Entry";
    begin
        ServiceInvoiceHeader.SetRange("Order No.", OrderNo);
        ServiceInvoiceHeader.FindFirst();
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        ServiceInvoiceLine.SetRange(Type, ServiceInvoiceLine.Type::Resource);
        ServiceInvoiceLine.FindFirst();
        ResLedgerEntry.SetRange("Document No.", ServiceInvoiceLine."Document No.");
        ResLedgerEntry.FindFirst();
        ResLedgerEntry.TestField(Quantity, -ServiceInvoiceLine.Quantity);
        ResLedgerEntry.TestField("Order Type", ResLedgerEntry."Order Type"::Service);
        ResLedgerEntry.TestField("Order No.", ServiceInvoiceHeader."Order No.");
        ResLedgerEntry.TestField("Order Line No.", ServiceInvoiceLine."Line No.");
    end;

    local procedure VerifyResourceLedgerEntryTypeUsage(DocumentNo: Code[20]; ResourceNo: Code[20])
    var
        ResLedgerEntry: Record "Res. Ledger Entry";
    begin
        ResLedgerEntry.SetRange("Entry Type", ResLedgerEntry."Entry Type"::Usage);
        ResLedgerEntry.SetRange("Document No.", DocumentNo);
        ResLedgerEntry.SetRange("Resource No.", ResourceNo);
        Assert.RecordCount(ResLedgerEntry, 1);
    end;

    local procedure VerifyServiceOrderGLEntry(OrderNo: Code[20])
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        GLEntry: Record "G/L Entry";
    begin
        ServiceInvoiceHeader.SetRange("Order No.", OrderNo);
        ServiceInvoiceHeader.FindFirst();
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("Document No.", ServiceInvoiceHeader."No.");
        GLEntry.SetRange("Source Type", GLEntry."Source Type"::Customer);
        GLEntry.FindSet();
        repeat
            GLEntry.TestField("Source No.", ServiceInvoiceHeader."Bill-to Customer No.");
            GLEntry.TestField("Posting Date", ServiceInvoiceHeader."Posting Date");
        until GLEntry.Next() = 0;
    end;

    local procedure VerifyServiceOrderVATEntry(OrderNo: Code[20])
    var
        ServiceInvoiceLine: Record "Service Invoice Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        VATEntry: Record "VAT Entry";
    begin
        ServiceInvoiceHeader.SetRange("Order No.", OrderNo);
        ServiceInvoiceHeader.FindFirst();
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        ServiceInvoiceLine.FindFirst();
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.SetRange("Document No.", ServiceInvoiceLine."Document No.");
        VATEntry.FindFirst();
        VATEntry.TestField(Base, -ServiceInvoiceLine."VAT Base Amount");
    end;

    local procedure VerifyServiceLedgerEntry(OrderNo: Code[20]; CustomerNo: Code[20])
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        ServiceLedgerEntry.SetRange("Document Type", ServiceLedgerEntry."Document Type"::Invoice);
        ServiceLedgerEntry.SetRange("Service Order No.", OrderNo);
        ServiceLedgerEntry.FindSet();
        repeat
            ServiceLedgerEntry.TestField("Customer No.", CustomerNo);
        until ServiceLedgerEntry.Next() = 0;
    end;

    local procedure VerifySourceNoOnValueEntry(ItemNo: Code[20]; SourceCode: Code[20])
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.FindFirst();
        ValueEntry.TestField("Source No.", SourceCode);
    end;

    local procedure VerifyOrderItemLedgerEntry(ServiceLine: Record "Service Line")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Service Shipment");
        ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type"::Service);
        ItemLedgerEntry.SetRange("Order No.", ServiceLine."Document No.");
        ItemLedgerEntry.FindSet();
        repeat
            ItemLedgerEntry.TestField("Item No.", ServiceLine."No.");
            ItemLedgerEntry.TestField(Quantity, -ServiceLine.Quantity);
        until ItemLedgerEntry.Next() = 0;
    end;

    local procedure VerifyInvoiceQtyItemLedger(OrderNo: Code[20])
    var
        ServiceShipmentLine: Record "Service Shipment Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ServiceShipmentLine.SetRange("Order No.", OrderNo);
        ServiceShipmentLine.FindFirst();
        ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Service Shipment");
        ItemLedgerEntry.SetRange("Document No.", ServiceShipmentLine."Document No.");
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField("Item No.", ServiceShipmentLine."No.");
        ItemLedgerEntry.TestField("Invoiced Quantity", -ServiceShipmentLine."Quantity Invoiced");
    end;

    local procedure VerifyServiceOrderValueEntry(OrderNo: Code[20])
    var
        ServiceShipmentLine: Record "Service Shipment Line";
        ValueEntry: Record "Value Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Service Shipment");
        ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type"::Service);
        ItemLedgerEntry.SetRange("Order No.", OrderNo);
        ItemLedgerEntry.FindFirst();
        ServiceShipmentLine.SetRange("Order No.", ItemLedgerEntry."Order No.");
        ServiceShipmentLine.FindFirst();
        ValueEntry.SetRange("Item Ledger Entry Type", ItemLedgerEntry."Entry Type");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntry."Entry No.");
        ValueEntry.FindFirst();
        ValueEntry.TestField("Valued Quantity", -ServiceShipmentLine.Quantity);
    end;

    local procedure VerifyVATEntry(OrderNo: Code[20])
    var
        ServiceInvoiceLine: Record "Service Invoice Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        VATEntry: Record "VAT Entry";
        VatBaseAmount: Decimal;
    begin
        ServiceInvoiceHeader.SetRange("Order No.", OrderNo);
        ServiceInvoiceHeader.FindFirst();
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        ServiceInvoiceLine.FindFirst();
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.SetRange("Document No.", ServiceInvoiceLine."Document No.");
        VATEntry.FindSet();
        repeat
            VatBaseAmount += VATEntry.Base;
        until VATEntry.Next() = 0;
        Assert.AreEqual(
          ServiceInvoiceLine."VAT Base Amount", -VatBaseAmount, StrSubstNo(BaseAmountError, -ServiceInvoiceLine."VAT Base Amount"));
    end;

    local procedure VerifyZeroDiscountCreditLines(DocumentNo: Code[20])
    var
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
    begin
        FindServiceCreditMemoLines(ServiceCrMemoLine, DocumentNo);
        repeat
            ServiceCrMemoLine.TestField("Inv. Discount Amount", 0);
        until ServiceCrMemoLine.Next() = 0;
    end;

    local procedure VerifyZeroDiscountInLines(DocumentNo: Code[20])
    var
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        FindServiceInvoiceLines(ServiceInvoiceLine, DocumentNo);
        repeat
            ServiceInvoiceLine.TestField("Inv. Discount Amount", 0);
        until ServiceInvoiceLine.Next() = 0;
    end;

    local procedure VerifyItemLedgerAndValueEntriesAfterUndoConsumption(var TempServiceLineBeforePosting: Record "Service Line" temporary)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        RelatedItemLedgerEntry: Record "Item Ledger Entry";
        Tolerance: Decimal;
    begin
        // Verify that the value of the field Quantity of the Item Ledger Entry is equal to the value of the field Qty. to Ship of the
        // relevant Service Line.
        Tolerance := 0.000005;
        TempServiceLineBeforePosting.SetRange(Type, TempServiceLineBeforePosting.Type::Item);
        TempServiceLineBeforePosting.FindSet();
        ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Service Shipment");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Negative Adjmt.");
        ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type"::Service);
        ItemLedgerEntry.SetRange("Order No.", TempServiceLineBeforePosting."Document No.");
        ItemLedgerEntry.SetRange(Correction, false);
        repeat
            ItemLedgerEntry.SetRange("Order Line No.", TempServiceLineBeforePosting."Line No.");
            ItemLedgerEntry.FindLast();  // Find the Item Ledger Entry for the second action.
            Assert.AreNearlyEqual(
              ItemLedgerEntry.Quantity, -TempServiceLineBeforePosting."Qty. to Consume", Tolerance,
              'Quantity and Quantity Consumed are nearly equal');
            Assert.AreNearlyEqual(
              ItemLedgerEntry."Invoiced Quantity", -TempServiceLineBeforePosting."Qty. to Consume", Tolerance,
              'Quantity Consumed and Invoiced Quantity are nearly equal');
            RelatedItemLedgerEntry.SetRange("Applies-to Entry", ItemLedgerEntry."Applies-to Entry");
            RelatedItemLedgerEntry.FindFirst();
            ItemLedgerEntry.TestField("Cost Amount (Actual)", -RelatedItemLedgerEntry."Cost Amount (Actual)");
            ItemLedgerEntry.TestField("Sales Amount (Actual)", 0);
            VerifyValueEntryAfterUndoConsumption(ItemLedgerEntry);
        until TempServiceLineBeforePosting.Next() = 0;
    end;

    local procedure VerifyValueEntryAfterUndoConsumption(var ItemLedgerEntry: Record "Item Ledger Entry")
    var
        ValueEntry: Record "Value Entry";
    begin
        // Verify that the value ofthe field Valued Quantity of the Value Entry is equal to the value of the field Qty. to Ship of
        // the relevant Service Line.
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntry."Entry No.");
        ValueEntry.FindLast();
        ValueEntry.TestField("Valued Quantity", ItemLedgerEntry.Quantity);
        ValueEntry.TestField("Item Ledger Entry Type", ItemLedgerEntry."Entry Type");
        ItemLedgerEntry.TestField("Cost Amount (Actual)", ItemLedgerEntry."Cost Amount (Actual)");
    end;

    local procedure VerifyPostedServiceOrder(OrderNo: Code[20])
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        ServiceInvoiceHeader.SetRange("Order No.", OrderNo);
        ServiceInvoiceHeader.FindFirst();
    end;

    local procedure VerifyNotPostedServiceOrder(OrderNo: Code[20])
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        ServiceInvoiceHeader.SetRange("Order No.", OrderNo);
        Assert.RecordIsEmpty(ServiceInvoiceHeader);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ExpectedCostConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    var
        ConfirmValue: Integer;
    begin
        ConfirmValue := 0;
        Assert.IsTrue(
          ConfirmValue in [StrPos(Question, ExpectedConfirm), StrPos(Question, UndoShipmentConfirm)],
          'Unexpected confirm dialog: ' + Question);
        Reply := true
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ExpectedCostMsgHandler(Msg: Text[1024])
    begin
        if StrPos(Msg, WarningMsg) = 1 then
            exit;
        Assert.IsTrue(StrPos(Msg, ExpectedMsg) = 1, 'Unexpected message dialog: ' + Msg)
    end;

    local procedure ExecuteUIHandlers()
    begin
        Message(StrSubstNo(ExpectedMsg));
        if Confirm(StrSubstNo(ExpectedConfirm)) then;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure HandleStrMenu(Options: Text[1024]; var Choice: Integer; Instructions: Text[1024])
    begin
        // Select posting option
        Choice := LibraryVariableStorage.DequeueInteger();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedServiceInvoicePH(var PostedServiceInvoice: TestPage "Posted Service Invoice")
    begin
        PostedServiceInvoice."No.".AssertEquals(LibraryVariableStorage.DequeueText());
        PostedServiceInvoice."Customer No.".AssertEquals(LibraryVariableStorage.DequeueText());
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure CreateEmptyPostedInvConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Question);
        Reply := false;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PostBatchRequestValuesHandler1(var PostBatchForm: TestRequestPage "Batch Post Service Cr. Memos")
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();

        if LibraryVariableStorage.DequeueBoolean() then begin
            PostBatchForm.PostingDate.SetValue(20200101D);
            PostBatchForm.ReplacePostingDate.SetValue(true);
            PostBatchForm.ReplaceDocumentDate.SetValue(true);
            PostBatchForm.CalcInvDisc.SetValue(not SalesReceivablesSetup."Calc. Inv. Discount");
            PostBatchForm.OK().Invoke();
        end else begin
            Assert.AreEqual(PostBatchForm.PostingDate.AsDate(), 20200101D, 'Expected value to be restored.');
            Assert.AreEqual(PostBatchForm.ReplacePostingDate.AsBoolean(), true, 'Expected value to be restored.');
            Assert.AreEqual(PostBatchForm.ReplaceDocumentDate.AsBoolean(), true, 'Expected value to be restored.');
            Assert.AreEqual(
                PostBatchForm.CalcInvDisc.AsBoolean(),
                not SalesReceivablesSetup."Calc. Inv. Discount",
                'Expected value to be restored.'
            );
        end;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PostBatchRequestValuesHandler2(var PostBatchForm: TestRequestPage "Batch Post Service Invoices")
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();

        if LibraryVariableStorage.DequeueBoolean() then begin
            PostBatchForm.PostingDate.SetValue(20200101D);
            PostBatchForm.ReplacePostingDate.SetValue(true);
            PostBatchForm.ReplaceDocumentDate.SetValue(true);
            PostBatchForm.CalcInvDisc.SetValue(not SalesReceivablesSetup."Calc. Inv. Discount");
            PostBatchForm.OK().Invoke();
        end else begin
            Assert.AreEqual(PostBatchForm.PostingDate.AsDate(), 20200101D, 'Expected value to be restored.');
            Assert.AreEqual(PostBatchForm.ReplacePostingDate.AsBoolean(), true, 'Expected value to be restored.');
            Assert.AreEqual(PostBatchForm.ReplaceDocumentDate.AsBoolean(), true, 'Expected value to be restored.');
            Assert.AreEqual(
                PostBatchForm.CalcInvDisc.AsBoolean(),
                not SalesReceivablesSetup."Calc. Inv. Discount",
                'Expected value to be restored.'
            );
        end;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PostBatchRequestValuesHandler3(var PostBatchForm: TestRequestPage "Batch Post Service Orders")
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();

        if LibraryVariableStorage.DequeueBoolean() then begin
            PostBatchForm.Ship.SetValue(true);
            PostBatchForm.Invoice.SetValue(true);
            PostBatchForm.PostingDate.SetValue(20200101D);
            PostBatchForm.ReplacePostingDate_Option.SetValue(true);
            PostBatchForm.ReplaceDocumentDate_Option.SetValue(true);
            PostBatchForm.CalcInvDiscount.SetValue(not SalesReceivablesSetup."Calc. Inv. Discount");
            PostBatchForm.OK().Invoke();
        end else begin
            Assert.AreEqual(PostBatchForm.Ship.AsBoolean(), true, 'Expected value to be restored.');
            Assert.AreEqual(PostBatchForm.Invoice.AsBoolean(), true, 'Expected value to be restored.');
            Assert.AreEqual(PostBatchForm.PostingDate.AsDate(), 20200101D, 'Expected value to be restored.');
            Assert.AreEqual(PostBatchForm.ReplacePostingDate_Option.AsBoolean(), true, 'Expected value to be restored.');
            Assert.AreEqual(PostBatchForm.ReplaceDocumentDate_Option.AsBoolean(), true, 'Expected value to be restored.');
            Assert.AreEqual(
                PostBatchForm.CalcInvDiscount.AsBoolean(),
                not SalesReceivablesSetup."Calc. Inv. Discount",
                'Expected value to be restored.'
            );
        end;
    end;

    local procedure InstallConnectorAndAddAccount()
    var
        ConnectorMock: Codeunit "Connector Mock";
        TempAccount: Record "Email Account" temporary;
        EmailScenarioMock: Codeunit "Email Scenario Mock";
    begin
        ConnectorMock.Initialize();
        ConnectorMock.AddAccount(TempAccount);
        EmailScenarioMock.DeleteAllMappings();
        EmailScenarioMock.AddMapping(Enum::"Email Scenario"::Default, TempAccount."Account Id", TempAccount.Connector);
    end;

    local procedure CustomReportSelectionPrint(Document: Variant; ReportUsage: Enum "Report Selection Usage"; CustomerNoFieldNo: Integer)
    var
        ReportSelections: Record "Report Selections";
        TempReportSelections: Record "Report Selections" temporary;
        RecRef: RecordRef;
        FieldRef: FieldRef;
        CustomerNo: Code[20];
    begin
        RecRef.GetTable(Document);
        FieldRef := RecRef.Field(CustomerNoFieldNo);
        CustomerNo := CopyStr(Format(FieldRef.Value), 1, MaxStrLen(CustomerNo));

        RecRef.SetRecFilter();
        RecRef.SetTable(Document);

        ReportSelections.FindEmailAttachmentUsageForCust(ReportUsage, CustomerNo, TempReportSelections);
        ReportSelections.SendEmailToCust(ReportUsage.AsInteger(), Document, '', '', true, CustomerNo);
    end;

    local procedure CreateServiceLineReplacement(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; ItemNo: Code[20]; ServiceItemNo: Code[20])
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
        ServiceLine.Validate("No.", ItemNo);
        ServiceLine.Validate("Service Item No.", ServiceItemNo);
        ServiceLine.Validate(Quantity, 1);
        ServiceLine.Modify(true);
    end;

    local procedure CreateNonInventoryItemWithServiceItem(CustomerNo: Code[20]; var ItemNo: Code[20]; var ServiceItemNo: Code[20])
    var
        ServiceItem: Record "Service Item";
        Item: Record Item;
    begin
        LibraryInventory.CreateNonInventoryTypeItem(Item);
        LibraryService.CreateServiceItem(ServiceItem, CustomerNo);
        ServiceItem.Validate("Item No.", Item."No.");
        ServiceItem.Validate("Serial No.", Format(LibraryRandom.RandText(50)));
        ServiceItem.Modify(true);
        ItemNo := Item."No.";
        ServiceItemNo := ServiceItem."No.";
    end;

    local procedure CreateCustomer(): Code[20]
    begin
        exit(LibrarySales.CreateCustomerNo());
    end;

    local procedure CreateServiceInvoiceHeader(var ServiceHeader: Record "Service Header"; CustomerNo: Code[20])
    var
        ServiceInvoice: TestPage "Service Invoice";
        ServiceInvoiceNo: Code[20];
    begin
        ServiceInvoice.OpenNew();
        ServiceInvoice."Customer No.".Activate();
        ServiceInvoiceNo := ServiceInvoice."No.".Value();
        ServiceInvoice.OK().Invoke();
        Commit();

        Clear(ServiceInvoice);
        ServiceInvoice.OpenEdit();
        ServiceInvoice.FILTER.SetFilter("Document Type", Format(ServiceHeader."Document Type"::Invoice));
        ServiceInvoice.FILTER.SetFilter("No.", ServiceInvoiceNo);
        ServiceInvoice."Customer No.".SetValue(CustomerNo);
        ServiceInvoice.Close();

        ServiceHeader.Get(ServiceHeader."Document Type"::Invoice, ServiceInvoiceNo);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalEmailEditorHandler(var EmailEditor: TestPage "Email Editor")
    begin
        EmailEditor.ShowSourceRecord.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalEmailRelationPickerHandler(var EmailRelationPicker: TestPage "Email Relation Picker")
    begin
        LibraryVariableStorage.Enqueue(EmailRelationPicker."Source Name".Value); //first line is customer related
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure CancelMailSendingStrMenuHandler(Options: Text; var Choice: Integer; Instruction: Text)
    begin
        Choice := 1; //Save as Draft //Discard email	
    end;

    local procedure CheckCustomerAddedToMailRelation(CustomerNo: Code[20])
    var
        CustomerNoForCompare: Code[20];
        DequeuedText: Text;
    begin
        DequeuedText := LibraryVariableStorage.DequeueText();
        CustomerNoForCompare := CopyStr(DequeuedText, StrPos(DequeuedText, ': ') + 2);
        Assert.AreEqual(CustomerNo, CustomerNoForCompare, UnknownError);
    end;
}