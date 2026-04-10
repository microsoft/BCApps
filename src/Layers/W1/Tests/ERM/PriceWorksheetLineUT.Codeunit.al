codeunit 134198 "Price Worksheet Line UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Price Calculation] [Price Worksheet Line]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryJob: Codeunit "Library - Job";
        LibraryMarketing: codeunit "Library - Marketing";
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";
        LibraryResource: Codeunit "Library - Resource";
        LibraryRandom: Codeunit "Library - Random";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        StartingDateErr: Label 'Starting Date %1 cannot be after Ending Date %2.', Comment = '%1 and %2 - dates';
        CampaignDateErr: Label 'If Source Type is Campaign, then you can only change Starting Date and Ending Date from the Campaign Card.';
        AssetTypeForUOMErr: Label 'Product Type must be equal to Item or Resource.';
        AssetTypeMustNotBeAllErr: Label 'Product Type must not be (All)';
        AssetNoMustHaveValueErr: Label 'Product No. must have a value';
        NotPostingJobTaskTypeErr: Label 'Project Task Type must be equal to ''Posting''';
        WrongPriceListCodeErr: Label 'The field Price List Code of table Price Worksheet Line contains a value (%1) that cannot be found';
        FieldNotAllowedForAmountTypeErr: Label 'Field %1 is not allowed in the price list line where %2 is %3.',
            Comment = '%1 - the field caption; %2 - Amount Type field caption; %3 - amount type value: Discount or Price';
        LineSourceTypeErr: Label 'cannot be set to %1 if the header''s source type is %2.', Comment = '%1 and %2 - the source type value.';
        ParentSourceNoMustBeFilledErr: Label 'Assign-to Parent No. must have a value';
        SourceNoMustBeFilledErr: Label 'Assign-to No. must have a value';
        IsInitialized: Boolean;

    [Test]
    procedure T000_PriceListLinesIsASubsetOfPriceWorksheetLine()
    var
        LLField: Record "Field";
        WLField: Record "Field";
    begin
        // [SCENARIO] All fields of "Price List Line" do exist in "Price Worksheet Line"
        Initialize();

        LLField.SetRange(TableNo, Database::"Price List Line");
        if LLField.FindSet() then
            repeat
                WLField.Get(Database::"Price Worksheet Line", LLField."No.");
                WLField.TestField(Enabled, LLField.Enabled);
                WLField.TestField(IsPartOfPrimaryKey, LLField.IsPartOfPrimaryKey);
                WLField.TestField(Type, LLField.Type);
                WLField.TestField(Len, LLField.Len);
                WLField.TestField(RelationTableNo, LLField.RelationTableNo);
                WLField.TestField(RelationFieldNo, LLField.RelationFieldNo);
                WLField.TestField(Class, LLField.Class);
                WLField.TestField(ObsoleteState, LLField.ObsoleteState);
            until LLField.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('ItemUOMModalHandler')]
    procedure T001_LookupItemUnitOfMeasure()
    var
        Item: Record Item;
        ItemUnitofMeasure: Record "Item Unit of Measure";
        PriceWorksheetLine: Record "Price Worksheet Line";
        MockPriceWorksheetLine: TestPage "Mock Price Worksheet Line";
    begin
        // [FEATURE] [Asset] [Item] [Unit Of Measure]
        Initialize();
        // [GIVEN] Item 'I', and one Item UoM 'X'
        LibraryInventory.CreateItem(Item);
        ItemUnitofMeasure.SetRange("Item No.", Item."No.");
        ItemUnitofMeasure.DeleteAll();
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitofMeasure, Item."No.", 134124);
        // [GIVEN] Price Worksheet Line, where "Asset Type" is Item, "Asset No."" is 'I'
        PriceWorksheetLine.Init();
        PriceWorksheetLine.Validate("Asset Type", "Price Asset Type"::Item);
        PriceWorksheetLine.Validate("Asset No.", Item."No.");
        PriceWorksheetLine.Insert();

        // [WHEN] Lookup Unit Of Measure in Line
        MockPriceWorksheetLine.Trap();
        Page.Run(Page::"Mock Price Worksheet Line", PriceWorksheetLine);
        MockPriceWorksheetLine."Unit of Measure Code".Lookup();

        // [THEN] Page "Item Unit Of Measure" shows one record with 'X'
        Assert.AreEqual(ItemUnitofMeasure.Code, LibraryVariableStorage.DequeueText(), 'UoM Code');
        Assert.AreEqual(
            ItemUnitofMeasure."Qty. per Unit of Measure",
            LibraryVariableStorage.DequeueDecimal(), 'Qty. per Unit of Measure');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'Next line is found');
    end;

    [Test]
    [HandlerFunctions('ItemVariantsHandler')]
    procedure T002_LookupVariant()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        PriceWorksheetLine: Record "Price Worksheet Line";
        MockPriceWorksheetLine: TestPage "Mock Price Worksheet Line";
    begin
        // [FEATURE] [Asset] [Item] [Variant]
        Initialize();
        // [GIVEN] Item 'I', and one Variant 'X'
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        // [GIVEN] Price Worksheet Line, where "Asset Type" is Item, "Asset No."" is 'I'
        PriceWorksheetLine.Init();
        PriceWorksheetLine.Validate("Asset Type", "Price Asset Type"::Item);
        PriceWorksheetLine.Validate("Asset No.", Item."No.");
        PriceWorksheetLine.Insert();

        // [WHEN] Lookup "Valiant Code" in Line
        MockPriceWorksheetLine.Trap();
        Page.Run(Page::"Mock Price Worksheet Line", PriceWorksheetLine);
        MockPriceWorksheetLine."Variant Code".Lookup();

        // [THEN] Page "Item Variants" shows one record with 'X'
        Assert.AreEqual(ItemVariant.Code, LibraryVariableStorage.DequeueText(), 'Variant Code');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'Next Variant is found');
    end;

    [Test]
    [HandlerFunctions('ResourceUOMModalHandler')]
    procedure T003_LookupRersourceUnitOfMeasure()
    var
        Resource: Record Resource;
        ResourceUnitofMeasure: Record "Resource Unit of Measure";
        PriceWorksheetLine: Record "Price Worksheet Line";
        UnitofMeasure: Record "Unit of Measure";
        MockPriceWorksheetLine: TestPage "Mock Price Worksheet Line";
    begin
        // [FEATURE] [Asset] [Resource] [Unit Of Measure]
        Initialize();
        // [GIVEN] Resource 'R', and one UoM 'X'
        LibraryResource.CreateResource(Resource, '');
        ResourceUnitofMeasure.SetRange("Resource No.", Resource."No.");
        ResourceUnitofMeasure.DeleteAll();
        LibraryInventory.CreateUnitOfMeasureCode(UnitofMeasure);
        LibraryResource.CreateResourceUnitOfMeasure(ResourceUnitofMeasure, Resource."No.", UnitofMeasure.Code, 1);
        // [GIVEN] Price Worksheet Line, where "Asset Type" is Resource, "Asset No."" is 'R'
        PriceWorksheetLine.Init();
        PriceWorksheetLine.Validate("Asset Type", "Price Asset Type"::Resource);
        PriceWorksheetLine.Validate("Asset No.", Resource."No.");
        PriceWorksheetLine.Insert();

        // [WHEN] Lookup Unit Of Measure in Line
        MockPriceWorksheetLine.Trap();
        Page.Run(Page::"Mock Price Worksheet Line", PriceWorksheetLine);
        MockPriceWorksheetLine."Unit of Measure Code".Lookup();

        // [THEN] Page "Item Unit Of Measure" shows one record with 'X'
        Assert.AreEqual(ResourceUnitofMeasure.Code, LibraryVariableStorage.DequeueText(), 'UoM Code');
        Assert.AreEqual(
            ResourceUnitofMeasure."Qty. per Unit of Measure",
            LibraryVariableStorage.DequeueDecimal(), 'Qty. per Unit of Measure');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'Next line is found');
    end;

    [Test]
    procedure T005_ValidateNonexistingPriceListCode()
    var
        PriceListHeader: Record "Price List Header";
        PriceWorksheetLine: Record "Price Worksheet Line";
        PriceListCode: Code[20];
    begin
        Initialize();

        PriceListHeader.DeleteAll();
        PriceListCode := LibraryUtility.GenerateGUID();
        asserterror PriceWorksheetLine.Validate("Price List Code", PriceListCode);

        Assert.ExpectedError(StrSubstNo(WrongPriceListCodeErr, PriceListCode));
    end;

    [Test]
    procedure T006_ValidateExistingPriceListCode()
    var
        PriceListHeader: Record "Price List Header";
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        Initialize();

        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Sale, "Price Source Type"::Customer, LibrarySales.CreateCustomerNo());
        PriceWorksheetLine.Validate("Price List Code", PriceListHeader.Code);

        PriceWorksheetLine.Testfield("Price List Code", PriceListHeader.Code);
    end;

    [Test]
    procedure T007_InsertLineForPriceListWithSourceTypeAll()
    var
        PriceListHeader: Record "Price List Header";
        PriceWorksheetLine: Record "Price Worksheet Line";
        CustomerNo: Code[20];
    begin
        Initialize();
        // [GIVEN] Price List Header 'X', where "Source Type" is 'All', "Source No." is <blank>, "Price Type" is 'Any', "Amount Type" is 'Any'
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Sale, "Price Source Type"::All, '');
        PriceListHeader."Amount Type" := PriceListHeader."Amount Type"::Any;
        PriceListHeader."Price Type" := "Price Type"::Any;
        // [GIVEN] all other header's fields are filled with data
        PriceListHeader."Starting Date" := WorkDate();
        PriceListHeader."Ending Date" := WorkDate() + 10;
        PriceListHeader."Allow Invoice Disc." := true;
        PriceListHeader."Allow Line Disc." := true;
        PriceListHeader."Price Includes VAT" := true;
        PriceListHeader."VAT Bus. Posting Gr. (Price)" := LibraryUtility.GenerateGUID();
        PriceListHeader.Modify();
        // [GIVEN] Fill the Line, where "Price List Code" is 'X', "Source Type" is 'Customer', "Source No." is 'C', 
        PriceWorksheetLine.Init();
        PriceWorksheetLine.Validate("Price List Code", PriceListHeader.Code);
        PriceWorksheetLine.Validate("Source Type", "Price Source Type"::Customer);
        CustomerNo := LibrarySales.CreateCustomerNo();
        PriceWorksheetLine.Validate("Source No.", CustomerNo);
        // [GIVEN] "Amount Type" is 'Price', "Price Type" is 'Sale'
        PriceWorksheetLine.Validate("Price Type", "Price Type"::Sale);
        PriceWorksheetLine.Validate("Amount Type", PriceWorksheetLine."Amount Type"::Price);
        // [WHEN] Insert the line
        PriceWorksheetLine.Insert(true);
        // [THEN] Header's fields are not copied, "Line No." is not 0,
        PriceWorksheetLine.TestField("Line No.");
        PriceWorksheetLine.TestField("Starting Date", 0D);

        // [WHEN] Validate "Asset Type"
        PriceWorksheetLine.Validate("Asset Type", "Price Asset Type"::Item);

        // [THEN] Line where,  "Source Type" is 'All', "Source No." is ''
        PriceWorksheetLine.TestField("Source Type", "Price Source Type"::All);
        PriceWorksheetLine.TestField("Source No.", '');
        // [GIVEN] "Amount Type" is 'Price', "Price Type" is 'Any'
        PriceWorksheetLine.TestField("Price Type", "Price Type"::Any);
        PriceWorksheetLine.TestField("Amount Type", PriceWorksheetLine."Amount Type"::Price);
        // [THEN] Other fields are copied from the header
        PriceWorksheetLine.TestField("Starting Date", PriceListHeader."Starting Date");
        PriceWorksheetLine.TestField("Ending Date", PriceListHeader."Ending Date");
        PriceWorksheetLine.TestField("Allow Invoice Disc.", PriceListHeader."Allow Invoice Disc.");
        PriceWorksheetLine.TestField("Allow Line Disc.", PriceListHeader."Allow Line Disc.");
        PriceWorksheetLine.TestField("Price Includes VAT", PriceListHeader."Price Includes VAT");
        PriceWorksheetLine.TestField("VAT Bus. Posting Gr. (Price)", PriceListHeader."VAT Bus. Posting Gr. (Price)");
    end;

    [Test]
    procedure T008_InsertLineForPriceListWithSourceTypeNotAll()
    var
        Item: Record Item;
        PriceListHeader: Record "Price List Header";
        PriceWorksheetLine: Record "Price Worksheet Line";
        SourceNo: Code[20];
    begin
        Initialize();
        // [GIVEN] Price List Header 'X', where "Source Type" is 'Vendor', "Source No." is 'V', "Price Type" is 'Any', "Amount Type" is 'Any'
        SourceNo := LibraryPurchase.CreateVendorNo();
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Purchase, "Price Source Type"::Vendor, SourceNo);
        PriceListHeader."Amount Type" := PriceListHeader."Amount Type"::Price;
        PriceListHeader."Price Type" := "Price Type"::Purchase;
        // [GIVEN] all other header's fields are filled with data
        PriceListHeader."Starting Date" := WorkDate();
        PriceListHeader."Ending Date" := WorkDate() + 10;
        PriceListHeader."Allow Invoice Disc." := true;
        PriceListHeader."Allow Line Disc." := true;
        PriceListHeader."Price Includes VAT" := true;
        PriceListHeader."VAT Bus. Posting Gr. (Price)" := LibraryUtility.GenerateGUID();
        PriceListHeader.Modify();
        // [GIVEN] Fill the Line, where "Price List Code" is 'X', "Source Type" is 'Customer', "Source No." is 'C', 
        PriceWorksheetLine.Init();
        PriceWorksheetLine.Validate("Price List Code", PriceListHeader.Code);
        PriceWorksheetLine."Source Type" := "Price Source Type"::Customer;
        PriceWorksheetLine."Source No." := LibrarySales.CreateCustomerNo();
        // [GIVEN] "Amount Type" is 'Price', "Price Type" is 'Sale'
        PriceWorksheetLine."Price Type" := "Price Type"::Sale;
        PriceWorksheetLine."Amount Type" := PriceWorksheetLine."Amount Type"::Price;

        // [WHEN] Insert the line
        PriceWorksheetLine.Insert(true);
        // [THEN] Header's fields are not copied, "Line No." is not 0,
        PriceWorksheetLine.TestField("Line No.");
        PriceWorksheetLine.TestField("Price Type", "Price Type"::Sale);

        // [WHEN] Validate "Asset Type"
        PriceWorksheetLine.Validate("Asset Type", "Price Asset Type"::Item);

        // [THEN] Line inserted, all fields are copied from the header
        PriceWorksheetLine.TestField("Source Type", PriceListHeader."Source Type");
        PriceWorksheetLine.TestField("Source No.", PriceListHeader."Source No.");
        PriceWorksheetLine.TestField("Price Type", PriceListHeader."Price Type");
        PriceWorksheetLine.TestField("Starting Date", PriceListHeader."Starting Date");
        PriceWorksheetLine.TestField("Ending Date", PriceListHeader."Ending Date");
        PriceWorksheetLine.TestField("Allow Invoice Disc.", PriceListHeader."Allow Invoice Disc.");
        PriceWorksheetLine.TestField("Allow Line Disc.", PriceListHeader."Allow Line Disc.");
        PriceWorksheetLine.TestField("Price Includes VAT", PriceListHeader."Price Includes VAT");
        PriceWorksheetLine.TestField("VAT Bus. Posting Gr. (Price)", PriceListHeader."VAT Bus. Posting Gr. (Price)");

        // [GIVEN] Item 'I', where "Price Includes VAT" = false
        LibraryInventory.CreateItem(Item);
        Item.Validate("Price Includes VAT", not PriceListHeader."Price Includes VAT");
        Item.Modify();

        // [WHEN] Validate "Asset No." as 'I'
        PriceWorksheetLine.Validate("Asset No.", Item."No.");

        // [THEN] "Price Includes VAT" is equal to the header's value
        PriceWorksheetLine.TestField("Price Includes VAT", PriceListHeader."Price Includes VAT");
    end;

    [Test]
    procedure T009_AssetTypeAllAutoconvertedToItem()
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [WHEN] New price worksheet line
        PriceWorksheetLine.Init();
        // [THEN] Default "Asset Type" is Item
        PriceWorksheetLine.TestField("Asset Type", "Price Asset Type"::Item);
        // [WHEN] Change "Asset Type" to '(All)'
        PriceWorksheetLine.Validate("Asset Type", "Price Asset Type"::" ");
        // [THEN] "Asset Type" is Item
        PriceWorksheetLine.Validate("Asset Type", "Price Asset Type"::Item);
    end;

    [Test]
    procedure T010_ValidateSourceNo()
    var
        Customer: Record Customer;
        MockPriceWorksheetLine: TestPage "Mock Price Worksheet Line";
    begin
        // [FEATURE] [Source]
        Initialize();
        // [GIVEN] Customer 'C', SystemID is 'X'
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] Price Line, where "Source Type" is 'Customer'
        MockPriceWorksheetLine.OpenEdit();
        MockPriceWorksheetLine."Source Type".SetValue("Price Source Type"::Customer);
        // [WHEN] Enter "Source No." set as 'C'
        MockPriceWorksheetLine."Source No.".SetValue(Customer."No.");
        // [THEN] "Source No." is 'C', "Source ID" is 'X'
        MockPriceWorksheetLine."Source No.".AssertEquals(Customer."No.");
        MockPriceWorksheetLine."Source ID".AssertEquals(Customer.SystemId);
    end;

    [Test]
    procedure T011_ReValidateSourceType()
    var
        Customer: Record Customer;
        MockPriceWorksheetLine: TestPage "Mock Price Worksheet Line";
    begin
        // [FEATURE] [Source]
        // [SCENARIO] Revalidated unchanged "Source Type" does blank the source
        Initialize();
        // [GIVEN] Customer 'C'
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] Price Line, where "Source Type" is 'Customer', "Source No." is 'C'
        MockPriceWorksheetLine.OpenEdit();
        MockPriceWorksheetLine."Source Type".SetValue("Price Source Type"::Customer);
        MockPriceWorksheetLine."Source No.".SetValue(Customer."No.");
        // [WHEN] "Source Type" set as 'Customer'
        MockPriceWorksheetLine."Source Type".SetValue("Price Source Type"::Customer);
        // [THEN] "Source Type" is 'Customer', "Source No." is <blank>
        MockPriceWorksheetLine."Source No.".AssertEquals('');
    end;

    [Test]
    procedure T012_ValidateParentSourceNo()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        MockPriceWorksheetLine: TestPage "Mock Price Worksheet Line";
    begin
        // [FEATURE] [Source]
        Initialize();
        // [GIVEN] Job Task 'JT', where Job is 'J'
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        // [GIVEN] Price Line, where "Source Type" is 'Job Task', "Parent Source No." is 'J'
        MockPriceWorksheetLine.OpenEdit();
        MockPriceWorksheetLine."Source Type".SetValue("Price Source Type"::"Job Task");
        MockPriceWorksheetLine."Parent Source No.".SetValue(JobTask."Job No.");
        // [WHEN] Enter "Source No." as 'JT'
        MockPriceWorksheetLine."Source No.".SetValue(JobTask."Job Task No.");
        // [THEN] "Source No." is 'JT',"Parent Source No." is 'J'
        MockPriceWorksheetLine."Source No.".AssertEquals(JobTask."Job Task No.");
        MockPriceWorksheetLine."Parent Source No.".AssertEquals(JobTask."Job No.");
    end;

    [Test]
    procedure T013_ValidateSourceID()
    var
        Customer: Record Customer;
        MockPriceWorksheetLine: TestPage "Mock Price Worksheet Line";
    begin
        // [FEATURE] [Source]
        Initialize();
        // [GIVEN] Customer 'C', where SystemID is 'X'
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] Price Line, where "Source Type" is 'Customer', "Source No." is 'C'
        MockPriceWorksheetLine.OpenEdit();
        MockPriceWorksheetLine."Source Type".SetValue("Price Source Type"::Customer);
        // [WHEN] "Source ID" set as 'X'
        MockPriceWorksheetLine."Source ID".SetValue(Customer.SystemId);
        // [THEN] "Source Type" is 'Customer', "Source No." is 'C'
        MockPriceWorksheetLine."Source Type".AssertEquals("Price Source Type"::Customer);
        MockPriceWorksheetLine."Source No.".AssertEquals(Customer."No.");
    end;

    [Test]
    [HandlerFunctions('LookupCustomerModalHandler')]
    procedure T014_LookupSourceNo()
    var
        Customer: Record Customer;
        MockPriceWorksheetLine: TestPage "Mock Price Worksheet Line";
    begin
        // [FEATURE] [Source]
        Initialize();
        // [GIVEN] Customer 'C', SystemID is 'X'
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] Price Line, where "Source Type" is 'Customer'
        MockPriceWorksheetLine.OpenEdit();
        MockPriceWorksheetLine."Source Type".SetValue("Price Source Type"::Customer);
        // [WHEN] Lookup "Source No." set as 'C'
        LibraryVariableStorage.Enqueue(Customer."No."); // for LookupCustomerModalHandler
        MockPriceWorksheetLine."Source No.".Lookup();

        // [THEN] "Source No." is 'C', "Source ID" is 'X'
        MockPriceWorksheetLine."Source No.".AssertEquals(Customer."No.");
        MockPriceWorksheetLine."Source ID".AssertEquals(Customer.SystemId);
    end;

    [Test]
    [HandlerFunctions('LookupJobModalHandler,LookupJobTaskModalHandler')]
    procedure T015_LookupParentSourceNo()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        MockPriceWorksheetLine: TestPage "Mock Price Worksheet Line";
    begin
        // [FEATURE] [Source]
        Initialize();
        // [GIVEN] Job Task 'JT', where Job is 'J'
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        // [GIVEN] Price Line, where "Source Type" is 'Job Task', "Parent Source No." is 'J'
        MockPriceWorksheetLine.OpenEdit();
        MockPriceWorksheetLine."Source Type".SetValue("Price Source Type"::"Job Task");
        // [WHEN] Lookup "Source No."
        LibraryVariableStorage.Enqueue(JobTask."Job No."); // for LookupJobModalHandler
        LibraryVariableStorage.Enqueue(JobTask."Job Task No."); // for LookupJobTaskModalHandler
        MockPriceWorksheetLine."Source No.".Lookup();

        // [THEN] "Source No." is 'JT',"Parent Source No." is 'J'
        MockPriceWorksheetLine."Parent Source No.".AssertEquals(JobTask."Job No.");
    end;

    [Test]
    [HandlerFunctions('LookupItemModalHandler')]
    procedure T016_LookupAssetNo()
    var
        Item: Record Item;
        MockPriceWorksheetLine: TestPage "Mock Price Worksheet Line";
    begin
        // [FEATURE] [Asset]
        Initialize();
        // [GIVEN] Item 'I'
        LibraryInventory.CreateItem(Item);
        // [GIVEN] Price Line, where "Asset Type" is 'Item'
        MockPriceWorksheetLine.OpenEdit();
        MockPriceWorksheetLine."Asset Type".SetValue("Price Asset Type"::Item);
        // [WHEN] Lookup "Asset No." set as 'I'
        LibraryVariableStorage.Enqueue(Item."No."); // for LookupItemModalHandler
        MockPriceWorksheetLine."Asset No.".Lookup();

        // [THEN] "Asset No." is 'I'
        MockPriceWorksheetLine."Asset No.".AssertEquals(Item."No.");
    end;

    [Test]
    procedure T017_SourceTypeInLineMustBeTheSameIfSourceNoDefined()
    var
        Job: Record Job;
        PriceListHeader: Record "Price List Header";
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        Initialize();
        // [GIVEN] Price List Header, where all fields are filled, "Source Type" = 'Job', "Source No." is 'J'
        LibraryJob.CreateJob(Job);
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Purchase, "Price Source Type"::Job, Job."No.");
        // [GIVEN] One line added
        PriceWorksheetLine.Init();
        PriceWorksheetLine."Price List Code" := PriceListHeader.Code;
        PriceWorksheetLine.Insert(true);

        // [WHEN] set "Source Type" as 'Job Task' in the line
        asserterror PriceWorksheetLine.Validate("Source Type", "Price Source Type"::"Job Task");
        // [THEN] Error message: "Source Type must be equal to Job"
        Assert.ExpectedTestFieldError(PriceWorksheetLine.FieldCaption("Source Type"), Format(PriceWorksheetLine."Source Type"::Job));
    end;

    [Test]
    procedure T018_SourceTypeInLineMustBeLowerHeadersSourceType()
    var
        Job: Record Job;
        PriceListHeader: Record "Price List Header";
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        Initialize();
        // [GIVEN] Price List Header, where all fields are filled, "Source Type" = 'Job', "Source No." is <blank>
        LibraryJob.CreateJob(Job);
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Purchase,
            "Price Source Type"::Job, Job."No.");
        PriceListHeader.Validate("Source No.", '');
        PriceListHeader.Modify();
        // [GIVEN] One line added
        PriceWorksheetLine.Init();
        PriceWorksheetLine."Price List Code" := PriceListHeader.Code;
        PriceWorksheetLine.Insert(true);

        // [WHEN] set "Source Type" as 'All Jobs' in the line
        asserterror PriceWorksheetLine.Validate("Source Type", "Price Source Type"::"All Jobs");
        // [THEN] Error message: "Cannot set All Jobs if header's source type is Job"
        Assert.ExpectedError(
            StrSubstNo(LineSourceTypeErr, "Price Source Type"::"All Jobs", "Price Source Type"::Job));
    end;

    [Test]
    procedure T019_SourceTypeInLineMustBeInTheHeadersSourceGroup()
    var
        PriceListHeader: Record "Price List Header";
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        Initialize();
        // [GIVEN] Price List Header, where all fields are filled, "Source Type" = 'All Custromers'
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        // [GIVEN] One line added
        PriceWorksheetLine.Init();
        PriceWorksheetLine."Price List Code" := PriceListHeader.Code;
        PriceWorksheetLine.Insert(true);

        // [WHEN] set "Source Type" as 'Vendor' in the line
        asserterror PriceWorksheetLine.Validate("Source Type", "Price Source Type"::Vendor);
        // [THEN] Error message: "Cannot set Vendor if header's source type is All Customers"
        Assert.ExpectedError(
            StrSubstNo(LineSourceTypeErr, "Price Source Type"::Vendor, "Price Source Type"::"All Customers"));
    end;

    [Test]
    procedure T020_InsertNewLineDoesNotControlConsistency()
    var
        TempPriceWorksheetLine: Record "Price Worksheet Line" temporary;
        LineNo: Integer;
    begin
        // [SCENARIO] OnInsert() does not control data consistency, does not increments "Line No." for the temp record.
        Initialize();
        // [GIVEN] Price Worksheet Line, where "Source Type" is 'Customer', "Asset Type" is 'Item', but "Source No." and "Asset No." are blank, 
        LineNo := LibraryRandom.RandInt(100);
        TempPriceWorksheetLine."Line No." := LineNo;
        TempPriceWorksheetLine.Validate("Source Type", "Price Source Type"::Customer);
        TempPriceWorksheetLine.Validate("Asset Type", "Price Asset Type"::Item);
        // [WHEN] Insert temporary line 
        TempPriceWorksheetLine.Insert(true);
        // [THEN] "Line No." is not changed
        TempPriceWorksheetLine.TestField("Line No.", LineNo);
    end;

    [Test]
    procedure T021_UnitPriceBlanksCostFactor()
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [SCENARIO] "Unit Price" validation with a non-zero value blanks "Cost Factor".
        Initialize();
        PriceWorksheetLine."Source Type" := "Price Source Type"::"All Customers";
        PriceWorksheetLine."Asset Type" := "Price Asset Type"::"G/L Account";
        PriceWorksheetLine."Asset No." := LibraryERM.CreateGLAccountNo();

        PriceWorksheetLine."Cost Factor" := 1.2;
        PriceWorksheetLine.Validate("Unit Price", 0);
        PriceWorksheetLine.TestField("Cost Factor", 1.2);

        PriceWorksheetLine.Validate("Unit Price", 10);
        PriceWorksheetLine.TestField("Cost Factor", 0);
        PriceWorksheetLine.TestField("Unit Price", 10);
    end;

    [Test]
    procedure T022_CostFactorBlanksUnitPrice()
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [SCENARIO] "Cost Factor" validation with a non-zero value blanks "Unit Price".
        Initialize();
        PriceWorksheetLine.Validate("Source Type", "Price Source Type"::"All Jobs");
        PriceWorksheetLine."Asset Type" := "Price Asset Type"::"G/L Account";
        PriceWorksheetLine."Asset No." := LibraryERM.CreateGLAccountNo();

        PriceWorksheetLine."Unit Price" := 10.15;
        PriceWorksheetLine.Validate("Cost Factor", 0);
        PriceWorksheetLine.TestField("Unit Price", 10.15);

        PriceWorksheetLine.Validate("Cost Factor", 0.98);
        PriceWorksheetLine.TestField("Unit Price", 0);
        PriceWorksheetLine.TestField("Cost Factor", 0.98);
    end;

    [Test]
    procedure T023_UnitPriceCostFactorNotAllowedForDiscountLine()
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [SCENARIO] "Unit Price" validation fails in Discount line
        Initialize();
        PriceWorksheetLine."Amount Type" := PriceWorksheetLine."Amount Type"::Discount;
        asserterror PriceWorksheetLine.Validate("Unit Price", 1);
        Assert.ExpectedError(
            StrSubstNo(
                FieldNotAllowedForAmountTypeErr, PriceWorksheetLine.FieldCaption("Unit Price"),
                PriceWorksheetLine.FieldCaption("Amount Type"), PriceWorksheetLine."Amount Type"::Discount));

        asserterror PriceWorksheetLine.Validate("Cost Factor", 1);
        Assert.ExpectedError(
            StrSubstNo(
                FieldNotAllowedForAmountTypeErr, PriceWorksheetLine.FieldCaption("Cost Factor"),
                PriceWorksheetLine.FieldCaption("Amount Type"), PriceWorksheetLine."Amount Type"::Discount));
    end;

    [Test]
    procedure T024_UnitCostDirectUnitCostNotAllowedForDiscountLine()
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [SCENARIO] "Cost Factor" validation fails in Discount line
        Initialize();
        PriceWorksheetLine.Validate("Source Type", "Price Source Type"::"Customer Disc. Group");
        asserterror PriceWorksheetLine.Validate("Unit Cost", 1);
        Assert.ExpectedError(
            StrSubstNo(
                FieldNotAllowedForAmountTypeErr, PriceWorksheetLine.FieldCaption("Unit Cost"),
                PriceWorksheetLine.FieldCaption("Amount Type"), PriceWorksheetLine."Amount Type"::Discount));

        asserterror PriceWorksheetLine.Validate("Direct Unit Cost", 1);
        Assert.ExpectedError(
            StrSubstNo(
                FieldNotAllowedForAmountTypeErr, PriceWorksheetLine.FieldCaption("Direct Unit Cost"),
                PriceWorksheetLine.FieldCaption("Amount Type"), PriceWorksheetLine."Amount Type"::Discount));
    end;

    [Test]
    procedure T025_AllowLineDiscNotAllowedForDiscountLine()
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [SCENARIO] "Allow Line Disc." validation fails in Discount line
        Initialize();
        PriceWorksheetLine."Amount Type" := PriceWorksheetLine."Amount Type"::Discount;
        asserterror PriceWorksheetLine.Validate("Allow Line Disc.", true);
        Assert.ExpectedError(
            StrSubstNo(
                FieldNotAllowedForAmountTypeErr, PriceWorksheetLine.FieldCaption("Allow Line Disc."),
                PriceWorksheetLine.FieldCaption("Amount Type"), PriceWorksheetLine."Amount Type"::Discount));
    end;

    [Test]
    procedure T026_AllowInvDiscNotAllowedForDiscountLine()
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [SCENARIO] "Allow Invoice Disc." validation fails in Discount line
        Initialize();
        PriceWorksheetLine."Amount Type" := PriceWorksheetLine."Amount Type"::Discount;
        asserterror PriceWorksheetLine.Validate("Allow Invoice Disc.", true);
        Assert.ExpectedError(
            StrSubstNo(
                FieldNotAllowedForAmountTypeErr, PriceWorksheetLine.FieldCaption("Allow Invoice Disc."),
                PriceWorksheetLine.FieldCaption("Amount Type"), PriceWorksheetLine."Amount Type"::Discount));
    end;

    [Test]
    procedure T027_LineDiscPctNotAllowedForPriceLine()
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [SCENARIO] "Line Discount %" validation fails in Price line for "Customer Price Group"
        Initialize();
        PriceWorksheetLine.Validate("Source Type", "Price Source Type"::"Customer Price Group");
        asserterror PriceWorksheetLine.Validate("Line Discount %", 3);
        Assert.ExpectedError(
            StrSubstNo(
                FieldNotAllowedForAmountTypeErr, PriceWorksheetLine.FieldCaption("Line Discount %"),
                PriceWorksheetLine.FieldCaption("Amount Type"), PriceWorksheetLine."Amount Type"::Price));
    end;

    [Test]
    procedure T028_DefaultAmountTypeOnSourceTypeValidation()
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [SCENARIO] Default "Amount Type" depends on source type. 
        Initialize();
        PriceWorksheetLine.DeleteAll();
        // [WHEN] Set "Source Type" as "Customer Disc. Group" in Price list header
        PriceWorksheetLine.Validate("Source Type", "Price Source Type"::"Customer Price Group");
        // [THEN] "Amount Type" is 'Price'
        PriceWorksheetLine.TestField("Amount Type", "Price Amount Type"::Price);

        // [WHEN] Set "Source Type" as "Customer Disc. Group" in Price list header
        PriceWorksheetLine.Validate("Source Type", "Price Source Type"::"Customer Disc. Group");
        // [THEN] "Amount Type" is 'Discount'
        PriceWorksheetLine.TestField("Amount Type", "Price Amount Type"::Discount);

        // [WHEN] Set "Source Type" as "Customer" in Price list header
        PriceWorksheetLine.Validate("Source Type", "Price Source Type"::Customer);
        // [THEN] "Amount Type" is 'Price'
        PriceWorksheetLine.TestField("Amount Type", "Price Amount Type"::Any);
    end;

    [Test]
    procedure T029_ValidateAmountType()
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [SCENARIO] Cannot change "Amount Type" for source types "Customer Disc. Group", "Customer Price Group"
        Initialize();
        PriceWorksheetLine.Init();
        // [WHEN] Set "Source Type" as "Customer Disc. Group" in Price list header
        PriceWorksheetLine."Source Type" := "Price Source Type"::"Customer Disc. Group";
        // [THEN] Can change "Amount Type" to 'Discount'
        PriceWorksheetLine.Validate("Amount Type", "Price Amount Type"::Discount);
        // [THEN] Cannot change "Amount Type" to 'Price' or 'Any'
        asserterror PriceWorksheetLine.Validate("Amount Type", "Price Amount Type"::Price);
        asserterror PriceWorksheetLine.Validate("Amount Type", "Price Amount Type"::Any);

        PriceWorksheetLine.Init();
        // [WHEN] Set "Source Type" as "Customer Disc. Group" in Price list header
        PriceWorksheetLine."Source Type" := "Price Source Type"::"Customer Price Group";
        // [THEN] Can change "Amount Type" to 'Price'
        PriceWorksheetLine.Validate("Amount Type", "Price Amount Type"::Price);
        // [THEN] Cannot change "Amount Type" to 'Discount' or 'Any'
        asserterror PriceWorksheetLine.Validate("Amount Type", "Price Amount Type"::Discount);
        asserterror PriceWorksheetLine.Validate("Amount Type", "Price Amount Type"::Any);

        PriceWorksheetLine.Init();
        // [WHEN] Set "Source Type" as "Customer" in Price list header
        PriceWorksheetLine."Source Type" := "Price Source Type"::Customer;
        // [THEN] Can change "Amount Type" to 'Any', 'Discount', or 'Price'
        PriceWorksheetLine.Validate("Amount Type", "Price Amount Type"::Price);
        PriceWorksheetLine.TestField("Amount Type", "Price Amount Type"::Price);
        PriceWorksheetLine.Validate("Amount Type", "Price Amount Type"::Any);
        PriceWorksheetLine.TestField("Amount Type", "Price Amount Type"::Any);
        PriceWorksheetLine.Validate("Amount Type", "Price Amount Type"::Discount);
        PriceWorksheetLine.TestField("Amount Type", "Price Amount Type"::Discount);
    end;

    [Test]
    procedure T030_WorkTypeCodeNotAllowedForItem()
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [FEATURE] [Work Type] [Item]
        // [SCENARIO] "Work Type Code" must not be filled for product type 'Item'
        Initialize();
        // [GIVEN] Price Worksheet Line, where "Asset Type" is 'Item' 
        PriceWorksheetLine.Validate("Asset Type", "Price Asset Type"::Item);
        // [WHEN] Validate "Work Type Code" with a valid code
        asserterror PriceWorksheetLine.Validate("Work Type Code", GetWorkTypeCode());
        // [THEN] Error message: 'Asset Type must be Resource'
        Assert.ExpectedTestFieldError(PriceWorksheetLine.FieldCaption("Asset Type"), Format(PriceWorksheetLine."Asset Type"::Resource));
    end;

    [Test]
    procedure T031_WorkTypeCodeAllowedForResource()
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
        Resource: Record Resource;
        WorkType: Record "Work Type";
    begin
        // [FEATURE] [Work Type] [Resource]
        // [SCENARIO] "Work Type Code" can be filled for product type 'Resource'
        Initialize();
        // [GIVEN] Price Worksheet Line, where "Asset Type" is 'Resource', "Asset No." is 'R'
        PriceWorksheetLine.Validate("Asset Type", "Price Asset Type"::Resource);
        LibraryResource.CreateResource(Resource, '');
        PriceWorksheetLine.Validate("Asset No.", Resource."No.");
        // [GIVEN] Work Group 'WT', where "Unit of Measure Code" is <blank>
        WorkType.Get(GetWorkTypeCode());
        WorkType."Unit of Measure Code" := '';
        WorkType.Modify();

        // [WHEN] Validate "Work Type Code" with a valid code 'WT'
        PriceWorksheetLine.Validate("Work Type Code", WorkType.Code);

        // [THEN] 'Work Type Code' is 'WT', "Unit of Measure Code" is 'R-UOM'
        PriceWorksheetLine.TestField("Work Type Code", WorkType.Code);
        PriceWorksheetLine.TestField("Unit of Measure Code", Resource."Base Unit of Measure");
    end;

    [Test]
    procedure T032_WorkTypeCodeAllowedForResourceGroup()
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
        ResourceGroup: Record "Resource Group";
        UnitofMeasure: Record "Unit of Measure";
        WorkType: Record "Work Type";
    begin
        // [FEATURE] [Work Type] [Resource Group]
        // [SCENARIO] "Work Type Code" can be filled for product type 'Resource Group'
        Initialize();
        // [GIVEN] Price Worksheet Line, where "Asset Type" is 'Resource', "Asset No." is 'R'
        PriceWorksheetLine.Validate("Asset Type", "Price Asset Type"::"Resource Group");
        LibraryResource.CreateResourceGroup(ResourceGroup);
        PriceWorksheetLine.Validate("Asset No.", ResourceGroup."No.");
        // [GIVEN] Work Group 'WT', where "Unit of Measure Code" is 'X'
        WorkType.Get(GetWorkTypeCode());
        LibraryInventory.CreateUnitOfMeasureCode(UnitofMeasure);
        WorkType."Unit of Measure Code" := UnitofMeasure.Code;
        WorkType.Modify();

        // [WHEN] Validate "Work Type Code" with a valid code 'WT'
        PriceWorksheetLine.Validate("Work Type Code", WorkType.Code);

        // [THEN] 'Work Type Code' is 'WT', "Unit of Measure Code" is 'X'
        PriceWorksheetLine.TestField("Work Type Code", WorkType.Code);
        PriceWorksheetLine.TestField("Unit of Measure Code", WorkType."Unit of Measure Code");
    end;

    [Test]
    procedure T033_UnitOfMeasureAllowedForResourceGroup()
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
        ResourceGroup: Record "Resource Group";
        UnitofMeasure: Record "Unit of Measure";
    begin
        // [FEATURE] [Resource Group] [Unit of Measure]
        // [SCENARIO] "Unit of Measure Code" can be filled for product type 'Resource Group'
        Initialize();
        // [GIVEN] Price Worksheet Line, where "Asset Type" is 'Resource', "Asset No." is 'R'
        PriceWorksheetLine.Validate("Asset Type", "Price Asset Type"::"Resource Group");
        LibraryResource.CreateResourceGroup(ResourceGroup);
        PriceWorksheetLine.Validate("Asset No.", ResourceGroup."No.");

        // [WHEN] Validate "Unit of Measure Code" with a valid code 'UOM'
        LibraryInventory.CreateUnitOfMeasureCode(UnitofMeasure);
        PriceWorksheetLine.Validate("Unit of Measure Code", UnitofMeasure.Code);

        // [THEN] "Unit of Measure Code" is 'UOM'
        PriceWorksheetLine.Validate("Unit of Measure Code", UnitofMeasure.Code);
    end;

    [Test]
    procedure T034_UnitOfMeasureAllowedForResource()
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
        Resource: Record Resource;
        ResourceUnitofMeasure: Record "Resource Unit of Measure";
        UnitofMeasure: Record "Unit of Measure";
    begin
        // [FEATURE] [Resource] [Unit of Measure]
        // [SCENARIO] "Unit of Measure Code" can be filled for product type 'Resource'
        Initialize();
        // [GIVEN] Price Worksheet Line, where "Asset Type" is 'Resource', "Asset No." is 'R'
        PriceWorksheetLine.Validate("Asset Type", "Price Asset Type"::Resource);
        LibraryResource.CreateResource(Resource, '');
        PriceWorksheetLine.Validate("Asset No.", Resource."No.");

        // [WHEN] Validate "Unit of Measure Code" with a valid code 'UOM'
        LibraryInventory.CreateUnitOfMeasureCode(UnitofMeasure);
        LibraryResource.CreateResourceUnitOfMeasure(
            ResourceUnitofMeasure, Resource."No.", UnitofMeasure.Code, 1);
        PriceWorksheetLine.Validate("Unit of Measure Code", UnitofMeasure.Code);

        // [THEN] "Unit of Measure Code" is 'UOM'
        PriceWorksheetLine.Validate("Unit of Measure Code", UnitofMeasure.Code);
    end;

    [Test]
    procedure T035_VariantCodeAllowedForItem()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [SCENARIO] "Variant Code" can be filled for product type 'Item'
        Initialize();
        // [GIVEN] Price Worksheet Line, where "Asset Type" is 'Item', "Asset No." is 'I' 
        PriceWorksheetLine.Validate("Asset Type", "Price Asset Type"::Item);
        LibraryInventory.CreateItem(Item);
        PriceWorksheetLine.Validate("Asset No.", Item."No.");
        // [WHEN] Validate "Variant Code" with a valid code 'V'
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        PriceWorksheetLine.Validate("Variant Code", ItemVariant.Code);
        // [THEN] "Variant Code" is 'V'
        PriceWorksheetLine.TestField("Variant Code", ItemVariant.Code);
    end;

    [Test]
    procedure T036_VariantCodeNoAllowedForBlankItem()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [SCENARIO] "Variant Code" cannot be filled for product type 'Item', but blank "Asset No."
        Initialize();
        // [GIVEN] Price Worksheet Line, where "Asset Type" is 'Item', "Asset No." is <blank> 
        PriceWorksheetLine.Validate("Asset Type", "Price Asset Type"::Item);
        PriceWorksheetLine.Validate("Asset No.", '');
        // [WHEN] Validate "Variant Code" with a valid code 'V'
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        asserterror PriceWorksheetLine.Validate("Variant Code", ItemVariant.Code);
        // [THEN] Error message: 'Asset No. must have a value.'
        Assert.ExpectedError(AssetNoMustHaveValueErr);
    end;

    [Test]
    procedure T037_ValidateUnitPriceWithBlankAssetType()
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [SCENARIO] "Unit Price" cannot be filled if "Asset Type" is blank.
        Initialize();
        // [GIVEN] Price Worksheet Line, where "Asset Type" is 'All', "Asset No." is <blank> 
        PriceWorksheetLine.Validate("Price Type", "Price Type"::Sale);
        PriceWorksheetLine."Asset Type" := "Price Asset Type"::" ";
        // [WHEN] Validate "Unit Price" as 1
        asserterror PriceWorksheetLine.Validate("Unit Price", 1);
        // [THEN] Error message: 'Asset Type must not be (All).'
        Assert.ExpectedError(AssetTypeMustNotBeAllErr);
    end;

    [Test]
    procedure T038_ValidateDirectUnitCostWithBlankAssetType()
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [SCENARIO] "Unit Price" cannot be filled if "Asset Type" is blank.
        Initialize();
        // [GIVEN] Price Worksheet Line, where "Asset Type" is 'All', "Asset No." is <blank> 
        PriceWorksheetLine.Validate("Price Type", "Price Type"::Purchase);
        PriceWorksheetLine."Asset Type" := "Price Asset Type"::" ";
        // [WHEN] Validate "Direct Unit Cost" as 1
        asserterror PriceWorksheetLine.Validate("Direct Unit Cost", 1);
        // [THEN] Error message: 'Asset Type must not be (All).'
        Assert.ExpectedError(AssetTypeMustNotBeAllErr);
    end;

    [Test]
    procedure T039_ValidateLineDiscountPctWithBlankAssetType()
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [SCENARIO] "Line Discount %" cannot be filled if "Asset Type" is blank.
        Initialize();
        // [GIVEN] Price Worksheet Line, where "Asset Type" is 'All', "Asset No." is <blank> 
        PriceWorksheetLine.Validate("Price Type", "Price Type"::Sale);
        PriceWorksheetLine."Asset Type" := "Price Asset Type"::" ";
        // [WHEN] Validate "Line Discount %" as 1
        asserterror PriceWorksheetLine.Validate("Line Discount %", 1);
        // [THEN] Error message: 'Asset Type must not be (All).'
        Assert.ExpectedError(AssetTypeMustNotBeAllErr);
    end;

    [Test]
    procedure T040_AmountTypePriceFromDiscount()
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [SCENARIO] "Amount Type" set to Price, blanks "Line Discount %" and sets "Allows .. Disc" from header
        Initialize();
        PriceWorksheetLine."Amount Type" := PriceWorksheetLine."Amount Type"::Discount;
        PriceWorksheetLine."Line Discount %" := 13.3;
        PriceWorksheetLine."Unit Price" := 0;
        PriceWorksheetLine."Cost Factor" := 0;
        PriceWorksheetLine."Allow Invoice Disc." := false;
        PriceWorksheetLine."Allow Line Disc." := false;

        PriceWorksheetLine.Validate("Amount Type", PriceWorksheetLine."Amount Type"::Price);

        PriceWorksheetLine.TestField("Line Discount %", 0);
        PriceWorksheetLine.TestField("Unit Price", 0);
        PriceWorksheetLine.TestField("Cost Factor", 0);
        PriceWorksheetLine.TestField("Allow Invoice Disc.", false);
        PriceWorksheetLine.TestField("Allow Line Disc.", false);
    end;

    [Test]
    procedure T041_AmountTypePriceWithHeader()
    var
        PriceListHeader: Record "Price List Header";
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [SCENARIO] "Amount Type" set to Price, "Allows .. Disc" are set from header
        Initialize();
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        PriceListHeader."Allow Invoice Disc." := true;
        PriceListHeader."Allow Line Disc." := true;
        PriceListHeader.Modify();

        PriceWorksheetLine.Init();
        PriceWorksheetLine."Price List Code" := PriceListHeader.Code;
        PriceWorksheetLine."Amount Type" := PriceWorksheetLine."Amount Type"::Discount;
        PriceWorksheetLine."Line Discount %" := 13.3;
        PriceWorksheetLine."Unit Price" := 0;
        PriceWorksheetLine."Cost Factor" := 0;
        PriceWorksheetLine."Allow Invoice Disc." := false;
        PriceWorksheetLine."Allow Line Disc." := false;

        PriceWorksheetLine.Validate("Amount Type", PriceWorksheetLine."Amount Type"::Price);

        PriceWorksheetLine.TestField("Line Discount %", 0);
        PriceWorksheetLine.TestField("Unit Price", 0);
        PriceWorksheetLine.TestField("Cost Factor", 0);
        PriceWorksheetLine.TestField("Allow Invoice Disc.", true);
        PriceWorksheetLine.TestField("Allow Line Disc.", true);
    end;

    [Test]
    procedure T042_AmountTypeDiscountFromPrice()
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [SCENARIO] "Amount Type" set to Discount, blanks "Unit Price" and "Allows .. Disc" fields.
        Initialize();
        PriceWorksheetLine."Amount Type" := PriceWorksheetLine."Amount Type"::Price;
        PriceWorksheetLine."Line Discount %" := 0;
        PriceWorksheetLine."Unit Price" := 10;
        PriceWorksheetLine."Cost Factor" := 0.5;
        PriceWorksheetLine."Allow Invoice Disc." := true;
        PriceWorksheetLine."Allow Line Disc." := true;

        PriceWorksheetLine.Validate("Amount Type", PriceWorksheetLine."Amount Type"::Discount);

        PriceWorksheetLine.TestField("Line Discount %", 0);
        PriceWorksheetLine.TestField("Unit Price", 0);
        PriceWorksheetLine.TestField("Cost Factor", 0);
        PriceWorksheetLine.TestField("Allow Invoice Disc.", false);
        PriceWorksheetLine.TestField("Allow Line Disc.", false);
    end;

    [Test]
    procedure T043_AmountTypeMustBeDiscountForItemDiscGroup()
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [SCENARIO] "Amount Type" must be Discount for 'Item Discounnt Group'
        Initialize();

        PriceWorksheetLine.Validate("Asset Type", "Price Asset Type"::"Item Discount Group");
        PriceWorksheetLine.TestField("Amount Type", PriceWorksheetLine."Amount Type"::Discount);

        asserterror PriceWorksheetLine.Validate("Amount Type", PriceWorksheetLine."Amount Type"::Price);
        Assert.ExpectedTestFieldError(PriceWorksheetLine.FieldCaption("Amount Type"), Format(PriceWorksheetLine."Amount Type"::Discount));

        asserterror PriceWorksheetLine.Validate("Amount Type", PriceWorksheetLine."Amount Type"::Any);
        Assert.ExpectedTestFieldError(PriceWorksheetLine.FieldCaption("Amount Type"), Format(PriceWorksheetLine."Amount Type"::Discount));
    end;

    [Test]
    procedure T045_AssetTypeItemDiscGroupNotAllowedForPurchase()
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [FEATURE] [Purchase] [Item Discount Group]
        // [SCENARIO] Product Type 'Item Discount Group' is not allowed for 'Purchase'
        Initialize();

        PriceWorksheetLine."Price Type" := "Price Type"::Purchase;
        asserterror PriceWorksheetLine.Validate("Asset Type", "Price Asset Type"::"Item Discount Group");
        Assert.ExpectedTestFieldError(PriceWorksheetLine.FieldCaption("Asset Type"), Format(PriceWorksheetLine."Asset Type"::"Item Discount Group"));
    end;

    [Test]
    procedure T050_IsEditable()
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [SCENARIO] Price Worksheet Line should be editable only if Status is 'Draft'.
        Initialize();

        PriceWorksheetLine.Status := PriceWorksheetLine.Status::Draft;
        Assert.IsTrue(PriceWorksheetLine.IsEditable(), 'Draft');

        PriceWorksheetLine.Status := PriceWorksheetLine.Status::Active;
        Assert.IsFalse(PriceWorksheetLine.IsEditable(), 'Active');

        PriceWorksheetLine.Status := PriceWorksheetLine.Status::Inactive;
        Assert.IsFalse(PriceWorksheetLine.IsEditable(), 'Inactive')
    end;

    [Test]
    procedure T051_ActiveIsEditableIfEditingAllowed()
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [FEATURE] [Allow Editing Active Price]
        // [SCENARIO] Price Worksheet Line should be editable only if Status is 'Draft' or 'Active' and "Allow Editing Active Price" is on.
        Initialize();
        // [GIVEN] Allow Editing Active Purchase Price
        LibraryPriceCalculation.AllowEditingActivePurchPrice();

        PriceWorksheetLine."Price Type" := "Price Type"::Purchase;
        PriceWorksheetLine.Status := PriceWorksheetLine.Status::Draft;
        Assert.IsTrue(PriceWorksheetLine.IsEditable(), 'Draft');

        PriceWorksheetLine.Status := PriceWorksheetLine.Status::Active;
        Assert.IsTrue(PriceWorksheetLine.IsEditable(), 'Active');

        PriceWorksheetLine.Status := PriceWorksheetLine.Status::Inactive;
        Assert.IsFalse(PriceWorksheetLine.IsEditable(), 'Inactive')
    end;

    [Test]
    procedure T055_CanDeleteActiveLine()
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        Initialize();
        // [GIVEN] Price line, where Status is Draft
        PriceWorksheetLine."Price List Code" := LibraryUtility.GenerateGUID();
        PriceWorksheetLine.Status := PriceWorksheetLine.Status::Draft;
        PriceWorksheetLine."Line No." := 0;
        PriceWorksheetLine.Insert();

        // [WHEN] Delete line with status Draft
        // [THEN] line is deleted
        Assert.IsTrue(PriceWorksheetLine.Delete(true), 'Draft line not deleted');

        // [GIVEN] Price line, where Status is Inactive
        PriceWorksheetLine.Status := PriceWorksheetLine.Status::Inactive;
        PriceWorksheetLine."Line No." := 0;
        PriceWorksheetLine.Insert();
        // [WHEN] Delete line with status Inactive
        // [THEN] line is deleted
        Assert.IsTrue(PriceWorksheetLine.Delete(true), 'Inactive line not deleted');

        // [GIVEN] Price line, where Status is Active
        PriceWorksheetLine.Status := PriceWorksheetLine.Status::Active;
        PriceWorksheetLine."Line No." := 0;
        PriceWorksheetLine.Insert();

        // [WHEN] Delete line with status Active
        // [THEN] line is deleted
        Assert.IsTrue(PriceWorksheetLine.Delete(true), 'Active line not deleted');
    end;

    [Test]
    procedure T056_CanDeleteActiveLineIfEditingAllowed()
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [FEATURE] [Allow Editing Active Price]
        Initialize();
        // [GIVEN] Allow Editing Active Sales Price
        LibraryPriceCalculation.AllowEditingActiveSalesPrice();
        // [GIVEN] Price line, where Status is Active
        PriceWorksheetLine."Price List Code" := LibraryUtility.GenerateGUID();
        PriceWorksheetLine."Price Type" := "Price Type"::Sale;
        PriceWorksheetLine.Status := PriceWorksheetLine.Status::Active;
        PriceWorksheetLine."Line No." := 0;
        PriceWorksheetLine.Insert();

        // [WHEN] Delete line with status Active
        PriceWorksheetLine.Delete(true);
        // [THEN] Line is deleted
        Assert.IsFalse(PriceWorksheetLine.Find(), 'must be deleted');
    end;

    [Test]
    procedure T060_CopyCustomerHeaderToAllCustomersLine()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        Initialize();

        // [GIVEN] Header, where "Price Source Type" is "Customer" 'X', Status 'Active'
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Sale, "Price Source Type"::Customer, LibrarySales.CreateCustomerNo());
        PriceListHeader.Status := "Price Status"::Active;
        PriceListHeader.Modify();

        // [GIVEN] Line, where "Price Source Type" is "All Customers"
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, '', "Price Source Type"::"All Customers", '', "Price Asset Type"::Item, LibraryInventory.CreateItemNo());
        PriceWorksheetLine.TransferFields(PriceListLine);

        // [WHEN] Copy Header to Line
        PriceWorksheetLine.CopyFrom(PriceListHeader);

        // [THEN] Line, where "Price Source Type" is "Customer" 'X', Status is 'Draft'
        PriceWorksheetLine.TestField("Source Type", PriceListHeader."Source Type");
        PriceWorksheetLine.TestField("Source No.", PriceListHeader."Source No.");
        PriceWorksheetLine.TestField(Status, "Price Status"::Draft);
    end;

    [Test]
    procedure T061_CopyAllVendorsHeaderToCustomerLine()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        Initialize();

        // [GIVEN] Header, where "Price Source Type" is "All Vendors"
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Purchase, "Price Source Type"::"All Vendors", '');

        // [GIVEN] Line, where "Price Source Type" is "Customer" 'X'
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, '', "Price Source Type"::Customer, LibrarySales.CreateCustomerNo(),
            "Price Asset Type"::Item, LibraryInventory.CreateItemNo());
        PriceWorksheetLine.TransferFields(PriceListLine);

        // [WHEN] Copy Header to Line
        PriceWorksheetLine.CopyFrom(PriceListHeader);

        // [THEN] Line, where "Price Source Type" is "All Vendors", "Price Type" is 'Purchase'
        PriceWorksheetLine.TestField("Price Type", PriceListHeader."Price Type");
        PriceWorksheetLine.TestField("Source Type", PriceListHeader."Source Type");
        PriceWorksheetLine.TestField("Source No.", PriceListHeader."Source No.");
    end;

    [Test]
    procedure T062_CopyPriceHeaderToDiscountLine()
    var
        ItemDiscountGroup: Record "Item Discount Group";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        Initialize();

        // [GIVEN] Header, where "Amount Type" is "Price"
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        PriceListHeader."Amount Type" := PriceListHeader."Amount Type"::Price;
        PriceListHeader.Modify();

        // [GIVEN] Line, where "Amount Type" is "Discount", "Asset Type" is 'Item Discount Group'
        LibraryERM.CreateItemDiscountGroup(ItemDiscountGroup);
        LibraryPriceCalculation.CreateSalesDiscountLine(
            PriceListLine, '', "Price Source Type"::Customer, LibrarySales.CreateCustomerNo(),
            "Price Asset Type"::Item, LibraryInventory.CreateItemNo());
        PriceWorksheetLine.TransferFields(PriceListLine);

        // [WHEN] Copy Header to Line
        PriceWorksheetLine.CopyFrom(PriceListHeader);

        // [THEN] Line, where "Amount Type" is 'Price', "Line Discount %" is 0.
        PriceWorksheetLine.TestField("Price Type", PriceListHeader."Price Type");
        PriceWorksheetLine.TestField("Amount Type", PriceListHeader."Amount Type");
        PriceWorksheetLine.TestField("Line Discount %", 0);
    end;

    [Test]
    procedure T063_CopyPriceHeaderToItemDiscGroupLine()
    var
        ItemDiscountGroup: Record "Item Discount Group";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        Initialize();

        // [GIVEN] Header, where "Amount Type" is "Price"
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        PriceListHeader."Amount Type" := PriceListHeader."Amount Type"::Price;
        PriceListHeader.Modify();

        // [GIVEN] Line, where "Amount Type" is "Discount", "Asset Type" is 'Item Discount Group'
        LibraryERM.CreateItemDiscountGroup(ItemDiscountGroup);
        LibraryPriceCalculation.CreateSalesDiscountLine(
            PriceListLine, '', "Price Source Type"::Customer, LibrarySales.CreateCustomerNo(),
            "Price Asset Type"::"Item Discount Group", ItemDiscountGroup.Code);
        PriceWorksheetLine.TransferFields(PriceListLine);
        PriceWorksheetLine.Validate("Asset Type");

        // [WHEN] Copy Header to Line
        asserterror PriceWorksheetLine.CopyFrom(PriceListHeader);

        // [THEN] Error: 'Defines must be equal to 'Discount''
        Assert.ExpectedTestFieldError(PriceWorksheetLine.FieldCaption("Amount Type"), Format(PriceWorksheetLine."Amount Type"::Discount));
    end;

    [Test]
    procedure T064_CopyDiscountHeaderToPriceLine()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        Initialize();

        // [GIVEN] Header, where "Amount Type" is "Discount"
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        PriceListHeader."Amount Type" := PriceListHeader."Amount Type"::Discount;
        PriceListHeader.Modify();

        // [GIVEN] Line, where "Amount Type" is "Price", "Asset Type" is 'Item'
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, '', "Price Source Type"::Customer, LibrarySales.CreateCustomerNo(),
            "Price Asset Type"::Item, LibraryInventory.CreateItemNo());
        PriceWorksheetLine.TransferFields(PriceListLine);

        // [WHEN] Copy Header to Line
        PriceWorksheetLine.CopyFrom(PriceListHeader);

        // [THEN] Line, where "Amount Type" is 'Discount', "Unit Price" is 0.
        PriceWorksheetLine.TestField("Price Type", PriceListHeader."Price Type");
        PriceWorksheetLine.TestField("Amount Type", PriceListHeader."Amount Type");
        PriceWorksheetLine.TestField("Unit Price", 0);
    end;

    [Test]
    procedure T070_VerifySourceForSourceAllLocationsSourceFilled()
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [FEATURE] [Price Source Type] [Extended]
        // [SCENARIO] Verify source in the line fails on inconsistent source: Assign-to is filled.
        Initialize();
        // [GIVEN] New Price Worksheet Line, where "Source Type"::"All Locations", "Source No." is 'X'
        PriceWorksheetLine."Source Type" := "Price Source Type"::Test_All_Locations;
        PriceWorksheetLine."Source No." := 'X';

        // [WHEN] Verify source
        asserterror PriceWorksheetLine.Verify();

        // [THEN] Error: "Assign-to No. must be equal to ''''"
        Assert.ExpectedTestFieldError(PriceWorksheetLine.FieldCaption("Source No."), '''');
    end;

    [Test]
    procedure T071_VerifySourceForSourceLocationSourceBlank()
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [FEATURE] [Price Source Type] [Extended]
        // [SCENARIO] Verify source in the line fails on inconsistent source: Assign-to is blank.
        Initialize();
        // [GIVEN] New Price Worksheet Line, where "Source Type"::"Location", "Parent Source No." is 'X', "Source No." is <blank>
        PriceWorksheetLine."Source Type" := "Price Source Type"::Test_Location;
        PriceWorksheetLine."Parent Source No." := 'X';
        PriceWorksheetLine."Source No." := '';

        // [WHEN] Verify source
        asserterror PriceWorksheetLine.Verify();

        // [THEN] Error: "Assign-to No. must have a value"
        Assert.ExpectedError(SourceNoMustBeFilledErr);
    end;

    [Test]
    procedure T072_VerifySourceForSourceAllLocationsParentSourceFilled()
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [FEATURE] [Price Source Type] [Extended]
        // [SCENARIO] Verify source in the line fails on inconsistent source: Assign-to Parent No. is filled.
        Initialize();
        // [GIVEN] New Price Worksheet Line, where "Source Type"::"All Locations", "Parent Source No." is 'X'
        PriceWorksheetLine."Source Type" := "Price Source Type"::Test_All_Locations;
        PriceWorksheetLine."Parent Source No." := 'X';

        // [WHEN] Verify source
        asserterror PriceWorksheetLine.Verify();

        // [THEN] Error: "Assign-to Parent No. must be equal to ''''"
        Assert.ExpectedTestFieldError(PriceWorksheetLine.FieldCaption("Parent Source No."), '''');
    end;

    [Test]
    procedure T073_VerifySourceForSourceLocationParentSourceBlank()
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [FEATURE] [Price Source Type] [Extended]
        // [SCENARIO] Verify source in the line fails on inconsistent source: Assign-to Parent No. is blank.
        Initialize();
        // [GIVEN] New Price Worksheet Line, where "Source Type"::"Location", "Parent Source No." is <blank>
        PriceWorksheetLine."Source Type" := "Price Source Type"::Test_Location;
        PriceWorksheetLine."Parent Source No." := '';

        // [WHEN] Verify source
        asserterror PriceWorksheetLine.Verify();

        // [THEN] Error: "Assign-to Parent No. must have a value"
        Assert.ExpectedError(ParentSourceNoMustBeFilledErr);
    end;

    [Test]
    procedure T080_SourcePriceIncludesVATKeepsHeadersValueIfNotAllowedUpdatingDefaults()
    var
        Customer: Record Customer;
        Item: Record Item;
        PriceListHeader: Record "Price List Header";
        PriceWorksheetLine: Record "Price Worksheet Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [SCENARIO 405104] "Price Includes VAT" value set in the header cannot be changed in the line by the asset validation.
        Initialize();
        // [GIVEN] Customer 'C', where "Price Includes VAT" = true
        LibrarySales.CreateCustomer(Customer);

        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, Item."VAT Prod. Posting Group");
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("VAT Bus. Posting Gr. (Price)", VATBusinessPostingGroup.Code);
        SalesReceivablesSetup.Modify();

        Customer.Validate("Prices Including VAT", true);
        Customer.Validate("VAT Bus. Posting Group", VATBusinessPostingGroup.Code);
        Customer.Modify();

        // [GIVEN] Price List Header 'X', where "Source Type" is 'Customer', "Source No." is 'C', "Allow Updating Defaults" is 'No'
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Sale, "Price Source Type"::Customer, Customer."No.");
        PriceListHeader."Amount Type" := PriceListHeader."Amount Type"::Price;
        PriceListHeader."Allow Updating Defaults" := false;
        // [GIVEN] "Price Includes VAT" is false
        PriceListHeader."Starting Date" := WorkDate();
        PriceListHeader."Ending Date" := WorkDate() + 10;
        PriceListHeader."Price Includes VAT" := false;
        PriceListHeader."VAT Bus. Posting Gr. (Price)" := '';
        PriceListHeader.Modify();
        // [GIVEN] Fill the Line, where "Price List Code" is 'X' 
        PriceWorksheetLine.Init();
        PriceWorksheetLine.Validate("Price List Code", PriceListHeader.Code);
        // [WHEN] Line is inserted
        PriceWorksheetLine.Insert(true);

        // [THEN] Line, where "Price Includes VAT" is false
        PriceWorksheetLine.TestField("Price Includes VAT", PriceListHeader."Price Includes VAT");
        PriceWorksheetLine.TestField("VAT Bus. Posting Gr. (Price)", PriceListHeader."VAT Bus. Posting Gr. (Price)");
    end;

    [Test]
    procedure T081_AssetPriceIncludesVATKeepsHeadersValueIfNotAllowedUpdatingDefaults()
    var
        Item: Record Item;
        PriceListHeader: Record "Price List Header";
        PriceWorksheetLine: Record "Price Worksheet Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        SourceNo: Code[20];
    begin
        // [SCENARIO 405104] "Price Includes VAT" value set in the header cannot be changed in the line by the asset validation.
        Initialize();
        // [GIVEN] Item 'I', where "Price Includes VAT" = true
        LibraryInventory.CreateItem(Item);

        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, Item."VAT Prod. Posting Group");
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("VAT Bus. Posting Gr. (Price)", VATBusinessPostingGroup.Code);
        SalesReceivablesSetup.Modify();

        Item.Validate("Price Includes VAT", true);
        Item.Modify();

        // [GIVEN] Price List Header 'X', where "Source Type" is 'Customer', "Source No." is 'C', "Allow Updating Defaults" is 'No'
        SourceNo := LibrarySales.CreateCustomerNo();
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Sale, "Price Source Type"::Customer, SourceNo);
        PriceListHeader."Amount Type" := PriceListHeader."Amount Type"::Price;
        PriceListHeader."Allow Updating Defaults" := false;
        // [GIVEN] "Price Includes VAT" is false
        PriceListHeader."Starting Date" := WorkDate();
        PriceListHeader."Ending Date" := WorkDate() + 10;
        PriceListHeader."Price Includes VAT" := false;
        PriceListHeader."VAT Bus. Posting Gr. (Price)" := '';
        PriceListHeader.Modify();
        // [GIVEN] Fill the Line, where "Price List Code" is 'X' 
        PriceWorksheetLine.Init();
        PriceWorksheetLine.Validate("Price List Code", PriceListHeader.Code);
        PriceWorksheetLine.Insert(true);

        // [WHEN] Validate "Asset Type"
        PriceWorksheetLine.Validate("Asset Type", "Price Asset Type"::Item);

        // [THEN] Line inserted, "Price Includes VAT" is false
        PriceWorksheetLine.TestField("Price Includes VAT", PriceListHeader."Price Includes VAT");
        PriceWorksheetLine.TestField("VAT Bus. Posting Gr. (Price)", PriceListHeader."VAT Bus. Posting Gr. (Price)");

        // [WHEN] Validate "Asset No." as 'I'
        PriceWorksheetLine.Validate("Asset No.", Item."No.");

        // [THEN] "Price Includes VAT" is false (as header's value)
        PriceWorksheetLine.TestField("Price Includes VAT", PriceListHeader."Price Includes VAT");
        PriceWorksheetLine.TestField("VAT Bus. Posting Gr. (Price)", PriceListHeader."VAT Bus. Posting Gr. (Price)");
    end;

    [Test]
    procedure T082_PriceIncludesVATGetsAssetsValueIfAllowedUpdatingDeafults()
    var
        Item: Record Item;
        PriceListHeader: Record "Price List Header";
        PriceWorksheetLine: Record "Price Worksheet Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        SourceNo: Code[20];
    begin
        // [SCENARIO 405104] "Price Includes VAT" value set in the header can be changed in the line by the asset validation if "Allow Updating Defaults".
        Initialize();
        // [GIVEN] Item 'I', where "Price Includes VAT" = true
        LibraryInventory.CreateItem(Item);

        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, Item."VAT Prod. Posting Group");
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("VAT Bus. Posting Gr. (Price)", VATBusinessPostingGroup.Code);
        SalesReceivablesSetup.Modify();

        Item.Validate("Price Includes VAT", true);
        Item.Modify();

        // [GIVEN] Price List Header 'X', where "Source Type" is 'Customer', "Source No." is 'C', "Allow Updating Defaults" is 'Yes'
        SourceNo := LibrarySales.CreateCustomerNo();
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Sale, "Price Source Type"::Customer, SourceNo);
        PriceListHeader."Amount Type" := PriceListHeader."Amount Type"::Price;
        PriceListHeader."Allow Updating Defaults" := true;
        // [GIVEN] "Price Includes VAT" is false
        PriceListHeader."Starting Date" := WorkDate();
        PriceListHeader."Ending Date" := WorkDate() + 10;
        PriceListHeader."Price Includes VAT" := false;
        PriceListHeader."VAT Bus. Posting Gr. (Price)" := '';
        PriceListHeader.Modify();
        // [GIVEN] Fill the Line, where "Price List Code" is 'X' 
        PriceWorksheetLine.Init();
        PriceWorksheetLine.Validate("Price List Code", PriceListHeader.Code);
        PriceWorksheetLine.Insert(true);

        // [WHEN] Validate "Asset Type"
        PriceWorksheetLine.Validate("Asset Type", "Price Asset Type"::Item);

        // [THEN] Line inserted, "Price Includes VAT" is false
        PriceWorksheetLine.TestField("Price Includes VAT", PriceListHeader."Price Includes VAT");
        PriceWorksheetLine.TestField("VAT Bus. Posting Gr. (Price)", PriceListHeader."VAT Bus. Posting Gr. (Price)");

        // [WHEN] Validate "Asset No." as 'I'
        PriceWorksheetLine.Validate("Asset No.", Item."No.");

        // [THEN] "Price Includes VAT" is true (as item's value)
        PriceWorksheetLine.TestField("Price Includes VAT", Item."Price Includes VAT");
        PriceWorksheetLine.TestField("VAT Bus. Posting Gr. (Price)", Item."VAT Bus. Posting Gr. (Price)");
    end;

    [Test]
    procedure T099_ValidateBlankNoForAsset()
    var
        Item: Record Item;
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        Initialize();
        // [GIVEN] Item 'X'
        LibraryInventory.CreateItem(Item);
        // [GIVEN] Price List Line, where "Source Type" is 'All Customers', "Asset Type" is Item, "Asset No." is 'X', "Minimum Quantity" is 10, "Unit Price" is 100
        PriceWorksheetLine.Validate("Source Type", "Price Source Type"::"All Customers");
        PriceWorksheetLine.Validate("Asset Type", "Price Asset Type"::Item);
        PriceWorksheetLine.Validate("Asset No.", Item."No.");
        PriceWorksheetLine.Validate("Minimum Quantity", 10);
        PriceWorksheetLine.Validate("Unit Price", 100.00);

        // [WHEN] Blank "Asset No."
        PriceWorksheetLine.Validate("Asset No.", '');

        // [THEN] Price List Line, where "Asset Type" is Item, "Asset No." is <blank>, "Minimum Quantity" is 10, "Unit Price" is 100
        PriceWorksheetLine.TestField("Asset Type", "Price Asset Type"::Item);
        PriceWorksheetLine.TestField("Asset No.", '');
        PriceWorksheetLine.TestField("Minimum Quantity", 10);
        PriceWorksheetLine.TestField("Unit Price", 100.00);
    end;

    [Test]
    procedure T100_ValidateItemNoForCustomer()
    var
        Customer: Record Customer;
        Item: Record Item;
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [FEATURE] [Customer] [Item]
        Initialize();
        // [GIVEN] Item 'X', where "Sales Unit of Measure" - 'SUoM', "Allow Invoice Disc." is Yes, 
        // [GIVEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'VATBPG'
        CreateItem(Item);
        // [GIVEN] Customer 'C', where "VAT Bus. Posting Group" is 'CVAT'
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] Price Worksheet Line, where "Source Type" is 'Customer', "Asset Type" is Item
        PriceWorksheetLine.Validate("Source Type", "Price Source Type"::Customer);
        PriceWorksheetLine.Validate("Source No.", Customer."No.");
        PriceWorksheetLine."Unit of Measure Code" := LibraryUtility.GenerateGUID();
        PriceWorksheetLine.Validate("Asset Type", "Price Asset Type"::Item);

        // [WHEN] Set "Asset No." as 'X'
        PriceWorksheetLine.Validate("Asset No.", Item."No.");

        // [THEN] Price Worksheet Line, where "Unit of Measure Code" is 'SUoM', "Variant Code" is <blank>, "Allow Invoice Disc." is Yes, 
        // [THEN] "Price Includes VAT" is No, "VAT Bus. Posting Gr. (Price)" is 'CVAT'
        VerifyLineVariant(PriceWorksheetLine, Item."Sales Unit of Measure", true, false, Customer."VAT Bus. Posting Group", '', '', Customer."Currency Code");
    end;

    [Test]
    procedure T101_ValidateItemNoForAllCustomers()
    var
        Item: Record Item;
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [FEATURE] [Customer] [Item]
        Initialize();
        // [GIVEN] Item 'X', where "Sales Unit of Measure" - 'SUoM', "Allow Invoice Disc." is Yes, 
        // [GIVEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'VATBPG'
        CreateItem(Item);
        // [GIVEN] Price Worksheet Line, where "Source Type" is 'All Customers', "Asset Type" is Item
        PriceWorksheetLine.Validate("Source Type", "Price Source Type"::"All Customers");
        PriceWorksheetLine."Unit of Measure Code" := LibraryUtility.GenerateGUID();
        PriceWorksheetLine.Validate("Asset Type", "Price Asset Type"::Item);

        // [WHEN] Set "Asset No." as 'X'
        PriceWorksheetLine.Validate("Asset No.", Item."No.");

        // [THEN] Price Worksheet Line, where "Unit of Measure Code" is 'SUoM', "Variant Code" is <blank>, "Allow Invoice Disc." is Yes, 
        // [THEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'VATBPG'
        VerifyLineVariant(
            PriceWorksheetLine, Item."Sales Unit of Measure", true, true, Item."VAT Bus. Posting Gr. (Price)", '', '', '');
    end;

    [Test]
    procedure T102_ValidateItemNoForCustomerPriceGroup()
    var
        Item: Record Item;
        CustomerPriceGroup: Record "Customer Price Group";
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [FEATURE] [Customer Price Group] [Item]
        Initialize();
        // [GIVEN] Item 'X', where "Sales Unit of Measure" - 'SUoM', "Allow Invoice Disc." is Yes, 
        // [GIVEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'VATBPG'
        CreateItem(Item);
        // [GIVEN] CustomerPriceGroup 'CPG', where "Allow Invoice Disc." is No, "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'CPGVAT'
        CreateCustomerPriceGroup(CustomerPriceGroup);
        // [GIVEN] Price Worksheet Line, where "Allow Invoice Disc." is No, "Source Type" is 'Customer Price Group', "Asset Type" is 'Item'
        PriceWorksheetLine.Validate("Source Type", "Price Source Type"::"Customer Price Group");
        PriceWorksheetLine.Validate("Source No.", CustomerPriceGroup.Code);
        PriceWorksheetLine."Unit of Measure Code" := LibraryUtility.GenerateGUID();
        PriceWorksheetLine.Validate("Asset Type", "Price Asset Type"::Item);

        // [WHEN] Set "Asset No." as 'X'
        PriceWorksheetLine.Validate("Asset No.", Item."No.");

        // [THEN] Price Worksheet Line, where "Unit of Measure Code" is 'SUoM', "Variant Code" is <blank>, "Allow Invoice Disc." is Yes, 
        // [THEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'CPGVAT'
        VerifyLineVariant(
            PriceWorksheetLine, Item."Sales Unit of Measure", Item."Allow Invoice Disc.",
            CustomerPriceGroup."Price Includes VAT", CustomerPriceGroup."VAT Bus. Posting Gr. (Price)", '', '', '');
    end;

    [Test]
    procedure T103_ValidateItemDiscountGroupForCustomer()
    var
        Customer: Record Customer;
        ItemDiscountGroup: Record "Item Discount Group";
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [FEATURE] [Customer] [Item Discount Group]
        Initialize();
        // [GIVEN] ItemDiscountGroup 'X'
        LibraryERM.CreateItemDiscountGroup(ItemDiscountGroup);
        // [GIVEN] Customer 'C', where "VAT Bus. Posting Group" is 'CVAT'
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] Price Worksheet Line, where "Source Type" is 'Customer', "Asset Type" is "Item Discount Group", 
        // [GIVEN] "Variant Code" is 'V', "Unit of Measure Code" is 'UoM'
        PriceWorksheetLine.Validate("Source Type", "Price Source Type"::Customer);
        PriceWorksheetLine.Validate("Source No.", Customer."No.");
        PriceWorksheetLine."Variant Code" := LibraryUtility.GenerateGUID();
        PriceWorksheetLine."Unit of Measure Code" := LibraryUtility.GenerateGUID();
        PriceWorksheetLine.Validate("Asset Type", "Price Asset Type"::"Item Discount Group");

        // [WHEN] Set "Asset No." as 'X'
        PriceWorksheetLine.Validate("Asset No.", ItemDiscountGroup.Code);

        // [THEN] Price Worksheet Line, where "Unit of Measure Code" is <blank>, "Variant Code" is <blank>, "Allow Invoice Disc." is No, 
        // [THEN] "Price Includes VAT" is No, "VAT Bus. Posting Gr. (Price)" is 'CVAT'
        VerifyLineVariant(PriceWorksheetLine, '', false, false, Customer."VAT Bus. Posting Group", '', '', Customer."Currency Code");
    end;

    [Test]
    procedure T104_ValidateItemNoForVendor()
    var
        Currency: Record Currency;
        Item: Record Item;
        PriceWorksheetLine: Record "Price Worksheet Line";
        Vendor: Record Vendor;
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        // [FEATURE] [Vendor] [Item]
        Initialize();
        // [GIVEN] Vendor 'V', where "Currency Code" is 'USD', "Price Includes VAT" is Yes, "VAT Bus. Posting Group" is 'VBG'
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.CreateCurrency(Currency);
        Vendor."Currency Code" := Currency.Code;
        Vendor."Prices Including VAT" := true;
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        Vendor."VAT Bus. Posting Group" := VATBusinessPostingGroup.Code;
        Vendor.Modify();
        // [GIVEN] Item 'X', where "Purch. Unit of Measure" - 'PUoM', "Allow Invoice Disc." is Yes, 
        // [GIVEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'VATBPG'
        CreateItem(Item);
        // [GIVEN] Price Worksheet Line, where "Source Type" is 'Vendor', "Asset Type" is Item
        PriceWorksheetLine.Validate("Source Type", "Price Source Type"::Vendor);
        PriceWorksheetLine.Validate("Source No.", Vendor."No.");
        PriceWorksheetLine."Unit of Measure Code" := LibraryUtility.GenerateGUID();
        PriceWorksheetLine.Validate("Asset Type", "Price Asset Type"::Item);

        // [WHEN] Set "Asset No." as 'X'
        PriceWorksheetLine.Validate("Asset No.", Item."No.");

        // [THEN] Price Worksheet Line, where "Unit of Measure Code" is 'PUoM', "Variant Code" is <blank>, "Allow Invoice Disc." is Yes, 
        // [THEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'VBG'
        VerifyLineVariant(PriceWorksheetLine, Item."Purch. Unit of Measure", Item."Allow Invoice Disc.", Vendor."Prices Including VAT", Vendor."VAT Bus. Posting Group", '', '', Vendor."Currency Code");
    end;

    [Test]
    procedure T105_ValidateItemNoForJobSale()
    var
        Item: Record Item;
        Job: Record Job;
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [FEATURE] [Job] [Item]
        Initialize();
        // [GIVEN] Item 'X', where "Sales Unit of Measure" - 'SUoM', "Allow Invoice Disc." is Yes, 
        // [GIVEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'VATBPG'
        CreateItem(Item);
        // [GIVEN] Price Worksheet Line, where "Price Type" is 'Sale', "Source Type" is 'Job', "Asset Type" is Item
        PriceWorksheetLine."Price Type" := "Price Type"::Sale;
        PriceWorksheetLine.Validate("Source Type", "Price Source Type"::Job);
        LibraryJob.CreateJob(Job);
        PriceWorksheetLine.Validate("Source No.", Job."No.");
        PriceWorksheetLine."Unit of Measure Code" := LibraryUtility.GenerateGUID();
        PriceWorksheetLine.Validate("Asset Type", "Price Asset Type"::Item);

        // [WHEN] Set "Asset No." as 'X'
        PriceWorksheetLine.Validate("Asset No.", Item."No.");

        // [THEN] Price Worksheet Line, where "Unit of Measure Code" is 'SUoM', "Variant Code" is <blank>, "Allow Invoice Disc." is Yes, 
        // [THEN] "Price Includes VAT" is No, "VAT Bus. Posting Gr. (Price)" is <blank>
        VerifyLineVariant(
            PriceWorksheetLine, Item."Sales Unit of Measure", Item."Allow Invoice Disc.",
            Item."Price Includes VAT", item."VAT Bus. Posting Gr. (Price)", '', '', Job."Currency Code");
    end;

    [Test]
    procedure T106_ValidateItemNoForJobPurchase()
    var
        Item: Record Item;
        Job: Record Job;
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [FEATURE] [Job] [Item]
        Initialize();
        // [GIVEN] Item 'X', where "Purch. Unit of Measure" - 'PUoM', "Allow Invoice Disc." is Yes, 
        // [GIVEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'VATBPG'
        CreateItem(Item);
        // [GIVEN] Price Worksheet Line, where "Price Type" is 'Purchase', "Source Type" is 'Job', "Asset Type" is Item
        PriceWorksheetLine."Price Type" := "Price Type"::Purchase;
        PriceWorksheetLine.Validate("Source Type", "Price Source Type"::Job);
        LibraryJob.CreateJob(Job);
        PriceWorksheetLine.Validate("Source No.", Job."No.");
        PriceWorksheetLine."Unit of Measure Code" := LibraryUtility.GenerateGUID();
        PriceWorksheetLine.Validate("Asset Type", "Price Asset Type"::Item);

        // [WHEN] Set "Asset No." as 'X'
        PriceWorksheetLine.Validate("Asset No.", Item."No.");

        // [THEN] Price Worksheet Line, where "Unit of Measure Code" is 'PUoM', "Variant Code" is <blank>, "Allow Invoice Disc." is Yes, 
        // [THEN] "Price Includes VAT" is No, "VAT Bus. Posting Gr. (Price)" is <blank>
        VerifyLineVariant(PriceWorksheetLine, Item."Purch. Unit of Measure", Item."Allow Invoice Disc.", false, '', '', '', Job."Currency Code");
    end;

    [Test]
    procedure T107_ValidateGlAccNoForJob()
    var
        GLAccount: Record "G/L Account";
        Job: Record Job;
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [FEATURE] [Job] [G/L Account]
        Initialize();
        // [GIVEN] G/L Account 'X', where "VAT Bus. Posting Group" is 'VATBPG', Name is 'Descr'
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        GLAccount.Name := LibraryUtility.GenerateRandomText(MaxStrLen(GLAccount.Name));
        GLAccount.Modify();
        // [GIVEN] Price Worksheet Line, where "Price Type" is 'Any, "Source Type" is 'Job', "Asset Type" is Item, "Variant Code" is 'V'
        PriceWorksheetLine.Validate("Source Type", "Price Source Type"::Job);
        LibraryJob.CreateJob(Job);
        PriceWorksheetLine.Validate("Source No.", Job."No.");
        PriceWorksheetLine."Variant Code" := LibraryUtility.GenerateGUID();
        PriceWorksheetLine."Unit of Measure Code" := LibraryUtility.GenerateGUID();
        PriceWorksheetLine.Validate("Asset Type", "Price Asset Type"::"G/L Account");

        // [WHEN] Set "Asset No." as 'X'
        PriceWorksheetLine.Validate("Asset No.", GLAccount."No.");

        // [THEN] Price Worksheet Line, where "Unit of Measure Code" is <blank>, "Variant Code" is <blank>, "Allow Invoice Disc." is No, 
        // [THEN] "Price Includes VAT" is No, "VAT Bus. Posting Gr. (Price)" is <blank>, Description is 'Descr'
        VerifyLineVariant(PriceWorksheetLine, '', false, false, '', '', '', Job."Currency Code");
        PriceWorksheetLine.TestField(Description, GLAccount.Name);
    end;

    [Test]
    procedure T108_ValidateResourceForJob()
    var
        Resource: Record Resource;
        Job: Record Job;
        PriceWorksheetLine: Record "Price Worksheet Line";
        WorkType: Record "Work Type";
    begin
        // [FEATURE] [Job] [Resource]
        Initialize();
        // [GIVEN] Resource 'X', where "Unit of Measure Code" is 'R-UOM'
        Resource.Get(LibraryResource.CreateResourceNo());
        // [GIVEN] Price Worksheet Line, where "Price Type" is 'Any, "Source Type" is 'Job', "Asset Type" is Resource, 
        // [GIVEN] "Variant Code" is 'V', "Work Type Code" is 'WT'
        PriceWorksheetLine.Validate("Source Type", "Price Source Type"::Job);
        LibraryJob.CreateJob(Job);
        PriceWorksheetLine.Validate("Source No.", Job."No.");
        PriceWorksheetLine."Variant Code" := LibraryUtility.GenerateGUID();
        PriceWorksheetLine."Unit of Measure Code" := LibraryUtility.GenerateGUID();
        LibraryResource.CreateWorkType(WorkType);
        PriceWorksheetLine."Work Type Code" := WorkType.Code;
        PriceWorksheetLine.Validate("Asset Type", "Price Asset Type"::Resource);

        // [WHEN] Set "Asset No." as 'X'
        PriceWorksheetLine.Validate("Asset No.", Resource."No.");

        // [THEN] Price Worksheet Line, where "Unit of Measure Code" is 'R-UOM', "Variant Code" is <blank>, "Allow Invoice Disc." is No, 
        // [THEN] "Price Includes VAT" is No, "VAT Bus. Posting Gr. (Price)" is <blank>, "Work Type Code" is <blank>
        VerifyLineVariant(PriceWorksheetLine, Resource."Base Unit of Measure", false, false, '', '', '', Job."Currency Code");
    end;

    [Test]
    procedure T109_ValidateResourceGroupForJob()
    var
        ResourceGroup: Record "Resource Group";
        Job: Record Job;
        PriceWorksheetLine: Record "Price Worksheet Line";
        WorkType: Record "Work Type";
    begin
        // [FEATURE] [Job] [Resource Group]
        Initialize();
        // [GIVEN] Resource Group 'X'
        LibraryResource.CreateResourceGroup(ResourceGroup);
        // [GIVEN] Price Worksheet Line, where "Price Type" is 'Any, "Source Type" is 'Job', "Asset Type" is 'Resource Group', 
        // [GIVEN] "Variant Code" is 'V', "Work Type Code" is 'WT'
        PriceWorksheetLine.Validate("Source Type", "Price Source Type"::Job);
        LibraryJob.CreateJob(Job);
        PriceWorksheetLine.Validate("Source No.", Job."No.");
        PriceWorksheetLine."Variant Code" := LibraryUtility.GenerateGUID();
        PriceWorksheetLine."Unit of Measure Code" := LibraryUtility.GenerateGUID();
        LibraryResource.CreateWorkType(WorkType);
        PriceWorksheetLine."Work Type Code" := WorkType.Code;
        PriceWorksheetLine.Validate("Asset Type", "Price Asset Type"::"Resource Group");

        // [WHEN] Set "Asset No." as 'X'
        PriceWorksheetLine.Validate("Asset No.", ResourceGroup."No.");

        // [THEN] Price Worksheet Line, where "Unit of Measure Code" is <blank>, "Variant Code" is <blank>, "Allow Invoice Disc." is No, 
        // [THEN] "Price Includes VAT" is No, "VAT Bus. Posting Gr. (Price)" is <blank>, "Work Type Code" is <blank>
        VerifyLineVariant(PriceWorksheetLine, '', false, false, '', '', '', Job."Currency Code");
    end;

    [Test]
    procedure T110_ValidateResourceForCustomer()
    var
        Customer: Record Customer;
        Resource: Record Resource;
        PriceWorksheetLine: Record "Price Worksheet Line";
        WorkType: Record "Work Type";
    begin
        // [FEATURE] [Customer] [Resource]
        Initialize();
        // [GIVEN] Resource 'X', where "Unit of Measure Code" is 'R-UOM'
        Resource.Get(LibraryResource.CreateResourceNo());
        // [GIVEN] Customer 'C', where "VAT Bus. Posting Group" is 'CVAT'
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] Price Worksheet Line, where "Source Type" is 'Customer', "Asset Type" is Resource, 
        // [GIVEN] "Variant Code" is 'V', "Work Type Code" is 'WT'
        PriceWorksheetLine.Validate("Source Type", "Price Source Type"::Customer);
        PriceWorksheetLine.Validate("Source No.", Customer."No.");
        PriceWorksheetLine."Variant Code" := LibraryUtility.GenerateGUID();
        PriceWorksheetLine."Unit of Measure Code" := LibraryUtility.GenerateGUID();
        LibraryResource.CreateWorkType(WorkType);
        PriceWorksheetLine."Work Type Code" := WorkType.Code;
        PriceWorksheetLine.Validate("Asset Type", "Price Asset Type"::Resource);

        // [WHEN] Set "Asset No." as 'X'
        PriceWorksheetLine.Validate("Asset No.", Resource."No.");

        // [THEN] Price Worksheet Line, where "Unit of Measure Code" is 'R-UOM', "Variant Code" is <blank>, "Allow Invoice Disc." is No, 
        // [THEN] "Price Includes VAT" is No, "VAT Bus. Posting Gr. (Price)" is 'CVAT', "Work Type Code" is <blank>
        VerifyLineVariant(
            PriceWorksheetLine, Resource."Base Unit of Measure", false, false,
            Customer."VAT Bus. Posting Group", '', '', Customer."Currency Code");
    end;

    [Test]
    procedure T111_ValidateResourceGroupForVendor()
    var
        ResourceGroup: Record "Resource Group";
        PriceWorksheetLine: Record "Price Worksheet Line";
        Vendor: Record Vendor;
        WorkType: Record "Work Type";
    begin
        // [FEATURE] [Vendor] [Resource Group]
        Initialize();
        // [GIVEN] Vendor 'V', where "VAT Bus. Posting Group" is 'VPG'
        LibraryPurchase.CreateVendor(Vendor);
        // [GIVEN] Resource Group 'X'
        LibraryResource.CreateResourceGroup(ResourceGroup);
        // [GIVEN] Price Worksheet Line, where "Source Type" is 'Vendor', "Asset Type" is 'Resource Group',
        // [GIVEN] "Variant Code" is 'V', "Work Type Code" is 'WT'
        PriceWorksheetLine.Validate("Source Type", "Price Source Type"::Vendor);
        PriceWorksheetLine.Validate("Source No.", Vendor."No.");
        PriceWorksheetLine."Variant Code" := LibraryUtility.GenerateGUID();
        PriceWorksheetLine."Unit of Measure Code" := LibraryUtility.GenerateGUID();
        LibraryResource.CreateWorkType(WorkType);
        PriceWorksheetLine."Work Type Code" := WorkType.Code;
        PriceWorksheetLine.Validate("Asset Type", "Price Asset Type"::"Resource Group");

        // [WHEN] Set "Asset No." as 'X'
        PriceWorksheetLine.Validate("Asset No.", ResourceGroup."No.");

        // [THEN] Price Worksheet Line, where "Unit of Measure Code" is <blank>, "Variant Code" is <blank>, "Allow Invoice Disc." is No, 
        // [THEN] "Price Includes VAT" is No, "VAT Bus. Posting Gr. (Price)" is 'VPG', "Work Type Code" is <blank>
        VerifyLineVariant(PriceWorksheetLine, '', false, false, Vendor."VAT Bus. Posting Group", '', '', '');
    end;

    [Test]
    procedure T112_ValidateSourceTypeForItem()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [FEATURE] [Customer] [Item]
        Initialize();
        // [GIVEN] Item 'X', where "Sales Unit of Measure" - 'SUoM', "Allow Invoice Disc." is Yes, 
        // [GIVEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'VATBPG'
        CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        // [GIVEN] Price Worksheet Line, where "Source Type" is 'Customer', "Asset Type" is Item, "Variant Code" is 'V'
        PriceWorksheetLine.Validate("Source Type", "Price Source Type"::"All Customers");
        PriceWorksheetLine.Validate("Asset Type", "Price Asset Type"::Item);
        PriceWorksheetLine.Validate("Asset No.", Item."No.");
        PriceWorksheetLine."Variant Code" := ItemVariant.Code;
        PriceWorksheetLine."Unit of Measure Code" := LibraryUtility.GenerateGUID();

        // [WHEN] Set "Source Type " as 'Customer'
        PriceWorksheetLine.Validate("Source Type", "Price Source Type"::Customer);

        // [THEN] Price Worksheet Line, where "Unit of Measure Code" is 'SUoM', "Variant Code" is 'V', "Allow Invoice Disc." is Yes, 
        // [THEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'VATBPG'
        VerifyLineVariant(
            PriceWorksheetLine, Item."Sales Unit of Measure", true, true,
            Item."VAT Bus. Posting Gr. (Price)", ItemVariant.Code, '', '');
    end;

    [Test]
    procedure T113_ValidateAllCustomersSourceNoForItem()
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [FEATURE] [All Customers]
        Initialize();
        // [GIVEN] Price Worksheet Line, where "Source Type" is 'All Customers'
        PriceWorksheetLine.Validate("Source Type", "Price Source Type"::"All Customers");

        // [WHEN] Set "Source No." as 'X'
        PriceWorksheetLine.Validate("Source No.", LibraryUtility.GenerateGUID());

        // [THEN] "Source No." is <blank>
        PriceWorksheetLine.TestField("Source No.", '');
    end;

    [Test]
    procedure T114_ValidateCustomerNoForItem()
    var
        Customer: Record Customer;
        Item: Record Item;
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [FEATURE] [Customer] [Item]
        Initialize();
        // [GIVEN] Customer 'C', where "Currency Code" is 'USD', "VAT Bus. POsting Group" is 'CVAT', 
        // [GIVEN] "Prices Including VAT" is No, "Allow Line Disc." is Yes
        CreateCustomer(Customer);
        // [GIVEN] Item 'X', where "Sales Unit of Measure" - 'SUoM', "Allow Invoice Disc." is Yes, 
        // [GIVEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'VATBPG'
        CreateItem(Item);
        // [GIVEN] Price Worksheet Line, where "Source Type" is 'Customer', "Asset Type" is Item, "Variant Code" is 'V'
        PriceWorksheetLine.Validate("Source Type", "Price Source Type"::Customer);
        PriceWorksheetLine.Validate("Asset Type", "Price Asset Type"::Item);
        PriceWorksheetLine.Validate("Asset No.", Item."No.");
        PriceWorksheetLine."Variant Code" := LibraryUtility.GenerateGUID();
        PriceWorksheetLine."Unit of Measure Code" := LibraryUtility.GenerateGUID();

        // [WHEN] Set "Source Type " as 'Customer'
        PriceWorksheetLine.Validate("Source No.", Customer."No.");

        // [THEN] Price Worksheet Line, where "Allow Line Disc." is Yes, "Currency Code" is 'USD',
        // [THEN] "Price Includes VAT" is No, "VAT Bus. Posting Gr. (Price)" is 'CVAT'
        VerifyLine(
            PriceWorksheetLine, Customer."Allow Line Disc.", Customer."Prices Including VAT",
            Customer."VAT Bus. Posting Group", Customer."Currency Code");
    end;

    [Test]
    procedure T115_ValidateCustomerPriceGroupForItem()
    var
        CustomerPriceGroup: Record "Customer Price Group";
        Item: Record Item;
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [FEATURE] [Customer Price Group] [Item]
        Initialize();
        // [GIVEN] Customer Price Group 'CPG', where "VAT Bus. Posting Gr. (Price)" is 'CVAT', 
        // [GIVEN] "Prices Including VAT" is Yes, "Allow Line Disc." is No, "Allow Invoice Disc." is No
        CreateCustomerPriceGroup(CustomerPriceGroup);
        // [GIVEN] Item 'X', where "Sales Unit of Measure" - 'SUoM', "Allow Invoice Disc." is Yes, 
        // [GIVEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'VATBPG'
        CreateItem(Item);
        // [GIVEN] Price Worksheet Line, where "Source Type" is 'Customer Price GroupCustomer Price Group', "Asset Type" is Item, "Variant Code" is 'V'
        PriceWorksheetLine.Validate("Source Type", "Price Source Type"::"Customer Price Group");
        PriceWorksheetLine.Validate("Asset Type", "Price Asset Type"::Item);
        PriceWorksheetLine.Validate("Asset No.", Item."No.");
        PriceWorksheetLine."Variant Code" := LibraryUtility.GenerateGUID();
        PriceWorksheetLine."Unit of Measure Code" := LibraryUtility.GenerateGUID();

        // [WHEN] Set "Source Type " as 'Customer'
        PriceWorksheetLine.Validate("Source No.", CustomerPriceGroup.Code);

        // [THEN] Price Worksheet Line, where "Allow Line Disc." is No, "Allow Invoice Disc." is No,
        // [THEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'CVAT'
        VerifyLine(
            PriceWorksheetLine, CustomerPriceGroup."Allow Line Disc.", CustomerPriceGroup."Price Includes VAT",
            CustomerPriceGroup."VAT Bus. Posting Gr. (Price)", CustomerPriceGroup."Allow Invoice Disc.");
    end;

    [Test]
    procedure T116_ValidateCampaignNoForItem()
    var
        Campaign: Record Campaign;
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [FEATURE] [Campaign]
        Initialize();
        // [GIVEN] Campaign 'C', where "Starting Date" is '010120', "Ending Date" is '310120'
        LibraryMarketing.CreateCampaign(Campaign);
        Campaign.Validate("Starting Date", WorkDate());
        Campaign.Validate("Ending Date", WorkDate() + 10);
        Campaign.Modify();
        // [GIVEN] Price Worksheet Line, where "Source Type" is 'Campaign', "Starting Date" and "Ending Date" are <blank>
        PriceWorksheetLine.Validate("Source Type", "Price Source Type"::Campaign);

        // [WHEN] Set "Source No." as 'C'
        PriceWorksheetLine.Validate("Source No.", Campaign."No.");

        // [THEN] Price Worksheet Line, where "Starting Date" is '010120', "Ending Date" is '310120'
        VerifyLine(PriceWorksheetLine, Campaign."Starting Date", Campaign."Ending Date");
    end;

    [Test]
    procedure T117_ValidateContactNoForItem()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        Item: Record Item;
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [FEATURE] [Contact] [Item]
        Initialize();
        // [GIVEN] Customer 'C' with Contact 'CONT', where "VAT Bus. Posting Group" is 'CVAT', 
        // [GIVEN] "Prices Including VAT" is No, "Allow Line Disc." is Yes
        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);
        // [GIVEN] Item 'X', where "Sales Unit of Measure" - 'SUoM', "Allow Invoice Disc." is Yes, 
        // [GIVEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'VATBPG'
        CreateItem(Item);
        // [GIVEN] Price Worksheet Line, where "Price Type"::Sale, "Source Type" is 'Contact', "Asset Type" is Item, "Variant Code" is 'V'
        PriceWorksheetLine."Price Type" := "Price Type"::Sale;
        PriceWorksheetLine.Validate("Source Type", "Price Source Type"::Contact);
        PriceWorksheetLine.Validate("Asset Type", "Price Asset Type"::Item);
        PriceWorksheetLine.Validate("Asset No.", Item."No.");

        // [WHEN] Set "Source No." as 'CONT'
        PriceWorksheetLine.Validate("Source No.", Contact."No.");

        // [THEN] Price Worksheet Line, where "Unit of Measure Code" is 'SUoM', "Variant Code" is <blank>, "Allow Invoice Disc." is Yes, 
        // [THEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'VATBPG'
        VerifyLineVariant(PriceWorksheetLine, Item."Sales Unit of Measure", true, true, Item."VAT Bus. Posting Gr. (Price)", '', '', '');
    end;

    [Test]
    procedure T118_ValidateItemForContact()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        Item: Record Item;
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [FEATURE] [Contact] [Item]
        Initialize();
        // [GIVEN] Customer 'C' with Contact 'CONT', where "VAT Bus. Posting Group" is 'CVAT', 
        // [GIVEN] "Prices Including VAT" is No, "Allow Line Disc." is Yes
        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);
        // [GIVEN] Item 'X', where "Sales Unit of Measure" - 'SUoM', "Allow Invoice Disc." is Yes, 
        // [GIVEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'VATBPG'
        CreateItem(Item);
        // [GIVEN] Price Worksheet Line, where "Price Type"::Sale, "Source Type" is 'Contact', "Asset Type" is Item
        PriceWorksheetLine."Price Type" := "Price Type"::Sale;
        PriceWorksheetLine.Validate("Source Type", "Price Source Type"::Contact);
        PriceWorksheetLine.Validate("Source No.", Contact."No.");
        PriceWorksheetLine.Validate("Asset Type", "Price Asset Type"::Item);
        PriceWorksheetLine."Unit of Measure Code" := LibraryUtility.GenerateGUID();

        // [WHEN] Set "Source No." as 'X'
        PriceWorksheetLine.Validate("Asset No.", Item."No.");

        // [THEN] Price Worksheet Line, where "Unit of Measure Code" is 'SUoM', "Variant Code" is <blank>, "Allow Invoice Disc." is Yes, 
        // [THEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'VATBPG'
        VerifyLineVariant(PriceWorksheetLine, Item."Sales Unit of Measure", true, true, Item."VAT Bus. Posting Gr. (Price)", '', '', '');
    end;

    [Test]
    procedure T119_ValidateWorkTypeForAllResources()
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
        WorkType: Record "Work Type";
        UnitofMeasure: Record "Unit of Measure";
    begin
        // [FEATURE] [Resource] [Work Type]
        // [SCENARIO 406833] "Work Type Code" can be set for 'all resources' price line ("Asset No." is blank)
        Initialize();
        // [GIVEN] Work Type 'WT', where "Unit of Measure Code" is 'UOM'
        LibraryResource.CreateWorkType(WorkType);
        LibraryInventory.CreateUnitOfMeasureCode(UnitofMeasure);
        WorkType."Unit of Measure Code" := UnitofMeasure.Code;
        WorkType.Modify();
        // [GIVEN] Price Worksheet Line, where "Source Type" is 'All Vendors', "Asset Type" is 'Resource', "Asset No." is <blank>
        PriceWorksheetLine.Validate("Source Type", "Price Source Type"::"All Vendors");
        PriceWorksheetLine.Validate("Asset Type", "Price Asset Type"::Resource);

        // [WHEN] Set "Work Type Code" as 'WT'
        PriceWorksheetLine.Validate("Work Type Code", WorkType.Code);

        // [THEN] Price Line, where "Unit of Measure Code" is 'UOM'
        PriceWorksheetLine.TestField("Work Type Code", WorkType.Code);
        PriceWorksheetLine.TestField("Unit of Measure Code", WorkType."Unit of Measure Code");
    end;

    [Test]
    procedure T120_DeletePricesOnResourceDeletion()
    var
        Resource: array[2] of Record Resource;
    begin
        // [FEATURE] [Resource]
        Initialize();
        // [GIVEN] Two Resource 'A' and 'B' have related price lines
        LibraryResource.CreateResource(Resource[1], '');
        LibraryResource.CreateResource(Resource[2], '');
        CreateAssetPriceLines("Price Asset Type"::Resource, Resource[1]."No.", Resource[2]."No.");

        // [WHEN] Delete Resource 'A'
        Resource[1].Delete(true);

        // [THEN] Price Worksheet Lines for Resource 'A' are deleted, for Resource 'B' are not deleted
        VerifyDeletedAssetPrices("Price Asset Type"::Resource, Resource[1]."No.", Resource[2]."No.");
    end;

    [Test]
    procedure T121_DeletePricesOnResourceGroupDeletion()
    var
        ResourceGroup: array[2] of Record "Resource Group";
    begin
        // [FEATURE] [Resource Group]
        Initialize();
        // [GIVEN] Two Resource Groups 'A' and 'B' have related price lines
        LibraryResource.CreateResourceGroup(ResourceGroup[1]);
        LibraryResource.CreateResourceGroup(ResourceGroup[2]);
        CreateAssetPriceLines("Price Asset Type"::"Resource Group", ResourceGroup[1]."No.", ResourceGroup[2]."No.");

        // [WHEN] Delete ResourceGroup 'A'
        ResourceGroup[1].Delete(true);

        // [THEN] Price Worksheet Lines for ResourceGroup 'A' are deleted, for ResourceGroup 'B' are not deleted
        VerifyDeletedAssetPrices("Price Asset Type"::"Resource Group", ResourceGroup[1]."No.", ResourceGroup[2]."No.");
    end;

    [Test]
    procedure T122_DeletePricesOnItemDeletion()
    var
        Item: array[2] of Record Item;
    begin
        // [FEATURE] [Item]
        Initialize();
        // [GIVEN] Two Item 'A' and 'B' have related price lines
        LibraryInventory.CreateItem(Item[1]);
        LibraryInventory.CreateItem(Item[2]);
        CreateAssetPriceLines("Price Asset Type"::Item, Item[1]."No.", Item[2]."No.");

        // [WHEN] Delete Item 'A'
        Item[1].Delete(true);

        // [THEN] Price Worksheet Lines for Item 'A' are deleted, for Item 'B' are not deleted
        VerifyDeletedAssetPrices("Price Asset Type"::Item, Item[1]."No.", Item[2]."No.");
    end;

    [Test]
    procedure T123_DeletePricesOnItemDiscountGroupDeletion()
    var
        ItemDiscountGroup: array[2] of Record "Item Discount Group";
    begin
        // [FEATURE] [Item Discount Group]
        Initialize();
        // [GIVEN] Two "Item Discount Group" 'A' and 'B' have related price lines
        LibraryERM.CreateItemDiscountGroup(ItemDiscountGroup[1]);
        LibraryERM.CreateItemDiscountGroup(ItemDiscountGroup[2]);
        CreateAssetDiscLines("Price Asset Type"::"Item Discount Group", ItemDiscountGroup[1].Code, ItemDiscountGroup[2].Code);

        // [WHEN] Delete "Item Discount Group" 'A'
        ItemDiscountGroup[1].Delete(true);

        // [THEN] Price Worksheet Lines for "Item Discount Group" 'A' are deleted, for "Item Discount Group" 'B' are not deleted
        VerifyDeletedAssetPrices("Price Asset Type"::"Item Discount Group", ItemDiscountGroup[1].Code, ItemDiscountGroup[2].Code);
    end;

    [Test]
    procedure T124_DeletePricesOnGLAccountDeletion()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLAccount: array[2] of Record "G/L Account";
    begin
        // [FEATURE] [G/L Account]
        Initialize();
        // [GIVEN] GeneralLedgerSetup, where "Allow G/L Acc. Deletion Before" is set
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Allow G/L Acc. Deletion Before" := WorkDate();
        GeneralLedgerSetup.Modify();
        // [GIVEN] Two G/L Account 'A' and 'B' have related price lines
        LibraryERM.CreateGLAccount(GLAccount[1]);
        LibraryERM.CreateGLAccount(GLAccount[2]);
        CreateAssetPriceLines("Price Asset Type"::"G/L Account", GLAccount[1]."No.", GLAccount[2]."No.");

        // [WHEN] Delete G/L Account 'A'
        GLAccount[1].Delete(true);

        // [THEN] Price Worksheet Lines for G/L Account 'A' are deleted, for G/L Account 'B' are not deleted
        VerifyDeletedAssetPrices("Price Asset Type"::"G/L Account", GLAccount[1]."No.", GLAccount[2]."No.");
    end;

    [Test]
    procedure T125_DeletePricesOnServiceCostDeletion()
    var
        ServiceCost: array[2] of Record "Service Cost";
    begin
        // [FEATURE] [Service Cost]
        Initialize();
        // [GIVEN] Two "Service Cost" 'A' and 'B' have related price lines
        LibraryService.CreateServiceCost(ServiceCost[1]);
        LibraryService.CreateServiceCost(ServiceCost[2]);
        CreateAssetPriceLines("Price Asset Type"::"Service Cost", ServiceCost[1].Code, ServiceCost[2].Code);

        // [WHEN] Delete Service Cost 'A'
        ServiceCost[1].Delete(true);

        // [THEN] Price Worksheet Lines for Service Cost 'A' are deleted, for Service Cost 'B' are not deleted
        VerifyDeletedAssetPrices("Price Asset Type"::"Service Cost", ServiceCost[1].Code, ServiceCost[2].Code);
    end;

    [Test]
    procedure T126_DeletePricesOnItemVariantDeletion()
    var
        Item: Record Item;
        ItemVariant: array[2] of Record "Item Variant";
    begin
        // [FEATURE] [Item Variant]
        Initialize();
        // [GIVEN] Two Item Variants 'A' and 'B' have related price lines
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant[1], Item."No.");
        LibraryInventory.CreateItemVariant(ItemVariant[2], Item."No.");
        CreateAssetPriceLines(Item."No.", ItemVariant[1].Code, ItemVariant[2].Code);

        // [WHEN] Delete Item Variant 'A'
        ItemVariant[1].Delete(true);

        // [THEN] Price Worksheet Lines for Item Variant 'A' are deleted, for Item Variant 'B' are not deleted
        VerifyDeletedAssetPrices(Item."No.", ItemVariant[1].Code, ItemVariant[2].Code);
    end;

    [Test]
    procedure T130_ModifyPricesOnResourceRename()
    var
        Resource: array[2] of Record Resource;
        OldNo: Code[20];
    begin
        // [FEATURE] [Resource]
        Initialize();
        // [GIVEN] Two Resource 'A' and 'B' have related price lines
        LibraryResource.CreateResource(Resource[1], '');
        LibraryResource.CreateResource(Resource[2], '');
        CreateAssetPriceLines("Price Asset Type"::Resource, Resource[1]."No.", Resource[2]."No.");

        // [WHEN] Rename Resource 'A' to 'X'
        OldNo := Resource[1]."No.";
        Resource[1].Rename(LibraryUtility.GenerateGUID());

        // [THEN] Price Worksheet Lines for Resource 'A' are modified to 'X', for Resource 'B' are not deleted
        VerifyRenamedAssetPrices("Price Asset Type"::Resource, Resource[1]."No.", Resource[2]."No.", OldNo);
    end;

    [Test]
    procedure T131_ModifyPricesOnResourceGroupRename()
    var
        ResourceGroup: array[2] of Record "Resource Group";
        OldNo: Code[20];
    begin
        // [FEATURE] [Resource Group]
        Initialize();
        // [GIVEN] Two Resource 'A' and 'B' have related price lines
        LibraryResource.CreateResourceGroup(ResourceGroup[1]);
        LibraryResource.CreateResourceGroup(ResourceGroup[2]);
        CreateAssetPriceLines("Price Asset Type"::"Resource Group", ResourceGroup[1]."No.", ResourceGroup[2]."No.");

        // [WHEN] Rename ResourceGroup 'A' to 'X'
        OldNo := ResourceGroup[1]."No.";
        ResourceGroup[1].Rename(LibraryUtility.GenerateGUID());

        // [THEN] Price Worksheet Lines for ResourceGroup 'A' are modified to 'X', for ResourceGroup 'B' are not deleted
        VerifyRenamedAssetPrices("Price Asset Type"::"Resource Group", ResourceGroup[1]."No.", ResourceGroup[2]."No.", OldNo);
    end;

    [Test]
    procedure T132_ModifyPricesOnItemRename()
    var
        Item: array[2] of Record Item;
        OldNo: Code[20];
    begin
        // [FEATURE] [Item]
        Initialize();
        // [GIVEN] Two Item 'A' and 'B' have related price lines
        LibraryInventory.CreateItem(Item[1]);
        LibraryInventory.CreateItem(Item[2]);
        CreateAssetPriceLines("Price Asset Type"::Item, Item[1]."No.", Item[2]."No.");

        // [WHEN] Rename Item 'A' to 'X'
        OldNo := Item[1]."No.";
        Item[1].Rename(LibraryUtility.GenerateGUID());

        // [THEN] Price Worksheet Lines for Item 'A' are modified to 'X', for Item 'B' are not deleted
        VerifyRenamedAssetPrices("Price Asset Type"::Item, Item[1]."No.", Item[2]."No.", OldNo);
    end;

    [Test]
    procedure T133_ModifyPricesOnItemDiscountGroupRename()
    var
        ItemDiscountGroup: array[2] of Record "Item Discount Group";
        OldNo: Code[20];
    begin
        // [FEATURE] [Item Discount Group]
        Initialize();
        // [GIVEN] Two Item Discount Groups 'A' and 'B' have related price lines
        LibraryERM.CreateItemDiscountGroup(ItemDiscountGroup[1]);
        LibraryERM.CreateItemDiscountGroup(ItemDiscountGroup[2]);
        CreateAssetDiscLines("Price Asset Type"::"Item Discount Group", ItemDiscountGroup[1].Code, ItemDiscountGroup[2].Code);

        // [WHEN] Rename ItemDiscountGroup 'A' to 'X'
        OldNo := ItemDiscountGroup[1].Code;
        ItemDiscountGroup[1].Rename(LibraryUtility.GenerateGUID());

        // [THEN] Price Worksheet Lines for "Item Discount Group" 'A' are modified to 'X', for "Item Discount Group" 'B' are not deleted
        VerifyRenamedAssetPrices("Price Asset Type"::"Item Discount Group", ItemDiscountGroup[1].Code, ItemDiscountGroup[2].Code, OldNo);
    end;

    [Test]
    procedure T134_ModifyPricesOnGLAccountRename()
    var
        GLAccount: array[2] of Record "G/L Account";
        OldNo: Code[20];
    begin
        // [FEATURE] [G/L Account]
        Initialize();
        // [GIVEN] Two GLAccount 'A' and 'B' have related price lines
        LibraryERM.CreateGLAccount(GLAccount[1]);
        LibraryERM.CreateGLAccount(GLAccount[2]);
        CreateAssetPriceLines("Price Asset Type"::"G/L Account", GLAccount[1]."No.", GLAccount[2]."No.");

        // [WHEN] Rename GLAccount 'A' to 'X'
        OldNo := GLAccount[1]."No.";
        GLAccount[1].Rename(LibraryUtility.GenerateGUID());

        // [THEN] Price Worksheet Lines for GLAccount 'A' are modified to 'X', for GLAccount 'B' are not deleted
        VerifyRenamedAssetPrices("Price Asset Type"::"G/L Account", GLAccount[1]."No.", GLAccount[2]."No.", OldNo);
    end;

    [Test]
    procedure T135_ModifyPricesOnServiceCostRename()
    var
        ServiceCost: array[2] of Record "Service Cost";
        OldNo: Code[20];
    begin
        // [FEATURE] [Service Cost]
        Initialize();
        // [GIVEN] Two "Service Cost" 'A' and 'B' have related price lines
        LibraryService.CreateServiceCost(ServiceCost[1]);
        LibraryService.CreateServiceCost(ServiceCost[2]);
        CreateAssetPriceLines("Price Asset Type"::"Service Cost", ServiceCost[1].Code, ServiceCost[2].Code);

        // [WHEN] Rename "Service Cost" 'A' to 'X'
        OldNo := ServiceCost[1].Code;
        ServiceCost[1].Rename(LibraryUtility.GenerateGUID());

        // [THEN] Price Worksheet Lines for "Service Cost" 'A' are modified to 'X', for "Service Cost" 'B' are not deleted
        VerifyRenamedAssetPrices("Price Asset Type"::"Service Cost", ServiceCost[1].Code, ServiceCost[2].Code, OldNo);
    end;

    [Test]
    procedure T136_ModifyPricesOnItemVariantRename()
    var
        Item: Record Item;
        ItemVariant: array[2] of Record "Item Variant";
        OldNo: Code[10];
    begin
        // [FEATURE] [Item Variant]
        Initialize();
        // [GIVEN] Two Item Variants 'A' and 'B' have related price lines
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant[1], Item."No.");
        LibraryInventory.CreateItemVariant(ItemVariant[2], Item."No.");
        CreateAssetPriceLines(Item."No.", ItemVariant[1].Code, ItemVariant[2].Code);

        // [WHEN] Rename Item Variant 'A' to 'X'
        OldNo := ItemVariant[1].Code;
        ItemVariant[1].Rename(Item."No.", LibraryUtility.GenerateGUID());

        // [THEN] Price Worksheet Lines for Item Variant 'A' are modified to 'X', for Item Variant 'B' are not deleted
        VerifyRenamedAssetPrices(Item."No.", ItemVariant[1].Code, ItemVariant[2].Code, OldNo);
    end;

    [Test]
    procedure T137_ModifyPricesOnUnitOfMeasureRename()
    var
        UnitOfMeasure: array[2] of Record "Unit Of Measure";
        OldNo: Code[20];
    begin
        // [FEATURE] [Unit of Measure]
        Initialize();
        // [GIVEN] Two "Unit of Measure" 'A' and 'B' have related price lines
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure[1]);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure[2]);
        CreatePriceLinesWithUOM(UnitOfMeasure[1].Code, UnitOfMeasure[2].Code);

        // [WHEN] Rename "Unit Of Measure" 'A' to 'X'
        OldNo := UnitOfMeasure[1].Code;
        UnitOfMeasure[1].Rename(LibraryUtility.GenerateGUID());

        // [THEN] Price Worksheet Lines for "Unit Of Measure" 'A' are modified to 'X', for "Unit Of Measure" 'B' are not deleted
        VerifyRenamedUOMs(UnitOfMeasure[1].Code, UnitOfMeasure[2].Code, OldNo);
    end;

    [Test]
    procedure T140_ValidateStartingDateAfterEndingDate()
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        Initialize();
        // [GIVEN] Price Worksheet Line, where  "Ending Date" is '310120'
        PriceWorksheetLine.Init();
        PriceWorksheetLine."Ending Date" := WorkDate();
        // [WHEN] Set "Starting Date" as '010220'
        asserterror PriceWorksheetLine.Validate("Starting Date", PriceWorksheetLine."Ending Date" + 1);

        // [THEN] Error message: 'Starting Date cannot be after Ending Date'
        Assert.ExpectedError(StrSubstNo(StartingDateErr, PriceWorksheetLine."Ending Date" + 1, PriceWorksheetLine."Ending Date"));
    end;

    [Test]
    procedure T141_ValidateEndingDateBeforeStartingDate()
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        Initialize();
        // [GIVEN] Price Worksheet Line, where "Starting Date" is '010220'
        PriceWorksheetLine.Init();
        PriceWorksheetLine."Starting Date" := WorkDate();
        // [WHEN] Set "Ending Date" as '310120'
        asserterror PriceWorksheetLine.Validate("Ending Date", PriceWorksheetLine."Starting Date" - 1);

        // [THEN] Error message: 'Starting Date cannot be after Ending Date'
        Assert.ExpectedError(StrSubstNo(StartingDateErr, PriceWorksheetLine."Starting Date", PriceWorksheetLine."Starting Date" - 1));
    end;

    [Test]
    procedure T142_ValidateStartingDateForCampaign()
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [FEATURE] [Campaign]
        Initialize();
        // [GIVEN] Price Worksheet Line, where "Source Type" is 'Campaign', "Ending Date" is '310120'
        PriceWorksheetLine.Init();
        PriceWorksheetLine."Source Type" := "Price Source Type"::Campaign;
        PriceWorksheetLine."Ending Date" := WorkDate();
        // [WHEN] Set "Starting Date" as '010120'
        asserterror PriceWorksheetLine.Validate("Starting Date", WorkDate() + 1);

        // [THEN] Error message: '... you can only change Starting Date and Ending Date from the Campaign Card.'
        Assert.ExpectedError(CampaignDateErr);
    end;

    [Test]
    procedure T143_ValidateEndingDateForCampaignViaUI()
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
        MockPriceWorksheetLine: TestPage "Mock Price Worksheet Line";
    begin
        // [FEATURE] [Campaign] [UI]
        Initialize();
        // [GIVEN] Price Worksheet Line, where "Source Type" is 'Campaign', "Starting Date" is '010220'
        PriceWorksheetLine.DeleteAll();
        PriceWorksheetLine.Init();
        PriceWorksheetLine."Source Type" := "Price Source Type"::Campaign;
        PriceWorksheetLine."Starting Date" := WorkDate();
        PriceWorksheetLine.Insert();
        // [GIVEN] Open page 
        MockPriceWorksheetLine.Trap();
        Page.Run(Page::"Mock Price Worksheet Line", PriceWorksheetLine, PriceWorksheetLine."Starting Date");
        // [WHEN] Set "Ending Date" as '310120'
        asserterror MockPriceWorksheetLine."Ending Date".SetValue(PriceWorksheetLine."Starting Date" - 1);

        // [THEN] Error message: '... you can only change Starting Date and Ending Date from the Campaign Card.'
        Assert.ExpectedError(CampaignDateErr);
    end;

    [Test]
    procedure T150_ValidateUnitOfMeasureForNonItem()
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
        UnitofMeasure: Record "Unit of Measure";
    begin
        // [FEATURE] [Unit of Measure]
        Initialize();
        // [GIVEN] Price Worksheet Line, where "Asset Type" is 'G/L Account'
        PriceWorksheetLine.Init();
        PriceWorksheetLine."Asset Type" := "Price Asset Type"::"G/L Account";
        // [WHEN] Set "Unit Of Meadure" as 'BOX'
        UnitofMeasure.FindFirst();
        asserterror PriceWorksheetLine.Validate("Unit of Measure Code", UnitofMeasure.Code);

        // [THEN] Error message: 'Asset Type must be Item or Resource.'
        Assert.ExpectedError(AssetTypeForUOMErr);
    end;

    [Test]
    procedure T151_ValidateVariantCodeForNonItem()
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
        ItemVariant: Record "Item Variant";
    begin
        // [FEATURE] [Item Variant]
        Initialize();
        // [GIVEN] Item Variant 'X' for Item 'I'
        ItemVariant.FindFirst();
        // [GIVEN] Price Worksheet Line, where "Asset Type" is 'Item Discount Group', "Asset Type" is 'I'
        PriceWorksheetLine.Init();
        PriceWorksheetLine."Asset Type" := "Price Asset Type"::"Item Discount Group";
        PriceWorksheetLine."Asset No." := ItemVariant."Item No.";
        // [WHEN] Set "Variant Code" as 'X'
        asserterror PriceWorksheetLine.Validate("Variant Code", ItemVariant.Code);

        // [THEN] Error message: 'Asset Type must be Item.'
        Assert.ExpectedTestFieldError(PriceWorksheetLine.FieldCaption("Asset Type"), Format(PriceWorksheetLine."Asset Type"::Item));
    end;

    [Test]
    procedure T160_ValidateUnitPriceForJob()
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [FEATURE] [Job]
        Initialize();
        // [GIVEN] Price Worksheet Line, where "Source Type" is 'Job', "Cost Factor" is 2
        PriceWorksheetLine.Init();
        PriceWorksheetLine."Source Type" := "Price Source Type"::Job;
        PriceWorksheetLine."Source No." := 'JOB';
        PriceWorksheetLine."Asset Type" := "Price Asset Type"::"G/L Account";
        PriceWorksheetLine."Asset No." := 'ACC';
        PriceWorksheetLine."Cost Factor" := 2;
        // [WHEN] Set "Unit Price" as 1
        PriceWorksheetLine.Validate("Unit Price", 1);
        // [THEN] "Cost Factor" is 0
        PriceWorksheetLine.TestField("Cost Factor", 0);
    end;

    [Test]
    procedure T161_ValidateCostFactorForJob()
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [FEATURE] [Job]
        Initialize();
        // [GIVEN] Price Worksheet Line, where "Source Type" is 'Job', "Unit Price" is 2
        PriceWorksheetLine.Init();
        PriceWorksheetLine.Validate("Source Type", "Price Source Type"::Job);
        PriceWorksheetLine."Source No." := 'JOB';
        PriceWorksheetLine."Asset Type" := "Price Asset Type"::"G/L Account";
        PriceWorksheetLine."Asset No." := 'ACC';
        PriceWorksheetLine."Unit Price" := 2;
        // [WHEN] Set "Cost Factor" as 1
        PriceWorksheetLine.Validate("Cost Factor", 1);
        // [THEN] "Unit Price" is 0
        PriceWorksheetLine.TestField("Unit Price", 0);
    end;

    [Test]
    procedure T162_ValidateCostFactorForNonJob()
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [FEATURE] [Cost Factor]
        Initialize();
        // [GIVEN] Price Worksheet Line, where "Source Type" is 'All Customers'
        PriceWorksheetLine.Init();
        PriceWorksheetLine.Validate("Source Type", "Price Source Type"::"All Customers");
        PriceWorksheetLine."Asset Type" := "Price Asset Type"::"G/L Account";
        PriceWorksheetLine."Asset No." := 'ACC';
        // [WHEN] Set "Cost Factor" as 1
        asserterror PriceWorksheetLine.Validate("Cost Factor", 1);
        // [THEN] Error message: 'Source Group must be equal to Project'
        Assert.ExpectedTestFieldError(PriceWorksheetLine.FieldCaption("Source Group"), Format(PriceWorksheetLine."Source Group"::Job));
    end;

    [Test]
    procedure T163_ValidateNonPostingJobTask()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [FEATURE] [Job]
        Initialize();
        // [GIVEN] Job Task 'JT', where "Job Task Type" is 'Heading' (not Posting)
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        JobTask."Job Task Type" := JobTask."Job Task Type"::Heading;
        JobTask.Modify();
        // [GIVEN] Price Worksheet Line, where "Source Type" is 'Job Task'
        PriceWorksheetLine.Init();
        PriceWorksheetLine."Source Type" := "Price Source Type"::"Job Task";
        PriceWorksheetLine."Parent Source No." := Job."No.";
        // [WHEN] Set "Source No." as 'JT'
        asserterror PriceWorksheetLine.Validate("Source No.", JobTask."Job Task No.");
        // [THEN] Error message: 'Job Task Type must be equal to Posting'
        Assert.ExpectedError(NotPostingJobTaskTypeErr);
    end;

    [Test]
    procedure T164_ValidateJobNoAsSource()
    var
        Currency: Record Currency;
        Job: Record Job;
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [FEATURE] [Job]
        Initialize();
        // [GIVEN] Job Task 'J', where "Currency Code" is 'USD'
        LibraryJob.CreateJob(Job);
        LibraryERM.CreateCurrency(Currency);
        Job."Currency Code" := Currency.Code;
        Job.Modify();
        // [GIVEN] Price Worksheet Line, where "Source Type" is 'Job'
        PriceWorksheetLine.Init();
        PriceWorksheetLine."Source Type" := "Price Source Type"::"Job";
        // [WHEN] Set "Source No." as 'JT'
        PriceWorksheetLine.Validate("Source No.", Job."No.");
        // [THEN] Line, where "Currency Code" is 'USD'
        PriceWorksheetLine.TestField("Currency Code", Job."Currency Code");
    end;

    [Test]
    procedure T165_ValidateJobNoAsParentSource()
    var
        Currency: Record Currency;
        Job: Record Job;
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        // [FEATURE] [Job]
        Initialize();
        // [GIVEN] Job Task 'J', where "Currency Code" is 'USD'
        LibraryJob.CreateJob(Job);
        LibraryERM.CreateCurrency(Currency);
        Job."Currency Code" := Currency.Code;
        Job.Modify();
        // [GIVEN] Price Worksheet Line, where "Source Type" is 'Job Task'
        PriceWorksheetLine.Init();
        PriceWorksheetLine."Source Type" := "Price Source Type"::"Job Task";
        // [WHEN] Set "Parent Source No." as 'J'
        PriceWorksheetLine.Validate("Parent Source No.", Job."No.");
        // [THEN] Line, where "Currency Code" is 'USD'
        PriceWorksheetLine.TestField("Currency Code", Job."Currency Code");
    end;

    [Test]
    [HandlerFunctions('LookupJobModalHandler,LookupJobTaskModalHandler')]
    procedure T200_LookupJobTaskInLineParentSourceBlank()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        PriceListHeader: Record "Price List Header";
        PriceWorksheetLine: Record "Price Worksheet Line";
        SalesPriceList: TestPage "Sales Price List";
    begin
        // [FEATURE] [Source] [Job Task] [Allow Updating Defaults]
        Initialize(true);
        PriceListHeader.DeleteAll();
        PriceWorksheetLine.DeleteAll();
        // [GIVEN] Job Task 'JT', where Job is 'J'
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Price List Header, where "Source Group" is 'Job', "Allow Updating Defaults" is true
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Jobs", '');
        PriceListHeader.Validate("Allow Updating Defaults", true);
        PriceListHeader.Modify();

        // [GIVEN] Open price list page, add new line, where SourceType is 'Job Task'
        SalesPriceList.OpenEdit();
        SalesPriceList.Filter.SetFilter(Code, PriceListHeader.Code);
        SalesPriceList.Lines.New();
        SalesPriceList.Lines.JobSourceType.SetValue("Price Source Type"::"Job Task");

        // [WHEN] Lookup "Source No.", setting "Job No." as 'J', "Job Task No." as JT
        LibraryVariableStorage.Enqueue(JobTask."Job No."); // for LookupJobModalHandler
        LibraryVariableStorage.Enqueue(JobTask."Job Task No."); // for LookupJobTaskModalHandler
        SalesPriceList.Lines.SourceNo.Lookup();

        // [THEN] "Source No." is 'JT',"Parent Source No." is 'J'
        SalesPriceList.Lines.ParentSourceNo.AssertEquals(JobTask."Job No.");
        SalesPriceList.Lines.SourceNo.AssertEquals(JobTask."Job Task No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('LookupJobModalHandler')]
    procedure T201_LookupJobInJobTaskLine()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        PriceListHeader: Record "Price List Header";
        PriceWorksheetLine: Record "Price Worksheet Line";
        SalesPriceList: TestPage "Sales Price List";
    begin
        // [FEATURE] [Source] [Job Task] [Allow Updating Defaults]
        Initialize(true);
        PriceListHeader.DeleteAll();
        PriceWorksheetLine.DeleteAll();
        // [GIVEN] Job Task 'JT', where Job is 'J'
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        // [GIVEN] Price List Header, where "Source Group" is 'Job', "Allow Updating Defaults" is true
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Jobs", '');
        PriceListHeader.Validate("Allow Updating Defaults", true);
        PriceListHeader.Modify();

        // [GIVEN] Open price list page, add new line, where SourceType is 'Job Task'
        SalesPriceList.OpenEdit();
        SalesPriceList.Filter.SetFilter(Code, PriceListHeader.Code);
        SalesPriceList.Lines.New();
        SalesPriceList.Lines.JobSourceType.SetValue("Price Source Type"::"Job Task");

        // [WHEN] Lookup " Parent Source No.", setting "Job No." as 'J'
        LibraryVariableStorage.Enqueue(JobTask."Job No."); // for LookupJobModalHandler
        SalesPriceList.Lines.ParentSourceNo.Lookup();

        // [THEN] "Parent Source No." is 'J', "Source No." is <blank>
        SalesPriceList.Lines.ParentSourceNo.AssertEquals(JobTask."Job No.");
        SalesPriceList.Lines.SourceNo.AssertEquals('');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('LookupJobTaskModalHandler')]
    procedure T202_LookupJobThenJobTaskInJobTaskLine()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        PriceListHeader: Record "Price List Header";
        PriceWorksheetLine: Record "Price Worksheet Line";
        SalesPriceList: TestPage "Sales Price List";
    begin
        // [FEATURE] [Source] [Job Task] [Allow Updating Defaults]
        Initialize(true);
        PriceListHeader.DeleteAll();
        PriceWorksheetLine.DeleteAll();
        // [GIVEN] Job Task 'JT', where Job is 'J1' (added to have two tasks with the same "Job Task No.", but diff "Job No.")
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        // [GIVEN] Job Task 'JT', where Job is 'J2'
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        // [GIVEN] Price List Header, where "Source Group" is 'Job', "Allow Updating Defaults" is true
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Jobs", '');
        PriceListHeader.Validate("Allow Updating Defaults", true);
        PriceListHeader.Modify();

        // [GIVEN] Open price list page, add new line, where SourceType is 'Job Task'
        SalesPriceList.OpenEdit();
        SalesPriceList.Filter.SetFilter(Code, PriceListHeader.Code);
        SalesPriceList.Lines.New();
        SalesPriceList.Lines.JobSourceType.SetValue("Price Source Type"::"Job Task");

        // [GIVEN] Set "Parent Source No.", "Job No." as 'J2'
        SalesPriceList.Lines.ParentSourceNo.SetValue(JobTask."Job No.");

        // [WHEN] Lookup "Source No.", setting "Job Task No." as 'JT'
        LibraryVariableStorage.Enqueue(JobTask."Job Task No."); // for LookupJobTaskModalHandler
        SalesPriceList.Lines.SourceNo.Lookup();

        // [THEN] "Parent Source No." is 'J2', "Source No." is 'JT'
        SalesPriceList.Lines.ParentSourceNo.AssertEquals(JobTask."Job No.");
        SalesPriceList.Lines.SourceNo.AssertEquals(JobTask."Job Task No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('LookupJobModalHandler')]
    procedure T203_LookupJobIfJobAndTaskFilledInJobTaskLine()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        PriceListHeader: Record "Price List Header";
        PriceWorksheetLine: Record "Price Worksheet Line";
        SalesPriceList: TestPage "Sales Price List";
    begin
        // [FEATURE] [Source] [Job Task] [Allow Updating Defaults]
        Initialize(true);
        PriceListHeader.DeleteAll();
        PriceWorksheetLine.DeleteAll();
        // [GIVEN] Job Task 'JT', where Job is 'J'
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        // [GIVEN] Price List Header, where "Source Group" is 'Job', "Allow Updating Defaults" is true
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Jobs", '');
        PriceListHeader.Validate("Allow Updating Defaults", true);
        PriceListHeader.Modify();

        // [GIVEN] Open price list page, add new line, where SourceType is 'Job Task'
        SalesPriceList.OpenEdit();
        SalesPriceList.Filter.SetFilter(Code, PriceListHeader.Code);
        SalesPriceList.Lines.New();
        SalesPriceList.Lines.JobSourceType.SetValue("Price Source Type"::"Job Task");

        // [GIVEN] Set "Parent Source No." as 'J', "Source No." as 'JT'
        SalesPriceList.Lines.ParentSourceNo.SetValue(JobTask."Job No.");
        SalesPriceList.Lines.SourceNo.SetValue(JobTask."Job Task No.");

        // [WHEN] Lookup "Parent Source No.", setting "Job No." as 'J'
        LibraryVariableStorage.Enqueue(JobTask."Job No."); // for LookupJobModalHandler
        SalesPriceList.Lines.ParentSourceNo.Lookup();

        // [THEN] "Parent Source No." is 'J', "Source No." is <blank>
        SalesPriceList.Lines.ParentSourceNo.AssertEquals(JobTask."Job No.");
        SalesPriceList.Lines.SourceNo.AssertEquals('');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('LookupJobCancelModalHandler')]
    procedure T204_LookupJobTaskCancelledInLineParentSourceBlank()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        PriceListHeader: Record "Price List Header";
        PriceWorksheetLine: Record "Price Worksheet Line";
        SalesPriceList: TestPage "Sales Price List";
    begin
        // [FEATURE] [Source] [Job Task] [Allow Updating Defaults]
        Initialize(true);
        PriceListHeader.DeleteAll();
        PriceWorksheetLine.DeleteAll();
        // [GIVEN] Job Task 'JT', where Job is 'J'
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        // [GIVEN] Price List Header, where "Source Group" is 'Job', "Allow Updating Defaults" is true
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Jobs", '');
        PriceListHeader.Validate("Allow Updating Defaults", true);
        PriceListHeader.Modify();

        // [GIVEN] Open price list page, add new line, where SourceType is 'Job Task'
        SalesPriceList.OpenEdit();
        SalesPriceList.Filter.SetFilter(Code, PriceListHeader.Code);
        SalesPriceList.Lines.New();
        SalesPriceList.Lines.JobSourceType.SetValue("Price Source Type"::"Job Task");

        // [WHEN] Lookup "Source No.", cancel on the Job list
        SalesPriceList.Lines.SourceNo.Lookup(); // by LookupJobCancelModalHandler

        // [THEN] "Source No." is <blank>,"Parent Source No." is <blank>
        SalesPriceList.Lines.ParentSourceNo.AssertEquals('');
        SalesPriceList.Lines.SourceNo.AssertEquals('');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure T205_JobTaskInLineSetParentSourceBlank()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        PriceListHeader: Record "Price List Header";
        PriceWorksheetLine: Record "Price Worksheet Line";
        SalesPriceList: TestPage "Sales Price List";
    begin
        // [FEATURE] [Source] [Job Task] [Allow Updating Defaults]
        Initialize(true);
        PriceListHeader.DeleteAll();
        PriceWorksheetLine.DeleteAll();
        // [GIVEN] Job Task 'JT', where Job is 'J'
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        // [GIVEN] Price List Header, where "Source Group" is 'Job', "Allow Updating Defaults" is true
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Jobs", '');
        PriceListHeader.Validate("Allow Updating Defaults", true);
        PriceListHeader.Modify();

        // [GIVEN] Open price list page, add new line, where SourceType is 'Job Task'
        SalesPriceList.OpenEdit();
        SalesPriceList.Filter.SetFilter(Code, PriceListHeader.Code);
        SalesPriceList.Lines.New();
        SalesPriceList.Lines.JobSourceType.SetValue("Price Source Type"::"Job Task");

        // [GIVEN] Set "Parent Source No." and "Source No." as 'J' and 'JT'
        SalesPriceList.Lines.ParentSourceNo.SetValue(JobTask."Job No.");
        SalesPriceList.Lines.SourceNo.SetValue(JobTask."Job Task No.");

        // [WHEN] Set "Parent Source No." as <blank>
        SalesPriceList.Lines.ParentSourceNo.SetValue('');

        // [THEN] "Source No." is <blank>,"Parent Source No." is <blank>
        SalesPriceList.Lines.ParentSourceNo.AssertEquals('');
        SalesPriceList.Lines.SourceNo.AssertEquals('');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('LookupItemModalHandler')]
    procedure T216_LookupProductNo()
    var
        Item: Record Item;
        MockPriceWorksheetLine: TestPage "Mock Price List Line";
    begin
        // [FEATURE] [Asset]
        Initialize();
        // [GIVEN] Item 'I'
        LibraryInventory.CreateItem(Item);
        // [GIVEN] Price Line, where "Asset Type" is 'Item'
        MockPriceWorksheetLine.OpenEdit();
        MockPriceWorksheetLine."Asset Type".SetValue("Price Asset Type"::Item);
        // [WHEN] Lookup "Asset No." set as 'I'
        LibraryVariableStorage.Enqueue(Item."No."); // for LookupItemModalHandler
        MockPriceWorksheetLine."Product No.".Lookup();

        // [THEN] "Asset No." is 'I'
        MockPriceWorksheetLine."Product No.".AssertEquals(Item."No.");
    end;

    local procedure Initialize()
    begin
        Initialize(false);
    end;

    local procedure Initialize(Enable: Boolean)
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Price Worksheet Line UT");
        LibraryVariableStorage.Clear();
        LibraryPriceCalculation.EnableExtendedPriceCalculation(Enable);

        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Price Worksheet Line UT");
        LibraryERM.SetBlockDeleteGLAccount(false);
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Price Worksheet Line UT");
    end;

    local procedure CreateAssetDiscLines(AssetType: Enum "Price Asset Type"; AssetNo1: Code[20]; AssetNo2: Code[20])
    var
        PriceListLine: Record "Price List Line";
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        PriceWorksheetLine.DeleteAll();
        LibraryPriceCalculation.CreateSalesDiscountLine(
            PriceListLine, '', "Price Source Type"::"All Customers", '', AssetType, AssetNo1);
        PriceWorksheetLine.TransferFields(PriceListLine);
        PriceWorksheetLine.Insert();
        LibraryPriceCalculation.CreateSalesDiscountLine(
            PriceListLine, '', "Price Source Type"::"All Customers", '', AssetType, AssetNo2);
        PriceWorksheetLine.TransferFields(PriceListLine);
        PriceWorksheetLine.Insert();
    end;

    local procedure CreateAssetPriceLines(AssetType: Enum "Price Asset Type"; AssetNo1: Code[20]; AssetNo2: Code[20])
    var
        PriceListLine: Record "Price List Line";
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        PriceWorksheetLine.DeleteAll();
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, '', "Price Source Type"::"All Customers", '', AssetType, AssetNo1);
        PriceWorksheetLine.TransferFields(PriceListLine);
        PriceWorksheetLine.Insert();
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, '', "Price Source Type"::"All Customers", '', AssetType, AssetNo2);
        PriceWorksheetLine.TransferFields(PriceListLine);
        PriceWorksheetLine.Insert();
    end;

    local procedure CreatePriceLinesWithUOM(UOM1: Code[20]; UOM2: Code[20])
    var
        GLAccount: Record "G/L Account";
        PriceListLine: Record "Price List Line";
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        PriceWorksheetLine.DeleteAll();
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, '', "Price Source Type"::"All Customers", '', "Price Asset Type"::"G/L Account", GLAccount."No.");
        PriceListLine."Unit of Measure Code" := UOM1;
        PriceListLine.Modify();
        PriceWorksheetLine.TransferFields(PriceListLine);
        PriceWorksheetLine.Insert();
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, '', "Price Source Type"::"All Customers", '', "Price Asset Type"::"G/L Account", GLAccount."No.");
        PriceListLine."Unit of Measure Code" := UOM2;
        PriceListLine.Modify();
        PriceWorksheetLine.TransferFields(PriceListLine);
        PriceWorksheetLine.Insert();
    end;

    local procedure CreateAssetPriceLines(ItemNo: Code[20]; VariantCode1: Code[10]; VariantCode2: Code[10])
    var
        PriceListLine: Record "Price List Line";
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        PriceWorksheetLine.DeleteAll();
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, '', "Price Source Type"::"All Customers", '', "Price Asset Type"::Item, ItemNo);
        PriceListLine.Validate("Variant Code", VariantCode1);
        PriceListLine.Modify();
        PriceWorksheetLine.TransferFields(PriceListLine);
        PriceWorksheetLine.Insert();
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, '', "Price Source Type"::"All Customers", '', "Price Asset Type"::Item, ItemNo);
        PriceListLine.Validate("Variant Code", VariantCode2);
        PriceListLine.Modify();
        PriceWorksheetLine.TransferFields(PriceListLine);
        PriceWorksheetLine.Insert();
    end;

    local procedure GetWorkTypeCode(): Code[10]
    var
        WorkType: Record "Work Type";
    begin
        LibraryResource.CreateWorkType(WorkType);
        exit(WorkType.Code);
    end;

    local procedure VerifyDeletedAssetPrices(AssetType: Enum "Price Asset Type"; AssetNo1: Code[20]; AssetNo2: Code[20])
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        PriceWorksheetLine.SetRange("Asset Type", AssetType);
        PriceWorksheetLine.SetRange("Asset No.", AssetNo2);
        Assert.RecordCount(PriceWorksheetLine, 1);
        PriceWorksheetLine.SetRange("Asset No.", AssetNo1);
        Assert.RecordIsEmpty(PriceWorksheetLine);
    end;

    local procedure VerifyDeletedAssetPrices(ItemNo: Code[20]; VariantCode1: Code[10]; VariantCode2: Code[10])
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        PriceWorksheetLine.SetRange("Asset Type", "Price Asset Type"::Item);
        PriceWorksheetLine.SetRange("Asset No.", ItemNo);
        PriceWorksheetLine.SetRange("Variant Code", VariantCode2);
        Assert.RecordCount(PriceWorksheetLine, 1);
        PriceWorksheetLine.SetRange("Variant Code", VariantCode1);
        Assert.RecordIsEmpty(PriceWorksheetLine);
    end;

    local procedure VerifyRenamedAssetPrices(AssetType: Enum "Price Asset Type"; AssetNo1: Code[20]; AssetNo2: Code[20]; OldAssetNo: Code[20])
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        PriceWorksheetLine.SetRange("Asset Type", AssetType);
        PriceWorksheetLine.SetRange("Asset No.", AssetNo1);
        Assert.RecordCount(PriceWorksheetLine, 1);
        PriceWorksheetLine.SetRange("Asset No.", AssetNo2);
        Assert.RecordCount(PriceWorksheetLine, 1);
        PriceWorksheetLine.SetRange("Asset No.", OldAssetNo);
        Assert.RecordIsEmpty(PriceWorksheetLine);
    end;

    local procedure VerifyRenamedAssetPrices(ItemNo: Code[20]; VariantCode1: Code[10]; VariantCode2: Code[10]; OldVariantCode: Code[10])
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        PriceWorksheetLine.SetRange("Asset Type", "Price Asset Type"::Item);
        PriceWorksheetLine.SetRange("Asset No.", ItemNo);
        PriceWorksheetLine.SetRange("Variant Code", VariantCode1);
        Assert.RecordCount(PriceWorksheetLine, 1);
        PriceWorksheetLine.SetRange("Variant Code", VariantCode2);
        Assert.RecordCount(PriceWorksheetLine, 1);
        PriceWorksheetLine.SetRange("Variant Code", OldVariantCode);
        Assert.RecordIsEmpty(PriceWorksheetLine);
    end;

    local procedure VerifyRenamedUOMs(UOM1: Code[20]; UOM2: Code[20]; OldUOM: Code[20])
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        PriceWorksheetLine.SetRange("Unit of Measure Code", UOM1);
        Assert.RecordCount(PriceWorksheetLine, 1);
        PriceWorksheetLine.SetRange("Unit of Measure Code", UOM2);
        Assert.RecordCount(PriceWorksheetLine, 1);
        PriceWorksheetLine.SetRange("Unit of Measure Code", OldUOM);
        Assert.RecordIsEmpty(PriceWorksheetLine);
    end;

    local procedure CreateItem(var Item: Record Item)
    var
        ItemUnitofMeasure: Record "Item Unit of Measure";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        LibraryInventory.CreateItem(Item);
        Item."Allow Invoice Disc." := true;
        Item."Price Includes VAT" := true;
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        Item."VAT Bus. Posting Gr. (Price)" := VATBusinessPostingGroup.Code;
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitofMeasure, Item."No.", 10);
        Item."Sales Unit of Measure" := ItemUnitofMeasure.Code;
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitofMeasure, Item."No.", 10);
        Item."Purch. Unit of Measure" := ItemUnitofMeasure.Code;
        Item.Modify(true);
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    var
        Currency: Record Currency;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreateCurrency(Currency);
        Customer."Currency Code" := Currency.Code;
        Customer."Allow Line Disc." := true;
        Customer."Prices Including VAT" := false;
        Customer.Modify();
    end;

    local procedure CreateCustomerPriceGroup(var CustomerPriceGroup: Record "Customer Price Group")
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        CustomerPriceGroup."Allow Invoice Disc." := false;
        CustomerPriceGroup."Allow Line Disc." := false;
        CustomerPriceGroup."Price Includes VAT" := true;
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        CustomerPriceGroup."VAT Bus. Posting Gr. (Price)" := VATBusinessPostingGroup.Code;
        CustomerPriceGroup.Modify(true);
    end;

    local procedure VerifyLineVariant(PriceWorksheetLine: Record "Price Worksheet Line"; UoM: Code[10]; AllowInvoiceDisc: Boolean; PriceIncludesVAT: Boolean; VATBusPostingGr: Code[20]; VariantCode: Code[10]; WorkTypeCode: Code[10]; CurrencyCode: Code[10])
    begin
        PriceWorksheetLine.TestField("Unit of Measure Code", UoM);
        PriceWorksheetLine.TestField("Variant Code", VariantCode);
        PriceWorksheetLine.TestField("Allow Invoice Disc.", AllowInvoiceDisc);
        PriceWorksheetLine.TestField("Price Includes VAT", PriceIncludesVAT);
        PriceWorksheetLine.TestField("VAT Bus. Posting Gr. (Price)", VATBusPostingGr);
        PriceWorksheetLine.TestField("Work Type Code", WorkTypeCode);
        PriceWorksheetLine.TestField("Currency Code", CurrencyCode);
    end;

    local procedure VerifyLine(PriceWorksheetLine: Record "Price Worksheet Line"; AllowLineDisc: Boolean; PriceIncludesVAT: Boolean; VATBusPostingGr: Code[20]; CurrencyCode: Code[10])
    begin
        PriceWorksheetLine.TestField("Currency Code", CurrencyCode);
        PriceWorksheetLine.TestField("Allow Line Disc.", AllowLineDisc);
        PriceWorksheetLine.TestField("Price Includes VAT", PriceIncludesVAT);
        PriceWorksheetLine.TestField("VAT Bus. Posting Gr. (Price)", VATBusPostingGr);
    end;

    local procedure VerifyLine(PriceWorksheetLine: Record "Price Worksheet Line"; AllowLineDisc: Boolean; PriceIncludesVAT: Boolean; VATBusPostingGr: Code[20]; AlloInvDisc: Boolean)
    begin
        PriceWorksheetLine.TestField("Allow Invoice Disc.", AlloInvDisc);
        PriceWorksheetLine.TestField("Allow Line Disc.", AllowLineDisc);
        PriceWorksheetLine.TestField("Price Includes VAT", PriceIncludesVAT);
        PriceWorksheetLine.TestField("VAT Bus. Posting Gr. (Price)", VATBusPostingGr);
    end;

    local procedure VerifyLine(PriceWorksheetLine: Record "Price Worksheet Line"; StartingDate: Date; EndingDate: Date)
    begin
        PriceWorksheetLine.TestField("Starting Date", StartingDate);
        PriceWorksheetLine.TestField("Ending Date", EndingDate);
    end;

    [ModalPageHandler]
    procedure ItemUOMModalHandler(var ItemUnitsofMeasure: testpage "Item Units of Measure")
    begin
        LibraryVariableStorage.Enqueue(ItemUnitsofMeasure.Code.Value);
        LibraryVariableStorage.Enqueue(ItemUnitsofMeasure."Qty. per Unit of Measure".Value);
        LibraryVariableStorage.Enqueue(ItemUnitsofMeasure.Next());
        ItemUnitsofMeasure.First();
        ItemUnitsofMeasure.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ItemVariantsHandler(var ItemVariants: testpage "Item Variants")
    begin
        LibraryVariableStorage.Enqueue(ItemVariants.Code.Value);
        LibraryVariableStorage.Enqueue(ItemVariants.Next());
        ItemVariants.First();
        ItemVariants.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ResourceUOMModalHandler(var ResourceUnitsofMeasure: testpage "Resource Units of Measure")
    begin
        LibraryVariableStorage.Enqueue(ResourceUnitsofMeasure.Code.Value);
        LibraryVariableStorage.Enqueue(ResourceUnitsofMeasure."Qty. per Unit of Measure".Value);
        LibraryVariableStorage.Enqueue(ResourceUnitsofMeasure.Next());
        ResourceUnitsofMeasure.First();
        ResourceUnitsofMeasure.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure LookupCustomerModalHandler(var CustomerLookup: testpage "Customer Lookup")
    begin
        CustomerLookup.Filter.SetFilter("No.", LibraryVariableStorage.DequeueText());
        CustomerLookup.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure LookupItemModalHandler(var ItemLookup: testpage "Item Lookup")
    begin
        ItemLookup.Filter.SetFilter("No.", LibraryVariableStorage.DequeueText());
        ItemLookup.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure LookupJobCancelModalHandler(var JobList: testpage "Job List")
    begin
        JobList.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure LookupJobModalHandler(var JobList: testpage "Job List")
    begin
        JobList.Filter.SetFilter("No.", LibraryVariableStorage.DequeueText());
        JobList.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure LookupJobTaskModalHandler(var JobTaskList: testpage "Job Task List")
    begin
        JobTaskList.Filter.SetFilter("Job Task No.", LibraryVariableStorage.DequeueText());
        JobTaskList.OK().Invoke();
    end;
}
