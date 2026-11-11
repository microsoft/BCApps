codeunit 144007 "VAT On Sales/Purchase Document"
{
    // Test Cases related to VAT Amount on Statistics for Sales/Purchase Documents:
    // 1. Verify that VAT Amount is edited successfully on Sales Return Order Statistics after partial Receipt and Invoice.
    // 2. Verify that VAT Amount is edited successfully on Sales Order Statistics after partial Shipment and Invoice.
    // 3. Verify that VAT Amount is edited successfully on Purchase Return Order Statistics after partial Shipment and Invoice.
    // 4. Verify that VAT Amount is edited successfully on Purchase Order Statistics after partial Receipt and Invoice.
    // 
    // Covers Test Cases for WI - 340131
    // -------------------------------------------------------------------
    // Test Function Name                                          TFS ID
    // -------------------------------------------------------------------
    // VATAmtOnCrMemoStatsAfterPartialPostSalesRetOrder            207420
    // VATAmtOnInvoiceStatsAfterPartialPostSalesOrder              207421
    // VATAmtOnCrMemoStatsAfterPartialPostPurchRetOrder            207422
    // VATAmtOnInvoiceStatsAfterPartialPostPurchOrder              207423

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        isInitialized: Boolean;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsPageHandlerNM,VATAmountLinesPageHandler')]
    [Scope('OnPrem')]
    procedure VATAmtOnStatsAfterPartialPostSalesRetOrderNM()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesReturnOrder: TestPage "Sales Return Order";
        SalesCreditMemoStatistics: TestPage "Sales Credit Memo Statistics";
        VATAmount: Decimal;
        DocumentNo: Code[20];
        Quantity: Decimal;
    begin
        // Verify that VAT Amount is edited successfully on Sales Return Order Statistics after partial Receipt and Invoice.

        // Setup: Create and partially post Sales Return Order.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);  // Use Random value for Quantity.
        VATAmount := CreateAndPostSalesDocument(SalesHeader, SalesHeader."Document Type"::"Return Order", Quantity, Quantity / 2, 0);  // Zero for Quantity to Ship.

        // Open Sales Return Order Statistics Page from Sales Return Order to change VAT Amount.
        LibraryVariableStorage.Enqueue(VATAmount);  // Enqueue value for VATAmountLinesPageHandler.
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.GotoRecord(SalesHeader);
        SalesReturnOrder.SalesOrderStatistics.Invoke();  // Invoking Statistics.
        SalesReturnOrder.OK().Invoke();

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify changed VAT Amount on Sales Credit Memo Statistics Page.
        SalesCrMemoHeader.Get(DocumentNo);
        SalesCreditMemoStatistics.OpenEdit();
        SalesCreditMemoStatistics.GotoRecord(SalesCrMemoHeader);
        SalesCreditMemoStatistics.Subform."VAT Amount".AssertEquals(VATAmount);
        SalesCreditMemoStatistics.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsPageHandlerNM,VATAmountLinesPageHandler')]
    [Scope('OnPrem')]
    procedure VATAmtOnStatsAfterPartialPostSalesOrderNM()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesOrder: TestPage "Sales Order";
        SalesInvoiceStatistics: TestPage "Sales Invoice Statistics";
        VATAmount: Decimal;
        DocumentNo: Code[20];
        Quantity: Decimal;
    begin
        // Verify that VAT Amount is edited successfully on Sales Order Statistics after partial Shipment and Invoice.

        // Setup: Create and partially post Sales Order.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);  // Use Random value for Quantity.
        VATAmount := CreateAndPostSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, Quantity, 0, Quantity / 2);  // Zero for Return Quantity to Receive.

        // Open Sales Order Statistics Page from Sales Order to change VAT Amount.
        LibraryVariableStorage.Enqueue(VATAmount);  // Enqueue value for VATAmountLinesPageHandler.
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder.SalesOrderStatistics.Invoke();
        SalesOrder.OK().Invoke();

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify changed VAT Amount on Sales Invoice Statistics Page.
        SalesInvoiceHeader.Get(DocumentNo);
        SalesInvoiceStatistics.OpenEdit();
        SalesInvoiceStatistics.GotoRecord(SalesInvoiceHeader);
        SalesInvoiceStatistics.Subform."VAT Amount".AssertEquals(VATAmount);
        SalesInvoiceStatistics.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('PurchOrderStatisticsPageHandler,VATAmountLinesPageHandler')]
    [Scope('OnPrem')]
    procedure VATAmtOnStatsAfterPartialPostPurchReturnOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        PurchCreditMemoStatistics: TestPage "Purch. Credit Memo Statistics";
        VATAmount: Decimal;
        DocumentNo: Code[20];
        Quantity: Decimal;
    begin
        // Verify that VAT Amount is edited successfully on Purchase Return Order Statistics after partial Shipment and Invoice.

        // Setup: Create and partially post Purchase Return Order.
        Initialize();
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Posted Return Shpt. Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);
        Quantity := LibraryRandom.RandDec(10, 2);  // Use Random value for Quantity.
        VATAmount :=
          CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", Quantity, Quantity / 2, 0);  // Zero for Quantity to Receive.

        // Open Purchase Return Order Statistics Page from Purchase Return Order to change VAT Amount.
        LibraryVariableStorage.Enqueue(VATAmount);  // Enqueue value for VATAmountLinesPageHandler.
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.GotoRecord(PurchaseHeader);
        PurchaseReturnOrder.PurchaseOrderStatistics.Invoke();  // Invoking Statistics.
        PurchaseReturnOrder.OK().Invoke();

        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify changed VAT Amount on Purchase Credit Memo Statistics Page.
        PurchCrMemoHdr.Get(DocumentNo);
        PurchCreditMemoStatistics.OpenEdit();
        PurchCreditMemoStatistics.GotoRecord(PurchCrMemoHdr);
        PurchCreditMemoStatistics.SubForm."VAT Amount".AssertEquals(VATAmount);
        PurchCreditMemoStatistics.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('PurchOrderStatisticsPageHandler,VATAmountLinesPageHandler')]
    [Scope('OnPrem')]
    procedure VATAmtOnStatsAfterPartialPostPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseOrder: TestPage "Purchase Order";
        PurchaseInvoiceStatistics: TestPage "Purchase Invoice Statistics";
        VATAmount: Decimal;
        DocumentNo: Code[20];
        Quantity: Decimal;
    begin
        // Verify that VAT Amount is edited successfully on Purchase Order Statistics after partial Receipt and Invoice.

        // Setup: Create and partially post Purchase Order.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);  // Use Random value for Quantity.
        VATAmount := CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, Quantity, 0, Quantity / 2);  // Zero for Return Quantity to Ship.
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");

        // Open Purchase Order Statistics Page from Purchase Order to change VAT Amount.
        LibraryVariableStorage.Enqueue(VATAmount);  // Enqueue value for VATAmountLinesPageHandler.
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        PurchaseOrder.PurchaseOrderStatistics.Invoke();
        PurchaseOrder.OK().Invoke();

        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify changed VAT Amount on Purchase Invoice Statistics Page.
        PurchInvHeader.Get(DocumentNo);
        PurchaseInvoiceStatistics.OpenEdit();
        PurchaseInvoiceStatistics.GotoRecord(PurchInvHeader);
        PurchaseInvoiceStatistics.SubForm."VAT Amount".AssertEquals(VATAmount);
        PurchaseInvoiceStatistics.OK().Invoke();
    end;


    local procedure Initialize()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();

        if isInitialized then
            exit;
        isInitialized := true;

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Return Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Return Receipt on Credit Memo", true);
        SalesReceivablesSetup.Validate("Posted Return Receipt Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Modify(true);

        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; Quantity: Decimal; ReturnQtyToShip: Decimal; QtyToReceive: Decimal) VATAmount: Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        // Update General Ledger Setup and Purchases Payables Setup for VAT Difference. Create and post Purchase Document.
        UpdateGeneralLedgerSetupForMaxVATDiffAllowed(GeneralLedgerSetup);
        UpdatePurchasesPayablesSetup();
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item), Quantity);
        PurchaseLine.Validate("Return Qty. to Ship", ReturnQtyToShip);
        PurchaseLine.Validate("Qty. to Receive", QtyToReceive);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));  // Use Random value for Direct Unit Cost.
        PurchaseLine.Modify(true);
        VATAmount :=
          PurchaseLine."Qty. to Invoice" * PurchaseLine."Direct Unit Cost" * PurchaseLine."VAT %" / 100 +
          LibraryRandom.RandDec(GeneralLedgerSetup."Max. VAT Difference Allowed", 2);  // Increase VAT Amount with Random value.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateAndPostSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; Quantity: Decimal; ReturnQtyToReceive: Decimal; QtyToShip: Decimal) VATAmount: Decimal
    var
        Customer: Record Customer;
        GeneralLedgerSetup: Record "General Ledger Setup";
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        // Update General Ledger Setup and Sales Receivables Setup for VAT Difference. Create and post Sales Document.
        UpdateGeneralLedgerSetupForMaxVATDiffAllowed(GeneralLedgerSetup);
        UpdateSalesReceivablesSetupForAllowVATDifference();
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item), Quantity);
        SalesLine.Validate("Return Qty. to Receive", ReturnQtyToReceive);
        SalesLine.Validate("Qty. to Ship", QtyToShip);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));  // Use Random value for Unit Price.
        SalesLine.Modify(true);
        VATAmount :=
          SalesLine."Qty. to Invoice" * SalesLine."Unit Price" * SalesLine."VAT %" / 100 +
          LibraryRandom.RandDec(GeneralLedgerSetup."Max. VAT Difference Allowed", 2);  // Increase VAT Amount with Random value.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure UpdateGeneralLedgerSetupForMaxVATDiffAllowed(var GeneralLedgerSetup: Record "General Ledger Setup")
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Max. VAT Difference Allowed", LibraryRandom.RandInt(5));  // Use Random value.
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdatePurchasesPayablesSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Allow VAT Difference", true);
        PurchasesPayablesSetup.Validate("Ext. Doc. No. Mandatory", false);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure UpdateSalesReceivablesSetupForAllowVATDifference()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Allow VAT Difference", true);
        SalesReceivablesSetup.Modify(true);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchOrderStatisticsPageHandler(var PurchaseOrderStatistics: TestPage "Purchase Order Statistics")
    begin
        PurchaseOrderStatistics.NoOfVATLines_Invoicing.DrillDown();
        PurchaseOrderStatistics.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsPageHandlerNM(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        SalesOrderStatistics.NoOfVATLines_Invoicing.DrillDown();
        SalesOrderStatistics.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VATAmountLinesPageHandler(var VATAmountLines: TestPage "VAT Amount Lines")
    var
        VATAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATAmount);
        VATAmountLines."VAT Amount".SetValue(VATAmount);
        VATAmountLines.OK().Invoke();
    end;

}

