codeunit 134118 "Price List Header UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Price Calculation] [Price List Header]
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
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        StartingDateErr: Label 'Starting Date %1 cannot be after Ending Date %2.', Comment = '%1 and %2 - dates';
        CampaignDateErr: Label 'If Source Type is Campaign, then you can only change Starting Date and Ending Date from the Campaign Card.';
        CodeMustNotBeBlankErr: Label 'Code must have a value in Price List';
        DateConfirmQst: Label 'Do you want to update %1 in the price list lines?', Comment = '%1 - the field caption';
        LinesExistErr: Label 'You cannot change %1 because one or more lines exist.', Comment = '%1 - Field caption';
        StatusUpdateQst: Label 'Do you want to update status to %1?', Comment = '%1 - status value: Draft, Active, or Inactive';
        CannotDeleteActivePriceListErr: Label 'You cannot delete the active price list %1.', Comment = '%1 - the price list code.';
        ParentSourceJobErr: Label 'Parent Source No. must be blank for Project source type.';
        CustomParentSourceNoMustBeFilledErr: Label 'Assign-to Parent No. (custom) must have a value';
        JobsParentSourceNoMustBeFilledErr: Label 'Assign-to Parent No. (projects) must have a value';
        SourceNoCustomMustBeFilledErr: Label 'Assign-to No. (custom) must have a value';
        MissingPriceListCodeErr: Label '%1 must have a value', Comment = '%1 - field caption.';
        CannotRenameErr: Label 'You cannot rename a %1.', Comment = '%1 - table caption';
        IsInitialized: Boolean;
        ResourceNoErr: Label 'Resource No. is not updated';
        SourceNoErr: Label 'Invalid Source No.';
        AssignToNoErr: Label 'Invalid Assign-to No.';
        UnitCostErr: Label 'Invalid Unit Cost';

    [Test]
    procedure T001_ManualCode()
    var
        PriceListHeader: Record "Price List Header";
    begin
        Initialize();
        PriceListHeader."Source Group" := PriceListHeader."Source Group"::Customer;

        PriceListHeader.Validate(Code, LibraryUtility.GenerateGUID());
        PriceListHeader.Insert(true);

        PriceListHeader.Testfield(Code);
        PriceListHeader.TestField("No. Series", '');
        PriceListHeader.TestField("Amount Type", "Price Amount Type"::Any);
    end;

    [Test]
    procedure T002_CodeBySalesNoSeriesOnInsert()
    var
        PriceListHeader: Record "Price List Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        Initialize();
        PriceListHeader.DeleteAll();

        PriceListHeader."Source Group" := PriceListHeader."Source Group"::Customer;
        PriceListHeader.Insert(true);

        PriceListHeader.Testfield(Code);
        PriceListHeader.TestField("Amount Type", "Price Amount Type"::Any);
        SalesReceivablesSetup.Get();
        PriceListHeader.TestField("No. Series", SalesReceivablesSetup."Price List Nos.");
    end;

    [Test]
    procedure T003_CodeByPurchaseNoSeriesOnInsert()
    var
        PriceListHeader: Record "Price List Header";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        Initialize();
        PriceListHeader.DeleteAll();

        PriceListHeader."Source Group" := PriceListHeader."Source Group"::Vendor;
        PriceListHeader.Insert(true);

        PriceListHeader.Testfield(Code);
        PriceListHeader.TestField("Amount Type", "Price Amount Type"::Any);
        PurchasesPayablesSetup.Get();
        PriceListHeader.TestField("No. Series", PurchasesPayablesSetup."Price List Nos.");
    end;

    [Test]
    procedure T004_CodeByJobsNoSeriesOnInsert()
    var
        PriceListHeader: Record "Price List Header";
        JobsSetup: Record "Jobs Setup";
    begin
        Initialize();
        PriceListHeader.DeleteAll();

        PriceListHeader."Source Group" := PriceListHeader."Source Group"::Job;
        PriceListHeader.Insert(true);

        PriceListHeader.Testfield(Code);
        PriceListHeader.TestField("Amount Type", "Price Amount Type"::Any);
        JobsSetup.Get();
        PriceListHeader.TestField("No. Series", JobsSetup."Price List Nos.");
    end;

    [Test]
    procedure T005_CodeByAllNoSeriesOnInsert()
    var
        PriceListHeader: Record "Price List Header";
    begin
        Initialize();
        PriceListHeader."Source Group" := PriceListHeader."Source Group"::All;
        asserterror PriceListHeader.Insert(true);
        Assert.ExpectedError(CodeMustNotBeBlankErr);
    end;

    [Test]
    procedure T006_DeleteLineOnHeaderDeletion()
    var
        PriceListHeader: array[2] of Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        Initialize();
        PriceListHeader[1].DeleteAll();
        PriceListLine.DeleteAll();

        // [GIVEN] Price list header, where "Code" is 'X' has two lines
        PriceListHeader[1].Init();
        PriceListHeader[1]."Source Group" := PriceListHeader[1]."Source Group"::Job;
        PriceListHeader[1].Insert(true);
        PriceListLine."Price List Code" := PriceListHeader[1].Code;
        PriceListLine."Line No." := 0;
        PriceListLine.Insert();
        PriceListLine."Line No." := 0;
        PriceListLine.Insert();

        // [GIVEN] Price list header, where "Code" is 'Y' has one lines
        PriceListHeader[2].Init();
        PriceListHeader[2]."Source Group" := PriceListHeader[2]."Source Group"::Job;
        PriceListHeader[2].Insert(true);
        PriceListLine."Price List Code" := PriceListHeader[2].Code;
        PriceListLine."Line No." := 0;
        PriceListLine.Insert();

        // [WHEN] Delete header 'X'
        PriceListHeader[1].Delete(true);

        // [THEN] Lines, where "Price List Code" is 'X', are deleted
        PriceListLine.SetRange("Price List Code", PriceListHeader[1].Code);
        Assert.RecordIsEmpty(PriceListLine);
        // [THEN] Line, where "Price List Code" is 'Y', is not deleted
        PriceListLine.SetRange("Price List Code", PriceListHeader[2].Code);
        Assert.RecordIsNotEmpty(PriceListLine);
    end;

    [Test]
    procedure T007_CannotRenamePriceListHeader()
    var
        PriceListHeader: Record "Price List Header";
    begin
        Initialize();
        PriceListHeader.Code := LibraryUtility.GenerateGUID();
        PriceListHeader."Source Group" := PriceListHeader."Source Group"::Customer;
        PriceListHeader.Insert();

        asserterror PriceListHeader.Rename(LibraryUtility.GenerateGUID());
        Assert.ExpectedError(StrSubstNo(CannotRenameErr, PriceListHeader.TableCaption()));
    end;

    [Test]
    procedure T008_CannotRenameOnCodeValidatePriceListHeader()
    var
        PriceListHeader: Record "Price List Header";
    begin
        Initialize();
        PriceListHeader."Source Group" := PriceListHeader."Source Group"::Customer;
        PriceListHeader.Validate(Code, LibraryUtility.GenerateGUID());
        asserterror PriceListHeader.Validate(Code, LibraryUtility.GenerateGUID());
        Assert.ExpectedError(StrSubstNo(CannotRenameErr, PriceListHeader.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('LookupCustomerModalHandler')]
    procedure T009_LookupSourceNoCustomer()
    var
        PriceListHeader: Record "Price List Header";
        MockPriceListHeader: TestPage "Mock Price List Header";
        SourceNo: Code[20];
    begin
        // [FEATURE] [Customer] [UI]
        Initialize();
        // [GIVEN] Header, where "Source Type" is 'All Customers'
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Sale, PriceListHeader."Source Type"::"All Customers", '');
        Commit();
        // [GIVEN] Open Price List Header page and set "Source Type" as 'Customer'
        MockPriceListHeader.Trap();
        PriceListHeader.SetRecFilter();
        Page.Run(Page::"Mock Price List Header", PriceListHeader);
        MockPriceListHeader."Source Type".SetValue(PriceListHeader."Source Type"::Customer);

        // [WHEN] Lookup "Source No." to pick Customer 'X'
        SourceNo := LibrarySales.CreateCustomerNo();
        LibraryVariableStorage.Enqueue(SourceNo); // CustomerNo to LookupCustomerModalHandler
        MockPriceListHeader."Source No.".Lookup();
        MockPriceListHeader.Close();

        // [THEN] Header, where "Source Type" is Customer, "Source No." is 'X'
        PriceListHeader.Find();
        PriceListHeader.TestField("Source No.", SourceNo);
    end;

    [Test]
    procedure T010_ChangedSourceTypeValidation()
    var
        PriceListHeader: Record "Price List Header";
    begin
        Initialize();
        // [GIVEN] Price List Header, where all fields are filled, "Source Type" = 'Job Task'
        NewSourceJobTask(PriceListHeader);

        // [WHEN] Validate "Source Type" as 'Vendor'
        PriceListHeader.Validate("Source Type", PriceListHeader."Source Type"::Vendor);

        // [THEN] "Source No.", "Parent Source No.", "Source ID" are blank, "Source Type" = 'Vendor', "Source Group" =  'Vendor'
        PriceListHeader.Testfield("Source Type", PriceListHeader."Source Type"::Vendor);
        PriceListHeader.Testfield("Source Group", PriceListHeader."Source Group"::Vendor);
        VerifyBlankSource(PriceListHeader);
    end;

    [Test]
    procedure T011_SourceTypeCannotBeChangedIfLinesExist()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        Initialize();
        // [GIVEN] Price List Header, where "Source Type" = 'All Customers'
        CreatePriceList(PriceListHeader, PriceListLine);
        // [WHEN] Change "Source Type" to 'Customer'
        asserterror PriceListHeader.Validate("Source Type", PriceListHeader."Source Type"::Customer);
        // [THEN] Error message: 'You cannot update Source Type because lines exist.'
        Assert.ExpectedError(StrSubstNo(LinesExistErr, PriceListHeader.FieldCaption("Source Type")));
    end;

    [Test]
    procedure T012_SourceNoCannotBeChangedIfLinesExist()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        Initialize();
        // [GIVEN] Price List Header, where "Source Type" = 'All Customers'
        CreatePriceList(PriceListHeader, PriceListLine);
        // [WHEN] Change "Source Type" to 'Customer'
        asserterror PriceListHeader.Validate("Source No.", LibrarySales.CreateCustomerNo());
        // [THEN] Error message: 'You cannot update Source No. because lines exist.'
        Assert.ExpectedError(StrSubstNo(LinesExistErr, PriceListHeader.FieldCaption("Source No.")));
    end;

    [Test]
    procedure T015_JobTask_ChangedSourceNoValidation()
    var
        NewPriceListHeader: Record "Price List Header";
        PriceListHeader: Record "Price List Header";
        PriceListHeaderPreStartingDateChange: Record "Price List Header";
        JobNo: Code[20];
    begin
        // [FEATURE] [Job Task]
        // [SCENARIO 486161] "Filter Source No." value is not changed when changing "Starting Date" on the price list.
        Initialize();
        // [GIVEN] Price Source, where "Source Type" = 'Job Task', "Job Task No." is 'JT', Job No." is 'J'
        NewSourceJobTask(PriceListHeader);
        JobNo := PriceListHeader."Parent Source No.";

        // [GIVEN] JobTask, where "Job Task No." is 'X', Job No." is 'J', SystemId is 'A'
        NewPriceListHeader."Parent Source No." := JobNo;
        NewSourceJobTask(NewPriceListHeader);

        // [WHEN] Validate "Source No." as 'X'
        PriceListHeader.Validate("Source No.", NewPriceListHeader."Source No.");

        // [THEN] "Source No." is 'X', "Parent Source No." = 'J', "Source ID" is 'A', "Source Type" = 'Job Task'
        PriceListHeader.Testfield("Source Type", PriceListHeader."Source Type"::"Job Task");
        PriceListHeader.Testfield("Parent Source No.", JobNo);
        PriceListHeader.Testfield("Source No.", NewPriceListHeader."Source No.");
        PriceListHeader.Testfield("Source ID", NewPriceListHeader."Source ID");

        // [WHEN] Set "Starting Date" as Today
        PriceListHeaderPreStartingDateChange := PriceListHeader;
        PriceListHeader.Validate("Starting Date", Today());

        // [THEN] "Filter Source No." and other values are not changed
        PriceListHeader.TestField("Filter Source No.", PriceListHeaderPreStartingDateChange."Filter Source No.");
        PriceListHeader.Testfield("Source Type", PriceListHeader."Source Type"::"Job Task");
        PriceListHeader.Testfield("Parent Source No.", JobNo);
        PriceListHeader.Testfield("Source No.", NewPriceListHeader."Source No.");
        PriceListHeader.Testfield("Source ID", NewPriceListHeader."Source ID");
    end;

    [Test]
    procedure T016_JobTask_IsSourceNoAllowed()
    var
        PriceListHeader: Record "Price List Header";
    begin
        // [FEATURE] [Job Task]
        Initialize();
        PriceListHeader.Validate("Source Type", PriceListHeader."Source Type"::"Job Task");
        Assert.IsTrue(PriceListHeader.IsSourceNoAllowed(), 'IsSourceNoAllowed');
    end;

    [Test]
    procedure T020_ValidateStartingDateAfterEndingDate()
    var
        PriceListHeader: Record "Price List Header";
    begin
        Initialize();
        // [GIVEN] Price List Header, where  "Ending Date" is '310120'
        PriceListHeader.Init();
        PriceListHeader."Ending Date" := WorkDate();
        // [WHEN] Set "Starting Date" as '010220'
        asserterror PriceListHeader.Validate("Starting Date", PriceListHeader."Ending Date" + 1);

        // [THEN] Error message: 'Starting Date cannot be after Ending Date'
        Assert.ExpectedError(StrSubstNo(StartingDateErr, PriceListHeader."Ending Date" + 1, PriceListHeader."Ending Date"));
    end;

    [Test]
    procedure T021_ValidateEndingDateBeforeStartingDate()
    var
        PriceListHeader: Record "Price List Header";
    begin
        Initialize();
        // [GIVEN] Price List Header, where "Starting Date" is '010220'
        PriceListHeader.Init();
        PriceListHeader."Starting Date" := WorkDate();
        // [WHEN] Set "Ending Date" as '310120'
        asserterror PriceListHeader.Validate("Ending Date", PriceListHeader."Starting Date" - 1);

        // [THEN] Error message: 'Starting Date cannot be after Ending Date'
        Assert.ExpectedError(StrSubstNo(StartingDateErr, PriceListHeader."Starting Date", PriceListHeader."Starting Date" - 1));
    end;

    [Test]
    procedure T022_ChangeStartingDateWithMultipleLines()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO 426808] Updating "Starting Date" on the price list header does not modify "Ending Date" on the corresponding price list lines".
        Initialize();
        // [GIVEN] Price List with 2 lines, where "Starting Date" is '010220', "Ending Date" is '020320', "Allow Updating Defaults" is 'No'
        CreatePriceList(PriceListHeader, PriceListLine);
        PriceListHeader.TestField("Allow Updating Defaults", false);
        // [GIVEN] Price list lines are in 'Active' and 'Inactive' status (a mock to see Status change on the lines)
        PriceListLine.Status := "Price Status"::Active;
        PriceListLine."Ending Date" := PriceListLine."Ending Date" + 10;
        PriceListLine.Modify();
        PriceListLine."Line No." += 1;
        PriceListLine.Status := "Price Status"::Inactive;
        PriceListLine."Ending Date" := PriceListLine."Ending Date" - 5;
        PriceListLine.Insert();

        // [WHEN] Set "Starting Date" as '0D'
        PriceListHeader.Validate("Starting Date", 0D);

        // [THEN] both Price List Lines, got "Starting Date" from the header, Status is 'Draft'
        PriceListLine.SetRange("Price List Code", PriceListHeader.Code);
        PriceListLine.SetRange("Starting Date", PriceListHeader."Starting Date");
        PriceListLine.SetRange(Status, "Price Status"::Draft);
        Assert.RecordCount(PriceListLine, 2);

        // [THEN] both Price List Lines, did not get "Ending Date" from the header, Status is 'Draft'
        PriceListLine.SetRange("Ending Date", PriceListHeader."Ending Date");
        Assert.RecordCount(PriceListLine, 0);

        // [THEN] "Ending Date" is not changed on the lines
        PriceListLine.SetRange("Ending Date", PriceListHeader."Ending Date" + 10);
        Assert.RecordCount(PriceListLine, 1);
        PriceListLine.SetRange("Ending Date", PriceListHeader."Ending Date" + 5);
        Assert.RecordCount(PriceListLine, 1);
    end;

    [Test]
    procedure T023_ChangeEndingDateWithMultipleLines()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO 426808] Update of "Ending Date" on the price list copies both dates to all lines.
        Initialize();
        // [GIVEN] Price List with 2 lines, where "Starting Date" is '010220', "Ending Date" is '020320', "Allow Updating Defaults" is 'No'
        CreatePriceList(PriceListHeader, PriceListLine);
        PriceListHeader.TestField("Allow Updating Defaults", false);
        // [GIVEN] Price list lines are in 'Active' and 'Inactive' status (a mock to see Status change on the lines)
        PriceListLine.Status := "Price Status"::Active;
        PriceListLine."Starting Date" := PriceListLine."Starting Date" - 10;
        PriceListLine.Modify();
        PriceListLine."Line No." += 1;
        PriceListLine.Status := "Price Status"::Inactive;
        PriceListLine."Starting Date" := PriceListLine."Starting Date" + 5;
        PriceListLine.Insert();

        // [WHEN] Set "Ending Date" as 030320
        PriceListHeader.Validate("Ending Date", PriceListHeader."Ending Date" + 1);

        // [THEN] both Price List Lines, got "Ending Date" from the header, Status is 'Draft'
        PriceListLine.SetRange("Price List Code", PriceListHeader.Code);
        PriceListLine.SetRange("Ending Date", PriceListHeader."Ending Date");
        PriceListLine.SetRange(Status, "Price Status"::Draft);
        Assert.RecordCount(PriceListLine, 2);

        // [THEN] both Price List Lines, did not get "Starting Date" from the header, Status is 'Draft'
        PriceListLine.SetRange("Starting Date", PriceListHeader."Starting Date");
        Assert.RecordCount(PriceListLine, 0);

        // [THEN] "Starting Date" is not changed on the lines
        PriceListLine.SetRange("Starting Date", PriceListHeader."Starting Date" - 10);
        Assert.RecordCount(PriceListLine, 1);
        PriceListLine.SetRange("Starting Date", PriceListHeader."Starting Date" - 5);
        Assert.RecordCount(PriceListLine, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure T024_ChangeStartingDateWithLines()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        Initialize();
        // [GIVEN] Price List with one line, where "Starting Date" is '010220', "Allow Updating Defaults" is 'Yes'
        CreatePriceList(PriceListHeader, PriceListLine);
        PriceListHeader.Validate("Allow Updating Defaults", true);
        PriceListHeader.Modify();

        // [WHEN] Set "Starting Date" as '310120', answer 'Yes' to confirm
        PriceListHeader.Validate("Starting Date", PriceListHeader."Starting Date" - 1);

        // [THEN] Confirmation question: 'Do you want to update Starting Date'
        Assert.AreEqual(
            StrSubstNo(DateConfirmQst, PriceListHeader.FieldCaption("Starting Date")),
            LibraryVariableStorage.DequeueText(), 'Confirm question'); // from ConfirmYesHandler
        // [THEN] Price List Line, where "Starting Date" is '310120'
        PriceListLine.Find();
        PriceListLine.TestField("Starting Date", PriceListHeader."Starting Date");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure T025_ChangeEndingDateWithLines()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        Initialize();
        // [GIVEN] Price List with one line, where "Ending Date" is '300120', "Allow Updating Defaults" is 'Yes'
        CreatePriceList(PriceListHeader, PriceListLine);
        PriceListHeader.Validate("Allow Updating Defaults", true);
        PriceListHeader.Modify();

        // [WHEN] Set "Ending Date" as '310120', answer 'Yes' to confirm
        PriceListHeader.Validate("Ending Date", PriceListHeader."Ending Date" + 1);

        // [THEN] Confirmation question: 'Do you want to update Ending Date'
        Assert.AreEqual(
            StrSubstNo(DateConfirmQst, PriceListHeader.FieldCaption("Ending Date")),
            LibraryVariableStorage.DequeueText(), 'Confirm question'); // from ConfirmYesHandler
        // [THEN] Price List Line, where "Ending Date" is '310120'
        PriceListLine.Find();
        PriceListLine.TestField("Ending Date", PriceListHeader."Ending Date");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    procedure T026_ChangeStartingDateWithLinesConfirmNo()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        ExpectedDate: Date;
    begin
        Initialize();
        // [GIVEN] Price List with one line, where "Starting Date" is '010220', "Allow Updating Defaults" is 'Yes'
        CreatePriceList(PriceListHeader, PriceListLine);
        PriceListHeader.Validate("Allow Updating Defaults", true);
        PriceListHeader.Modify();

        // [WHEN] Set "Starting Date" as '310120', answer 'No' to confirm
        ExpectedDate := PriceListHeader."Starting Date";
        PriceListHeader.Validate("Starting Date", PriceListHeader."Starting Date" - 1);

        // [THEN] Confirmation question: 'Do you want to update Starting Date'
        Assert.AreEqual(
            StrSubstNo(DateConfirmQst, PriceListHeader.FieldCaption("Starting Date")),
            LibraryVariableStorage.DequeueText(), 'Confirm question'); // from ConfirmNoHandler
        // [THEN] Price List Hader, where "Starting Date" is changed to '310120'
        PriceListHeader.TestField("Starting Date", ExpectedDate - 1);
        // [THEN] Price List Line, where "Starting Date" is '010220'
        PriceListLine.Find();
        PriceListLine.TestField("Starting Date", ExpectedDate);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    procedure T027_ChangeEndingDateWithLinesConfirmNo()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        ExpectedDate: Date;
    begin
        Initialize();
        // [GIVEN] Price List with one line, where "Ending Date" is '300120', "Allow Updating Defaults" is 'Yes'
        CreatePriceList(PriceListHeader, PriceListLine);
        PriceListHeader.Validate("Allow Updating Defaults", true);
        PriceListHeader.Modify();

        // [WHEN] Set "Ending Date" as '310120', answer 'No' to confirm
        ExpectedDate := PriceListHeader."Ending Date";
        PriceListHeader.Validate("Ending Date", PriceListHeader."Ending Date" + 1);

        // [THEN] Confirmation question: 'Do you want to update Ending Date'
        Assert.AreEqual(
            StrSubstNo(DateConfirmQst, PriceListHeader.FieldCaption("Ending Date")),
            LibraryVariableStorage.DequeueText(), 'Confirm question'); // from ConfirmNoHandler
        // [THEN] Price List Hader, where "Ending Date" is changed to '310120'
        PriceListHeader.TestField("Ending Date", ExpectedDate + 1);
        // [THEN] Price List Line, where "Ending Date" is '300120'
        PriceListLine.Find();
        PriceListLine.TestField("Ending Date", ExpectedDate);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmYesSimpleHandler')]
    procedure T028_SetConflictingEndingDateWithLines()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLineOrig: Record "Price List Line";
        PriceListLine: Record "Price List Line";
    begin
        Initialize();
        // [GIVEN] Price List with one line, where "Ending Date" is '300120', "Allow Updating Defaults" is 'Yes'
        CreatePriceList(PriceListHeader, PriceListLineOrig);
        PriceListHeader.Validate("Allow Updating Defaults", true);
        PriceListHeader.Modify();

        // [GIVEN] Price List Line, where "Starting Date" is '300120'
        PriceListLine := PriceListLineOrig;
        PriceListLine.Validate("Starting Date", PriceListHeader."Ending Date");
        PriceListLine.Modify(true);

        // [WHEN] Set "Ending Date" as '290120', answer 'Yes' to confirm
        PriceListHeader.Validate("Ending Date", PriceListLine."Starting Date" - 1);

        // [THEN] Price line, where "Starting Date" "Ending Date" are equal to header's dates
        PriceListLine.Find();
        PriceListLine.TestField("Starting Date", PriceListHeader."Starting Date");
        PriceListLine.TestField("Ending Date", PriceListHeader."Ending Date");
    end;

    [Test]
    [HandlerFunctions('ConfirmYesSimpleHandler')]
    procedure T029_SetConflictingStartingDateWithLines()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLineOrig: Record "Price List Line";
        PriceListLine: Record "Price List Line";
    begin
        Initialize();
        // [GIVEN] Price List with one line, where "Starting Date" is '300120', "Allow Updating Defaults" is 'Yes'
        CreatePriceList(PriceListHeader, PriceListLineOrig);
        PriceListHeader.Validate("Allow Updating Defaults", true);
        PriceListHeader.Modify();

        // [GIVEN] Price List Line, where "Ending Date" is '300120'
        PriceListLine := PriceListLineOrig;
        PriceListLine.Validate("Ending Date", PriceListHeader."Starting Date");
        PriceListLine.Modify(true);

        // [WHEN] Set "Starting Date" as '310120', answer 'Yes' to confirm
        PriceListHeader.Validate("Starting Date", PriceListLine."Ending Date" + 1);

        // [THEN] Price line, where "Starting Date" "Ending Date" are equal to header's dates
        PriceListLine.Find();
        PriceListLine.TestField("Starting Date", PriceListHeader."Starting Date");
        PriceListLine.TestField("Ending Date", PriceListHeader."Ending Date");
    end;

    [Test]
    procedure T030_UpdateAmountTypeAnyNoLines()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] "Amount Type" is 'Any' if lines contain a lines with 'Any'
        Initialize();
        PriceListHeader.DeleteAll();
        PriceListLine.DeleteAll();
        // [GIVEN] Price list includes no lines
        PriceListHeader.Code := 'X';
        PriceListHeader.Insert();
        // [WHEN] UpdateAmountType
        PriceListHeader.UpdateAmountType();
        // [THEN] "Amount Type" is 'Any'
        PriceListHeader.TestField("Amount Type", PriceListHeader."Amount Type"::Any);
    end;

    [Test]
    procedure T031_UpdateAmountTypeAnyInLines()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] "Amount Type" is 'Any' if lines contain a lines with 'Any'
        Initialize();
        PriceListHeader.DeleteAll();
        PriceListLine.DeleteAll();
        // [GIVEN] Price list includes one line with "Amount Type" 'Any'
        PriceListHeader.Code := 'X';
        PriceListHeader.Insert();
        PriceListLine."Price List Code" := PriceListHeader.Code;
        PriceListLine."Line No." := 0;
        PriceListLine."Amount Type" := PriceListLine."Amount Type"::Any;
        PriceListLine.Insert();

        // [WHEN] UpdateAmountType
        PriceListHeader.UpdateAmountType();
        // [THEN] "Amount Type" is 'Any'
        PriceListHeader.TestField("Amount Type", PriceListHeader."Amount Type"::Any);
    end;

    [Test]
    procedure T032_UpdateAmountTypeAnyInLinesPriceAndDiscount()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLIne: Record "Price List Line";
    begin
        // [SCENARIO] "Amount Type" is 'Any' if lines contain a lines with both 'Price' and 'Discount'
        Initialize();
        PriceListHeader.DeleteAll();
        PriceListLine.DeleteAll();
        // [GIVEN] Price list includes two lines with "Amount Type" 'Price' and 'Discount'
        PriceListHeader.Code := 'X';
        PriceListHeader.Insert();
        PriceListLine."Price List Code" := PriceListHeader.Code;
        PriceListLine."Line No." := 0;
        PriceListLine."Amount Type" := PriceListLine."Amount Type"::Price;
        PriceListLine.Insert();
        PriceListLine."Line No." := 0;
        PriceListLine."Amount Type" := PriceListLine."Amount Type"::Discount;
        PriceListLine.Insert();

        // [WHEN] UpdateAmountType
        PriceListHeader.UpdateAmountType();
        // [THEN] "Amount Type" is 'Any'
        PriceListHeader.TestField("Amount Type", PriceListHeader."Amount Type"::Any);
    end;

    [Test]
    procedure T033_UpdateAmountTypePriceInLinesPriceOnly()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLIne: Record "Price List Line";
    begin
        // [SCENARIO] "Amount Type" is 'Price' if all lines contain 'Price' only
        Initialize();
        PriceListHeader.DeleteAll();
        PriceListLine.DeleteAll();
        // [GIVEN] Price list includes one line with "Amount Type" 'Price'
        PriceListHeader.Code := 'X';
        PriceListHeader.Insert();
        PriceListLine."Price List Code" := PriceListHeader.Code;
        PriceListLine."Line No." := 0;
        PriceListLine."Amount Type" := PriceListLine."Amount Type"::Price;
        PriceListLine.Insert();

        // [WHEN] UpdateAmountType
        PriceListHeader.UpdateAmountType();
        // [THEN] "Amount Type" is 'Price'
        PriceListHeader.TestField("Amount Type", PriceListHeader."Amount Type"::Price);
    end;

    [Test]
    procedure T034_UpdateAmountTypeDiscountInLinesDiscountOnly()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLIne: Record "Price List Line";
    begin
        // [SCENARIO] "Amount Type" is 'Discount' if all lines contain 'Discount' only
        Initialize();
        PriceListHeader.DeleteAll();
        PriceListLine.DeleteAll();
        // [GIVEN] Price list includes one line with "Amount Type" 'Discount'
        PriceListHeader.Code := 'X';
        PriceListHeader.Insert();
        PriceListLine."Price List Code" := PriceListHeader.Code;
        PriceListLine."Line No." := 0;
        PriceListLine."Amount Type" := PriceListLine."Amount Type"::Discount;
        PriceListLine.Insert();

        // [WHEN] UpdateAmountType
        PriceListHeader.UpdateAmountType();
        // [THEN] "Amount Type" is 'Discount'
        PriceListHeader.TestField("Amount Type", PriceListHeader."Amount Type"::Discount);
    end;

    [Test]
    procedure T035_DefaultAmountTypeOnSourceTypeValidation()
    var
        PriceListHeader: Record "Price List Header";
    begin
        // [SCENARIO] Default "Amount Type" depends on source type.
        Initialize();
        PriceListHeader.DeleteAll();
        // [WHEN] Set "Source Type" as "Customer Disc. Group" in Price list header
        PriceListHeader.Validate("Source Type", "Price Source Type"::"Customer Price Group");
        // [THEN] "Amount Type" is 'Price'
        PriceListHeader.TestField("Amount Type", "Price Amount Type"::Price);

        // [WHEN] Set "Source Type" as "Customer Disc. Group" in Price list header
        PriceListHeader.Validate("Source Type", "Price Source Type"::"Customer Disc. Group");
        // [THEN] "Amount Type" is 'Discount'
        PriceListHeader.TestField("Amount Type", "Price Amount Type"::Discount);

        // [WHEN] Set "Source Type" as "Customer" in Price list header
        PriceListHeader.Validate("Source Type", "Price Source Type"::Customer);
        // [THEN] "Amount Type" is 'Price'
        PriceListHeader.TestField("Amount Type", "Price Amount Type"::Any);
    end;

    [Test]
    procedure T036_ValidateAmountType()
    var
        PriceListHeader: Record "Price List Header";
    begin
        // [SCENARIO] Cannot change "Amount Type" for source types "Customer Disc. Group", "Customer Price Group"
        Initialize();
        PriceListHeader.Init();
        // [WHEN] Set "Source Type" as "Customer Disc. Group" in Price list header
        PriceListHeader."Source Type" := "Price Source Type"::"Customer Disc. Group";
        // [THEN] Can change "Amount Type" to 'Discount'
        PriceListHeader.Validate("Amount Type", "Price Amount Type"::Discount);
        // [THEN] Cannot change "Amount Type" to 'Price' or 'Any'
        asserterror PriceListHeader.Validate("Amount Type", "Price Amount Type"::Price);
        asserterror PriceListHeader.Validate("Amount Type", "Price Amount Type"::Any);

        PriceListHeader.Init();
        // [WHEN] Set "Source Type" as "Customer Disc. Group" in Price list header
        PriceListHeader."Source Type" := "Price Source Type"::"Customer Price Group";
        // [THEN] Can change "Amount Type" to 'Price'
        PriceListHeader.Validate("Amount Type", "Price Amount Type"::Price);
        // [THEN] Cannot change "Amount Type" to 'Discount' or 'Any'
        asserterror PriceListHeader.Validate("Amount Type", "Price Amount Type"::Discount);
        asserterror PriceListHeader.Validate("Amount Type", "Price Amount Type"::Any);

        PriceListHeader.Init();
        // [WHEN] Set "Source Type" as "Customer" in Price list header
        PriceListHeader."Source Type" := "Price Source Type"::Customer;
        // [THEN] Can change "Amount Type" to 'Any', 'Discount', or 'Price'
        PriceListHeader.Validate("Amount Type", "Price Amount Type"::Price);
        PriceListHeader.TestField("Amount Type", "Price Amount Type"::Price);
        PriceListHeader.Validate("Amount Type", "Price Amount Type"::Any);
        PriceListHeader.TestField("Amount Type", "Price Amount Type"::Any);
        PriceListHeader.Validate("Amount Type", "Price Amount Type"::Discount);
        PriceListHeader.TestField("Amount Type", "Price Amount Type"::Discount);
    end;

    [Test]
    procedure T040_UpdateAllowLineDiscDoesNotUpdateLines()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] Updated "Allow Line Disc." in the header does not update lines.
        Initialize();
        CreatePriceList(PriceListHeader, PriceListLine);

        // [WHEN] Change "Allow Line Disc." in the header
        PriceListHeader.Validate("Allow Line Disc.", not PriceListHeader."Allow Line Disc.");
        // [THEN] Price list line, where "Allow Line Disc." is not changed
        PriceListLine.Find();
        PriceListLine.TestField("Allow Line Disc.", not PriceListHeader."Allow Line Disc.");
    end;

    [Test]
    procedure T041_UpdateAllowInvDiscDoesNotUpdateLines()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] Updated "Allow Invoice Disc." in the header does not update lines.
        Initialize();
        CreatePriceList(PriceListHeader, PriceListLine);

        // [WHEN] Change "Allow Invoice Disc." in the header
        PriceListHeader.Validate("Allow Invoice Disc.", not PriceListHeader."Allow Invoice Disc.");
        // [THEN] Price list line, where "Allow LiInvoicene Disc." is not changed
        PriceListLine.Find();
        PriceListLine.TestField("Allow Invoice Disc.", not PriceListHeader."Allow Invoice Disc.");
    end;

    [Test]
    procedure T042_UpdateCurrencyCodeWIthLinesNotAllowed()
    var
        Currency: Record Currency;
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] Update of "Currency Code" in the header with lines not allowed.
        Initialize();
        CreatePriceList(PriceListHeader, PriceListLine);

        // [WHEN] Change "Currency Code" in the header
        LibraryERM.CreateCurrency(Currency);
        asserterror PriceListHeader.Validate("Currency Code", Currency.Code);
        // [THEN] Error message: 'You cannot update Currency Code because lines exist.'
        Assert.ExpectedError(StrSubstNo(LinesExistErr, PriceListHeader.FieldCaption("Currency Code")));
    end;

    [Test]
    procedure T043_UpdatePriceInclVatWithLinesNotAllowed()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] Update of "Price Includes VAT" in the header with lines not allowed.
        Initialize();
        CreatePriceList(PriceListHeader, PriceListLine);

        // [WHEN] Change "Price Includes VAT" in the header
        asserterror PriceListHeader.Validate("Price Includes VAT", not PriceListHeader."Price Includes VAT");
        // [THEN] Error message: 'You cannot update Price Includes VAT because lines exist.'
        Assert.ExpectedError(StrSubstNo(LinesExistErr, PriceListHeader.FieldCaption("Price Includes VAT")));
    end;

    [Test]
    procedure T044_UpdateVATBusGroupWithLinesNotAllowed()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        // [SCENARIO] Update of "VAT Bus. Posting Gr. (Price)" in the header with lines not allowed.
        Initialize();
        CreatePriceList(PriceListHeader, PriceListLine);

        // [WHEN] Change "VAT Bus. Posting Gr. (Price)" in the header
        LibraryERM.FindVATBusinessPostingGroup(VATBusinessPostingGroup);
        asserterror PriceListHeader.Validate("VAT Bus. Posting Gr. (Price)", VATBusinessPostingGroup.Code);
        // [THEN] Error message: 'You cannot update VAT Bus. Posting Gr. (Price) because lines exist.'
        Assert.ExpectedError(StrSubstNo(LinesExistErr, PriceListHeader.FieldCaption("VAT Bus. Posting Gr. (Price)")));
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure T050_UpdateStatusConfirmYes()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] Update of Status in the header with lines updates lines with confirmation.
        Initialize();
        // [GIVEN] New price list, where "Status" is 'Draft'
        CreatePriceList(PriceListHeader, PriceListLine);
        PriceListHeader.TestField(Status, PriceListHeader.Status::Draft);

        // [WHEN] Set "Status" as 'Active' and answer 'Yes'
        PriceListHeader.Validate(Status, PriceListHeader.Status::Active);

        // [THEN] Confirmation question: 'Do you want to update Status to Active?'
        Assert.AreEqual(
            StrSubstNo(StatusUpdateQst, PriceListHeader.Status::Active),
            LibraryVariableStorage.DequeueText(), 'Confirm question'); // from ConfirmYesHandler
        // [THEN] Price list lines got "Status" 'Active'.
        PriceListHeader.TestField(Status, PriceListHeader.Status::Active);
        PriceListLine.Find();
        PriceListLine.TestField(Status, PriceListHeader.Status::Active);
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    procedure T051_UpdateStatusConfirmNo()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] Update of Status in the header with lines will not be updated without confirmation.
        Initialize();
        // [GIVEN] New price list, where "Status" is 'Draft'
        CreatePriceList(PriceListHeader, PriceListLine);
        PriceListHeader.TestField(Status, PriceListHeader.Status::Draft);

        // [WHEN] Set "Status" as 'Active' and answer 'No'
        PriceListHeader.Validate(Status, PriceListHeader.Status::Active);

        // [THEN] Confirmation question: 'Do you want to update Status to Active?'
        Assert.AreEqual(
            StrSubstNo(StatusUpdateQst, PriceListHeader.Status::Active),
            LibraryVariableStorage.DequeueText(), 'Confirm question'); // from ConfirmNoHandler
        // [THEN] Price list header and lines keep "Status" 'Draft'.
        PriceListHeader.TestField(Status, PriceListHeader.Status::Draft);
        PriceListLine.Find();
        PriceListLine.TestField(Status, PriceListHeader.Status::Draft);
    end;

    [Test]
    procedure T052_IsEditable()
    var
        PriceListHeader: Record "Price List Header";
    begin
        // [SCENARIO] Price List should be editable only if Status is 'Draft'.
        Initialize();

        PriceListHeader.Status := PriceListHeader.Status::Draft;
        Assert.IsTrue(PriceListHeader.IsEditable(), 'Draft');

        PriceListHeader.Status := PriceListHeader.Status::Active;
        Assert.IsFalse(PriceListHeader.IsEditable(), 'Active');

        PriceListHeader.Status := PriceListHeader.Status::Inactive;
        Assert.IsFalse(PriceListHeader.IsEditable(), 'Inactive')
    end;

    [Test]
    procedure T053_ActiveIsEditableIfAllowedEditing()
    var
        PriceListHeader: Record "Price List Header";
    begin
        // [FEATURE] [Allow Editing Active Price]
        // [SCENARIO] Price List should be editable if Status is 'Draft' or 'Active' and "Allow Editing Active Price" is on.
        Initialize();
        // [GIVEN] Allow Editing Active Sales Price
        LibraryPriceCalculation.AllowEditingActiveSalesPrice();

        PriceListHeader."Price Type" := "Price Type"::Sale;
        PriceListHeader.Status := PriceListHeader.Status::Draft;
        Assert.IsTrue(PriceListHeader.IsEditable(), 'Draft');

        PriceListHeader.Status := PriceListHeader.Status::Active;
        Assert.IsTrue(PriceListHeader.IsEditable(), 'Active');

        PriceListHeader.Status := PriceListHeader.Status::Inactive;
        Assert.IsFalse(PriceListHeader.IsEditable(), 'Inactive')
    end;

    [Test]
    procedure T055_CannotDeleteActivePriceList()
    var
        PriceListHeader: Record "Price List Header";
    begin
        // [SCENARIO] Price List cannot be deleted if Status is Active.
        Initialize();
        PriceListHeader.DeleteAll();

        PriceListHeader.Code := 'X';
        PriceListHeader.Status := PriceListHeader.Status::Draft;
        PriceListHeader.Insert(true);
        PriceListHeader.Delete(true);

        PriceListHeader.Status := PriceListHeader.Status::Inactive;
        PriceListHeader.Insert(true);
        PriceListHeader.Delete(true);

        PriceListHeader.Status := PriceListHeader.Status::Active;
        PriceListHeader.Insert(true);
        asserterror PriceListHeader.Delete(true);
        Assert.ExpectedError(StrSubstNo(CannotDeleteActivePriceListErr, PriceListHeader.Code));
    end;

    [Test]
    procedure T056_CanDeleteActivePriceListIfEditingAllowed()
    var
        PriceListHeader: Record "Price List Header";
    begin
        // [FEATURE] [Allow Editing Active Price]
        // [SCENARIO] Price List can be deleted if Status is Active, but "Allow Editing Active Price".
        Initialize();
        PriceListHeader.DeleteAll();
        LibraryPriceCalculation.AllowEditingActivePurchPrice();

        PriceListHeader."Price Type" := "Price Type"::Purchase;
        PriceListHeader.Code := 'X';
        PriceListHeader.Status := PriceListHeader.Status::Draft;
        PriceListHeader.Insert(true);
        PriceListHeader.Delete(true);

        PriceListHeader.Status := PriceListHeader.Status::Inactive;
        PriceListHeader.Insert(true);
        PriceListHeader.Delete(true);

        PriceListHeader.Status := PriceListHeader.Status::Active;
        PriceListHeader.Insert(true);
        PriceListHeader.Delete(true);
        Assert.IsFalse(PriceListHeader.Find(), 'must be deleted');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure T057_ActivePriceListToDraft()
    var
        Item: Record Item;
        PriceListHeader: Record "Price List Header";
        PriceListLine: array[2] of Record "Price List Line";
    begin
        Initialize();
        // [GIVEN] Item 'X'
        LibraryInventory.CreateItem(Item);
        // [GIVEN] 'Draft' price list, where "Asset No." is 'X', "Minimum Quantity" is 0, prices are different.
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[1], PriceListHeader.Code, "Price Source Type"::"All Customers", '', "Price Asset Type"::Item, Item."No.");
        // [GIVEN] Activate the price list
        PriceListHeader.Validate(Status, "Price Status"::Active);

        // [WHEN] Deactivate the price list to 'Draft', answer 'Yes' to confirmation.
        PriceListHeader.Validate(Status, "Price Status"::Draft);

        // [THEN] Price list is a draft, where is one (first) line.
        Assert.IsTrue(PriceListLine[1].Find(), 'active first line is not found');
        PriceListLine[1].TestField(Status, "Price Status"::Draft);
    end;

    [Test]
    procedure T060_UpdateStatusOnHeaderSourceAllCustomersSourceFilled()
    var
        PriceListHeader: Record "Price List Header";
    begin
        // [SCENARIO] Update of Status in the header fails on inconsistent source: Assign-to is filled.
        Initialize();
        // [GIVEN] New price list, where "Status" is 'Draft', "Source Type"::"All Customers", "Source No." is 'X'
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, PriceListHeader."Price Type"::Sale,
            PriceListHeader."Source Type"::"All Customers", '');
        PriceListHeader."Source No." := 'x';
        PriceListHeader.Modify();

        // [WHEN] Set "Status" as 'Active' and answer 'Yes'
        asserterror PriceListHeader.Validate(Status, PriceListHeader.Status::Active);

        // [THEN] Error: "Assign-to No. (custom) must be equal to ''''"
        Assert.ExpectedTestFieldError(PriceListHeader.FieldCaption("Source No."), '''');
    end;

    [Test]
    procedure T061_UpdateStatusOnHeaderSourceCustomersSourceBlank()
    var
        PriceListHeader: Record "Price List Header";
    begin
        // [SCENARIO] Update of Status in the header fails on inconsistent source: Assign-to is blank.
        Initialize();
        // [GIVEN] New price list, where "Status" is 'Draft', "Source Type"::"Customer", "Source No." is <blank>
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, PriceListHeader."Price Type"::Sale,
            PriceListHeader."Source Type"::Customer, '');
        PriceListHeader.Modify();

        // [WHEN] Set "Status" as 'Active'
        asserterror PriceListHeader.Validate(Status, PriceListHeader.Status::Active);

        // [THEN] Error: "Assign-to No. (custom) must have a value"
        Assert.ExpectedError(SourceNoCustomMustBeFilledErr);
    end;

    [Test]
    procedure T062_UpdateStatusOnHeaderSourceAllJobTaskParentSourceBlank()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        PriceListHeader: Record "Price List Header";
    begin
        // [SCENARIO] Update of Status in the header fails on inconsistent source: Assign-to Parent No. is blank.
        Initialize();
        // [GIVEN] New price list, where "Status" is 'Draft', "Source Type"::"Job Task", "Source No." is 'JT',
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, PriceListHeader."Price Type"::Sale,
            PriceListHeader."Source Type"::"Job Task", JobTask."Job Task No.");
        // [GIVEN] "Parent Source No." is <blank>
        PriceListHeader."Parent Source No." := '';
        PriceListHeader.Modify();

        // [WHEN] Set "Status" as 'Active'
        asserterror PriceListHeader.Validate(Status, PriceListHeader.Status::Active);

        // [THEN] Error: "Parent Assign-to No. (jobs) must have a value"
        Assert.ExpectedError(JobsParentSourceNoMustBeFilledErr);
    end;

    [Test]
    procedure T063_UpdateStatusOnHeaderSourceAllJobParentSourceFilled()
    var
        Job: Record Job;
        PriceListHeader: Record "Price List Header";
    begin
        // [SCENARIO] Update of Status in the header fails on inconsistent source: Assign-to Parent No. is filled.
        Initialize();
        // [GIVEN] New price list, where "Status" is 'Draft', "Source Type"::"Job", "Source No." is 'J',
        LibraryJob.CreateJob(Job);
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, PriceListHeader."Price Type"::Sale,
            PriceListHeader."Source Type"::Job, Job."No.");
        // [GIVEN] "Parent Source No." is 'J'
        PriceListHeader."Parent Source No." := Job."No.";
        PriceListHeader.Modify();

        // [WHEN] Set "Status" as 'Active' and answer 'Yes'
        asserterror PriceListHeader.Validate(Status, PriceListHeader.Status::Active);

        // [THEN] Error: "Assign-to Parent No. must be equal to ''''"
        Assert.ExpectedError(ParentSourceJobErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure T065_UpdateStatusOnHeaderAsDefault()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: array[2] of Record "Price List Line";
    begin
        // [SCENARIO] Update of Status in the header with lines updates lines with confirmation.
        Initialize();
        // [GIVEN] New price list, where "Status" is 'Draft', "Allow Updating Defaults" is 'Yes'
        CreatePriceList(PriceListHeader, PriceListLine[1]);
        PriceListHeader."Allow Updating Defaults" := true;
        PriceListHeader.Modify();
        PriceListHeader.TestField(Status, PriceListHeader.Status::Draft);
        // [GIVEN] Two lines, where Item is the same, but "Source No." are different
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[2], PriceListHeader.Code, "Price Source Type"::"All Customers", '',
            PriceListLine[1]."Asset Type", PriceListLine[1]."Asset No.");

        // [WHEN] Set "Status" as 'Active' and answer 'Yes'
        PriceListHeader.Validate(Status, PriceListHeader.Status::Active);

        // [THEN] Confirmation question: 'Do you want to update Status to Active?'
        Assert.AreEqual(
            StrSubstNo(StatusUpdateQst, PriceListHeader.Status::Active),
            LibraryVariableStorage.DequeueText(), 'Confirm question'); // from ConfirmYesHandler
        // [THEN] Price list header and lines got "Status" 'Active'.
        PriceListHeader.TestField(Status, PriceListHeader.Status::Active);
        PriceListLine[1].Find();
        PriceListLine[1].TestField(Status, PriceListHeader.Status::Active);
        PriceListLine[2].Find();
        PriceListLine[2].TestField(Status, PriceListHeader.Status::Active);
    end;

    [Test]
    procedure T066_UpdateStatusOnHeaderAsDefaultWithBlankSourceNo()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: array[2] of Record "Price List Line";
    begin
        // [SCENARIO] Update of Status in the header with lines updates lines missing Assign-to
        Initialize();
        // [GIVEN] New price list, where "Source Type" is 'All Customers', "Status" is 'Draft', "Allow Updating Defaults" is 'Yes'
        CreatePriceList(PriceListHeader, PriceListLine[1]);
        PriceListHeader."Allow Updating Defaults" := true;
        PriceListHeader.Modify();
        PriceListHeader.TestField(Status, PriceListHeader.Status::Draft);
        // [GIVEN] Two lines, where Item is the same, but "Source Type" is 'Customer', "Source No." is <blank> in the 2nd line
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[2], PriceListHeader.Code, "Price Source Type"::Customer, LibrarySales.CreateCustomerNo(),
            PriceListLine[1]."Asset Type", PriceListLine[1]."Asset No.");
        PriceListLine[2].Validate("Source No.", '');
        PriceListLine[2].Modify();

        // [WHEN] Set "Status" as 'Active'
        asserterror PriceListHeader.Validate(Status, PriceListHeader.Status::Active);

        // [THEN] Error message: "Assign-to No. (custom) must have a value"
        Assert.ExpectedError(SourceNoCustomMustBeFilledErr);
    end;

    [Test]
    procedure T067_UpdateStatusOnHeaderAsDefaultWithBlankParentSourceNo()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: array[2] of Record "Price List Line";
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        // [SCENARIO] Update of Status in the header with lines updates lines missing Assign-to Parent No.
        Initialize();
        // [GIVEN] New price list, where "Source Type" is 'All Customers', "Status" is 'Draft', "Allow Updating Defaults" is 'Yes'
        CreatePriceList(PriceListHeader, PriceListLine[1]);
        PriceListHeader."Allow Updating Defaults" := true;
        PriceListHeader.Modify();
        PriceListHeader.TestField(Status, PriceListHeader.Status::Draft);
        // [GIVEN] Two lines, where Item is the same, but "Source Type" is 'Job Task', "Parent Source No." is <blank> in the 2nd line
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[2], PriceListHeader.Code, "Price Type"::Sale, "Price Source Type"::"Job Task", Job."No.", JobTask."Job Task No.",
            "Price Amount Type"::Price, PriceListLine[1]."Asset Type", PriceListLine[1]."Asset No.");
        PriceListLine[2].Validate("Parent Source No.", '');
        PriceListLine[2].Modify();

        // [WHEN] Set "Status" as 'Active'
        asserterror PriceListHeader.Validate(Status, PriceListHeader.Status::Active);

        // [THEN] Error message: "Assign-to Parent No. (custom) must have a value"
        Assert.ExpectedError(CustomParentSourceNoMustBeFilledErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure T068_UpdateStatusOnHeaderAsDefaultWithBlankProductNo()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: array[2] of Record "Price List Line";
    begin
        // [SCENARIO] Update of Status in the header with lines updates lines missing Product No.
        Initialize();
        // [GIVEN] New price list, where "Source Type" is 'All Customers', "Status" is 'Draft', "Allow Updating Defaults" is 'Yes'
        CreatePriceList(PriceListHeader, PriceListLine[1]);
        PriceListHeader."Allow Updating Defaults" := true;
        PriceListHeader.Modify();
        PriceListHeader.TestField(Status, PriceListHeader.Status::Draft);
        // [GIVEN] Two lines, where Item is the same, but "Source Type" is 'All Customers', "Source No." is <blank> in the 2nd line
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[2], PriceListHeader.Code, "Price Source Type"::"All Customers", '',
            PriceListLine[1]."Asset Type", PriceListLine[1]."Asset No.");
        // [GIVEN] "Asset No." is <blank>
        PriceListLine[2]."Asset No." := '';
        PriceListLine[2].Modify();

        // [WHEN] Set "Status" as 'Active'
        PriceListHeader.Validate(Status, PriceListHeader.Status::Active);

        // [THEN] Both lines are active
        PriceListLine[1].Find();
        PriceListLine[1].Testfield(Status, "Price Status"::Active);
        PriceListLine[2].Find();
        PriceListLine[2].Testfield(Status, "Price Status"::Active);
    end;

    [Test]
    procedure T069_UpdateStatusOnHeaderSourceAllLocationsSourceFilled()
    var
        PriceListHeader: Record "Price List Header";
    begin
        // [FEATURE] [Price Source Type] [Extended]
        // [SCENARIO] Update of Status in the header fails on inconsistent source: Assign-to is filled.
        Initialize();
        // [GIVEN] New price list, where "Status" is 'Draft', "Source Type"::"All Locations", "Source No." is 'X'
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, PriceListHeader."Price Type"::Sale,
            PriceListHeader."Source Type"::Test_All_Locations, '');
        PriceListHeader."Source No." := 'x';
        PriceListHeader.Modify();

        // [WHEN] Set "Status" as 'Active' and answer 'Yes'
        asserterror PriceListHeader.Validate(Status, PriceListHeader.Status::Active);

        // [THEN] Error: "Assign-to No. (custom) must be equal to ''''"
        Assert.ExpectedTestFieldError(PriceListHeader.FieldCaption("Source No."), '''');
    end;

    [Test]
    procedure T070_UpdateStatusOnHeaderSourceLocationSourceBlank()
    var
        PriceListHeader: Record "Price List Header";
    begin
        // [FEATURE] [Price Source Type] [Extended]
        // [SCENARIO] Update of Status in the header fails on inconsistent source: Assign-to is blank.
        Initialize();
        // [GIVEN] New price list, where "Status" is 'Draft', "Source Type"::"Location", "Parent Source No." is 'X', "Source No." is <blank>
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, PriceListHeader."Price Type"::Sale,
            PriceListHeader."Source Type"::Test_Location, '');
        PriceListHeader."Parent Source No." := 'X';
        PriceListHeader.Modify();

        // [WHEN] Set "Status" as 'Active'
        asserterror PriceListHeader.Validate(Status, PriceListHeader.Status::Active);

        // [THEN] Error: "Assign-to No. (custom) must have a value"
        Assert.ExpectedTestFieldError(PriceListHeader.FieldCaption("Source No."), '');
    end;

    [Test]
    procedure T071_UpdateStatusOnHeaderSourceAllLocationsParentSourceFilled()
    var
        PriceListHeader: Record "Price List Header";
    begin
        // [FEATURE] [Price Source Type] [Extended]
        // [SCENARIO] Update of Status in the header fails on inconsistent source: "Assign-to Parent No."" is filled.
        Initialize();
        // [GIVEN] New price list, where "Status" is 'Draft', "Source Type"::"All Locations", "Parent Source No." is 'X'
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, PriceListHeader."Price Type"::Sale,
            PriceListHeader."Source Type"::Test_All_Locations, '');
        PriceListHeader."Parent Source No." := 'X';
        PriceListHeader.Modify();

        // [WHEN] Set "Status" as 'Active' and answer 'Yes'
        asserterror PriceListHeader.Validate(Status, PriceListHeader.Status::Active);

        // [THEN] Error: "Assign-to Parent No. (custom) must be equal to ''''"
        Assert.ExpectedTestFieldError(PriceListHeader.FieldCaption("Parent Source No."), '''');
    end;

    [Test]
    procedure T072_UpdateStatusOnHeaderSourceLocationParentSourceBlank()
    var
        PriceListHeader: Record "Price List Header";
    begin
        // [FEATURE] [Price Source Type] [Extended]
        // [SCENARIO] Update of Status in the header fails on inconsistent source: Assign-to is blank.
        Initialize();
        // [GIVEN] New price list, where "Status" is 'Draft', "Source Type"::"Location", "Parent Source No." is <blank>
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, PriceListHeader."Price Type"::Sale,
            PriceListHeader."Source Type"::Test_Location, 'X');

        // [WHEN] Set "Status" as 'Active'
        asserterror PriceListHeader.Validate(Status, PriceListHeader.Status::Active);

        // [THEN] Error: "Assign-to Parent No. (jobs) must have a value"
        Assert.ExpectedError(JobsParentSourceNoMustBeFilledErr);
    end;

    [Test]
    procedure T080_ValidateStartingDateForCampaign()
    var
        PriceListHeader: Record "Price List Header";
    begin
        // [FEATURE] [Campaign]
        Initialize();
        // [GIVEN] Price List Header, where "Source Type" is 'Campaign', "Ending Date" is '310120'
        PriceListHeader.Init();
        PriceListHeader."Source Type" := PriceListHeader."Source Type"::Campaign;
        PriceListHeader."Ending Date" := WorkDate();
        // [WHEN] Set "Starting Date" as '010120'
        asserterror PriceListHeader.Validate("Starting Date", WorkDate() + 1);

        // [THEN] Error message: '... you can only change Starting Date and Ending Date from the Campaign Card.'
        Assert.ExpectedError(CampaignDateErr);
    end;

    [Test]
    procedure T081_ValidateCampaignNoSetsDates()
    var
        Campaign: Record Campaign;
        PriceListHeader: Record "Price List Header";
    begin
        // [FEATURE] [Campaign]
        Initialize();
        // [GIVEN] Campaign 'C', where "Starting Date" is '010120', "Ending Date" is '310120'
        LibraryMarketing.CreateCampaign(Campaign);
        Campaign.Validate("Starting Date", WorkDate());
        Campaign.Validate("Ending Date", WorkDate() + 10);
        Campaign.Modify();
        // [GIVEN] Price List Line, where "Source Type" is 'Campaign', "Starting Date" and "Ending Date" are <blank>
        PriceListHeader.Validate("Source Type", PriceListHeader."Source Type"::Campaign);

        // [WHEN] Set "Source No." as 'C'
        PriceListHeader.Validate("Source No.", Campaign."No.");

        // [THEN] Price List Header, where "Starting Date" is '010120', "Ending Date" is '310120'
        VerifyDates(PriceListHeader, Campaign."Starting Date", Campaign."Ending Date");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure T082_ValidateStartingDateOnCampaignCardActivePriceConfirmed()
    var
        Campaign: Record Campaign;
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        NewDate: Date;
    begin
        // [FEATURE] [Campaign]
        // [SCEANRIO 436511] "Starting Date" can be changed on the Campaign if confirmed price list update..
        Initialize();
        // [GIVEN] Campaign 'C', where "Starting Date" is '010120', "Ending Date" is '310120'
        LibraryMarketing.CreateCampaign(Campaign);
        Campaign.Validate("Starting Date", WorkDate());
        Campaign.Validate("Ending Date", WorkDate() + 10);
        Campaign.Modify();
        NewDate := WorkDate() + 5;
        // [GIVEN] Editing active prices is off
        LibraryPriceCalculation.DisallowEditingActiveSalesPrice();
        // [GIVEN] Active Price List Header with one line, where "Source Type" is 'Campaign', "Source No." set as 'C'
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, PriceListHeader."Price Type"::Sale,
            PriceListHeader."Source Type"::Campaign, Campaign."No.");
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, PriceListHeader.Code, PriceListHeader."Source Type"::Campaign, Campaign."No.",
            "Price Asset Type"::"G/L Account", LibraryERM.CreateGLAccountNo());
        LibraryVariableStorage.Enqueue(true); // to confirm Status update
        PriceListHeader.Validate(Status, "Price Status"::Active);
        PriceListHeader.Modify(true);
        // [GIVEN] Price List Header, gets "Starting Date" is '010120', "Ending Date" is '310120' from Campaign
        VerifyDates(PriceListHeader, Campaign."Starting Date", Campaign."Ending Date");
        VerifyDates(PriceListLine, Campaign."Starting Date", Campaign."Ending Date");

        // [WHEN] Change "Ending Date" on campaign card to '010220', confirming price list update.
        LibraryVariableStorage.Enqueue(true); // to confirm Price lists update
        Campaign.Validate("Starting Date", NewDate);

        // [THEN] Price List Header is Active and Line, gets "Ending Date" as '010220'
        VerifyDates(PriceListHeader, NewDate, Campaign."Ending Date");
        PriceListHeader.TestField(Status, "Price Status"::Active);
        VerifyDates(PriceListLine, NewDate, Campaign."Ending Date");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure T083_ValidateStartingDateOnCampaignCardActivePriceNotConfirmed()
    var
        Campaign: Record Campaign;
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        NewDate: Date;
    begin
        // [FEATURE] [Campaign]
        // [SCEANRIO 436511] "Starting Date" will not be changed on the Campaign if not confirmed price list update.
        Initialize();
        // [GIVEN] Campaign 'C', where "Starting Date" is '010120', "Ending Date" is '310120'
        LibraryMarketing.CreateCampaign(Campaign);
        Campaign.Validate("Starting Date", WorkDate());
        Campaign.Validate("Ending Date", WorkDate() + 10);
        Campaign.Modify();
        NewDate := WorkDate() + 5;
        // [GIVEN] Editing active prices is off
        LibraryPriceCalculation.DisallowEditingActiveSalesPrice();
        // [GIVEN] Active Price List Header with one line, where "Source Type" is 'Campaign', "Source No." set as 'C'
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, PriceListHeader."Price Type"::Sale,
            PriceListHeader."Source Type"::Campaign, Campaign."No.");
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, PriceListHeader.Code, PriceListHeader."Source Type"::Campaign, Campaign."No.",
            "Price Asset Type"::"G/L Account", LibraryERM.CreateGLAccountNo());
        LibraryVariableStorage.Enqueue(true); // to confirm Status update
        PriceListHeader.Validate(Status, "Price Status"::Active);
        PriceListHeader.Modify(true);
        Commit();
        // [GIVEN] Price List Header, gets "Starting Date" is '010120', "Ending Date" is '310120' from Campaign
        VerifyDates(PriceListHeader, Campaign."Starting Date", Campaign."Ending Date");
        VerifyDates(PriceListLine, Campaign."Starting Date", Campaign."Ending Date");

        // [WHEN] Change "Starting Date" on campaign card to '010220', not confirming price list update.
        LibraryVariableStorage.Enqueue(false); // to not confirm Price lists update
        asserterror Campaign.Validate("Starting Date", NewDate);

        // [THEN] Price List Header is Active and Line, gets "Ending Date" as '310120'
        VerifyDates(PriceListHeader, WorkDate(), WorkDate() + 10);
        PriceListHeader.TestField(Status, "Price Status"::Active);
        VerifyDates(PriceListLine, WorkDate(), WorkDate() + 10);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure T084_ValidateEndingDateOnCampaignCardActivePriceEditingAllowed()
    var
        Campaign: Record Campaign;
        PriceListHeader: array[2] of Record "Price List Header";
        PriceListLine: Record "Price List Line";
        NewDate: Date;
    begin
        // [FEATURE] [Campaign]
        // [SCEANRIO 436511] "Ending Date" can be changed on the Campaign that have a related price list.
        Initialize();
        // [GIVEN] Campaign 'C', where "Starting Date" is '010120', "Ending Date" is '310120'
        LibraryMarketing.CreateCampaign(Campaign);
        Campaign.Validate("Starting Date", WorkDate());
        Campaign.Validate("Ending Date", WorkDate() + 10);
        NewDate := WorkDate() + 11;
        Campaign.Modify();
        // [GIVEN] Editing active prices is on
        LibraryPriceCalculation.AllowEditingActiveSalesPrice();
        // [GIVEN] Active Price List Header 'A' with one line, where "Source Type" is 'Campaign', "Source No." set as 'C'
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader[1], PriceListHeader[1]."Price Type"::Sale,
            PriceListHeader[1]."Source Type"::Campaign, Campaign."No.");
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, PriceListHeader[1].Code, "Price Source Type"::Campaign, Campaign."No.",
            "Price Asset Type"::"G/L Account", LibraryERM.CreateGLAccountNo());
        LibraryVariableStorage.Enqueue(true); // to confirm Status update
        PriceListHeader[1].Validate(Status, "Price Status"::Active);
        PriceListHeader[1].Modify(true);
        // [GIVEN] Inactive Price List Header 'B', where "Source Type" is 'Campaign', "Source No." set as 'C'
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader[2], PriceListHeader[2]."Price Type"::Sale,
            PriceListHeader[2]."Source Type"::Campaign, Campaign."No.");
        PriceListHeader[2].Validate(Status, "Price Status"::Inactive);
        PriceListHeader[2].Modify(true);

        // [GIVEN] Price List Header, gets "Starting Date" is '010120', "Ending Date" is '310120' from Campaign
        VerifyDates(PriceListHeader[1], Campaign."Starting Date", Campaign."Ending Date");
        VerifyDates(PriceListHeader[2], Campaign."Starting Date", Campaign."Ending Date");
        VerifyDates(PriceListLine, Campaign."Starting Date", Campaign."Ending Date");

        // [WHEN] Change "Ending Date" on campaign card to '010220'
        Campaign.Validate("Ending Date", NewDate);

        // [THEN] Price List Header 'A' and Line, gets "Ending Date" as '010220'
        VerifyDates(PriceListHeader[1], Campaign."Starting Date", NewDate);
        VerifyDates(PriceListLine, Campaign."Starting Date", NewDate);
        // [THEN] The inactive price list 'B' also gets "Ending Date" as '010220'.
        VerifyDates(PriceListHeader[2], WorkDate(), NewDate);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure T085_ValidateEndingDateOnCampaignCardDraftPrice()
    var
        Campaign: Record Campaign;
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        NewDate: Date;
    begin
        // [FEATURE] [Campaign]
        // [SCEANRIO 436511] "Ending Date" can be changed on the Campaign that have a draft price list.
        Initialize();
        // [GIVEN] Campaign 'C', where "Starting Date" is '010120', "Ending Date" is '310120'
        LibraryMarketing.CreateCampaign(Campaign);
        Campaign.Validate("Starting Date", WorkDate());
        Campaign.Validate("Ending Date", WorkDate() + 10);
        NewDate := WorkDate() + 11;
        Campaign.Modify();
        // [GIVEN] Editing active prices is on
        LibraryPriceCalculation.AllowEditingActiveSalesPrice();
        // [GIVEN] Active Price List Header with one line, where "Source Type" is 'Campaign', "Source No." set as 'C'
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, PriceListHeader."Price Type"::Sale,
            PriceListHeader."Source Type"::Campaign, Campaign."No.");
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, PriceListHeader.Code, PriceListHeader."Source Type"::Campaign, Campaign."No.",
            "Price Asset Type"::"G/L Account", LibraryERM.CreateGLAccountNo());
        PriceListHeader.Validate(Status, "Price Status"::Draft);
        PriceListHeader.Modify(true);
        // [GIVEN] Price List Header, gets "Starting Date" is '010120', "Ending Date" is '310120' from Campaign
        VerifyDates(PriceListHeader, Campaign."Starting Date", Campaign."Ending Date");
        VerifyDates(PriceListLine, Campaign."Starting Date", Campaign."Ending Date");

        // [WHEN] Change "Ending Date" on campaign card to '010220'
        Campaign.Validate("Ending Date", NewDate);

        // [THEN] Price List Header and Line, gets "Ending Date" as '010220'
        VerifyDates(PriceListHeader, Campaign."Starting Date", NewDate);
        VerifyDates(PriceListLine, Campaign."Starting Date", NewDate);
    end;

    [Test]
    procedure T090_ActivePriceListHasDraflLinesIfAllowedEditing()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Allow Editing Active Price]
        // [SCENARIO] HasDraftLines() returns Yes for Active Price List having draft lines and "Allow Editing Active Price" is on.
        Initialize();
        // [GIVEN] Allow Editing Active Sales Price
        LibraryPriceCalculation.AllowEditingActiveSalesPrice();

        PriceListHeader.DeleteAll();

        PriceListHeader."Price Type" := "Price Type"::Sale;
        PriceListHeader.Code := 'X';
        PriceListHeader.Status := PriceListHeader.Status::Active;
        PriceListHeader.Insert(true);

        PriceListLine."Price List Code" := PriceListHeader.Code;
        PriceListLine.Status := "Price Status"::Draft;
        PriceListLine.Insert(true);

        Assert.IsTrue(PriceListHeader.HasDraftLines(), 'HasDraftLines');
    end;

    [Test]
    procedure T091_ActivePriceListHasNoDraflLinesIfDisallowedEditing()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Allow Editing Active Price]
        // [SCENARIO] HasDraftLines() returns No for Active Price List having draft lines and "Allow Editing Active Price" is off.
        Initialize();
        // [GIVEN] Allow Editing Active Sales Price
        LibraryPriceCalculation.DisallowEditingActiveSalesPrice();

        PriceListHeader.DeleteAll();

        PriceListHeader."Price Type" := "Price Type"::Sale;
        PriceListHeader.Code := 'X';
        PriceListHeader.Status := PriceListHeader.Status::Active;
        PriceListHeader.Insert(true);

        PriceListLine."Price List Code" := PriceListHeader.Code;
        PriceListLine.Status := "Price Status"::Draft;
        PriceListLine.Insert(true);

        Assert.IsFalse(PriceListHeader.HasDraftLines(), 'HasDraftLines');
    end;

    [Test]
    procedure T092_DraftPriceListHasDraflLines()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Allow Editing Active Price]
        // [SCENARIO] HasDraftLines() returns Yes for Draft Price List having draft lines.
        Initialize();

        PriceListHeader.DeleteAll();

        PriceListHeader."Price Type" := "Price Type"::Sale;
        PriceListHeader.Code := 'X';
        PriceListHeader.Status := PriceListHeader.Status::Draft;
        PriceListHeader.Insert(true);

        PriceListLine."Price List Code" := PriceListHeader.Code;
        PriceListLine.Status := "Price Status"::Draft;
        PriceListLine.Insert(true);

        Assert.IsFalse(PriceListHeader.HasDraftLines(), 'HasDraftLines');
    end;

    [Test]
    procedure T100_DeletePricesOnCampaignDeletion()
    var
        Campaign: array[2] of Record Campaign;
    begin
        Initialize();
        // [GIVEN] Two Campaigns 'A' and 'B' have related prices
        LibraryMarketing.CreateCampaign(Campaign[1]);
        LibraryMarketing.CreateCampaign(Campaign[2]);
        CreatePriceListFor("Price Source Type"::Campaign, Campaign[1]."No.", Campaign[2]."No.", "Price Amount Type"::Price);

        // [WHEN] Delete Campaign 'A'
        Campaign[1].Delete(true);

        // [THEN] Price list headers and lines for Campaign 'A' are deleted, for Campaign 'B' are not deleted
        VerifyPricesDeleted("Price Source Type"::Campaign, '', Campaign[1]."No.", Campaign[2]."No.");
    end;

    [Test]
    procedure T101_DeletePricesOnContactDeletion()
    var
        Contact: array[2] of Record Contact;
    begin
        Initialize();
        // [GIVEN] Two Contacts 'A' and 'B' have related prices
        LibraryMarketing.CreateCompanyContact(Contact[1]);
        LibraryMarketing.CreateCompanyContact(Contact[2]);
        CreatePriceListFor("Price Source Type"::Contact, Contact[1]."No.", Contact[2]."No.", "Price Amount Type"::Discount);

        // [WHEN] Delete Contact 'A'
        Contact[1].Delete(true);

        // [THEN] Price list headers and lines for Contact 'A' are deleted, for Contact 'B' are not deleted
        VerifyPricesDeleted("Price Source Type"::Contact, '', Contact[1]."No.", Contact[2]."No.");
    end;

    [Test]
    procedure T102_DeletePricesOnCustomerDeletion()
    var
        Customer: array[2] of Record Customer;
    begin
        Initialize();
        // [GIVEN] Two Customers 'A' and 'B' have related prices
        LibrarySales.CreateCustomer(Customer[1]);
        LibrarySales.CreateCustomer(Customer[2]);
        CreatePriceListFor("Price Source Type"::Customer, Customer[1]."No.", Customer[2]."No.", "Price Amount Type"::Price);

        // [WHEN] Delete Customer 'A'
        Customer[1].Delete(true);

        // [THEN] Price list headers and lines for Customer 'A' are deleted, for Customer 'B' are not deleted
        VerifyPricesDeleted("Price Source Type"::Customer, '', Customer[1]."No.", Customer[2]."No.");
    end;

    [Test]
    procedure T103_DeletePricesOnCustomerPriceGroupDeletion()
    var
        CustomerPriceGroup: array[2] of Record "Customer Price Group";
    begin
        Initialize();
        // [GIVEN] Two Customer Price Groups 'A' and 'B' have related prices
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup[1]);
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup[2]);
        CreatePriceListFor(
            "Price Source Type"::"Customer Price Group", CustomerPriceGroup[1].Code, CustomerPriceGroup[2].Code,
            "Price Amount Type"::Price);

        // [WHEN] Delete Customer Price Group 'A'
        CustomerPriceGroup[1].Delete(true);

        // [THEN] Price list headers and lines for Customer Price Group 'A' are deleted, for Customer Price Group 'B' are not deleted
        VerifyPricesDeleted("Price Source Type"::"Customer Price Group", '', CustomerPriceGroup[1].Code, CustomerPriceGroup[2].Code);
    end;

    [Test]
    procedure T104_DeletePricesOnCustomerDiscGroupDeletion()
    var
        CustomerDiscountGroup: array[2] of Record "Customer Discount Group";
    begin
        Initialize();
        // [GIVEN] Two Customer Disc Groups 'A' and 'B' have related prices
        LibraryERM.CreateCustomerDiscountGroup(CustomerDiscountGroup[1]);
        LibraryERM.CreateCustomerDiscountGroup(CustomerDiscountGroup[2]);
        CreatePriceListFor(
            "Price Source Type"::"Customer Disc. Group", CustomerDiscountGroup[1].Code, CustomerDiscountGroup[2].Code,
            "Price Amount Type"::Discount);

        // [WHEN] Delete Customer Price Group 'A'
        CustomerDiscountGroup[1].Delete(true);

        // [THEN] Price list headers and lines for Customer Disc. Group 'A' are deleted, for Customer Disc. Group 'B' are not deleted
        VerifyPricesDeleted("Price Source Type"::"Customer Disc. Group", '', CustomerDiscountGroup[1].Code, CustomerDiscountGroup[2].Code);
    end;

    [Test]
    procedure T105_DeletePricesOnVendorDeletion()
    var
        Vendor: array[2] of Record Vendor;
    begin
        Initialize();
        // [GIVEN] Two Vendors 'A' and 'B' have related prices
        LibraryPurchase.CreateVendor(Vendor[1]);
        LibraryPurchase.CreateVendor(Vendor[2]);
        CreatePriceListFor("Price Source Type"::Vendor, Vendor[1]."No.", Vendor[2]."No.", "Price Amount Type"::Discount);

        // [WHEN] Delete Vendor 'A'
        Vendor[1].Delete(true);

        // [THEN] Price list headers and lines for Vendor 'A' are deleted, for Vendor 'B' are not deleted
        VerifyPricesDeleted("Price Source Type"::Vendor, '', Vendor[1]."No.", Vendor[2]."No.");
    end;

    [Test]
    procedure T106_DeletePricesOnJobDeletion()
    var
        Job: array[2] of Record Job;
    begin
        Initialize();
        // [GIVEN] Two Jobs 'A' and 'B' have related prices
        LibraryJob.CreateJob(Job[1]);
        LibraryJob.CreateJob(Job[2]);
        CreatePriceListFor("Price Source Type"::Job, Job[1]."No.", Job[2]."No.", "Price Amount Type"::Price);

        // [WHEN] Delete Job 'A'
        Job[1].Delete(true);

        // [THEN] Price list headers and lines for Job 'A' are deleted, for Job 'B' are not deleted
        VerifyPricesDeleted("Price Source Type"::Job, '', Job[1]."No.", Job[2]."No.");
    end;

    [Test]
    procedure T107_DeletePricesOnJobTaskDeletion()
    var
        Job: Record Job;
        JobTask: array[2] of Record "Job Task";
    begin
        Initialize();
        // [GIVEN] Two Job Tasks 'A' and 'B' have related prices
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask[1]);
        LibraryJob.CreateJobTask(Job, JobTask[2]);
        CreatePriceListFor("Price Source Type"::"Job Task", JobTask[1]."Job Task No.", JobTask[2]."Job Task No.", Job."No.");

        // [WHEN] Delete Job 'A'
        JobTask[1].Delete(true);

        // [THEN] Price list headers and lines for JobTask 'A' are deleted, for JobTask 'B' are not deleted
        VerifyPricesDeleted("Price Source Type"::"Job Task", Job."No.", JobTask[1]."Job Task No.", JobTask[2]."Job Task No.");
    end;

    [Test]
    procedure T110_ModifyPricesOnCampaignRename()
    var
        Campaign: array[2] of Record Campaign;
        OldNo: Code[20];
    begin
        Initialize();
        // [GIVEN] Two Campaigns 'A' and 'B' have related prices
        LibraryMarketing.CreateCampaign(Campaign[1]);
        LibraryMarketing.CreateCampaign(Campaign[2]);
        CreatePriceListFor("Price Source Type"::Campaign, Campaign[1]."No.", Campaign[2]."No.", "Price Amount Type"::Discount);

        // [WHEN] Rename Campaign 'A' to 'X'
        OldNo := Campaign[1]."No.";
        Campaign[1].Rename(LibraryUtility.GenerateGUID());

        // [THEN] Price list headers and lines for Campaign 'A' are modified to 'X', for Campaign 'B' are not deleted
        VerifyPricesRenamed("Price Source Type"::Campaign, '', Campaign[1]."No.", OldNo, Campaign[2]."No.");
    end;

    [Test]
    procedure T111_ModifyPricesOnContactRename()
    var
        Contact: array[2] of Record Contact;
        OldNo: Code[20];
    begin
        Initialize();
        // [GIVEN] Two Contacts 'A' and 'B' have related prices
        LibraryMarketing.CreateCompanyContact(Contact[1]);
        LibraryMarketing.CreateCompanyContact(Contact[2]);
        CreatePriceListFor("Price Source Type"::Contact, Contact[1]."No.", Contact[2]."No.", "Price Amount Type"::Price);

        // [WHEN] Rename Contact 'A' to 'X'
        OldNo := Contact[1]."No.";
        Contact[1].Rename(LibraryUtility.GenerateGUID());

        // [THEN] Price list headers and lines for Contact 'A' are modified to 'X', for Contact 'B' are not deleted
        VerifyPricesRenamed("Price Source Type"::Contact, '', Contact[1]."No.", OldNo, Contact[2]."No.");
    end;

    [Test]
    procedure T112_ModifyPricesOnCustomerRename()
    var
        Customer: array[2] of Record Customer;
        OldNo: Code[20];
    begin
        Initialize();
        // [GIVEN] Two Customers 'A' and 'B' have related prices
        LibrarySales.CreateCustomer(Customer[1]);
        LibrarySales.CreateCustomer(Customer[2]);
        CreatePriceListFor("Price Source Type"::Customer, Customer[1]."No.", Customer[2]."No.", "Price Amount Type"::Price);

        // [WHEN] Rename Customer 'A' to 'X'
        OldNo := Customer[1]."No.";
        Customer[1].Rename(LibraryUtility.GenerateGUID());

        // [THEN] Price list headers and lines for Customer 'A' are modified to 'X', for Customer 'B' are not deleted
        VerifyPricesRenamed("Price Source Type"::Customer, '', Customer[1]."No.", OldNo, Customer[2]."No.");
    end;

    [Test]
    procedure T113_ModifyPricesOnCustomerPriceGroupRename()
    var
        CustomerPriceGroup: array[2] of Record "Customer Price Group";
        OldNo: Code[20];
    begin
        Initialize();
        // [GIVEN] Two Customer Price Groups 'A' and 'B' have related prices
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup[1]);
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup[2]);
        CreatePriceListFor(
            "Price Source Type"::"Customer Price Group", CustomerPriceGroup[1].Code, CustomerPriceGroup[2].Code,
            "Price Amount Type"::Price);

        // [WHEN] Rename CustomerPriceGroup 'A' to 'X'
        OldNo := CustomerPriceGroup[1].Code;
        CustomerPriceGroup[1].Rename(LibraryUtility.GenerateGUID());

        // [THEN] Price list headers and lines for CustomerPriceGroup 'A' are modified to 'X', for CustomerPriceGroup 'B' are not deleted
        VerifyPricesRenamed("Price Source Type"::"Customer Price Group", '', CustomerPriceGroup[1].Code, OldNo, CustomerPriceGroup[2].Code);
    end;

    [Test]
    procedure T114_ModifyPricesOnCustomerDiscGroupRename()
    var
        CustomerDiscountGroup: array[2] of Record "Customer Discount Group";
        OldNo: Code[20];
    begin
        Initialize();
        // [GIVEN] Two Customer Disc Groups 'A' and 'B' have related prices
        LibraryERM.CreateCustomerDiscountGroup(CustomerDiscountGroup[1]);
        LibraryERM.CreateCustomerDiscountGroup(CustomerDiscountGroup[2]);
        CreatePriceListFor(
            "Price Source Type"::"Customer Disc. Group", CustomerDiscountGroup[1].Code, CustomerDiscountGroup[2].Code,
            "Price Amount Type"::Discount);

        // [WHEN] Rename CustomerDiscountGroup 'A' to 'X'
        OldNo := CustomerDiscountGroup[1].Code;
        CustomerDiscountGroup[1].Rename(LibraryUtility.GenerateGUID());

        // [THEN] Price list headers and lines for CustomerDiscountGroup 'A' are modified to 'X', for CustomerDiscountGroup 'B' are not deleted
        VerifyPricesRenamed("Price Source Type"::"Customer Disc. Group", '', CustomerDiscountGroup[1].Code, OldNo, CustomerDiscountGroup[2].Code);
    end;

    [Test]
    procedure T115_ModifyPricesOnVendorRename()
    var
        Vendor: array[2] of Record Vendor;
        OldNo: Code[20];
    begin
        Initialize();
        // [GIVEN] Two Vendors 'A' and 'B' have related prices
        LibraryPurchase.CreateVendor(Vendor[1]);
        LibraryPurchase.CreateVendor(Vendor[2]);
        CreatePriceListFor("Price Source Type"::Vendor, Vendor[1]."No.", Vendor[2]."No.", "Price Amount Type"::Price);

        // [WHEN] Rename Vendor 'A' to 'X'
        OldNo := Vendor[1]."No.";
        Vendor[1].Rename(LibraryUtility.GenerateGUID());

        // [THEN] Price list headers and lines for Vendor 'A' are modified to 'X', for Vendor 'B' are not deleted
        VerifyPricesRenamed("Price Source Type"::Vendor, '', Vendor[1]."No.", OldNo, Vendor[2]."No.");
    end;

    [Test]
    procedure T116_ModifyPricesOnJobRename()
    var
        Job: array[2] of Record Job;
        OldNo: Code[20];
    begin
        Initialize();
        // [GIVEN] Two Jobs 'A' and 'B' have related prices
        LibraryJob.CreateJob(Job[1]);
        LibraryJob.CreateJob(Job[2]);
        CreatePriceListFor("Price Source Type"::Job, Job[1]."No.", Job[2]."No.", "Price Amount Type"::Discount);

        // [WHEN] Rename Job 'A' to 'X'
        OldNo := Job[1]."No.";
        Job[1].Rename(LibraryUtility.GenerateGUID());

        // [THEN] Price list headers and lines for Job 'A' are modified to 'X', for Job 'B' are not deleted
        VerifyPricesRenamed("Price Source Type"::Job, '', Job[1]."No.", OldNo, Job[2]."No.");

        // [THEN] Verify Price list header fields for for Job 'X'
        VerifyPricesFieldsRenamedForJob("Price Source Type"::Job, '', Job[1]."No.");
    end;

    [Test]
    procedure T117_ModifyPricesOnJobTaskRename()
    var
        Job: Record Job;
        JobTask: array[2] of Record "Job Task";
        OldNo: Code[20];
    begin
        Initialize();
        // [GIVEN] Two Job Tasks 'A' and 'B' have related prices
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask[1]);
        LibraryJob.CreateJobTask(Job, JobTask[2]);
        CreatePriceListFor("Price Source Type"::"Job Task", JobTask[1]."Job Task No.", JobTask[2]."Job Task No.", Job."No.");

        // [WHEN] Rename Job Task 'A' to 'X'
        OldNo := JobTask[1]."Job Task No.";
        JobTask[1].Rename(Job."No.", LibraryUtility.GenerateGUID());

        // [THEN] Price list headers and lines for JobTask 'A' are modified to 'X', for JobTask 'B' are not deleted
        VerifyPricesRenamed("Price Source Type"::"Job Task", Job."No.", JobTask[1]."Job Task No.", OldNo, JobTask[2]."Job Task No.");
    end;

    [Test]
    procedure T120_CopyJobWIthPrices()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        PriceListHeader: array[2] of Record "Price List Header";
        NewPriceListHeader: Record "Price List Header";
        PriceListLine: array[6] of Record "Price List Line";
        NewPriceListLine: Record "Price List Line";
        CopyJob: Codeunit "Copy Job";
        NewJobNo: Code[20];
    begin
        Initialize();
        LibraryPriceCalculation.EnableExtendedPriceCalculation();

        // [GIVEN] Job 'J' with Job Task 'JT'
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        // [GIVEN] Price List, where "Source Type" is 'Job', "Source No." is 'J'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[1], "Price Type"::Sale, "Price Source Type"::Job, Job."No.");
        FillPriceListHeader(PriceListHeader[1]);
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[1], PriceListHeader[1], "Price Amount Type"::Price, "Price Asset Type"::Item, LibraryInventory.CreateItemNo());
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[2], PriceListHeader[1], "Price Amount Type"::Price, "Price Asset Type"::Item, LibraryInventory.CreateItemNo());
        // [GIVEN] Price List, where "Source Type" is 'Job Task', "Source No." is 'JT', "Parent Source No." is 'J'
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader[2], "Price Type"::Sale, "Price Source Type"::"Job Task", Job."No.", JobTask."Job Task No.");
        FillPriceListHeader(PriceListHeader[2]);
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[3], PriceListHeader[2], "Price Amount Type"::Price, "Price Asset Type"::Item, LibraryInventory.CreateItemNo());
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[4], PriceListHeader[2], "Price Amount Type"::Price, "Price Asset Type"::Item, LibraryInventory.CreateItemNo());
        // [GIVEN] Price List Line, where 'Price List Code' is <blank>, "Source Type" is 'Job', "Source No." is 'J'
        PriceListLine[5] := PriceListLine[1];
        PriceListLine[5]."Price List Code" := '';
        PriceListLine[5]."Line No." := 0;
        PriceListLine[5].Insert();
        // [GIVEN] Price List Line, where 'Price List Code' is <blank>, "Source Type" is 'Job Task', "Source No." is 'JT', "Parent Source No." is 'J'
        PriceListLine[6] := PriceListLine[3];
        PriceListLine[6]."Price List Code" := '';
        PriceListLine[6]."Line No." := 0;
        PriceListLine[6].Insert();

        // [WHEN] Copy Job 'J' as 'NewJ'
        NewJobNo := LibraryUtility.GenerateGUID();
        CopyJob.SetCopyOptions(true, false, false, 0, 0, 0);
        CopyJob.CopyJob(Job, NewJobNo, '', '', '');

        // [THEN] Job 'NewJ' with  Job Task 'JT'
        Job.Get(NewJobNo);
        JobTask.Get(NewJobNo, JobTask."Job Task No.");
        // [GIVEN] Price List, where "Source Type" is 'Job', "Source No." is 'NewJ'
        NewPriceListHeader.SetRange("Source Type", NewPriceListHeader."Source Type"::Job);
        NewPriceListHeader.SetRange("Source No.", NewJobNo);
        Assert.RecordCount(NewPriceListHeader, 1);
        NewPriceListHeader.FindFirst();
        NewPriceListHeader.TestField("Filter Source No.", NewJobNo);
        NewPriceListHeader.TestField("Assign-to No.", NewJobNo);
        NewPriceListHeader.TestField(Description, PriceListHeader[1].Description);
        NewPriceListHeader.TestField("Currency Code", PriceListHeader[1]."Currency Code");
        NewPriceListHeader.TestField("Starting Date", PriceListHeader[1]."Starting Date");
        NewPriceListHeader.TestField("Ending Date", PriceListHeader[1]."Ending Date");

        NewPriceListLine.Reset();
        NewPriceListLine.SetRange("Source Type", NewPriceListLine."Source Type"::Job);
        NewPriceListLine.SetRange("Source No.", NewJobNo);
        Assert.RecordCount(NewPriceListLine, 3);
        NewPriceListLine.SetRange("Price List Code", NewPriceListHeader.Code);
        Assert.RecordCount(NewPriceListLine, 2);
        // [GIVEN] Price List, where "Source Type" is 'Job Task', "Source No." is 'JT', "Parent Source No." is 'NewJ'
        NewPriceListHeader.Reset();
        NewPriceListHeader.SetRange("Source Type", NewPriceListHeader."Source Type"::"Job Task");
        NewPriceListHeader.SetRange("Parent Source No.", NewJobNo);
        NewPriceListHeader.SetRange("Source No.", JobTask."Job Task No.");
        Assert.RecordCount(NewPriceListHeader, 1);
        NewPriceListHeader.FindFirst();
        NewPriceListHeader.TestField("Filter Source No.", NewJobNo);
        NewPriceListHeader.TestField("Assign-to Parent No.", NewJobNo);
        NewPriceListHeader.TestField("Assign-to No.", JobTask."Job Task No.");
        NewPriceListHeader.TestField(Description, PriceListHeader[2].Description);
        NewPriceListHeader.TestField("Currency Code", PriceListHeader[2]."Currency Code");
        NewPriceListHeader.TestField("Starting Date", PriceListHeader[2]."Starting Date");
        NewPriceListHeader.TestField("Ending Date", PriceListHeader[2]."Ending Date");

        NewPriceListLine.Reset();
        NewPriceListLine.SetRange("Source Type", NewPriceListLine."Source Type"::"Job Task");
        NewPriceListLine.SetRange("Parent Source No.", NewJobNo);
        NewPriceListLine.SetRange("Source No.", JobTask."Job Task No.");
        Assert.RecordCount(NewPriceListLine, 3);
        NewPriceListLine.SetRange("Price List Code", NewPriceListHeader.Code);
        Assert.RecordCount(NewPriceListLine, 2);
    end;

    [Test]
    procedure T130_GetDefaultPriceListCodeSales()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PriceListManagement: Codeunit "Price List Management";
    begin
        Initialize();
        // [GIVEN] "Default Price List Code" is blank in Sales Setup
        LibraryPriceCalculation.ClearDefaultPriceList("Price Type"::Sale, "Price Source Group"::Customer);
        // [WHEN] GetDefaultPriceListCode for Sale
        asserterror PriceListManagement.GetDefaultPriceListCode("Price Type"::Sale, "Price Source Group"::Customer, true);
        // [THEN] Error message: 'Default Price List Code must have a value'
        Assert.ExpectedError(StrSubstNo(MissingPriceListCodeErr, SalesReceivablesSetup.FieldCaption("Default Price List Code")));

        // [GIVEN] "Default Price List Code" is 'S0001' in Sales Setup
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Default Price List Code" := LibraryUtility.GenerateGUID();
        SalesReceivablesSetup.Modify();

        // [WHEN] GetDefaultPriceListCode for Sale
        // [THEN] returned 'S0001'
        Assert.AreEqual(
            SalesReceivablesSetup."Default Price List Code",
            PriceListManagement.GetDefaultPriceListCode("Price Type"::Sale, "Price Source Group"::Customer, true),
            'Sales default Price List Code');
    end;

    [Test]
    procedure T131_GetDefaultPriceListCodePurchase()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PriceListManagement: Codeunit "Price List Management";
    begin
        Initialize();
        // [GIVEN] "Default Price List Code" is blank in Purchase Setup
        LibraryPriceCalculation.ClearDefaultPriceList("Price Type"::Purchase, "Price Source Group"::Vendor);
        // [WHEN] GetDefaultPriceListCode for Purchase
        asserterror PriceListManagement.GetDefaultPriceListCode("Price Type"::Purchase, "Price Source Group"::Vendor, true);
        // [THEN] Error message: 'Default Price List Code must have a value'
        Assert.ExpectedError(StrSubstNo(MissingPriceListCodeErr, PurchasesPayablesSetup.FieldCaption("Default Price List Code")));

        // [GIVEN] "Default Price List Code" is 'P0001' in Purchase Setup
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Default Price List Code" := LibraryUtility.GenerateGUID();
        PurchasesPayablesSetup.Modify();

        // [WHEN] GetDefaultPriceListCode for Purchase
        // [THEN] returned 'P0001'
        Assert.AreEqual(
            PurchasesPayablesSetup."Default Price List Code",
            PriceListManagement.GetDefaultPriceListCode("Price Type"::Purchase, "Price Source Group"::Vendor, true),
            'Sales default Price List Code');
    end;

    [Test]
    procedure T132_GetDefaultPriceListCodeJobSales()
    var
        JobsSetup: Record "Jobs Setup";
        PriceListManagement: Codeunit "Price List Management";
    begin
        Initialize();
        // [GIVEN] "Default Sales Price List Code" is blank in Jobs Setup
        LibraryPriceCalculation.ClearDefaultPriceList("Price Type"::Sale, "Price Source Group"::Job);
        // [WHEN] GetDefaultPriceListCode for Job Sale
        asserterror PriceListManagement.GetDefaultPriceListCode("Price Type"::Sale, "Price Source Group"::Job, true);
        // [THEN] Error message: 'Default Sales Price List Code must have a value'
        Assert.ExpectedError(StrSubstNo(MissingPriceListCodeErr, JobsSetup.FieldCaption("Default Sales Price List Code")));

        // [GIVEN] "Default Sales Price List Code" is 'S0001' in Jobs Setup
        JobsSetup.Get();
        JobsSetup."Default Sales Price List Code" := LibraryUtility.GenerateGUID();
        JobsSetup.Modify();

        // [WHEN] GetDefaultPriceListCode for Job Sale
        // [THEN] returned 'S0001'
        Assert.AreEqual(
            JobsSetup."Default Sales Price List Code",
            PriceListManagement.GetDefaultPriceListCode("Price Type"::Sale, "Price Source Group"::Job, true),
            'Sales default Price List Code');
    end;

    [Test]
    procedure T133_GetDefaultPriceListCodeJobPurchase()
    var
        JobsSetup: Record "Jobs Setup";
        PriceListManagement: Codeunit "Price List Management";
    begin
        Initialize();
        // [GIVEN] "Default Purchase Price List Code" is blank in Job Setup
        LibraryPriceCalculation.ClearDefaultPriceList("Price Type"::Purchase, "Price Source Group"::Job);
        // [WHEN] GetDefaultPriceListCode for Job Purchase
        asserterror PriceListManagement.GetDefaultPriceListCode("Price Type"::Purchase, "Price Source Group"::Job, true);
        // [THEN] Error message: 'Default Purch Price List Code must have a value'
        Assert.ExpectedError(StrSubstNo(MissingPriceListCodeErr, JobsSetup.FieldCaption("Default Purch Price List Code")));

        // [GIVEN] "Default Purch Price List Code" is 'P0001' in Jobs Setup
        JobsSetup.Get();
        JobsSetup."Default Purch Price List Code" := LibraryUtility.GenerateGUID();
        JobsSetup.Modify();

        // [WHEN] GetDefaultPriceListCode for Job Purchase
        // [THEN] returned 'P0001'
        Assert.AreEqual(
            JobsSetup."Default Purch Price List Code",
            PriceListManagement.GetDefaultPriceListCode("Price Type"::Purchase, "Price Source Group"::Job, true),
            'Sales default Price List Code');
    end;

    [Test]
    procedure T135_NewLineWithNumberOver1bnGoesToNewDefaultPriceListSales()
    var
        PriceListLine: Record "Price List Line";
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
        PriceListManagement: Codeunit "Price List Management";
        DefaultPriceListCode: array[2] of Code[20];
    begin
        Initialize();
        // [GIVEN] "Default Price List Code" is Sales Setup is 'S0001'
        DefaultPriceListCode[1] :=
            LibraryPriceCalculation.SetDefaultPriceList("Price Type"::Sale, "Price Source Group"::Customer);
        // [GIVEN] Price List 'S0001' has the line, where "Line No." is 1000000000
        PriceListLine.Init();
        PriceListLine.Validate("Price List Code", DefaultPriceListCode[1]);
        PriceListLine."Line No." := 1000000000;
        PriceListLine.Insert();

        // [GIVEN] new Price List line, where "Price Source Type" 'All Customers'
        PriceListLine.Init();
        PriceListLine.Validate("Source Type", "Price Source Type"::"All Customers");

        // [WHEN] InitLineNo() for new Price List Line
        CopyFromToPriceListLine.SetGenerateHeader(true);
        CopyFromToPriceListLine.InitLineNo(PriceListLine);

        // [THEN] Price List Line is the first line of the new default price list 'S0002'
        DefaultPriceListCode[2] :=
            PriceListManagement.GetDefaultPriceListCode("Price Type"::Sale, "Price Source Group"::Customer, true);
        Assert.AreNotEqual(DefaultPriceListCode[1], DefaultPriceListCode[2], 'Default price list code is not changed');
        PriceListLine.TestField("Price List Code", DefaultPriceListCode[2]);
        PriceListLine.TestField("Line No.", 10000);
    end;

    [Test]
    procedure T136_NewLineWithNumberOver1bnGoesToNewDefaultPriceListPurch()
    var
        PriceListLine: Record "Price List Line";
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
        PriceListManagement: Codeunit "Price List Management";
        DefaultPriceListCode: array[2] of Code[20];
    begin
        Initialize();
        // [GIVEN] "Default Price List Code" is Purch Setup is 'P0001'
        DefaultPriceListCode[1] :=
            LibraryPriceCalculation.SetDefaultPriceList("Price Type"::Purchase, "Price Source Group"::Vendor);
        // [GIVEN] Price List 'P0001' has the line, where "Line No." is 1000000000
        PriceListLine.Init();
        PriceListLine.Validate("Price List Code", DefaultPriceListCode[1]);
        PriceListLine."Line No." := 1000000000;
        PriceListLine.Insert();

        // [GIVEN] new Price List line, where "Price Source Type" 'All Vendors'
        PriceListLine.Init();
        PriceListLine.Validate("Source Type", "Price Source Type"::"All Vendors");

        // [WHEN] InitLineNo() for new Price List Line
        CopyFromToPriceListLine.SetGenerateHeader(true);
        CopyFromToPriceListLine.InitLineNo(PriceListLine);

        // [THEN] Price List Line is the first line of the new default price list 'P0002'
        DefaultPriceListCode[2] :=
            PriceListManagement.GetDefaultPriceListCode("Price Type"::Purchase, "Price Source Group"::Vendor, true);
        Assert.AreNotEqual(DefaultPriceListCode[1], DefaultPriceListCode[2], 'Default price list code is not changed');
        PriceListLine.TestField("Price List Code", DefaultPriceListCode[2]);
        PriceListLine.TestField("Line No.", 10000);
    end;

    [Test]
    procedure T137_NewLineWithNumberOver1bnGoesToNewDefaultPriceListJobSales()
    var
        PriceListLine: Record "Price List Line";
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
        PriceListManagement: Codeunit "Price List Management";
        DefaultPriceListCode: array[2] of Code[20];
    begin
        Initialize();
        // [GIVEN] "Default Sales Price List Code" is Jobs Setup is 'S0001'
        DefaultPriceListCode[1] :=
            LibraryPriceCalculation.SetDefaultPriceList("Price Type"::Sale, "Price Source Group"::Job);
        // [GIVEN] Price List 'S0001' has the line, where "Line No." is 1000000000
        PriceListLine.Init();
        PriceListLine.Validate("Price List Code", DefaultPriceListCode[1]);
        PriceListLine."Line No." := 1000000000;
        PriceListLine.Insert();

        // [GIVEN] new Price List line, where "Price Source Type" 'All Jobs', "Price Type" 'Sale'
        PriceListLine.Init();
        PriceListLine.Validate("Source Type", "Price Source Type"::"All Jobs");
        PriceListLine.Validate("Price Type", "Price Type"::Sale);

        // [WHEN] InitLineNo() for new Price List Line
        CopyFromToPriceListLine.SetGenerateHeader(true);
        CopyFromToPriceListLine.InitLineNo(PriceListLine);

        // [THEN] Price List Line is the first line of the new default price list 'S0002'
        DefaultPriceListCode[2] :=
            PriceListManagement.GetDefaultPriceListCode("Price Type"::Sale, "Price Source Group"::Job, true);
        Assert.AreNotEqual(DefaultPriceListCode[1], DefaultPriceListCode[2], 'Default price list code is not changed');
        PriceListLine.TestField("Price List Code", DefaultPriceListCode[2]);
        PriceListLine.TestField("Line No.", 10000);
    end;

    [Test]
    procedure T138_NewLineWithNumberOver1bnGoesToNewDefaultPriceListJobPurch()
    var
        PriceListLine: Record "Price List Line";
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
        PriceListManagement: Codeunit "Price List Management";
        DefaultPriceListCode: array[2] of Code[20];
    begin
        Initialize();
        // [GIVEN] "Default Purch Price List Code" is Jobs Setup is 'P0001'
        DefaultPriceListCode[1] :=
            LibraryPriceCalculation.SetDefaultPriceList("Price Type"::Purchase, "Price Source Group"::Job);
        // [GIVEN] Price List 'P0001' has the line, where "Line No." is 1000000000
        PriceListLine.Init();
        PriceListLine.Validate("Price List Code", DefaultPriceListCode[1]);
        PriceListLine."Line No." := 1000000000;
        PriceListLine.Insert();

        // [GIVEN] new Price List line, where "Price Source Type" 'All Jobs', "Price Type" 'Purchase'
        PriceListLine.Init();
        PriceListLine.Validate("Source Type", "Price Source Type"::"All Jobs");
        PriceListLine.Validate("Price Type", "Price Type"::Purchase);

        // [WHEN] InitLineNo() for new Price List Line
        CopyFromToPriceListLine.SetGenerateHeader(true);
        CopyFromToPriceListLine.InitLineNo(PriceListLine);

        // [THEN] Price List Line is the first line of the new default price list 'P0002'
        DefaultPriceListCode[2] :=
            PriceListManagement.GetDefaultPriceListCode("Price Type"::Purchase, "Price Source Group"::Job, true);
        Assert.AreNotEqual(DefaultPriceListCode[1], DefaultPriceListCode[2], 'Default price list code is not changed');
        PriceListLine.TestField("Price List Code", DefaultPriceListCode[2]);
        PriceListLine.TestField("Line No.", 10000);
    end;

    [Test]
    procedure VerifyValuesOnPriceListHeaderAndPriceListLineWhenResourceAndJobTaskRename()
    var
        PriceListHeader: array[2] of Record "Price List Header";
        PriceListLine: array[2] of Record "Price List Line";
        Resource: Record Resource;
        Job: array[2] of Record Job;
        JobTask: array[2] of Record "Job Task";
        JobTask2: Record "Job Task";
        ResourceNo: Code[20];
    begin
        // [SCENARIO 450480] The values on the sales Job Price list should be updated correctly.
        Initialize();

        // [GIVEN] Create 2 Jobs with Job Tasks and Create Resource.
        LibraryJob.CreateJob(Job[1]);
        LibraryJob.CreateJob(Job[2]);
        LibraryJob.CreateJobTask(Job[1], JobTask[1]);
        LibraryJob.CreateJobTask(Job[2], JobTask[2]);
        ResourceNo := LibraryResource.CreateResourceNo();

        // [GIVEN] Create 1st Price List Header and it's Price List Line.
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader[1], "Price Type"::Sale, PriceListHeader[1]."Source Type"::"Job Task", Job[1]."No.", JobTask[1]."Job Task No.");
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[1], PriceListHeader[1], "Price Amount Type"::Price, "Price Asset Type"::Resource, ResourceNo);

        // [GIVEN] Create 2nd Price List Header and it's Price List Line.
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader[2], "Price Type"::Sale, PriceListHeader[2]."Source Type"::"Job Task", Job[2]."No.", JobTask[2]."Job Task No.");
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[2], PriceListHeader[2], "Price Amount Type"::Price, "Price Asset Type"::Resource, ResourceNo);

        // [WHEN] Rename the Resource No.
        Resource.Get(ResourceNo);
        Resource.Rename(LibraryUtility.GenerateGUID());

        // [THEN] Verify Resource No. is updated in Price List Line.
        PriceListLine[1].Find();
        Assert.AreEqual(Resource."No.", PriceListLine[1]."Product No.", ResourceNoErr);

        // [WHEN] Rename the Job Task No.
        JobTask2.Get(JobTask[2]."Job No.", JobTask[2]."Job Task No.");
        JobTask2.Rename(Job[2]."No.", LibraryUtility.GenerateGUID());

        // [THEN] Verify the Job Task No. is not updated in 1st Price List Header.
        Assert.AreNotEqual(PriceListHeader[1]."Source No.", JobTask2."Job Task No.", SourceNoErr);

        // [THEN] Verify the Assign-to No. is updated in 2nd Price List Header.
        Assert.AreEqual(PriceListHeader[2]."Source No.", PriceListHeader[2]."Assign-to No.", AssignToNoErr);
    end;

    [Test]
    procedure VerifyUnitCostInJobJournalWhenUsingPurchasePriceList()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        JobJournalLine: Record "Job Journal Line";
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        // [SCENARIO 450229] Purchase price list doesn't work in job journal
        Initialize();

        // [GIVEN] Enable the new sales pricing in feature management
        LibraryPriceCalculation.EnableExtendedPriceCalculation();

        // [GIVEN] Create Price List Header
        PriceListHeader.Code := LibraryUtility.GenerateGUID();
        PriceListHeader."Price Type" := PriceListHeader."Price Type"::Purchase;
        PriceListHeader.Validate("Source Type", PriceListHeader."Source Type"::"All Vendors");
        PriceListHeader."Source Group" := PriceListHeader."Source Group"::Vendor;
        PriceListHeader.Validate("Amount Type", PriceListHeader."Amount Type"::Price);
        PriceListHeader.Validate("Allow Updating Defaults", true);
        PriceListHeader.Status := PriceListHeader.Status::Active;
        PriceListHeader.Insert(true);

        // [GIVEN] Create Price List Line
        PriceListLine."Price List Code" := PriceListHeader.Code;
        PriceListLine."Line No." := 10000;
        PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::Resource);
        PriceListLine.Validate("Asset No.", LibraryResource.CreateResourceNo());
        PriceListLine.Validate("Minimum Quantity", 4);
        PriceListLine.Validate("Direct Unit Cost", 6);
        PriceListLine.Validate("Unit Cost", 6);
        PriceListLine."Source Group" := PriceListLine."Source Group"::Vendor;
        PriceListLine.Validate("Source Type", PriceListLine."Source Type"::"All Vendors");
        PriceListLine."Price Type" := PriceListLine."Price Type"::Purchase;
        PriceListLine.Status := PriceListLine.Status::Active;
        PriceListLine.Insert(true);

        // [GIVEN] Create Job, Job Task, Job Journal Line
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobJournalLine(JobJournalLine."Line Type"::" ", JobTask, JobJournalLine);
        JobJournalLine.Type := JobJournalLine.Type::Resource;
        JobJournalLine.Validate("No.", PriceListLine."Asset No.");

        // [WHEN] Assign quanity in Job Journal Line
        JobJournalLine.Validate(Quantity, 4);
        JobJournalLine.Modify();

        // [THEN] Verify unit cost are equal
        Assert.AreEqual(JobJournalLine."Unit Cost", PriceListLine."Direct Unit Cost", UnitCostErr);
    end;

    local procedure Initialize()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        JobsSetup: Record "Jobs Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Price List Header UT");
        LibraryVariableStorage.Clear();

        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Price List Header UT");

        LibraryPriceCalculation.DisAllowEditingActivePurchPrice();
        LibraryPriceCalculation.DisAllowEditingActiveSalesPrice();

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Price List Nos.", LibraryERM.CreateNoSeriesCode('SAL'));
        SalesReceivablesSetup.Modify();

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Price List Nos.", LibraryERM.CreateNoSeriesCode('PUR'));
        PurchasesPayablesSetup.Modify();

        JobsSetup.Get();
        JobsSetup.Validate("Price List Nos.", LibraryERM.CreateNoSeriesCode('JOB'));
        JobsSetup.Modify();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Price List Header UT");
    end;

    local procedure CreatePriceList(var PriceListHeader: Record "Price List Header"; var PriceListLine: Record "Price List Line")
    begin
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, PriceListHeader."Price Type"::Sale,
            PriceListHeader."Source Type"::"All Customers", '');
        FillPriceListHeader(PriceListHeader);
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::"G/L Account", LibraryERM.CreateGLAccountNo());
    end;

    local procedure CreatePriceListFor(SourceType: Enum "Price Source Type"; DeletedSourceNo: Code[20]; SourceNo: Code[20]; ParentSourceNo: Code[20])
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        PriceListHeader.DeleteAll();
        PriceListLine.DeleteAll();

        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Sale, SourceType, ParentSourceNo, DeletedSourceNo);
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::Resource, LibraryResource.CreateResourceNo());

        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Sale, SourceType, ParentSourceNo, SourceNo);
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::Resource, LibraryResource.CreateResourceNo());
    end;

    local procedure CreatePriceListFor(SourceType: Enum "Price Source Type"; DeletedSourceNo: Code[20]; SourceNo: Code[20]; AmountType: Enum "Price Amount Type")
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        PriceListHeader.DeleteAll();
        PriceListLine.DeleteAll();

        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Sale, SourceType, DeletedSourceNo);
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine, PriceListHeader, AmountType, "Price Asset Type"::"G/L Account", LibraryERM.CreateGLAccountNo());

        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Sale, SourceType, SourceNo);
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine, PriceListHeader, AmountType, "Price Asset Type"::"G/L Account", LibraryERM.CreateGLAccountNo());
    end;

    local procedure FillPriceListHeader(var PriceListHeader: Record "Price List Header")
    var
        Currency: Record Currency;
    begin
        PriceListHeader.Description := LibraryUtility.GenerateGUID();
        PriceListHeader."Starting Date" := LibraryRandom.RandDate(50);
        PriceListHeader."Ending Date" := PriceListHeader."Starting Date" + 30;
        LibraryERM.CreateCurrency(Currency);
        PriceListHeader."Currency Code" := Currency.Code;
        PriceListHeader.Modify();
    end;

    local procedure NewSourceJobTask(var PriceListHeader: Record "Price List Header")
    var
        PriceSource: Record "Price Source";
    begin
        PriceSource.NewEntry(PriceSource."Source Type"::"Job Task", 0);
        PriceSource."Parent Source No." := PriceListHeader."Parent Source No.";
        PriceSource.Validate("Source No.", NewJobTask(PriceSource."Parent Source No.", PriceSource."Source ID"));
        PriceListHeader.CopyFrom(PriceSource);
    end;

    local procedure NewJobTask(var JobNo: Code[20]; var SystemID: Guid) JobTaskNo: Code[20]
    var
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        if not Job.Get(JobNo) then begin
            LibraryJob.CreateJob(Job);
            JobNo := Job."No.";
        end;
        LibraryJob.CreateJobTask(Job, JobTask);
        JobTaskNo := JobTask."Job Task No.";
        SystemID := JobTask.SystemId;
    end;

    local procedure VerifyBlankSource(PriceListHeader: Record "Price List Header")
    var
        BlankGuid: Guid;
    begin
        PriceListHeader.Testfield("Parent Source No.", '');
        PriceListHeader.Testfield("Source No.", '');
        PriceListHeader.Testfield("Source ID", BlankGuid);
    end;

    local procedure VerifyDates(PriceListHeader: Record "Price List Header"; StartingDate: Date; EndingDate: Date)
    begin
        if PriceListHeader.Code <> '' then
            PriceListHeader.Find();
        PriceListHeader.TestField("Starting Date", StartingDate);
        PriceListHeader.TestField("Ending Date", EndingDate);
    end;

    local procedure VerifyDates(PriceListLine: Record "Price List Line"; StartingDate: Date; EndingDate: Date)
    begin
        PriceListLine.Find();
        PriceListLine.TestField("Starting Date", StartingDate);
        PriceListLine.TestField("Ending Date", EndingDate);
    end;

    local procedure VerifyPricesDeleted(SourceType: Enum "Price Source Type"; ParentSourceNo: Code[20]; DeletedSourceNo: Code[20]; SourceNo: Code[20])
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        PriceListHeader.SetRange("Source Type", SourceType);
        PriceListHeader.SetRange("Parent Source No.", ParentSourceNo);
        PriceListHeader.SetRange("Source No.", DeletedSourceNo);
        Assert.RecordIsEmpty(PriceListHeader);
        PriceListHeader.SetRange("Source No.", SourceNo);
        Assert.RecordIsNotEmpty(PriceListHeader);

        PriceListLine.SetRange("Source Type", SourceType);
        PriceListLine.SetRange("Parent Source No.", ParentSourceNo);
        PriceListLine.SetRange("Source No.", DeletedSourceNo);
        Assert.RecordIsEmpty(PriceListLine);
        PriceListLine.SetRange("Source No.", SourceNo);
        Assert.RecordIsNotEmpty(PriceListLine);
    end;

    local procedure VerifyPricesRenamed(SourceType: Enum "Price Source Type"; ParentSourceNo: Code[20]; NewSourceNo: Code[20]; RenamedSourceNo: Code[20]; SourceNo: Code[20])
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        PriceListHeader.SetRange("Source Type", SourceType);
        PriceListHeader.SetRange("Parent Source No.", ParentSourceNo);
        PriceListHeader.SetRange("Source No.", RenamedSourceNo);
        Assert.RecordIsEmpty(PriceListHeader);
        PriceListHeader.SetRange("Source No.", NewSourceNo);
        Assert.RecordIsNotEmpty(PriceListHeader);
        PriceListHeader.SetRange("Source No.", SourceNo);
        Assert.RecordIsNotEmpty(PriceListHeader);

        PriceListLine.SetRange("Source Type", SourceType);
        PriceListLine.SetRange("Parent Source No.", ParentSourceNo);
        PriceListLine.SetRange("Source No.", RenamedSourceNo);
        Assert.RecordIsEmpty(PriceListLine);
        PriceListLine.SetRange("Source No.", NewSourceNo);
        Assert.RecordIsNotEmpty(PriceListLine);
        PriceListLine.SetRange("Source No.", SourceNo);
        Assert.RecordIsNotEmpty(PriceListLine);
    end;

    local procedure VerifyPricesFieldsRenamedForJob(SourceType: Enum "Price Source Type"; ParentSourceNo: Code[20]; NewSourceNo: Code[20])
    var
        PriceListHeader: Record "Price List Header";
    begin
        PriceListHeader.SetRange("Source Type", SourceType);
        PriceListHeader.SetRange("Parent Source No.", ParentSourceNo);
        PriceListHeader.SetRange("Source No.", NewSourceNo);
        if PriceListHeader.FindSet() then
            repeat
                PriceListHeader.TestField("Filter Source No.", NewSourceNo);
                PriceListHeader.TestField("Assign-to No.", NewSourceNo);
            until PriceListHeader.Next() = 0;
    end;

    [ModalPageHandler]
    procedure LookupCustomerModalHandler(var CustomerLookup: TestPage "Customer Lookup")
    begin
        CustomerLookup.Filter.SetFilter("No.", LibraryVariableStorage.DequeueText());
        CustomerLookup.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [ConfirmHandler]
    procedure ConfirmNoHandler(Question: Text; var Reply: Boolean)
    begin
        LibraryVariableStorage.Enqueue(Question);
        Reply := false;
    end;

    [ConfirmHandler]
    procedure ConfirmYesHandler(Question: Text; var Reply: Boolean)
    begin
        LibraryVariableStorage.Enqueue(Question);
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmYesSimpleHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;
}
