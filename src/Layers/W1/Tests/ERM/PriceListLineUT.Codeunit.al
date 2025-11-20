codeunit 134123 "Price List Line UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Price Calculation] [Price List Line]
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
        WrongPriceListCodeErr: Label 'The field Price List Code of table Price List Line contains a value (%1) that cannot be found';
        FieldNotAllowedForAmountTypeErr: Label 'Field %1 is not allowed in the price list line where %2 is %3.',
            Comment = '%1 - the field caption; %2 - Amount Type field caption; %3 - amount type value: Discount or Price';
        AmountTypeMustBeDiscountErr: Label 'Defines must be equal to ''Discount''';
        ItemDiscGroupMustNotBePurchaseErr: Label 'Product Type must not be Item Discount Group';
        LineSourceTypeErr: Label 'cannot be set to %1 if the header''s source type is %2.', Comment = '%1 and %2 - the source type value.';
        ParentSourceNoMustBeFilledErr: Label 'Assign-to Parent No. (custom) must have a value';
        CustomSourceNoMustBeFilledErr: Label 'Assign-to No. (custom) must have a value';
        CannotDeleteActivePriceListLineErr: Label 'You cannot delete the active price list line %1 %2.', Comment = '%1 - the price list code, %2 - line no';
        OutOfSyncNotificationMsg: Label 'We have detected that price list lines exists, which are out of sync. We have disabled the new lookups to prevent issues.';
        IsInitialized: Boolean;
        ResourceNoErr: Label 'Resource Group is not updated';
        JobPriceListFieldErr: Label 'Invalid %1', Comment = '%1 Price List Header Field Caption';
        AssignToNoErr: Label 'Invalid Assign-to No.';
        VATProdPostingGroupErr: Label 'VAT Product Posting Group are not equal.';
        AmountTypeNotAllowedForSourceTypeErr: Label '%1 is not allowed for %2.', Comment = '%1 - Price or Discount, %2 - Source Type';
        VariantCodeErr: Label 'Variant Code must be empty when new record is inserted.';

    [Test]
    [HandlerFunctions('ItemUOMModalHandler')]
    procedure T001_LookupItemUnitOfMeasure()
    var
        Item: Record Item;
        ItemUnitofMeasure: Record "Item Unit of Measure";
        PriceListLine: Record "Price List Line";
        MockPriceListLine: TestPage "Mock Price List Line";
    begin
        // [FEATURE] [Asset] [Item] [Unit Of Measure]
        Initialize();
        // [GIVEN] Item 'I', and one Item UoM 'X'
        LibraryInventory.CreateItem(Item);
        ItemUnitofMeasure.SetRange("Item No.", Item."No.");
        ItemUnitofMeasure.DeleteAll();
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitofMeasure, Item."No.", 134123);
        // [GIVEN] Price List Line, where "Asset Type" is Item, "Asset No."" is 'I'
        PriceListLine.Init();
        PriceListLine.Validate("Asset Type", "Price Asset Type"::Item);
        PriceListLine.Validate("Asset No.", Item."No.");
        PriceListLine.Insert();

        // [WHEN] Lookup Unit Of Measure in Line
        MockPriceListLine.Trap();
        Page.Run(Page::"Mock Price List Line", PriceListLine);
        MockPriceListLine."Unit of Measure Code".Lookup();

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
        PriceListLine: Record "Price List Line";
        MockPriceListLine: TestPage "Mock Price List Line";
    begin
        // [FEATURE] [Asset] [Item] [Variant]
        Initialize();
        // [GIVEN] Item 'I', and one Variant 'X'
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        // [GIVEN] Price List Line, where "Asset Type" is Item, "Asset No."" is 'I'
        PriceListLine.Init();
        PriceListLine.Validate("Asset Type", "Price Asset Type"::Item);
        PriceListLine.Validate("Asset No.", Item."No.");
        PriceListLine.Insert();

        // [WHEN] Lookup "Valiant Code" in Line
        MockPriceListLine.Trap();
        Page.Run(Page::"Mock Price List Line", PriceListLine);
        MockPriceListLine."Variant Code".Lookup();

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
        PriceListLine: Record "Price List Line";
        UnitofMeasure: Record "Unit of Measure";
        MockPriceListLine: TestPage "Mock Price List Line";
    begin
        // [FEATURE] [Asset] [Resource] [Unit Of Measure]
        Initialize();
        // [GIVEN] Resource 'R', and one UoM 'X'
        LibraryResource.CreateResource(Resource, '');
        ResourceUnitofMeasure.SetRange("Resource No.", Resource."No.");
        ResourceUnitofMeasure.DeleteAll();
        LibraryInventory.CreateUnitOfMeasureCode(UnitofMeasure);
        LibraryResource.CreateResourceUnitOfMeasure(ResourceUnitofMeasure, Resource."No.", UnitofMeasure.Code, 1);
        // [GIVEN] Price List Line, where "Asset Type" is Resource, "Asset No."" is 'R'
        PriceListLine.Init();
        PriceListLine.Validate("Asset Type", "Price Asset Type"::Resource);
        PriceListLine.Validate("Asset No.", Resource."No.");
        PriceListLine.Insert();

        // [WHEN] Lookup Unit Of Measure in Line
        MockPriceListLine.Trap();
        Page.Run(Page::"Mock Price List Line", PriceListLine);
        MockPriceListLine."Unit of Measure Code".Lookup();

        // [THEN] Page "Item Unit Of Measure" shows one record with 'X'
        Assert.AreEqual(ResourceUnitofMeasure.Code, LibraryVariableStorage.DequeueText(), 'UoM Code');
        Assert.AreEqual(
            ResourceUnitofMeasure."Qty. per Unit of Measure",
            LibraryVariableStorage.DequeueDecimal(), 'Qty. per Unit of Measure');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'Next line is found');
    end;

    [Test]
    procedure T004_SetNextLineNo()
    var
        PriceListLine: Record "Price List Line";
        LineNo: Integer;
    begin
        // [SCENARIO] SetNextLineNo() sets "Line No." by adding 10000 to the last line within the price list.
        Initialize();

        PriceListLine.DeleteAll();
        PriceListLine.SetNextLineNo();
        PriceListLine.TestField("Line No.", 10000);

        PriceListLine."Price List Code" := 'X';
        LineNo := LibraryRandom.RandInt(100000);
        PriceListLine."Line No." := LineNo;
        PriceListLine.Insert();

        PriceListLine."Line No." := 0;
        PriceListLine.SetNextLineNo();
        PriceListLine.TestField("Line No.", LineNo + 10000);
    end;

    [Test]
    procedure T005_ValidateNonexistingPriceListCode()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListCode: Code[20];
    begin
        Initialize();

        PriceListHeader.DeleteAll();
        PriceListCode := LibraryUtility.GenerateGUID();
        asserterror PriceListLine.Validate("Price List Code", PriceListCode);

        Assert.ExpectedError(StrSubstNo(WrongPriceListCodeErr, PriceListCode));
    end;

    [Test]
    procedure T006_ValidateExistingPriceListCode()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        Initialize();

        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Sale, "Price Source Type"::Customer, LibrarySales.CreateCustomerNo());
        PriceListLine.Validate("Price List Code", PriceListHeader.Code);

        PriceListLine.Testfield("Price List Code", PriceListHeader.Code);
    end;

    [Test]
    procedure T007_InsertLineForPriceListWithSourceTypeAll()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
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
        PriceListLine.Init();
        PriceListLine.Validate("Price List Code", PriceListHeader.Code);
        PriceListLine.Validate("Source Type", "Price Source Type"::Customer);
        CustomerNo := LibrarySales.CreateCustomerNo();
        PriceListLine.Validate("Source No.", CustomerNo);
        // [GIVEN] "Amount Type" is 'Price', "Price Type" is 'Sale'
        PriceListLine.Validate("Price Type", "Price Type"::Sale);
        PriceListLine.Validate("Amount Type", PriceListLine."Amount Type"::Price);
        // [WHEN] Insert the line
        PriceListLine.Insert(true);
        // [THEN] Header's fields are not copied, "Line No." is not 0,
        PriceListLine.TestField("Line No.");
        PriceListLine.TestField("Starting Date", 0D);

        // [WHEN] Validate "Asset Type"
        PriceListLine.Validate("Asset Type", "Price Asset Type"::Item);

        // [THEN] Line where,  "Source Type" is 'All', "Source No." is ''
        PriceListLine.TestField("Source Type", "Price Source Type"::All);
        PriceListLine.TestField("Source No.", '');
        // [GIVEN] "Amount Type" is 'Price', "Price Type" is 'Any'
        PriceListLine.TestField("Price Type", "Price Type"::Any);
        PriceListLine.TestField("Amount Type", PriceListLine."Amount Type"::Price);
        // [THEN] Other fields are copied from the header
        PriceListLine.TestField("Starting Date", PriceListHeader."Starting Date");
        PriceListLine.TestField("Ending Date", PriceListHeader."Ending Date");
        PriceListLine.TestField("Allow Invoice Disc.", PriceListHeader."Allow Invoice Disc.");
        PriceListLine.TestField("Allow Line Disc.", PriceListHeader."Allow Line Disc.");
        PriceListLine.TestField("Price Includes VAT", PriceListHeader."Price Includes VAT");
        PriceListLine.TestField("VAT Bus. Posting Gr. (Price)", PriceListHeader."VAT Bus. Posting Gr. (Price)");
    end;

    [Test]
    procedure T008_InsertLineForPriceListWithSourceTypeNotAll()
    var
        Item: Record Item;
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
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
        PriceListLine.Init();
        PriceListLine.Validate("Price List Code", PriceListHeader.Code);
        PriceListLine."Source Type" := "Price Source Type"::Customer;
        PriceListLine."Source No." := LibrarySales.CreateCustomerNo();
        // [GIVEN] "Amount Type" is 'Price', "Price Type" is 'Sale'
        PriceListLine."Price Type" := "Price Type"::Sale;
        PriceListLine."Amount Type" := PriceListLine."Amount Type"::Price;

        // [WHEN] Insert the line
        PriceListLine.Insert(true);
        // [THEN] Header's fields are not copied, "Line No." is not 0,
        PriceListLine.TestField("Line No.");
        PriceListLine.TestField("Price Type", "Price Type"::Sale);

        // [WHEN] Validate "Asset Type"
        PriceListLine.Validate("Asset Type", "Price Asset Type"::Item);

        // [THEN] Line inserted, all fields are copied from the header
        PriceListLine.TestField("Source Type", PriceListHeader."Source Type");
        PriceListLine.TestField("Source No.", PriceListHeader."Source No.");
        PriceListLine.TestField("Price Type", PriceListHeader."Price Type");
        PriceListLine.TestField("Starting Date", PriceListHeader."Starting Date");
        PriceListLine.TestField("Ending Date", PriceListHeader."Ending Date");
        PriceListLine.TestField("Allow Invoice Disc.", PriceListHeader."Allow Invoice Disc.");
        PriceListLine.TestField("Allow Line Disc.", PriceListHeader."Allow Line Disc.");
        PriceListLine.TestField("Price Includes VAT", PriceListHeader."Price Includes VAT");
        PriceListLine.TestField("VAT Bus. Posting Gr. (Price)", PriceListHeader."VAT Bus. Posting Gr. (Price)");

        // [GIVEN] Item 'I', where "Price Includes VAT" = false
        LibraryInventory.CreateItem(Item);
        Item.Validate("Price Includes VAT", not PriceListHeader."Price Includes VAT");
        Item.Modify();

        // [WHEN] Validate "Asset No." as 'I'
        PriceListLine.Validate("Asset No.", Item."No.");

        // [THEN] "Price Includes VAT" is equal to the header's value
        PriceListLine.TestField("Price Includes VAT", PriceListHeader."Price Includes VAT");
    end;

    [Test]
    procedure T009_AssetTypeAllAutoconvertedToItem()
    var
        PriceListLine: Record "Price List Line";
    begin
        // [WHEN] New price list line
        PriceListLine.Init();
        // [THEN] Default "Asset Type" is Item
        PriceListLine.TestField("Asset Type", "Price Asset Type"::Item);
        // [WHEN] Change "Asset Type" to '(All)'
        PriceListLine.Validate("Asset Type", "Price Asset Type"::" ");
        // [THEN] "Asset Type" is Item
        PriceListLine.Validate("Asset Type", "Price Asset Type"::Item);
    end;

    [Test]
    procedure T010_ValidateSourceNo()
    var
        Customer: Record Customer;
        MockPriceListLine: TestPage "Mock Price List Line";
    begin
        // [FEATURE] [Source]
        Initialize();
        // [GIVEN] Customer 'C', SystemID is 'X'
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] Price Line, where "Source Type" is 'Customer'
        MockPriceListLine.OpenEdit();
        MockPriceListLine."Source Type".SetValue("Price Source Type"::Customer);
        // [WHEN] Enter "Source No." set as 'C'
        MockPriceListLine."Source No.".SetValue(Customer."No.");
        // [THEN] "Source No." is 'C', "Source ID" is 'X'
        MockPriceListLine."Source No.".AssertEquals(Customer."No.");
        MockPriceListLine."Source ID".AssertEquals(Customer.SystemId);
    end;

    [Test]
    procedure T011_ReValidateSourceType()
    var
        Customer: Record Customer;
        MockPriceListLine: TestPage "Mock Price List Line";
    begin
        // [FEATURE] [Source]
        // [SCENARIO] Revalidated unchanged "Source Type" does blank the source
        Initialize();
        // [GIVEN] Customer 'C'
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] Price Line, where "Source Type" is 'Customer', "Source No." is 'C'
        MockPriceListLine.OpenEdit();
        MockPriceListLine."Source Type".SetValue("Price Source Type"::Customer);
        MockPriceListLine."Source No.".SetValue(Customer."No.");
        // [WHEN] "Source Type" set as 'Customer'
        MockPriceListLine."Source Type".SetValue("Price Source Type"::Customer);
        // [THEN] "Source Type" is 'Customer', "Source No." is <blank>
        MockPriceListLine."Source No.".AssertEquals('');
    end;

    [Test]
    procedure T012_ValidateParentSourceNo()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        MockPriceListLine: TestPage "Mock Price List Line";
    begin
        // [FEATURE] [Source]
        Initialize();
        // [GIVEN] Job Task 'JT', where Job is 'J'
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        // [GIVEN] Price Line, where "Source Type" is 'Job Task', "Parent Source No." is 'J'
        MockPriceListLine.OpenEdit();
        MockPriceListLine."Source Type".SetValue("Price Source Type"::"Job Task");
        MockPriceListLine."Parent Source No.".SetValue(JobTask."Job No.");
        // [WHEN] Enter "Source No." as 'JT'
        MockPriceListLine."Source No.".SetValue(JobTask."Job Task No.");
        // [THEN] "Source No." is 'JT',"Parent Source No." is 'J'
        MockPriceListLine."Source No.".AssertEquals(JobTask."Job Task No.");
        MockPriceListLine."Parent Source No.".AssertEquals(JobTask."Job No.");
    end;

    [Test]
    procedure T013_ValidateSourceID()
    var
        Customer: Record Customer;
        MockPriceListLine: TestPage "Mock Price List Line";
    begin
        // [FEATURE] [Source]
        Initialize();
        // [GIVEN] Customer 'C', where SystemID is 'X'
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] Price Line, where "Source Type" is 'Customer', "Source No." is 'C'
        MockPriceListLine.OpenEdit();
        MockPriceListLine."Source Type".SetValue("Price Source Type"::Customer);
        // [WHEN] "Source ID" set as 'X'
        MockPriceListLine."Source ID".SetValue(Customer.SystemId);
        // [THEN] "Source Type" is 'Customer', "Source No." is 'C'
        MockPriceListLine."Source Type".AssertEquals("Price Source Type"::Customer);
        MockPriceListLine."Source No.".AssertEquals(Customer."No.");
    end;

    [Test]
    [HandlerFunctions('LookupCustomerModalHandler')]
    procedure T014_LookupSourceNo()
    var
        Customer: Record Customer;
        MockPriceListLine: TestPage "Mock Price List Line";
    begin
        // [FEATURE] [Source]
        Initialize();
        // [GIVEN] Customer 'C', SystemID is 'X'
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] Price Line, where "Source Type" is 'Customer'
        MockPriceListLine.OpenEdit();
        MockPriceListLine."Source Type".SetValue("Price Source Type"::Customer);
        // [WHEN] Lookup "Source No." set as 'C'
        LibraryVariableStorage.Enqueue(Customer."No."); // for LookupCustomerModalHandler
        MockPriceListLine."Source No.".Lookup();

        // [THEN] "Source No." is 'C', "Source ID" is 'X'
        MockPriceListLine."Source No.".AssertEquals(Customer."No.");
        MockPriceListLine."Source ID".AssertEquals(Customer.SystemId);
    end;

    [Test]
    [HandlerFunctions('LookupJobModalHandler,LookupJobTaskModalHandler')]
    procedure T015_LookupParentSourceNo()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        MockPriceListLine: TestPage "Mock Price List Line";
    begin
        // [FEATURE] [Source]
        Initialize();
        // [GIVEN] Job Task 'JT', where Job is 'J'
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        // [GIVEN] Price Line, where "Source Type" is 'Job Task', "Parent Source No." is 'J'
        MockPriceListLine.OpenEdit();
        MockPriceListLine."Source Type".SetValue("Price Source Type"::"Job Task");
        // [WHEN] Lookup "Source No."
        LibraryVariableStorage.Enqueue(JobTask."Job No."); // for LookupJobModalHandler
        LibraryVariableStorage.Enqueue(JobTask."Job Task No."); // for LookupJobTaskModalHandler
        MockPriceListLine."Source No.".Lookup();

        // [THEN] "Source No." is 'JT',"Parent Source No." is 'J'
        MockPriceListLine."Parent Source No.".AssertEquals(JobTask."Job No.");
    end;

    [Test]
    [HandlerFunctions('LookupItemModalHandler')]
    procedure T016_LookupAssetNo()
    var
        Item: Record Item;
        MockPriceListLine: TestPage "Mock Price List Line";
    begin
        // [FEATURE] [Asset]
        Initialize();
        // [GIVEN] Item 'I'
        LibraryInventory.CreateItem(Item);
        // [GIVEN] Price Line, where "Asset Type" is 'Item'
        MockPriceListLine.OpenEdit();
        MockPriceListLine."Asset Type".SetValue("Price Asset Type"::Item);
        // [WHEN] Lookup "Asset No." set as 'I'
        LibraryVariableStorage.Enqueue(Item."No."); // for LookupItemModalHandler
        MockPriceListLine."Asset No.".Lookup();

        // [THEN] "Asset No." is 'I'
        MockPriceListLine."Asset No.".AssertEquals(Item."No.");
    end;

    [Test]
    procedure T017_SourceTypeInLineMustBeTheSameIfSourceNoDefined()
    var
        Job: Record Job;
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        Initialize();
        // [GIVEN] Price List Header, where all fields are filled, "Source Type" = 'Job', "Source No." is 'J'
        LibraryJob.CreateJob(Job);
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Purchase, "Price Source Type"::Job, Job."No.");
        // [GIVEN] One line added
        PriceListLine.Init();
        PriceListLine."Price List Code" := PriceListHeader.Code;
        PriceListLine.Insert(true);

        // [WHEN] set "Source Type" as 'Job Task' in the line
        asserterror PriceListLine.Validate("Source Type", "Price Source Type"::"Job Task");
        // [THEN] Error message: "Source Type must be equal to Job"
        Assert.ExpectedTestFieldError(PriceListLine.FieldCaption("Source Type"), Format(PriceListLine."Source Type"::Job));
    end;

    [Test]
    procedure T018_SourceTypeInLineMustBeLowerHeadersSourceType()
    var
        Job: Record Job;
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
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
        PriceListLine.Init();
        PriceListLine."Price List Code" := PriceListHeader.Code;
        PriceListLine.Insert(true);

        // [WHEN] set "Source Type" as 'All Jobs' in the line
        asserterror PriceListLine.Validate("Source Type", "Price Source Type"::"All Jobs");
        // [THEN] Error message: "Cannot set All Jobs if header's source type is Job"
        Assert.ExpectedError(
            StrSubstNo(LineSourceTypeErr, "Price Source Type"::"All Jobs", "Price Source Type"::Job));
    end;

    [Test]
    procedure T019_SourceTypeInLineMustBeInTheHeadersSourceGroup()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        Initialize();
        // [GIVEN] Price List Header, where all fields are filled, "Source Type" = 'All Custromers'
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        // [GIVEN] One line added
        PriceListLine.Init();
        PriceListLine."Price List Code" := PriceListHeader.Code;
        PriceListLine.Insert(true);

        // [WHEN] set "Source Type" as 'Vendor' in the line
        asserterror PriceListLine.Validate("Source Type", "Price Source Type"::Vendor);
        // [THEN] Error message: "Cannot set Vendor if header's source type is All Customers"
        Assert.ExpectedError(
            StrSubstNo(LineSourceTypeErr, "Price Source Type"::Vendor, "Price Source Type"::"All Customers"));
    end;

    [Test]
    procedure T020_InsertNewLineDoesNotControlConsistency()
    var
        TempPriceListLine: Record "Price List Line" temporary;
        LineNo: Integer;
    begin
        // [SCENARIO] OnInsert() does not control data consistency, does not increments "Line No." for the temp record.
        Initialize();
        // [GIVEN] Price List Line, where "Source Type" is 'Customer', "Asset Type" is 'Item', but "Source No." and "Asset No." are blank, 
        LineNo := LibraryRandom.RandInt(100);
        TempPriceListLine."Line No." := LineNo;
        TempPriceListLine.Validate("Source Type", "Price Source Type"::Customer);
        TempPriceListLine.Validate("Asset Type", "Price Asset Type"::Item);
        // [WHEN] Insert temporary line 
        TempPriceListLine.Insert(true);
        // [THEN] "Line No." is not changed
        TempPriceListLine.TestField("Line No.", LineNo);
    end;

    [Test]
    procedure T021_UnitPriceBlanksCostFactor()
    var
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] "Unit Price" validation with a non-zero value blanks "Cost Factor".
        Initialize();
        PriceListLine."Source Type" := "Price Source Type"::"All Customers";
        PriceListLine."Asset Type" := "Price Asset Type"::"G/L Account";
        PriceListLine."Asset No." := LibraryERM.CreateGLAccountNo();

        PriceListLine."Cost Factor" := 1.2;
        PriceListLine.Validate("Unit Price", 0);
        PriceListLine.TestField("Cost Factor", 1.2);

        PriceListLine.Validate("Unit Price", 10);
        PriceListLine.TestField("Cost Factor", 0);
        PriceListLine.TestField("Unit Price", 10);
    end;

    [Test]
    procedure T022_CostFactorBlanksUnitPrice()
    var
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] "Cost Factor" validation with a non-zero value blanks "Unit Price".
        Initialize();
        PriceListLine.Validate("Source Type", "Price Source Type"::"All Jobs");
        PriceListLine."Asset Type" := "Price Asset Type"::"G/L Account";
        PriceListLine."Asset No." := LibraryERM.CreateGLAccountNo();

        PriceListLine."Unit Price" := 10.15;
        PriceListLine.Validate("Cost Factor", 0);
        PriceListLine.TestField("Unit Price", 10.15);

        PriceListLine.Validate("Cost Factor", 0.98);
        PriceListLine.TestField("Unit Price", 0);
        PriceListLine.TestField("Cost Factor", 0.98);
    end;

    [Test]
    procedure T023_UnitPriceCostFactorNotAllowedForDiscountLine()
    var
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] "Unit Price" validation fails in Discount line
        Initialize();
        PriceListLine."Amount Type" := PriceListLine."Amount Type"::Discount;
        asserterror PriceListLine.Validate("Unit Price", 1);
        Assert.ExpectedError(
            StrSubstNo(
                FieldNotAllowedForAmountTypeErr, PriceListLine.FieldCaption("Unit Price"),
                PriceListLine.FieldCaption("Amount Type"), PriceListLine."Amount Type"::Discount));

        asserterror PriceListLine.Validate("Cost Factor", 1);
        Assert.ExpectedError(
            StrSubstNo(
                FieldNotAllowedForAmountTypeErr, PriceListLine.FieldCaption("Cost Factor"),
                PriceListLine.FieldCaption("Amount Type"), PriceListLine."Amount Type"::Discount));
    end;

    [Test]
    procedure T024_UnitCostDirectUnitCostNotAllowedForDiscountLine()
    var
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] "Cost Factor" validation fails in Discount line
        Initialize();
        PriceListLine.Validate("Source Type", "Price Source Type"::"Customer Disc. Group");
        asserterror PriceListLine.Validate("Unit Cost", 1);
        Assert.ExpectedError(
            StrSubstNo(
                FieldNotAllowedForAmountTypeErr, PriceListLine.FieldCaption("Unit Cost"),
                PriceListLine.FieldCaption("Amount Type"), PriceListLine."Amount Type"::Discount));

        asserterror PriceListLine.Validate("Direct Unit Cost", 1);
        Assert.ExpectedError(
            StrSubstNo(
                FieldNotAllowedForAmountTypeErr, PriceListLine.FieldCaption("Direct Unit Cost"),
                PriceListLine.FieldCaption("Amount Type"), PriceListLine."Amount Type"::Discount));
    end;

    [Test]
    procedure T025_AllowLineDiscNotAllowedForDiscountLine()
    var
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] "Allow Line Disc." validation fails in Discount line
        Initialize();
        PriceListLine."Amount Type" := PriceListLine."Amount Type"::Discount;
        asserterror PriceListLine.Validate("Allow Line Disc.", true);
        Assert.ExpectedError(
            StrSubstNo(
                FieldNotAllowedForAmountTypeErr, PriceListLine.FieldCaption("Allow Line Disc."),
                PriceListLine.FieldCaption("Amount Type"), PriceListLine."Amount Type"::Discount));
    end;

    [Test]
    procedure T026_AllowInvDiscNotAllowedForDiscountLine()
    var
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] "Allow Invoice Disc." validation fails in Discount line
        Initialize();
        PriceListLine."Amount Type" := PriceListLine."Amount Type"::Discount;
        asserterror PriceListLine.Validate("Allow Invoice Disc.", true);
        Assert.ExpectedError(
            StrSubstNo(
                FieldNotAllowedForAmountTypeErr, PriceListLine.FieldCaption("Allow Invoice Disc."),
                PriceListLine.FieldCaption("Amount Type"), PriceListLine."Amount Type"::Discount));
    end;

    [Test]
    procedure T027_LineDiscPctNotAllowedForPriceLine()
    var
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] "Line Discount %" validation fails in Price line for "Customer Price Group"
        Initialize();
        PriceListLine.Validate("Source Type", "Price Source Type"::"Customer Price Group");
        asserterror PriceListLine.Validate("Line Discount %", 3);
        Assert.ExpectedError(
            StrSubstNo(
                FieldNotAllowedForAmountTypeErr, PriceListLine.FieldCaption("Line Discount %"),
                PriceListLine.FieldCaption("Amount Type"), PriceListLine."Amount Type"::Price));
    end;

    [Test]
    procedure T028_DefaultAmountTypeOnSourceTypeValidation()
    var
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] Default "Amount Type" depends on source type. 
        Initialize();
        PriceListLine.DeleteAll();
        // [WHEN] Set "Source Type" as "Customer Disc. Group" in Price list header
        PriceListLine.Validate("Source Type", "Price Source Type"::"Customer Price Group");
        // [THEN] "Amount Type" is 'Price'
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Price);

        // [WHEN] Set "Source Type" as "Customer Disc. Group" in Price list header
        PriceListLine.Validate("Source Type", "Price Source Type"::"Customer Disc. Group");
        // [THEN] "Amount Type" is 'Discount'
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Discount);

        // [WHEN] Set "Source Type" as "Customer" in Price list header
        PriceListLine.Validate("Source Type", "Price Source Type"::Customer);
        // [THEN] "Amount Type" is 'Price'
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Any);
    end;

    [Test]
    procedure T029_ValidateAmountType()
    var
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] Cannot change "Amount Type" for source types "Customer Disc. Group", "Customer Price Group"
        Initialize();
        PriceListLine.Init();
        // [WHEN] Set "Source Type" as "Customer Disc. Group" in Price list header
        PriceListLine."Source Type" := "Price Source Type"::"Customer Disc. Group";
        // [THEN] Can change "Amount Type" to 'Discount'
        PriceListLine.Validate("Amount Type", "Price Amount Type"::Discount);
        // [THEN] Cannot change "Amount Type" to 'Price' or 'Any'
        asserterror PriceListLine.Validate("Amount Type", "Price Amount Type"::Price);
        asserterror PriceListLine.Validate("Amount Type", "Price Amount Type"::Any);

        PriceListLine.Init();
        // [WHEN] Set "Source Type" as "Customer Disc. Group" in Price list header
        PriceListLine."Source Type" := "Price Source Type"::"Customer Price Group";
        // [THEN] Can change "Amount Type" to 'Price'
        PriceListLine.Validate("Amount Type", "Price Amount Type"::Price);
        // [THEN] Cannot change "Amount Type" to 'Discount' or 'Any'
        asserterror PriceListLine.Validate("Amount Type", "Price Amount Type"::Discount);
        asserterror PriceListLine.Validate("Amount Type", "Price Amount Type"::Any);

        PriceListLine.Init();
        // [WHEN] Set "Source Type" as "Customer" in Price list header
        PriceListLine."Source Type" := "Price Source Type"::Customer;
        // [THEN] Can change "Amount Type" to 'Any', 'Discount', or 'Price'
        PriceListLine.Validate("Amount Type", "Price Amount Type"::Price);
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Price);
        PriceListLine.Validate("Amount Type", "Price Amount Type"::Any);
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Any);
        PriceListLine.Validate("Amount Type", "Price Amount Type"::Discount);
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Discount);
    end;

    [Test]
    procedure T030_WorkTypeCodeNotAllowedForItem()
    var
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Work Type] [Item]
        // [SCENARIO] "Work Type Code" must not be filled for product type 'Item'
        Initialize();
        // [GIVEN] Price List Line, where "Asset Type" is 'Item' 
        PriceListLine.Validate("Asset Type", "Price Asset Type"::Item);
        // [WHEN] Validate "Work Type Code" with a valid code
        asserterror PriceListLine.Validate("Work Type Code", GetWorkTypeCode());
        // [THEN] Error message: 'Asset Type must be Resource'
        Assert.ExpectedTestFieldError(PriceListLine.FieldCaption("Asset Type"), Format(PriceListLine."Asset Type"::Resource));
    end;

    [Test]
    procedure T031_WorkTypeCodeAllowedForResource()
    var
        PriceListLine: Record "Price List Line";
        Resource: Record Resource;
        WorkType: Record "Work Type";
    begin
        // [FEATURE] [Work Type] [Resource]
        // [SCENARIO] "Work Type Code" can be filled for product type 'Resource'
        Initialize();
        // [GIVEN] Price List Line, where "Asset Type" is 'Resource', "Asset No." is 'R'
        PriceListLine.Validate("Asset Type", "Price Asset Type"::Resource);
        LibraryResource.CreateResource(Resource, '');
        PriceListLine.Validate("Asset No.", Resource."No.");
        // [GIVEN] Work Group 'WT', where "Unit of Measure Code" is <blank>
        WorkType.Get(GetWorkTypeCode());
        WorkType."Unit of Measure Code" := '';
        WorkType.Modify();

        // [WHEN] Validate "Work Type Code" with a valid code 'WT'
        PriceListLine.Validate("Work Type Code", WorkType.Code);

        // [THEN] 'Work Type Code' is 'WT', "Unit of Measure Code" is 'R-UOM'
        PriceListLine.TestField("Work Type Code", WorkType.Code);
        PriceListLine.TestField("Unit of Measure Code", Resource."Base Unit of Measure");
    end;

    [Test]
    procedure T032_WorkTypeCodeAllowedForResourceGroup()
    var
        PriceListLine: Record "Price List Line";
        ResourceGroup: Record "Resource Group";
        UnitofMeasure: Record "Unit of Measure";
        WorkType: Record "Work Type";
    begin
        // [FEATURE] [Work Type] [Resource Group]
        // [SCENARIO] "Work Type Code" can be filled for product type 'Resource Group'
        Initialize();
        // [GIVEN] Price List Line, where "Asset Type" is 'Resource', "Asset No." is 'R'
        PriceListLine.Validate("Asset Type", "Price Asset Type"::"Resource Group");
        LibraryResource.CreateResourceGroup(ResourceGroup);
        PriceListLine.Validate("Asset No.", ResourceGroup."No.");
        // [GIVEN] Work Group 'WT', where "Unit of Measure Code" is 'X'
        WorkType.Get(GetWorkTypeCode());
        LibraryInventory.CreateUnitOfMeasureCode(UnitofMeasure);
        WorkType."Unit of Measure Code" := UnitofMeasure.Code;
        WorkType.Modify();

        // [WHEN] Validate "Work Type Code" with a valid code 'WT'
        PriceListLine.Validate("Work Type Code", WorkType.Code);

        // [THEN] 'Work Type Code' is 'WT', "Unit of Measure Code" is 'X'
        PriceListLine.TestField("Work Type Code", WorkType.Code);
        PriceListLine.TestField("Unit of Measure Code", WorkType."Unit of Measure Code");
    end;

    [Test]
    procedure T033_UnitOfMeasureAllowedForResourceGroup()
    var
        PriceListLine: Record "Price List Line";
        ResourceGroup: Record "Resource Group";
        UnitofMeasure: Record "Unit of Measure";
    begin
        // [FEATURE] [Resource Group] [Unit of Measure]
        // [SCENARIO] "Unit of Measure Code" can be filled for product type 'Resource Group'
        Initialize();
        // [GIVEN] Price List Line, where "Asset Type" is 'Resource', "Asset No." is 'R'
        PriceListLine.Validate("Asset Type", "Price Asset Type"::"Resource Group");
        LibraryResource.CreateResourceGroup(ResourceGroup);
        PriceListLine.Validate("Asset No.", ResourceGroup."No.");

        // [WHEN] Validate "Unit of Measure Code" with a valid code 'UOM'
        LibraryInventory.CreateUnitOfMeasureCode(UnitofMeasure);
        PriceListLine.Validate("Unit of Measure Code", UnitofMeasure.Code);

        // [THEN] "Unit of Measure Code" is 'UOM'
        PriceListLine.Validate("Unit of Measure Code", UnitofMeasure.Code);
    end;

    [Test]
    procedure T034_UnitOfMeasureAllowedForResource()
    var
        PriceListLine: Record "Price List Line";
        Resource: Record Resource;
        ResourceUnitofMeasure: Record "Resource Unit of Measure";
        UnitofMeasure: Record "Unit of Measure";
    begin
        // [FEATURE] [Resource] [Unit of Measure]
        // [SCENARIO] "Unit of Measure Code" can be filled for product type 'Resource'
        Initialize();
        // [GIVEN] Price List Line, where "Asset Type" is 'Resource', "Asset No." is 'R'
        PriceListLine.Validate("Asset Type", "Price Asset Type"::Resource);
        LibraryResource.CreateResource(Resource, '');
        PriceListLine.Validate("Asset No.", Resource."No.");

        // [WHEN] Validate "Unit of Measure Code" with a valid code 'UOM'
        LibraryInventory.CreateUnitOfMeasureCode(UnitofMeasure);
        LibraryResource.CreateResourceUnitOfMeasure(
            ResourceUnitofMeasure, Resource."No.", UnitofMeasure.Code, 1);
        PriceListLine.Validate("Unit of Measure Code", UnitofMeasure.Code);

        // [THEN] "Unit of Measure Code" is 'UOM'
        PriceListLine.Validate("Unit of Measure Code", UnitofMeasure.Code);
    end;

    [Test]
    procedure T035_VariantCodeAllowedForItem()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] "Variant Code" can be filled for product type 'Item'
        Initialize();
        // [GIVEN] Price List Line, where "Asset Type" is 'Item', "Asset No." is 'I' 
        PriceListLine.Validate("Asset Type", "Price Asset Type"::Item);
        LibraryInventory.CreateItem(Item);
        PriceListLine.Validate("Asset No.", Item."No.");
        // [WHEN] Validate "Variant Code" with a valid code 'V'
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        PriceListLine.Validate("Variant Code", ItemVariant.Code);
        // [THEN] "Variant Code" is 'V'
        PriceListLine.TestField("Variant Code", ItemVariant.Code);
    end;

    [Test]
    procedure T036_VariantCodeNoAllowedForBlankItem()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] "Variant Code" cannot be filled for product type 'Item', but blank "Asset No."
        Initialize();
        // [GIVEN] Price List Line, where "Asset Type" is 'Item', "Asset No." is <blank> 
        PriceListLine.Validate("Asset Type", "Price Asset Type"::Item);
        PriceListLine.Validate("Asset No.", '');
        // [WHEN] Validate "Variant Code" with a valid code 'V'
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        asserterror PriceListLine.Validate("Variant Code", ItemVariant.Code);
        // [THEN] Error message: 'Asset No. must have a value.'
        Assert.ExpectedError(AssetNoMustHaveValueErr);
    end;

    [Test]
    procedure T037_ValidateUnitPriceWithBlankAssetType()
    var
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] "Unit Price" cannot be filled if "Asset Type" is blank.
        Initialize();
        // [GIVEN] Price List Line, where "Asset Type" is 'All', "Asset No." is <blank> 
        PriceListLine.Validate("Price Type", "Price Type"::Sale);
        PriceListLine."Asset Type" := "Price Asset Type"::" ";
        // [WHEN] Validate "Unit Price" as 1
        asserterror PriceListLine.Validate("Unit Price", 1);
        // [THEN] Error message: 'Asset Type must not be (All).'
        Assert.ExpectedError(AssetTypeMustNotBeAllErr);
    end;

    [Test]
    procedure T038_ValidateDirectUnitCostWithBlankAssetType()
    var
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] "Unit Price" cannot be filled if "Asset Type" is blank.
        Initialize();
        // [GIVEN] Price List Line, where "Asset Type" is 'All', "Asset No." is <blank> 
        PriceListLine.Validate("Price Type", "Price Type"::Purchase);
        PriceListLine."Asset Type" := "Price Asset Type"::" ";
        // [WHEN] Validate "Direct Unit Cost" as 1
        asserterror PriceListLine.Validate("Direct Unit Cost", 1);
        // [THEN] Error message: 'Asset Type must not be (All).'
        Assert.ExpectedError(AssetTypeMustNotBeAllErr);
    end;

    [Test]
    procedure T039_ValidateLineDiscountPctWithBlankAssetType()
    var
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] "Line Discount %" cannot be filled if "Asset Type" is blank.
        Initialize();
        // [GIVEN] Price List Line, where "Asset Type" is 'All', "Asset No." is <blank> 
        PriceListLine.Validate("Price Type", "Price Type"::Sale);
        PriceListLine."Asset Type" := "Price Asset Type"::" ";
        // [WHEN] Validate "Line Discount %" as 1
        asserterror PriceListLine.Validate("Line Discount %", 1);
        // [THEN] Error message: 'Asset Type must not be (All).'
        Assert.ExpectedError(AssetTypeMustNotBeAllErr);
    end;

    [Test]
    procedure T040_AmountTypePriceFromDiscount()
    var
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] "Amount Type" set to Price, blanks "Line Discount %" and sets "Allows .. Disc" from header
        Initialize();
        PriceListLine."Amount Type" := PriceListLine."Amount Type"::Discount;
        PriceListLine."Line Discount %" := 13.3;
        PriceListLine."Unit Price" := 0;
        PriceListLine."Cost Factor" := 0;
        PriceListLine."Allow Invoice Disc." := false;
        PriceListLine."Allow Line Disc." := false;

        PriceListLine.Validate("Amount Type", PriceListLine."Amount Type"::Price);

        PriceListLine.TestField("Line Discount %", 0);
        PriceListLine.TestField("Unit Price", 0);
        PriceListLine.TestField("Cost Factor", 0);
        PriceListLine.TestField("Allow Invoice Disc.", false);
        PriceListLine.TestField("Allow Line Disc.", false);
    end;

    [Test]
    procedure T041_AmountTypePriceWithHeader()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] "Amount Type" set to Price, "Allows .. Disc" are set from header
        Initialize();
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        PriceListHeader."Allow Invoice Disc." := true;
        PriceListHeader."Allow Line Disc." := true;
        PriceListHeader.Modify();

        PriceListLine.Init();
        PriceListLine."Price List Code" := PriceListHeader.Code;
        PriceListLine."Amount Type" := PriceListLine."Amount Type"::Discount;
        PriceListLine."Line Discount %" := 13.3;
        PriceListLine."Unit Price" := 0;
        PriceListLine."Cost Factor" := 0;
        PriceListLine."Allow Invoice Disc." := false;
        PriceListLine."Allow Line Disc." := false;

        PriceListLine.Validate("Amount Type", PriceListLine."Amount Type"::Price);

        PriceListLine.TestField("Line Discount %", 0);
        PriceListLine.TestField("Unit Price", 0);
        PriceListLine.TestField("Cost Factor", 0);
        PriceListLine.TestField("Allow Invoice Disc.", true);
        PriceListLine.TestField("Allow Line Disc.", true);
    end;

    [Test]
    procedure T042_AmountTypeDiscountFromPrice()
    var
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] "Amount Type" set to Discount, blanks "Unit Price" and "Allows .. Disc" fields.
        Initialize();
        PriceListLine."Amount Type" := PriceListLine."Amount Type"::Price;
        PriceListLine."Line Discount %" := 0;
        PriceListLine."Unit Price" := 10;
        PriceListLine."Cost Factor" := 0.5;
        PriceListLine."Allow Invoice Disc." := true;
        PriceListLine."Allow Line Disc." := true;

        PriceListLine.Validate("Amount Type", PriceListLine."Amount Type"::Discount);

        PriceListLine.TestField("Line Discount %", 0);
        PriceListLine.TestField("Unit Price", 0);
        PriceListLine.TestField("Cost Factor", 0);
        PriceListLine.TestField("Allow Invoice Disc.", false);
        PriceListLine.TestField("Allow Line Disc.", false);
    end;

    [Test]
    procedure T043_AmountTypeMustBeDiscountForItemDiscGroup()
    var
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] "Amount Type" must be Discount for 'Item Discounnt Group'
        Initialize();

        PriceListLine.Validate("Asset Type", "Price Asset Type"::"Item Discount Group");
        PriceListLine.TestField("Amount Type", PriceListLine."Amount Type"::Discount);

        asserterror PriceListLine.Validate("Amount Type", PriceListLine."Amount Type"::Price);
        Assert.ExpectedError(AmountTypeMustBeDiscountErr);

        asserterror PriceListLine.Validate("Amount Type", PriceListLine."Amount Type"::Any);
        Assert.ExpectedTestFieldError(PriceListLine.FieldCaption("Amount Type"), Format(PriceListLine."Amount Type"::Discount));
    end;

    [Test]
    procedure T045_AssetTypeItemDiscGroupNotAllowedForPurchase()
    var
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Purchase] [Item Discount Group]
        // [SCENARIO] Product Type 'Item Discount Group' is not allowed for 'Purchase'
        Initialize();

        PriceListLine."Price Type" := "Price Type"::Purchase;
        asserterror PriceListLine.Validate("Asset Type", "Price Asset Type"::"Item Discount Group");
        Assert.ExpectedError(ItemDiscGroupMustNotBePurchaseErr);
    end;

    [Test]
    procedure T050_IsEditable()
    var
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] Price List Line should be editable only if Status is 'Draft'.
        Initialize();

        PriceListLine.Status := PriceListLine.Status::Draft;
        Assert.IsTrue(PriceListLine.IsEditable(), 'Draft');

        PriceListLine.Status := PriceListLine.Status::Active;
        Assert.IsFalse(PriceListLine.IsEditable(), 'Active');

        PriceListLine.Status := PriceListLine.Status::Inactive;
        Assert.IsFalse(PriceListLine.IsEditable(), 'Inactive')
    end;

    [Test]
    procedure T051_ActiveIsEditableIfEditingAllowed()
    var
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Allow Editing Active Price]
        // [SCENARIO] Price List Line should be editable only if Status is 'Draft' or 'Active' and "Allow Editing Active Price" is on.
        Initialize();
        // [GIVEN] Allow Editing Active Purchase Price
        LibraryPriceCalculation.AllowEditingActivePurchPrice();

        PriceListLine."Price Type" := "Price Type"::Purchase;
        PriceListLine.Status := PriceListLine.Status::Draft;
        Assert.IsTrue(PriceListLine.IsEditable(), 'Draft');

        PriceListLine.Status := PriceListLine.Status::Active;
        Assert.IsTrue(PriceListLine.IsEditable(), 'Active');

        PriceListLine.Status := PriceListLine.Status::Inactive;
        Assert.IsFalse(PriceListLine.IsEditable(), 'Inactive')
    end;

    [Test]
    procedure T055_CannotDeleteActiveLine()
    var
        PriceListLine: Record "Price List Line";
    begin
        Initialize();
        // [GIVEN] Price line, where Status is Draft
        PriceListLine."Price List Code" := LibraryUtility.GenerateGUID();
        PriceListLine.Status := PriceListLine.Status::Draft;
        PriceListLine."Line No." := 0;
        PriceListLine.Insert();

        // [WHEN] Delete line with status Draft
        // [THEN] line is deleted
        Assert.IsTrue(PriceListLine.Delete(true), 'Draft line not deleted');

        // [GIVEN] Price line, where Status is Inactive
        PriceListLine.Status := PriceListLine.Status::Inactive;
        PriceListLine."Line No." := 0;
        PriceListLine.Insert();
        // [WHEN] Delete line with status Inactive
        // [THEN] line is deleted
        Assert.IsTrue(PriceListLine.Delete(true), 'Inactive line not deleted');

        // [GIVEN] Price line, where Status is Active
        PriceListLine.Status := PriceListLine.Status::Active;
        PriceListLine."Line No." := 0;
        PriceListLine.Insert();

        // [WHEN] Delete line with status Active
        asserterror PriceListLine.Delete(true);
        // [THEN] Error message: 'Cannot delete active line...'
        Assert.ExpectedError(StrSubstNo(CannotDeleteActivePriceListLineErr, PriceListLine."Price List Code", PriceListLine."Line No."));
    end;

    [Test]
    procedure T056_CanDeleteActiveLineIfEditingAllowed()
    var
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Allow Editing Active Price]
        Initialize();
        // [GIVEN] Allow Editing Active Sales Price
        LibraryPriceCalculation.AllowEditingActiveSalesPrice();
        // [GIVEN] Price line, where Status is Active
        PriceListLine."Price List Code" := LibraryUtility.GenerateGUID();
        PriceListLine."Price Type" := "Price Type"::Sale;
        PriceListLine.Status := PriceListLine.Status::Active;
        PriceListLine."Line No." := 0;
        PriceListLine.Insert();

        // [WHEN] Delete line with status Active
        PriceListLine.Delete(true);
        // [THEN] Line is deleted
        Assert.IsFalse(PriceListLine.Find(), 'must be deleted');
    end;

    [Test]
    procedure T060_CopyCustomerHeaderToAllCustomersLine()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
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

        // [WHEN] Copy Header to Line
        PriceListLine.CopyFrom(PriceListHeader);

        // [THEN] Line, where "Price Source Type" is "Customer" 'X', Status is 'Draft'
        PriceListLine.TestField("Source Type", PriceListHeader."Source Type");
        PriceListLine.TestField("Source No.", PriceListHeader."Source No.");
        PriceListLine.TestField(Status, "Price Status"::Draft);
    end;

    [Test]
    procedure T061_CopyAllVendorsHeaderToCustomerLine()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        Initialize();

        // [GIVEN] Header, where "Price Source Type" is "All Vendors"
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Purchase, "Price Source Type"::"All Vendors", '');

        // [GIVEN] Line, where "Price Source Type" is "Customer" 'X'
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, '', "Price Source Type"::Customer, LibrarySales.CreateCustomerNo(),
            "Price Asset Type"::Item, LibraryInventory.CreateItemNo());

        // [WHEN] Copy Header to Line
        PriceListLine.CopyFrom(PriceListHeader);

        // [THEN] Line, where "Price Source Type" is "All Vendors", "Price Type" is 'Purchase'
        PriceListLine.TestField("Price Type", PriceListHeader."Price Type");
        PriceListLine.TestField("Source Type", PriceListHeader."Source Type");
        PriceListLine.TestField("Source No.", PriceListHeader."Source No.");
    end;

    [Test]
    procedure T062_CopyPriceHeaderToDiscountLine()
    var
        ItemDiscountGroup: Record "Item Discount Group";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
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

        // [WHEN] Copy Header to Line
        PriceListLine.CopyFrom(PriceListHeader);

        // [THEN] Line, where "Amount Type" is 'Price', "Line Discount %" is 0.
        PriceListLine.TestField("Price Type", PriceListHeader."Price Type");
        PriceListLine.TestField("Amount Type", PriceListHeader."Amount Type");
        PriceListLine.TestField("Line Discount %", 0);
    end;

    [Test]
    procedure T063_CopyPriceHeaderToItemDiscGroupLine()
    var
        ItemDiscountGroup: Record "Item Discount Group";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
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

        // [WHEN] Copy Header to Line
        asserterror PriceListLine.CopyFrom(PriceListHeader);

        // [THEN] Error: 'Defines must be equal to 'Discount''
        Assert.ExpectedTestFieldError(PriceListHeader.FieldCaption("Amount Type"), Format(PriceListLine."Amount Type"::Discount));
    end;

    [Test]
    procedure T064_CopyDiscountHeaderToPriceLine()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
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

        // [WHEN] Copy Header to Line
        PriceListLine.CopyFrom(PriceListHeader);

        // [THEN] Line, where "Amount Type" is 'Discount', "Unit Price" is 0.
        PriceListLine.TestField("Price Type", PriceListHeader."Price Type");
        PriceListLine.TestField("Amount Type", PriceListHeader."Amount Type");
        PriceListLine.TestField("Unit Price", 0);
    end;

    [Test]
    procedure T070_VerifySourceForSourceAllLocationsSourceFilled()
    var
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Price Source Type] [Extended]
        // [SCENARIO] Verify source in the line fails on inconsistent source: Assign-to is filled.
        Initialize();
        // [GIVEN] New Price List Line, where "Source Type"::"All Locations", "Source No." is 'X'
        PriceListLine."Source Type" := "Price Source Type"::Test_All_Locations;
        PriceListLine."Source No." := 'X';

        // [WHEN] Verify source
        asserterror PriceListLine.Verify();

        // [THEN] Error: "Assign-to No. (custom) must be equal to ''''"
        Assert.ExpectedTestFieldError(PriceListLine.FieldCaption("Source No."), '''');
    end;

    [Test]
    procedure T071_VerifySourceForSourceLocationSourceBlank()
    var
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Price Source Type] [Extended]
        // [SCENARIO] Verify source in the line fails on inconsistent source: Assign-to is blank.
        Initialize();
        // [GIVEN] New Price List Line, where "Source Type"::"Location", "Parent Source No." is 'X', "Source No." is <blank>
        PriceListLine."Source Type" := "Price Source Type"::Test_Location;
        PriceListLine."Parent Source No." := 'X';
        PriceListLine."Source No." := '';

        // [WHEN] Verify source
        asserterror PriceListLine.Verify();

        // [THEN] Error: "Assign-to No. (custom) must have a value"
        Assert.ExpectedError(CustomSourceNoMustBeFilledErr);
    end;

    [Test]
    procedure T072_VerifySourceForSourceAllLocationsParentSourceFilled()
    var
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Price Source Type] [Extended]
        // [SCENARIO] Verify source in the line fails on inconsistent source: Assign-to Parent No. is filled.
        Initialize();
        // [GIVEN] New Price List Line, where "Source Type"::"All Locations", "Parent Source No." is 'X'
        PriceListLine."Source Type" := "Price Source Type"::Test_All_Locations;
        PriceListLine."Parent Source No." := 'X';

        // [WHEN] Verify source
        asserterror PriceListLine.Verify();

        // [THEN] Error: "Assign-to Parent No. (custom) must be equal to ''''"
        Assert.ExpectedTestFieldError(PriceListLine.FieldCaption("Parent Source No."), '''');
    end;

    [Test]
    procedure T073_VerifySourceForSourceLocationParentSourceBlank()
    var
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Price Source Type] [Extended]
        // [SCENARIO] Verify source in the line fails on inconsistent source: Assign-to Parent No. is blank.
        Initialize();
        // [GIVEN] New Price List Line, where "Source Type"::"Location", "Parent Source No." is <blank>
        PriceListLine."Source Type" := "Price Source Type"::Test_Location;
        PriceListLine."Parent Source No." := '';

        // [WHEN] Verify source
        asserterror PriceListLine.Verify();

        // [THEN] Error: "Assign-to Parent No. (custom) must have a value"
        Assert.ExpectedError(ParentSourceNoMustBeFilledErr);
    end;

    [Test]
    procedure T080_SourcePriceIncludesVATKeepsHeadersValueIfNotAllowedUpdatingDefaults()
    var
        Customer: Record Customer;
        Item: Record Item;
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
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
        PriceListLine.Init();
        PriceListLine.Validate("Price List Code", PriceListHeader.Code);
        // [WHEN] Line is inserted
        PriceListLine.Insert(true);

        // [THEN] Line, where "Price Includes VAT" is false
        PriceListLine.TestField("Price Includes VAT", PriceListHeader."Price Includes VAT");
        PriceListLine.TestField("VAT Bus. Posting Gr. (Price)", PriceListHeader."VAT Bus. Posting Gr. (Price)");
    end;

    [Test]
    procedure T081_AssetPriceIncludesVATKeepsHeadersValueIfNotAllowedUpdatingDefaults()
    var
        Item: Record Item;
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
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
        PriceListLine.Init();
        PriceListLine.Validate("Price List Code", PriceListHeader.Code);
        PriceListLine.Insert(true);

        // [WHEN] Validate "Asset Type"
        PriceListLine.Validate("Asset Type", "Price Asset Type"::Item);

        // [THEN] Line inserted, "Price Includes VAT" is false
        PriceListLine.TestField("Price Includes VAT", PriceListHeader."Price Includes VAT");
        PriceListLine.TestField("VAT Bus. Posting Gr. (Price)", PriceListHeader."VAT Bus. Posting Gr. (Price)");

        // [WHEN] Validate "Asset No." as 'I'
        PriceListLine.Validate("Asset No.", Item."No.");

        // [THEN] "Price Includes VAT" is false (as header's value)
        PriceListLine.TestField("Price Includes VAT", PriceListHeader."Price Includes VAT");
        PriceListLine.TestField("VAT Bus. Posting Gr. (Price)", PriceListHeader."VAT Bus. Posting Gr. (Price)");
    end;

    [Test]
    procedure T082_PriceIncludesVATGetsAssetsValueIfAllowedUpdatingDeafults()
    var
        Item: Record Item;
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
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
        PriceListLine.Init();
        PriceListLine.Validate("Price List Code", PriceListHeader.Code);
        PriceListLine.Insert(true);

        // [WHEN] Validate "Asset Type"
        PriceListLine.Validate("Asset Type", "Price Asset Type"::Item);

        // [THEN] Line inserted, "Price Includes VAT" is false
        PriceListLine.TestField("Price Includes VAT", PriceListHeader."Price Includes VAT");
        PriceListLine.TestField("VAT Bus. Posting Gr. (Price)", PriceListHeader."VAT Bus. Posting Gr. (Price)");

        // [WHEN] Validate "Asset No." as 'I'
        PriceListLine.Validate("Asset No.", Item."No.");

        // [THEN] "Price Includes VAT" is true (as item's value)
        PriceListLine.TestField("Price Includes VAT", Item."Price Includes VAT");
        PriceListLine.TestField("VAT Bus. Posting Gr. (Price)", Item."VAT Bus. Posting Gr. (Price)");
    end;

    [Test]
    procedure T099_ValidateBlankNoForAsset()
    var
        Item: Record Item;
        PriceListLine: Record "Price List Line";
    begin
        Initialize();
        // [GIVEN] Item 'X'
        LibraryInventory.CreateItem(Item);
        // [GIVEN] Price List Line, where "Source Type" is 'All Customers', "Asset Type" is Item, "Asset No." is 'X', "Minimum Quantity" is 10, "Unit Price" is 100
        PriceListLine.Validate("Source Type", "Price Source Type"::"All Customers");
        PriceListLine.Validate("Asset Type", "Price Asset Type"::Item);
        PriceListLine.Validate("Asset No.", Item."No.");
        PriceListLine.Validate("Minimum Quantity", 10);
        PriceListLine.Validate("Unit Price", 100.00);

        // [WHEN] Blank "Asset No."
        PriceListLine.Validate("Asset No.", '');

        // [THEN] Price List Line, where "Asset Type" is Item, "Asset No." is <blank>, "Minimum Quantity" is 10, "Unit Price" is 100
        PriceListLine.TestField("Asset Type", "Price Asset Type"::Item);
        PriceListLine.TestField("Asset No.", '');
        PriceListLine.TestField("Minimum Quantity", 10);
        PriceListLine.TestField("Unit Price", 100.00);
    end;

    [Test]
    procedure T100_ValidateItemNoForCustomer()
    var
        Customer: Record Customer;
        Item: Record Item;
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Customer] [Item]
        Initialize();
        // [GIVEN] Item 'X', where "Sales Unit of Measure" - 'SUoM', "Allow Invoice Disc." is Yes, 
        // [GIVEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'VATBPG'
        CreateItem(Item);
        // [GIVEN] Customer 'C', where "VAT Bus. Posting Group" is 'CVAT'
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] Price List Line, where "Source Type" is 'Customer', "Asset Type" is Item
        PriceListLine.Validate("Source Type", "Price Source Type"::Customer);
        PriceListLine.Validate("Source No.", Customer."No.");
        PriceListLine."Unit of Measure Code" := LibraryUtility.GenerateGUID();
        PriceListLine.Validate("Asset Type", "Price Asset Type"::Item);

        // [WHEN] Set "Asset No." as 'X'
        PriceListLine.Validate("Asset No.", Item."No.");

        // [THEN] Price List Line, where "Unit of Measure Code" is 'SUoM', "Variant Code" is <blank>, "Allow Invoice Disc." is Yes, 
        // [THEN] "Price Includes VAT" is No, "VAT Bus. Posting Gr. (Price)" is 'CVAT'
        VerifyLineVariant(PriceListLine, Item."Sales Unit of Measure", true, false, Customer."VAT Bus. Posting Group", '', '', Customer."Currency Code");
    end;

    [Test]
    procedure T101_ValidateItemNoForAllCustomers()
    var
        Item: Record Item;
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Customer] [Item]
        Initialize();
        // [GIVEN] Item 'X', where "Sales Unit of Measure" - 'SUoM', "Allow Invoice Disc." is Yes, 
        // [GIVEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'VATBPG'
        CreateItem(Item);
        // [GIVEN] Price List Line, where "Source Type" is 'All Customers', "Asset Type" is Item
        PriceListLine.Validate("Source Type", "Price Source Type"::"All Customers");
        PriceListLine."Unit of Measure Code" := LibraryUtility.GenerateGUID();
        PriceListLine.Validate("Asset Type", "Price Asset Type"::Item);

        // [WHEN] Set "Asset No." as 'X'
        PriceListLine.Validate("Asset No.", Item."No.");

        // [THEN] Price List Line, where "Unit of Measure Code" is 'SUoM', "Variant Code" is <blank>, "Allow Invoice Disc." is Yes, 
        // [THEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'VATBPG'
        VerifyLineVariant(
            PriceListLine, Item."Sales Unit of Measure", true, true, Item."VAT Bus. Posting Gr. (Price)", '', '', '');
    end;

    [Test]
    procedure T102_ValidateItemNoForCustomerPriceGroup()
    var
        Item: Record Item;
        CustomerPriceGroup: Record "Customer Price Group";
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Customer Price Group] [Item]
        Initialize();
        // [GIVEN] Item 'X', where "Sales Unit of Measure" - 'SUoM', "Allow Invoice Disc." is Yes, 
        // [GIVEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'VATBPG'
        CreateItem(Item);
        // [GIVEN] CustomerPriceGroup 'CPG', where "Allow Invoice Disc." is No, "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'CPGVAT'
        CreateCustomerPriceGroup(CustomerPriceGroup);
        // [GIVEN] Price List Line, where "Allow Invoice Disc." is No, "Source Type" is 'Customer Price Group', "Asset Type" is 'Item'
        PriceListLine.Validate("Source Type", "Price Source Type"::"Customer Price Group");
        PriceListLine.Validate("Source No.", CustomerPriceGroup.Code);
        PriceListLine."Unit of Measure Code" := LibraryUtility.GenerateGUID();
        PriceListLine.Validate("Asset Type", "Price Asset Type"::Item);

        // [WHEN] Set "Asset No." as 'X'
        PriceListLine.Validate("Asset No.", Item."No.");

        // [THEN] Price List Line, where "Unit of Measure Code" is 'SUoM', "Variant Code" is <blank>, "Allow Invoice Disc." is Yes, 
        // [THEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'CPGVAT'
        VerifyLineVariant(
            PriceListLine, Item."Sales Unit of Measure", Item."Allow Invoice Disc.",
            CustomerPriceGroup."Price Includes VAT", CustomerPriceGroup."VAT Bus. Posting Gr. (Price)", '', '', '');
    end;

    [Test]
    procedure T103_ValidateItemDiscountGroupForCustomer()
    var
        Customer: Record Customer;
        ItemDiscountGroup: Record "Item Discount Group";
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Customer] [Item Discount Group]
        Initialize();
        // [GIVEN] ItemDiscountGroup 'X'
        LibraryERM.CreateItemDiscountGroup(ItemDiscountGroup);
        // [GIVEN] Customer 'C', where "VAT Bus. Posting Group" is 'CVAT'
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] Price List Line, where "Source Type" is 'Customer', "Asset Type" is "Item Discount Group", 
        // [GIVEN] "Variant Code" is 'V', "Unit of Measure Code" is 'UoM'
        PriceListLine.Validate("Source Type", "Price Source Type"::Customer);
        PriceListLine.Validate("Source No.", Customer."No.");
        PriceListLine."Variant Code" := LibraryUtility.GenerateGUID();
        PriceListLine."Unit of Measure Code" := LibraryUtility.GenerateGUID();
        PriceListLine.Validate("Asset Type", "Price Asset Type"::"Item Discount Group");

        // [WHEN] Set "Asset No." as 'X'
        PriceListLine.Validate("Asset No.", ItemDiscountGroup.Code);

        // [THEN] Price List Line, where "Unit of Measure Code" is <blank>, "Variant Code" is <blank>, "Allow Invoice Disc." is No, 
        // [THEN] "Price Includes VAT" is No, "VAT Bus. Posting Gr. (Price)" is 'CVAT'
        VerifyLineVariant(PriceListLine, '', false, false, Customer."VAT Bus. Posting Group", '', '', Customer."Currency Code");
    end;

    [Test]
    procedure T104_ValidateItemNoForVendor()
    var
        Currency: Record Currency;
        Item: Record Item;
        PriceListLine: Record "Price List Line";
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
        // [GIVEN] Price List Line, where "Source Type" is 'Vendor', "Asset Type" is Item
        PriceListLine.Validate("Source Type", "Price Source Type"::Vendor);
        PriceListLine.Validate("Source No.", Vendor."No.");
        PriceListLine."Unit of Measure Code" := LibraryUtility.GenerateGUID();
        PriceListLine.Validate("Asset Type", "Price Asset Type"::Item);

        // [WHEN] Set "Asset No." as 'X'
        PriceListLine.Validate("Asset No.", Item."No.");

        // [THEN] Price List Line, where "Unit of Measure Code" is 'PUoM', "Variant Code" is <blank>, "Allow Invoice Disc." is Yes, 
        // [THEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'VBG'
        VerifyLineVariant(PriceListLine, Item."Purch. Unit of Measure", Item."Allow Invoice Disc.", Vendor."Prices Including VAT", Vendor."VAT Bus. Posting Group", '', '', Vendor."Currency Code");
    end;

    [Test]
    procedure T105_ValidateItemNoForJobSale()
    var
        Item: Record Item;
        Job: Record Job;
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Job] [Item]
        Initialize();
        // [GIVEN] Item 'X', where "Sales Unit of Measure" - 'SUoM', "Allow Invoice Disc." is Yes, 
        // [GIVEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'VATBPG'
        CreateItem(Item);
        // [GIVEN] Price List Line, where "Price Type" is 'Sale', "Source Type" is 'Job', "Asset Type" is Item
        PriceListLine."Price Type" := "Price Type"::Sale;
        PriceListLine.Validate("Source Type", "Price Source Type"::Job);
        LibraryJob.CreateJob(Job);
        PriceListLine.Validate("Source No.", Job."No.");
        PriceListLine."Unit of Measure Code" := LibraryUtility.GenerateGUID();
        PriceListLine.Validate("Asset Type", "Price Asset Type"::Item);

        // [WHEN] Set "Asset No." as 'X'
        PriceListLine.Validate("Asset No.", Item."No.");

        // [THEN] Price List Line, where "Unit of Measure Code" is 'SUoM', "Variant Code" is <blank>, "Allow Invoice Disc." is Yes, 
        // [THEN] "Price Includes VAT" is No, "VAT Bus. Posting Gr. (Price)" is <blank>
        VerifyLineVariant(
            PriceListLine, Item."Sales Unit of Measure", Item."Allow Invoice Disc.",
            Item."Price Includes VAT", item."VAT Bus. Posting Gr. (Price)", '', '', Job."Currency Code");
    end;

    [Test]
    procedure T106_ValidateItemNoForJobPurchase()
    var
        Item: Record Item;
        Job: Record Job;
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Job] [Item]
        Initialize();
        // [GIVEN] Item 'X', where "Purch. Unit of Measure" - 'PUoM', "Allow Invoice Disc." is Yes, 
        // [GIVEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'VATBPG'
        CreateItem(Item);
        // [GIVEN] Price List Line, where "Price Type" is 'Purchase', "Source Type" is 'Job', "Asset Type" is Item
        PriceListLine."Price Type" := "Price Type"::Purchase;
        PriceListLine.Validate("Source Type", "Price Source Type"::Job);
        LibraryJob.CreateJob(Job);
        PriceListLine.Validate("Source No.", Job."No.");
        PriceListLine."Unit of Measure Code" := LibraryUtility.GenerateGUID();
        PriceListLine.Validate("Asset Type", "Price Asset Type"::Item);

        // [WHEN] Set "Asset No." as 'X'
        PriceListLine.Validate("Asset No.", Item."No.");

        // [THEN] Price List Line, where "Unit of Measure Code" is 'PUoM', "Variant Code" is <blank>, "Allow Invoice Disc." is Yes, 
        // [THEN] "Price Includes VAT" is No, "VAT Bus. Posting Gr. (Price)" is <blank>
        VerifyLineVariant(PriceListLine, Item."Purch. Unit of Measure", Item."Allow Invoice Disc.", false, '', '', '', Job."Currency Code");
    end;

    [Test]
    procedure T107_ValidateGlAccNoForJob()
    var
        GLAccount: Record "G/L Account";
        Job: Record Job;
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Job] [G/L Account]
        Initialize();
        // [GIVEN] G/L Account 'X', where "VAT Bus. Posting Group" is 'VATBPG', Name is 'Descr'
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        GLAccount.Name := LibraryUtility.GenerateRandomText(MaxStrLen(GLAccount.Name));
        GLAccount.Modify();
        // [GIVEN] Price List Line, where "Price Type" is 'Any, "Source Type" is 'Job', "Asset Type" is Item, "Variant Code" is 'V'
        PriceListLine.Validate("Source Type", "Price Source Type"::Job);
        LibraryJob.CreateJob(Job);
        PriceListLine.Validate("Source No.", Job."No.");
        PriceListLine."Variant Code" := LibraryUtility.GenerateGUID();
        PriceListLine."Unit of Measure Code" := LibraryUtility.GenerateGUID();
        PriceListLine.Validate("Asset Type", "Price Asset Type"::"G/L Account");

        // [WHEN] Set "Asset No." as 'X'
        PriceListLine.Validate("Asset No.", GLAccount."No.");

        // [THEN] Price List Line, where "Unit of Measure Code" is <blank>, "Variant Code" is <blank>, "Allow Invoice Disc." is No, 
        // [THEN] "Price Includes VAT" is No, "VAT Bus. Posting Gr. (Price)" is <blank>, Description is 'Descr'
        VerifyLineVariant(PriceListLine, '', false, false, '', '', '', Job."Currency Code");
        PriceListLine.TestField(Description, GLAccount.Name);
    end;

    [Test]
    procedure T108_ValidateResourceForJob()
    var
        Resource: Record Resource;
        Job: Record Job;
        PriceListLine: Record "Price List Line";
        WorkType: Record "Work Type";
    begin
        // [FEATURE] [Job] [Resource]
        Initialize();
        // [GIVEN] Resource 'X', where "Unit of Measure Code" is 'R-UOM'
        Resource.Get(LibraryResource.CreateResourceNo());
        // [GIVEN] Price List Line, where "Price Type" is 'Any, "Source Type" is 'Job', "Asset Type" is Resource, 
        // [GIVEN] "Variant Code" is 'V', "Work Type Code" is 'WT'
        PriceListLine.Validate("Source Type", "Price Source Type"::Job);
        LibraryJob.CreateJob(Job);
        PriceListLine.Validate("Source No.", Job."No.");
        PriceListLine."Variant Code" := LibraryUtility.GenerateGUID();
        PriceListLine."Unit of Measure Code" := LibraryUtility.GenerateGUID();
        LibraryResource.CreateWorkType(WorkType);
        PriceListLine."Work Type Code" := WorkType.Code;
        PriceListLine.Validate("Asset Type", "Price Asset Type"::Resource);

        // [WHEN] Set "Asset No." as 'X'
        PriceListLine.Validate("Asset No.", Resource."No.");

        // [THEN] Price List Line, where "Unit of Measure Code" is 'R-UOM', "Variant Code" is <blank>, "Allow Invoice Disc." is No, 
        // [THEN] "Price Includes VAT" is No, "VAT Bus. Posting Gr. (Price)" is <blank>, "Work Type Code" is <blank>
        VerifyLineVariant(PriceListLine, Resource."Base Unit of Measure", false, false, '', '', '', Job."Currency Code");
    end;

    [Test]
    procedure T109_ValidateResourceGroupForJob()
    var
        ResourceGroup: Record "Resource Group";
        Job: Record Job;
        PriceListLine: Record "Price List Line";
        WorkType: Record "Work Type";
    begin
        // [FEATURE] [Job] [Resource Group]
        Initialize();
        // [GIVEN] Resource Group 'X'
        LibraryResource.CreateResourceGroup(ResourceGroup);
        // [GIVEN] Price List Line, where "Price Type" is 'Any, "Source Type" is 'Job', "Asset Type" is 'Resource Group', 
        // [GIVEN] "Variant Code" is 'V', "Work Type Code" is 'WT'
        PriceListLine.Validate("Source Type", "Price Source Type"::Job);
        LibraryJob.CreateJob(Job);
        PriceListLine.Validate("Source No.", Job."No.");
        PriceListLine."Variant Code" := LibraryUtility.GenerateGUID();
        PriceListLine."Unit of Measure Code" := LibraryUtility.GenerateGUID();
        LibraryResource.CreateWorkType(WorkType);
        PriceListLine."Work Type Code" := WorkType.Code;
        PriceListLine.Validate("Asset Type", "Price Asset Type"::"Resource Group");

        // [WHEN] Set "Asset No." as 'X'
        PriceListLine.Validate("Asset No.", ResourceGroup."No.");

        // [THEN] Price List Line, where "Unit of Measure Code" is <blank>, "Variant Code" is <blank>, "Allow Invoice Disc." is No, 
        // [THEN] "Price Includes VAT" is No, "VAT Bus. Posting Gr. (Price)" is <blank>, "Work Type Code" is <blank>
        VerifyLineVariant(PriceListLine, '', false, false, '', '', '', Job."Currency Code");
    end;

    [Test]
    procedure T110_ValidateResourceForCustomer()
    var
        Customer: Record Customer;
        Resource: Record Resource;
        PriceListLine: Record "Price List Line";
        WorkType: Record "Work Type";
    begin
        // [FEATURE] [Customer] [Resource]
        Initialize();
        // [GIVEN] Resource 'X', where "Unit of Measure Code" is 'R-UOM'
        Resource.Get(LibraryResource.CreateResourceNo());
        // [GIVEN] Customer 'C', where "VAT Bus. Posting Group" is 'CVAT'
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] Price List Line, where "Source Type" is 'Customer', "Asset Type" is Resource, 
        // [GIVEN] "Variant Code" is 'V', "Work Type Code" is 'WT'
        PriceListLine.Validate("Source Type", "Price Source Type"::Customer);
        PriceListLine.Validate("Source No.", Customer."No.");
        PriceListLine."Variant Code" := LibraryUtility.GenerateGUID();
        PriceListLine."Unit of Measure Code" := LibraryUtility.GenerateGUID();
        LibraryResource.CreateWorkType(WorkType);
        PriceListLine."Work Type Code" := WorkType.Code;
        PriceListLine.Validate("Asset Type", "Price Asset Type"::Resource);

        // [WHEN] Set "Asset No." as 'X'
        PriceListLine.Validate("Asset No.", Resource."No.");

        // [THEN] Price List Line, where "Unit of Measure Code" is 'R-UOM', "Variant Code" is <blank>, "Allow Invoice Disc." is No, 
        // [THEN] "Price Includes VAT" is No, "VAT Bus. Posting Gr. (Price)" is 'CVAT', "Work Type Code" is <blank>
        VerifyLineVariant(
            PriceListLine, Resource."Base Unit of Measure", false, false,
            Customer."VAT Bus. Posting Group", '', '', Customer."Currency Code");
    end;

    [Test]
    procedure T111_ValidateResourceGroupForVendor()
    var
        ResourceGroup: Record "Resource Group";
        PriceListLine: Record "Price List Line";
        Vendor: Record Vendor;
        WorkType: Record "Work Type";
    begin
        // [FEATURE] [Vendor] [Resource Group]
        Initialize();
        // [GIVEN] Vendor 'V', where "VAT Bus. Posting Group" is 'VPG'
        LibraryPurchase.CreateVendor(Vendor);
        // [GIVEN] Resource Group 'X'
        LibraryResource.CreateResourceGroup(ResourceGroup);
        // [GIVEN] Price List Line, where "Source Type" is 'Vendor', "Asset Type" is 'Resource Group',
        // [GIVEN] "Variant Code" is 'V', "Work Type Code" is 'WT'
        PriceListLine.Validate("Source Type", "Price Source Type"::Vendor);
        PriceListLine.Validate("Source No.", Vendor."No.");
        PriceListLine."Variant Code" := LibraryUtility.GenerateGUID();
        PriceListLine."Unit of Measure Code" := LibraryUtility.GenerateGUID();
        LibraryResource.CreateWorkType(WorkType);
        PriceListLine."Work Type Code" := WorkType.Code;
        PriceListLine.Validate("Asset Type", "Price Asset Type"::"Resource Group");

        // [WHEN] Set "Asset No." as 'X'
        PriceListLine.Validate("Asset No.", ResourceGroup."No.");

        // [THEN] Price List Line, where "Unit of Measure Code" is <blank>, "Variant Code" is <blank>, "Allow Invoice Disc." is No, 
        // [THEN] "Price Includes VAT" is No, "VAT Bus. Posting Gr. (Price)" is 'VPG', "Work Type Code" is <blank>
        VerifyLineVariant(PriceListLine, '', false, false, Vendor."VAT Bus. Posting Group", '', '', '');
    end;

    [Test]
    procedure T112_ValidateSourceTypeForItem()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Customer] [Item]
        Initialize();
        // [GIVEN] Item 'X', where "Sales Unit of Measure" - 'SUoM', "Allow Invoice Disc." is Yes, 
        // [GIVEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'VATBPG'
        CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        // [GIVEN] Price List Line, where "Source Type" is 'Customer', "Asset Type" is Item, "Variant Code" is 'V'
        PriceListLine.Validate("Source Type", "Price Source Type"::"All Customers");
        PriceListLine.Validate("Asset Type", "Price Asset Type"::Item);
        PriceListLine.Validate("Asset No.", Item."No.");
        PriceListLine."Variant Code" := ItemVariant.Code;
        PriceListLine."Unit of Measure Code" := LibraryUtility.GenerateGUID();

        // [WHEN] Set "Source Type " as 'Customer'
        PriceListLine.Validate("Source Type", "Price Source Type"::Customer);

        // [THEN] Price List Line, where "Unit of Measure Code" is 'SUoM', "Variant Code" is 'V', "Allow Invoice Disc." is Yes, 
        // [THEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'VATBPG'
        VerifyLineVariant(
            PriceListLine, Item."Sales Unit of Measure", true, true,
            Item."VAT Bus. Posting Gr. (Price)", ItemVariant.Code, '', '');
    end;

    [Test]
    procedure T113_ValidateAllCustomersSourceNoForItem()
    var
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [All Customers]
        Initialize();
        // [GIVEN] Price List Line, where "Source Type" is 'All Customers'
        PriceListLine.Validate("Source Type", "Price Source Type"::"All Customers");

        // [WHEN] Set "Source No." as 'X'
        PriceListLine.Validate("Source No.", LibraryUtility.GenerateGUID());

        // [THEN] "Source No." is <blank>
        PriceListLine.TestField("Source No.", '');
    end;

    [Test]
    procedure T114_ValidateCustomerNoForItem()
    var
        Customer: Record Customer;
        Item: Record Item;
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Customer] [Item]
        Initialize();
        // [GIVEN] Customer 'C', where "Currency Code" is 'USD', "VAT Bus. POsting Group" is 'CVAT', 
        // [GIVEN] "Prices Including VAT" is No, "Allow Line Disc." is Yes
        CreateCustomer(Customer);
        // [GIVEN] Item 'X', where "Sales Unit of Measure" - 'SUoM', "Allow Invoice Disc." is Yes, 
        // [GIVEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'VATBPG'
        CreateItem(Item);
        // [GIVEN] Price List Line, where "Source Type" is 'Customer', "Asset Type" is Item, "Variant Code" is 'V'
        PriceListLine.Validate("Source Type", "Price Source Type"::Customer);
        PriceListLine.Validate("Asset Type", "Price Asset Type"::Item);
        PriceListLine.Validate("Asset No.", Item."No.");
        PriceListLine."Variant Code" := LibraryUtility.GenerateGUID();
        PriceListLine."Unit of Measure Code" := LibraryUtility.GenerateGUID();

        // [WHEN] Set "Source Type " as 'Customer'
        PriceListLine.Validate("Source No.", Customer."No.");

        // [THEN] Price List Line, where "Allow Line Disc." is Yes, "Currency Code" is 'USD',
        // [THEN] "Price Includes VAT" is No, "VAT Bus. Posting Gr. (Price)" is 'CVAT'
        VerifyLine(
            PriceListLine, Customer."Allow Line Disc.", Customer."Prices Including VAT",
            Customer."VAT Bus. Posting Group", Customer."Currency Code");
    end;

    [Test]
    procedure T115_ValidateCustomerPriceGroupForItem()
    var
        CustomerPriceGroup: Record "Customer Price Group";
        Item: Record Item;
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Customer Price Group] [Item]
        Initialize();
        // [GIVEN] Customer Price Group 'CPG', where "VAT Bus. Posting Gr. (Price)" is 'CVAT', 
        // [GIVEN] "Prices Including VAT" is Yes, "Allow Line Disc." is No, "Allow Invoice Disc." is No
        CreateCustomerPriceGroup(CustomerPriceGroup);
        // [GIVEN] Item 'X', where "Sales Unit of Measure" - 'SUoM', "Allow Invoice Disc." is Yes, 
        // [GIVEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'VATBPG'
        CreateItem(Item);
        // [GIVEN] Price List Line, where "Source Type" is 'Customer Price GroupCustomer Price Group', "Asset Type" is Item, "Variant Code" is 'V'
        PriceListLine.Validate("Source Type", "Price Source Type"::"Customer Price Group");
        PriceListLine.Validate("Asset Type", "Price Asset Type"::Item);
        PriceListLine.Validate("Asset No.", Item."No.");
        PriceListLine."Variant Code" := LibraryUtility.GenerateGUID();
        PriceListLine."Unit of Measure Code" := LibraryUtility.GenerateGUID();

        // [WHEN] Set "Source Type " as 'Customer'
        PriceListLine.Validate("Source No.", CustomerPriceGroup.Code);

        // [THEN] Price List Line, where "Allow Line Disc." is No, "Allow Invoice Disc." is No,
        // [THEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'CVAT'
        VerifyLine(
            PriceListLine, CustomerPriceGroup."Allow Line Disc.", CustomerPriceGroup."Price Includes VAT",
            CustomerPriceGroup."VAT Bus. Posting Gr. (Price)", CustomerPriceGroup."Allow Invoice Disc.");
    end;

    [Test]
    procedure T116_ValidateCampaignNoForItem()
    var
        Campaign: Record Campaign;
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Campaign]
        Initialize();
        // [GIVEN] Campaign 'C', where "Starting Date" is '010120', "Ending Date" is '310120'
        LibraryMarketing.CreateCampaign(Campaign);
        Campaign.Validate("Starting Date", WorkDate());
        Campaign.Validate("Ending Date", WorkDate() + 10);
        Campaign.Modify();
        // [GIVEN] Price List Line, where "Source Type" is 'Campaign', "Starting Date" and "Ending Date" are <blank>
        PriceListLine.Validate("Source Type", "Price Source Type"::Campaign);

        // [WHEN] Set "Source No." as 'C'
        PriceListLine.Validate("Source No.", Campaign."No.");

        // [THEN] Price List Line, where "Starting Date" is '010120', "Ending Date" is '310120'
        VerifyLine(PriceListLine, Campaign."Starting Date", Campaign."Ending Date");
    end;

    [Test]
    procedure T117_ValidateContactNoForItem()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        Item: Record Item;
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Contact] [Item]
        Initialize();
        // [GIVEN] Customer 'C' with Contact 'CONT', where "VAT Bus. Posting Group" is 'CVAT', 
        // [GIVEN] "Prices Including VAT" is No, "Allow Line Disc." is Yes
        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);
        // [GIVEN] Item 'X', where "Sales Unit of Measure" - 'SUoM', "Allow Invoice Disc." is Yes, 
        // [GIVEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'VATBPG'
        CreateItem(Item);
        // [GIVEN] Price List Line, where "Price Type"::Sale, "Source Type" is 'Contact', "Asset Type" is Item, "Variant Code" is 'V'
        PriceListLine."Price Type" := "Price Type"::Sale;
        PriceListLine.Validate("Source Type", "Price Source Type"::Contact);
        PriceListLine.Validate("Asset Type", "Price Asset Type"::Item);
        PriceListLine.Validate("Asset No.", Item."No.");

        // [WHEN] Set "Source No." as 'CONT'
        PriceListLine.Validate("Source No.", Contact."No.");

        // [THEN] Price List Line, where "Unit of Measure Code" is 'SUoM', "Variant Code" is <blank>, "Allow Invoice Disc." is Yes, 
        // [THEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'VATBPG'
        VerifyLineVariant(PriceListLine, Item."Sales Unit of Measure", true, true, Item."VAT Bus. Posting Gr. (Price)", '', '', '');
    end;

    [Test]
    procedure T118_ValidateItemForContact()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        Item: Record Item;
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Contact] [Item]
        Initialize();
        // [GIVEN] Customer 'C' with Contact 'CONT', where "VAT Bus. Posting Group" is 'CVAT', 
        // [GIVEN] "Prices Including VAT" is No, "Allow Line Disc." is Yes
        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);
        // [GIVEN] Item 'X', where "Sales Unit of Measure" - 'SUoM', "Allow Invoice Disc." is Yes, 
        // [GIVEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'VATBPG'
        CreateItem(Item);
        // [GIVEN] Price List Line, where "Price Type"::Sale, "Source Type" is 'Contact', "Asset Type" is Item
        PriceListLine."Price Type" := "Price Type"::Sale;
        PriceListLine.Validate("Source Type", "Price Source Type"::Contact);
        PriceListLine.Validate("Source No.", Contact."No.");
        PriceListLine.Validate("Asset Type", "Price Asset Type"::Item);
        PriceListLine."Unit of Measure Code" := LibraryUtility.GenerateGUID();

        // [WHEN] Set "Source No." as 'X'
        PriceListLine.Validate("Asset No.", Item."No.");

        // [THEN] Price List Line, where "Unit of Measure Code" is 'SUoM', "Variant Code" is <blank>, "Allow Invoice Disc." is Yes, 
        // [THEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'VATBPG'
        VerifyLineVariant(PriceListLine, Item."Sales Unit of Measure", true, true, Item."VAT Bus. Posting Gr. (Price)", '', '', '');
    end;

    [Test]
    procedure T119_ValidateWorkTypeForAllResources()
    var
        PriceListLine: Record "Price List Line";
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
        // [GIVEN] Price List Line, where "Source Type" is 'All Vendors', "Asset Type" is 'Resource', "Asset No." is <blank>
        PriceListLine.Validate("Source Type", "Price Source Type"::"All Vendors");
        PriceListLine.Validate("Asset Type", "Price Asset Type"::Resource);

        // [WHEN] Set "Work Type Code" as 'WT'
        PriceListLine.Validate("Work Type Code", WorkType.Code);

        // [THEN] Price Line, where "Unit of Measure Code" is 'UOM'
        PriceListLine.TestField("Work Type Code", WorkType.Code);
        PriceListLine.TestField("Unit of Measure Code", WorkType."Unit of Measure Code");
    end;

    [Test]
    procedure T120_DeletePricesOnResourceDeletion()
    var
        Resource: Array[2] of Record Resource;
    begin
        // [FEATURE] [Resource]
        Initialize();
        // [GIVEN] Two Resource 'A' and 'B' have related price lines
        LibraryResource.CreateResource(Resource[1], '');
        LibraryResource.CreateResource(Resource[2], '');
        CreateAssetPriceLines("Price Asset Type"::Resource, Resource[1]."No.", Resource[2]."No.");

        // [WHEN] Delete Resource 'A'
        Resource[1].Delete(true);

        // [THEN] Price List Lines for Resource 'A' are deleted, for Resource 'B' are not deleted
        VerifyDeletedAssetPrices("Price Asset Type"::Resource, Resource[1]."No.", Resource[2]."No.");
    end;

    [Test]
    procedure T121_DeletePricesOnResourceGroupDeletion()
    var
        ResourceGroup: Array[2] of Record "Resource Group";
    begin
        // [FEATURE] [Resource Group]
        Initialize();
        // [GIVEN] Two Resource Groups 'A' and 'B' have related price lines
        LibraryResource.CreateResourceGroup(ResourceGroup[1]);
        LibraryResource.CreateResourceGroup(ResourceGroup[2]);
        CreateAssetPriceLines("Price Asset Type"::"Resource Group", ResourceGroup[1]."No.", ResourceGroup[2]."No.");

        // [WHEN] Delete ResourceGroup 'A'
        ResourceGroup[1].Delete(true);

        // [THEN] Price List Lines for ResourceGroup 'A' are deleted, for ResourceGroup 'B' are not deleted
        VerifyDeletedAssetPrices("Price Asset Type"::"Resource Group", ResourceGroup[1]."No.", ResourceGroup[2]."No.");
    end;

    [Test]
    procedure T122_DeletePricesOnItemDeletion()
    var
        Item: Array[2] of Record Item;
    begin
        // [FEATURE] [Item]
        Initialize();
        // [GIVEN] Two Item 'A' and 'B' have related price lines
        LibraryInventory.CreateItem(Item[1]);
        LibraryInventory.CreateItem(Item[2]);
        CreateAssetPriceLines("Price Asset Type"::Item, Item[1]."No.", Item[2]."No.");

        // [WHEN] Delete Item 'A'
        Item[1].Delete(true);

        // [THEN] Price List Lines for Item 'A' are deleted, for Item 'B' are not deleted
        VerifyDeletedAssetPrices("Price Asset Type"::Item, Item[1]."No.", Item[2]."No.");
    end;

    [Test]
    procedure T123_DeletePricesOnItemDiscountGroupDeletion()
    var
        ItemDiscountGroup: Array[2] of Record "Item Discount Group";
    begin
        // [FEATURE] [Item Discount Group]
        Initialize();
        // [GIVEN] Two "Item Discount Group" 'A' and 'B' have related price lines
        LibraryERM.CreateItemDiscountGroup(ItemDiscountGroup[1]);
        LibraryERM.CreateItemDiscountGroup(ItemDiscountGroup[2]);
        CreateAssetDiscLines("Price Asset Type"::"Item Discount Group", ItemDiscountGroup[1].Code, ItemDiscountGroup[2].Code);

        // [WHEN] Delete "Item Discount Group" 'A'
        ItemDiscountGroup[1].Delete(true);

        // [THEN] Price List Lines for "Item Discount Group" 'A' are deleted, for "Item Discount Group" 'B' are not deleted
        VerifyDeletedAssetPrices("Price Asset Type"::"Item Discount Group", ItemDiscountGroup[1].Code, ItemDiscountGroup[2].Code);
    end;

    [Test]
    procedure T124_DeletePricesOnGLAccountDeletion()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLAccount: Array[2] of Record "G/L Account";
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

        // [THEN] Price List Lines for G/L Account 'A' are deleted, for G/L Account 'B' are not deleted
        VerifyDeletedAssetPrices("Price Asset Type"::"G/L Account", GLAccount[1]."No.", GLAccount[2]."No.");
    end;

    [Test]
    procedure T125_DeletePricesOnServiceCostDeletion()
    var
        ServiceCost: Array[2] of Record "Service Cost";
    begin
        // [FEATURE] [Service Cost]
        Initialize();
        // [GIVEN] Two "Service Cost" 'A' and 'B' have related price lines
        LibraryService.CreateServiceCost(ServiceCost[1]);
        LibraryService.CreateServiceCost(ServiceCost[2]);
        CreateAssetPriceLines("Price Asset Type"::"Service Cost", ServiceCost[1].Code, ServiceCost[2].Code);

        // [WHEN] Delete Service Cost 'A'
        ServiceCost[1].Delete(true);

        // [THEN] Price List Lines for Service Cost 'A' are deleted, for Service Cost 'B' are not deleted
        VerifyDeletedAssetPrices("Price Asset Type"::"Service Cost", ServiceCost[1].Code, ServiceCost[2].Code);
    end;

    [Test]
    procedure T126_DeletePricesOnItemVariantDeletion()
    var
        Item: Record Item;
        ItemVariant: Array[2] of Record "Item Variant";
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

        // [THEN] Price List Lines for Item Variant 'A' are deleted, for Item Variant 'B' are not deleted
        VerifyDeletedAssetPrices(Item."No.", ItemVariant[1].Code, ItemVariant[2].Code);
    end;

    [Test]
    procedure T130_ModifyPricesOnResourceRename()
    var
        Resource: Array[2] of Record Resource;
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

        // [THEN] Price List Lines for Resource 'A' are modified to 'X', for Resource 'B' are not deleted
        VerifyRenamedAssetPrices("Price Asset Type"::Resource, Resource[1]."No.", Resource[2]."No.", OldNo);
    end;

    [Test]
    procedure T131_ModifyPricesOnResourceGroupRename()
    var
        ResourceGroup: Array[2] of Record "Resource Group";
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

        // [THEN] Price List Lines for ResourceGroup 'A' are modified to 'X', for ResourceGroup 'B' are not deleted
        VerifyRenamedAssetPrices("Price Asset Type"::"Resource Group", ResourceGroup[1]."No.", ResourceGroup[2]."No.", OldNo);
    end;

    [Test]
    procedure T132_ModifyPricesOnItemRename()
    var
        Item: Array[2] of Record Item;
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

        // [THEN] Price List Lines for Item 'A' are modified to 'X', for Item 'B' are not deleted
        VerifyRenamedAssetPrices("Price Asset Type"::Item, Item[1]."No.", Item[2]."No.", OldNo);
    end;

    [Test]
    procedure T133_ModifyPricesOnItemDiscountGroupRename()
    var
        ItemDiscountGroup: Array[2] of Record "Item Discount Group";
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

        // [THEN] Price List Lines for "Item Discount Group" 'A' are modified to 'X', for "Item Discount Group" 'B' are not deleted
        VerifyRenamedAssetPrices("Price Asset Type"::"Item Discount Group", ItemDiscountGroup[1].Code, ItemDiscountGroup[2].Code, OldNo);
    end;

    [Test]
    procedure T134_ModifyPricesOnGLAccountRename()
    var
        GLAccount: Array[2] of Record "G/L Account";
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

        // [THEN] Price List Lines for GLAccount 'A' are modified to 'X', for GLAccount 'B' are not deleted
        VerifyRenamedAssetPrices("Price Asset Type"::"G/L Account", GLAccount[1]."No.", GLAccount[2]."No.", OldNo);
    end;

    [Test]
    procedure T135_ModifyPricesOnServiceCostRename()
    var
        ServiceCost: Array[2] of Record "Service Cost";
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

        // [THEN] Price List Lines for "Service Cost" 'A' are modified to 'X', for "Service Cost" 'B' are not deleted
        VerifyRenamedAssetPrices("Price Asset Type"::"Service Cost", ServiceCost[1].Code, ServiceCost[2].Code, OldNo);
    end;

    [Test]
    procedure T136_ModifyPricesOnItemVariantRename()
    var
        Item: Record Item;
        ItemVariant: Array[2] of Record "Item Variant";
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

        // [THEN] Price List Lines for Item Variant 'A' are modified to 'X', for Item Variant 'B' are not deleted
        VerifyRenamedAssetPrices(Item."No.", ItemVariant[1].Code, ItemVariant[2].Code, OldNo);
    end;

    [Test]
    procedure T137_ModifyPricesOnUnitOfMeasureRename()
    var
        UnitOfMeasure: Array[2] of Record "Unit Of Measure";
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

        // [THEN] Price List Lines for "Unit Of Measure" 'A' are modified to 'X', for "Unit Of Measure" 'B' are not deleted
        VerifyRenamedUOMs(UnitOfMeasure[1].Code, UnitOfMeasure[2].Code, OldNo);
    end;

    [Test]
    procedure T140_ValidateStartingDateAfterEndingDate()
    var
        PriceListLine: Record "Price List Line";
    begin
        Initialize();
        // [GIVEN] Price List Line, where  "Ending Date" is '310120'
        PriceListLine.Init();
        PriceListLine."Ending Date" := WorkDate();
        // [WHEN] Set "Starting Date" as '010220'
        asserterror PriceListLine.Validate("Starting Date", PriceListLine."Ending Date" + 1);

        // [THEN] Error message: 'Starting Date cannot be after Ending Date'
        Assert.ExpectedError(StrSubstNo(StartingDateErr, PriceListLine."Ending Date" + 1, PriceListLine."Ending Date"));
    end;

    [Test]
    procedure T141_ValidateEndingDateBeforeStartingDate()
    var
        PriceListLine: Record "Price List Line";
    begin
        Initialize();
        // [GIVEN] Price List Line, where "Starting Date" is '010220'
        PriceListLine.Init();
        PriceListLine."Starting Date" := WorkDate();
        // [WHEN] Set "Ending Date" as '310120'
        asserterror PriceListLine.Validate("Ending Date", PriceListLine."Starting Date" - 1);

        // [THEN] Error message: 'Starting Date cannot be after Ending Date'
        Assert.ExpectedError(StrSubstNo(StartingDateErr, PriceListLine."Starting Date", PriceListLine."Starting Date" - 1));
    end;

    [Test]
    procedure T142_ValidateStartingDateForCampaign()
    var
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Campaign]
        Initialize();
        // [GIVEN] Price List Line, where "Source Type" is 'Campaign', "Ending Date" is '310120'
        PriceListLine.Init();
        PriceListLine."Source Type" := "Price Source Type"::Campaign;
        PriceListLine."Ending Date" := WorkDate();
        // [WHEN] Set "Starting Date" as '010120'
        asserterror PriceListLine.Validate("Starting Date", WorkDate() + 1);

        // [THEN] Error message: '... you can only change Starting Date and Ending Date from the Campaign Card.'
        Assert.ExpectedError(CampaignDateErr);
    end;

    [Test]
    procedure T143_ValidateEndingDateForCampaignViaUI()
    var
        PriceListLine: Record "Price List Line";
        MockPriceListLine: TestPage "Mock Price List Line";
    begin
        // [FEATURE] [Campaign] [UI]
        Initialize();
        // [GIVEN] Price List Line, where "Source Type" is 'Campaign', "Starting Date" is '010220'
        PriceListLine.DeleteAll();
        PriceListLine.Init();
        PriceListLine."Source Type" := "Price Source Type"::Campaign;
        PriceListLine."Starting Date" := WorkDate();
        PriceListLine.Insert();
        // [GIVEN] Open page 
        MockPriceListLine.Trap();
        Page.Run(Page::"Mock Price List Line", PriceListLine, PriceListLine."Starting Date");
        // [WHEN] Set "Ending Date" as '310120'
        asserterror MockPriceListLine."Ending Date".SetValue(PriceListLine."Starting Date" - 1);

        // [THEN] Error message: '... you can only change Starting Date and Ending Date from the Campaign Card.'
        Assert.ExpectedError(CampaignDateErr);
    end;

    [Test]
    procedure T150_ValidateUnitOfMeasureForNonItem()
    var
        PriceListLine: Record "Price List Line";
        UnitofMeasure: Record "Unit of Measure";
    begin
        // [FEATURE] [Unit of Measure]
        Initialize();
        // [GIVEN] Price List Line, where "Asset Type" is 'G/L Account'
        PriceListLine.Init();
        PriceListLine."Asset Type" := "Price Asset Type"::"G/L Account";
        // [WHEN] Set "Unit Of Meadure" as 'BOX'
        UnitofMeasure.FindFirst();
        asserterror PriceListLine.Validate("Unit of Measure Code", UnitofMeasure.Code);

        // [THEN] Error message: 'Asset Type must be Item or Resource.'
        Assert.ExpectedError(AssetTypeForUOMErr);
    end;

    [Test]
    procedure T151_ValidateVariantCodeForNonItem()
    var
        PriceListLine: Record "Price List Line";
        ItemVariant: Record "Item Variant";
    begin
        // [FEATURE] [Item Variant]
        Initialize();
        // [GIVEN] Item Variant 'X' for Item 'I'
        ItemVariant.FindFirst();
        // [GIVEN] Price List Line, where "Asset Type" is 'Item Discount Group', "Asset Type" is 'I'
        PriceListLine.Init();
        PriceListLine."Asset Type" := "Price Asset Type"::"Item Discount Group";
        PriceListLine."Asset No." := ItemVariant."Item No.";
        // [WHEN] Set "Variant Code" as 'X'
        asserterror PriceListLine.Validate("Variant Code", ItemVariant.Code);

        // [THEN] Error message: 'Asset Type must be Item.'
        Assert.ExpectedTestFieldError(PriceListLine.FieldCaption("Asset Type"), Format(PriceListLine."Asset Type"::Item));
    end;

    [Test]
    procedure T160_ValidateUnitPriceForJob()
    var
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Job]
        Initialize();
        // [GIVEN] Price List Line, where "Source Type" is 'Job', "Cost Factor" is 2
        PriceListLine.Init();
        PriceListLine."Source Type" := "Price Source Type"::Job;
        PriceListLine."Source No." := 'JOB';
        PriceListLine."Asset Type" := "Price Asset Type"::"G/L Account";
        PriceListLine."Asset No." := 'ACC';
        PriceListLine."Cost Factor" := 2;
        // [WHEN] Set "Unit Price" as 1
        PriceListLine.Validate("Unit Price", 1);
        // [THEN] "Cost Factor" is 0
        PriceListLine.TestField("Cost Factor", 0);
    end;

    [Test]
    procedure T161_ValidateCostFactorForJob()
    var
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Job]
        Initialize();
        // [GIVEN] Price List Line, where "Source Type" is 'Job', "Unit Price" is 2
        PriceListLine.Init();
        PriceListLine.Validate("Source Type", "Price Source Type"::Job);
        PriceListLine."Source No." := 'JOB';
        PriceListLine."Asset Type" := "Price Asset Type"::"G/L Account";
        PriceListLine."Asset No." := 'ACC';
        PriceListLine."Unit Price" := 2;
        // [WHEN] Set "Cost Factor" as 1
        PriceListLine.Validate("Cost Factor", 1);
        // [THEN] "Unit Price" is 0
        PriceListLine.TestField("Unit Price", 0);
    end;

    [Test]
    procedure T162_ValidateCostFactorForNonJob()
    var
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Cost Factor]
        Initialize();
        // [GIVEN] Price List Line, where "Source Type" is 'All Customers'
        PriceListLine.Init();
        PriceListLine.Validate("Source Type", "Price Source Type"::"All Customers");
        PriceListLine."Asset Type" := "Price Asset Type"::"G/L Account";
        PriceListLine."Asset No." := 'ACC';
        // [WHEN] Set "Cost Factor" as 1
        asserterror PriceListLine.Validate("Cost Factor", 1);
        // [THEN] Error message: 'Source Group must be equal to Job'
        Assert.ExpectedTestFieldError(PriceListLine.FieldCaption("Source Group"), Format(PriceListLine."Source Group"::Job));
    end;

    [Test]
    procedure T163_ValidateNonPostingJobTask()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Job]
        Initialize();
        // [GIVEN] Job Task 'JT', where "Job Task Type" is 'Heading' (not Posting)
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        JobTask."Job Task Type" := JobTask."Job Task Type"::Heading;
        JobTask.Modify();
        // [GIVEN] Price List Line, where "Source Type" is 'Job Task'
        PriceListLine.Init();
        PriceListLine."Source Type" := "Price Source Type"::"Job Task";
        PriceListLine."Parent Source No." := Job."No.";
        // [WHEN] Set "Source No." as 'JT'
        asserterror PriceListLine.Validate("Source No.", JobTask."Job Task No.");
        // [THEN] Error message: 'Project Task Type must be equal to Posting'
        Assert.ExpectedTestFieldError(JobTask.FieldCaption("Job Task Type"), Format(JobTask."Job Task Type"::Posting));
    end;

    [Test]
    procedure T164_ValidateJobNoAsSource()
    var
        Currency: Record Currency;
        Job: Record Job;
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Job]
        Initialize();
        // [GIVEN] Job Task 'J', where "Currency Code" is 'USD'
        LibraryJob.CreateJob(Job);
        LibraryERM.CreateCurrency(Currency);
        Job."Currency Code" := Currency.Code;
        Job.Modify();
        // [GIVEN] Price List Line, where "Source Type" is 'Job'
        PriceListLine.Init();
        PriceListLine."Source Type" := "Price Source Type"::"Job";
        // [WHEN] Set "Source No." as 'JT'
        PriceListLine.Validate("Source No.", Job."No.");
        // [THEN] Line, where "Currency Code" is 'USD'
        PriceListLine.TestField("Currency Code", Job."Currency Code");
    end;

    [Test]
    procedure T165_ValidateJobNoAsParentSource()
    var
        Currency: Record Currency;
        Job: Record Job;
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Job]
        Initialize();
        // [GIVEN] Job Task 'J', where "Currency Code" is 'USD'
        LibraryJob.CreateJob(Job);
        LibraryERM.CreateCurrency(Currency);
        Job."Currency Code" := Currency.Code;
        Job.Modify();
        // [GIVEN] Price List Line, where "Source Type" is 'Job Task'
        PriceListLine.Init();
        PriceListLine."Source Type" := "Price Source Type"::"Job Task";
        // [WHEN] Set "Parent Source No." as 'J'
        PriceListLine.Validate("Parent Source No.", Job."No.");
        // [THEN] Line, where "Currency Code" is 'USD'
        PriceListLine.TestField("Currency Code", Job."Currency Code");
    end;

    [Test]
    [HandlerFunctions('LookupJobModalHandler,LookupJobTaskModalHandler')]
    procedure T200_LookupJobTaskInLineParentSourceBlank()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        SalesPriceList: TestPage "Sales Price List";
    begin
        // [FEATURE] [Source] [Job Task] [Allow Updating Defaults]
        Initialize(true);
        PriceListHeader.DeleteAll();
        PriceListLine.DeleteAll();
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
        PriceListLine: Record "Price List Line";
        SalesPriceList: TestPage "Sales Price List";
    begin
        // [FEATURE] [Source] [Job Task] [Allow Updating Defaults]
        Initialize(true);
        PriceListHeader.DeleteAll();
        PriceListLine.DeleteAll();
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
        PriceListLine: Record "Price List Line";
        SalesPriceList: TestPage "Sales Price List";
    begin
        // [FEATURE] [Source] [Job Task] [Allow Updating Defaults]
        Initialize(true);
        PriceListHeader.DeleteAll();
        PriceListLine.DeleteAll();
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
        PriceListLine: Record "Price List Line";
        SalesPriceList: TestPage "Sales Price List";
    begin
        // [FEATURE] [Source] [Job Task] [Allow Updating Defaults]
        Initialize(true);
        PriceListHeader.DeleteAll();
        PriceListLine.DeleteAll();
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
        PriceListLine: Record "Price List Line";
        SalesPriceList: TestPage "Sales Price List";
    begin
        // [FEATURE] [Source] [Job Task] [Allow Updating Defaults]
        Initialize(true);
        PriceListHeader.DeleteAll();
        PriceListLine.DeleteAll();
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
        PriceListLine: Record "Price List Line";
        SalesPriceList: TestPage "Sales Price List";
    begin
        // [FEATURE] [Source] [Job Task] [Allow Updating Defaults]
        Initialize(true);
        PriceListHeader.DeleteAll();
        PriceListLine.DeleteAll();
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
        MockPriceListLine: TestPage "Mock Price List Line";
    begin
        // [FEATURE] [Asset]
        Initialize();
        // [GIVEN] Item 'I'
        LibraryInventory.CreateItem(Item);
        // [GIVEN] Price Line, where "Asset Type" is 'Item'
        MockPriceListLine.OpenEdit();
        MockPriceListLine."Asset Type".SetValue("Price Asset Type"::Item);
        // [WHEN] Lookup "Asset No." set as 'I'
        LibraryVariableStorage.Enqueue(Item."No."); // for LookupItemModalHandler
        MockPriceListLine."Product No.".Lookup();

        // [THEN] "Asset No." is 'I'
        MockPriceListLine."Product No.".AssertEquals(Item."No.");
    end;

    [Test]
    procedure PriceListLineSyncShouldFixOutOfSyncPriceListLines()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: array[2] of Record "Price List Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        PriceListLineSync: Codeunit "Price List Line Sync";
        i: Integer;
    begin
        Initialize(true);

        // [GIVEN] An item with a variant.
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [GIVEN] A job with job task.
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] A price List for the job with lines for the item that are not in sync.
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Sale, PriceListHeader."Source Type"::"Job Task",
            Job."No.", JobTask."Job Task No."
        );

        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[1], PriceListHeader.Code, "Price Type"::Sale, "Price Source Type"::"Job Task", Job."No.",
            JobTask."Job Task No.", "Price Amount Type"::Price, "Price Asset Type"::Item, Item."No.");
        PriceListLine[1].Validate("Variant Code", ItemVariant.Code);

        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[2], PriceListHeader.Code, "Price Type"::Sale, "Price Source Type"::"Job Task", Job."No.",
            JobTask."Job Task No.", "Price Amount Type"::Price, "Price Asset Type"::Item, Item."No.");
        PriceListLine[2].Validate("Variant Code", ItemVariant.Code);

        for i := 1 to 2 do begin
            PriceListLine[i]."Assign-to No." := '';
            PriceListLine[i]."Assign-to Parent No." := '';
            PriceListLine[i]."Product No." := '';
            PriceListLine[i]."Variant Code Lookup" := '';
            PriceListLine[i]."Unit of Measure Code Lookup" := '';
            PriceListLine[i].Modify();
        end;

        // [WHEN] Running "Price List Line Sync".
        PriceListLineSync.Run();

        // [THEN] Price lines are synced.
        for i := 1 to 2 do begin
            PriceListLine[i].Get(PriceListLine[i].RecordId());
            PriceListLine[i].TestField("Assign-to No.", PriceListLine[i]."Source No.");
            PriceListLine[i].TestField("Assign-to Parent No.", PriceListLine[i]."Parent Source No.");
            PriceListLine[i].TestField("Product No.", PriceListLine[i]."Asset No.");
            PriceListLine[i].TestField("Variant Code Lookup", PriceListLine[i]."Variant Code");
            PriceListLine[i].TestField("Unit of Measure Code Lookup", PriceListLine[i]."Unit of Measure Code");
        end;
    end;

    [Test]
    procedure PriceListLineSyncCorrectsOutOfSyncLines()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: array[2] of Record "Price List Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        PriceListLineSync: Codeunit "Price List Line Sync";
        i: Integer;
    begin
        Initialize(true);

        // [GIVEN] An item with a variant.
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [GIVEN] A job with job task.
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] A price List for the job with lines for the item that are not in sync.
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Sale, PriceListHeader."Source Type"::"Job Task",
            Job."No.", JobTask."Job Task No."
        );

        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[1], PriceListHeader.Code, "Price Type"::Sale, "Price Source Type"::"Job Task", Job."No.",
            JobTask."Job Task No.", "Price Amount Type"::Price, "Price Asset Type"::Item, Item."No.");
        PriceListLine[1].Validate("Variant Code", ItemVariant.Code);

        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[2], PriceListHeader.Code, "Price Type"::Sale, "Price Source Type"::"Job Task", Job."No.",
            JobTask."Job Task No.", "Price Amount Type"::Price, "Price Asset Type"::Item, Item."No.");
        PriceListLine[2].Validate("Variant Code", ItemVariant.Code);

        for i := 1 to 2 do begin
            PriceListLine[i]."Assign-to No." := '';
            PriceListLine[i]."Assign-to Parent No." := '';
            PriceListLine[i]."Product No." := '';
            PriceListLine[i]."Variant Code Lookup" := '';
            PriceListLine[i]."Unit of Measure Code Lookup" := '';
            PriceListLine[i].Modify();
        end;

        // [WHEN] Running "Price List Line Sync".
        PriceListLineSync.Run();

        // [THEN] Price lines are synced.
        for i := 1 to 2 do begin
            PriceListLine[i].Get(PriceListLine[i].RecordId());
            PriceListLine[i].TestField("Assign-to No.", PriceListLine[i]."Source No.");
            PriceListLine[i].TestField("Assign-to Parent No.", PriceListLine[i]."Parent Source No.");
            PriceListLine[i].TestField("Product No.", PriceListLine[i]."Asset No.");
            PriceListLine[i].TestField("Variant Code Lookup", PriceListLine[i]."Variant Code");
            PriceListLine[i].TestField("Unit of Measure Code Lookup", PriceListLine[i]."Unit of Measure Code");
        end;
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    procedure OutOfSyncNotificationShouldShowWhenOpeningPurchasePriceListAndPriceListLinesAreOutOfSync()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PurchasePriceLists: TestPage "Purchase Price List";
    begin
        Initialize(true);

        // [GIVEN] A price List Line that are not in sync.
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, PriceListHeader."Price Type"::Sale,
            PriceListHeader."Source Type"::"All Customers", '');

        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::Item,
            LibraryInventory.CreateItemNo());
        PriceListLine."Product No." := '';
        PriceListLine.Modify();

        // [WHEN] Opening "Purchase Price List".
        PurchasePriceLists.OpenView();

        // [THEN] A notification is shown informing about the issue.
        Assert.AreEqual(OutOfSyncNotificationMsg, LibraryVariableStorage.DequeueText(), 'Text not matching');
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    procedure OutOfSyncNotificationShouldShowWhenOpeningPriceListLinesAndPriceListLinesAreOutOfSync()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListLines: TestPage "Price List Lines";
    begin
        Initialize(true);

        // [GIVEN] A price List Line that are not in sync.
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, PriceListHeader."Price Type"::Sale,
            PriceListHeader."Source Type"::"All Customers", '');

        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::Item,
            LibraryInventory.CreateItemNo());
        PriceListLine."Product No." := '';
        PriceListLine.Modify();

        // [WHEN] Opening "Price List Lines".
        PriceListLines.OpenView();

        // [THEN] A notification is shown informing about the issue.
        Assert.AreEqual(OutOfSyncNotificationMsg, LibraryVariableStorage.DequeueText(), 'Text not matching');
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    procedure OutOfSyncNotificationShouldShowWhenOpeningPurchasePriceListLinesAndPriceListLinesAreOutOfSync()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PurchasePriceListLines: TestPage "Purchase Price List Lines";
    begin
        Initialize(true);

        // [GIVEN] A price List Line that are not in sync.
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, PriceListHeader."Price Type"::Sale,
            PriceListHeader."Source Type"::"All Customers", '');

        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::Item,
            LibraryInventory.CreateItemNo());
        PriceListLine."Product No." := '';
        PriceListLine.Modify();

        // [WHEN] Opening "Purchase Price List Lines".
        PurchasePriceListLines.OpenView();

        // [THEN] A notification is shown informing about the issue.
        Assert.AreEqual(OutOfSyncNotificationMsg, LibraryVariableStorage.DequeueText(), 'Text not matching');
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    procedure OutOfSyncNotificationShouldShowWhenOpeningPricesOverviewAndPriceListLinesAreOutOfSync()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PricesOverview: TestPage "Prices Overview";
    begin
        Initialize(true);

        // [GIVEN] A price List Line that are not in sync.
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, PriceListHeader."Price Type"::Sale,
            PriceListHeader."Source Type"::"All Customers", '');

        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::Item,
            LibraryInventory.CreateItemNo());
        PriceListLine."Product No." := '';
        PriceListLine.Modify();

        // [WHEN] Opening "Prices Overview".
        PricesOverview.OpenView();

        // [THEN] A notification is shown informing about the issue.
        Assert.AreEqual(OutOfSyncNotificationMsg, LibraryVariableStorage.DequeueText(), 'Text not matching');
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    procedure OutOfSyncNotificationShouldShowWhenOpeningPriceWorksheetAndPriceListLinesAreOutOfSync()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceWorksheet: TestPage "Price Worksheet";
    begin
        Initialize(true);

        // [GIVEN] A price List Line that are not in sync.
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, PriceListHeader."Price Type"::Sale,
            PriceListHeader."Source Type"::"All Customers", '');

        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::Item,
            LibraryInventory.CreateItemNo());
        PriceListLine."Product No." := '';
        PriceListLine.Modify();

        // [WHEN] Opening "Price Worksheet".
        PriceWorksheet.OpenView();

        // [THEN] A notification is shown informing about the issue.
        Assert.AreEqual(OutOfSyncNotificationMsg, LibraryVariableStorage.DequeueText(), 'Text not matching');
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    procedure OutOfSyncNotificationShouldShowWhenOpeningPriceListFiltersAndPriceListLinesAreOutOfSync()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListFilters: TestPage "Price List Filters";
    begin
        Initialize(true);

        // [GIVEN] A price List Line that are not in sync.
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, PriceListHeader."Price Type"::Sale,
            PriceListHeader."Source Type"::"All Customers", '');

        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::Item,
            LibraryInventory.CreateItemNo());
        PriceListLine."Product No." := '';
        PriceListLine.Modify();

        // [WHEN] Opening "Price List Filters".
        PriceListFilters.OpenView();

        // [THEN] A notification is shown informing about the issue.
        Assert.AreEqual(OutOfSyncNotificationMsg, LibraryVariableStorage.DequeueText(), 'Text not matching');
    end;

    [Test]
    procedure UseCustomizedLookupOverriddenIfPriceListLinesOutOfSync()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        Initialize(true);
        PriceListHeader.DeleteAll();
        PriceListLine.DeleteAll();

        // [GIVEN] Use Customized Lookup set to false in Sales & Receivables Setup.
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Use Customized Lookup", false);
        SalesReceivablesSetup.Modify();

        // [THEN] UseCustomizedLookup returns false.
        Assert.IsFalse(PriceListLine.UseCustomizedLookup(), 'Expected to be false.');

        // [GIVEN] A price List Line that are not in sync.
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, PriceListHeader."Price Type"::Sale,
            PriceListHeader."Source Type"::"All Customers", '');

        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::Item,
            LibraryInventory.CreateItemNo());
        PriceListLine."Product No." := '';
        PriceListLine.Modify();

        // [THEN] UseCustomizedLookup returns true.
        Assert.IsTrue(PriceListLine.UseCustomizedLookup(), 'Expected to be false.');
    end;

    [Test]
    procedure VerifyProductNoIsNotDeletedOnCreatingNewPriceLineFromItemWithVariant()
    var
        PriceListHeader: Record "Price List Header";
        Item, Item2 : Record Item;
        ItemVariant: Record "Item Variant";
        SalesPriceList: TestPage "Sales Price List";
    begin
        // [SCENARIO: 449112] Verify Product No. is not deleted on creating new price line, if existing line has Item with Variant value
        // [GIVEN] Initialize
        Initialize(true);

        // [GIVEN] Create Item with variant and Item without variant
        CreateItemWithVariant(Item, ItemVariant);
        LibraryInventory.CreateItem(Item2);

        // [GIVEN] Create Price List Header record
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, PriceListHeader."Price Type"::Sale,
            PriceListHeader."Source Type"::"All Customers", '');

        // [GIVEN] Open price list page, create new line and add variant
        SalesPriceList.OpenEdit();
        SalesPriceList.Filter.SetFilter(Code, PriceListHeader.Code);
        CreateNewSalesPriceListLine(SalesPriceList, Item."No.", ItemVariant.Code);

        // [GIVEN] Create new Price List line with same Item No.
        CreateNewSalesPriceListLine(SalesPriceList, Item."No.", '');

        // [WHEN] Create New Price Line from Action                
        CreateNewSalesPriceListLine(SalesPriceList, Item2."No.", '');

        // [THEN] Verify Product No., and Variant Code is empty
        SalesPriceList.Lines."Product No.".AssertEquals(Item2."No.");
        SalesPriceList.Lines."Variant Code".AssertEquals('');
    end;

    [Test]
    procedure VerifyValuesOnPriceListHeaderAndPriceListLineWhenResourceAndJobTaskRename()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        ResourceGroup: Record "Resource Group";
        Job: Record Job;
        JobTask: Record "Job Task";
        ResourceGroupNo: Code[20];
        JobTaskNo: Code[20];
    begin
        // [SCENARIO 457323] Resource Group and Assign-to No. on the Price List Lines page is not updated by the new code.
        Initialize();

        // [GIVEN] Create 2 Jobs with Job Tasks and Create Resource.
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryResource.CreateResourceGroup(ResourceGroup);

        // [GIVEN] SAve Resource Group and JOob task in a variable.
        ResourceGroupNo := ResourceGroup."No.";
        JobTaskNo := JobTask."Job Task No.";

        // [GIVEN] Create Price List Header and it's Price List Line.
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Sale, PriceListHeader."Source Type"::"Job Task", Job."No.", JobTask."Job Task No.");
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::"Resource Group", ResourceGroupNo);

        // [WHEN] Rename the Resource Group No. 
        ResourceGroup.Get(ResourceGroupNo);
        ResourceGroup.Rename(LibraryUtility.GenerateGUID());

        // [WHEN] Rename the Job task No
        JobTask.Get(Job."No.", JobTaskNo);
        JobTask.Rename(JobTask."Job No.", LibraryUtility.GenerateGUID());

        // [THEN] Verify Resource Group is updated in Price List Line.
        PriceListLine.Find();
        Assert.AreEqual(ResourceGroup."No.", PriceListLine."Product No.", ResourceNoErr);

        // [THEN] Verify the Assign-to No. is updated in Price List Line
        Assert.AreEqual(JobTask."Job Task No.", PriceListLine."Assign-to No.", AssignToNoErr);
    end;

    [Test]
    procedure VerifyValuesOnPriceListHeaderAndPriceListLineWhenItemAndGLAccountRename()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLineItem: Record "Price List Line";
        PriceListLineGLAcc: Record "Price List Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        Item: Record Item;
        GLAccount: Record "G/L Account";
        ItemNo: Code[20];
        GLAccNo: Code[20];
    begin
        // [SCENARIO 458555] Item and G/L Account and Assign-to No. on the Price List Lines page are not renamed
        Initialize();

        // [GIVEN] Create 2 Jobs with Job Tasks and Create Resource.
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Create Item and G/L Account
        ItemNo := LibraryInventory.CreateItemNo();
        GLAccNo := LibraryERM.CreateGLAccountNo();

        // [GIVEN] Create Price List Header and it's Price List Line.
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Sale, PriceListHeader."Source Type"::"Job Task", Job."No.", JobTask."Job Task No.");
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLineItem, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::"Item", ItemNo);
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLineGLAcc, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::"G/L Account", GLAccNo);

        // [WHEN] Rename the Item
        Item.Get(ItemNo);
        Item.Rename(LibraryUtility.GenerateGUID());

        // [WHEN] Rename the G/L Account
        GLAccount.Get(GLAccNo);
        GLAccount.Rename(LibraryUtility.GenerateGUID());

        // [THEN] Verify Item No. is updated in Price List Line.
        PriceListLineItem.Find();
        Assert.AreEqual(Item."No.", PriceListLineItem."Product No.", 'Item No. is not updated');

        // [THEN] Verify G/L Account No. is updated in Price List Line.
        PriceListLineGLAcc.Find();
        Assert.AreEqual(GLAccount."No.", PriceListLineGLAcc."Product No.", 'G/L Account No. is not updated');
    end;

    [Test]
    procedure VerifyPriceListLineforJobTaskAfterCopyJob()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListLine2: Record "Price List Line";
        ResourceGroup: Record "Resource Group";
        Job: Record Job;
        JobTask: Record "Job Task";
        CopyJob: Codeunit "Copy Job";
        TargetJobNo: Code[20];
    begin
        // [SCENARIO 458131] The Assign-to Job No.  on the Price List Lines page is incorrect, if the job is created by ‘Copy Job.’
        Initialize();

        // [GIVEN] Creat Jobs with Job Tasks and Create Resource.
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryResource.CreateResourceGroup(ResourceGroup);

        // [GIVEN] Create Price List Header and it's Price List Line.
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Sale, PriceListHeader."Source Type"::"Job Task", Job."No.", JobTask."Job Task No.");
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::"Resource Group", ResourceGroup."No.");

        // [GIVEN] Set "Allow Updating Defaults" as true to copy price list line for copy job
        PriceListHeader.Validate("Allow Updating Defaults", true);
        PriceListHeader.Modify();

        // [THEN] Copy Job 
        TargetJobNo := IncStr(Job."No.");
        CopyJob.SetCopyOptions(true, false, false, 0, 0, 0);
        CopyJob.CopyJob(Job, TargetJobNo, '', '', '');

        // [VERIFY] Verify New Job No on "Assign-to Parent No."
        PriceListLine2.Reset();
        PriceListLine2.SetRange("Source Type", PriceListLine2."Source Type"::"Job Task");
        PriceListLine2.SetRange("Parent Source No.", Job."No.");
        Assert.RecordCount(PriceListLine2, 1);
    end;

    [Test]
    procedure VerifyPriceListLineforJobAfterCopyJob()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListLine2: Record "Price List Line";
        ResourceGroup: Record "Resource Group";
        Job: Record Job;
        JobTask: Record "Job Task";
        CopyJob: Codeunit "Copy Job";
        TargetJobNo: Code[20];
    begin
        // [SCENARIO 458131] The Assign-to Job No.  on the Price List Lines page is incorrect, if the job is created by ‘Copy Job.’
        Initialize();

        // [GIVEN] Creat Jobs with Job Tasks and Create Resource.
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryResource.CreateResourceGroup(ResourceGroup);

        // [GIVEN] Create Price List Header and it's Price List Line.
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Sale, PriceListHeader."Source Type"::Job, '', Job."No.");
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::"Resource Group", ResourceGroup."No.");

        // [GIVEN] Set "Allow Updating Defaults" as true to copy price list line for copy job
        PriceListHeader.Validate("Allow Updating Defaults", true);
        PriceListHeader.Modify();

        // [THEN] Copy Job 
        TargetJobNo := IncStr(Job."No.");
        CopyJob.SetCopyOptions(true, false, false, 0, 0, 0);
        CopyJob.CopyJob(Job, TargetJobNo, '', '', '');

        // [VERIFY] Verify New Job No on "Assign-to Parent No."
        PriceListLine2.Reset();
        PriceListLine2.SetRange("Source Type", PriceListLine2."Source Type"::Job);
        PriceListLine2.SetRange("Source No.", Job."No.");
        Assert.RecordCount(PriceListLine2, 1);
    end;

    [Test]
    procedure VarifyFieldsOnSalesJobPriceListsPage()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        ResourceGroup: Record "Resource Group";
        Job: Record Job;
        JobTask: Record "Job Task";
        SalesJobPriceList: TestPage "Sales Job Price Lists";
    begin
        // [SCENARIO 460320] Assign-to Type, Assign-to and Assign-to Job No. fields have incorrect values in Sales Price Job List page
        Initialize(true);

        // [GIVEN] Create Jobs with Job Tasks and Create Resource.
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryResource.CreateResourceGroup(ResourceGroup);

        // [GIVEN] Create Price List Header and it's Price List Line.
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Sale, PriceListHeader."Source Type"::Job, '', Job."No.");
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::"Resource Group", ResourceGroup."No.");

        // [GIVEN] Set "Allow Updating Defaults" as true
        PriceListHeader.Validate("Allow Updating Defaults", true);
        PriceListHeader.Modify();

        // [WHEN] Trap and Run Sales Job Price Lists page
        SalesJobPriceList.Trap();
        Page.Run(Page::"Sales Job Price Lists", PriceListHeader);
        SalesJobPriceList.Code.Activate();

        // [VERIFY] Verify: Assign-to Type, Assign-to and Assign-to Job No. fields Sales Job Price Lists page is same as on Price List Header record
        Assert.AreEqual(SalesJobPriceList.SourceType.Value, Format(PriceListHeader."Source Type"), StrSubstNo(JobPriceListFieldErr, SalesJobPriceList.SourceType.Caption));
        Assert.AreEqual(SalesJobPriceList.SourceNo.Value, Format(PriceListHeader."Source No."), StrSubstNo(JobPriceListFieldErr, SalesJobPriceList.SourceNo.Caption));
        Assert.AreEqual(SalesJobPriceList.ParentSourceNo.Value, Format(PriceListHeader."Parent Source No."), StrSubstNo(JobPriceListFieldErr, SalesJobPriceList.ParentSourceNo.Caption));
    end;

    [Test]
    procedure VarifyFieldsOnPurchaseJobPriceListsPage()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        ResourceGroup: Record "Resource Group";
        Job: Record Job;
        JobTask: Record "Job Task";
        PurchaseJobPriceList: TestPage "Purchase Job Price Lists";
    begin
        // [SCENARIO 460320] Assign-to Type, Assign-to and Assign-to Job No. fields have incorrect values in Purchase Price Job List page
        Initialize(true);

        // [GIVEN] Create Jobs with Job Tasks and Create Resource.
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryResource.CreateResourceGroup(ResourceGroup);

        // [GIVEN] Create Price List Header and it's Price List Line.
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Purchase, PriceListHeader."Source Type"::Job, '', Job."No.");
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::"Resource Group", ResourceGroup."No.");

        // [GIVEN] Set "Allow Updating Defaults" as true
        PriceListHeader.Validate("Allow Updating Defaults", true);
        PriceListHeader.Modify();

        // [WHEN] Trap and Run Purchase Job Price Lists page
        PurchaseJobPriceList.Trap();
        Page.Run(Page::"Purchase Job Price Lists", PriceListHeader);
        PurchaseJobPriceList.Code.Activate();

        // [VERIFY] Verify: Assign-to Type, Assign-to and Assign-to Job No. fields Purchase Job Price Lists page is same as on Price List Header record
        Assert.AreEqual(PurchaseJobPriceList.SourceType.Value, Format(PriceListHeader."Source Type"), StrSubstNo(JobPriceListFieldErr, PurchaseJobPriceList.SourceType.Caption));
        Assert.AreEqual(PurchaseJobPriceList.SourceNo.Value, Format(PriceListHeader."Source No."), StrSubstNo(JobPriceListFieldErr, PurchaseJobPriceList.SourceNo.Caption));
        Assert.AreEqual(PurchaseJobPriceList.ParentSourceNo.Value, Format(PriceListHeader."Parent Source No."), StrSubstNo(JobPriceListFieldErr, PurchaseJobPriceList.ParentSourceNo.Caption));
    end;

    [Test]
    procedure VerifyVATProdPostingGroupFromItemOnPriceListLine()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        Item: Record Item;
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [SCENARIO 458626] "VAT Prod. Posting Group" in Purchase Price List Line and Sales price list
        Initialize();

        // [GIVEN] Create VAT Business Posting and update Sales Receivable Setup
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        UpdateSalesReceivablesSetup(VATBusinessPostingGroup.Code);

        // [GIVEN] Create Item and create VAT Posting Setup
        LibraryInventory.CreateItem(Item);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, Item."VAT Prod. Posting Group");

        // [GIVEN] Update Price Including VAT as true and VAT Bus. Posting GR. (Price)
        Item.Validate("Price Includes VAT", true);
        Item.Validate("VAT Bus. Posting Gr. (Price)", VATBusinessPostingGroup.Code);
        Item.Modify();

        // [GIVEN] Create new Price Header
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Sale, PriceListHeader."Source Type"::"All Customers", '', '');

        // [GIVEN] Create New Price List line
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::Item, Item."No.");

        // [WHEN] Insert Product No. as created new Item no
        PriceListLine.Validate("Product No.", Item."No.");
        PriceListLine.Modify();

        // [VERIFY] Verify VAT Prod. Posting Group has been updated from Item
        Assert.AreEqual(Item."VAT Prod. Posting Group", PriceListLine."VAT Prod. Posting Group", VATProdPostingGroupErr);
    end;

    [Test]
    procedure VerifyAmountTypeAnyIsNotAllowedForCustomerPriceGroupInPriceList()
    var
        PriceListHeader: Record "Price List Header";
        CustomerPriceGroup: Record "Customer Price Group";
    begin
        // [SCENARIO 473523] Verify that the customer won't be able to choose Price & Discount if Assign-to Type is Customer Price Group.
        Initialize();

        // [GIVEN] Create a Customer Price Group.
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);

        // [GIVEN] Create a Price Header.
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader,
            "Price Type"::Sale,
            "Price Source Type"::"Customer Price Group",
            CustomerPriceGroup.Code);

        // [GIVEN] Set Allow Updating Defaults to true in the Price List Header.
        PriceListHeader.Validate("Allow Updating Defaults", true);
        PriceListHeader.Modify(true);

        // [WHEN] Not allowed to validate Amount Type "Price & Discount" for Customer Price Group.
        asserterror PriceListHeader.Validate("Amount Type", PriceListHeader."Amount Type"::Any);

        // [VERIFY] Verify: Amount Type "Price & Discount" is not allowed if the Assign-to Type is Customer Price Group. 
        Assert.ExpectedError(
            StrSubstNo(
                AmountTypeNotAllowedForSourceTypeErr,
                PriceListHeader."Amount Type"::Any,
                PriceListHeader."Source Type"));
    end;

    [Test]
    procedure VerifyAmountTypeAnyIsNotAllowedForCustomerDiscGroupInPriceList()
    var
        PriceListHeader: Record "Price List Header";
        CustomerDiscountGroup: Record "Customer Discount Group";
    begin
        // [SCENARIO 473523] Verify that the customer won't be able to choose Price & Discount if Assign-to Type is Customer Discount Group.
        Initialize();

        // [GIVEN] Create a Customer Discount Group.
        LibraryERM.CreateCustomerDiscountGroup(CustomerDiscountGroup);

        // [GIVEN] Create a Price Header.
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader,
            "Price Type"::Sale,
            "Price Source Type"::"Customer Disc. Group",
            CustomerDiscountGroup.Code);

        // [GIVEN] Set Allow Updating Defaults to true in the Price List Header.
        PriceListHeader.Validate("Allow Updating Defaults", true);
        PriceListHeader.Modify(true);

        // [WHEN] Not allowed to validate Amount Type "Price & Discount" for Customer Discount Group.
        asserterror PriceListHeader.Validate("Amount Type", PriceListHeader."Amount Type"::Any);

        // [VERIFY] Verify: Amount Type "Price & Discount" is not allowed if the Assign-to Type is Customer Discount Group. 
        Assert.ExpectedError(
            StrSubstNo(
                AmountTypeNotAllowedForSourceTypeErr,
                PriceListHeader."Amount Type"::Any,
                PriceListHeader."Source Type"));
    end;

    [Test]
    procedure VariantCodeMustBeBlankWhenInsertNewRecord()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        SalesPriceList: TestPage "Sales Price List";
    begin
        // [SCENARIO 537505] When creating a new price for variant items the variant code does not automatically display in the price list based on the previously created line.
        Initialize(true);

        // [GIVEN] Create a Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Item Variant.
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [GIVEN] Create Sales Price Header with Price Type Sales and Source Type All Customers.
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader,
            PriceListHeader."Price Type"::Sale,
            PriceListHeader."Source Type"::"All Customers",
            '');

        // [GIVEN] Create a Price Line.
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine,
            PriceListHeader,
            "Price Amount Type"::Price,
            "Price Asset Type"::Item,
            Item."No.");

        // [GIVEN] Validate a Variant Code.
        PriceListLine.Validate("Variant Code", ItemVariant.Code);
        PriceListLine.Modify();

        // [GIVEN] Open Sales Price List Page and insert new Line.
        SalesPriceList.OpenEdit();
        SalesPriceList.GoToRecord(PriceListHeader);
        SalesPriceList.Lines.New();
        SalesPriceList.Lines."Product No.".SetValue(Item."No.");

        // [THEN] The value of Variant Code in new line must be empty.
        Assert.AreEqual('', SalesPriceList.Lines."Variant Code".Value(), VariantCodeErr);
    end;

    local procedure Initialize()
    begin
        Initialize(false);
    end;

    local procedure Initialize(Enable: Boolean)
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Price List Line UT");
        LibraryVariableStorage.Clear();
        LibraryPriceCalculation.EnableExtendedPriceCalculation(Enable);
        LibraryPriceCalculation.SetUseCustomLookup(true);

        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Price List Line UT");
        LibraryERM.SetBlockDeleteGLAccount(false);
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Price List Line UT");
    end;

    local procedure CreateAssetDiscLines(AssetType: Enum "Price Asset Type"; AssetNo1: Code[20]; AssetNo2: Code[20])
    var
        PriceListLine: Record "Price List Line";
    begin
        PriceListLine.DeleteAll();
        LibraryPriceCalculation.CreateSalesDiscountLine(
            PriceListLine, '', "Price Source Type"::"All Customers", '', AssetType, AssetNo1);
        LibraryPriceCalculation.CreateSalesDiscountLine(
            PriceListLine, '', "Price Source Type"::"All Customers", '', AssetType, AssetNo2);
    end;

    local procedure CreateAssetPriceLines(AssetType: Enum "Price Asset Type"; AssetNo1: Code[20]; AssetNo2: Code[20])
    var
        PriceListLine: Record "Price List Line";
    begin
        PriceListLine.DeleteAll();
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, '', "Price Source Type"::"All Customers", '', AssetType, AssetNo1);
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, '', "Price Source Type"::"All Customers", '', AssetType, AssetNo2);
    end;

    local procedure CreatePriceLinesWithUOM(UOM1: Code[20]; UOM2: Code[20])
    var
        GLAccount: Record "G/L Account";
        PriceListLine: Record "Price List Line";
    begin
        PriceListLine.DeleteAll();
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, '', "Price Source Type"::"All Customers", '', "Price Asset Type"::"G/L Account", GLAccount."No.");
        PriceListLine."Unit of Measure Code" := UOM1;
        PriceListLine."Unit of Measure Code Lookup" := UOM1;
        PriceListLine.Modify();
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, '', "Price Source Type"::"All Customers", '', "Price Asset Type"::"G/L Account", GLAccount."No.");
        PriceListLine."Unit of Measure Code" := UOM2;
        PriceListLine."Unit of Measure Code Lookup" := UOM2;
        PriceListLine.Modify();
    end;

    local procedure CreateAssetPriceLines(ItemNo: Code[20]; VariantCode1: Code[10]; VariantCode2: Code[10])
    var
        PriceListLine: Record "Price List Line";
    begin
        PriceListLine.DeleteAll();
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, '', "Price Source Type"::"All Customers", '', "Price Asset Type"::Item, ItemNo);
        PriceListLine.Validate("Variant Code", VariantCode1);
        PriceListLine.Modify();
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, '', "Price Source Type"::"All Customers", '', "Price Asset Type"::Item, ItemNo);
        PriceListLine.Validate("Variant Code", VariantCode2);
        PriceListLine.Modify();
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
        PriceListLine: Record "Price List Line";
    begin
        PriceListLine.SetRange("Asset Type", AssetType);
        PriceListLine.SetRange("Asset No.", AssetNo2);
        Assert.RecordCount(PriceListLine, 1);
        PriceListLine.SetRange("Asset No.", AssetNo1);
        Assert.RecordIsEmpty(PriceListLine);
    end;

    local procedure VerifyDeletedAssetPrices(ItemNo: Code[20]; VariantCode1: Code[10]; VariantCode2: Code[10])
    var
        PriceListLine: Record "Price List Line";
    begin
        PriceListLine.SetRange("Asset Type", "Price Asset Type"::Item);
        PriceListLine.SetRange("Asset No.", ItemNo);
        PriceListLine.SetRange("Variant Code", VariantCode2);
        Assert.RecordCount(PriceListLine, 1);
        PriceListLine.SetRange("Variant Code", VariantCode1);
        Assert.RecordIsEmpty(PriceListLine);
    end;

    local procedure VerifyRenamedAssetPrices(AssetType: Enum "Price Asset Type"; AssetNo1: Code[20]; AssetNo2: Code[20]; OldAssetNo: Code[20])
    var
        PriceListLine: Record "Price List Line";
    begin
        PriceListLine.SetRange("Asset Type", AssetType);
        PriceListLine.SetRange("Asset No.", AssetNo1);
        Assert.RecordCount(PriceListLine, 1);
        PriceListLine.SetRange("Asset No.", AssetNo2);
        Assert.RecordCount(PriceListLine, 1);
        PriceListLine.SetRange("Asset No.", OldAssetNo);
        Assert.RecordIsEmpty(PriceListLine);
    end;

    local procedure VerifyRenamedAssetPrices(ItemNo: Code[20]; VariantCode1: Code[10]; VariantCode2: Code[10]; OldVariantCode: Code[10])
    var
        PriceListLine: Record "Price List Line";
    begin
        PriceListLine.SetRange("Asset Type", "Price Asset Type"::Item);
        PriceListLine.SetRange("Asset No.", ItemNo);
        PriceListLine.SetRange("Variant Code", VariantCode1);
        PriceListLine.SetRange("Variant Code Lookup", VariantCode1);
        Assert.RecordCount(PriceListLine, 1);
        PriceListLine.SetRange("Variant Code", VariantCode2);
        PriceListLine.SetRange("Variant Code Lookup", VariantCode2);
        Assert.RecordCount(PriceListLine, 1);
        PriceListLine.SetRange("Variant Code", OldVariantCode);
        PriceListLine.SetRange("Variant Code Lookup", OldVariantCode);
        Assert.RecordIsEmpty(PriceListLine);
    end;

    local procedure VerifyRenamedUOMs(UOM1: Code[20]; UOM2: Code[20]; OldUOM: Code[20])
    var
        PriceListLine: Record "Price List Line";
    begin
        PriceListLine.SetRange("Unit of Measure Code", UOM1);
        PriceListLine.SetRange("Unit of Measure Code Lookup", UOM1);
        Assert.RecordCount(PriceListLine, 1);
        PriceListLine.SetRange("Unit of Measure Code", UOM2);
        PriceListLine.SetRange("Unit of Measure Code Lookup", UOM2);
        Assert.RecordCount(PriceListLine, 1);
        PriceListLine.SetRange("Unit of Measure Code", OldUOM);
        PriceListLine.SetRange("Unit of Measure Code Lookup", OldUOM);
        Assert.RecordIsEmpty(PriceListLine);
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

    local procedure VerifyLineVariant(PriceListLine: Record "Price List Line"; UoM: Code[10]; AllowInvoiceDisc: Boolean; PriceIncludesVAT: Boolean; VATBusPostingGr: Code[20]; VariantCode: Code[10]; WorkTypeCode: Code[10]; CurrencyCode: Code[10])
    begin
        PriceListLine.TestField("Unit of Measure Code", UoM);
        PriceListLine.TestField("Variant Code", VariantCode);
        PriceListLine.TestField("Allow Invoice Disc.", AllowInvoiceDisc);
        PriceListLine.TestField("Price Includes VAT", PriceIncludesVAT);
        PriceListLine.TestField("VAT Bus. Posting Gr. (Price)", VATBusPostingGr);
        PriceListLine.TestField("Work Type Code", WorkTypeCode);
        PriceListLine.TestField("Currency Code", CurrencyCode);
    end;

    local procedure VerifyLine(PriceListLine: Record "Price List Line"; AllowLineDisc: Boolean; PriceIncludesVAT: Boolean; VATBusPostingGr: Code[20]; CurrencyCode: Code[10])
    begin
        PriceListLine.TestField("Currency Code", CurrencyCode);
        PriceListLine.TestField("Allow Line Disc.", AllowLineDisc);
        PriceListLine.TestField("Price Includes VAT", PriceIncludesVAT);
        PriceListLine.TestField("VAT Bus. Posting Gr. (Price)", VATBusPostingGr);
    end;

    local procedure VerifyLine(PriceListLine: Record "Price List Line"; AllowLineDisc: Boolean; PriceIncludesVAT: Boolean; VATBusPostingGr: Code[20]; AlloInvDisc: Boolean)
    begin
        PriceListLine.TestField("Allow Invoice Disc.", AlloInvDisc);
        PriceListLine.TestField("Allow Line Disc.", AllowLineDisc);
        PriceListLine.TestField("Price Includes VAT", PriceIncludesVAT);
        PriceListLine.TestField("VAT Bus. Posting Gr. (Price)", VATBusPostingGr);
    end;

    local procedure VerifyLine(PriceListLine: Record "Price List Line"; StartingDate: Date; EndingDate: Date)
    begin
        PriceListLine.TestField("Starting Date", StartingDate);
        PriceListLine.TestField("Ending Date", EndingDate);
    end;

    local procedure CreateItemWithVariant(var Item: Record Item; var ItemVariant: Record "Item Variant")
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
    end;

    local procedure CreateNewSalesPriceListLine(var SalesPriceList: TestPage "Sales Price List"; ItemNo: Code[20]; VariantCode: Code[10])
    begin
        SalesPriceList.Lines.New();
        SalesPriceList.Lines."Product No.".SetValue(ItemNo);
        if VariantCode <> '' then
            SalesPriceList.Lines."Variant Code".SetValue(VariantCode);
    end;

    local procedure UpdateSalesReceivablesSetup(VATBusinessPostingGroup: Code[20])
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("VAT Bus. Posting Gr. (Price)", VATBusinessPostingGroup);
        SalesReceivablesSetup.Modify(true);
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

    [SendNotificationHandler]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    begin
        LibraryVariableStorage.Enqueue(Notification.Message);
    end;
}
