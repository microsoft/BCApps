codeunit 137274 "Item Jnl. Error Handling"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [UI] [Journal Error Handling]
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        TestFieldMustHaveValueErr: Label '%1 must have a value', Comment = '%1 - field caption';
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure ItemJournalSunshine()
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournal: TestPage "Item Journal";
        Item: Record Item;
    begin
        // [FEATURE] [Item Journal]
        // [SCENARIO 411162] Journal errors factbox works for item journal
        Initialize();

        // [GIVEN] Create journal line for item without Base Item Measure Code
        CreateItemJournalLineForItemWithoutBaseUOMForTemplate(ItemJournalLine);
        Commit();

        // [WHEN] Open item journal for batch "XXX"
        ItemJournal.Trap();
        Page.Run(Page::"Item Journal", ItemJournalLine);

        // [THEN] Journal Errors factbox shows message "Base Unit of Measure must have a value."
        VerifyErrorMessageText(
            ItemJournal.JournalErrorsFactBox.Error1.Value(),
            StrSubstNo(TestFieldMustHaveValueErr, Item.FieldCaption("Base Unit of Measure")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemJournalNumberOfBatchErrors()
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournal: TestPage "Item Journal";
        i: Integer;
        NumbefOfLines: Integer;
    begin
        // [FEATURE] [Item Journal]
        // [SCENARIO 411162] Journal errors factbox shows the number of batch errors
        Initialize();

        // [GIVEN] Create 5 journal lines with empty "Document No."
        SelectItemJournal(ItemJournalBatch);
        NumbefOfLines := LibraryRandom.RandIntInRange(5, 10);
        for i := 1 to NumbefOfLines do
            CreateItemJournalLineWithEmptyDoc(ItemJournalLine, ItemJournalBatch);

        // [WHEN] Open item journal for batch "XXX"
        ItemJournal.Trap();
        Page.Run(Page::"Item Journal", ItemJournalLine);

        // [THEN] Journal Errors factbox shows Lines with Issues = 5
        ItemJournal.JournalErrorsFactBox.NumberOfBatchErrors.AssertEquals(NumbefOfLines);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteJnlLineWithErrors()
    var
        ItemJournalLine: array[2] of Record "Item Journal Line";
        TempErrorMessage: Record "Error Message" temporary;
        ItemJournalBatch: Record "Item Journal Batch";
        ErrorHandlingParameters: Record "Error Handling Parameters";
        BackgroundErrorHandlingMgt: Codeunit "Background Error Handling Mgt.";
        TemJournalErrorsMgt: Codeunit "Item Journal Errors Mgt.";
        Args: Dictionary of [Text, Text];
    begin
        // [FEATURE] [Item Journal]
        // [SCENARIO 411162] Errors for deleted journal lines removed from error messages
        Initialize();

        // [GIVEN] journal lines with empty BaseUOM items: Line1 and Line2
        SelectItemJournal(ItemJournalBatch);
        CreateItemJournalLineForItemWithoutBaseUOM(ItemJournalLine[1], ItemJournalBatch);

        CreateItemJournalLineForItemWithoutBaseUOM(ItemJournalLine[2], ItemJournalBatch);

        // [GIVEN] Mock 2 error messages for Line1 and Line2
        MockFullBatchCheck(
            ItemJournalLine[1]."Journal Template Name",
            ItemJournalLine[1]."Journal Batch Name",
            TempErrorMessage);

        // [GIVEN] Mock Line2 deleted
        TemJournalErrorsMgt.InsertDeletedItemJnlLine(ItemJournalLine[2]);
        ItemJournalLine[2].Delete();

        // [WHEN] Run CleanTempErrorMessages 
        BackgroundErrorHandlingMgt.PackDeletedDocumentsToArgs(Args); // Mock call from "Journal Errors Factbox".CheckErrorsInBackground
        SetErrorHandlingParameters(ErrorHandlingParameters, ItemJournalLine[1], 0);
        BackgroundErrorHandlingMgt.CleanItemJnlTempErrorMessages(TempErrorMessage, ErrorHandlingParameters);

        // [THEN] Error message about Line2 deleted
        TempErrorMessage.Reset();
        TempErrorMessage.SetRange("Context Record ID", ItemJournalLine[2].RecordId);
        Assert.IsTrue(TempErrorMessage.IsEmpty, 'Error message for line 2 has to be deleted.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemJournalShowAllLinesActionsEnabledState()
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournal: TestPage "Item Journal";
        LinesWithIssuesCounter: Integer;
    begin
        // [SCENARIO 411162] Action "Show All Lines" makes action "Show Lines with Errors" enabled
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" 
        CreateEmptyDocItemJournalLineForTemplate(ItemJournalLine);

        // [GIVEN] Open item journal for batch "XXX"
        ItemJournal.Trap();
        Page.Run(Page::"Item Journal", ItemJournalLine);
        // [WHEN] Action "Show Lines with Errors" is selected
        ItemJournal.ShowLinesWithErrors.Invoke();

        // [THEN] Check that there is one line shown in the journal
        if ItemJournal.First() then
            repeat
                LinesWithIssuesCounter += 1;
            until not ItemJournal.Next();
        Assert.AreEqual(1, LinesWithIssuesCounter - 1, 'There must be exactly one line shown in the journal');

        // [WHEN] Action "Show All Lines" is being selected
        ItemJournal.ShowAllLines.Invoke();

        // [THEN] Action "Show Lines with Errors" enabled
        Assert.IsTrue(ItemJournal.ShowLinesWithErrors.Enabled(), 'Action ShowLinesWithErrors must be enabled');
        // [THEN] Action "Show All Lines" disabled
        Assert.IsFalse(ItemJournal.ShowAllLines.Enabled(), 'Action ShowAllLines must be disabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemJournalCheckUpdatedLineWithError()
    var
        ItemJournalLine: array[2] of Record "Item Journal Line";
        TempErrorMessage: Record "Error Message" temporary;
        ItemJournalBatch: Record "Item Journal Batch";
        ErrorHandlingParameters: Record "Error Handling Parameters";
        BackgroundErrorHandlingMgt: Codeunit "Background Error Handling Mgt.";
        TemJournalErrorsMgt: Codeunit "Item Journal Errors Mgt.";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 411162] Updated line checked after moving focus to another line and fixed error deleted
        Initialize();

        // [GIVEN] journal lines with empty Document No.: Line1 and Line2
        SelectItemJournal(ItemJournalBatch);
        CreateItemJournalLineWithEmptyDoc(ItemJournalLine[1], ItemJournalBatch);

        CreateItemJournalLineWithEmptyDoc(ItemJournalLine[2], ItemJournalBatch);

        // [GIVEN] Mock 2 error messages for Line1 and Line2
        MockFullBatchCheck(
            ItemJournalLine[1]."Journal Template Name",
            ItemJournalLine[1]."Journal Batch Name",
            TempErrorMessage);
        TempErrorMessage.Reset();
        Assert.AreEqual(2, TempErrorMessage.Count, 'Invalid number of error messages');

        // [GIVEN] Set Document No. = 'XXX' for Line 2 and mock it is modified
        ItemJournalLine[2]."Document No." := LibraryRandom.RandText(MaxStrLen(ItemJournalLine[2]."Document No."));
        ItemJournalLine[2].Modify();
        TemJournalErrorsMgt.SetItemJnlLineOnModify(ItemJournalLine[2]);

        // [WHEN] Run CleanTempErrorMessages
        SetErrorHandlingParameters(ErrorHandlingParameters, ItemJournalLine[1], ItemJournalLine[2]."Line No.");
        BackgroundErrorHandlingMgt.CleanItemJnlTempErrorMessages(TempErrorMessage, ErrorHandlingParameters);

        // [THEN] Error message about Line2 deleted
        TempErrorMessage.Reset();
        TempErrorMessage.SetRange("Context Record ID", ItemJournalLine[2].RecordId);
        Assert.IsTrue(TempErrorMessage.IsEmpty, 'Error message for line 2 has to be deleted.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemJournalCheckUpdatedLineNewError()
    var
        ItemJournalLine: array[2] of Record "Item Journal Line";
        TempErrorMessage: Record "Error Message" temporary;
        ItemJournalBatch: Record "Item Journal Batch";
        ErrorHandlingParameters: Record "Error Handling Parameters";
        TemJournalErrorsMgt: Codeunit "Item Journal Errors Mgt.";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 411162] Updated line checked after moving focus to another line and new error found
        Initialize();

        // [GIVEN] journal lines with not empty Document No.: Line1 and Line2
        SelectItemJournal(ItemJournalBatch);
        CreateItemJournalLine(ItemJournalLine[1], ItemJournalBatch);
        CreateItemJournalLine(ItemJournalLine[2], ItemJournalBatch);

        // [GIVEN] Set Document No. = '' for Line 2 and mock it is modified
        ItemJournalLine[2]."Document No." := '';
        ItemJournalLine[2].Modify();
        TemJournalErrorsMgt.SetItemJnlLineOnModify(ItemJournalLine[2]);

        // [WHEN] Run background check
        SetErrorHandlingParameters(ErrorHandlingParameters, ItemJournalLine[1], ItemJournalLine[2]."Line No.");
        RunBackgroundCheck(ErrorHandlingParameters, TempErrorMessage);

        // [THEN] Empty document error message about Line2 created
        TempErrorMessage.Reset();
        TempErrorMessage.FindFirst();

        VerifyErrorMessageText(
            TempErrorMessage."Message",
            StrSubstNo(TestFieldMustHaveValueErr, ItemJournalLine[2].FieldCaption("Document No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CapacityJournalSunshine()
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        CapacityJournal: TestPage "Capacity Journal";
    begin
        // [FEATURE] [Capacity Journal]
        // [SCENARIO 411162] Journal errors factbox works for Capacity journal
        Initialize();

        // [GIVEN] Create journal line with empty Document No.
        SelectItemJournal(ItemJournalBatch, "Item Journal Template Type"::Capacity);
        CreateItemJournalLineWithEmptyDoc(ItemJournalLine, ItemJournalBatch);

        // [WHEN] Open item journal for batch "XXX"
        CapacityJournal.Trap();
        Page.Run(Page::"Capacity Journal", ItemJournalLine);

        // [THEN] Journal Errors factbox shows message "Document No. must not be empty."
        VerifyErrorMessageText(
            CapacityJournal.JournalErrorsFactBox.Error1.Value,
            StrSubstNo(TestFieldMustHaveValueErr, ItemJournalLine.FieldCaption("Document No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConsumptionJournalSunshine()
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ConsumptionJournal: TestPage "Consumption Journal";
    begin
        // [FEATURE] [Consumption Journal]
        // [SCENARIO 411162] Journal errors factbox works for Consumption journal
        Initialize();

        // [GIVEN] Create journal line with empty Document No.
        SelectItemJournal(ItemJournalBatch, "Item Journal Template Type"::Consumption);
        CreateItemJournalLineWithEmptyDoc(ItemJournalLine, ItemJournalBatch);

        // [WHEN] Open item journal for batch "XXX"
        ConsumptionJournal.Trap();
        Page.Run(Page::"Consumption Journal", ItemJournalLine);

        // [THEN] Journal Errors factbox shows message "Document No. must not be empty."
        VerifyErrorMessageText(
            ConsumptionJournal.JournalErrorsFactBox.Error1.Value,
            StrSubstNo(TestFieldMustHaveValueErr, ItemJournalLine.FieldCaption("Document No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemReclassJournalJournalSunshine()
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemReclassJournal: TestPage "Item Reclass. Journal";
    begin
        // [FEATURE] [Item Reclass. Journal]
        // [SCENARIO 411162] Journal errors factbox works for Item Reclass. Journal journal
        Initialize();

        // [GIVEN] Create journal line with empty Document No.
        SelectItemJournal(ItemJournalBatch, "Item Journal Template Type"::Transfer);
        CreateItemJournalLineWithEmptyDoc(ItemJournalLine, ItemJournalBatch);

        // [WHEN] Open item journal for batch "XXX"
        ItemReclassJournal.Trap();
        Page.Run(Page::"Item Reclass. Journal", ItemJournalLine);

        // [THEN] Journal Errors factbox shows message "Document No. must not be empty."
        VerifyErrorMessageText(
            ItemReclassJournal.JournalErrorsFactBox.Error1.Value,
            StrSubstNo(TestFieldMustHaveValueErr, ItemJournalLine.FieldCaption("Document No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OutputJournalSunshine()
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        OutputJournal: TestPage "Output Journal";
    begin
        // [FEATURE] [Output Journal]
        // [SCENARIO 411162] Journal errors factbox works for Output journal
        Initialize();

        // [GIVEN] Create journal line with empty Document No.
        SelectItemJournal(ItemJournalBatch, "Item Journal Template Type"::Output);
        CreateItemJournalLineWithEmptyDoc(ItemJournalLine, ItemJournalBatch);

        // [WHEN] Open item journal for batch "XXX"
        OutputJournal.Trap();
        Page.Run(Page::"Output Journal", ItemJournalLine);

        // [THEN] Journal Errors factbox shows message "Document No. must not be empty."
        VerifyErrorMessageText(
            OutputJournal.JournalErrorsFactBox.Error1.Value,
            StrSubstNo(TestFieldMustHaveValueErr, ItemJournalLine.FieldCaption("Document No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PhysInventoryJournalSunshine()
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        PhysInventoryJournal: TestPage "Phys. Inventory Journal";
    begin
        // [FEATURE] [Phys. Inventory Journal]
        // [SCENARIO 411162] Journal errors factbox works for Phys. Inventory journal
        Initialize();

        // [GIVEN] Create journal line with empty Document No.
        SelectItemJournal(ItemJournalBatch, "Item Journal Template Type"::"Phys. Inventory");
        CreateItemJournalLineWithEmptyDoc(ItemJournalLine, ItemJournalBatch);

        // [WHEN] Open item journal for batch "XXX"
        PhysInventoryJournal.Trap();
        Page.Run(Page::"Phys. Inventory Journal", ItemJournalLine);

        // [THEN] Journal Errors factbox shows message "Document No. must not be empty."
        VerifyErrorMessageText(
            PhysInventoryJournal.JournalErrorsFactBox.Error1.Value,
            StrSubstNo(TestFieldMustHaveValueErr, ItemJournalLine.FieldCaption("Document No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemSourceError()
    var
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
        ItemJournal: TestPage "Item Journal";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Item Journal]
        // [SCENARIO 411162] Item related error shows Item Source Record Id and Source Field No
        Initialize();

        // [GIVEN] Create journal line for item "I" without Base Item Measure Code
        CreateItemJournalLineForItemWithoutBaseUOMForTemplate(ItemJournalLine);
        Item.Get(ItemJournalLine."Item No.");

        // [GIVEN] Open item journal for batch "XXX"
        ItemJournal.Trap();
        Page.Run(Page::"Item Journal", ItemJournalLine);

        // [WHEN] DrillDown from batch errors
        ErrorMessages.Trap();
        ItemJournal.JournalErrorsFactBox.NumberOfBatchErrors.Drilldown();

        // [THEN] Error Messages page shows Source = "Item: I" and Field Name = "Base Unit of Measure"
        ErrorMessages.Filter.SetFilter("Record ID", Format(Item.RecordId));
        ErrorMessages."Field Name".AssertEquals(Item.FieldName("Base Unit of Measure"));
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Item Jnl. Error Handling");
        LibrarySetupStorage.Restore();
        Commit(); // need to notify background sessions about data restore
        if IsInitialized then
            exit;

        SetEnableDataCheck(true);
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Item Jnl. Error Handling");

        Commit();
        IsInitialized := true;
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Item Jnl. Error Handling");
    end;

    local procedure SetEnableDataCheck(Enabled: Boolean)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup.Validate("Enable Data Check", Enabled);
        GLSetup.Modify();
    end;

    local procedure CreateEmptyDocItemJournalLineForTemplate(var ItemJournalLine: Record "Item Journal Line")
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        SelectItemJournal(ItemJournalBatch);
        CreateItemJournalLineWithEmptyDoc(ItemJournalLine, ItemJournalBatch);
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemJournalBatch: Record "Item Journal Batch")
    begin
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Purchase, LibraryInventory.CreateItemNo(),
          LibraryRandom.RandIntInRange(2, 10));
        Commit();
    end;

    local procedure CreateItemJournalLineWithEmptyDoc(var ItemJournalLine: Record "Item Journal Line"; ItemJournalBatch: Record "Item Journal Batch")
    begin
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Purchase, LibraryInventory.CreateItemNo(),
          LibraryRandom.RandIntInRange(2, 10));
        ItemJournalLine."Document No." := '';
        ItemJournalLine.Modify();
        Commit();
    end;

    local procedure CreateItemJournalLineForItemWithoutBaseUOM(var ItemJournalLine: Record "Item Journal Line"; ItemJournalBatch: Record "Item Journal Batch")
    begin
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Purchase, CreateItemWithoutBaseUOM(),
          LibraryRandom.RandIntInRange(2, 10));
    end;

    local procedure CreateItemJournalLineForItemWithoutBaseUOMForTemplate(var ItemJournalLine: Record "Item Journal Line")
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        SelectItemJournal(ItemJournalBatch);
        CreateItemJournalLineForItemWithoutBaseUOM(ItemJournalLine, ItemJournalBatch);
    end;

    local procedure SelectItemJournal(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure SelectItemJournal(var ItemJournalBatch: Record "Item Journal Batch"; TemplateType: Enum "Item Journal Template Type")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, TemplateType);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, TemplateType, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure CreateItemWithoutBaseUOM(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Base Unit of Measure", '');
        Item.Modify();
        Commit();
        exit(Item."No.");
    end;

    local procedure ClearTempErrorMessage(var TempErrorMessage: Record "Error Message" temporary)
    begin
        TempErrorMessage.Reset();
        TempErrorMessage.DeleteAll();
    end;

    local procedure MockFullBatchCheck(TemplateName: Code[10]; BatchName: Code[10]; var TempErrorMessage: Record "Error Message" temporary)
    var
        ErrorHandlingParameters: Record "Error Handling Parameters";
    begin
        ClearTempErrorMessage(TempErrorMessage);

        SetErrorHandlingParameters(ErrorHandlingParameters, TemplateName, BatchName, true);
        RunBackgroundCheck(ErrorHandlingParameters, TempErrorMessage);
    end;

    local procedure RunBackgroundCheck(ErrorHandlingParameters: Record "Error Handling Parameters"; var TempErrorMessage: Record "Error Message" temporary)
    var
        Params: Dictionary of [Text, Text];
        CheckItemJnlLineBackgr: Codeunit "Check Item Jnl. Line. Backgr.";
    begin
        ErrorHandlingParameters.ToArgs(Params);
        Commit();
        CheckItemJnlLineBackgr.RunCheck(Params, TempErrorMessage);
    end;

    local procedure SetErrorHandlingParameters(var ErrorHandlingParameters: Record "Error Handling Parameters"; TemplateName: Code[10]; BatchName: Code[10]; FullBatchCheck: Boolean)
    begin
        ErrorHandlingParameters.Init();
        ErrorHandlingParameters."Journal Template Name" := TemplateName;
        ErrorHandlingParameters."Journal Batch Name" := BatchName;
        ErrorHandlingParameters."Full Batch Check" := FullBatchCheck;
    end;

    local procedure SetErrorHandlingParameters(var ErrorHandlingParameters: Record "Error Handling Parameters"; ItemJournalLine: Record "Item Journal Line"; PreviosLineNo: Integer)
    begin
        ErrorHandlingParameters.Init();
        ErrorHandlingParameters."Journal Template Name" := ItemJournalLine."Journal Template Name";
        ErrorHandlingParameters."Journal Batch Name" := ItemJournalLine."Journal Batch Name";
        ErrorHandlingParameters."Line No." := ItemJournalLine."Line No.";
        ErrorHandlingParameters."Previous Line No." := PreviosLineNo;
    end;

    local procedure VerifyErrorMessageText(ActualText: Text; ExpectedText: Text)
    begin
        Assert.IsSubstring(ActualText, ExpectedText);
    end;
}