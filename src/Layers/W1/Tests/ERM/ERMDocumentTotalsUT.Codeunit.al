codeunit 134395 "ERM Document Totals UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Document Totals] [UT]
        isInitialized := false;
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        isInitialized: Boolean;
        VatAmountRecalculatedErr: Label 'Vat Amount should be recalculated';
        GetLineAmountToHandleErr: Label 'GetLineAmountToHandle returned bad result.';

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure SalesUpdateTotalsControlsUpdateTotals()
    var
        SalesHeader: Record "Sales Header";
        CurrentSalesLine: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        RefreshMessageEnabled: Boolean;
        InvDiscAmountEditable: Boolean;
        VATAmount: Decimal;
        ControlStyle: Text;
        RefreshMessageText: Text;
        NumberOfLines: Integer;
    begin
        // Setup
        Initialize();
        NumberOfLines := LibraryRandom.RandIntInRange(1, 10);

        CreateSalesDocument(SalesHeader, NumberOfLines);
        GetCurrentSalesLine(CurrentSalesLine, SalesHeader);

        // Execute
        DocumentTotals.SalesUpdateTotalsControls(
          CurrentSalesLine, SalesHeader, TotalSalesLine, RefreshMessageEnabled, ControlStyle, RefreshMessageText, InvDiscAmountEditable,
          true, VATAmount);

        // Verify
        SalesVerifyTotalsAreCalculated(RefreshMessageEnabled, ControlStyle, InvDiscAmountEditable, SalesHeader);

        // Execute again - no change should happen
        DocumentTotals.SalesUpdateTotalsControls(
          CurrentSalesLine, SalesHeader, TotalSalesLine, RefreshMessageEnabled, ControlStyle, RefreshMessageText, InvDiscAmountEditable,
          true, VATAmount);

        // Verify
        SalesVerifyTotalsAreCalculated(RefreshMessageEnabled, ControlStyle, InvDiscAmountEditable, SalesHeader);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure SalesUpdateTotalsControlsRecalculatesIfTheRecordIsChanged()
    var
        SalesHeader: Record "Sales Header";
        CurrentSalesLine: Record "Sales Line";
        TotalsSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        RefreshMessageEnabled: Boolean;
        InvDiscAmountEditable: Boolean;
        VATAmount: Decimal;
        ControlStyle: Text;
        RefreshMessageText: Text;
        PreviousTotalAmount: Decimal;
        NumberOfLines: Integer;
    begin
        // Setup
        Initialize();
        NumberOfLines := LibraryRandom.RandIntInRange(1, 10);
        CreateSalesDocument(SalesHeader, NumberOfLines);
        GetCurrentSalesLine(CurrentSalesLine, SalesHeader);
        DocumentTotals.SalesUpdateTotalsControls(
          CurrentSalesLine, SalesHeader, TotalsSalesLine, RefreshMessageEnabled, ControlStyle, RefreshMessageText, InvDiscAmountEditable,
          true, VATAmount);
        PreviousTotalAmount := TotalsSalesLine.Amount;

        // Execute
        GetCurrentSalesLine(CurrentSalesLine, SalesHeader);
        CurrentSalesLine.Validate("Line Amount", Round(CurrentSalesLine."Line Amount" / 2, 1));
        CurrentSalesLine.Modify(true);
        Clear(TotalsSalesLine);
        DocumentTotals.SalesUpdateTotalsControls(
          CurrentSalesLine, SalesHeader, TotalsSalesLine, RefreshMessageEnabled, ControlStyle, RefreshMessageText, InvDiscAmountEditable,
          true, VATAmount);

        // Verify
        Assert.AreNotEqual(PreviousTotalAmount, TotalsSalesLine.Amount, 'Total amount should be updated');
        SalesVerifyTotalsAreCalculated(RefreshMessageEnabled, ControlStyle, InvDiscAmountEditable, SalesHeader);
        LibraryVariableStorage.AssertEmpty();
    end;
#endif
    [Test]
    [HandlerFunctions('SalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure SalesUpdateTotalsControlsUpdateTotalsNM()
    var
        SalesHeader: Record "Sales Header";
        CurrentSalesLine: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        RefreshMessageEnabled: Boolean;
        InvDiscAmountEditable: Boolean;
        VATAmount: Decimal;
        ControlStyle: Text;
        RefreshMessageText: Text;
        NumberOfLines: Integer;
    begin
        // Setup
        Initialize();
        NumberOfLines := LibraryRandom.RandIntInRange(1, 10);

        CreateSalesDocument(SalesHeader, NumberOfLines);
        GetCurrentSalesLine(CurrentSalesLine, SalesHeader);

        // Execute
        DocumentTotals.SalesUpdateTotalsControls(
          CurrentSalesLine, SalesHeader, TotalSalesLine, RefreshMessageEnabled, ControlStyle, RefreshMessageText, InvDiscAmountEditable,
          true, VATAmount);

        // Verify
        SalesVerifyTotalsAreCalculatedNM(RefreshMessageEnabled, ControlStyle, InvDiscAmountEditable, SalesHeader);

        // Execute again - no change should happen
        DocumentTotals.SalesUpdateTotalsControls(
          CurrentSalesLine, SalesHeader, TotalSalesLine, RefreshMessageEnabled, ControlStyle, RefreshMessageText, InvDiscAmountEditable,
          true, VATAmount);

        // Verify
        SalesVerifyTotalsAreCalculatedNM(RefreshMessageEnabled, ControlStyle, InvDiscAmountEditable, SalesHeader);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure SalesUpdateTotalsControlsRecalculatesIfTheRecordIsChangedNM()
    var
        SalesHeader: Record "Sales Header";
        CurrentSalesLine: Record "Sales Line";
        TotalsSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        RefreshMessageEnabled: Boolean;
        InvDiscAmountEditable: Boolean;
        VATAmount: Decimal;
        ControlStyle: Text;
        RefreshMessageText: Text;
        PreviousTotalAmount: Decimal;
        NumberOfLines: Integer;
    begin
        // Setup
        Initialize();
        NumberOfLines := LibraryRandom.RandIntInRange(1, 10);
        CreateSalesDocument(SalesHeader, NumberOfLines);
        GetCurrentSalesLine(CurrentSalesLine, SalesHeader);
        DocumentTotals.SalesUpdateTotalsControls(
          CurrentSalesLine, SalesHeader, TotalsSalesLine, RefreshMessageEnabled, ControlStyle, RefreshMessageText, InvDiscAmountEditable,
          true, VATAmount);
        PreviousTotalAmount := TotalsSalesLine.Amount;

        // Execute
        GetCurrentSalesLine(CurrentSalesLine, SalesHeader);
        CurrentSalesLine.Validate("Line Amount", Round(CurrentSalesLine."Line Amount" / 2, 1));
        CurrentSalesLine.Modify(true);
        Clear(TotalsSalesLine);
        DocumentTotals.SalesUpdateTotalsControls(
          CurrentSalesLine, SalesHeader, TotalsSalesLine, RefreshMessageEnabled, ControlStyle, RefreshMessageText, InvDiscAmountEditable,
          true, VATAmount);

        // Verify
        Assert.AreNotEqual(PreviousTotalAmount, TotalsSalesLine.Amount, 'Total amount should be updated');
        SalesVerifyTotalsAreCalculatedNM(RefreshMessageEnabled, ControlStyle, InvDiscAmountEditable, SalesHeader);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesUpdateTotalsControlsDoesNotUpdateDocumentWithTooManyLines()
    var
        SalesHeader: Record "Sales Header";
        CurrentSalesLine: Record "Sales Line";
        TotalsSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        RefreshMessageEnabled: Boolean;
        InvDiscAmountEditable: Boolean;
        VATAmount: Decimal;
        ControlStyle: Text;
        RefreshMessageText: Text;
        NumberOfLines: Integer;
    begin
        // Setup
        Initialize();
        NumberOfLines := LibraryRandom.RandIntInRange(11, 110);
        CreateSalesDocument(SalesHeader, NumberOfLines);
        GetCurrentSalesLine(CurrentSalesLine, SalesHeader);

        // Execute
        DocumentTotals.SalesUpdateTotalsControls(
          CurrentSalesLine, SalesHeader, TotalsSalesLine, RefreshMessageEnabled, ControlStyle, RefreshMessageText, InvDiscAmountEditable,
          true, VATAmount);

        // Verify
        SalesVerifyTotalsAreSetToZero(RefreshMessageEnabled, ControlStyle, InvDiscAmountEditable, TotalsSalesLine, VATAmount);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesUpdateTotalsControlsDoesNotUpdateDocumentWhenRedistributeIsPending()
    var
        SalesHeader: Record "Sales Header";
        CurrentSalesLine: Record "Sales Line";
        TotalsSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        RefreshMessageEnabled: Boolean;
        InvDiscAmountEditable: Boolean;
        VATAmount: Decimal;
        ControlStyle: Text;
        RefreshMessageText: Text;
        NumberOfLines: Integer;
    begin
        // Setup
        Initialize();
        NumberOfLines := LibraryRandom.RandIntInRange(1, 10);
        CreateSalesDocument(SalesHeader, NumberOfLines);
        GetCurrentSalesLine(CurrentSalesLine, SalesHeader);

        SalesHeader.Validate("Invoice Discount Calculation", SalesHeader."Invoice Discount Calculation"::"%");
        SalesHeader.Modify();

        CurrentSalesLine.Validate("Recalculate Invoice Disc.", true);
        CurrentSalesLine.Modify();

        // Execute
        DocumentTotals.SalesUpdateTotalsControls(
          CurrentSalesLine, SalesHeader, TotalsSalesLine, RefreshMessageEnabled, ControlStyle, RefreshMessageText, InvDiscAmountEditable,
          true, VATAmount);

        // Verify
        SalesVerifyTotalsAreSetToZero(RefreshMessageEnabled, ControlStyle, InvDiscAmountEditable, TotalsSalesLine, VATAmount);

        // Execute - Verify that calling it twice will not reset
        DocumentTotals.SalesUpdateTotalsControls(
          CurrentSalesLine, SalesHeader, TotalsSalesLine, RefreshMessageEnabled, ControlStyle, RefreshMessageText, InvDiscAmountEditable,
          true, VATAmount);

        // Verify
        SalesVerifyTotalsAreSetToZero(RefreshMessageEnabled, ControlStyle, InvDiscAmountEditable, TotalsSalesLine, VATAmount);
        LibraryVariableStorage.AssertEmpty();
    end;

#if not CLEAN26
    [Test]
    [HandlerFunctions('SalesOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure SalesRedistributeTotalsClearsRefreshMessageAndTotalsAreUpdated()
    var
        SalesHeader: Record "Sales Header";
        CurrentSalesLine: Record "Sales Line";
        TotalsSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        RefreshMessageEnabled: Boolean;
        InvDiscAmountEditable: Boolean;
        VATAmount: Decimal;
        ControlStyle: Text;
        RefreshMessageText: Text;
        NumberOfLines: Integer;
    begin
        // Setup
        Initialize();
        NumberOfLines := LibraryRandom.RandIntInRange(1, 10);
        CreateSalesDocument(SalesHeader, NumberOfLines);
        GetCurrentSalesLine(CurrentSalesLine, SalesHeader);

        SalesHeader.Validate("Invoice Discount Calculation", SalesHeader."Invoice Discount Calculation"::"%");
        SalesHeader.Modify();

        CurrentSalesLine.Validate("Recalculate Invoice Disc.", true);
        CurrentSalesLine.Modify();

        DocumentTotals.SalesUpdateTotalsControls(
          CurrentSalesLine, SalesHeader, TotalsSalesLine, RefreshMessageEnabled, ControlStyle, RefreshMessageText,
          InvDiscAmountEditable, true, VATAmount);

        // Execute - Verify that calling it twice will not reset
        SalesCalcDiscountByType.ApplyDefaultInvoiceDiscount(0, SalesHeader);
        DocumentTotals.SalesUpdateTotalsControls(
          CurrentSalesLine, SalesHeader, TotalsSalesLine, RefreshMessageEnabled, ControlStyle, RefreshMessageText,
          InvDiscAmountEditable, true, VATAmount);

        // Verify
        SalesVerifyTotalsAreCalculated(RefreshMessageEnabled, ControlStyle, InvDiscAmountEditable, SalesHeader);
        LibraryVariableStorage.AssertEmpty();
    end;
#endif
    [Test]
    [HandlerFunctions('SalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure SalesRedistributeTotalsClearsRefreshMessageAndTotalsAreUpdatedNM()
    var
        SalesHeader: Record "Sales Header";
        CurrentSalesLine: Record "Sales Line";
        TotalsSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        RefreshMessageEnabled: Boolean;
        InvDiscAmountEditable: Boolean;
        VATAmount: Decimal;
        ControlStyle: Text;
        RefreshMessageText: Text;
        NumberOfLines: Integer;
    begin
        // Setup
        Initialize();
        NumberOfLines := LibraryRandom.RandIntInRange(1, 10);
        CreateSalesDocument(SalesHeader, NumberOfLines);
        GetCurrentSalesLine(CurrentSalesLine, SalesHeader);

        SalesHeader.Validate("Invoice Discount Calculation", SalesHeader."Invoice Discount Calculation"::"%");
        SalesHeader.Modify();

        CurrentSalesLine.Validate("Recalculate Invoice Disc.", true);
        CurrentSalesLine.Modify();

        DocumentTotals.SalesUpdateTotalsControls(
          CurrentSalesLine, SalesHeader, TotalsSalesLine, RefreshMessageEnabled, ControlStyle, RefreshMessageText,
          InvDiscAmountEditable, true, VATAmount);

        // Execute - Verify that calling it twice will not reset
        SalesCalcDiscountByType.ApplyDefaultInvoiceDiscount(0, SalesHeader);
        DocumentTotals.SalesUpdateTotalsControls(
          CurrentSalesLine, SalesHeader, TotalsSalesLine, RefreshMessageEnabled, ControlStyle, RefreshMessageText,
          InvDiscAmountEditable, true, VATAmount);

        // Verify
        SalesVerifyTotalsAreCalculatedNM(RefreshMessageEnabled, ControlStyle, InvDiscAmountEditable, SalesHeader);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesManualDiscountsAreNotPossibleWhenCalcInvoiceDiscountIsSet()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
        ManualDiscountAllowed: Boolean;
    begin
        // Setup
        Initialize();
        CreateCustomerWithDiscount(Customer);
        CreateItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Calc. Inv. Discount" := true;
        SalesReceivablesSetup.Modify();

        // Execute
        ManualDiscountAllowed := SalesCalcDiscountByType.InvoiceDiscIsAllowed(SalesHeader."Invoice Disc. Code");

        // Verify
        Assert.IsFalse(
          ManualDiscountAllowed, 'Manual discount must not be enabled when Calc. Inv. Discount is set. Posting will undo changes.');
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure PurchaseUpdateTotalsControlsUpdateTotals()
    var
        PurchaseHeader: Record "Purchase Header";
        CurrentPurchaseLine: Record "Purchase Line";
        TotalPurchaseLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        RefreshMessageEnabled: Boolean;
        InvDiscAmountEditable: Boolean;
        VATAmount: Decimal;
        ControlStyle: Text;
        RefreshMessageText: Text;
        NumberOfLines: Integer;
    begin
        // Setup
        Initialize();
        NumberOfLines := LibraryRandom.RandIntInRange(1, 10);

        CreatePurchaseDocument(PurchaseHeader, NumberOfLines);
        GetCurrentPurchaseLine(CurrentPurchaseLine, PurchaseHeader);

        // Execute
        DocumentTotals.PurchaseUpdateTotalsControls(
          CurrentPurchaseLine, PurchaseHeader, TotalPurchaseLine, RefreshMessageEnabled, ControlStyle, RefreshMessageText,
          InvDiscAmountEditable, VATAmount);

        // Verify
        PurchaseVerifyTotalsAreCalculated(RefreshMessageEnabled, ControlStyle, InvDiscAmountEditable, PurchaseHeader);

        // Execute again - no change should happen
        DocumentTotals.PurchaseUpdateTotalsControls(
          CurrentPurchaseLine, PurchaseHeader, TotalPurchaseLine, RefreshMessageEnabled, ControlStyle, RefreshMessageText,
          InvDiscAmountEditable, VATAmount);

        // Verify
        PurchaseVerifyTotalsAreCalculated(RefreshMessageEnabled, ControlStyle, InvDiscAmountEditable, PurchaseHeader);
        LibraryVariableStorage.AssertEmpty();
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseUpdateTotalsStatsControlsUpdateTotals()
    var
        PurchaseHeader: Record "Purchase Header";
        CurrentPurchaseLine: Record "Purchase Line";
        TotalPurchaseLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        RefreshMessageEnabled: Boolean;
        InvDiscAmountEditable: Boolean;
        VATAmount: Decimal;
        ControlStyle: Text;
        RefreshMessageText: Text;
        NumberOfLines: Integer;
    begin
        // Setup
        Initialize();
        NumberOfLines := LibraryRandom.RandIntInRange(1, 10);

        CreatePurchaseDocument(PurchaseHeader, NumberOfLines);
        GetCurrentPurchaseLine(CurrentPurchaseLine, PurchaseHeader);

        // Execute
        DocumentTotals.PurchaseUpdateTotalsControls(
          CurrentPurchaseLine, PurchaseHeader, TotalPurchaseLine, RefreshMessageEnabled, ControlStyle, RefreshMessageText,
          InvDiscAmountEditable, VATAmount);

        // Verify
        PurchaseVerifyTotalsStatsAreCalculated(RefreshMessageEnabled, ControlStyle, InvDiscAmountEditable, PurchaseHeader);

        // Execute again - no change should happen
        DocumentTotals.PurchaseUpdateTotalsControls(
          CurrentPurchaseLine, PurchaseHeader, TotalPurchaseLine, RefreshMessageEnabled, ControlStyle, RefreshMessageText,
          InvDiscAmountEditable, VATAmount);

        // Verify
        PurchaseVerifyTotalsStatsAreCalculated(RefreshMessageEnabled, ControlStyle, InvDiscAmountEditable, PurchaseHeader);
        LibraryVariableStorage.AssertEmpty();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure PurchaseUpdateTotalsControlsRecalculatesIfTheRecordIsChanged()
    var
        PurchaseHeader: Record "Purchase Header";
        CurrentPurchaseLine: Record "Purchase Line";
        TotalsPurchaseLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        RefreshMessageEnabled: Boolean;
        InvDiscAmountEditable: Boolean;
        VATAmount: Decimal;
        ControlStyle: Text;
        RefreshMessageText: Text;
        PreviousTotalAmount: Decimal;
        NumberOfLines: Integer;
    begin
        // Setup
        Initialize();
        NumberOfLines := LibraryRandom.RandIntInRange(1, 10);
        CreatePurchaseDocument(PurchaseHeader, NumberOfLines);
        GetCurrentPurchaseLine(CurrentPurchaseLine, PurchaseHeader);
        DocumentTotals.PurchaseUpdateTotalsControls(
          CurrentPurchaseLine, PurchaseHeader, TotalsPurchaseLine, RefreshMessageEnabled, ControlStyle, RefreshMessageText,
          InvDiscAmountEditable, VATAmount);
        PreviousTotalAmount := TotalsPurchaseLine.Amount;

        // Execute
        GetCurrentPurchaseLine(CurrentPurchaseLine, PurchaseHeader);
        CurrentPurchaseLine.Validate("Line Amount", CurrentPurchaseLine."Line Amount" / 2);
        CurrentPurchaseLine.Modify(true);
        Clear(TotalsPurchaseLine);
        DocumentTotals.PurchaseUpdateTotalsControls(
          CurrentPurchaseLine, PurchaseHeader, TotalsPurchaseLine, RefreshMessageEnabled, ControlStyle, RefreshMessageText,
          InvDiscAmountEditable, VATAmount);

        // Verify
        Assert.AreNotEqual(PreviousTotalAmount, TotalsPurchaseLine.Amount, 'Total amount should be updated');
        PurchaseVerifyTotalsAreCalculated(RefreshMessageEnabled, ControlStyle, InvDiscAmountEditable, PurchaseHeader);
        LibraryVariableStorage.AssertEmpty();
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseUpdateTotalsStatsControlsRecalculatesIfTheRecordIsChanged()
    var
        PurchaseHeader: Record "Purchase Header";
        CurrentPurchaseLine: Record "Purchase Line";
        TotalsPurchaseLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        RefreshMessageEnabled: Boolean;
        InvDiscAmountEditable: Boolean;
        VATAmount: Decimal;
        ControlStyle: Text;
        RefreshMessageText: Text;
        PreviousTotalAmount: Decimal;
        NumberOfLines: Integer;
    begin
        // Setup
        Initialize();
        NumberOfLines := LibraryRandom.RandIntInRange(1, 10);
        CreatePurchaseDocument(PurchaseHeader, NumberOfLines);
        GetCurrentPurchaseLine(CurrentPurchaseLine, PurchaseHeader);
        DocumentTotals.PurchaseUpdateTotalsControls(
          CurrentPurchaseLine, PurchaseHeader, TotalsPurchaseLine, RefreshMessageEnabled, ControlStyle, RefreshMessageText,
          InvDiscAmountEditable, VATAmount);
        PreviousTotalAmount := TotalsPurchaseLine.Amount;

        // Execute
        GetCurrentPurchaseLine(CurrentPurchaseLine, PurchaseHeader);
        CurrentPurchaseLine.Validate("Line Amount", CurrentPurchaseLine."Line Amount" / 2);
        CurrentPurchaseLine.Modify(true);
        Clear(TotalsPurchaseLine);
        DocumentTotals.PurchaseUpdateTotalsControls(
          CurrentPurchaseLine, PurchaseHeader, TotalsPurchaseLine, RefreshMessageEnabled, ControlStyle, RefreshMessageText,
          InvDiscAmountEditable, VATAmount);

        // Verify
        Assert.AreNotEqual(PreviousTotalAmount, TotalsPurchaseLine.Amount, 'Total amount should be updated');
        PurchaseVerifyTotalsStatsAreCalculated(RefreshMessageEnabled, ControlStyle, InvDiscAmountEditable, PurchaseHeader);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseUpdateTotalsControlsDoesNotUpdateDocumentWithTooManyLines()
    var
        PurchaseHeader: Record "Purchase Header";
        CurrentPurchaseLine: Record "Purchase Line";
        TotalsPurchaseLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        RefreshMessageEnabled: Boolean;
        InvDiscAmountEditable: Boolean;
        VATAmount: Decimal;
        ControlStyle: Text;
        RefreshMessageText: Text;
        NumberOfLines: Integer;
    begin
        // Setup
        Initialize();
        NumberOfLines := LibraryRandom.RandIntInRange(11, 110);
        CreatePurchaseDocument(PurchaseHeader, NumberOfLines);
        GetCurrentPurchaseLine(CurrentPurchaseLine, PurchaseHeader);

        // Execute
        DocumentTotals.PurchaseUpdateTotalsControls(
          CurrentPurchaseLine, PurchaseHeader, TotalsPurchaseLine, RefreshMessageEnabled, ControlStyle, RefreshMessageText,
          InvDiscAmountEditable, VATAmount);

        // Verify
        PurchaseVerifyTotalsAreSetToZero(RefreshMessageEnabled, ControlStyle, InvDiscAmountEditable, TotalsPurchaseLine, VATAmount);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseUpdateTotalsControlsDoesNotUpdateDocumentWhenRedistributeIsPending()
    var
        PurchaseHeader: Record "Purchase Header";
        CurrentPurchaseLine: Record "Purchase Line";
        TotalsPurchaseLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        RefreshMessageEnabled: Boolean;
        InvDiscAmountEditable: Boolean;
        VATAmount: Decimal;
        ControlStyle: Text;
        RefreshMessageText: Text;
        NumberOfLines: Integer;
    begin
        // Setup
        Initialize();
        NumberOfLines := LibraryRandom.RandIntInRange(1, 10);
        CreatePurchaseDocument(PurchaseHeader, NumberOfLines);
        GetCurrentPurchaseLine(CurrentPurchaseLine, PurchaseHeader);

        PurchaseHeader.Validate("Invoice Discount Calculation", PurchaseHeader."Invoice Discount Calculation"::"%");
        PurchaseHeader.Modify();

        CurrentPurchaseLine.Validate("Recalculate Invoice Disc.", true);
        CurrentPurchaseLine.Modify();

        // Execute
        DocumentTotals.PurchaseUpdateTotalsControls(
          CurrentPurchaseLine, PurchaseHeader, TotalsPurchaseLine, RefreshMessageEnabled, ControlStyle, RefreshMessageText,
          InvDiscAmountEditable, VATAmount);

        // Verify
        PurchaseVerifyTotalsAreSetToZero(RefreshMessageEnabled, ControlStyle, InvDiscAmountEditable, TotalsPurchaseLine, VATAmount);

        // Execute - Verify that calling it twice will not reset
        DocumentTotals.PurchaseUpdateTotalsControls(
          CurrentPurchaseLine, PurchaseHeader, TotalsPurchaseLine, RefreshMessageEnabled, ControlStyle, RefreshMessageText,
          InvDiscAmountEditable, VATAmount);

        // Verify
        PurchaseVerifyTotalsAreSetToZero(RefreshMessageEnabled, ControlStyle, InvDiscAmountEditable, TotalsPurchaseLine, VATAmount);
        LibraryVariableStorage.AssertEmpty();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure PurchaseRedistributeTotalsClearsRefreshMessageAndTotalsAreUpdated()
    var
        PurchaseHeader: Record "Purchase Header";
        CurrentPurchaseLine: Record "Purchase Line";
        TotalsPurchaseLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        RefreshMessageEnabled: Boolean;
        InvDiscAmountEditable: Boolean;
        VATAmount: Decimal;
        ControlStyle: Text;
        RefreshMessageText: Text;
        NumberOfLines: Integer;
    begin
        // Setup
        Initialize();
        NumberOfLines := LibraryRandom.RandIntInRange(1, 10);
        CreatePurchaseDocument(PurchaseHeader, NumberOfLines);
        GetCurrentPurchaseLine(CurrentPurchaseLine, PurchaseHeader);

        PurchaseHeader.Validate("Invoice Discount Calculation", PurchaseHeader."Invoice Discount Calculation"::"%");
        PurchaseHeader.Modify();

        CurrentPurchaseLine.Validate("Recalculate Invoice Disc.", true);
        CurrentPurchaseLine.Modify();

        DocumentTotals.PurchaseUpdateTotalsControls(
          CurrentPurchaseLine, PurchaseHeader, TotalsPurchaseLine, RefreshMessageEnabled, ControlStyle, RefreshMessageText,
          InvDiscAmountEditable, VATAmount);

        // Execute - Verify that calling it twice will not reset
        PurchCalcDiscByType.ApplyDefaultInvoiceDiscount(0, PurchaseHeader);
        DocumentTotals.PurchaseUpdateTotalsControls(
          CurrentPurchaseLine, PurchaseHeader, TotalsPurchaseLine, RefreshMessageEnabled, ControlStyle, RefreshMessageText,
          InvDiscAmountEditable, VATAmount);

        // Verify
        PurchaseVerifyTotalsAreCalculated(RefreshMessageEnabled, ControlStyle, InvDiscAmountEditable, PurchaseHeader);
        LibraryVariableStorage.AssertEmpty();
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseRedistributeTotalsStatsClearsRefreshMessageAndTotalsAreUpdated()
    var
        PurchaseHeader: Record "Purchase Header";
        CurrentPurchaseLine: Record "Purchase Line";
        TotalsPurchaseLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        RefreshMessageEnabled: Boolean;
        InvDiscAmountEditable: Boolean;
        VATAmount: Decimal;
        ControlStyle: Text;
        RefreshMessageText: Text;
        NumberOfLines: Integer;
    begin
        // Setup
        Initialize();
        NumberOfLines := LibraryRandom.RandIntInRange(1, 10);
        CreatePurchaseDocument(PurchaseHeader, NumberOfLines);
        GetCurrentPurchaseLine(CurrentPurchaseLine, PurchaseHeader);

        PurchaseHeader.Validate("Invoice Discount Calculation", PurchaseHeader."Invoice Discount Calculation"::"%");
        PurchaseHeader.Modify();

        CurrentPurchaseLine.Validate("Recalculate Invoice Disc.", true);
        CurrentPurchaseLine.Modify();

        DocumentTotals.PurchaseUpdateTotalsControls(
          CurrentPurchaseLine, PurchaseHeader, TotalsPurchaseLine, RefreshMessageEnabled, ControlStyle, RefreshMessageText,
          InvDiscAmountEditable, VATAmount);

        // Execute - Verify that calling it twice will not reset
        PurchCalcDiscByType.ApplyDefaultInvoiceDiscount(0, PurchaseHeader);
        DocumentTotals.PurchaseUpdateTotalsControls(
          CurrentPurchaseLine, PurchaseHeader, TotalsPurchaseLine, RefreshMessageEnabled, ControlStyle, RefreshMessageText,
          InvDiscAmountEditable, VATAmount);

        // Verify
        PurchaseVerifyTotalsStatsAreCalculated(RefreshMessageEnabled, ControlStyle, InvDiscAmountEditable, PurchaseHeader);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VatAmountRecalculationOnPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderForFailedCalcTotal: Record "Purchase Header";
        CurrentPurchaseLine: Record "Purchase Line";
        TotalPurchaseLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        ControlStyle: Text;
        RefreshMessageText: Text;
        TotalAmount: Decimal;
        VATAmount: Decimal;
        VATAmountRecalculated: Decimal;
        VATAmountForFailedCalcTotal: Decimal;
        RefreshMessageEnabled: Boolean;
        InvDiscAmountEditable: Boolean;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 377200] Vat Amount should be recalculated on Purchase Order if it is calculated after Refresh Message Enabled
        Initialize();

        // [GIVEN] Calculated Totals for Purchase Order "P1"
        CreatePurchaseDocument(PurchaseHeader, 1);
        GetCurrentPurchaseLine(CurrentPurchaseLine, PurchaseHeader);
        DocumentTotals.PurchaseUpdateTotalsControls(
          CurrentPurchaseLine, PurchaseHeader, TotalPurchaseLine, RefreshMessageEnabled, ControlStyle, RefreshMessageText,
          InvDiscAmountEditable, VATAmount);
        TotalAmount := TotalPurchaseLine.Amount;

        // [GIVEN] Calculated Totals for Purchase Order "P2" with Refresh Message Enabled = TRUE
        CreatePurchaseDocument(PurchaseHeaderForFailedCalcTotal, 1);
        PurchaseHeaderForFailedCalcTotal."Invoice Discount Calculation" :=
          PurchaseHeaderForFailedCalcTotal."Invoice Discount Calculation"::"%"; // Getting Refresh Message Enabled = TRUE
        PurchaseHeaderForFailedCalcTotal.Modify();
        GetCurrentPurchaseLine(CurrentPurchaseLine, PurchaseHeaderForFailedCalcTotal);
        DocumentTotals.PurchaseUpdateTotalsControls(
          CurrentPurchaseLine, PurchaseHeaderForFailedCalcTotal, TotalPurchaseLine, RefreshMessageEnabled, ControlStyle, RefreshMessageText,
          InvDiscAmountEditable, VATAmountForFailedCalcTotal);

        // [WHEN] Calculate Totals for Purchase Order "P1"
        GetCurrentPurchaseLine(CurrentPurchaseLine, PurchaseHeader);
        DocumentTotals.PurchaseUpdateTotalsControls(
          CurrentPurchaseLine, PurchaseHeader, TotalPurchaseLine, RefreshMessageEnabled, ControlStyle, RefreshMessageText,
          InvDiscAmountEditable, VATAmountRecalculated);

        // [THEN] Vat Amount for Purchase Order "P1" is recalculated
        Assert.AreEqual(TotalAmount, TotalPurchaseLine.Amount, VatAmountRecalculatedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VatAmountRecalculationOnSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderForFailedCalcTotal: Record "Sales Header";
        CurrentSalesLine: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        ControlStyle: Text;
        RefreshMessageText: Text;
        TotalAmount: Decimal;
        VATAmount: Decimal;
        VATAmountRecalculated: Decimal;
        VATAmountForFailedCalcTotal: Decimal;
        RefreshMessageEnabled: Boolean;
        InvDiscAmountEditable: Boolean;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 377200] Vat Amount should be recalculated on Sales Order if it is calculated after Refresh Message Enabled
        Initialize();

        // [GIVEN] Calculated Totals for Sales Order "S1"
        CreateSalesDocument(SalesHeader, 1);
        GetCurrentSalesLine(CurrentSalesLine, SalesHeader);
        DocumentTotals.SalesUpdateTotalsControls(
          CurrentSalesLine, SalesHeader, TotalSalesLine, RefreshMessageEnabled, ControlStyle, RefreshMessageText, InvDiscAmountEditable,
          true, VATAmount);
        TotalAmount := TotalSalesLine.Amount;

        // [GIVEN] Calculated Totals for Sales Order "S2" with Refresh Message Enabled = TRUE
        CreateSalesDocument(SalesHeaderForFailedCalcTotal, 101); // Getting Refresh Message Enabled = TRUE
        GetCurrentSalesLine(CurrentSalesLine, SalesHeaderForFailedCalcTotal);
        DocumentTotals.SalesUpdateTotalsControls(
          CurrentSalesLine, SalesHeaderForFailedCalcTotal, TotalSalesLine, RefreshMessageEnabled, ControlStyle, RefreshMessageText,
          InvDiscAmountEditable, true, VATAmountForFailedCalcTotal);

        // [WHEN] Calculate Totals for Sales Order "S1"
        GetCurrentSalesLine(CurrentSalesLine, SalesHeader);
        DocumentTotals.SalesUpdateTotalsControls(
          CurrentSalesLine, SalesHeader, TotalSalesLine, RefreshMessageEnabled, ControlStyle, RefreshMessageText, InvDiscAmountEditable,
          true, VATAmountRecalculated);

        // [THEN] Vat Amount for Sales Order "S1" is recalculated
        Assert.AreEqual(TotalAmount, TotalSalesLine.Amount, VatAmountRecalculatedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecalculateAmountsOnChangeSalesDocuments()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderNoAmount: Record "Sales Header";
        CurrentSalesLine: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        ControlStyle: Text;
        RefreshMessageText: Text;
        VATAmount: Decimal;
        RefreshMessageEnabled: Boolean;
        InvDiscAmountEditable: Boolean;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 254399] COD57 recalculates totals for changed sales document even if codeunit instance is cleared
        Initialize();

        // [GIVEN] Sales order "O1" with "Amount" = 100 and "VAT Amount" = 10
        CreateSalesDocument(SalesHeader, 1);

        // [GIVEN] Sales order "O2" with "Amount" = 0 and "VAT Amount" = 0
        CreateSalesDocument(SalesHeaderNoAmount, 1);
        GetCurrentSalesLine(CurrentSalesLine, SalesHeaderNoAmount);
        CurrentSalesLine.Validate("Unit Price", 0);
        CurrentSalesLine.Modify(true);

        // [GIVEN] Document totals calculated, "Total Amount" = 100 and "Total VAT Amount" = 10
        GetCurrentSalesLine(CurrentSalesLine, SalesHeader);
        DocumentTotals.SalesUpdateTotalsControls(
          CurrentSalesLine, SalesHeader, TotalSalesLine, RefreshMessageEnabled, ControlStyle, RefreshMessageText,
          InvDiscAmountEditable, true, VATAmount);
        TotalSalesLine.TestField(Amount);
        TotalSalesLine.TestField("Amount Including VAT");

        // [GIVEN] Document Totals instance cleared
        Clear(DocumentTotals);

        // [WHEN] When browsing from "O1" to "O2"
        GetCurrentSalesLine(CurrentSalesLine, SalesHeaderNoAmount);
        DocumentTotals.SalesUpdateTotalsControls(
          CurrentSalesLine, SalesHeader, TotalSalesLine, RefreshMessageEnabled, ControlStyle, RefreshMessageText,
          InvDiscAmountEditable, true, VATAmount);

        // [THEN] Document totals calculated, "Total Amount" = 0 and "Total VAT Amount" = 0
        TotalSalesLine.TestField(Amount, 0);
        TotalSalesLine.TestField("Amount Including VAT", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecalculateAmountsOnChangePurchaseDocuments()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderNoAmount: Record "Purchase Header";
        CurrentPurchaseLine: Record "Purchase Line";
        TotalPurchaseLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        ControlStyle: Text;
        RefreshMessageText: Text;
        VATAmount: Decimal;
        RefreshMessageEnabled: Boolean;
        InvDiscAmountEditable: Boolean;
    begin
        // [FEATURE] [Purchases]
        // [SCENARIO 254399] COD57 recalculates totals for changed purchase document even if codeunit instance is cleared
        Initialize();

        // [GIVEN] Purchase order "O1" with "Amount" = 100 and "VAT Amount" = 10
        CreatePurchaseDocument(PurchaseHeader, 1);

        // [GIVEN] Purchase order "O2" with "Amount" = 0 and "VAT Amount" = 0
        CreatePurchaseDocument(PurchaseHeaderNoAmount, 1);
        GetCurrentPurchaseLine(CurrentPurchaseLine, PurchaseHeaderNoAmount);
        CurrentPurchaseLine.Validate("Direct Unit Cost", 0);
        CurrentPurchaseLine.Modify(true);

        // [GIVEN] Document totals calculated for "O1", "Total Amount" = 100 and "Total VAT Amount" = 10
        GetCurrentPurchaseLine(CurrentPurchaseLine, PurchaseHeader);
        DocumentTotals.PurchaseUpdateTotalsControls(
          CurrentPurchaseLine, PurchaseHeader, TotalPurchaseLine, RefreshMessageEnabled, ControlStyle, RefreshMessageText,
          InvDiscAmountEditable, VATAmount);
        TotalPurchaseLine.TestField(Amount);
        TotalPurchaseLine.TestField("Amount Including VAT");

        // [GIVEN] Document Totals instance cleared
        Clear(DocumentTotals);

        // [WHEN] When browsing from "O1" to "O2"
        GetCurrentPurchaseLine(CurrentPurchaseLine, PurchaseHeaderNoAmount);
        DocumentTotals.PurchaseUpdateTotalsControls(
          CurrentPurchaseLine, PurchaseHeader, TotalPurchaseLine, RefreshMessageEnabled, ControlStyle, RefreshMessageText,
          InvDiscAmountEditable, VATAmount);

        // [THEN] Document totals calculated, "Total Amount" = 0 and "Total VAT Amount" = 0
        TotalPurchaseLine.TestField(Amount, 0);
        TotalPurchaseLine.TestField("Amount Including VAT", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderLineDiscountRoundingOnDocTotals()
    var
        SalesLine: Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
        DocumentTotals: Codeunit "Document Totals";
        VATAmount: Decimal;
        ExpectedLineAmount: Decimal;
    begin
        // [FEATURE] [Rounding] [Line Discount] [Sales] [Order]
        // [SCENARIO 254486] Line amount to handle and document total amount = 16700 when sales order line's quantity = 10000, price = 28.68 and line discount = 270100
        Initialize();

        ExpectedLineAmount := 16700;
        CreateSalesDocumentWithAmounts(SalesLine, SalesLine."Document Type"::Order, 10000, 28.68, 270100);

        DocumentTotals.CalculateSalesPageTotals(TempSalesLine, VATAmount, SalesLine);

        Assert.AreEqual(
          ExpectedLineAmount, SalesLine.GetLineAmountToHandle(SalesLine."Qty. to Invoice"), GetLineAmountToHandleErr);
        TempSalesLine.TestField(Amount, ExpectedLineAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderLineDiscountRoundingOnDocTotals()
    var
        PurchaseLine: Record "Purchase Line";
        TempPurchaseLine: Record "Purchase Line" temporary;
        DocumentTotals: Codeunit "Document Totals";
        VATAmount: Decimal;
        ExpectedLineAmount: Decimal;
    begin
        // [FEATURE] [Rounding] [Line Discount] [Purchase] [Order]
        // [SCENARIO 254486] Line amount to handle and document total amount = 16700 when purchase order line's quantity = 10000, price = 28.68 and line discount = 270100
        Initialize();

        ExpectedLineAmount := 16700;
        CreatePurchaseDocumentWithAmounts(PurchaseLine, PurchaseLine."Document Type"::Order, 10000, 28.68, 270100);

        DocumentTotals.CalculatePurchasePageTotals(TempPurchaseLine, VATAmount, PurchaseLine);

        Assert.AreEqual(
          ExpectedLineAmount, PurchaseLine.GetLineAmountToHandle(PurchaseLine."Qty. to Invoice"), GetLineAmountToHandleErr);
        TempPurchaseLine.TestField(Amount, ExpectedLineAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceLineDiscountRoundingOnDocTotals()
    var
        SalesLine: Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
        DocumentTotals: Codeunit "Document Totals";
        VATAmount: Decimal;
        ExpectedLineAmount: Decimal;
    begin
        // [FEATURE] [Rounding] [Line Discount] [Sales] [Invoice]
        // [SCENARIO 254486] Line amount to handle and document total amount = 16700 when sales invoice line's quantity = 10000, price = 28.68 and line discount = 270100
        Initialize();

        ExpectedLineAmount := 16700;
        CreateSalesDocumentWithAmounts(SalesLine, SalesLine."Document Type"::Invoice, 10000, 28.68, 270100);

        DocumentTotals.CalculateSalesPageTotals(TempSalesLine, VATAmount, SalesLine);

        Assert.AreEqual(
          ExpectedLineAmount, SalesLine.GetLineAmountToHandle(SalesLine."Qty. to Invoice"), GetLineAmountToHandleErr);
        TempSalesLine.TestField(Amount, ExpectedLineAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceLineDiscountRoundingOnDocTotals()
    var
        PurchaseLine: Record "Purchase Line";
        TempPurchaseLine: Record "Purchase Line" temporary;
        DocumentTotals: Codeunit "Document Totals";
        VATAmount: Decimal;
        ExpectedLineAmount: Decimal;
    begin
        // [FEATURE] [Rounding] [Line Discount] [Purchase] [Invoice]
        // [SCENARIO 254486] Line amount to handle and document total amount = 16700 when purchase invoice line's quantity = 10000, price = 28.68 and line discount = 270100
        Initialize();

        ExpectedLineAmount := 16700;
        CreatePurchaseDocumentWithAmounts(PurchaseLine, PurchaseLine."Document Type"::Order, 10000, 28.68, 270100);

        DocumentTotals.CalculatePurchasePageTotals(TempPurchaseLine, VATAmount, PurchaseLine);

        Assert.AreEqual(
          ExpectedLineAmount, PurchaseLine.GetLineAmountToHandle(PurchaseLine."Qty. to Invoice"), GetLineAmountToHandleErr);
        TempPurchaseLine.TestField(Amount, ExpectedLineAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderVATAmountOnDocTotalsVATRoundingTypeDown()
    var
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [UI] [Rounding] [Line Discount] [Order] [Sales]
        // [SCENARIO 251202] Document totals shows VAT Amoount = 9.79 for document with line amounts = 50.45 and -1.47 when VAT = 20%  on sales order card
        Initialize();

        LibraryERM.SetVATRoundingType('<');
        LibrarySales.SetInvoiceRounding(false);
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 20);

        CreateSalesDocumentWithTwoLines(SalesHeader, SalesHeader."Document Type"::Order, VATPostingSetup, 50.45, -1.47);

        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder.SalesLines."Total VAT Amount".AssertEquals(9.79);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderVATAmountOnDocTotalsVATRoundingTypeDown()
    var
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [UI] [Rounding] [Line Discount] [Order] [Purchase]
        // [SCENARIO 251202] Document totals shows VAT Amoount = 9.79 for document with line amounts = 50.45 and -1.47 when VAT = 20%  on purchase order card
        Initialize();

        LibraryERM.SetVATRoundingType('<');
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 20);

        CreatePurchaseDocumentWithTwoLines(PurchaseHeader, PurchaseHeader."Document Type"::Order, VATPostingSetup, 50.45, -1.47);

        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        PurchaseOrder.PurchLines."Total VAT Amount".AssertEquals(9.79);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceVATAmountOnDocTotalsVATRoundingTypeDown()
    var
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [UI] [Rounding] [Line Discount] [Invoice] [Sales]
        // [SCENARIO 251202] Document totals shows VAT Amoount = 9.79 for document with line amounts = 50.45 and -1.47 when VAT = 20%  on sales invoice card
        Initialize();

        LibraryERM.SetVATRoundingType('<');
        LibrarySales.SetInvoiceRounding(false);
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 20);

        CreateSalesDocumentWithTwoLines(SalesHeader, SalesHeader."Document Type"::Invoice, VATPostingSetup, 50.45, -1.47);

        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);
        SalesInvoice.SalesLines."Total VAT Amount".AssertEquals(9.79);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceVATAmountOnDocTotalsVATRoundingTypeDown()
    var
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [UI] [Rounding] [Line Discount] [Invoice] [Purchase]
        // [SCENARIO 251202] Document totals shows VAT Amoount = 9.79 for document with line amounts = 50.45 and -1.47 when VAT = 20%  on purchase invoice card
        Initialize();

        LibraryERM.SetVATRoundingType('<');
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 20);

        CreatePurchaseDocumentWithTwoLines(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VATPostingSetup, 50.45, -1.47);

        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);
        PurchaseInvoice.PurchLines."Total VAT Amount".AssertEquals(9.79);
    end;

    local procedure Initialize()
    begin
        LibraryApplicationArea.DisableApplicationAreaSetup();
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Document Totals UT");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Document Totals UT");

        LibraryPurchase.SetCalcInvDiscount(false);
        LibrarySales.SetCalcInvDiscount(false);
        LibrarySales.SetStockoutWarning(false);

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();

        isInitialized := true;

        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");

        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Document Totals UT");
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; NumberOfLines: Integer)
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
        Customer: Record Customer;
        I: Integer;
    begin
        CreateCustomer(Customer);
        CreateItem(Item);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        for I := 1 to NumberOfLines do begin
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.",
              LibraryRandom.RandIntInRange(1, 30));
            SalesLine.Validate("Qty. to Invoice", SalesLine.Quantity);
        end;
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; NumberOfLines: Integer)
    var
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        Vendor: Record Vendor;
        I: Integer;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        CreateItem(Item);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");

        for I := 1 to NumberOfLines do begin
            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.",
              LibraryRandom.RandIntInRange(1, 30));
            PurchaseLine.Validate("Qty. to Invoice", PurchaseLine.Quantity);
        end;
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Name := Customer."No.";
        Customer.Modify();
    end;

    local procedure CreateCustomerWithDiscount(var Customer: Record Customer)
    var
        minAmount: Decimal;
        discPct: Decimal;
    begin
        CreateCustomer(Customer);
        minAmount := LibraryRandom.RandDecInDecimalRange(1, 100, 2);
        discPct := LibraryRandom.RandDecInDecimalRange(1, 100, 1);
        AddInvoiceDiscToCustomer(Customer, minAmount, discPct);
    end;

    local procedure AddInvoiceDiscToCustomer(Customer: Record Customer; MinimumAmount: Decimal; Percentage: Decimal)
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, Customer."No.", Customer."Currency Code", MinimumAmount);
        CustInvoiceDisc.Validate("Discount %", Percentage);
        CustInvoiceDisc.Modify(true);
    end;

    local procedure CreateItem(var Item: Record Item)
    var
        UnitPrice: Decimal;
        LastDirectCost: Decimal;
    begin
        UnitPrice := LibraryRandom.RandDecInRange(1, 1000, 2);
        LastDirectCost := LibraryRandom.RandDecInRange(1, 1000, 2);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", UnitPrice);
        Item.Validate("Last Direct Cost", LastDirectCost);
        Item.Modify();
    end;

    local procedure CreatePurchaseDocumentWithAmounts(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; LineQuantity: Decimal; LineDirectUnitCost: Decimal; LineDiscountAmount: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), LineQuantity);
        PurchaseLine.Validate("Direct Unit Cost", LineDirectUnitCost);
        PurchaseLine.Validate("Line Discount Amount", LineDiscountAmount);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesDocumentWithAmounts(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; LineQuantity: Decimal; LineUnitPrice: Decimal; LineDiscountAmount: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), LineQuantity);
        SalesLine.Validate("Unit Price", LineUnitPrice);
        SalesLine.Validate("Line Discount Amount", LineDiscountAmount);
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchaseDocumentWithTwoLines(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VATPostingSetup: Record "VAT Posting Setup"; LineDirectUnitCost1: Decimal; LineDirectUnitCost2: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, DocumentType,
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::Purchase), 1);
        PurchaseLine.Validate("Direct Unit Cost", LineDirectUnitCost1);
        PurchaseLine.Modify(true);
        PurchaseLine."Line No." := LibraryUtility.GetNewRecNo(PurchaseLine, PurchaseLine.FieldNo("Line No."));
        PurchaseLine.Validate("Direct Unit Cost", LineDirectUnitCost2);
        PurchaseLine.Insert(true);
    end;

    local procedure CreateSalesDocumentWithTwoLines(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; VATPostingSetup: Record "VAT Posting Setup"; LineUnitPrice1: Decimal; LineUnitPrice2: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(
          SalesHeader, DocumentType,
          LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::Purchase), 1);
        SalesLine.Validate("Unit Price", LineUnitPrice1);
        SalesLine.Modify(true);
        SalesLine."Line No." := LibraryUtility.GetNewRecNo(SalesLine, SalesLine.FieldNo("Line No."));
        SalesLine.Validate("Unit Price", LineUnitPrice2);
        SalesLine.Insert(true);
    end;

    local procedure GetCurrentSalesLine(var CurrentSalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        CurrentSalesLine.SetRange("Document Type", SalesHeader."Document Type");
        CurrentSalesLine.SetRange("Document No.", SalesHeader."No.");
        CurrentSalesLine.FindFirst();
    end;

    local procedure GetCurrentPurchaseLine(var CurrentPurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
        CurrentPurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        CurrentPurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        CurrentPurchaseLine.FindFirst();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    local procedure SalesCompareWithOrderStatistics(SalesHeader: Record "Sales Header")
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(SalesOrder.SalesLines."Invoice Discount Amount".AsDecimal());
        LibraryVariableStorage.Enqueue(
          DoInvoiceRounding(SalesHeader."Currency Code", SalesOrder.SalesLines."Total Amount Incl. VAT".AsDecimal()));
        LibraryVariableStorage.Enqueue(SalesOrder.SalesLines."Total VAT Amount".AsDecimal());
        SalesOrder.Statistics.Invoke();
    end;
#endif
    local procedure SalesCompareWithOrderStatisticsNM(SalesHeader: Record "Sales Header")
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(SalesOrder.SalesLines."Invoice Discount Amount".AsDecimal());
        LibraryVariableStorage.Enqueue(
          DoInvoiceRounding(SalesHeader."Currency Code", SalesOrder.SalesLines."Total Amount Incl. VAT".AsDecimal()));
        LibraryVariableStorage.Enqueue(SalesOrder.SalesLines."Total VAT Amount".AsDecimal());
        SalesOrder.SalesOrderStatistics.Invoke();
    end;

    local procedure SalesVerifyTotalsAreSetToZero(RefreshMessageEnabled: Boolean; ControlStyle: Text; InvDiscAmountEditable: Boolean; TotalsSalesLine: Record "Sales Line"; VATAmount: Decimal)
    begin
        Assert.IsTrue(RefreshMessageEnabled, 'Refresh message enabled needs to be true for invoices larger than 10 lines');
        Assert.AreEqual(ControlStyle, 'Subordinate', 'Wrong style value');
        Assert.IsFalse(InvDiscAmountEditable, 'Invoice Discount amount field must not be editable');
        Assert.AreEqual(0, TotalsSalesLine.Amount, 'When totals are not calcualted Amount value must be set to zero');
        Assert.AreEqual(
          0, TotalsSalesLine."Amount Including VAT", 'When totals are not calcualted Amount Including VAT must be set to zero');
        Assert.AreEqual(0, VATAmount, 'When totals are not calcualted VAT Amount must be set to zero');
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    local procedure SalesVerifyTotalsAreCalculated(RefreshMessageEnabled: Boolean; ControlStyle: Text; InvDiscAmountEditable: Boolean; SalesHeader: Record "Sales Header")
    begin
        Assert.IsFalse(RefreshMessageEnabled, 'Refresh message enabled needs to be false for invoices under 10 lines');
        Assert.AreEqual(ControlStyle, 'Strong', 'Wrong style value');
        Assert.IsTrue(InvDiscAmountEditable, 'Invoice Discount amount should be editable');

        SalesCompareWithOrderStatistics(SalesHeader);
    end;
#endif
    local procedure SalesVerifyTotalsAreCalculatedNM(RefreshMessageEnabled: Boolean; ControlStyle: Text; InvDiscAmountEditable: Boolean; SalesHeader: Record "Sales Header")
    begin
        Assert.IsFalse(RefreshMessageEnabled, 'Refresh message enabled needs to be false for invoices under 10 lines');
        Assert.AreEqual(ControlStyle, 'Strong', 'Wrong style value');
        Assert.IsTrue(InvDiscAmountEditable, 'Invoice Discount amount should be editable');

        SalesCompareWithOrderStatisticsNM(SalesHeader);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    local procedure PurchaseCompareWithOrderStatistics(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(PurchaseOrder.PurchLines."Invoice Discount Amount".AsDecimal());
        LibraryVariableStorage.Enqueue(PurchaseOrder.PurchLines."Total Amount Incl. VAT".AsDecimal());
        LibraryVariableStorage.Enqueue(PurchaseOrder.PurchLines."Total VAT Amount".AsDecimal());
        PurchaseOrder.Statistics.Invoke();
    end;
#endif

    local procedure PurchaseCompareWithOrderStats(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(PurchaseOrder.PurchLines."Invoice Discount Amount".AsDecimal());
        LibraryVariableStorage.Enqueue(PurchaseOrder.PurchLines."Total Amount Incl. VAT".AsDecimal());
        LibraryVariableStorage.Enqueue(PurchaseOrder.PurchLines."Total VAT Amount".AsDecimal());
        PurchaseOrder.PurchaseOrderStatistics.Invoke();
    end;

    local procedure PurchaseVerifyTotalsAreSetToZero(RefreshMessageEnabled: Boolean; ControlStyle: Text; InvDiscAmountEditable: Boolean; TotalsPurchaseLine: Record "Purchase Line"; VATAmount: Decimal)
    begin
        Assert.IsTrue(RefreshMessageEnabled, 'Refresh message enabled needs to be true for invoices larger than 10 lines');
        Assert.AreEqual(ControlStyle, 'Subordinate', 'Wrong style value');
        Assert.IsFalse(InvDiscAmountEditable, 'Invoice Discount amount field must not be editable');
        Assert.AreEqual(0, TotalsPurchaseLine.Amount, 'When totals are not calcualted Amount value must be set to zero');
        Assert.AreEqual(
          0, TotalsPurchaseLine."Amount Including VAT", 'When totals are not calcualted Amount Including VAT must be set to zero');
        Assert.AreEqual(0, VATAmount, 'When totals are not calcualted VAT Amount must be set to zero');
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    local procedure PurchaseVerifyTotalsAreCalculated(RefreshMessageEnabled: Boolean; ControlStyle: Text; InvDiscAmountEditable: Boolean; PurchaseHeader: Record "Purchase Header")
    begin
        Assert.IsFalse(RefreshMessageEnabled, 'Refresh message enabled needs to be false for invoices under 10 lines');
        Assert.AreEqual(ControlStyle, 'Strong', 'Wrong style value');
        Assert.IsTrue(InvDiscAmountEditable, 'Invoice Discount amount should be editable');

        PurchaseCompareWithOrderStatistics(PurchaseHeader);
    end;
#endif

    local procedure PurchaseVerifyTotalsStatsAreCalculated(RefreshMessageEnabled: Boolean; ControlStyle: Text; InvDiscAmountEditable: Boolean; PurchaseHeader: Record "Purchase Header")
    begin
        Assert.IsFalse(RefreshMessageEnabled, 'Refresh message enabled needs to be false for invoices under 10 lines');
        Assert.AreEqual(ControlStyle, 'Strong', 'Wrong style value');
        Assert.IsTrue(InvDiscAmountEditable, 'Invoice Discount amount should be editable');

        PurchaseCompareWithOrderStats(PurchaseHeader);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsModalHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    var
        VATApplied: Variant;
        TotalAmountInclVAT: Variant;
        InvDiscAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(InvDiscAmount);
        LibraryVariableStorage.Dequeue(TotalAmountInclVAT);
        LibraryVariableStorage.Dequeue(VATApplied);

        Assert.AreEqual(InvDiscAmount, SalesOrderStatistics.InvDiscountAmount_General.AsDecimal(),
          'Invoice Discount Amount is not correct');
        Assert.AreEqual(TotalAmountInclVAT, SalesOrderStatistics."TotalAmount2[1]".AsDecimal(),
          'Total Amount Incl. VAT is not correct');
        Assert.AreEqual(VATApplied, SalesOrderStatistics.VATAmount.AsDecimal(),
          'VAT Amount is not correct');
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    var
        VATApplied: Variant;
        TotalAmountInclVAT: Variant;
        InvDiscAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(InvDiscAmount);
        LibraryVariableStorage.Dequeue(TotalAmountInclVAT);
        LibraryVariableStorage.Dequeue(VATApplied);

        Assert.AreEqual(InvDiscAmount, SalesOrderStatistics.InvDiscountAmount_General.AsDecimal(),
          'Invoice Discount Amount is not correct');
        Assert.AreEqual(TotalAmountInclVAT, SalesOrderStatistics."TotalAmount2[1]".AsDecimal(),
          'Total Amount Incl. VAT is not correct');
        Assert.AreEqual(VATApplied, SalesOrderStatistics.VATAmount.AsDecimal(),
          'VAT Amount is not correct');
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatisticsModalHandler(var PurchaseOrderStatistics: TestPage "Purchase Order Statistics")
    var
        VATApplied: Variant;
        TotalAmountInclVAT: Variant;
        InvDiscAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(InvDiscAmount);
        LibraryVariableStorage.Dequeue(TotalAmountInclVAT);
        LibraryVariableStorage.Dequeue(VATApplied);

        Assert.AreEqual(InvDiscAmount, PurchaseOrderStatistics.InvDiscountAmount_General.AsDecimal(),
          'Invoice Discount Amount is not correct');
        Assert.AreEqual(TotalAmountInclVAT, PurchaseOrderStatistics.TotalInclVAT_General.AsDecimal(),
          'Total Amount Incl. VAT is not correct');
        Assert.AreEqual(VATApplied, PurchaseOrderStatistics."VATAmount[1]".AsDecimal(),
          'VAT Amount is not correct');
    end;
#endif

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatisticsPageHandler(var PurchaseOrderStatistics: TestPage "Purchase Order Statistics")
    var
        VATApplied: Variant;
        TotalAmountInclVAT: Variant;
        InvDiscAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(InvDiscAmount);
        LibraryVariableStorage.Dequeue(TotalAmountInclVAT);
        LibraryVariableStorage.Dequeue(VATApplied);

        Assert.AreEqual(InvDiscAmount, PurchaseOrderStatistics.InvDiscountAmount_General.AsDecimal(),
          'Invoice Discount Amount is not correct');
        Assert.AreEqual(TotalAmountInclVAT, PurchaseOrderStatistics.TotalInclVAT_General.AsDecimal(),
          'Total Amount Incl. VAT is not correct');
        Assert.AreEqual(VATApplied, PurchaseOrderStatistics."VATAmount[1]".AsDecimal(),
          'VAT Amount is not correct');
    end;

    local procedure DoInvoiceRounding(CurrencyCode: Code[10]; Amount: Decimal): Decimal
    var
        Currency: Record Currency;
    begin
        if not Currency.Get(CurrencyCode) then
            Currency.InitRoundingPrecision();
        exit(Round(Amount, Currency."Invoice Rounding Precision", Currency.InvoiceRoundingDirection()))
    end;
}

