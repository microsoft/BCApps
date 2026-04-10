codeunit 134051 "ERM VAT Tool - Sales Doc"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [VAT Rate Change] [Sales]
        isInitialized := false;
    end;

    var
        VATRateChangeSetup2: Record "VAT Rate Change Setup";
        SalesHeader2: Record "Sales Header";
        Assert: Codeunit Assert;
        ERMVATToolHelper: Codeunit "ERM VAT Tool - Helper";
        LibraryERM: Codeunit "Library - ERM";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPlanning: Codeunit "Library - Planning";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        isInitialized: Boolean;
        GroupFilter: Label '%1|%2', Locked = true;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM VAT Tool - Sales Doc");
        ERMVATToolHelper.ResetToolSetup();  // This resets the setup table for all test cases.
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM VAT Tool - Sales Doc");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        ERMVATToolHelper.SetupItemNos();
        ERMVATToolHelper.ResetToolSetup();  // This resets setup table for the first test case after database is restored.
        LibrarySetupStorage.SaveSalesSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM VAT Tool - Sales Doc");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesDocConvFalse()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Run VAT Rate Change with Perform Conversion = FALSE, expect no updates.
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create data with groups to update.
        ERMVATToolHelper.CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, '', 1);

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolSales(VATRateChangeSetup2."Update Sales Documents"::Both, false, false);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: No data was updated
        ERMVATToolHelper.VerifyUpdateConvFalse(DATABASE::"Sales Line");

        // Verify: Log entries
        ERMVATToolHelper.VerifyLogEntriesConvFalse(DATABASE::"Sales Line", false);

        // Cleanup: Delete Groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesDocPShConvFalse()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Run VAT Rate Change with Perform Conversion = FALSE, expect no updates.
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create data with groups to update.
        ERMVATToolHelper.CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, '', 1);
        ERMVATToolHelper.UpdateQtyToShip(SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolSales(VATRateChangeSetup2."Update Sales Documents"::Both, false, true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify that no data was updated
        ERMVATToolHelper.VerifyUpdateConvFalse(DATABASE::"Sales Line");

        // Verify log entries
        ERMVATToolHelper.VerifyLogEntriesConvFalse(DATABASE::"Sales Line", true);

        // Cleanup: Delete Groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesLineWithZeroOutstandingQty()
    var
        SalesHeader: Record "Sales Header";
        VATRateChangeSetup: Record "VAT Rate Change Setup";
        VatProdPostingGroup: Code[20];
    begin
        // Check Description field value when out standing quantity is zero on sales order.

        // Setup: Create posting groups to update and save them in VAT Change Tool Conversion table.
        Initialize();
        ERMVATToolHelper.UpdateVatRateChangeSetup(VATRateChangeSetup);
        SetupToolSales(VATRateChangeSetup."Update Sales Documents"::"VAT Prod. Posting Group", true, true);
        ERMVATToolHelper.CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, '', LibraryRandom.RandInt(5));
        VatProdPostingGroup := GetVatProdPostingGroupFromSalesLine(SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Verify Description field on vat rate change log entry.
        ERMVATToolHelper.VerifyValueOnZeroOutstandingQty(VatProdPostingGroup, DATABASE::"Sales Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolReminderVAT()
    begin
        VATToolReminderLine(VATRateChangeSetup2."Update Reminders"::"VAT Prod. Posting Group", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolReminderNo()
    begin
        asserterror VATToolReminderLine(VATRateChangeSetup2."Update Reminders"::No, 1);
        Assert.ExpectedError(ERMVATToolHelper.GetConversionErrorNoTables());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolFinChargeMemoVAT()
    begin
        VATToolFinChargeMemoLine(VATRateChangeSetup2."Update Finance Charge Memos"::"VAT Prod. Posting Group", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolFinChargeMemoNo()
    begin
        asserterror VATToolFinChargeMemoLine(VATRateChangeSetup2."Update Finance Charge Memos"::No, 1);
        Assert.ExpectedError(ERMVATToolHelper.GetConversionErrorNoTables());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolProdOrderGen()
    begin
        VATToolProductionOrder(VATRateChangeSetup2."Update Production Orders"::"Gen. Prod. Posting Group", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolProdOrderNo()
    begin
        asserterror VATToolProductionOrder(VATRateChangeSetup2."Update Production Orders"::No, 1);
        Assert.ExpectedError(ERMVATToolHelper.GetConversionErrorNoTables());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesBlanketOrderVAT()
    begin
        // Sales Blanket Order with one line, update VAT group only.
        VATToolSalesLine(VATRateChangeSetup2."Update Sales Documents"::"VAT Prod. Posting Group", false,
          SalesHeader2."Document Type"::"Blanket Order", false, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesBlanketOrderGen()
    begin
        // Sales Blanket Order with one line, update Gen. group only.
        VATToolSalesLine(VATRateChangeSetup2."Update Sales Documents"::"Gen. Prod. Posting Group", false,
          SalesHeader2."Document Type"::"Blanket Order", false, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesBlanketOrderBoth()
    begin
        // Sales Blanket Order with one line, update both groups.
        VATToolSalesLine(VATRateChangeSetup2."Update Sales Documents"::Both, false,
          SalesHeader2."Document Type"::"Blanket Order", false, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesBlanketOrderNo()
    begin
        // Sales Blanket Order with one line, don't update groups.
        asserterror VATToolSalesLine(
            VATRateChangeSetup2."Update Sales Documents"::No, false, SalesHeader2."Document Type"::"Blanket Order", false, false, false);
        Assert.ExpectedError(ERMVATToolHelper.GetConversionErrorNoTables());

        // Cleanup: Delete Groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesBlanketOrdMakeFull()
    begin
        // Sales Blanket Order with one line, Make Sales Order, update VAT group only.
        VATToolMakeSalesOrder(VATRateChangeSetup2."Update Sales Documents"::"VAT Prod. Posting Group",
          SalesHeader2."Document Type"::"Blanket Order", false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesBlanketOrdMakePart()
    begin
        // Sales Blanket Order with one line, Make Sales Order, update VAT group only.
        VATToolMakeSalesOrder(VATRateChangeSetup2."Update Sales Documents"::"VAT Prod. Posting Group",
          SalesHeader2."Document Type"::"Blanket Order", true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesBlOrdMakePartMake()
    begin
        // Sales Blanket Order with one line, Make Sales Order, update VAT group only, Make Order.
        VATToolMakeSalesOrderMake(VATRateChangeSetup2."Update Sales Documents"::"VAT Prod. Posting Group",
          SalesHeader2."Document Type"::"Blanket Order", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesBlOrdMakeOrderFShp()
    begin
        // Sales Blanket Order with one line, Make Sales Order, Fully Ship Sales Order, update VAT group only. Do not expect update.
        VATToolMakeSalesOrderSh(VATRateChangeSetup2."Update Sales Documents"::"VAT Prod. Posting Group", false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesBlOrdMakeOrderPShp()
    begin
        // Sales Blanket Order with one line, Make Sales Order, Partially Ship Sales Order, update VAT group only.
        VATToolMakeSalesOrderSh(VATRateChangeSetup2."Update Sales Documents"::"VAT Prod. Posting Group", true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesBlOrdMakeFShpPost()
    begin
        // Sales Blanket Order with one line, Make Sales Order, Partially Ship Sales Order, Post, update VAT group only.
        VATToolMakeSalesOrderShPost(VATRateChangeSetup2."Update Sales Documents"::"VAT Prod. Posting Group", false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesBlOrdMakePShpPost()
    begin
        // Sales Blanket Order with one line, Make Sales Order, Partially Ship Sales Order, Post, update VAT group only.
        VATToolMakeSalesOrderShPost(VATRateChangeSetup2."Update Sales Documents"::"VAT Prod. Posting Group", true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesBlOrdMakePShpMake()
    var
        SalesHeader: Record "Sales Header";
        SalesOrderHeader: Record "Sales Header";
    begin
        // Sales Blanket Order with one line, Partial Make Sales Order, Partially Ship Sales Order, Make.
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create Blanket Order.
        ERMVATToolHelper.CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Blanket Order", '', GetLineCount(false));

        // SETUP: Make Order (Partial).
        ERMVATToolHelper.UpdateQtyToShip(SalesHeader);
        ERMVATToolHelper.MakeOrderSales(SalesHeader, SalesOrderHeader);

        // SETUP: Post Partial Shipment.
        ERMVATToolHelper.UpdateQtyToShip(SalesOrderHeader);
        LibrarySales.PostSalesDocument(SalesOrderHeader, true, false);

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolSales(VATRateChangeSetup2."Update Sales Documents"::Both, true, true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Make Sales Order Is Completed Successfully.
        UpdateQtyBlanketOrder(SalesHeader);
        ERMVATToolHelper.MakeOrderSales(SalesHeader, SalesOrderHeader);

        // Cleanup: Delete Groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesQuoteVAT()
    begin
        // Sales Blanket Order with one line, update VAT group only.
        VATToolSalesLine(VATRateChangeSetup2."Update Sales Documents"::"VAT Prod. Posting Group", false,
          SalesHeader2."Document Type"::Quote, false, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesQuoteGen()
    begin
        // Sales Blanket Order with one line, update Gen. group only.
        VATToolSalesLine(VATRateChangeSetup2."Update Sales Documents"::"Gen. Prod. Posting Group", false,
          SalesHeader2."Document Type"::Quote, false, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesQuoteBoth()
    begin
        // Sales Blanket Order with one line, update both groups.
        VATToolSalesLine(VATRateChangeSetup2."Update Sales Documents"::Both, false,
          SalesHeader2."Document Type"::Quote, false, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesQuoteNo()
    begin
        // Sales Blanket Order with one line, don't update groups.
        asserterror VATToolSalesLine(
            VATRateChangeSetup2."Update Sales Documents"::No, false, SalesHeader2."Document Type"::Quote, false, false, false);
        Assert.ExpectedError(ERMVATToolHelper.GetConversionErrorNoTables());

        // Cleanup: Delete Groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesQuoteMakeOrd()
    begin
        // Sales Blanket Order with one line, Make Sales Order, update VAT group only.
        VATToolMakeSalesOrder(VATRateChangeSetup2."Update Sales Documents"::"VAT Prod. Posting Group",
          SalesHeader2."Document Type"::Quote, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesInvoiceVAT()
    begin
        // Sales Invoice with Multiple Lines, update VAT group only.
        VATToolSalesLine(VATRateChangeSetup2."Update Sales Documents"::"VAT Prod. Posting Group", false,
          SalesHeader2."Document Type"::Invoice, false, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesInvoiceVATAmount()
    begin
        // Sales Invoice with Multiple Lines, Update VAT Group, Verify Amount.
        VATToolSalesLineAmount(SalesHeader2."Document Type"::Invoice, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesOrderVAT()
    begin
        // Sales Order with one line, update VAT group only.
        VATToolSalesLine(
          VATRateChangeSetup2."Update Sales Documents"::"VAT Prod. Posting Group", false, SalesHeader2."Document Type"::Order, false,
          false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesOrderVATAmount()
    begin
        // Sales Order with Multiple Lines, Update VAT Group, Verify Amount.
        VATToolSalesLineAmount(SalesHeader2."Document Type"::Order, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesOrderGen()
    begin
        // Sales Order with one line, update Gen. group only.
        VATToolSalesLine(
          VATRateChangeSetup2."Update Sales Documents"::"Gen. Prod. Posting Group", false, SalesHeader2."Document Type"::Order, false,
          false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesOrderBoth()
    begin
        // Sales Order with one line, update both groups.
        VATToolSalesLine(VATRateChangeSetup2."Update Sales Documents"::Both, false, SalesHeader2."Document Type"::Order, false, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesOrderNo()
    begin
        // Sales Order with one line, don't update groups.
        asserterror VATToolSalesLine(
            VATRateChangeSetup2."Update Sales Documents"::No, false, SalesHeader2."Document Type"::Order, false, false, false);
        Assert.ExpectedError(ERMVATToolHelper.GetConversionErrorNoTables());

        // Cleanup: Delete Groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesOrderMultipleLines()
    begin
        // Sales Order with multiple lines, update both groups.
        VATToolSalesLine(VATRateChangeSetup2."Update Sales Documents"::Both, false, SalesHeader2."Document Type"::Order, false, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesOrderMultipleLinesUpdateFirst()
    begin
        VATToolSalesOrderMultipleLinesSplit(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesOrderMultipleLinesUpdateSecond()
    begin
        VATToolSalesOrderMultipleLinesSplit(false);
    end;

    local procedure VATToolSalesOrderMultipleLinesSplit(First: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GenProdPostingGroup: Code[20];
        VATProdPostingGroup: Code[20];
        LineCount: Integer;
    begin
        // Sales Order with multiple lines, update one line only.
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Update VAT Change Tool Setup table and get new VAT group Code
        SetupToolSales(VATRateChangeSetup2."Update Sales Documents"::"VAT Prod. Posting Group", true, true);
        ERMVATToolHelper.GetGroupsAfter(VATProdPostingGroup, GenProdPostingGroup, DATABASE::"Sales Line");

        // SETUP: Create a Sales Order with 2 lines and Save data to update in a temporary table.
        ERMVATToolHelper.CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, '', 2);

        // SETUP: Change VAT Prod. Posting Group to new on one of the lines.
        GetSalesLine(SalesHeader, SalesLine);
        LineCount := SalesLine.Count();
        if First then
            SalesLine.Next()
        else
            SalesLine.FindFirst();
        SalesLine.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        SalesLine.Modify(true);

        // SETUP: Ship (Partially).
        ERMVATToolHelper.UpdateQtyToShip(SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        GetSalesLine(SalesHeader, SalesLine);
        Assert.AreEqual(LineCount + 1, SalesLine.Count, ERMVATToolHelper.GetConversionErrorSplitLines());

        // Cleanup: Delete Groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesOrdPartShpVAT()
    begin
        // Sales Order with one partially shipped and released line, update VAT group and ignore header status.
        VATToolSalesLinePartShip(VATRateChangeSetup2."Update Sales Documents"::"VAT Prod. Posting Group",
          SalesHeader2."Document Type"::Order, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesOrdPartShpVATAmt()
    begin
        // Sales Order with one partially shipped and released line, update VAT group and ignore header status. Verify Amount.
        VATToolSalesLineAmount(SalesHeader2."Document Type"::Order, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesOrdPartShpGen()
    begin
        // Sales Order with one partially shipped and released line, update Gen group and ignore header status.
        VATToolSalesLinePartShip(VATRateChangeSetup2."Update Sales Documents"::"Gen. Prod. Posting Group",
          SalesHeader2."Document Type"::Order, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesOrdPartShpBoth()
    begin
        // Sales Order with one partially shipped and released line, update both groups and ignore header status.
        VATToolSalesLinePartShip(VATRateChangeSetup2."Update Sales Documents"::Both,
          SalesHeader2."Document Type"::Order, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesOrdPartShpBothMultipleLines()
    begin
        // Sales Order with multiple partially shipped and released lines, update both groups and ignore header status.
        VATToolSalesLinePartShip(VATRateChangeSetup2."Update Sales Documents"::Both,
          SalesHeader2."Document Type"::Order, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalOrdPShpAutoInsSetup()
    begin
        // Sales Order with one partially shipped and released line, update both groups and ignore header status.
        VATToolSalesLinePartShip(VATRateChangeSetup2."Update Sales Documents"::Both,
          SalesHeader2."Document Type"::Order, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSaRetOrdPartShpBoth()
    begin
        // Sales Return Order with one partially shipped and released line, update both groups and ignore header status.
        // No update expected.
        VATToolSalesLinePartShip(VATRateChangeSetup2."Update Sales Documents"::Both,
          SalesHeader2."Document Type"::"Return Order", false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesOrderFullyShip()
    begin
        // Sales Order with one fully shipped line, update both groups and ignore header status. No update expected.
        // Since the line is shipped, it is by default also released (it is important for ignore status option).
        VATToolSalesLine(VATRateChangeSetup2."Update Sales Documents"::Both, true,
          SalesHeader2."Document Type"::Order, true, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesOrderReleasedIgn()
    begin
        // Sales Order with one released line, update both groups and ignore header status.
        VATToolSalesLine(VATRateChangeSetup2."Update Sales Documents"::Both, true,
          SalesHeader2."Document Type"::Order, true, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesOrderReleasedNoIgn()
    begin
        // Sales Order with one released line, update both groups and don't ignore header status. No update expected.
        VATToolSalesLine(VATRateChangeSetup2."Update Sales Documents"::Both, false,
          SalesHeader2."Document Type"::Order, true, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesCreditMemo()
    begin
        // Sales Credit Memo with one line, update both groups. Do not expect update.
        VATToolSalesLine(VATRateChangeSetup2."Update Sales Documents"::Both, false,
          SalesHeader2."Document Type"::"Credit Memo", false, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesInvoiceForShipment()
    var
        TempRecRef: RecordRef;
    begin
        // Sales Invoice with one line, related to a Shipment Line, update both groups. No update expected.
        Initialize();

        // Setup
        // Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // Create and Save data to update in a temporary table.
        PrepareSalesInvoiceForShipment(TempRecRef);

        // Update VAT Change Tool Setup table.
        SetupToolSales(VATRateChangeSetup2."Update Sales Documents"::Both, true, false);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Log Data
        ERMVATToolHelper.VerifyUpdate(TempRecRef, false);

        // Verify: Log Entries
        ERMVATToolHelper.VerifyErrorLogEntries(TempRecRef, false);

        // Cleanup: Delete Groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesOrderWhse()
    begin
        // Sales Order with one line with warehouse integration, update both groups. Expect update.
        VATToolSalesLineWhse(VATRateChangeSetup2."Update Sales Documents"::Both, 1, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesOrderWhsePartShip()
    begin
        // Sales Order with one partially shipped line with warehouse integration, update both groups. No update expected.
        VATToolSalesLineWhse(VATRateChangeSetup2."Update Sales Documents"::Both, 1, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesOrderReserve()
    begin
        // Sales Order with one partially shipped line with reservation, update both groups. Update of reservation line expected.
        VATToolSalesLineReserve(VATRateChangeSetup2."Update Sales Documents"::Both, false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure VATToolSalesOrderItemTracking()
    begin
        // Sales Order with one line with Item Tracking with Serial No., update both groups.
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and save data to update in a temporary table.
        PrepareSalesDocItemTracking();

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolSales(VATRateChangeSetup2."Update Sales Documents"::Both, true, true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        VerifySalesDocWithReservation(true);

        // Cleanup: Delete Groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesOrderItemCharge()
    begin
        // Sales Order with one line with Charge (Item), update both groups.
        VATToolSalesOrderItemChrgDiffDoc(false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesOrderItemChrgPShip()
    begin
        // Sales Order with one line with Charge (Item), partially shipped, update both groups. No update of Item Charge Assignment (Sales)
        // expected.
        VATToolSalesOrderItemChrgDiffDoc(true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesOrderItemChrgPInvoiced()
    begin
        // Sales Order with one line with Charge (Item), partially shipped, update both groups. No update of Item Charge Assignment (Sales)
        // expected.
        VATToolSalesOrderItemChrgDiffDoc(true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesOrderItemChargeSameDoc()
    begin
        // Sales Order with one line with Charge (Item), update both groups.
        VATToolSalesOrderItemChrgSameDoc(false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesOrderItemChrgPShipSameDoc()
    begin
        // Sales Order with one line with Charge (Item), partially shipped, update both groups. No update of Item Charge Assignment (Sales)
        // expected.
        VATToolSalesOrderItemChrgSameDoc(true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesOrderItemChrgPInvoicedSameDoc()
    begin
        // Sales Order with one line with Charge (Item), partially shipped, update both groups. No update of Item Charge Assignment (Sales)
        // expected.
        VATToolSalesOrderItemChrgSameDoc(true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesOrderDimensions()
    var
        SalesHeader: Record "Sales Header";
        TempRecRef: RecordRef;
    begin
        // Sales Order with one partially shipped line with Dimensions assigned, update both groups.
        // Verify that dimensions are copied to the new line.
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and save data to update in a temporary table.
        ERMVATToolHelper.CreateSalesDocumentWithRef(SalesHeader, TempRecRef, SalesHeader."Document Type"::Order, '', 1);

        // SETUP: Add Dimensions to the Sales Lines and save them in a temporary table
        AddDimensionsForSalesLines(SalesHeader);

        // SETUP: Ship (Partially).
        ERMVATToolHelper.UpdateQtyToShip(SalesHeader);
        ERMVATToolHelper.CreateLinesRefSales(TempRecRef, SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolSales(VATRateChangeSetup2."Update Sales Documents"::Both, true, true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        VerifySalesLnPartShipped(TempRecRef);

        // Cleanup: Delete Groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesOrderPrepayment()
    var
        SalesHeader: Record "Sales Header";
        TempRecRef: RecordRef;
    begin
        // Sales Order with prepayment, update both groups. No update expected.
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and Save data to update in a temporary table.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, ERMVATToolHelper.CreateCustomer());
        SalesHeader.Validate("Prices Including VAT", true);
        ERMVATToolHelper.CreateSalesLines(SalesHeader, '', GetLineCount(false));
        TempRecRef.Open(DATABASE::"Sales Line", true);
        ERMVATToolHelper.CreateLinesRefSales(TempRecRef, SalesHeader);

        // SETUP: Post prepayment.
        PostSalesPrepayment(SalesHeader);

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolSales(VATRateChangeSetup2."Update Sales Documents"::Both, true, true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        ERMVATToolHelper.VerifyUpdate(TempRecRef, false);

        // Verify: Log Entries
        ERMVATToolHelper.VerifyErrorLogEntries(TempRecRef, true);

        // Cleanup: Delete Groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesOrderWithNegativeQty()
    begin
        VATToolSalesLineWithNegativeQty(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesOrderWithNegativeQtyShip()
    begin
        VATToolSalesLineWithNegativeQty(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSalesOrderNoSpaceForNewLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LineCount: Integer;
    begin
        // Sales Order with two lines, first partially shipped, no line number available between them. Update both groups.
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and Save data to update in a temporary table.
        ERMVATToolHelper.CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, '', 1);
        AddLineWithNextLineNo(SalesHeader);
        GetSalesLine(SalesHeader, SalesLine);
        LineCount := SalesLine.Count();

        // SETUP: Ship
        ERMVATToolHelper.UpdateQtyToShip(SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolSales(VATRateChangeSetup2."Update Sales Documents"::Both, true, true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check that each line was splitted.
        GetSalesLine(SalesHeader, SalesLine);
        Assert.AreEqual(LineCount * 2, SalesLine.Count, ERMVATToolHelper.GetConversionErrorSplitLines());

        // Cleanup: Delete Groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolDropShipmentBoth()
    begin
        // Sales Order and Purchase Order with one line, defined as drop shipment, update both groups. No update expected.
        VATToolDropShipment(VATRateChangeSetup2."Update Sales Documents"::Both,
          VATRateChangeSetup2."Update Purchase Documents"::Both);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSpecialOrderBoth()
    begin
        // Sales Order and Purchase Order with one line, defined as special order, update both groups. No update expected.
        VATToolSpecialOrder(VATRateChangeSetup2."Update Sales Documents"::Both,
          VATRateChangeSetup2."Update Sales Documents"::Both);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitPriceUpdateForGLAccLineWhenPricesIncludingVATEnabled()
    var
        SalesLine: Record "Sales Line";
        ExpectedUnitPrice: Decimal;
    begin
        // [FEATURE] [Prices Including VAT]
        // [SCENARIO 361066] A unit price of sales line with "Prices Including VAT" and type "G/L Account" updates on "VAT Product Posting Group" change
        // [SCENARIO 361066] if "Update Unit Price For G/L Acc." is enabled in VAT Rate Change Setup

        Initialize();

        ERMVATToolHelper.CreatePostingGroups(false);
        ERMVATToolHelper.UpdateUnitPricesInclVATSetup(true, false, false);
        SetupToolSales(VATRateChangeSetup2."Update Sales Documents"::"VAT Prod. Posting Group", true, true);
        CreateSalesInvoiceWithPricesIncludingVAT(SalesLine, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup());

        ERMVATToolHelper.RunVATRateChangeTool();

        ExpectedUnitPrice := CalcChangedUnitPriceGivenDiffVATPostingSetup(SalesLine);
        SalesLine.Find();
        SalesLine.TestField("Unit Price", ExpectedUnitPrice);

        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitPriceDoesNotUpdateForGLAccLineWhenPricesIncludingVATEnabled()
    var
        SalesLine: Record "Sales Line";
        ExpectedUnitPrice: Decimal;
    begin
        // [FEATURE] [Prices Including VAT]
        // [SCENARIO 361066] A unit price of sales line with "Prices Including VAT" and type "G/L Account" does not update on "VAT Product Posting Group" change
        // [SCENARIO 361066] if "Update Unit Price For G/L Acc." is disabled in VAT Rate Change Setup

        Initialize();

        ERMVATToolHelper.CreatePostingGroups(false);
        ERMVATToolHelper.UpdateUnitPricesInclVATSetup(false, false, false);
        SetupToolSales(VATRateChangeSetup2."Update Sales Documents"::"VAT Prod. Posting Group", true, true);
        CreateSalesInvoiceWithPricesIncludingVAT(SalesLine, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup());

        ERMVATToolHelper.RunVATRateChangeTool();

        ExpectedUnitPrice := SalesLine."Unit Price";
        SalesLine.Find();
        SalesLine.TestField("Unit Price", ExpectedUnitPrice);

        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitPriceUpdateForItemChargeLineWhenPricesIncludingVATEnabled()
    var
        SalesLine: Record "Sales Line";
        ExpectedUnitPrice: Decimal;
    begin
        // [FEATURE] [Prices Including VAT]
        // [SCENARIO 361066] A unit price of sales line with "Prices Including VAT" and type "Charge (Item)" updates on "VAT Product Posting Group" change
        // [SCENARIO 361066] if "Update Unit Price For G/L Acc." is enabled in VAT Rate Change Setup

        Initialize();

        ERMVATToolHelper.CreatePostingGroups(false);
        ERMVATToolHelper.UpdateUnitPricesInclVATSetup(false, true, false);
        SetupToolSales(VATRateChangeSetup2."Update Sales Documents"::"VAT Prod. Posting Group", true, true);
        CreateSalesInvoiceWithPricesIncludingVAT(SalesLine, SalesLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo());

        ERMVATToolHelper.RunVATRateChangeTool();

        ExpectedUnitPrice := CalcChangedUnitPriceGivenDiffVATPostingSetup(SalesLine);
        SalesLine.Find();
        SalesLine.TestField("Unit Price", ExpectedUnitPrice);

        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitPriceDoesNotUpdateForItemChargeLineWhenPricesIncludingVATEnabled()
    var
        SalesLine: Record "Sales Line";
        ExpectedUnitPrice: Decimal;
    begin
        // [FEATURE] [Prices Including VAT]
        // [SCENARIO 361066] A unit price of sales line with "Prices Including VAT" and type "Charge (Item)" does not update on "VAT Product Posting Group" change
        // [SCENARIO 361066] if "Update Unit Price For G/L Acc." is disabled in VAT Rate Change Setup

        Initialize();

        ERMVATToolHelper.CreatePostingGroups(false);
        ERMVATToolHelper.UpdateUnitPricesInclVATSetup(false, false, false);
        SetupToolSales(VATRateChangeSetup2."Update Sales Documents"::"VAT Prod. Posting Group", true, true);
        CreateSalesInvoiceWithPricesIncludingVAT(SalesLine, SalesLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo());

        ERMVATToolHelper.RunVATRateChangeTool();

        ExpectedUnitPrice := SalesLine."Unit Price";
        SalesLine.Find();
        SalesLine.TestField("Unit Price", ExpectedUnitPrice);

        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitPriceUpdateForFixedAssetLineWhenPricesIncludingVATEnabled()
    var
        FixedAsset: Record "Fixed Asset";
        SalesLine: Record "Sales Line";
        ExpectedUnitPrice: Decimal;
    begin
        // [FEATURE] [Prices Including VAT]  [Fixed Asset]
        // [SCENARIO 361066] A unit price of sales line with "Prices Including VAT" and type "Fixed Asset" updates on "VAT Product Posting Group" change
        // [SCENARIO 361066] if "Update Unit Price For G/L Acc." is enabled in VAT Rate Change Setup

        Initialize();

        ERMVATToolHelper.CreatePostingGroups(false);
        ERMVATToolHelper.UpdateUnitPricesInclVATSetup(false, false, true);
        SetupToolSales(VATRateChangeSetup2."Update Sales Documents"::"VAT Prod. Posting Group", true, true);
        LibraryFixedAsset.CreateFixedAssetWithSetup(FixedAsset);
        CreateSalesInvoiceWithPricesIncludingVAT(SalesLine, SalesLine.Type::"Fixed Asset", FixedAsset."No.");

        ERMVATToolHelper.RunVATRateChangeTool();

        ExpectedUnitPrice := CalcChangedUnitPriceGivenDiffVATPostingSetup(SalesLine);
        SalesLine.Find();
        SalesLine.TestField("Unit Price", ExpectedUnitPrice);

        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitPriceDoesNotUpdateForFixedAssetLineWhenPricesIncludingVATEnabled()
    var
        FixedAsset: Record "Fixed Asset";
        SalesLine: Record "Sales Line";
        ExpectedUnitPrice: Decimal;
    begin
        // [FEATURE] [Prices Including VAT]  [Fixed Asset]
        // [SCENARIO 361066] A unit price of sales line with "Prices Including VAT" and type "Fixed Asset" does not update on "VAT Product Posting Group" change
        // [SCENARIO 361066] if "Update Unit Price For G/L Acc." is disabled in VAT Rate Change Setup

        Initialize();

        ERMVATToolHelper.CreatePostingGroups(false);
        ERMVATToolHelper.UpdateUnitPricesInclVATSetup(false, false, false);
        SetupToolSales(VATRateChangeSetup2."Update Sales Documents"::"VAT Prod. Posting Group", true, true);
        LibraryFixedAsset.CreateFixedAssetWithSetup(FixedAsset);
        CreateSalesInvoiceWithPricesIncludingVAT(SalesLine, SalesLine.Type::"Fixed Asset", FixedAsset."No.");

        ERMVATToolHelper.RunVATRateChangeTool();

        ExpectedUnitPrice := SalesLine."Unit Price";
        SalesLine.Find();
        SalesLine.TestField("Unit Price", ExpectedUnitPrice);

        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConvertPartiallyReceivedOrderWithBlankQtyToReceive()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempRecRef: RecordRef;
    begin
        // [SCENARIO 362310] Stan can convert a VAT group of the Sales Order that was partially received and "Default Quantity to Shup" is enabled in the Sales & Receivables setup

        Initialize();
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Default Quantity to Ship", SalesReceivablesSetup."Default Quantity to Ship"::Blank);
        SalesReceivablesSetup.Modify(true);

        ERMVATToolHelper.CreatePostingGroups(false);

        ERMVATToolHelper.CreateSalesDocumentWithRef(SalesHeader, TempRecRef, SalesHeader."Document Type"::Order, '', 1);
        ERMVATToolHelper.UpdateQtyToShip(SalesHeader);
        ERMVATToolHelper.CreateLinesRefSales(TempRecRef, SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        ERMVATToolHelper.UpdateQtyToShip(SalesHeader);
        SetupToolSales(VATRateChangeSetup2."Update Sales Documents"::"VAT Prod. Posting Group", true, true);
        GetSalesLine(SalesHeader, SalesLine);

        ERMVATToolHelper.RunVATRateChangeTool();

        VerifyLineConverted(SalesHeader, SalesLine."Quantity Shipped", SalesLine.Quantity - SalesLine."Quantity Shipped");
        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure ConvertSalesLineWithItemTrackingAfterPlanningRun()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Planning] [Item Tracking]
        // [SCENARIO 368056] VAT Change Tool updates sales line with item tracking and reservation entries generated by the planning engine.
        Initialize();

        // [GIVEN] Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // [GIVEN] Create serial no.-tracked item and post inventory.
        // [GIVEN] Create sales order for the item.
        // [GIVEN] Partially ship the sales order.
        PrepareSalesDocItemTracking();

        // [GIVEN] Set reordering policy for the item and run planning.
        UpdateItemOnSalesLine(Item);
        LibraryPlanning.CalcRequisitionPlanForReqWksh(Item, WorkDate(), WorkDate());

        // [GIVEN] Update VAT Change Tool Setup table.
        SetupToolSales(VATRateChangeSetup2."Update Sales Documents"::Both, true, true);

        // [WHEN] Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // [THEN] Check that the posting group have been updated.
        VerifySalesDocWithReservation(true);

        // Tear down.
        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentVATFieldsUpdate()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GenProdPostingGroupCode: Code[20];
        VATProductPostingGroupCode: Code[20];
    begin
        // [FEATURE] [Prepayment]
        // [SCENARIO 364192] Prepayment VAT fields are updated during the conversion

        Initialize();

        // [GIVEN] Setup two general posting setup "A" and "B". Each of this general posting setup has the Prepayment Account with the VAT Posting Setup, either "X" or "Z"
        ERMVATToolHelper.CreatePostingGroupsPrepmtVAT(false);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, ERMVATToolHelper.CreateCustomer());
        SalesHeader.Validate("Prepayment %", LibraryRandom.RandIntInRange(5, 10));
        SalesHeader.Modify(true);
        ERMVATToolHelper.CreateSalesLines(SalesHeader, '', 1);

        // [GIVEN] Setup conversion from "A" to "B" and from "X" to "Z"
        SetupToolSales(VATRateChangeSetup2."Update Sales Documents"::Both, true, true);
        GetSalesLine(SalesHeader, SalesLine);

        // [WHEN] Run VAT Rate Change Tool
        ERMVATToolHelper.RunVATRateChangeTool();

        // [THEN] Prepayment VAT % and "Prepayment VAT Identifier" matches the "Z" VAT Posting Setup
        SalesLine.Find();
        ERMVATToolHelper.GetGroupsAfter(VATProductPostingGroupCode, GenProdPostingGroupCode, DATABASE::"Sales Line");
        VATPostingSetup.Get(SalesHeader."VAT Bus. Posting Group", VATProductPostingGroupCode);
        SalesLine.TestField("Prepayment VAT %", VATPostingSetup."VAT %");
        SalesLine.TestField("Prepayment VAT Identifier", VATPostingSetup."VAT Identifier");

        // Tear down
        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolAdjustExtTextsAttachedToLineNo()
    var
        VATProdPostingGroup: array[2] of Record "VAT Product Posting Group";
        VATBusPostingGroup: Record "VAT Business Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesOrderHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrderLine: Record "Sales Line";
        VATRateChangeConv: Record "VAT Rate Change Conversion";
        BlanketSalesOrderPage: TestPage "Blanket Sales Order";
        SalesDocumentType: Enum "Sales Document Type";
        SalesLineType: Enum "Sales Line Type";
        SalesOrderDocNo: Code[20];
        CustomerNo: Code[20];
        SecondSalesLineNo: Integer;
    begin
        // [FEATURE] [Extended Text]
        // [SCENARIO 377264] VAT Rate Change tool adjusts Extended Text line "Attached to Line No." field
        Initialize();

        // [GIVEN] VAT Prod. Posting Group 'VPPG1' and 'VPPG2'
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup[1]);
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup[2]);
        LibraryERM.CreateVATBusinessPostingGroup(VATBusPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup.Code, VATProdPostingGroup[1].Code);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup.Code, VATProdPostingGroup[2].Code);

        CustomerNo := LibrarySales.CreateCustomerWithVATBusPostingGroup(VATBusPostingGroup.Code);

        // [GIVEN] Item with VAT Prod. Posting Group = 'VPPG1' and enabled Automatic Ext. Texts with one line Ext. Text
        LibraryInventory.CreateItem(Item);
        Item.VALIDATE("VAT Prod. Posting Group", VATProdPostingGroup[1].Code);
        Item.Validate("Automatic Ext. Texts", true);
        Item.Modify(true);
        LibraryInventory.CreateExtendedTextForItem(Item."No.");

        // [GIVEN] Blanket Sales Order with line of type Item, Qty = 10 and one Ext. Text line
        // VAT Prod. Posting Group of Sales Line = 'VPPG1'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesDocumentType::"Blanket Order", CustomerNo);
        BlanketSalesOrderPage.OpenEdit();
        BlanketSalesOrderPage.Filter.SetFilter("No.", SalesHeader."No.");
        BlanketSalesOrderPage.SalesLines.Type.SetValue(SalesLineType::Item);
        BlanketSalesOrderPage.SalesLines."No.".SetValue(Item."No.");
        BlanketSalesOrderPage.SalesLines.Quantity.SetValue(10);
        BlanketSalesOrderPage.Close();
        Commit();

        // [GIVEN] Sales Order made out of Sales Blanket Order
        SalesOrderDocNo := LibrarySales.BlanketSalesOrderMakeOrder(SalesHeader);

        SalesOrderHeader.GET(SalesDocumentType::Order, SalesOrderDocNo);
        LibrarySales.FindFirstSalesLine(SalesOrderLine, SalesOrderHeader);

        // [GIVEN] Sales Order posted with Quanitity = 8.
        SalesOrderLine.Validate(Quantity, 8);
        SalesOrderLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesOrderHeader, true, true);

        // [WHEN] Run VAT Change Tool with option to convert 'VPPG1' into 'VPPG2' for Sales documents
        ERMVATToolHelper.SetupToolConvGroups(
            VATRateChangeConv.Type::"VAT Prod. Posting Group", VATProdPostingGroup[1].Code, VATProdPostingGroup[2].Code);
        SetupToolSales(VATRateChangeSetup2."Update Sales Documents"::"VAT Prod. Posting Group", true, false);
        ERMVATToolHelper.RunVATRateChangeTool();

        // [THEN] Blanket Sales Order has 3 lines. Extended text line is attached to Sales Line with 'VPPG2' VAT Posting Group
        LibrarySales.FindFirstSalesLine(SalesLine, SalesHeader);
        SalesLine.TestField(Quantity, 8);
        SalesLine.TestField("VAT Prod. Posting Group", VATProdPostingGroup[1].Code);
        SalesLine.Next();
        SalesLine.TestField(Quantity, 2);
        SalesLine.TestField("VAT Prod. Posting Group", VATProdPostingGroup[2].Code);
        SecondSalesLineNo := SalesLine."Line No.";

        SalesLine.Next();
        SalesLine.TestField("Attached to Line No.", SecondSalesLineNo);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    procedure BlanketOrderAndOrderWithShipment()
    var
        VATProdPostingGroup: array[2] of Record "VAT Product Posting Group";
        VATBusPostingGroup: Record "VAT Business Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        Item: Record Item;
        SalesHeaderBlanketOrder: Record "Sales Header";
        SalesHeaderOrder: Record "Sales Header";
        SalesLineBlanketOrder: Record "Sales Line";
        SalesLineOrder: Record "Sales Line";
        VATRateChangeConv: Record "VAT Rate Change Conversion";
        SalesOrderDocNo: Code[20];
        CustomerNo: Code[20];
        BlanketOrderQuantity: Decimal;
    begin
        // [FEATURE] [Blanket Order] [Order] [Partial Shipment] [Shipment]
        // [SCENARIO 385191] Partially or fully shipped line in a Sales Order created from a Blanket Order does not change reference to a source Blanket Order's line after running the VAT Rate Change Tool
        Initialize();

        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup[1]);
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup[2]);
        LibraryERM.CreateVATBusinessPostingGroup(VATBusPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup.Code, VATProdPostingGroup[1].Code);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup.Code, VATProdPostingGroup[2].Code);

        CustomerNo := LibrarySales.CreateCustomerWithVATBusPostingGroup(VATBusPostingGroup.Code);

        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup[1].Code);
        Item.Modify(true);

        BlanketOrderQuantity := LibraryRandom.RandIntInRange(10, 20) * 3;

        LibrarySales.CreateSalesHeader(SalesHeaderBlanketOrder, SalesHeaderBlanketOrder."Document Type"::"Blanket Order", CustomerNo);
        LibrarySales.CreateSalesLine(
            SalesLineBlanketOrder, SalesHeaderBlanketOrder,
            SalesLineBlanketOrder.Type::Item, Item."No.", BlanketOrderQuantity);
        SalesLineBlanketOrder.Validate("Qty. to Ship", Round(BlanketOrderQuantity / 3));
        SalesLineBlanketOrder.Modify(true);

        SalesOrderDocNo := LibrarySales.BlanketSalesOrderMakeOrder(SalesHeaderBlanketOrder);

        SalesHeaderOrder.Get(SalesHeaderOrder."Document Type"::Order, SalesOrderDocNo);
        LibrarySales.FindFirstSalesLine(SalesLineOrder, SalesHeaderOrder);
        SalesLineOrder.Validate("Qty. to Invoice", 0);
        SalesLineOrder.Modify(true);

        LibrarySales.PostSalesDocument(SalesHeaderOrder, true, false);

        ERMVATToolHelper.SetupToolConvGroups(
            VATRateChangeConv.Type::"VAT Prod. Posting Group", VATProdPostingGroup[1].Code, VATProdPostingGroup[2].Code);
        SetupToolSales(VATRateChangeSetup2."Update Sales Documents"::"VAT Prod. Posting Group", true, false);
        ERMVATToolHelper.RunVATRateChangeTool();

        SalesLineOrder.Reset();
        SalesLineOrder.SetRange("Document Type", SalesHeaderOrder."Document Type");
        SalesLineOrder.SetRange("Document No.", SalesHeaderOrder."No.");
        Assert.RecordCount(SalesLineOrder, 1);

        SalesLineOrder.FindFirst();
        SalesLineOrder.TestField("VAT Prod. Posting Group", VATProdPostingGroup[1].Code);
        SalesLineOrder.TestField("Blanket Order No.", SalesHeaderBlanketOrder."No.");
        SalesLineOrder.TestField("Blanket Order Line No.", SalesLineBlanketOrder."Line No.");

        SalesLineBlanketOrder.SetRange("Document Type", SalesHeaderBlanketOrder."Document Type");
        SalesLineBlanketOrder.SetRange("Document No.", SalesHeaderBlanketOrder."No.");
        Assert.RecordCount(SalesLineBlanketOrder, 2);

        SalesLineBlanketOrder.FindFirst();
        VerifyQuantitiesOnSalesLine(
            SalesLineBlanketOrder, Round(BlanketOrderQuantity / 3),
            Round(BlanketOrderQuantity / 3), 0, 0, Round(BlanketOrderQuantity / 3),
            VATProdPostingGroup[1].Code);

        SalesLineBlanketOrder.Next();
        VerifyQuantitiesOnSalesLine(
            SalesLineBlanketOrder, Round(BlanketOrderQuantity * 2 / 3),
            Round(BlanketOrderQuantity * 2 / 3), 0, Round(BlanketOrderQuantity * 2 / 3), 0,
            VATProdPostingGroup[2].Code);

        SalesLineOrder.Validate("Qty. to Invoice", SalesLineOrder.Quantity);
        SalesLineOrder.Modify(true);

        LibrarySales.PostSalesDocument(SalesHeaderOrder, true, true);

        SalesLineBlanketOrder.FindFirst();
        VerifyQuantitiesOnSalesLine(
            SalesLineBlanketOrder, Round(BlanketOrderQuantity / 3),
            0, Round(BlanketOrderQuantity / 3), 0, Round(BlanketOrderQuantity / 3),
            VATProdPostingGroup[1].Code);

        SalesLineBlanketOrder.Next();
        VerifyQuantitiesOnSalesLine(
            SalesLineBlanketOrder, Round(BlanketOrderQuantity * 2 / 3),
            Round(BlanketOrderQuantity * 2 / 3), 0, Round(BlanketOrderQuantity * 2 / 3), 0,
            VATProdPostingGroup[2].Code);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    local procedure VATToolReminderLine(FieldOption: Option; "Count": Integer)
    var
        TempRecRef: RecordRef;
    begin
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and save data to update in a temporary table.
        CreateReminderLines(TempRecRef, Count);

        // SETUP: Update VAT Change Tool Setup table.
        ERMVATToolHelper.SetupToolOption(VATRateChangeSetup2.FieldNo("Update Reminders"), FieldOption);
        ERMVATToolHelper.SetupToolCheckbox(VATRateChangeSetup2.FieldNo("Perform Conversion"), true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        ERMVATToolHelper.VerifyUpdate(TempRecRef, true);

        // Verify: Log Entries
        ERMVATToolHelper.VerifyLogEntries(TempRecRef);

        // Tear Down
        ERMVATToolHelper.DeleteRecords(TempRecRef.Number);
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure VATToolFinChargeMemoLine(FieldOption: Option; "Count": Integer)
    var
        TempRecRef: RecordRef;
    begin
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and save data to update in a temporary table.
        CreateFinChargeMemoLines(TempRecRef, Count);

        // SETUP: Update VAT Change Tool Setup table.
        ERMVATToolHelper.SetupToolOption(VATRateChangeSetup2.FieldNo("Update Finance Charge Memos"), FieldOption);
        ERMVATToolHelper.SetupToolCheckbox(VATRateChangeSetup2.FieldNo("Perform Conversion"), true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        ERMVATToolHelper.VerifyUpdate(TempRecRef, true);

        // Verify: Log Entries
        ERMVATToolHelper.VerifyLogEntries(TempRecRef);

        // Tear Down
        ERMVATToolHelper.DeleteRecords(TempRecRef.Number);
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure VATToolProductionOrder(FieldOption: Option; "Count": Integer)
    var
        TempRecRef: RecordRef;
    begin
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and save data to update in a temporary table.
        CreateProductionOrders(TempRecRef, Count);

        // SETUP: Update VAT Change Tool Setup table.
        ERMVATToolHelper.SetupToolOption(VATRateChangeSetup2.FieldNo("Update Production Orders"), FieldOption);
        ERMVATToolHelper.SetupToolCheckbox(VATRateChangeSetup2.FieldNo("Perform Conversion"), true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        ERMVATToolHelper.VerifyUpdate(TempRecRef, true);

        // Verify: Log Entries
        ERMVATToolHelper.VerifyLogEntries(TempRecRef);

        // Tear Down
        ERMVATToolHelper.DeleteRecords(TempRecRef.Number);
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure VATToolMakeSalesOrder(FieldOption: Option; DocumentType: Enum "Sales Document Type"; Partial: Boolean; MultipleLines: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesOrderHeader: Record "Sales Header";
        TempRecRef: RecordRef;
    begin
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and Save data to update in a temporary table.
        ERMVATToolHelper.CreateSalesDocumentWithRef(SalesHeader, TempRecRef, DocumentType, '', GetLineCount(MultipleLines));

        // SETUP: Update Qty. To Ship
        if Partial then
            ERMVATToolHelper.UpdateQtyToShip(SalesHeader);

        // SETUP: Make Order and Create Reference Lines.
        ERMVATToolHelper.MakeOrderSales(SalesHeader, SalesOrderHeader);
        if DocumentType = SalesHeader."Document Type"::"Blanket Order" then
            ERMVATToolHelper.CreateLinesRefSales(TempRecRef, SalesHeader) // Update Reference after Make
        else
            TempRecRef.DeleteAll(false); // Quote Deleted after Make
        ERMVATToolHelper.CreateLinesRefSales(TempRecRef, SalesOrderHeader);

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolSales(FieldOption, true, true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Blanket Order & Sales Order.
        ERMVATToolHelper.VerifyUpdate(TempRecRef, true);

        // Verify: Log Entries
        ERMVATToolHelper.VerifyLogEntries(TempRecRef);

        // Cleanup: Delete Groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure VATToolMakeSalesOrderMake(FieldOption: Option; DocumentType: Enum "Sales Document Type"; MultipleLines: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesOrderHeader: Record "Sales Header";
        TempRecRef: RecordRef;
    begin
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and Save data to update in a temporary table.
        ERMVATToolHelper.CreateSalesDocumentWithRef(SalesHeader, TempRecRef, DocumentType, '', GetLineCount(MultipleLines));

        // SETUP: Update Qty. To Ship
        ERMVATToolHelper.UpdateQtyToShip(SalesHeader);

        // SETUP: Make Order
        ERMVATToolHelper.MakeOrderSales(SalesHeader, SalesOrderHeader);

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolSales(FieldOption, true, true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Make Order is Successful
        SalesHeader.Find();
        // update Qty. to Ship
        ERMVATToolHelper.UpdateQtyToShip(SalesHeader);

        ERMVATToolHelper.MakeOrderSales(SalesHeader, SalesOrderHeader);

        // Cleanup: Delete Groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure VATToolMakeSalesOrderSh(FieldOption: Option; Partial: Boolean; MultipleLines: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesOrderHeader: Record "Sales Header";
        TempRecRef: RecordRef;
    begin
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and Save data to update in a temporary table.
        ERMVATToolHelper.CreateSalesDocumentWithRef(SalesHeader, TempRecRef, SalesHeader."Document Type"::"Blanket Order", '',
          GetLineCount(MultipleLines));

        // SETUP: Make Order and Create Reference Lines.
        ERMVATToolHelper.MakeOrderSales(SalesHeader, SalesOrderHeader);
        ERMVATToolHelper.CreateLinesRefSales(TempRecRef, SalesHeader);

        // SETUP: Ship Sales Order.
        if Partial then
            ERMVATToolHelper.UpdateQtyToShip(SalesOrderHeader);
        ERMVATToolHelper.CreateLinesRefSales(TempRecRef, SalesOrderHeader);
        LibrarySales.PostSalesDocument(SalesOrderHeader, true, false);

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolSales(FieldOption, true, true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Blanket Order & Sales Order.
        if Partial then begin
            VerifySalesLnPartShipped(TempRecRef);
            ERMVATToolHelper.VerifyDocumentSplitLogEntries(TempRecRef);
        end else begin
            ERMVATToolHelper.VerifyUpdate(TempRecRef, false);
            ERMVATToolHelper.VerifyErrorLogEntries(TempRecRef, true);
        end;

        // Cleanup: Delete Groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure VATToolMakeSalesOrderShPost(FieldOption: Option; Partial: Boolean; MultipleLines: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesOrderHeader: Record "Sales Header";
        TempRecRef: RecordRef;
    begin
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create Blanket Order.
        ERMVATToolHelper.CreateSalesDocumentWithRef(SalesHeader, TempRecRef, SalesHeader."Document Type"::"Blanket Order", '',
          GetLineCount(MultipleLines));

        // SETUP: Make Order.
        ERMVATToolHelper.MakeOrderSales(SalesHeader, SalesOrderHeader);

        // SETUP: Ship Sales Order.
        if Partial then
            ERMVATToolHelper.UpdateQtyToShip(SalesOrderHeader);
        LibrarySales.PostSalesDocument(SalesOrderHeader, true, false);

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolSales(FieldOption, true, true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Sales Order Posted Successfully.
        SalesOrderHeader.Find();
        LibrarySales.PostSalesDocument(SalesOrderHeader, true, true);

        // Cleanup: Delete Groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure VATToolSalesLine(FieldOption: Option; IgnoreStatus: Boolean; DocumentType: Enum "Sales Document Type"; Release: Boolean; Ship: Boolean; MultipleLines: Boolean)
    var
        SalesHeader: Record "Sales Header";
        TempRecRef: RecordRef;
        Update: Boolean;
    begin
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and Save data to update in a temporary table.
        ERMVATToolHelper.CreateSalesDocumentWithRef(SalesHeader, TempRecRef, DocumentType, '', GetLineCount(MultipleLines));

        // SETUP: Release.
        if Release then
            LibrarySales.ReleaseSalesDocument(SalesHeader);

        // SETUP: Ship (Fully).
        if Ship then
            LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolSales(FieldOption, true, IgnoreStatus);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        Update := ExpectUpdate(SalesHeader."Document Type", Ship, Release, IgnoreStatus);
        ERMVATToolHelper.VerifyUpdate(TempRecRef, Update);
        // Verify: Log Entries
        if Update then
            ERMVATToolHelper.VerifyLogEntries(TempRecRef)
        else
            ERMVATToolHelper.VerifyErrorLogEntries(TempRecRef, ExpectLogEntries(SalesHeader."Document Type", Release, IgnoreStatus));

        // Cleanup: Delete Groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure VATToolSalesLineAmount(DocumentType: Enum "Sales Document Type"; PartialShip: Boolean)
    var
        SalesHeader: Record "Sales Header";
    begin
        // Sales Order with one partially shipped and released line, update VAT group and ignore header status. Verify Amount.
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and Save data to update in a temporary table.
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, ERMVATToolHelper.CreateCustomer());
        SalesHeader.Validate("Prices Including VAT", true);
        SalesHeader.Modify(true);
        ERMVATToolHelper.CreateSalesLines(SalesHeader, '', GetLineCount(true));

        // SETUP: Ship (Partially).
        if PartialShip then begin
            ERMVATToolHelper.UpdateQtyToShip(SalesHeader);
            LibrarySales.PostSalesDocument(SalesHeader, true, false);
        end;

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolSales(VATRateChangeSetup2."Update Sales Documents"::"VAT Prod. Posting Group", true, true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check VAT%, Unit Price and Line Amount Including VAT.
        VerifySalesDocAmount(SalesHeader);

        // Cleanup: Delete Groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure VATToolSalesLinePartShip(FieldOption: Option; DocumentType: Enum "Sales Document Type"; AutoInsertDefault: Boolean; MultipleLines: Boolean)
    var
        SalesHeader: Record "Sales Header";
        TempRecRef: RecordRef;
    begin
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(AutoInsertDefault);

        // SETUP: Create and Save data to update in a temporary table.
        ERMVATToolHelper.CreateSalesDocumentWithRef(SalesHeader, TempRecRef, DocumentType, '', GetLineCount(MultipleLines));

        // SETUP: Ship (Partially).
        ERMVATToolHelper.UpdateQtyToShip(SalesHeader);
        ERMVATToolHelper.CreateLinesRefSales(TempRecRef, SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolSales(FieldOption, true, true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        if SalesHeader."Document Type" = SalesHeader."Document Type"::Order then begin
            VerifySalesLnPartShipped(TempRecRef);
            ERMVATToolHelper.VerifyDocumentSplitLogEntries(TempRecRef);
        end else begin
            ERMVATToolHelper.VerifyUpdate(TempRecRef, false);
            ERMVATToolHelper.VerifyErrorLogEntries(TempRecRef, false);
        end;

        // Cleanup: Delete Groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure VATToolSalesLineReserve(FieldOption: Option; MultipleLines: Boolean)
    begin
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and save data to update in a temporary table.
        PrepareSalesDocWithReservation(GetLineCount(MultipleLines));

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolSales(FieldOption, true, true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        VerifySalesDocWithReservation(false);

        // Cleanup: Delete Groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure VATToolSalesLineWhse(FieldOption: Option; LineCount: Integer; Ship: Boolean)
    var
        TempRecRef: RecordRef;
    begin
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and save data to update in a temporary table.
        ERMVATToolHelper.CreateWarehouseDocument(TempRecRef, DATABASE::"Sales Line", LineCount, Ship);

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolSales(FieldOption, true, true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        ERMVATToolHelper.VerifyUpdate(TempRecRef, not Ship);
        // Verify: Log Entries
        if not Ship then
            ERMVATToolHelper.VerifyLogEntries(TempRecRef)
        else
            ERMVATToolHelper.VerifyErrorLogEntries(TempRecRef, true);

        // Cleanup: Delete Groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure VATToolSalesOrderItemChrgDiffDoc(Ship: Boolean; Invoice: Boolean)
    var
        TempRecRef: RecordRef;
    begin
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and save data to update in a temporary table.
        PrepareSalesDocItemCharge(TempRecRef, Ship, Invoice);

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolSales(VATRateChangeSetup2."Update Sales Documents"::Both, true, true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        ERMVATToolHelper.VerifyUpdate(TempRecRef, not Ship);

        // Cleanup: Delete Groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure VATToolSalesOrderItemChrgSameDoc(Ship: Boolean; Invoice: Boolean)
    var
        TempRecRef: RecordRef;
    begin
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and save data to update in a temporary table.
        PrepareSalesDocItemChargeSameDoc(TempRecRef, Ship, Invoice);

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolSales(VATRateChangeSetup2."Update Sales Documents"::Both, true, true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        if not Ship then
            VerifyItemChrgAssignmentSales(TempRecRef)
        else
            ERMVATToolHelper.VerifyUpdate(TempRecRef, false);

        // Cleanup: Delete Groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure VATToolSalesLineWithNegativeQty(Ship: Boolean)
    var
        SalesHeader: Record "Sales Header";
        TempRecRef: RecordRef;
    begin
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and Save data to update in a temporary table.
        ERMVATToolHelper.CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, '', 1);
        AddLineWithNegativeQty(SalesHeader);
        TempRecRef.Open(DATABASE::"Sales Line", true);
        ERMVATToolHelper.CreateLinesRefSales(TempRecRef, SalesHeader);

        // SETUP: Ship
        if Ship then begin
            ERMVATToolHelper.UpdateQtyToShip(SalesHeader);
            ERMVATToolHelper.CreateLinesRefSales(TempRecRef, SalesHeader);
            LibrarySales.PostSalesDocument(SalesHeader, true, false);
        end;

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolSales(VATRateChangeSetup2."Update Sales Documents"::Both, true, true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        if Ship then
            VerifySalesLnPartShipped(TempRecRef)
        else
            ERMVATToolHelper.VerifyUpdate(TempRecRef, true);

        // Cleanup: Delete Groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure VATToolDropShipment(FieldOption: Option; FieldOption2: Option)
    var
        SalesTempRecRef: RecordRef;
        PurchaseTempRecRef: RecordRef;
    begin
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and save data to update in temporary tables.
        CreateSpecialDocs(SalesTempRecRef, PurchaseTempRecRef, true);

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolSales(FieldOption, true, true);
        ERMVATToolHelper.SetupToolOption(VATRateChangeSetup2.FieldNo("Update Purchase Documents"), FieldOption2);
        ERMVATToolHelper.SetupToolCheckbox(VATRateChangeSetup2.FieldNo("Ignore Status on Purch. Docs."), true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        VerifySpecialDocUpdate(SalesTempRecRef, PurchaseTempRecRef);

        // Verify: Log Entries
        ERMVATToolHelper.VerifySpecialDocLogEntries(SalesTempRecRef);
        ERMVATToolHelper.VerifySpecialDocLogEntries(PurchaseTempRecRef);

        // Cleanup: Delete Groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure VATToolSpecialOrder(FieldOption: Option; FieldOption2: Option)
    var
        SalesTempRecRef: RecordRef;
        PurchaseTempRecRef: RecordRef;
    begin
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and save data to update in temporary tables.
        CreateSpecialDocs(SalesTempRecRef, PurchaseTempRecRef, false);

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolSales(FieldOption, true, true);
        ERMVATToolHelper.SetupToolOption(VATRateChangeSetup2.FieldNo("Update Purchase Documents"), FieldOption2);
        ERMVATToolHelper.SetupToolCheckbox(VATRateChangeSetup2.FieldNo("Ignore Status on Purch. Docs."), true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        VerifySpecialDocUpdate(SalesTempRecRef, PurchaseTempRecRef);

        // Verify: Log Entries
        ERMVATToolHelper.VerifySpecialDocLogEntries(SalesTempRecRef);
        ERMVATToolHelper.VerifySpecialDocLogEntries(PurchaseTempRecRef);

        // Cleanup: Delete Groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure AddDimensionsForSalesLines(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DimensionSetID: Integer;
    begin
        GetSalesLine(SalesHeader, SalesLine);
        repeat
            DimensionSetID := SalesLine."Dimension Set ID";
            LibraryDimension.FindDimension(Dimension);
            LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
            DimensionSetID := LibraryDimension.CreateDimSet(DimensionSetID, DimensionValue."Dimension Code", DimensionValue.Code);
            SalesLine.Validate("Dimension Set ID", DimensionSetID);
            SalesLine.Modify(true);
        until SalesLine.Next() = 0;
    end;

    local procedure AddLineWithNegativeQty(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        SalesLine3: Record "Sales Line";
    begin
        GetSalesLine(SalesHeader, SalesLine3);
        SalesLine3.FindLast();
        ERMVATToolHelper.CreateSalesLine(SalesLine, SalesHeader, '', SalesLine3."No.", -SalesLine3.Quantity);
    end;

    local procedure AddLineWithNextLineNo(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        SalesLine3: Record "Sales Line";
    begin
        GetSalesLine(SalesHeader, SalesLine3);
        SalesLine3.FindLast();

        SalesLine.Init();
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
        SalesLine.Validate("Line No.", SalesLine3."Line No." + 1);
        SalesLine.Insert(true);

        SalesLine.Validate(Type, SalesLine3.Type);
        SalesLine.Validate("No.", SalesLine3."No.");
        SalesLine.Validate(Quantity, SalesLine3.Quantity);
        SalesLine.Modify(true);
    end;

    local procedure CopySalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; SalesLine3: Record "Sales Line")
    begin
        ERMVATToolHelper.CreateSalesLine(SalesLine, SalesHeader, SalesLine3."Location Code", SalesLine3."No.", SalesLine3.Quantity);
        SalesLine.Validate("VAT Prod. Posting Group", SalesLine3."VAT Prod. Posting Group");
        SalesLine.Modify(true);
    end;

    local procedure CreateSpecialDocs(var SalesTempRecRef: RecordRef; var PurchaseTempRecRef: RecordRef; DropShipment: Boolean)
    var
        SalesHeader: Record "Sales Header";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        ReqWkshName: Record "Requisition Wksh. Name";
        ReqLine: Record "Requisition Line";
        PurchaseLine: Record "Purchase Line";
        RecRef: RecordRef;
        VATProdPostingGroup: Code[20];
        GenProdPostingGroup: Code[20];
    begin
        ERMVATToolHelper.GetGroupsBefore(VATProdPostingGroup, GenProdPostingGroup);

        ERMVATToolHelper.CreateSalesDocumentWithRef(SalesHeader, SalesTempRecRef, SalesHeader."Document Type"::Order, '', 1);
        UpdateSpecialSalesLine(SalesHeader, DropShipment);
        ReqWkshTemplate.SetRange(Type, ReqWkshName."Template Type"::"Req.");
        ReqWkshTemplate.FindFirst();
        LibraryPlanning.CreateRequisitionWkshName(ReqWkshName, ReqWkshTemplate.Name);
        ReqLine.Init();
        ReqLine.Validate("Worksheet Template Name", ReqWkshName."Worksheet Template Name");
        ReqLine.Validate("Journal Batch Name", ReqWkshName.Name);
        // No INSERT.
        RunGetSalesOrders(ReqLine, SalesHeader, DropShipment);
        ReqLine.SetRange("Worksheet Template Name", ReqWkshName."Worksheet Template Name");
        ReqLine.SetRange("Journal Batch Name", ReqWkshName.Name);
        ReqLine.FindFirst();
        ReqLine.Validate("Vendor No.", ERMVATToolHelper.CreateVendor());
        ReqLine.Modify(true);
        LibraryPlanning.CarryOutActionMsgPlanWksh(ReqLine);

        PurchaseTempRecRef.Open(DATABASE::"Purchase Line", true);
        if DropShipment then
            PurchaseLine.SetFilter("Sales Order No.", SalesHeader."No.")
        else
            PurchaseLine.SetFilter("Special Order Sales No.", SalesHeader."No.");
        PurchaseLine.FindFirst();
        RecRef.GetTable(PurchaseLine);
        ERMVATToolHelper.CopyRecordRef(RecRef, PurchaseTempRecRef);
    end;

    local procedure CreateFinChargeMemoLines(var TempRecRef: RecordRef; "Count": Integer)
    var
        FinChargeMemoHeader: Record "Finance Charge Memo Header";
        FinChargeMemoLine: Record "Finance Charge Memo Line";
        RecRef: RecordRef;
        VATProdPostingGroup: Code[20];
        GenProdPostingGroup: Code[20];
        I: Integer;
    begin
        ERMVATToolHelper.GetGroupsBefore(VATProdPostingGroup, GenProdPostingGroup);
        TempRecRef.Open(DATABASE::"Finance Charge Memo Line", true);

        LibraryERM.CreateFinanceChargeMemoHeader(FinChargeMemoHeader, ERMVATToolHelper.CreateCustomer());
        FinChargeMemoHeader.Modify(true);
        for I := 1 to Count do begin
            LibraryERM.CreateFinanceChargeMemoLine(FinChargeMemoLine, FinChargeMemoHeader."No.", FinChargeMemoLine.Type::"G/L Account");
            FinChargeMemoLine.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
            FinChargeMemoLine.Modify(true);
            RecRef.GetTable(FinChargeMemoLine);
            ERMVATToolHelper.CopyRecordRef(RecRef, TempRecRef);
        end;
    end;

    local procedure CreateProductionOrders(var TempRecRef: RecordRef; "Count": Integer)
    var
        ProductionOrder: Record "Production Order";
        RecRef: RecordRef;
        VATProdPostingGroup: Code[20];
        GenProdPostingGroup: Code[20];
        I: Integer;
    begin
        ERMVATToolHelper.GetGroupsBefore(VATProdPostingGroup, GenProdPostingGroup);
        TempRecRef.Open(DATABASE::"Production Order", true);

        for I := 1 to Count do begin
            Clear(ProductionOrder);
            ProductionOrder.Init();
            ProductionOrder.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
            ProductionOrder.Insert(true);
            RecRef.GetTable(ProductionOrder);
            ERMVATToolHelper.CopyRecordRef(RecRef, TempRecRef);
        end;
    end;

    local procedure CreateReminderLines(var TempRecRef: RecordRef; "Count": Integer)
    var
        ReminderHeader: Record "Reminder Header";
        ReminderLine: Record "Reminder Line";
        RecRef: RecordRef;
        VATProdPostingGroup: Code[20];
        GenProdPostingGroup: Code[20];
        I: Integer;
    begin
        ERMVATToolHelper.GetGroupsBefore(VATProdPostingGroup, GenProdPostingGroup);
        TempRecRef.Open(DATABASE::"Reminder Line", true);

        LibraryERM.CreateReminderHeader(ReminderHeader);
        ReminderHeader.Validate("Customer No.", ERMVATToolHelper.CreateCustomer());
        ReminderHeader.Modify(true);
        for I := 1 to Count do begin
            ReminderLine.Init();
            ReminderLine.Validate("Reminder No.", ReminderHeader."No.");
            ReminderLine.Validate(Type, ReminderLine.Type::"G/L Account");
            RecRef.GetTable(ReminderLine);
            ReminderLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, ReminderLine.FieldNo("Line No.")));
            ReminderLine.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
            ReminderLine.Insert(true);
            RecRef.GetTable(ReminderLine);
            ERMVATToolHelper.CopyRecordRef(RecRef, TempRecRef);
        end;
    end;

    local procedure CreateSalesItemChargeLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    var
        ItemCharge: Record "Item Charge";
        VATProdPostingGroupCode: Code[20];
        GenProdPostingGroupCode: Code[20];
    begin
        ERMVATToolHelper.GetGroupsBefore(VATProdPostingGroupCode, GenProdPostingGroupCode);
        ERMVATToolHelper.CreateItemCharge(ItemCharge);
        // Create Sales Line with Quantity > 1 to be able to partially ship it
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"Charge (Item)",
          ItemCharge."No.", ERMVATToolHelper.GetQuantity());
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Location Code", '');
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesInvoiceWithPricesIncludingVAT(var SalesLine: Record "Sales Line"; Type: Enum "Sales Line Type"; No: Code[20])
    var
        SalesHeader: Record "Sales Header";
        VATProdPostingGroup: Code[20];
        GenProdPostingGroup: Code[20];
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Prices Including VAT", true);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, LibraryRandom.RandInt(10));
        ERMVATToolHelper.GetGroupsBefore(VATProdPostingGroup, GenProdPostingGroup);
        SalesLine.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        SalesLine.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure GetLineCount(MultipleLines: Boolean) "Count": Integer
    begin
        if MultipleLines then
            Count := LibraryRandom.RandInt(2) + 1
        else
            Count := 1;
    end;

    local procedure GetSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        SalesHeader.Find();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindSet();
    end;

    local procedure GetSalesShipmentLine(var SalesShipmentLine: Record "Sales Shipment Line"; SalesHeader: Record "Sales Header")
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        SalesShipmentHeader.SetRange("Order No.", SalesHeader."No.");
        SalesShipmentHeader.FindFirst();
        SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");
        SalesShipmentLine.SetRange(Type, SalesShipmentLine.Type::Item);
        SalesShipmentLine.FindFirst();
    end;

    local procedure GetShipmentLineForSalesInvoice(var SalesHeader: Record "Sales Header"; var SalesShipmentLine: Record "Sales Shipment Line")
    var
        SalesGetShpt: Codeunit "Sales-Get Shipment";
    begin
        SalesGetShpt.SetSalesHeader(SalesHeader);
        SalesGetShpt.CreateInvLines(SalesShipmentLine);
    end;

    local procedure GetVatProdPostingGroupFromSalesLine(var SalesHeader: Record "Sales Header"): Code[20]
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        exit(SalesLine."VAT Prod. Posting Group");
    end;

    local procedure CalcChangedUnitPriceGivenDiffVATPostingSetup(SalesLine: Record "Sales Line"): Decimal
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenProdPostingGroup: Code[20];
        VATProdPostingGroup: Code[20];
    begin
        ERMVATToolHelper.GetGroupsAfter(VATProdPostingGroup, GenProdPostingGroup, DATABASE::"Sales Line");
        VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", VATProdPostingGroup);
        exit(
          Round(
            SalesLine."Unit Price" * (100 + VATPostingSetup."VAT %") / (100 + SalesLine."VAT %"),
            LibraryERM.GetUnitAmountRoundingPrecision()));
    end;

    local procedure ExpectLogEntries(DocumentType: Enum "Sales Document Type"; Release: Boolean; IgnoreStatus: Boolean): Boolean
    var
        Update: Boolean;
    begin
        Update := true;

        if (not IgnoreStatus) and Release then
            Update := false;

        if (DocumentType = SalesHeader2."Document Type"::"Credit Memo") or
           (DocumentType = SalesHeader2."Document Type"::"Return Order")
        then
            Update := false;

        exit(Update);
    end;

    local procedure ExpectUpdate(DocumentType: Enum "Sales Document Type"; Ship: Boolean; Release: Boolean; IgnoreStatus: Boolean): Boolean
    var
        Update: Boolean;
    begin
        Update := true;

        if (not IgnoreStatus) and Release then
            Update := false;

        if Ship then
            Update := false;

        if (DocumentType = SalesHeader2."Document Type"::"Credit Memo") or
           (DocumentType = SalesHeader2."Document Type"::"Return Order")
        then
            Update := false;

        exit(Update);
    end;

    local procedure PrepareSalesDocItemCharge(var TempRecRef: RecordRef; Ship: Boolean; Invoice: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        RecRef: RecordRef;
    begin
        ERMVATToolHelper.CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, '', 1);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        GetSalesShipmentLine(SalesShipmentLine, SalesHeader);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SalesHeader."Sell-to Customer No.");
        CreateSalesItemChargeLine(SalesLine, SalesHeader);
        LibraryInventory.CreateItemChargeAssignment(ItemChargeAssignmentSales,
              SalesLine, ItemChargeAssignmentSales."Applies-to Doc. Type"::Shipment, SalesShipmentLine."Document No.", SalesShipmentLine."Line No.", SalesShipmentLine."No.");
        RecRef.GetTable(SalesLine);
        TempRecRef.Open(DATABASE::"Sales Line", true);
        ERMVATToolHelper.CopyRecordRef(RecRef, TempRecRef);

        if Ship then begin
            ERMVATToolHelper.UpdateQtyToShip(SalesHeader);
            ERMVATToolHelper.UpdateQtyToAssignSales(ItemChargeAssignmentSales, SalesLine);
            LibrarySales.PostSalesDocument(SalesHeader, true, Invoice);
        end;
    end;

    local procedure PrepareSalesDocItemChargeSameDoc(var TempRecRef: RecordRef; Ship: Boolean; Invoice: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine3: Record "Sales Line";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        RecRef: RecordRef;
    begin
        ERMVATToolHelper.CreateSalesDocumentWithRef(SalesHeader, TempRecRef, SalesHeader."Document Type"::Order, '', 1);
        CreateSalesItemChargeLine(SalesLine, SalesHeader);
        SalesLine3.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine3.SetRange("Document No.", SalesHeader."No.");
        SalesLine3.FindFirst();
        LibraryInventory.CreateItemChargeAssignment(ItemChargeAssignmentSales,
              SalesLine, ItemChargeAssignmentSales."Applies-to Doc. Type"::Order, SalesLine3."Document No.", SalesLine3."Line No.", SalesLine3."No.");

        SalesLine.Find();
        RecRef.GetTable(SalesLine);
        ERMVATToolHelper.CopyRecordRef(RecRef, TempRecRef);

        ERMVATToolHelper.UpdateQtyToShip(SalesHeader);

        // If Item Charge should not be shipped, change Qty. to Ship to 0.
        if not Ship then begin
            SalesLine.Find();
            SalesLine.Validate("Qty. to Ship", 0);
            SalesLine.Modify(true);
        end;

        // If Item Charge should be invoiced, Qty. to Assign should be equal Qty. to Invoice.
        if Invoice then
            ERMVATToolHelper.UpdateQtyToAssignSales(ItemChargeAssignmentSales, SalesLine);

        // Line with Item is only split, if Item Charge is not partially shipped.
        if not Ship then
            ERMVATToolHelper.CreateLinesRefSales(TempRecRef, SalesHeader);

        LibrarySales.PostSalesDocument(SalesHeader, true, Invoice);
    end;

    local procedure PrepareSalesInvoiceForShipment(var TempRecRef: RecordRef)
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        ERMVATToolHelper.CreateSalesDocumentWithRef(SalesHeader, TempRecRef, SalesHeader."Document Type"::Order, '', 1);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        GetSalesShipmentLine(SalesShipmentLine, SalesHeader);

        LibrarySales.CreateSalesHeader(SalesHeader2, SalesHeader."Document Type"::Invoice, SalesHeader."Sell-to Customer No.");
        GetShipmentLineForSalesInvoice(SalesHeader2, SalesShipmentLine);
        ERMVATToolHelper.CreateLinesRefSales(TempRecRef, SalesHeader2);
    end;

    local procedure PrepareSalesDocItemTracking()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        Qty: Integer;
    begin
        // Create Item with tracking and purchase it
        ERMVATToolHelper.CreateItemWithTracking(Item, true);
        Qty := ERMVATToolHelper.GetQuantity();
        ERMVATToolHelper.PostItemPurchase(Item, '', Qty);

        // Create Sales Order with Item with tracking
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, ERMVATToolHelper.CreateCustomer());
        ERMVATToolHelper.CreateSalesLine(SalesLine, SalesHeader, '', Item."No.", Qty);

        // Assign Serial Nos
        SalesLine.OpenItemTrackingLines();

        // Partially Ship Order
        ERMVATToolHelper.UpdateQtyToShip(SalesHeader);
        ERMVATToolHelper.UpdateQtyToHandleSales(SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure PrepareSalesDocWithReservation(LineCount: Integer)
    var
        SalesHeader: Record "Sales Header";
    begin
        ERMVATToolHelper.CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, '', LineCount);
        ERMVATToolHelper.AddReservationLinesForSales(SalesHeader);
        ERMVATToolHelper.UpdateQtyToShip(SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure RunGetSalesOrders(RequisitionLine: Record "Requisition Line"; SalesHeader: Record "Sales Header"; DropShipment: Boolean)
    var
        SalesLine: Record "Sales Line";
        GetSalesOrders: Report "Get Sales Orders";
        RetrieveDimensions: Option "Sales Line",Item;
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        Clear(GetSalesOrders);
        GetSalesOrders.SetTableView(SalesLine);
        GetSalesOrders.InitializeRequest(RetrieveDimensions::"Sales Line");
        if DropShipment then
            GetSalesOrders.SetReqWkshLine(RequisitionLine, 0)
        else
            GetSalesOrders.SetReqWkshLine(RequisitionLine, 1);
        GetSalesOrders.UseRequestPage(false);
        GetSalesOrders.Run();
    end;

    local procedure PostSalesPrepayment(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
    begin
        // Mandatory field for IT
        SalesHeader.Validate("Prepayment Due Date", WorkDate());
        SalesHeader.Modify(true);
        GetSalesLine(SalesHeader, SalesLine);

        repeat
            UpdateSalesLinePrepayment(SalesLine);
        until SalesLine.Next() = 0;

        SalesPostPrepayments.Invoice(SalesHeader);
    end;

    local procedure SetTempTableSales(TempRecRef: RecordRef; var TempSalesLn: Record "Sales Line" temporary)
    begin
        // SETTABLE call required for each record of the temporary table.
        TempRecRef.Reset();
        if TempRecRef.FindSet() then begin
            TempSalesLn.SetView(TempRecRef.GetView());
            repeat
                TempRecRef.SetTable(TempSalesLn);
                TempSalesLn.Insert(false);
            until TempRecRef.Next() = 0;
        end;
    end;

    local procedure SetupToolSales(FieldOption: Option; PerformConversion: Boolean; IgnoreStatus: Boolean)
    var
        VATRateChangeSetup: Record "VAT Rate Change Setup";
    begin
        ERMVATToolHelper.SetupToolOption(VATRateChangeSetup.FieldNo("Update Sales Documents"), FieldOption);
        ERMVATToolHelper.SetupToolCheckbox(VATRateChangeSetup.FieldNo("Ignore Status on Sales Docs."), IgnoreStatus);
        ERMVATToolHelper.SetupToolCheckbox(VATRateChangeSetup.FieldNo("Perform Conversion"), PerformConversion);
    end;

    local procedure UpdateSpecialSalesLine(SalesHeader: Record "Sales Header"; DropShipment: Boolean)
    var
        SalesLine: Record "Sales Line";
        Purchasing: Record Purchasing;
    begin
        SalesLine.SetFilter("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        if DropShipment then
            Purchasing.SetRange("Drop Shipment", true)
        else
            Purchasing.SetRange("Special Order", true);
        Purchasing.FindFirst();
        SalesLine.Validate("Purchasing Code", Purchasing.Code);
        SalesLine.Modify(true);
    end;

    local procedure UpdateSalesLinePrepayment(var SalesLine: Record "Sales Line")
    begin
        SalesLine.Validate("Prepayment %", LibraryRandom.RandInt(20));
        SalesLine.Modify(true);
    end;

    local procedure UpdateQtyBlanketOrder(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        QtyShipped: Integer;
    begin
        GetSalesLine(SalesHeader, SalesLine);
        QtyShipped := SalesLine."Qty. Shipped Not Invoiced";
        SalesLine.Next();
        SalesLine.Validate("Qty. to Ship", SalesLine.Quantity - QtyShipped);
        SalesLine.Modify(true);
    end;

    local procedure UpdateItemOnSalesLine(var Item: Record Item)
    var
        SalesLine: Record "Sales Line";
        VATProdPostingGroupCode: Code[20];
        GenProdPostingGroupCode: Code[20];
    begin
        ERMVATToolHelper.GetGroupsAfter(VATProdPostingGroupCode, GenProdPostingGroupCode, DATABASE::"Sales Line");
        SalesLine.SetRange("VAT Prod. Posting Group", VATProdPostingGroupCode);
        SalesLine.SetRange("Gen. Prod. Posting Group", GenProdPostingGroupCode);
        SalesLine.FindFirst();

        Item.Get(SalesLine."No.");
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Modify(true);
    end;

    local procedure VerifyQuantitiesOnSalesLine(SalesLine: Record "Sales Line"; ExpectedQuantity: Decimal; ExpectedQuantityToInvoice: Decimal; ExpectedQuantityInvoiced: Decimal; ExpectedQuantityToShip: Decimal; ExpectedQuantityShipped: Decimal; VATProductPostingGroupCode: Code[20])
    begin
        SalesLine.TestField("VAT Prod. Posting Group", VATProductPostingGroupCode);
        SalesLine.TestField(Quantity, ExpectedQuantity);
        SalesLine.TestField("Quantity Invoiced", ExpectedQuantityInvoiced);
        SalesLine.TestField("Qty. to Invoice", ExpectedQuantityToInvoice);
        SalesLine.TestField("Quantity Shipped", ExpectedQuantityShipped);
        SalesLine.TestField("Qty. to Ship", ExpectedQuantityToShip);
    end;

    local procedure VerifySalesDocAmount(SalesHeader: Record "Sales Header")
    var
        SalesHeader3: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine3: Record "Sales Line";
    begin
        GetSalesLine(SalesHeader, SalesLine);
        LibrarySales.CreateSalesHeader(SalesHeader3, SalesHeader3."Document Type"::Order, SalesHeader."Sell-to Customer No.");
        SalesHeader3.Validate("Prices Including VAT", true);
        SalesHeader3.Modify(true);
        repeat
            CopySalesLine(SalesHeader3, SalesLine3, SalesLine);
            VerifySalesLineAmount(SalesLine, SalesLine3);
        until SalesLine.Next() = 0;
    end;

    local procedure VerifySalesLineAmount(SalesLine: Record "Sales Line"; SalesLine3: Record "Sales Line")
    begin
        SalesLine.TestField("VAT %", SalesLine3."VAT %");
        SalesLine.TestField("Unit Price", SalesLine3."Unit Price");
        SalesLine.TestField("Line Amount", SalesLine3."Line Amount");
    end;

    local procedure VerifyItemChrgAssignmentSales(TempRecRef: RecordRef)
    var
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        TempSalesLn: Record "Sales Line" temporary;
        QtyItemCharge: Integer;
        QtyItem: Integer;
        QtyShippedItem: Integer;
    begin
        SetTempTableSales(TempRecRef, TempSalesLn);
        TempSalesLn.SetRange(Type, TempSalesLn.Type::"Charge (Item)");
        TempSalesLn.FindFirst();
        QtyItemCharge := TempSalesLn.Quantity;
        TempSalesLn.SetRange(Type, TempSalesLn.Type::Item);
        TempSalesLn.FindSet();
        QtyItem := TempSalesLn.Quantity;
        QtyShippedItem := TempSalesLn."Qty. to Ship";
        TempSalesLn.Next();
        QtyItem += TempSalesLn.Quantity;

        ItemChargeAssignmentSales.SetRange("Document Type", TempSalesLn."Document Type");
        ItemChargeAssignmentSales.SetFilter("Document No.", TempSalesLn."Document No.");
        ItemChargeAssignmentSales.FindSet();
        Assert.AreEqual(2, ItemChargeAssignmentSales.Count, ERMVATToolHelper.GetItemChargeErrorCount());
        Assert.AreNearlyEqual(QtyShippedItem / QtyItem * QtyItemCharge, ItemChargeAssignmentSales."Qty. to Assign", 0.01, ERMVATToolHelper.GetItemChargeErrorCount());
        ItemChargeAssignmentSales.Next();
        Assert.AreNearlyEqual(
          (QtyItem - QtyShippedItem) / QtyItem * QtyItemCharge, ItemChargeAssignmentSales."Qty. to Assign", 0.01, ERMVATToolHelper.GetItemChargeErrorCount());
    end;

    local procedure VerifySalesDocWithReservation(Tracking: Boolean)
    var
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        VATProdPostingGroup: Code[20];
        GenProdPostingGroup: Code[20];
    begin
        ERMVATToolHelper.GetGroupsAfter(VATProdPostingGroup, GenProdPostingGroup, DATABASE::"Sales Line");

        SalesLine.SetRange("VAT Prod. Posting Group", VATProdPostingGroup);
        SalesLine.SetRange("Gen. Prod. Posting Group", GenProdPostingGroup);
        SalesLine.FindSet();

        repeat
            ERMVATToolHelper.GetReservationEntrySales(ReservationEntry, SalesLine);
            if Tracking then
                Assert.AreEqual(SalesLine.Quantity, ReservationEntry.Count, ERMVATToolHelper.GetConversionErrorUpdate())
            else
                Assert.AreEqual(1, ReservationEntry.Count, ERMVATToolHelper.GetConversionErrorUpdate());
        until SalesLine.Next() = 0;

        ERMVATToolHelper.GetGroupsBefore(VATProdPostingGroup, GenProdPostingGroup);

        SalesLine.SetRange("VAT Prod. Posting Group", VATProdPostingGroup);
        SalesLine.SetRange("Gen. Prod. Posting Group", GenProdPostingGroup);
        SalesLine.FindSet();

        repeat
            ERMVATToolHelper.GetReservationEntrySales(ReservationEntry, SalesLine);
            Assert.AreEqual(0, ReservationEntry.Count, ERMVATToolHelper.GetConversionErrorUpdate());
        until SalesLine.Next() = 0;
    end;

    local procedure VerifySalesLnPartShipped(TempRecRef: RecordRef)
    var
        VATRateChangeSetup: Record "VAT Rate Change Setup";
        TempSalesLn: Record "Sales Line" temporary;
        SalesLn: Record "Sales Line";
        VATProdPostingGroupOld: Code[20];
        GenProdPostingGroupOld: Code[20];
        VATProdPostingGroupNew: Code[20];
        GenProdPostingGroupNew: Code[20];
    begin
        VATRateChangeSetup.Get();
        ERMVATToolHelper.GetGroupsBefore(VATProdPostingGroupOld, GenProdPostingGroupOld);
        ERMVATToolHelper.GetGroupsAfter(VATProdPostingGroupNew, GenProdPostingGroupNew, TempRecRef.Number);

        SalesLn.Reset();
        SalesLn.SetFilter("VAT Prod. Posting Group", StrSubstNo(GroupFilter, VATProdPostingGroupOld, VATProdPostingGroupNew));
        SalesLn.SetFilter("Gen. Prod. Posting Group", StrSubstNo(GroupFilter, GenProdPostingGroupOld, GenProdPostingGroupNew));
        SalesLn.FindSet();

        // Compare Number of lines.
        Assert.AreEqual(TempRecRef.Count, SalesLn.Count, StrSubstNo(ERMVATToolHelper.GetConversionErrorCount(), SalesLn.GetFilters));

        TempRecRef.Reset();
        SetTempTableSales(TempRecRef, TempSalesLn);
        TempSalesLn.FindSet();

        repeat
            if TempSalesLn."Description 2" = Format(TempSalesLn."Line No.") then
                VerifySplitNewLineSales(TempSalesLn, SalesLn, VATProdPostingGroupNew, GenProdPostingGroupNew)
            else
                VerifySplitOldLineSales(TempSalesLn, SalesLn);
            SalesLn.Next();
        until TempSalesLn.Next() = 0;
    end;

    local procedure VerifySplitOldLineSales(var SalesLn1: Record "Sales Line"; SalesLn2: Record "Sales Line")
    begin
        // Splitted Line should have Quantity = Quantity to Ship/Receive of the Original Line and old Product Posting Groups.
        SalesLn2.TestField("Line No.", SalesLn1."Line No.");
        case SalesLn2."Document Type" of
            SalesLn2."Document Type"::Order:
                SalesLn2.TestField(Quantity, SalesLn1."Qty. to Ship");
            SalesLn2."Document Type"::"Return Order":
                SalesLn2.TestField(Quantity, SalesLn1."Return Qty. to Receive");
        end;
        SalesLn2.TestField("Qty. to Ship", 0);
        SalesLn2.TestField("Return Qty. to Receive", 0);
        SalesLn2.TestField("Quantity Shipped", SalesLn1."Qty. to Ship");
        SalesLn2.TestField("Return Qty. Received", SalesLn1."Return Qty. to Receive");
        SalesLn2.TestField("Blanket Order No.", SalesLn1."Blanket Order No.");
        SalesLn2.TestField("Blanket Order Line No.", SalesLn1."Blanket Order Line No.");
        SalesLn2.TestField("VAT Prod. Posting Group", SalesLn1."VAT Prod. Posting Group");
        SalesLn2.TestField("Gen. Prod. Posting Group", SalesLn1."Gen. Prod. Posting Group");
    end;

    local procedure VerifySplitNewLineSales(var SalesLn1: Record "Sales Line"; SalesLn2: Record "Sales Line"; VATProdPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    begin
        // Line should have Quantity = Original Quantity - Quantity Shipped/Received,
        // Quantity Shipped/Received = 0 and new Posting Groups.
        SalesLn2.TestField(Quantity, SalesLn1.Quantity);
        if SalesLn2."Document Type" = SalesLn2."Document Type"::"Blanket Order" then
            SalesLn2.TestField("Qty. to Ship", 0)
        else
            SalesLn2.TestField("Qty. to Ship", SalesLn1."Qty. to Ship");
        SalesLn2.TestField("Return Qty. to Receive", SalesLn1."Return Qty. to Receive");
        SalesLn2.TestField("Dimension Set ID", SalesLn1."Dimension Set ID");
        SalesLn2.TestField("Blanket Order No.", SalesLn1."Blanket Order No.");
        SalesLn2.TestField("Blanket Order Line No.", SalesLn1."Blanket Order Line No.");
        SalesLn2.TestField("VAT Prod. Posting Group", VATProdPostingGroup);
        SalesLn2.TestField("Gen. Prod. Posting Group", GenProdPostingGroup);
    end;

    local procedure VerifySpecialDocUpdate(SalesTempRecRef: RecordRef; PurchaseTempRecRef: RecordRef)
    begin
        ERMVATToolHelper.VerifyUpdate(SalesTempRecRef, false);
        ERMVATToolHelper.VerifyUpdate(PurchaseTempRecRef, false);
    end;

    local procedure VerifyLineConverted(SalesHeader: Record "Sales Header"; QtyShipped: Decimal; QtyToBeConverted: Decimal)
    var
        SalesLine: Record "Sales Line";
        VATProdPostingGroupCode: Code[20];
        GenProdPostingGroupCode: Code[20];
    begin
        GetSalesLine(SalesHeader, SalesLine);
        SalesLine.TestField(Quantity, QtyShipped);
        SalesLine.TestField("Quantity Shipped", QtyShipped);
        ERMVATToolHelper.GetGroupsBefore(VATProdPostingGroupCode, GenProdPostingGroupCode);
        SalesLine.TestField("Gen. Prod. Posting Group", GenProdPostingGroupCode);
        SalesLine.TestField("VAT Prod. Posting Group", VATProdPostingGroupCode);
        Assert.AreEqual(1, SalesLine.Next(), 'No second line has been generated');
        SalesLine.TestField(Quantity, QtyToBeConverted);
        SalesLine.TestField("Quantity Shipped", 0);
        ERMVATToolHelper.GetGroupsAfter(VATProdPostingGroupCode, GenProdPostingGroupCode, DATABASE::"Sales Line");
        SalesLine.TestField("Gen. Prod. Posting Group", GenProdPostingGroupCode);
        SalesLine.TestField("VAT Prod. Posting Group", VATProdPostingGroupCode);
        Assert.AreEqual(0, SalesLine.Next(), 'The third line has been generated');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Assign Serial No.".Invoke();
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure QuantityToCreatePageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.OK().Invoke();
    end;
}

