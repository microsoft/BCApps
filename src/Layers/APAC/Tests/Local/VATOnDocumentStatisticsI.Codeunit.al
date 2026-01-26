codeunit 141079 "VAT On Document Statistics I"
{
    // 1. Test to verify values on Purchase Order Statistics page of Purchase Order with Invoice Rounding Precision.
    // 2. Test to verify values on Sales Order Statistics page of Sales Order with Invoice Rounding Precision.
    // 3. Test to verify values on Sales Order Statistics page of Sales Order with multiple lines and Full GST On Prepayment False.
    // 
    // Covers Test Cases for WI - 348934
    // ------------------------------------------------------------------------------
    // Test Function Name                                                     TFS ID
    // ------------------------------------------------------------------------------
    // PurchOrderStatisticsWithInvoiceRoundingPrecision                       239193
    // SalesOrderStatisticsWithInvoiceRoundingPrecision                       239193
    // 
    // Covers Test Cases for WI - 349034
    // ------------------------------------------------------------------------------
    // Test Function Name                                                     TFS ID
    // ------------------------------------------------------------------------------
    // SalesOrdStatsWithMultipleLineFullGSTOnPrepmtFalse                      184297

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Statistics] [UI]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        AmountErr: Label '%1 must be %2 in %3.';

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsModalPageHandler,VATAmountLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure PurchOrderStatisticsWithInvoiceRoundingPrecision()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
        OldInvoiceRoundingPrecision: Decimal;
    begin
        // [FEATURE] [Purchase] [Order] [Invoice Rounding]
        // [SCENARIO] values on Purchase Order Statistics page of Purchase Order with Invoice Rounding Precision.

        // [GIVEN] Update Invoice Rounding Precision on General Ledger Setup. Create Purchase Order.
        Initialize();
        OldInvoiceRoundingPrecision :=
          UpdateInvRoundingPrecisionOnGeneralLedgerSetup(LibraryRandom.RandDecInDecimalRange(0.02, 0.1, 2));  // Random value required for Invoice Rounding Precision.
        CreatePurchaseOrderWithSetup(PurchaseLine);
        EnqueueValuesForHandler(PurchaseLine.Amount * PurchaseLine."VAT %" / 100, PurchaseLine."Amount Including VAT");  // Enqueue values for PurchaseOrderStatisticsModalPageHandler and VATAmountLinesModalPageHandler.
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", PurchaseLine."Document No.");

        // Exercise.
        PurchaseOrder.Statistics.Invoke();  // Opens PurchaseOrderStatisticsModalPageHandler.

        // Verify: Verification is done in PurchaseOrderStatisticsModalPageHandler and VATAmountLinesModalPageHandler.

        // Tear Down.
        UpdateInvRoundingPrecisionOnGeneralLedgerSetup(OldInvoiceRoundingPrecision);
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsPageHandler,VATAmountLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure PurchOrderStatisticsWithInvRoundingPrecision()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
        OldInvoiceRoundingPrecision: Decimal;
    begin
        // [FEATURE] [Purchase] [Order] [Invoice Rounding]
        // [SCENARIO] values on Purchase Order Statistics page of Purchase Order with Invoice Rounding Precision.

        // [GIVEN] Update Invoice Rounding Precision on General Ledger Setup. Create Purchase Order.
        Initialize();
        OldInvoiceRoundingPrecision :=
          UpdateInvRoundingPrecisionOnGeneralLedgerSetup(LibraryRandom.RandDecInDecimalRange(0.02, 0.1, 2));  // Random value required for Invoice Rounding Precision.
        CreatePurchaseOrderWithSetup(PurchaseLine);
        EnqueueValuesForHandler(PurchaseLine.Amount * PurchaseLine."VAT %" / 100, PurchaseLine."Amount Including VAT");  // Enqueue values for PurchaseOrderStatisticsModalPageHandler and VATAmountLinesModalPageHandler.
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", PurchaseLine."Document No.");

        // Exercise.
        PurchaseOrder.PurchaseOrderStatistics.Invoke();  // Opens PurchaseOrderStatisticsPageHandler.

        // Verify: Verification is done in PurchaseOrderStatisticsPageHandler and VATAmountLinesModalPageHandler.

        // Tear Down.
        UpdateInvRoundingPrecisionOnGeneralLedgerSetup(OldInvoiceRoundingPrecision);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatisticsModalPageHandler,VATAmountLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsWithInvoiceRoundingPrecision()
    var
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        OldInvoiceRoundingPrecision: Decimal;
    begin
        // [FEATURE] [Sales] [Order] [Invoice Rounding]
        // [SCENARIO] values on Sales Order Statistics page of Sales Order with Invoice Rounding Precision.

        // [GIVEN] Update Invoice Rounding Precision on General Ledger Setup. Create Sales Order.
        Initialize();
        OldInvoiceRoundingPrecision :=
          UpdateInvRoundingPrecisionOnGeneralLedgerSetup(LibraryRandom.RandDecInDecimalRange(0.02, 0.1, 2));  // Random value required for Invoice Rounding Precision.
        CreateSalesOrderWithSetup(SalesLine, 0);  // Value 0 required for Prepayment Percent.
        EnqueueValuesForHandler(SalesLine.Amount * SalesLine."VAT %" / 100, SalesLine."Amount Including VAT");  // Enqueue values for SalesOrderStatisticsModalPageHandler and VATAmountLinesModalPageHandler.
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", SalesLine."Document No.");

        // Exercise.
        SalesOrder.Statistics.Invoke();  // Opens SalesOrderStatisticsModalPageHandler.

        // Verify: Verification is done in SalesOrderStatisticsModalPageHandler and VATAmountLinesModalPageHandler.

        // Tear Down.
        UpdateInvRoundingPrecisionOnGeneralLedgerSetup(OldInvoiceRoundingPrecision);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatisticsModalPageHandler,VATAmountLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrdStatsWithMultipleLineFullGSTOnPrepmtFalse()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        OldFullGSTOnPrepayment: Boolean;
    begin
        // [FEATURE] [Sales] [Order] [Full GST On Prepayment]
        // [SCENARIO] values on Sales Order Statistics page of Sales Order with multiple lines and Full GST On Prepayment False.

        // Setup: Update Full GST On Prepayment as False on General Ledger Setup. Create Sales Order with two lines.
        Initialize();
        OldFullGSTOnPrepayment := UpdateFullGSTOnPrepaymentOnGeneralLedgerSetup(false);
        CreateSalesOrderWithSetup(SalesLine, LibraryRandom.RandDecInRange(20, 50, 2));  // Random value used for Prepayment Percent.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        CreateSalesLine(SalesLine2, SalesHeader, SalesLine."Gen. Prod. Posting Group", SalesLine."VAT Prod. Posting Group");
        EnqueueValuesForHandler(
          (SalesLine.Amount + SalesLine2.Amount) * SalesLine."VAT %" / 100,
          SalesLine."Amount Including VAT" + SalesLine2."Amount Including VAT");  // Enqueue values for SalesOrderStatisticsModalPageHandler and VATAmountLinesModalPageHandler.
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", SalesHeader."No.");

        // Exercise.
        SalesOrder.Statistics.Invoke();  // Opens SalesOrderStatisticsModalPageHandler.

        // Verify: Verification is done in SalesOrderStatisticsModalPageHandler and VATAmountLinesModalPageHandler.

        // Tear Down.
        UpdateFullGSTOnPrepaymentOnGeneralLedgerSetup(OldFullGSTOnPrepayment);
    end;
#endif
    [Test]
    [HandlerFunctions('SalesOrderStatisticsPageHandler,VATAmountLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsWithInvoiceRoundingPrecisionNM()
    var
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        OldInvoiceRoundingPrecision: Decimal;
    begin
        // [FEATURE] [Sales] [Order] [Invoice Rounding]
        // [SCENARIO] values on Sales Order Statistics page of Sales Order with Invoice Rounding Precision.

        // [GIVEN] Update Invoice Rounding Precision on General Ledger Setup. Create Sales Order.
        Initialize();
        OldInvoiceRoundingPrecision :=
          UpdateInvRoundingPrecisionOnGeneralLedgerSetup(LibraryRandom.RandDecInDecimalRange(0.02, 0.1, 2));  // Random value required for Invoice Rounding Precision.
        CreateSalesOrderWithSetup(SalesLine, 0);  // Value 0 required for Prepayment Percent.
        EnqueueValuesForHandler(SalesLine.Amount * SalesLine."VAT %" / 100, SalesLine."Amount Including VAT");  // Enqueue values for SalesOrderStatisticsPageHandler and VATAmountLinesModalPageHandler.
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", SalesLine."Document No.");

        // Exercise.
        SalesOrder.SalesOrderStatistics.Invoke();  // Opens SalesOrderStatisticsPageHandler.

        // Verify: Verification is done in SalesOrderStatisticsPageHandler and VATAmountLinesModalPageHandler.

        // Tear Down.
        UpdateInvRoundingPrecisionOnGeneralLedgerSetup(OldInvoiceRoundingPrecision);
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsPageHandler,VATAmountLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrdStatsWithMultipleLineFullGSTOnPrepmtFalseNM()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        OldFullGSTOnPrepayment: Boolean;
    begin
        // [FEATURE] [Sales] [Order] [Full GST On Prepayment]
        // [SCENARIO] values on Sales Order Statistics page of Sales Order with multiple lines and Full GST On Prepayment False.

        // Setup: Update Full GST On Prepayment as False on General Ledger Setup. Create Sales Order with two lines.
        Initialize();
        OldFullGSTOnPrepayment := UpdateFullGSTOnPrepaymentOnGeneralLedgerSetup(false);
        CreateSalesOrderWithSetup(SalesLine, LibraryRandom.RandDecInRange(20, 50, 2));  // Random value used for Prepayment Percent.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        CreateSalesLine(SalesLine2, SalesHeader, SalesLine."Gen. Prod. Posting Group", SalesLine."VAT Prod. Posting Group");
        EnqueueValuesForHandler(
          (SalesLine.Amount + SalesLine2.Amount) * SalesLine."VAT %" / 100,
          SalesLine."Amount Including VAT" + SalesLine2."Amount Including VAT");  // Enqueue values for SalesOrderStatisticsPageHandler and VATAmountLinesModalPageHandler.
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", SalesHeader."No.");

        // Exercise.
        SalesOrder.SalesOrderStatistics.Invoke();  // Opens SalesOrderStatisticsPageHandler.

        // Verify: Verification is done in SalesOrderStatisticsPageHandler and VATAmountLinesModalPageHandler.

        // Tear Down.
        UpdateFullGSTOnPrepaymentOnGeneralLedgerSetup(OldFullGSTOnPrepayment);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateGeneralPostingSetup(var GeneralPostingSetup: Record "General Posting Setup")
    var
        GenProdPostingGroup: Record "Gen. Product Posting Group";
        GenBusPostingGroup: Record "Gen. Business Posting Group";
    begin
        LibraryERM.CreateGenProdPostingGroup(GenProdPostingGroup);
        LibraryERM.CreateGenBusPostingGroup(GenBusPostingGroup);
        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusPostingGroup.Code, GenProdPostingGroup.Code);
    end;

    local procedure CreateGLAccount(GenProductPostingGroup: Code[20]; VATBusinessPostingGroup: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup, 0);  // Value 0 required for VAT Percent.
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProductPostingGroup);
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateItem(GenProdPostingGroup: Code[20]; VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePurchaseOrderWithSetup(var PurchaseLine: Record "Purchase Line")
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, LibraryRandom.RandDec(20, 2));  // Random value used for VAT Percent.
        CreateGeneralPostingSetup(GeneralPostingSetup);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        VendorPostingGroup.Validate(
          "Invoice Rounding Account", CreateGLAccount(
            GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Bus. Posting Group"));
        VendorPostingGroup.Modify(true);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(GeneralPostingSetup."Gen. Prod. Posting Group",
            VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandDec(10, 2));  // Random value used for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; GenProdPostingGroup: Code[20]; VATProdPostingGroup: Code[20])
    begin
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(GenProdPostingGroup, VATProdPostingGroup),
          LibraryRandom.RandDec(10, 2));  // Random value used for Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrderWithSetup(var SalesLine: Record "Sales Line"; PrepaymentPercent: Decimal)
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, LibraryRandom.RandDec(20, 2));  // Random value used for VAT Percent.
        CreateGeneralPostingSetup(GeneralPostingSetup);
        GeneralPostingSetup.Validate(
          "Sales Prepayments Account", CreateGLAccount(
            GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Bus. Posting Group"));
        GeneralPostingSetup.Modify(true);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        CustomerPostingGroup.Validate(
          "Invoice Rounding Account", CreateGLAccount(
            GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Bus. Posting Group"));
        CustomerPostingGroup.Modify(true);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("Prepayment %", PrepaymentPercent);
        SalesHeader.Modify(true);
        CreateSalesLine(SalesLine, SalesHeader, GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATBusinessPostingGroup: Code[20]; VATPercent: Decimal)
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("VAT %", VATPercent);
        VATPostingSetup.Validate("VAT Identifier", VATPostingSetup."VAT Prod. Posting Group");
        VATPostingSetup.Modify(true);
    end;

    local procedure EnqueueValuesForHandler(Value: Decimal; Value2: Decimal)
    begin
        LibraryVariableStorage.Enqueue(Value);
        LibraryVariableStorage.Enqueue(Value);
        LibraryVariableStorage.Enqueue(Value2);
    end;

    local procedure UpdateFullGSTOnPrepaymentOnGeneralLedgerSetup(NewFullGSTOnPrepayment: Boolean) OldFullGSTOnPrepayment: Boolean
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        OldFullGSTOnPrepayment := GeneralLedgerSetup."Full GST on Prepayment";
        GeneralLedgerSetup.Validate("Full GST on Prepayment", NewFullGSTOnPrepayment);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateInvRoundingPrecisionOnGeneralLedgerSetup(NewInvoiceRoundingPrecision: Decimal) OldInvoiceRoundingPrecision: Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        OldInvoiceRoundingPrecision := GeneralLedgerSetup."Inv. Rounding Precision (LCY)";
        GeneralLedgerSetup.Validate("Inv. Rounding Precision (LCY)", NewInvoiceRoundingPrecision);
        GeneralLedgerSetup.Modify(true);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatisticsModalPageHandler(var PurchaseOrderStatistics: TestPage "Purchase Order Statistics")
    var
        VATAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATAmount);
        Assert.AreNearlyEqual(
          PurchaseOrderStatistics."VATAmount[1]".AsDecimal(), VATAmount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, PurchaseOrderStatistics."VATAmount[1]".Caption, VATAmount, PurchaseOrderStatistics.Caption));
        PurchaseOrderStatistics.NoOfVATLines_General.DrillDown();  // Opens VATAmountLinesModalPageHandler.
    end;
#endif

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatisticsPageHandler(var PurchaseOrderStatistics: TestPage "Purchase Order Statistics")
    var
        VATAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATAmount);
        Assert.AreNearlyEqual(
          PurchaseOrderStatistics."VATAmount[1]".AsDecimal(), VATAmount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, PurchaseOrderStatistics."VATAmount[1]".Caption, VATAmount, PurchaseOrderStatistics.Caption));
        PurchaseOrderStatistics.NoOfVATLines_General.DrillDown();  // Opens VATAmountLinesModalPageHandler.
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsModalPageHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    var
        VATAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATAmount);
        Assert.AreNearlyEqual(
          SalesOrderStatistics.VATAmount.AsDecimal(), VATAmount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, SalesOrderStatistics.VATAmount.Caption, VATAmount, SalesOrderStatistics.Caption));
        SalesOrderStatistics.NoOfVATLines_General.DrillDown();  // Opens VATAmountLinesModalPageHandler.
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsPageHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    var
        VATAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATAmount);
        Assert.AreNearlyEqual(
          SalesOrderStatistics.VATAmount.AsDecimal(), VATAmount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, SalesOrderStatistics.VATAmount.Caption, VATAmount, SalesOrderStatistics.Caption));
        SalesOrderStatistics.NoOfVATLines_General.DrillDown();  // Opens VATAmountLinesModalPageHandler.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VATAmountLinesModalPageHandler(var VATAmountLines: TestPage "VAT Amount Lines")
    var
        AmountIncludingVAT: Variant;
        VATAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATAmount);
        LibraryVariableStorage.Dequeue(AmountIncludingVAT);
        VATAmountLines.FILTER.SetFilter("VAT %", '<>0');  // Filter not equal to zero required for VAT Amount line with VAT.
        Assert.AreNearlyEqual(
          VATAmountLines."VAT Amount".AsDecimal(), VATAmount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(VATAmountLines."VAT Amount".Caption, VATAmount, VATAmountLines.Caption));
        Assert.AreNearlyEqual(
          VATAmountLines."Amount Including VAT".AsDecimal(), AmountIncludingVAT, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(VATAmountLines."Amount Including VAT".Caption, AmountIncludingVAT, VATAmountLines.Caption));
    end;
}

