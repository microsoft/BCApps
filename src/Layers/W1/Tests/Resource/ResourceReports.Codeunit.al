codeunit 136902 "Resource Reports"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Reports] [Resource]
        isInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryResource: Codeunit "Library - Resource";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryService: Codeunit "Library - Service";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        TextErr: Label 'Recurring Method must be specified.';
        ValidationErr: Label '%1 must be %2 .';

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Resource Reports");
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Resource Reports");

        LibraryService.SetupServiceMgtNoSeries();
        LibraryERMCountryData.CreateVATData();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Resource Reports");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,ResourceRegisterReportHandler')]
    [Scope('OnPrem')]
    procedure ResourceRegisterReport()
    var
        ResJournalBatch: Record "Res. Journal Batch";
        ResJournalLine: Record "Res. Journal Line";
        Resource: Record Resource;
        Resource2: Record Resource;
        ResourceRegister: Record "Resource Register";
        ResourceRegisterReport: Report "Resource Register";
    begin
        // Test and verify Resource Register Report.

        // 1. Setup: Create two Resource, Resource Journal Batch,
        // Create and Post two Resource Journal Lines with different Resource No.
        Initialize();
        CreateResource(Resource);
        CreateResource(Resource2);

        CreateResourceJournalBatch(ResJournalBatch, false);
        CreateResourceJournalLine(ResJournalLine, ResJournalBatch, Resource."No.", '', ResJournalLine."Entry Type"::Usage);
        CreateResourceJournalLine(ResJournalLine, ResJournalBatch, Resource2."No.", '', ResJournalLine."Entry Type"::Usage);

        LibraryResource.PostResourceJournalLine(ResJournalLine);

        // 2. Exercise: Run the Resource Register Report.
        Clear(ResourceRegisterReport);
        ResourceRegister.SetRange("Journal Batch Name", ResJournalBatch.Name);
        ResourceRegisterReport.SetTableView(ResourceRegister);
        ResourceRegisterReport.Run();

        // 3. Verify: Verify values on Resource Register Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyResourceRegister(Resource."No.");
        VerifyResourceRegister(Resource2."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,ResourceCostBreakdownReportHandler')]
    [Scope('OnPrem')]
    procedure ResourceCostBreakdown()
    var
        ResJournalLine: Record "Res. Journal Line";
        ResJournalBatch: Record "Res. Journal Batch";
        Resource: Record Resource;
        WorkType: Record "Work Type";
        WorkType2: Record "Work Type";
        ResourceCostBreakdown: Report "Resource - Cost Breakdown";
    begin
        // Test and verify Resource - Cost Breakdown Report.

        // 1. Setup: Create Resource, two Work Type, Resource Journal Batch,
        // Create and Post two Resource Journal Lines with same Resource No. and different Work Type Code.
        Initialize();
        CreateResource(Resource);
        LibraryResource.CreateWorkType(WorkType);
        LibraryResource.CreateWorkType(WorkType2);

        ModifyUnitOfMeasureOnWorkType(WorkType, Resource."Base Unit of Measure");
        ModifyUnitOfMeasureOnWorkType(WorkType2, Resource."Base Unit of Measure");

        CreateResourceJournalBatch(ResJournalBatch, false);
        CreateResourceJournalLine(ResJournalLine, ResJournalBatch, Resource."No.", WorkType.Code, ResJournalLine."Entry Type"::Usage);
        CreateResourceJournalLine(ResJournalLine, ResJournalBatch, Resource."No.", WorkType2.Code, ResJournalLine."Entry Type"::Usage);
        LibraryResource.PostResourceJournalLine(ResJournalLine);

        // 2. Exercise: Run the Resource - Cost Breakdown Report.
        Clear(ResourceCostBreakdown);
        Resource.SetRange("No.", Resource."No.");
        ResourceCostBreakdown.SetTableView(Resource);
        ResourceCostBreakdown.Run();

        // 3. Verify: Verify values on Resource - Cost Breakdown Report.
        VerifyResourceCostBreakDown(Resource."No.", WorkType.Code, WorkType2.Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,ResourceUsageReportHandler')]
    [Scope('OnPrem')]
    procedure ResourceUsage()
    var
        ResJournalBatch: Record "Res. Journal Batch";
        ResJournalLine: Record "Res. Journal Line";
        Resource: Record Resource;
        ResourceUsage: Report "Resource Usage";
    begin
        // Test and verify Resource Usage Report.

        // 1. Setup: Create Resource, Resource Journal Batch and Create and Post Resource Journal Line with Resource.
        Initialize();
        CreateResource(Resource);

        CreateResourceJournalBatch(ResJournalBatch, false);
        CreateResourceJournalLine(ResJournalLine, ResJournalBatch, Resource."No.", '', ResJournalLine."Entry Type"::Usage);
        LibraryResource.PostResourceJournalLine(ResJournalLine);

        // 2. Exercise: Run the Resource Usage Report.
        Clear(ResourceUsage);
        Resource.SetRange("No.", Resource."No.");
        ResourceUsage.SetTableView(Resource);
        ResourceUsage.Run();

        // 3. Verify: Verify values on Resource Usage Report.
        VerifyResourceUsage(Resource);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,ResourceStatisticsReportHandler')]
    [Scope('OnPrem')]
    procedure ResourceStatistics()
    var
        ResJournalBatch: Record "Res. Journal Batch";
        ResJournalLine: Record "Res. Journal Line";
        Resource: Record Resource;
        Resource2: Record Resource;
        ResourceStatistics: Report "Resource Statistics";
    begin
        // Test and verify Resource Statistics Report.

        // 1. Setup: Create two Resource, Resource Journal Batch,
        // Create and Post Resource Journal Lines with different Resource No. and Entry Type.
        Initialize();
        CreateResource(Resource);
        CreateResource(Resource2);

        CreateResourceJournalBatch(ResJournalBatch, false);
        CreateResourceJournalLine(ResJournalLine, ResJournalBatch, Resource."No.", '', ResJournalLine."Entry Type"::Usage);
        CreateResourceJournalLine(ResJournalLine, ResJournalBatch, Resource."No.", '', ResJournalLine."Entry Type"::Sale);

        CreateResourceJournalLine(ResJournalLine, ResJournalBatch, Resource2."No.", '', ResJournalLine."Entry Type"::Usage);
        CreateResourceJournalLine(ResJournalLine, ResJournalBatch, Resource2."No.", '', ResJournalLine."Entry Type"::Sale);
        LibraryResource.PostResourceJournalLine(ResJournalLine);

        // 2. Exercise: Run the Resource Statistics Report.
        Clear(ResourceStatistics);
        Resource.SetFilter("No.", '%1|%2', Resource."No.", Resource2."No.");
        ResourceStatistics.SetTableView(Resource);
        ResourceStatistics.Run();

        // 3. Verify: Verify values on Resource Statistics Report.
        VerifyResourceStatistics(Resource, Resource2);
    end;

    [Test]
    [HandlerFunctions('ResourceJournalTestReportHandler')]
    [Scope('OnPrem')]
    procedure ResourceJournalTest()
    var
        ResJournalBatch: Record "Res. Journal Batch";
        ResJournalLine: Record "Res. Journal Line";
        Resource: Record Resource;
        Resource2: Record Resource;
    begin
        // Test and verify Resource Journal - Test Report.

        // 1. Setup: Create two Resource, Resource Journal Batch and Resource Journal Lines with different Resource No.
        Initialize();
        CreateResource(Resource);
        CreateResource(Resource2);

        CreateResourceJournalBatch(ResJournalBatch, false);
        CreateResourceJournalLine(ResJournalLine, ResJournalBatch, Resource."No.", '', ResJournalLine."Entry Type"::Usage);
        CreateResourceJournalLine(ResJournalLine, ResJournalBatch, Resource2."No.", '', ResJournalLine."Entry Type"::Usage);

        // 2. Exercise: Run the Resource Journal - Test Report.
        RunResourceJournalTestReport(ResJournalBatch."Journal Template Name", ResJournalBatch.Name, false);

        // 3. Verify: Verify values on Resource Journal - Test Report.
        VerifyResourceJournalTest(Resource."No.", Resource2."No.");
    end;

    [Test]
    [HandlerFunctions('ResourceJournalTestReportHandler')]
    [Scope('OnPrem')]
    procedure ResourceJournalTestDimension()
    var
        DefaultDimension: Record "Default Dimension";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        ResJournalBatch: Record "Res. Journal Batch";
        ResJournalLine: Record "Res. Journal Line";
        Resource: Record Resource;
        ResourceJournalTest: Report "Resource Journal - Test";
        LibraryDimension: Codeunit "Library - Dimension";
    begin
        // Test and verify Resource Journal - Test Report with Show Dimension as True.

        // 1. Setup: Create Resource, Default Dimension for Resource, Resource Journal Batch and Resource Journal Line.
        Initialize();
        CreateResource(Resource);
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::Resource, Resource."No.", Dimension.Code, DimensionValue.Code);

        CreateResourceJournalBatch(ResJournalBatch, false);
        CreateResourceJournalLine(ResJournalLine, ResJournalBatch, Resource."No.", '', ResJournalLine."Entry Type"::Usage);

        // 2. Exercise: Run the Resource Journal - Test Report.
        Commit();
        ResourceJournalTest.SetTableView(ResJournalBatch);
        ResourceJournalTest.InitializeRequest(true);
        ResourceJournalTest.Run();

        // 3. Verify: Verify values on Resource Journal - Test Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Name_ResJnlBatch', ResJournalBatch.Name);
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the journal batch name');
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'DimText', StrSubstNo('%1 - %2', DimensionValue."Dimension Code", DimensionValue.Code));
    end;

    [Test]
    [HandlerFunctions('ResourceJournalTestReportHandler')]
    [Scope('OnPrem')]
    procedure ResourceJournalTestWarning()
    var
        ResJournalBatch: Record "Res. Journal Batch";
        ResJournalLine: Record "Res. Journal Line";
        Resource: Record Resource;
    begin
        // Test and verify Warnings on Resource Journal - Test Report.

        // 1. Setup: Create Resource, Resource Journal Batch with Recurring Resource Journal Template
        // Create Resource Journal Line.
        Initialize();
        CreateResource(Resource);
        CreateResourceJournalBatch(ResJournalBatch, true);
        CreateResourceJournalLine(ResJournalLine, ResJournalBatch, Resource."No.", '', ResJournalLine."Entry Type"::Usage);

        // 2. Exercise: Run the Resource Journal - Test Report.
        RunResourceJournalTestReport(ResJournalBatch."Journal Template Name", ResJournalBatch.Name, false);

        // 3. Verify: Verify values on Resource Journal - Test Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('ResNo_ResJnlLine', Resource."No.");
        LibraryReportDataset.SetRange('ErrorTextNumber', TextErr);
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the resource no and error text');
    end;

    [Test]
    [HandlerFunctions('ResourceListReportHandler')]
    [Scope('OnPrem')]
    procedure ResourceListReport()
    var
        Resource: Record Resource;
        ResourceList: Report "Resource - List";
    begin
        // Test and verify Resource List Report.

        // 1. Setup: Create Resource, Attach Resource Group and Global Dimensions.
        Initialize();
        CreateResource(Resource);
        InputResourceGroupOnResource(Resource);
        AttachResourceGlobalDimensions(Resource);

        // 2. Exercise: Run the Resource List Report.
        Commit();
        Clear(ResourceList);
        Resource.SetRange("No.", Resource."No.");
        ResourceList.SetTableView(Resource);
        ResourceList.Run();

        // 3. Verify: Verify values on Resource List Report.
        VerifyResource(Resource);
    end;

    [Test]
    [HandlerFunctions('ResourcePriceListReportHandler')]
    [Scope('OnPrem')]
    procedure ResourcePriceListReport()
    var
        Resource: Record Resource;
        ResourcePrice: Record "Resource Price";
        WorkType: Record "Work Type";
        ResourcePriceList: Report "Resource - Price List";
    begin
        // Test and verify Resource - Price List Report.

        // 1. Setup: Create Resource, Work Type and Resource Price.
        Initialize();
        CreateResource(Resource);
        LibraryResource.CreateWorkType(WorkType);
        CreateResourcePrice(ResourcePrice, Resource."No.", WorkType.Code);

        // 2. Exercise: Run the Resource - Price List Report.
        Commit();
        Clear(ResourcePriceList);
        Resource.SetRange("No.", Resource."No.");
        ResourcePriceList.SetTableView(Resource);
        ResourcePriceList.Run();

        // 3. Verify: Verify values on Resource - Price List Report.
        VerifyResourcePriceList(ResourcePrice, Resource."Unit Price");
    end;

    [Test]
    [HandlerFunctions('ResourcePriceListReportHandler')]
    [Scope('OnPrem')]
    procedure ResourcePriceListWithCurrency()
    var
        Resource: Record Resource;
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        Value: Variant;
        ActualUnitPrice: Decimal;
    begin
        // Test and verify Resource - Price List Report with Currency.

        // 1. Setup: Create Resource, Currency and Currency Exchange Rate.
        Initialize();
        CreateResource(Resource);
        LibraryERM.CreateCurrency(Currency);
        CreateCurrencyExchangeRate(CurrencyExchangeRate, Currency.Code);

        // Calculation for Actual Unit Price is taken from Report.
        ActualUnitPrice :=
          Round(
            CurrencyExchangeRate.ExchangeAmtLCYToFCY(
              WorkDate(), Currency.Code, Resource."Unit Price",
              CurrencyExchangeRate.ExchangeRate(WorkDate(), Currency.Code)),
            Currency."Unit-Amount Rounding Precision");

        // 2. Exercise: Run the Resource - Price List Report with Currency.
        RunResourcePriceListReport(Resource."No.", Currency.Code);

        // 3. Verify: Verify values on Resource - Price List Report with Currency.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Resource', Resource."No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the resource no');

        LibraryReportDataset.FindCurrentRowValue('UnitPrice_Resource', Value);
        Assert.AreNearlyEqual(
          ActualUnitPrice,
          Value,
          Currency."Unit-Amount Rounding Precision",
          StrSubstNo(ValidationErr, Resource.FieldCaption("Unit Price"), ActualUnitPrice));
    end;

    local procedure AttachResourceGlobalDimensions(var Resource: Record Resource)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionValue: Record "Dimension Value";
        LibraryDimension: Codeunit "Library - Dimension";
    begin
        GeneralLedgerSetup.Get();
        LibraryDimension.FindDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 1 Code");
        Resource.Validate("Global Dimension 1 Code", DimensionValue.Code);

        LibraryDimension.FindDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 2 Code");
        Resource.Validate("Global Dimension 2 Code", DimensionValue.Code);
        Resource.Modify(true);
    end;

    local procedure CreateCurrencyExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate"; CurrencyCode: Code[10])
    begin
        // Create Currency Exchange Rate with Exchange Rate Amount, Relational Exch. Rate Amount as Random values.
        LibraryERM.CreateExchRate(CurrencyExchangeRate, CurrencyCode, WorkDate());
        CurrencyExchangeRate.Validate("Exchange Rate Amount", LibraryRandom.RandDec(10, 2));
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");

        // Relational Exch. Rate Amount is always greater than Exchange Rate Amount.
        CurrencyExchangeRate.Validate(
          "Relational Exch. Rate Amount",
          LibraryRandom.RandDec(10, 2) + CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount");
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure CreateResource(var Resource: Record Resource)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryResource.CreateResource(Resource, VATPostingSetup."VAT Bus. Posting Group");

        // Use Random because value is not important.
        Resource.Validate(Capacity, LibraryRandom.RandDec(10, 2));
        Resource.Modify(true);
    end;

    local procedure CreateResourceJournalBatch(var ResJournalBatch: Record "Res. Journal Batch"; Recurring: Boolean)
    var
        ResJournalTemplate: Record "Res. Journal Template";
    begin
        ResJournalTemplate.SetRange(Recurring, Recurring);
        LibraryResource.FindResJournalTemplate(ResJournalTemplate);
        LibraryResource.CreateResourceJournalBatch(ResJournalBatch, ResJournalTemplate.Name);
    end;

    local procedure CreateResourceJournalLine(var ResJournalLine: Record "Res. Journal Line"; ResJournalBatch: Record "Res. Journal Batch"; ResourceNo: Code[20]; WorkTypeCode: Code[10]; EntryType: Enum "Res. Journal Line Entry Type")
    begin
        LibraryResource.CreateResJournalLine(ResJournalLine, ResJournalBatch."Journal Template Name", ResJournalBatch.Name);
        ResJournalLine.Validate("Posting Date", WorkDate());
        ResJournalLine.Validate("Entry Type", EntryType);
        ResJournalLine.Validate("Resource No.", ResourceNo);
        ResJournalLine.Validate("Work Type Code", WorkTypeCode);

        // Use Document No. as Resource No. value is not important.
        ResJournalLine.Validate("Document No.", ResourceNo);

        // Use Random because value is not important.
        ResJournalLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));
        ResJournalLine.Modify(true);
    end;

    local procedure CreateResourcePrice(var ResourcePrice: Record "Resource Price"; ResourceNo: Code[20]; WorkTypeCode: Code[10])
    begin
        LibraryResource.CreateResourcePrice(ResourcePrice, ResourcePrice.Type, ResourceNo, WorkTypeCode, '');

        // Use Random because value is not important.
        ResourcePrice.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ResourcePrice.Modify(true);
    end;

    local procedure InputResourceGroupOnResource(var Resource: Record Resource)
    var
        ResourceGroup: Record "Resource Group";
    begin
        LibraryResource.CreateResourceGroup(ResourceGroup);
        Resource.Validate("Resource Group No.", ResourceGroup."No.");
        Resource.Modify(true);
    end;

    local procedure RunResourceJournalTestReport(JournalTemplateName: Code[10]; Name: Code[10]; ShowDimensions: Boolean)
    var
        ResJournalBatch: Record "Res. Journal Batch";
        ResourceJournalTest: Report "Resource Journal - Test";
    begin
        Clear(ResourceJournalTest);
        Commit();
        ResJournalBatch.SetRange("Journal Template Name", JournalTemplateName);
        ResJournalBatch.SetRange(Name, Name);
        ResourceJournalTest.SetTableView(ResJournalBatch);
        ResourceJournalTest.InitializeRequest(ShowDimensions);
        ResourceJournalTest.Run();
    end;

    local procedure RunResourcePriceListReport(No: Code[20]; CurrencyCode: Code[10])
    var
        Resource: Record Resource;
        ResourcePriceList: Report "Resource - Price List";
    begin
        Commit();
        Clear(ResourcePriceList);
        Resource.SetRange("No.", No);
        ResourcePriceList.SetTableView(Resource);
        ResourcePriceList.InitializeRequest(CurrencyCode);
        ResourcePriceList.Run();
    end;

    local procedure ModifyUnitOfMeasureOnWorkType(WorkType: Record "Work Type"; UnitOfMeasureCode: Code[10])
    begin
        WorkType.Validate("Unit of Measure Code", UnitOfMeasureCode);
        WorkType.Modify(true);
    end;

    local procedure VerifyResource(Resource: Record Resource)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Resource__No__', Resource."No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the resource no');

        LibraryReportDataset.AssertCurrentRowValueEquals('Resource__Resource_Group_No__', Resource."Resource Group No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Resource__Gen__Prod__Posting_Group_', Resource."Gen. Prod. Posting Group");
        LibraryReportDataset.AssertCurrentRowValueEquals('Resource__Global_Dimension_1_Code_', Resource."Global Dimension 1 Code");
        LibraryReportDataset.AssertCurrentRowValueEquals('Resource__Global_Dimension_2_Code_', Resource."Global Dimension 2 Code");
    end;

    local procedure VerifyResourceCostBreakDown(ResourceNo: Code[20]; WorkTypeCode: Code[10]; WorkTypeCode2: Code[10])
    var
        ResLedgerEntry: Record "Res. Ledger Entry";
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No1_Resource', ResourceNo);
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the resource no');

        // Verify First Row Values on Resource - Cost Breakdown Report.
        ResLedgerEntry.SetRange("Work Type Code", WorkTypeCode);
        ResLedgerEntry.FindFirst();
        VerifyResourceCostBreakDownRow(ResLedgerEntry);

        // Verify Second Row Values on Resource - Cost Breakdown Report.
        ResLedgerEntry.SetRange("Work Type Code", WorkTypeCode2);
        ResLedgerEntry.FindFirst();
        VerifyResourceCostBreakDownRow(ResLedgerEntry);
    end;

    local procedure VerifyResourceCostBreakDownRow(ResLedgerEntry: Record "Res. Ledger Entry")
    begin
        LibraryReportDataset.SetRange('WorkTypeCode_ResLedgEntry', ResLedgerEntry."Work Type Code");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the work type code');

        LibraryReportDataset.AssertCurrentRowValueEquals('Qty_ResLedgEntry', ResLedgerEntry.Quantity);
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalCost_ResLedgEntry', ResLedgerEntry."Total Cost");
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalDirectCost', ResLedgerEntry.Quantity * ResLedgerEntry."Direct Unit Cost");
    end;

    local procedure VerifyResourceJournalTest(ResourceNo: Code[20]; ResourceNo2: Code[20])
    var
        ResJournalLine: Record "Res. Journal Line";
    begin
        LibraryReportDataset.LoadDataSetFile();

        // Verify First Row Values on Resource Journal - Test Report.
        ResJournalLine.SetRange("Resource No.", ResourceNo);
        ResJournalLine.FindFirst();
        VerifyResourceJournalTestRow(ResJournalLine);

        // Verify Second Row Values on Resource Journal - Test Report.
        ResJournalLine.SetRange("Resource No.", ResourceNo2);
        ResJournalLine.FindFirst();
        VerifyResourceJournalTestRow(ResJournalLine);
    end;

    local procedure VerifyResourceJournalTestRow(ResJournalLine: Record "Res. Journal Line")
    begin
        LibraryReportDataset.SetRange('ResNo_ResJnlLine', ResJournalLine."Resource No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the work type code');

        LibraryReportDataset.AssertCurrentRowValueEquals('Qty_ResJnlLine', ResJournalLine.Quantity);
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalCost_ResJnlLine', ResJournalLine."Total Cost");
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalPrice_ResJnlLine', ResJournalLine."Total Price");
    end;

    local procedure VerifyResourcePriceList(ResourcePrice: Record "Resource Price"; ResourceUnitPrice: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Resource', ResourcePrice.Code);
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the work type code');
        LibraryReportDataset.AssertCurrentRowValueEquals('UnitPrice_Resource', ResourceUnitPrice);

        LibraryReportDataset.Reset();
        LibraryReportDataset.SetRange('No_Resource', ResourcePrice.Code);
        LibraryReportDataset.SetRange('WorkTypeCode_ResPrice', ResourcePrice."Work Type Code");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the work type code');
        LibraryReportDataset.AssertCurrentRowValueEquals('UnitPrice_ResPrice', ResourcePrice."Unit Price");
    end;

    local procedure VerifyResourceRegister(ResourceNo: Code[20])
    var
        ResLedgerEntry: Record "Res. Ledger Entry";
    begin
        ResLedgerEntry.SetRange("Resource No.", ResourceNo);
        ResLedgerEntry.FindFirst();

        LibraryReportDataset.SetRange('Res__Ledger_Entry__Resource_No__', ResourceNo);
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the resource no');

        LibraryReportDataset.AssertCurrentRowValueEquals('Res__Ledger_Entry_Quantity', ResLedgerEntry.Quantity);
        LibraryReportDataset.AssertCurrentRowValueEquals('Res__Ledger_Entry__Total_Cost_', ResLedgerEntry."Total Cost");
        LibraryReportDataset.AssertCurrentRowValueEquals('Res__Ledger_Entry__Total_Price_', ResLedgerEntry."Total Price");
        LibraryReportDataset.AssertCurrentRowValueEquals('Res__Ledger_Entry__Entry_No__', ResLedgerEntry."Entry No.");
    end;

    local procedure VerifyResourceStatistics(Resource: Record Resource; Resource2: Record Resource)
    begin
        LibraryReportDataset.LoadDataSetFile();
        Resource.CalcFields("Sales (Price)", "Usage (Price)");
        Resource2.CalcFields("Sales (Price)", "Usage (Price)");

        // Verify First Row Values on Resource Statistics Report.
        VerifyResourceStatisticsRow(Resource);

        // Verify First Row Values on Resource Statistics Report.
        VerifyResourceStatisticsRow(Resource2);
    end;

    local procedure VerifyResourceStatisticsRow(Resource: Record Resource)
    begin
        LibraryReportDataset.SetRange('No_Resource', Resource."No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the resource no');

        LibraryReportDataset.AssertCurrentRowValueEquals('UsagePrice_Resource', Resource."Usage (Price)");
        LibraryReportDataset.AssertCurrentRowValueEquals('SalesPrice_Resource', Resource."Sales (Price)");
    end;

    local procedure VerifyResourceUsage(Resource: Record Resource)
    begin
        Resource.CalcFields(Capacity, "Usage (Qty.)");

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Resource', Resource."No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the resource no');

        LibraryReportDataset.AssertCurrentRowValueEquals('capacity_Resource', Resource.Capacity);
        LibraryReportDataset.AssertCurrentRowValueEquals('UsageQty_Resource', Resource."Usage (Qty.)");
        LibraryReportDataset.AssertCurrentRowValueEquals('CapacityUsageQty', Resource.Capacity - Resource."Usage (Qty.)");
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ResourceJournalTestReportHandler(var ResourceJournalTestRequest: TestRequestPage "Resource Journal - Test")
    begin
        ResourceJournalTestRequest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ResourceRegisterReportHandler(var ResourceRegister: TestRequestPage "Resource Register")
    begin
        ResourceRegister.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ResourceCostBreakdownReportHandler(var ResourceCostBreakdown: TestRequestPage "Resource - Cost Breakdown")
    begin
        ResourceCostBreakdown.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ResourceUsageReportHandler(var ResourceUsage: TestRequestPage "Resource Usage")
    begin
        ResourceUsage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ResourceListReportHandler(var ResourceList: TestRequestPage "Resource - List")
    begin
        ResourceList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ResourcePriceListReportHandler(var ResourcePriceList: TestRequestPage "Resource - Price List")
    begin
        ResourcePriceList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ResourceStatisticsReportHandler(var ResourceStatistics: TestRequestPage "Resource Statistics")
    begin
        ResourceStatistics.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}
