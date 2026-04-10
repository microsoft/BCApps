codeunit 136403 "Resource Journal"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Resource]
        IsInitialized := false;
    end;

    var
        TempDocumentEntry: Record "Document Entry" temporary;
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryResource: Codeunit "Library - Resource";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        TemplateName: Code[20];
        UnitPriceError: Label 'Unit Price must be equal.';

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Resource Journal");
        // Clear global variable.
        TemplateName := '';
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Resource Journal");

        LibraryERMCountryData.CreateVATData();
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Resource Journal");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,NavigatePageHandler')]
    [Scope('OnPrem')]
    procedure ResourceNavigation()
    var
        ResJournalLine: Record "Res. Journal Line";
        ResLedgerEntry: Record "Res. Ledger Entry";
        Navigate: Page Navigate;
        ResourceNo: Code[20];
        DocumentNo: Code[20];
    begin
        // Test the functionality of Navigation from Navigation pane on Resource Planning.

        // 1. Setup: Create new Resource, Resource Journal Line.
        Initialize();
        ResourceNo := CreateResource();
        CreateMultipleJournalLines(ResJournalLine, ResourceNo);
        DocumentNo := ResJournalLine."Document No.";  // Assign Value in Global Variable.

        // 2. Exercise: Post Resource Journal Line and open the Navigate page.
        LibraryResource.PostResourceJournalLine(ResJournalLine);
        Navigate.SetDoc(WorkDate(), DocumentNo);
        Navigate.Run();

        // 3. Verify: Verify number of entries for Res. Ledger Entry table.
        ResLedgerEntry.SetRange("Resource No.", ResourceNo);
        VerifyNavigateRecords(TempDocumentEntry, DATABASE::"Res. Ledger Entry", ResLedgerEntry.Count);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ResourceJournalPosting()
    var
        TempResJournalLine: Record "Res. Journal Line" temporary;
        ResJournalLine: Record "Res. Journal Line";
        ResJournalBatch: Record "Res. Journal Batch";
    begin
        // Test the Posting of Resource Journal Line.

        // 1. Setup: Create Resource, Resource Journal Template, Resource Journal Batch and create Resource Journal Line.
        Initialize();
        FindResourceJournalBatch(ResJournalBatch);
        CreateResourceJournalLine(ResJournalLine, ResJournalBatch."Journal Template Name", ResJournalBatch.Name, CreateResource());
        TempResJournalLine := ResJournalLine;

        // 2. Exercise: Post the Resource Journal Line.
        LibraryResource.PostResourceJournalLine(ResJournalLine);

        // 3. Verify: Verify that both the Resource Journal Line and Resource Ledger Entry have same Resource No and same Quantity.
        VerifyResourceLedgerEntry(TempResJournalLine);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PostJournalWithDifferentBatch()
    var
        ResJournalLine: Record "Res. Journal Line";
        TempResJournalLine: Record "Res. Journal Line" temporary;
        TempResJournalLine2: Record "Res. Journal Line" temporary;
        ResJournalTemplate: Record "Res. Journal Template";
        ResJournalBatch: Record "Res. Journal Batch";
        Resource: Record Resource;
    begin
        // Test the Creation of Resource Journal Template, assign Resource Journal Batches and Resource Journal Line Posting.

        // 1. Setup: Create Resource Journal Template, Create Resource Batch.
        Initialize();
        LibraryResource.FindResource(Resource);
        CreateResourceJournalTemplate(ResJournalTemplate);
        LibraryResource.CreateResourceJournalBatch(ResJournalBatch, ResJournalTemplate.Name);

        // 2. Exercise: Create and Post The Resource Journal Line.
        CreateResourceJournalLine(ResJournalLine, ResJournalBatch."Journal Template Name", ResJournalBatch.Name, Resource."No.");
        TempResJournalLine := ResJournalLine;
        LibraryResource.PostResourceJournalLine(ResJournalLine);

        Clear(ResJournalLine);
        Clear(ResJournalBatch);
        CreateResourceJournalTemplate(ResJournalTemplate);
        LibraryResource.CreateResourceJournalBatch(ResJournalBatch, ResJournalTemplate.Name);
        CreateResourceJournalLine(ResJournalLine, ResJournalBatch."Journal Template Name", ResJournalBatch.Name, Resource."No.");
        TempResJournalLine2 := ResJournalLine;
        LibraryResource.PostResourceJournalLine(ResJournalLine);

        // 3. Verify: Verify that both the Resource Journal Line and Resource Ledger Entry have same Resource No, same Quantity,same Direct
        // Unit Cost for this particular Resource Journal Batch.
        VerifyResourceLedgerEntry(TempResJournalLine);
        VerifyResourceLedgerEntry(TempResJournalLine2);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PostRecurringJournalNewBatch()
    var
        ResJournalLine: Record "Res. Journal Line";
        TempResJournalLine: Record "Res. Journal Line" temporary;
        TempResJournalLine2: Record "Res. Journal Line" temporary;
        ResJournalBatch: Record "Res. Journal Batch";
        Resource: Record Resource;
    begin
        // Test the Posting of Resource Journal line using the Recurring Resource Journal Template and Recurring Resource Journal Batch.

        // 1. Setup: Find Recurring Resource Journal Template, Create Recurring Resource Journal Batch.
        Initialize();
        LibraryResource.FindResource(Resource);
        LibraryResource.CreateResourceJournalBatch(ResJournalBatch, CreateRecurringJournalTemplate());

        // 2. Exercise: Create Resource Journal Line and Post Resource Journal Line.
        JournalLineRecurringFrequency(ResJournalLine, ResJournalBatch."Journal Template Name", ResJournalBatch.Name, Resource."No.");
        TempResJournalLine := ResJournalLine;
        LibraryResource.PostResourceJournalLine(ResJournalLine);

        LibraryResource.CreateResourceJournalBatch(ResJournalBatch, ResJournalLine."Journal Template Name");
        JournalLineRecurringFrequency(ResJournalLine, ResJournalBatch."Journal Template Name", ResJournalBatch.Name, Resource."No.");
        TempResJournalLine2 := ResJournalLine;
        LibraryResource.PostResourceJournalLine(ResJournalLine);

        // 3. Verify: Verify that both the Resource Journal Line and Resource Ledger Entry have same fields for this particular Resource
        // Journal Batch.Verify that Resource Journal Line has one Extra line created after posting of Recurring Journal.
        VerifyResourceLedgerEntry(TempResJournalLine);
        VerifyResourceLedgerEntry(TempResJournalLine2);
        ResJournalLine.Get(
          TempResJournalLine."Journal Template Name", TempResJournalLine."Journal Batch Name", TempResJournalLine."Line No.");
        VerifyRecurringJournalLine(TempResJournalLine);
        ResJournalLine.Get(
          TempResJournalLine2."Journal Template Name", TempResJournalLine2."Journal Batch Name", TempResJournalLine2."Line No.");
        VerifyRecurringJournalLine(TempResJournalLine2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckValueOnResourcePage()
    var
        TempResource: Record Resource temporary;
    begin
        // Create New Resource by Page and verify it.

        // 1. Setup.
        Initialize();

        // 2. Exercise: Create Resource by Resource Card Page.
        InsertValuesOnTempResource(TempResource);
        InsertValuesOnResourceCard(TempResource);

        // 3. Verify: Check value on Resource.
        VerifyValuesOnResource(TempResource);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckResourceJournalLineValues()
    var
        Resource: Record Resource;
        ResJournalBatch: Record "Res. Journal Batch";
        ResJournalTemplate: Record "Res. Journal Template";
        ResourceJournal: TestPage "Resource Journal";
    begin
        // Check Resource Journal Line values by Page.

        // 1. Setup: Create Resource.
        Initialize();
        Resource.Get(CreateResource());
        FindResourceJournalBatch(ResJournalBatch);
        TemplateName := ResJournalBatch."Journal Template Name";  // Assign global variable.
        ResJournalTemplate.SetFilter(Name, '<>%1', ResJournalBatch."Journal Template Name");
        ResJournalTemplate.DeleteAll(); // keep just one template to avoid selection modal page

        // 2. Exercise: Create Resource Journal Line by page.
        ResourceJournal.OpenEdit();
        CreateResourceJournalLineByPage(ResourceJournal, ResJournalBatch.Name, Resource."No.", '');
        ResourceJournal.OK().Invoke();

        // 3. Verify: Check Resource Journal Line values.
        VerifyResourceJournalLineUnitPrice(Resource."No.", '', Resource."Unit Price", ResJournalBatch.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckResourcePriceWithAndWithoutWorkType()
    var
        PriceListLine: Record "Price List Line";
        Resource: Record Resource;
        ResJournalTemplate: Record "Res. Journal Template";
        ResourcePrice: Record "Resource Price";
        ResourcePrice2: Record "Resource Price";
        ResJournalBatch: Record "Res. Journal Batch";
        WorkType: Record "Work Type";
        ResourceJournal: TestPage "Resource Journal";
    begin
        // Check Resource Price on Resource Journal Line with and without Work Type by Page.

        // 1. Setup: Create Resource and Resource Price.
        Initialize();
        FindResourceJournalBatch(ResJournalBatch);
        TemplateName := ResJournalBatch."Journal Template Name";  // Assign global variable.
        ResJournalTemplate.SetFilter(Name, '<>%1', ResJournalBatch."Journal Template Name");
        ResJournalTemplate.DeleteAll(); // keep just one template to avoid selection modal page

        Resource.Get(CreateResource());
        LibraryResource.CreateWorkType(WorkType);
        CreateResourcePrice(ResourcePrice, ResourcePrice.Type::Resource, Resource."No.", '', '');
        CreateResourcePrice(ResourcePrice2, ResourcePrice.Type::Resource, Resource."No.", WorkType.Code, '');
        CopyFromToPriceListLine.CopyFrom(ResourcePrice, PriceListLine);

        // 2. Exercise: Create Resource Journal Lines without and with Work Type with same Document No.
        ResourceJournal.OpenEdit();
        CreateResourceJournalLineByPage(ResourceJournal, ResJournalBatch.Name, Resource."No.", '');
        ResourceJournal.New();
        CreateResourceJournalLineByPage(ResourceJournal, ResJournalBatch.Name, Resource."No.", WorkType.Code);
        ResourceJournal.OK().Invoke();

        // 3. Verify: Check Unit Price of Resource Journal Lines.
        VerifyResourceJournalLineUnitPrice(Resource."No.", '', ResourcePrice."Unit Price", ResJournalBatch.Name);
        VerifyResourceJournalLineUnitPrice(Resource."No.", WorkType.Code, ResourcePrice2."Unit Price", ResJournalBatch.Name);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure CheckResourcePriceAfterUseBatchJob()
    var
        PriceListLine: Record "Price List Line";
        Resource: Record Resource;
        ResourcePrice: Record "Resource Price";
        ResourcePrice2: Record "Resource Price";
        ResJournalBatch: Record "Res. Journal Batch";
        ResJournalTemplate: Record "Res. Journal Template";
        WorkType: Record "Work Type";
        ResourceJournal: TestPage "Resource Journal";
        UnitPrice: Decimal;
        UnitPrice2: Decimal;
    begin
        // Check Resource Price on Resource Journal Line after used batch job Resource Price Change Resource and Resource Price Change Resource Prices.

        // 1. Setup: Create Resource and Resource Price.
        Initialize();
        FindResourceJournalBatch(ResJournalBatch);
        TemplateName := ResJournalBatch."Journal Template Name";  // Assign global variable.
        ResJournalTemplate.SetFilter(Name, '<>%1', ResJournalBatch."Journal Template Name");
        ResJournalTemplate.DeleteAll(); // keep just one template to avoid selection modal page

        Resource.Get(CreateResource());
        LibraryResource.CreateWorkType(WorkType);
        CreateResourcePrice(ResourcePrice, ResourcePrice.Type::Resource, Resource."No.", '', '');
        CreateResourcePrice(ResourcePrice2, ResourcePrice.Type::Resource, Resource."No.", WorkType.Code, '');
        CopyFromToPriceListLine.CopyFrom(ResourcePrice, PriceListLine);

        // Create Resource Journal Lines without and with Work Type with same Document No.
        ResourceJournal.OpenEdit();
        CreateResourceJournalLineByPage(ResourceJournal, ResJournalBatch.Name, Resource."No.", '');
        ResourceJournal.New();
        CreateResourceJournalLineByPage(ResourceJournal, ResJournalBatch.Name, Resource."No.", WorkType.Code);
        ResourceJournal.OK().Invoke();

        // 2. Exercise: Run Suggest Resource Price Change Resource, Suggest Resource Price Change Price and Implement Resource Price Change report.
        RunSuggestResPriceChgResBatchJob(Resource."No.", '');
        RunSuggestResPriceChgPriceBatchJob(Resource."No.", WorkType.Code);
        UnitPrice := GetResourcePrice(Resource."No.", '');
        UnitPrice2 := GetResourcePrice(Resource."No.", WorkType.Code);
        RunImplementResPriceChangeBatchJob(Resource."No.");

        // 3. Verify: Check Unit price in Resource Price.
        VerifyResourcePrice(Resource."No.", '', UnitPrice);
        VerifyResourcePrice(Resource."No.", WorkType.Code, UnitPrice2);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure BlankDescriptionOnResourceLedgerEntry()
    begin
        // Test Blank Description in Resource Ledger Entries after Posting Resource Journal Line with Blank Description.

        Initialize();
        PostResourceJournalWithDescription('');  // Passing Blank Value for Description.
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure DescriptionOnResourceLedgerEntry()
    begin
        // Test Description updated correctly in Resource Ledger Entries after Posting Resource Journal Line with some Description.

        Initialize();
        PostResourceJournalWithDescription(LibraryUtility.GenerateGUID());  // Passing any Value for Description.
    end;

    local procedure PostResourceJournalWithDescription(Description: Text[50])
    var
        ResJournalLine: Record "Res. Journal Line";
        ResJournalBatch: Record "Res. Journal Batch";
        ResLedgerEntry: Record "Res. Ledger Entry";
        TempResJournalLine: Record "Res. Journal Line" temporary;
    begin
        // 1. Setup: Create Resource Journal Line and update Description as on it.
        ClearResourceJournalLines(ResJournalBatch);
        CreateResourceJournalLine(ResJournalLine, ResJournalBatch."Journal Template Name", ResJournalBatch.Name, CreateResource());
        UpdateDescriptionOnResourceJournalLine(ResJournalLine, Description);
        TempResJournalLine := ResJournalLine;

        // 2. Exercise: Post the Resource Journal Line.
        LibraryResource.PostResourceJournalLine(ResJournalLine);

        // 3. Verify: Verify that Description updated correctly in Resource Ledger Entry.
        FindResourceLedgerEntry(ResLedgerEntry, TempResJournalLine."Document No.", ResJournalBatch.Name, TempResJournalLine."Resource No.");
        ResLedgerEntry.TestField(Description, Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WorkTypeWithUOMOnResourceJournalLine()
    var
        ResourceUnitOfMeasure: Record "Resource Unit of Measure";
        ResJournalLine: Record "Res. Journal Line";
    begin
        // Test various Costs and Prices on Resource Journal Line after updating Work Type with Unit of Measure containing larger Quantity Per Unit of Measure.

        // 1. Setup: Create Resource and update a new Unit of Measure for it.
        Initialize();
        CreateResourceAndUpdateUOM(ResourceUnitOfMeasure);

        // 2. Exercise. Create Resource Journal Line with Work Type contains Resource Unit of Measure.
        CreateAndUpdateResourceJournalLine(ResJournalLine, ResourceUnitOfMeasure."Resource No.", ResourceUnitOfMeasure.Code);

        // 3. Verify: Verify Costs and Prices updated correctly on Resource Journal Line.
        VerifyCostAndPriceOnResourceJornalLine(ResJournalLine, ResourceUnitOfMeasure);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure WorkTypeWithUOMAfterPostingResourceJournalLine()
    var
        ResourceUnitOfMeasure: Record "Resource Unit of Measure";
        ResJournalLine: Record "Res. Journal Line";
        ResLedgerEntry: Record "Res. Ledger Entry";
        TempResJournalLine: Record "Res. Journal Line" temporary;
    begin
        // Test Quantity Per Unit of Measure and Base Quantity in Resource Ledger Entry after Posting Resource Journal with Work Type having Unit Of Measure attached.

        // 1. Setup: Create Resource and update a new Unit of Measure for it, Create Resource Journal Line with Work Type contains Resource Unit of Measure.
        Initialize();
        CreateResourceAndUpdateUOM(ResourceUnitOfMeasure);
        CreateAndUpdateResourceJournalLine(ResJournalLine, ResourceUnitOfMeasure."Resource No.", ResourceUnitOfMeasure.Code);
        TempResJournalLine := ResJournalLine;

        // 2. Exercise.
        LibraryResource.PostResourceJournalLine(ResJournalLine);

        // 3. Verify: Verify Qty. per Unit of Measure and Quantity (Base) updated correctly on Resource Ledger Entries.
        FindResourceLedgerEntry(
          ResLedgerEntry, TempResJournalLine."Document No.", TempResJournalLine."Journal Batch Name", ResourceUnitOfMeasure."Resource No.");
        ResLedgerEntry.TestField("Qty. per Unit of Measure", ResourceUnitOfMeasure."Qty. per Unit of Measure");
        ResLedgerEntry.TestField("Quantity (Base)", TempResJournalLine.Quantity * ResourceUnitOfMeasure."Qty. per Unit of Measure");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    procedure RecordLinkDeletedAfterPostingResJnlLine()
    var
        ResJournalBatch: Record "Res. Journal Batch";
        ResJournalLine: Record "Res. Journal Line";
        RecordLink: Record "Record Link";
    begin
        // [FEATURE] [Journal] [Record Link]
        // [SCENARIO] Record links are deleted after posting a resource journal line

        Initialize();

        // [GIVEN] Resource journal line
        FindResourceJournalBatch(ResJournalBatch);
        CreateResourceJournalLine(ResJournalLine, ResJournalBatch."Journal Template Name", ResJournalBatch.Name, CreateResource());

        // [GIVEN] Assign a record link to the journal line
        LibraryUtility.CreateRecordLink(ResJournalLine);

        // [WHEN] Post the journal
        LibraryResource.PostResourceJournalLine(ResJournalLine);

        // [THEN] The record link is deleted
        RecordLink.SetRange("Record ID", ResJournalLine.RecordId);
        Assert.RecordIsEmpty(RecordLink);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    procedure ResourceJournalCannotBePostedWithoutDocumentNo()
    var
        ResJournalBatch: Record "Res. Journal Batch";
        Resource: Record Resource;
        ResourceJournal: TestPage "Resource Journal";
    begin
        // [SCENARIO 579390] Verify that the Resource Journal cannot be posted without a Document No.
        Initialize();

        // [GIVEN] Create a resource.
        Resource.Get(CreateResource());

        // [GIVEN] Create Resource Journal Template And Batch.
        FindResourceJournalBatch(ResJournalBatch);

        // [GIVEN] Open Resource Journal Page.
        ResourceJournal.OpenEdit();

        // [GIVEN] Create Resource Journal Line.
        CreateResourceJournalLineByPage(ResourceJournal, ResJournalBatch.Name, Resource."No.", '');

        // [WHEN] Document No. field is blank in the Resource Journal.
        ResourceJournal."Document No.".SetValue('');

        // [THEN] Resource Journal does not post and shows an error that Document No. must have a value .
        asserterror ResourceJournal.Post.Invoke();
        ResourceJournal.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    procedure VerifyTheResourceLedgerEntryHasDocumentNo()
    var
        ResJournalBatch: Record "Res. Journal Batch";
        ResLedgerEntry: Record "Res. Ledger Entry";
        Resource: Record Resource;
        DocumentNo: Text;
        ResourceJournal: TestPage "Resource Journal";
    begin
        // [SCENARIO 579390] Ensure that the Resource Ledger Entry includes a Document No.
        Initialize();

        // [GIVEN] Create a resource.
        Resource.Get(CreateResource());

        // [GIVEN] Create Resource Journal Template And Batch.
        FindResourceJournalBatch(ResJournalBatch);

        // [GIVEN] Open Resource Journal Page.
        ResourceJournal.OpenEdit();

        // [GIVEN] Create Resource Journal Line.
        CreateResourceJournalLineByPage(ResourceJournal, ResJournalBatch.Name, Resource."No.", '');

        // [GIVEN] Save the document no. value.
        DocumentNo := ResourceJournal."Document No.".Value();

        // [WHEN] Post the Resource Journal.
        ResourceJournal.Post.Invoke();
        Commit();
        ResourceJournal.OK().Invoke();

        // [THEN] Verify that the Resource Ledger Entry has a Document No.
        FindResourceLedgerEntry(ResLedgerEntry, DocumentNo, ResJournalBatch.Name, Resource."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    procedure ResLedgerEntryHaveDocumentNoGeneratedFromResJournalBatchPostingNoSeries()
    var
        ResJournalBatch: Record "Res. Journal Batch";
        ResLedgerEntry: Record "Res. Ledger Entry";
        Resource: Record Resource;
        ResourceJournal: TestPage "Resource Journal";
        LastNoUsed, PostingNoSeries : Code[20];
    begin
        // [SCENARIO 581954] Ensure that the Resource Ledger Entry includes a Document No. generated from the Resource Journal Batch Posting No. Series.
        Initialize();

        // [GIVEN] Create Posting No. Series.
        PostingNoSeries := LibraryUtility.GetGlobalNoSeriesCode();

        // [GIVEN] Create a resource.
        Resource.Get(CreateResource());

        // [GIVEN] Create Resource Journal Template And Batch.
        FindResourceJournalBatch(ResJournalBatch);

        // [GIVEN] Set Posting No. Series in Resource Journal Batch.
        ResJournalBatch.Validate("Posting No. Series", PostingNoSeries);
        ResJournalBatch.Modify(true);

        // [GIVEN] Open Resource Journal Page.
        ResourceJournal.OpenEdit();

        // [GIVEN] Create Resource Journal Line.
        CreateResourceJournalLineByPage(ResourceJournal, ResJournalBatch.Name, Resource."No.", '');

        // [GIVEN] Set Document No. value blank in resource journal.
        ResourceJournal."Document No.".SetValue('');

        // [WHEN] Post the Resource Journal.
        ResourceJournal.Post.Invoke();
        Commit();
        ResourceJournal.OK().Invoke();

        // [THEN] Verify that the Resource Ledger Entry has a Document No. from the Resource Journal Batch Posting No. Series. 
        LastNoUsed := FindLastNoUsed(PostingNoSeries);
        FindResourceLedgerEntry(ResLedgerEntry, LastNoUsed, ResJournalBatch.Name, Resource."No.");
    end;

    local procedure ClearResourceJournalLines(var ResJournalBatch: Record "Res. Journal Batch")
    var
        ResJournalLine: Record "Res. Journal Line";
    begin
        FindResourceJournalBatch(ResJournalBatch);
        ResJournalLine.SetRange("Journal Template Name", ResJournalBatch."Journal Template Name");
        ResJournalLine.SetRange("Journal Batch Name", ResJournalBatch.Name);
        ResJournalLine.DeleteAll(true);
    end;

    local procedure CreateAndUpdateResourceJournalLine(var ResJournalLine: Record "Res. Journal Line"; ResourceNo: Code[20]; UnitOfMeasureCode: Code[10])
    var
        ResJournalBatch: Record "Res. Journal Batch";
    begin
        ClearResourceJournalLines(ResJournalBatch);
        CreateResourceJournalLine(ResJournalLine, ResJournalBatch."Journal Template Name", ResJournalBatch.Name, ResourceNo);
        ResJournalLine.Validate("Work Type Code", CreateAndUpdateWorkType(UnitOfMeasureCode));  // Update Work Type Code on Resource Journal Line.
        ResJournalLine.Modify(true);
    end;

    local procedure CreateAndUpdateWorkType(UnitOfMeasureCode: Code[10]): Code[10]
    var
        WorkType: Record "Work Type";
    begin
        LibraryResource.CreateWorkType(WorkType);
        WorkType.Validate("Unit of Measure Code", UnitOfMeasureCode);
        WorkType.Modify(true);
        exit(WorkType.Code);
    end;

    local procedure CreateResourceAndUpdateUOM(var ResourceUnitOfMeasure: Record "Resource Unit of Measure")
    var
        Resource: Record Resource;
    begin
        Resource.Get(CreateResource());
        LibraryResource.CreateResourceUnitOfMeasure(ResourceUnitOfMeasure, Resource."No.", FindUnitOfMeasure(), 1);
        ResourceUnitOfMeasure.Validate("Qty. per Unit of Measure", 1 + LibraryRandom.RandInt(10));  // Take Random Quantity greater than One, value important for test.
        ResourceUnitOfMeasure.Modify(true);
    end;

    local procedure CreateResource(): Code[20]
    begin
        exit(LibraryResource.CreateResourceNo());
    end;

    local procedure CreateResourcePrice(var ResourcePrice: Record "Resource Price"; Type: Option; ResourceNo: Code[20]; WorkTypeCode: Code[10]; CurrencyCode: Code[10])
    begin
        LibraryResource.CreateResourcePrice(ResourcePrice, Type, ResourceNo, WorkTypeCode, CurrencyCode);
        ResourcePrice.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ResourcePrice.Modify(true);
    end;

    local procedure CreateRecurringJournalTemplate(): Code[10]
    var
        ResJournalTemplate: Record "Res. Journal Template";
    begin
        LibraryResource.CreateResourceJournalTemplate(ResJournalTemplate);
        ResJournalTemplate.Validate(Recurring, true);
        ResJournalTemplate.Modify(true);
        exit(ResJournalTemplate.Name);
    end;

    local procedure CreateResourceJournalTemplate(var ResJournalTemplate: Record "Res. Journal Template")
    begin
        LibraryResource.CreateResourceJournalTemplate(ResJournalTemplate);
        ResJournalTemplate.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ResJournalTemplate.Modify(true);
    end;

    local procedure CreateResourceJournalLineByPage(var ResourceJournal: TestPage "Resource Journal"; BatchName: Code[10]; ResourceNo: Code[20]; WorkTypeCode: Code[10])
    var
        ResJournalLine: Record "Res. Journal Line";
    begin
        ResourceJournal.CurrentJnlBatchName.SetValue(BatchName);
        ResourceJournal."Entry Type".SetValue(ResJournalLine."Entry Type"::Sale);
        ResourceJournal."Document No.".SetValue(BatchName);
        ResourceJournal."Resource No.".SetValue(ResourceNo);
        ResourceJournal."Work Type Code".SetValue(WorkTypeCode);
        ResourceJournal.Quantity.SetValue(LibraryRandom.RandDec(10, 2));  // Value is not important here.
    end;

    local procedure CreateResourceJournalLine(var ResJournalLine: Record "Res. Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10]; ResourceNo: Code[20])
    begin
        LibraryResource.CreateResJournalLine(ResJournalLine, JournalTemplateName, JournalBatchName);
        ResJournalLine.Validate("Resource No.", ResourceNo);
        ResJournalLine.Validate("Posting Date", WorkDate());
        ResJournalLine.Validate("Document No.", ResourceNo);

        // Use Random Quantity because value is not important.
        ResJournalLine.Validate(Quantity, LibraryRandom.RandDec(100, 2));
        ResJournalLine.Modify(true);
    end;

    local procedure CreateMultipleJournalLines(var ResJournalLine: Record "Res. Journal Line"; ResourceNo: Code[20])
    var
        ResJournalBatch: Record "Res. Journal Batch";
        NoOfRecords: Integer;
    begin
        FindResourceJournalBatch(ResJournalBatch);
        for NoOfRecords := 1 to 5 do
            CreateResourceJournalLine(ResJournalLine, ResJournalBatch."Journal Template Name", ResJournalBatch.Name, ResourceNo);
    end;

    local procedure FindResourceLedgerEntry(var ResLedgerEntry: Record "Res. Ledger Entry"; DocumentNo: Code[20]; JournalBatchName: Code[10]; ResourceNo: Code[20])
    begin
        ResLedgerEntry.SetRange("Document No.", DocumentNo);
        ResLedgerEntry.SetRange("Journal Batch Name", JournalBatchName);
        ResLedgerEntry.SetRange("Resource No.", ResourceNo);
        ResLedgerEntry.FindFirst();
    end;

    local procedure FindUnitOfMeasure(): Code[10]
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        exit(UnitOfMeasure.Code);
    end;

    local procedure GetResourcePrice(ResourceNo: Code[20]; WorkTypeCode: Code[10]): Decimal
    var
        ResourcePriceChange: Record "Resource Price Change";
    begin
        ResourcePriceChange.SetRange(Code, ResourceNo);
        ResourcePriceChange.SetRange("Work Type Code", WorkTypeCode);
        ResourcePriceChange.FindFirst();
        exit(ResourcePriceChange."New Unit Price");
    end;

    local procedure InsertValuesOnResourceCard(Resource: Record Resource)
    var
        ResourceCard: TestPage "Resource Card";
    begin
        ResourceCard.OpenNew();
        ResourceCard."No.".SetValue(Resource."No.");
        ResourceCard.Name.SetValue(Resource.Name);
        ResourceCard."Direct Unit Cost".SetValue(Resource."Direct Unit Cost");
        ResourceCard."Unit Price".SetValue(Resource."Unit Price");
        ResourceCard."Gen. Prod. Posting Group".SetValue(Resource."Gen. Prod. Posting Group");
        ResourceCard."VAT Prod. Posting Group".SetValue(Resource."VAT Prod. Posting Group");
        ResourceCard.OK().Invoke();
    end;

    local procedure InsertValuesOnTempResource(var TempResource: Record Resource temporary)
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        TempResource.Init();
        TempResource.Validate("No.", LibraryUtility.GenerateRandomCode(TempResource.FieldNo("No."), DATABASE::Resource));
        TempResource.Validate(Name, TempResource."No.");  // Validate Name as No. because value is not important.
        TempResource.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));  // Value is not important here.
        TempResource.Validate("Unit Price", LibraryRandom.RandDec(100, 2));  // Value is not important here.
        TempResource.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        TempResource.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        TempResource.Insert(true);
    end;

    local procedure JournalLineRecurringFrequency(var ResJournalLine: Record "Res. Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10]; ResourceNo: Code[20])
    var
        RecurringFrequency: DateFormula;
    begin
        CreateResourceJournalLine(ResJournalLine, JournalTemplateName, JournalBatchName, ResourceNo);
        ResJournalLine.Validate("Recurring Method", ResJournalLine."Recurring Method"::Fixed);
        Evaluate(RecurringFrequency, '<' + Format(LibraryRandom.RandInt(5)) + 'M>'); // Use Random Number because value is not important.
        ResJournalLine.Validate("Recurring Frequency", RecurringFrequency);
        ResJournalLine.Modify(true);
    end;

    local procedure FindResourceJournalBatch(var ResJournalBatch: Record "Res. Journal Batch")
    var
        ResJournalTemplate: Record "Res. Journal Template";
    begin
        ResJournalTemplate.SetRange(Recurring, false);
        LibraryResource.FindResJournalTemplate(ResJournalTemplate);
        LibraryResource.FindResJournalBatch(ResJournalBatch, ResJournalTemplate.Name);
    end;

    local procedure RunImplementResPriceChangeBatchJob(ResourceNo: Code[20])
    var
        ResourcePriceChange: Record "Resource Price Change";
        ImplementResPriceChange: Report "Implement Res. Price Change";
    begin
        Clear(ImplementResPriceChange);
        ResourcePriceChange.SetRange(Type, ResourcePriceChange.Type::Resource);
        ResourcePriceChange.SetRange(Code, ResourceNo);
        ImplementResPriceChange.SetTableView(ResourcePriceChange);
        ImplementResPriceChange.UseRequestPage(false);
        ImplementResPriceChange.Run();
    end;

    local procedure RunSuggestResPriceChgResBatchJob(ResourceNo: Code[20]; WorkTypeCode: Code[10])
    var
        Resource: Record Resource;
        SuggestResPriceChgRes: Report "Suggest Res. Price Chg. (Res.)";
    begin
        Clear(SuggestResPriceChgRes);
        Resource.SetRange("No.", ResourceNo);
        SuggestResPriceChgRes.InitializeCopyToResPrice('', WorkTypeCode);
        SuggestResPriceChgRes.InitializeRequest(0, LibraryRandom.RandDec(10, 2), '', true);  // Value is not important here.
        SuggestResPriceChgRes.SetTableView(Resource);
        SuggestResPriceChgRes.UseRequestPage(false);
        SuggestResPriceChgRes.Run();
    end;

    local procedure RunSuggestResPriceChgPriceBatchJob(ResourceNo: Code[20]; WorkTypeCode: Code[10])
    var
        ResourcePrice: Record "Resource Price";
        SuggestResPriceChgPrice: Report "Suggest Res. Price Chg.(Price)";
    begin
        Clear(SuggestResPriceChgPrice);
        ResourcePrice.SetRange(Type, ResourcePrice.Type);
        ResourcePrice.SetRange(Code, ResourceNo);
        SuggestResPriceChgPrice.InitializeCopyToResPrice('', WorkTypeCode);
        SuggestResPriceChgPrice.InitializeRequest(0, LibraryRandom.RandDec(10, 2), '', true);  // Value is not important here.
        SuggestResPriceChgPrice.SetTableView(ResourcePrice);
        SuggestResPriceChgPrice.UseRequestPage(false);
        SuggestResPriceChgPrice.Run();
    end;

    local procedure UpdateDescriptionOnResourceJournalLine(ResJournalLine: Record "Res. Journal Line"; Description: Text[50])
    begin
        ResJournalLine.Validate(Description, Description);
        ResJournalLine.Modify(true);
    end;

    local procedure VerifyCostAndPriceOnResourceJornalLine(ResJournalLine: Record "Res. Journal Line"; ResourceUnitOfMeasure: Record "Resource Unit of Measure")
    var
        Resource: Record Resource;
    begin
        Resource.Get(ResourceUnitOfMeasure."Resource No.");
        ResJournalLine.TestField("Qty. per Unit of Measure", ResourceUnitOfMeasure."Qty. per Unit of Measure");
        ResJournalLine.TestField("Unit Cost", Resource."Unit Cost" * ResourceUnitOfMeasure."Qty. per Unit of Measure");
        ResJournalLine.TestField("Direct Unit Cost", Resource."Direct Unit Cost" * ResourceUnitOfMeasure."Qty. per Unit of Measure");
        ResJournalLine.TestField("Unit Price", Resource."Unit Price" * ResourceUnitOfMeasure."Qty. per Unit of Measure");
        ResJournalLine.TestField(
          "Total Price", ResJournalLine.Quantity * Resource."Unit Price" * ResourceUnitOfMeasure."Qty. per Unit of Measure");
    end;

    local procedure VerifyNavigateRecords(var TempDocumentEntry2: Record "Document Entry" temporary; TableID: Integer; NoOfRecords: Integer)
    begin
        TempDocumentEntry2.SetRange("Table ID", TableID);
        TempDocumentEntry2.FindFirst();
        TempDocumentEntry2.TestField("No. of Records", NoOfRecords);
    end;

    local procedure VerifyResourceJournalLineUnitPrice(ResourceNo: Code[20]; WorkTypeCode: Code[10]; UnitPrice: Decimal; DocumentNo: Code[20])
    var
        ResJournalLine: Record "Res. Journal Line";
    begin
        ResJournalLine.SetRange("Document No.", DocumentNo);
        ResJournalLine.SetRange("Resource No.", ResourceNo);
        ResJournalLine.SetRange("Work Type Code", WorkTypeCode);
        ResJournalLine.FindFirst();
        ResJournalLine.TestField("Unit Price", UnitPrice);
    end;

    local procedure VerifyResourceLedgerEntry(ResJournalLine: Record "Res. Journal Line")
    var
        ResLedgerEntry: Record "Res. Ledger Entry";
    begin
        FindResourceLedgerEntry(
          ResLedgerEntry, ResJournalLine."Document No.", ResJournalLine."Journal Batch Name", ResJournalLine."Resource No.");
        ResLedgerEntry.TestField(Quantity, ResJournalLine.Quantity);
        ResLedgerEntry.TestField("Direct Unit Cost", ResJournalLine."Direct Unit Cost");
    end;

    local procedure VerifyResourcePrice(ResourceNo: Code[20]; WorkTypeCode: Code[10]; UnitPrice: Decimal)
    var
        ResourcePrice: Record "Resource Price";
        Assert: Codeunit Assert;
    begin
        ResourcePrice.SetRange(Code, ResourceNo);
        ResourcePrice.SetRange("Work Type Code", WorkTypeCode);
        ResourcePrice.FindFirst();
        Assert.AreEqual(UnitPrice, ResourcePrice."Unit Price", UnitPriceError);
    end;

    local procedure VerifyRecurringJournalLine(TempResJournalLine: Record "Res. Journal Line" temporary)
    var
        ResJournalLine: Record "Res. Journal Line";
    begin
        ResJournalLine.SetRange("Journal Batch Name", TempResJournalLine."Journal Batch Name");
        ResJournalLine.SetRange("Document No.", TempResJournalLine."Document No.");
        ResJournalLine.FindFirst();
        ResJournalLine.TestField(Quantity, TempResJournalLine.Quantity);
        ResJournalLine.TestField("Unit Cost", TempResJournalLine."Unit Cost");
        ResJournalLine.TestField("Total Price", TempResJournalLine."Total Price");
        ResJournalLine.TestField("Posting Date", CalcDate(TempResJournalLine."Recurring Frequency", WorkDate()));
    end;

    local procedure VerifyValuesOnResource(Resource: Record Resource)
    var
        Resource2: Record Resource;
    begin
        Resource2.Get(Resource."No.");
        Resource2.TestField(Name, Resource.Name);
        Resource2.TestField("Direct Unit Cost", Resource."Direct Unit Cost");
        Resource2.TestField("Unit Price", Resource."Unit Price");
        Resource2.TestField("Gen. Prod. Posting Group", Resource."Gen. Prod. Posting Group");
        Resource2.TestField("VAT Prod. Posting Group", Resource."VAT Prod. Posting Group");
    end;

    local procedure FindLastNoUsed(SeriesCode: Code[20]): Code[20]
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeriesLine.SetRange("Series Code", SeriesCode);
        NoSeriesLine.FindFirst();

        exit(NoSeriesLine."Last No. Used");
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure NavigatePageHandler(var Navigate: Page Navigate)
    begin
        Navigate.UpdateNavigateForm(false);
        Navigate.FindRecordsOnOpen();
        Navigate.ReturnDocumentEntry(TempDocumentEntry);
    end;
}

