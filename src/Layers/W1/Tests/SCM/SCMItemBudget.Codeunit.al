codeunit 137401 "SCM Item Budget"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Item Budget] [SCM]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        ItemBudgetEntryMustExist: Label 'Item Budget Entry must exist.';
        PostingDescription: Label 'Posting Description';
        Quantity: Decimal;
        Amount: Decimal;

    [Test]
    [HandlerFunctions('DateCompItemBudgetEntriesHandler,DimensionSelectionHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure DateCompressItemBudgetEntries()
    var
        ItemBudgetEntry: Record "Item Budget Entry";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        // Test and verify Date Compress Item Budget Entries Report functionality.

        // Setup: Create Item Budget Entries.
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();
        LibraryInventory.CreateItemBudgetEntry(
          ItemBudgetEntry, ItemBudgetEntry."Analysis Area"::Sales, FindItemBudgetName(), LibraryFiscalYear.GetFirstPostingDate(true),
          CreateItem());
        LibraryInventory.CreateItemBudgetEntry(
          ItemBudgetEntry, ItemBudgetEntry."Analysis Area"::Sales, ItemBudgetEntry."Budget Name",
          CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', LibraryFiscalYear.GetFirstPostingDate(true)),
          ItemBudgetEntry."Item No.");
        ItemBudgetEntry.SetRange("Item No.", ItemBudgetEntry."Item No.");

        // Exercise: Run Date Compress Item Budget Entries.
        RunDateCompressItemBudgetEntries(ItemBudgetEntry);

        // Verify: Verify Compressed Item Budget Entry.
        ItemBudgetEntry.SetRange(Description, PostingDescription);
        Assert.IsTrue(ItemBudgetEntry.FindFirst(), ItemBudgetEntryMustExist);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemBudgetEntryRoundingFactor()
    var
        Customer: Record Customer;
        ItemBudgetEntry: Record "Item Budget Entry";
        SalesBudgetOverview: TestPage "Sales Budget Overview";
        RoundingFactor: Option "None","1","1000","1000000";
    begin
        // Test functionality of Rounding Factor on Sales Budget Overview.

        // Setup: Create Item Budget Entry.
        Initialize();
        CreateItemBudgetEntry(ItemBudgetEntry);

        // Exercise: Run Sales Budget Overview.
        RunSalesBudgetOverview(
          SalesBudgetOverview, ItemBudgetEntry."Budget Name", Customer.TableCaption(), ItemBudgetEntry."Item No.",
          ItemBudgetEntry."Source No.", RoundingFactor::"1");

        // Verify: Verify Amount must be rounded with 1 precision.
        SalesBudgetOverview.MATRIX.Field1.AssertEquals(Round(ItemBudgetEntry."Sales Amount", 1));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemBudgetEntryShowAsColumn()
    var
        ItemBudgetEntry: Record "Item Budget Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesBudgetOverview: TestPage "Sales Budget Overview";
        RoundingFactor: Option "None","1","1000","1000000";
    begin
        // Test functionality of Show As Column on Sales Budget Overview.

        // Setup: Create Item Budget Entry.
        Initialize();
        CreateItemBudgetEntry(ItemBudgetEntry);
        GeneralLedgerSetup.Get();

        // Exercise: Run Sales Budget Overview.
        RunSalesBudgetOverview(
          SalesBudgetOverview, ItemBudgetEntry."Budget Name", GeneralLedgerSetup."Global Dimension 1 Code", ItemBudgetEntry."Item No.", '',
          RoundingFactor::None);

        // Verify: Verify Amount must be zero.
        SalesBudgetOverview.MATRIX.Field1.AssertEquals(0);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure SalesBudgetEntryWithDeletion()
    var
        Customer: Record Customer;
        ItemBudgetEntry: Record "Item Budget Entry";
        SalesBudgetOverview: TestPage "Sales Budget Overview";
        RoundingFactor: Option "None","1","1000","1000000";
    begin
        // Delete item budget entries and check overview amount is zero.

        // Setup: Create Item Budget Entry.
        Initialize();
        CreateItemBudgetEntry(ItemBudgetEntry);

        // Exercise: Run Sales Budget Overview and invoke Delete Budget.
        RunSalesBudgetOverview(
          SalesBudgetOverview, ItemBudgetEntry."Budget Name", Customer.TableCaption(), ItemBudgetEntry."Item No.",
          ItemBudgetEntry."Source No.", RoundingFactor::"1");
        SalesBudgetOverview.DeleteBudget.Invoke();

        // Verify: Verify overview amount is zero after delete item budget entries.
        SalesBudgetOverview.MATRIX.Field1.AssertEquals(0);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure SalesBudgetEntryWithoutDeletion()
    var
        Customer: Record Customer;
        ItemBudgetEntry: Record "Item Budget Entry";
        SalesBudgetOverview: TestPage "Sales Budget Overview";
        RoundingFactor: Option "None","1","1000","1000000";
    begin
        // Decline delete item budget entries and check overview amount is unchanged.

        // Setup: Create Item Budget Entry.
        Initialize();
        CreateItemBudgetEntry(ItemBudgetEntry);

        // Exercise: Run Sales Budget Overview and invoke Delete Budget.
        RunSalesBudgetOverview(
          SalesBudgetOverview, ItemBudgetEntry."Budget Name", Customer.TableCaption(), ItemBudgetEntry."Item No.",
          ItemBudgetEntry."Source No.", RoundingFactor::"1");
        SalesBudgetOverview.DeleteBudget.Invoke();

        // Verify: Verify overview amount is unchanged after decline delete item budget entries.
        SalesBudgetOverview.MATRIX.Field1.AssertEquals(Round(ItemBudgetEntry."Sales Amount", 1));  // Use 1 for Rounding Factor.
    end;

    [Test]
    [HandlerFunctions('DateCompItemBudgetEntriesHandler,DimensionSelectionHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure SalesBudgetOverviewWithCompressedItemBudgetEntries()
    var
        Customer: Record Customer;
        ItemBudgetEntry: Record "Item Budget Entry";
        SalesBudgetOverview: TestPage "Sales Budget Overview";
        RoundingFactor: Option "None","1","1000","1000000";
    begin
        // Test and verify Sales Budget Overview with compressed Item Budget Entries.

        // Setup: Create Item Budget Entries. Run Date Compress Item Budget Entries.
        Initialize();
        CreateItemBudgetEntryWithSourceNo(ItemBudgetEntry, FindItemBudgetName(), CreateItem(), LibrarySales.CreateCustomerNo());
        CreateItemBudgetEntryWithSourceNo(
          ItemBudgetEntry, ItemBudgetEntry."Budget Name", ItemBudgetEntry."Item No.", ItemBudgetEntry."Source No.");
        ItemBudgetEntry.SetRange("Item No.", ItemBudgetEntry."Item No.");
        RunDateCompressItemBudgetEntries(ItemBudgetEntry);

        // Exercise: Run Sales Budget Overview.
        RunSalesBudgetOverview(
          SalesBudgetOverview, ItemBudgetEntry."Budget Name", Customer.TableCaption(), ItemBudgetEntry."Item No.",
          ItemBudgetEntry."Source No.", RoundingFactor::"1");

        // Verify: Verify Amount must be zero on Sales Budget Overview Page.
        SalesBudgetOverview.MATRIX.Field1.AssertEquals(0);
    end;

    [Test]
    [HandlerFunctions('SalesAnalysisbyDimMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure SalesAnalysisByDimMatrixForBudgetAmount()
    var
        ItemAnalysisView: Record "Item Analysis View";
        ItemBudgetEntry: Record "Item Budget Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LibraryERM: Codeunit "Library - ERM";
        AnalysisViewListSales: TestPage "Analysis View List Sales";
    begin
        // Test to verify the Sales Amount and Quantity on Sales Analysis By Dim Matrix page with Budget.
        Initialize();

        // Setup: Create Item Analysis View. Create and post a Sales Order as Ship and Invoice. Create Item Budget entry. Open Analysis View List Sales page and invoke Update Item Analysis View.
        LibraryERM.CreateItemAnalysisView(ItemAnalysisView, ItemAnalysisView."Analysis Area"::Sales);
        CreateAndPostSalesOrder(SalesHeader, SalesLine);
        Quantity := SalesLine.Quantity;  // Quantity is made Global as it is used in handler for verification.
        Amount := SalesLine."Line Amount";  // Amount is made Global as it is used in handler for verification.
        CreateItemBudgetEntryWithSourceNo(ItemBudgetEntry, FindItemBudgetName(), SalesLine."No.", SalesHeader."Sell-to Customer No.");
        InvokeUpdateItemAnalysisViewOnAnalysisViewListSales(AnalysisViewListSales, ItemAnalysisView.Code);

        // Exercise: Open Sales Analysis By Dimensions page and invoke Show Matrix to open Sales Analysis By Dim Matrix page.
        InvokeShowMatrixOnSalesAnalysisByDimensions(AnalysisViewListSales, SalesLine."No.", ItemBudgetEntry."Budget Name");

        // Verify: Quantity and Amount on Sales Analysis by Dim Matrix page.
        // Verification is done in SalesAnalysisbyDimMatrixPageHandler.
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Item Budget");
        Clear(Quantity);
        Clear(Amount);

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Item Budget");
        LibraryFiscalYear.CreateClosedAccountingPeriods();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryApplicationArea.EnableItemBudgetSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Item Budget");
    end;

    local procedure CreateAndPostSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandDec(100, 2)); // Use Random Quantity.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Inventory Posting Group", FindInventoryPostingSetup());
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemBudgetEntry(var ItemBudgetEntry: Record "Item Budget Entry")
    begin
        LibraryInventory.CreateItemBudgetEntry(
          ItemBudgetEntry, ItemBudgetEntry."Analysis Area"::Sales, FindItemBudgetName(), WorkDate(), CreateItem());
        ItemBudgetEntry.Validate("Source Type", ItemBudgetEntry."Source Type"::Customer);
        ItemBudgetEntry.Validate("Source No.", LibrarySales.CreateCustomerNo());
        ItemBudgetEntry.Validate("Sales Amount", LibraryRandom.RandDec(100, 2));  // Use Random Value.
        ItemBudgetEntry.Modify(true);
    end;

    local procedure CreateItemBudgetEntryWithSourceNo(var ItemBudgetEntry: Record "Item Budget Entry"; BudgetName: Code[10]; ItemNo: Code[20]; SourceNo: Code[20])
    begin
        // Create Item Budget Entry with random Quantity, Cost Amount and Sales Amount.
        LibraryInventory.CreateItemBudgetEntry(
          ItemBudgetEntry, ItemBudgetEntry."Analysis Area"::Sales, BudgetName, LibraryFiscalYear.GetFirstPostingDate(true), ItemNo);
        ItemBudgetEntry.Validate("Source Type", ItemBudgetEntry."Source Type"::Customer);
        ItemBudgetEntry.Validate("Source No.", SourceNo);
        ItemBudgetEntry.Validate(Quantity, LibraryRandom.RandDec(100, 2));
        ItemBudgetEntry.Validate("Cost Amount", LibraryRandom.RandDec(100, 2));
        ItemBudgetEntry.Validate("Sales Amount", LibraryRandom.RandDec(100, 2));
        ItemBudgetEntry.Modify(true);
    end;

    local procedure FindInventoryPostingSetup(): Code[10]
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        InventoryPostingSetup.FindFirst();
        exit(InventoryPostingSetup."Invt. Posting Group Code");
    end;

    local procedure FindItemBudgetName(): Code[10]
    var
        ItemBudgetName: Record "Item Budget Name";
    begin
        ItemBudgetName.SetRange("Analysis Area", ItemBudgetName."Analysis Area"::Sales);
        ItemBudgetName.FindFirst();
        exit(ItemBudgetName.Name);
    end;

    local procedure InvokeShowMatrixOnSalesAnalysisByDimensions(AnalysisViewListSales: TestPage "Analysis View List Sales"; ItemNo: Code[20]; BudgetName: Code[10])
    var
        SalesAnalysisbyDimensions: TestPage "Sales Analysis by Dimensions";
    begin
        SalesAnalysisbyDimensions.Trap();
        AnalysisViewListSales.EditAnalysisView.Invoke();
        SalesAnalysisbyDimensions.ItemFilter.SetValue(ItemNo);
        SalesAnalysisbyDimensions.BudgetFilter.SetValue(BudgetName);
        SalesAnalysisbyDimensions.ShowMatrix_Process.Invoke();
    end;

    local procedure InvokeUpdateItemAnalysisViewOnAnalysisViewListSales(var AnalysisViewListSales: TestPage "Analysis View List Sales"; ItemAnalysisViewCode: Code[10])
    begin
        AnalysisViewListSales.OpenEdit();
        AnalysisViewListSales.FILTER.SetFilter(Code, ItemAnalysisViewCode);
        AnalysisViewListSales."&Update".Invoke();
    end;

    local procedure RunDateCompressItemBudgetEntries(var ItemBudgetEntry: Record "Item Budget Entry")
    var
        DateCompItemBudgetEntries: Report "Date Comp. Item Budget Entries";
    begin
        Commit();  // Commit required for batch reports.
        Clear(DateCompItemBudgetEntries);
        DateCompItemBudgetEntries.SetTableView(ItemBudgetEntry);
        DateCompItemBudgetEntries.Run();
    end;

    local procedure RunSalesBudgetOverview(var SalesBudgetOverview: TestPage "Sales Budget Overview"; CurrentBudgetName: Code[10]; ColumnDimCode: Text[30]; ItemFilter: Code[20]; CustomerFilter: Code[20]; RoundingFactor: Option)
    begin
        SalesBudgetOverview.OpenEdit();
        SalesBudgetOverview.CurrentBudgetName.SetValue(CurrentBudgetName);
        SalesBudgetOverview.ColumnDimCode.SetValue(ColumnDimCode);
        SalesBudgetOverview.ItemFilter.SetValue(ItemFilter);
        SalesBudgetOverview.SalesCodeFilterCtrl.SetValue(CustomerFilter);
        SalesBudgetOverview.RoundingFactor.SetValue(RoundingFactor);
        SalesBudgetOverview.ShowColumnName.SetValue(true);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DateCompItemBudgetEntriesHandler(var DateCompItemBudgetEntries: TestRequestPage "Date Comp. Item Budget Entries")
    var
        DateComprRegister: Record "Date Compr. Register";
        DateCompression: Codeunit "Date Compression";
    begin
        DateCompItemBudgetEntries.StartingDate.SetValue(LibraryFiscalYear.GetFirstPostingDate(true));
        DateCompItemBudgetEntries.EndingDate.SetValue(DateCompression.CalcMaxEndDate());
        DateCompItemBudgetEntries.PeriodLength.SetValue(DateComprRegister."Period Length"::Week);
        DateCompItemBudgetEntries.PostingDescription.SetValue(PostingDescription);
        DateCompItemBudgetEntries.RetainDimensions.AssistEdit();
        DateCompItemBudgetEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DimensionSelectionHandler(var DimensionSelectionMultiple: TestPage "Dimension Selection-Multiple")
    begin
        // Set Dimension Selection Multiple for all the rows.
        DimensionSelectionMultiple.First();
        repeat
            DimensionSelectionMultiple.Selected.SetValue(true);
        until not DimensionSelectionMultiple.Next();
        DimensionSelectionMultiple.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesAnalysisbyDimMatrixPageHandler(var SalesAnalysisbyDimMatrix: TestPage "Sales Analysis by Dim Matrix")
    begin
        SalesAnalysisbyDimMatrix.TotalQuantity.AssertEquals(-Quantity);
        SalesAnalysisbyDimMatrix.TotalInvtValue.AssertEquals(Amount);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerFalse(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;
}

