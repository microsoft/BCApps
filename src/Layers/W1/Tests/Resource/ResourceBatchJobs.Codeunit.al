codeunit 136402 "Resource Batch Jobs"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Resource]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryRandom: Codeunit "Library - Random";
        LibraryResource: Codeunit "Library - Resource";
        IsInitialized: Boolean;
        StartDate: Date;
        EndDate: Date;
        ResourceRegisterError: Label 'Resource Register must be deleted for %1 %2 .';
        EndingDateMissingErr: Label 'You must specify an ending date.';

    local procedure Initialize()
    var
        LibraryService: Codeunit "Library - Service";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Resource Batch Jobs");
        // Clear global variable.
        Clear(StartDate);
        Clear(EndDate);

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Resource Batch Jobs");

        LibraryService.SetupServiceMgtNoSeries();
        LibraryERMCountryData.CreateVATData();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Resource Batch Jobs");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestPriceChangeResource()
    var
        Resource: Record Resource;
        SuggestResPriceChgRes: Report "Suggest Res. Price Chg. (Res.)";
        UnitPriceFactor: Decimal;
    begin
        // Test Resource Price Change after running Suggest Res. Price Chg. Res. Batch Job.

        // 1. Setup: Create Resource with Unit Price.
        Initialize();
        CreateResourceWithUnitPrice(Resource);
        UnitPriceFactor := LibraryRandom.RandDec(10, 2);  // Use Random because value is not important.

        // 2. Exercise: Run Suggest Res. Price Chg. Res. Batch Job.
        Clear(SuggestResPriceChgRes);
        Resource.SetRange("No.", Resource."No.");
        SuggestResPriceChgRes.SetTableView(Resource);
        SuggestResPriceChgRes.InitializeRequest(0, UnitPriceFactor, '', true);
        SuggestResPriceChgRes.UseRequestPage(false);
        SuggestResPriceChgRes.Run();

        // 3. Verify: Verify New Unit Price on Resource Price Change.
        VerifyResourcePriceChange(Resource."No.", 0, Resource."Unit Price" * UnitPriceFactor);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestPriceChangePrice()
    var
        Resource: Record Resource;
        UnitPriceFactor: Decimal;
        UnitPrice: Decimal;
    begin
        // Test Resource Price Change after running Suggest Res. Price Chg. Price Batch Job.

        // 1. Setup: Create Resource and Resource Price with Unit Price.
        Initialize();
        CreateResourceWithUnitPrice(Resource);
        UnitPrice := CreateResourcePrice(Resource."No.");
        UnitPriceFactor := LibraryRandom.RandDec(10, 2);  // Use Random because value is not important.

        // 2. Exercise: Run Suggest Res. Price Chg. Price Batch Job.
        RunSuggestResPriceChgPrice(Resource."No.", UnitPriceFactor);

        // 3. Verify: Verify New Unit Price and Current Unit Price on Resource Price Change.
        VerifyResourcePriceChange(Resource."No.", UnitPrice, UnitPrice * UnitPriceFactor);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure ImplementResourcePriceChange()
    var
        Resource: Record Resource;
        ResourcePriceChange: Record "Resource Price Change";
        ImplementResPriceChange: Report "Implement Res. Price Change";
        UnitPriceFactor: Decimal;
        UnitPrice: Decimal;
    begin
        // Test Resource Price after running Implement Res. Price Change Batch Job.

        // 1. Setup: Create Resource and Resource Price with Unit Price.
        Initialize();
        CreateResourceWithUnitPrice(Resource);
        UnitPrice := CreateResourcePrice(Resource."No.");
        UnitPriceFactor := LibraryRandom.RandDec(10, 2);  // Use Random because value is not important.

        // 2. Exercise: Run Suggest Res. Price Chg. Price and Implement Res. Price Change Batch Jobs.
        RunSuggestResPriceChgPrice(Resource."No.", UnitPriceFactor);
        Clear(ImplementResPriceChange);
        ResourcePriceChange.SetRange(Type, ResourcePriceChange.Type::Resource);
        ResourcePriceChange.SetRange(Code, Resource."No.");
        ImplementResPriceChange.SetTableView(ResourcePriceChange);
        ImplementResPriceChange.UseRequestPage(false);
        ImplementResPriceChange.Run();

        // 3. Verify: Verify Unit Price on Resource Price.
        VerifyResourcePrice(Resource."No.", UnitPrice * UnitPriceFactor);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdjustResourceCostsPrice()
    var
        Selection: Option "Direct Unit Cost","Indirect Cost %","Unit Cost","Profit %","Unit Price";
    begin
        // Test Direct Unit Cost after running Adjust Resource Costs Prices Batch Job with Direct Unit Cost.
        Initialize();
        RunAdjustCostPriceBatchJobAndValidateData(Selection::"Direct Unit Cost", '', 0.0);
    end;

    [Test]
    [HandlerFunctions('DateCompressResourceLedgerHandler')]
    [Scope('OnPrem')]
    procedure DateCompressWithoutStartEndDate()
    var
        Resource: Record Resource;
        NoOfUnCompressedYears: Integer;
    begin
        // Test Functionality of Date Compress Resource Ledger without Start date and End Date.

        // 1. Setup: Create Resource.
        Initialize();
        CreateResourceWithUnitPrice(Resource);
        NoOfUnCompressedYears := 5;

        // 2. Exercise: Run Date Compress Resource Ledger report without start date and end date.
        StartDate := 0D;
        EndDate := 0D;
        Commit();  // Commit needs before run Date Compress Resource Ledger report.
        asserterror DateCompressResourceJournal(Resource."No.");

        // 3. Verify: Check expected ERROR must be come for End date.
        Assert.ExpectedError(EndingDateMissingErr);
    end;

    [Test]
    [HandlerFunctions('DateCompressResourceLedgerHandler,ConfirmMessageHandlerTRUE,MessageHandler,DimensionSelectionHandler')]
    [Scope('OnPrem')]
    procedure DateCompressWithStartEndDate()
    var
        Resource: Record Resource;
    begin
        // Test Functionality of Date Compress Resource Ledger with Start date and End date.

        // 1. Setup: Create Resource, Resource Journal Line and Post.
        Initialize();
        CreateResourceWithUnitPrice(Resource);
        CreateAndPostResourceJournalLine(Resource."No.");

        // 2. Exercise: Run Date Compress Resource Ledger report with start date and end date.
        DateCompressResourceJournal(Resource."No.");

        // 3. Verify: Check Resource Ledger Entry with Resource.
        VerifyResourceLedgerEntry(Resource."No.");
    end;

    [Test]
    [HandlerFunctions('DateCompressResourceLedgerHandler,MessageHandler,DimensionSelectionHandler,ConfirmMessageHandlerTRUE')]
    [Scope('OnPrem')]
    procedure DeleteEmptyResourceRegisters()
    var
        Resource: Record Resource;
        ResourceRegister: Record "Resource Register";
        JournalBatchName: Code[20];
    begin
        // Check Resource Register deleted after running Delete Empty Resource Registers Batch job.

        // 1. Setup: Create Resource, Resource Journal Line and Post.
        Initialize();
        CreateResourceWithUnitPrice(Resource);
        JournalBatchName := CreateAndPostResourceJournalLine(Resource."No.");

        // Run Date Compress Resource Ledger report with start date and end date.
        DateCompressResourceJournal(Resource."No.");

        // 2. Exercise: Run Delete Empty Resource Registers Batch job.
        RunDeleteEmptyResourceRegisters();

        // 3. Verify: Resource Register must be deleted after run Delete Empty Resource Ledger report.
        Assert.IsFalse(
          FindResourceRegister(JournalBatchName),
          StrSubstNo(ResourceRegisterError, ResourceRegister.FieldCaption("Journal Batch Name"), JournalBatchName));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdjustResourceUnitPrice()
    var
        RoundingMethod: Record "Rounding Method";
        Selection: Option "Direct Unit Cost","Indirect Cost %","Unit Cost","Profit %","Unit Price";
    begin
        // Test Unit Price after running Adjust Resource Costs Prices Batch Job with Unit Price.
        Initialize();
        RoundingMethod.FindFirst();
        RunAdjustCostPriceBatchJobAndValidateData(Selection::"Unit Price", RoundingMethod.Code, RoundingMethod.Precision);
    end;

    local procedure RunAdjustCostPriceBatchJobAndValidateData(Selection: Option "Direct Unit Cost","Indirect Cost %","Unit Cost","Profit %","Unit Price"; RoundingMethod: Code[10]; Precision: Decimal)
    var
        Resource: Record Resource;
        Resource2: Record Resource;
        AdjustResourceCostsPrices: Report "Adjust Resource Costs/Prices";
        UnitPriceFactor: Decimal;
    begin
        // 1. Setup: Create Resource with Unit Price.
        CreateResourceWithUnitPrice(Resource);
        UnitPriceFactor := LibraryRandom.RandDec(10, 2);  // Use Random because value is not important.

        // 2. Exercise: Run Adjust Resource Costs Prices Batch Job with Unit Price.
        Clear(AdjustResourceCostsPrices);
        Resource.SetRange("No.", Resource."No.");
        AdjustResourceCostsPrices.SetTableView(Resource);
        AdjustResourceCostsPrices.InitializeRequest(Selection, UnitPriceFactor, RoundingMethod);
        AdjustResourceCostsPrices.UseRequestPage(false);
        AdjustResourceCostsPrices.Run();

        // 3. Verify: Verify Unit Price on Resource.
        Resource2.Get(Resource."No.");
        if Selection = Selection::"Direct Unit Cost" then
            Resource2.TestField("Direct Unit Cost", Resource."Direct Unit Cost" * UnitPriceFactor)
        else
            Resource2.TestField("Unit Price", Round(Resource."Unit Price" * UnitPriceFactor, Precision));
    end;

    local procedure CreateResourcePrice(ResourceNo: Code[20]): Decimal
    var
        ResourcePrice: Record "Resource Price";
    begin
        LibraryResource.CreateResourcePrice(ResourcePrice, ResourcePrice.Type::Resource, ResourceNo, '', '');
        ResourcePrice.Validate("Unit Price", LibraryRandom.RandDec(100, 2));  // Use Random because value is not important.
        ResourcePrice.Modify(true);
        exit(ResourcePrice."Unit Price");
    end;

    local procedure CreateAndPostResourceJournalLine(ResourceNo: Code[20]): Code[20]
    var
        ResJournalBatch: Record "Res. Journal Batch";
        ResJournalLine: Record "Res. Journal Line";
        ResJournalTemplate: Record "Res. Journal Template";
    begin
        LibraryFiscalYear.CreateClosedAccountingPeriods();
        StartDate := DMY2Date(1, 1, Date2DMY(Today(), 3) - 6);
        EndDate := CalcDate('<+CY>', StartDate);

        LibraryResource.CreateResourceJournalTemplate(ResJournalTemplate);
        LibraryResource.CreateResourceJournalBatch(ResJournalBatch, ResJournalTemplate.Name);
        LibraryResource.CreateResJournalLine(ResJournalLine, ResJournalTemplate.Name, ResJournalBatch.Name);
        ResJournalLine.Validate("Posting Date", StartDate);
        ResJournalLine.Validate("Resource No.", ResourceNo);
        ResJournalLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));  // Value is not important here.
        ResJournalLine.Validate("Document No.", ResourceNo);
        ResJournalLine.Modify(true);
        LibraryResource.PostResourceJournalLine(ResJournalLine);
        LibraryFiscalYear.CloseFiscalYear();
        exit(ResJournalBatch.Name);
    end;

    local procedure CreateResourceWithUnitPrice(var Resource: Record Resource)
    begin
        LibraryResource.CreateResourceNew(Resource);
    end;

    local procedure DateCompressResourceJournal(ResourceNo: Code[20])
    var
        ResLedgerEntry: Record "Res. Ledger Entry";
        DateCompressResourceLedger: Report "Date Compress Resource Ledger";
    begin
        Commit(); // required for CH
        Clear(DateCompressResourceLedger);
        ResLedgerEntry.SetRange("Resource No.", ResourceNo);
        DateCompressResourceLedger.SetTableView(ResLedgerEntry);
        DateCompressResourceLedger.Run();
    end;

    local procedure FindResourceRegister(JournalBatchName: Code[20]): Boolean
    var
        ResourceRegister: Record "Resource Register";
    begin
        ResourceRegister.SetRange("Journal Batch Name", JournalBatchName);
        exit(ResourceRegister.FindFirst())
    end;

    local procedure RunDeleteEmptyResourceRegisters()
    var
        DeleteEmptyResRegisters: Report "Delete Empty Res. Registers";
    begin
        DeleteEmptyResRegisters.UseRequestPage(false);
        DeleteEmptyResRegisters.Run();
    end;

    local procedure RunSuggestResPriceChgPrice("Code": Code[20]; UnitPriceFactor: Decimal)
    var
        ResourcePrice: Record "Resource Price";
        SuggestResPriceChgPrice: Report "Suggest Res. Price Chg.(Price)";
    begin
        Clear(SuggestResPriceChgPrice);
        ResourcePrice.SetRange(Type, ResourcePrice.Type::Resource);
        ResourcePrice.SetRange(Code, Code);
        SuggestResPriceChgPrice.SetTableView(ResourcePrice);
        SuggestResPriceChgPrice.InitializeRequest(0, UnitPriceFactor, '', true);
        SuggestResPriceChgPrice.UseRequestPage(false);
        SuggestResPriceChgPrice.Run();
    end;

    local procedure VerifyResourceLedgerEntry(ResourceNo: Code[20])
    var
        ResLedgerEntry: Record "Res. Ledger Entry";
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        ResLedgerEntry.SetRange("Resource No.", ResourceNo);
        ResLedgerEntry.SetRange("Source Code", SourceCodeSetup."Compress Res. Ledger");
        ResLedgerEntry.FindFirst();
    end;

    local procedure VerifyResourcePrice("Code": Code[20]; UnitPrice: Decimal)
    var
        ResourcePrice: Record "Resource Price";
    begin
        ResourcePrice.SetRange(Type, ResourcePrice.Type::Resource);
        ResourcePrice.SetRange(Code, Code);
        ResourcePrice.FindFirst();
        ResourcePrice.TestField("Unit Price", UnitPrice);
    end;

    local procedure VerifyResourcePriceChange("Code": Code[20]; CurrentUnitPrice: Decimal; NewUnitPrice: Decimal)
    var
        ResourcePriceChange: Record "Resource Price Change";
    begin
        ResourcePriceChange.SetRange(Type, ResourcePriceChange.Type::Resource);
        ResourcePriceChange.SetRange(Code, Code);
        ResourcePriceChange.FindFirst();
        ResourcePriceChange.TestField("Current Unit Price", CurrentUnitPrice);
        ResourcePriceChange.TestField("New Unit Price", NewUnitPrice);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmMessageHandler(Question: Text[1024]; var Reply: Boolean)
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DateCompressResourceLedgerHandler(var DateCompressResourceLedger: TestRequestPage "Date Compress Resource Ledger")
    begin
        DateCompressResourceLedger.StartingDate.SetValue(StartDate);
        DateCompressResourceLedger.EndingDate.SetValue(EndDate);
        DateCompressResourceLedger.RetainDimensions.AssistEdit();
        DateCompressResourceLedger.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmMessageHandlerTRUE(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
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
}

