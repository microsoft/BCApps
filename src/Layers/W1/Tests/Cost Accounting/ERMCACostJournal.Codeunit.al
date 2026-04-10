codeunit 134811 "ERM CA Cost Journal"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Cost Accounting]
    end;

    var
        LibraryCostAccounting: Codeunit "Library - Cost Accounting";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        CostJournalLinesCountError: Label 'Incorrect number of cost journal lines.';
        CostEntryFieldError: Label 'Incorrect value of %1 field of Cost Entry.';
        CostRegisterFieldError: Label 'Incorrect value of %1 field of Cost Register.';
        CostJournalBatchNameError: Label 'Incorrect value of Cost Journal Batch Name.';
        CostRegisterSourceCodeError: Label 'Incorrect value of Source Code field of Cost Register Entry. ';
        BalCCAndCOErrorMsg: Label 'You cannot define both balance cost center and balance cost object.';
        CCAndCOErrorMsg: Label 'You cannot define both cost center and cost object.';
        CostJournalFieldErrorMsg: Label '%1 must have a value in Cost Journal Line';
        NoCCOrCOErrorMsg: Label 'Cost center or cost object must be defined.';
        NoBalCCOrCOErrorMsg: Label 'Balance cost center or balance cost object must be defined.';
        UnexpectedErrorMessage: Label 'Unexpected error message.';
        CostJnlBatchNotBalancedError: Label 'The lines in Cost Journal are out of balance by %1.';
        GlobalBatchName: Code[10];
        InvalidPostingReportIDErr: Label 'Field %1 must contain ID Cost Register Report';

    [Test]
    [Scope('OnPrem')]
    procedure ErrorWhenJournalNotBalanced()
    var
        CostJournalBatch: Record "Cost Journal Batch";
        CostJournalLine: Record "Cost Journal Line";
    begin
        Initialize();

        // Setup:
        FindCostJnlBatchAndTemplate(CostJournalBatch);

        // Exercise:
        LibraryCostAccounting.CreateCostJournalLine(CostJournalLine, CostJournalBatch."Journal Template Name", CostJournalBatch.Name);
        CostJournalLine.Validate("Bal. Cost Type No.", '');
        CostJournalLine.Modify(true);

        // Verify:
        asserterror LibraryCostAccounting.PostCostJournalLine(CostJournalLine);
        Assert.IsTrue(StrPos(GetLastErrorText, StrSubstNo(CostJnlBatchNotBalancedError, CostJournalLine.Amount)) > 0,
          UnexpectedErrorMessage);

        // Teardown.
        ClearLastError();
        ClearCostAccountingSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorWhenBothCCAndCOUsed()
    var
        CostCenter: Record "Cost Center";
        CostObject: Record "Cost Object";
        CostJournalBatch: Record "Cost Journal Batch";
        CostJournalLine: Record "Cost Journal Line";
    begin
        Initialize();

        // Setup:
        FindCostJnlBatchAndTemplate(CostJournalBatch);
        LibraryCostAccounting.CreateCostCenter(CostCenter);
        LibraryCostAccounting.CreateCostObject(CostObject);

        // Exercise:
        LibraryCostAccounting.CreateCostJournalLine(CostJournalLine, CostJournalBatch."Journal Template Name", CostJournalBatch.Name);
        CostJournalLine.Validate("Cost Center Code", CostCenter.Code);
        CostJournalLine.Validate("Cost Object Code", CostObject.Code);
        CostJournalLine.Modify(true);

        // Verify:
        asserterror LibraryCostAccounting.PostCostJournalLine(CostJournalLine);
        Assert.IsTrue(StrPos(GetLastErrorText, CCAndCOErrorMsg) > 0, UnexpectedErrorMessage);

        // Teardown.
        ClearLastError();
        ClearCostAccountingSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorWhenNoCCOrCOUsed()
    var
        CostJournalBatch: Record "Cost Journal Batch";
        CostJournalLine: Record "Cost Journal Line";
    begin
        Initialize();

        // Setup:
        FindCostJnlBatchAndTemplate(CostJournalBatch);

        // Exercise:
        LibraryCostAccounting.CreateCostJournalLine(CostJournalLine, CostJournalBatch."Journal Template Name", CostJournalBatch.Name);
        CostJournalLine.Validate("Cost Center Code", '');
        CostJournalLine.Validate("Cost Object Code", '');
        CostJournalLine.Modify(true);

        // Verify:
        asserterror LibraryCostAccounting.PostCostJournalLine(CostJournalLine);
        Assert.IsTrue(StrPos(GetLastErrorText, NoCCOrCOErrorMsg) > 0, UnexpectedErrorMessage);

        // Teardown.
        ClearLastError();
        ClearCostAccountingSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorWhenBothBalCCAndBalCOUsed()
    var
        CostCenter: Record "Cost Center";
        CostObject: Record "Cost Object";
        CostJournalBatch: Record "Cost Journal Batch";
        CostJournalLine: Record "Cost Journal Line";
    begin
        Initialize();

        // Setup:
        FindCostJnlBatchAndTemplate(CostJournalBatch);
        LibraryCostAccounting.CreateCostCenter(CostCenter);
        LibraryCostAccounting.CreateCostObject(CostObject);

        // Exercise:
        LibraryCostAccounting.CreateCostJournalLine(CostJournalLine, CostJournalBatch."Journal Template Name", CostJournalBatch.Name);
        CostJournalLine.Validate("Bal. Cost Type No.", CostJournalLine."Cost Type No.");
        CostJournalLine.Validate("Bal. Cost Center Code", CostCenter.Code);
        CostJournalLine.Validate("Bal. Cost Object Code", CostObject.Code);
        CostJournalLine.Modify(true);

        // Verify:
        asserterror LibraryCostAccounting.PostCostJournalLine(CostJournalLine);
        Assert.IsTrue(StrPos(GetLastErrorText, BalCCAndCOErrorMsg) > 0, UnexpectedErrorMessage);

        // Teardown.
        ClearLastError();
        ClearCostAccountingSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorWhenNoBalCCOrBalCOUsed()
    var
        CostJournalBatch: Record "Cost Journal Batch";
        CostJournalLine: Record "Cost Journal Line";
    begin
        Initialize();

        // Setup:
        FindCostJnlBatchAndTemplate(CostJournalBatch);

        // Exercise:
        LibraryCostAccounting.CreateCostJournalLine(CostJournalLine, CostJournalBatch."Journal Template Name", CostJournalBatch.Name);
        CostJournalLine.Validate("Bal. Cost Type No.", CostJournalLine."Cost Type No.");
        CostJournalLine.Validate("Bal. Cost Center Code", '');
        CostJournalLine.Validate("Bal. Cost Object Code", '');
        CostJournalLine.Modify(true);

        // Verify:
        asserterror LibraryCostAccounting.PostCostJournalLine(CostJournalLine);
        Assert.IsTrue(StrPos(GetLastErrorText, NoBalCCOrCOErrorMsg) > 0, UnexpectedErrorMessage);

        // Teardown.
        ClearLastError();
        ClearCostAccountingSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorWhenCostCenterBlocked()
    var
        CostCenter: Record "Cost Center";
        CostJournalBatch: Record "Cost Journal Batch";
        CostJournalLine: Record "Cost Journal Line";
    begin
        Initialize();

        // Setup:
        FindCostJnlBatchAndTemplate(CostJournalBatch);
        LibraryCostAccounting.CreateCostCenter(CostCenter);
        CostCenter.Validate(Blocked, true);
        CostCenter.Modify(true);

        // Exercise:
        LibraryCostAccounting.CreateCostJournalLine(CostJournalLine, CostJournalBatch."Journal Template Name", CostJournalBatch.Name);

        // Verify:
        asserterror CostJournalLine.Validate("Cost Center Code", CostCenter.Code);
        Assert.ExpectedTestFieldError(CostCenter.FieldCaption(Blocked), Format(false));

        // Teardown.
        ClearLastError();
        ClearCostAccountingSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorWhenCostObjectBlocked()
    var
        CostObject: Record "Cost Object";
        CostJournalBatch: Record "Cost Journal Batch";
        CostJournalLine: Record "Cost Journal Line";
    begin
        Initialize();

        // Setup:
        FindCostJnlBatchAndTemplate(CostJournalBatch);
        LibraryCostAccounting.CreateCostObject(CostObject);
        CostObject.Validate(Blocked, true);
        CostObject.Modify(true);

        // Exercise:
        LibraryCostAccounting.CreateCostJournalLine(CostJournalLine, CostJournalBatch."Journal Template Name", CostJournalBatch.Name);

        // Verify:
        asserterror CostJournalLine.Validate("Cost Object Code", CostObject.Code);
        Assert.ExpectedTestFieldError(CostObject.FieldCaption(Blocked), Format(false));

        // Teardown.
        ClearLastError();
        ClearCostAccountingSetup();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ErrorWhenCostTypeBlocked()
    var
        CostType: Record "Cost Type";
        CostJournalBatch: Record "Cost Journal Batch";
        CostJournalLine: Record "Cost Journal Line";
    begin
        Initialize();

        // Setup:
        FindCostJnlBatchAndTemplate(CostJournalBatch);
        LibraryCostAccounting.CreateCostType(CostType);
        CostType.Validate(Blocked, true);
        CostType.Modify(true);

        // Exercise
        LibraryCostAccounting.CreateCostJournalLine(CostJournalLine, CostJournalBatch."Journal Template Name", CostJournalBatch.Name);

        // Verify:
        asserterror CostJournalLine.Validate("Cost Type No.", CostType."No.");
        Assert.ExpectedTestFieldError(CostType.FieldCaption(Blocked), Format(false));

        // Teardown.
        ClearLastError();
        ClearCostAccountingSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorWhenDocumentNoIsMissing()
    var
        CostJournalBatch: Record "Cost Journal Batch";
        CostJournalLine: Record "Cost Journal Line";
    begin
        Initialize();

        // Setup:
        FindCostJnlBatchAndTemplate(CostJournalBatch);

        // Exercise:
        LibraryCostAccounting.CreateCostJournalLine(CostJournalLine, CostJournalBatch."Journal Template Name", CostJournalBatch.Name);
        CostJournalLine.Validate("Document No.", '');
        CostJournalLine.Modify(true);

        // Verify:
        asserterror LibraryCostAccounting.PostCostJournalLine(CostJournalLine);
        Assert.IsTrue(StrPos(GetLastErrorText, StrSubstNo(CostJournalFieldErrorMsg, CostJournalLine.FieldName("Document No."))) > 0,
          UnexpectedErrorMessage);

        // Teardown.
        ClearLastError();
        ClearCostAccountingSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorWhenJnlLinesNotBalanced()
    var
        CostJournalBatch: Record "Cost Journal Batch";
        CostJournalLine: Record "Cost Journal Line";
        Amount: Integer;
    begin
        Initialize();

        // Setup:
        FindCostJnlBatchAndTemplate(CostJournalBatch);

        // Exercise:
        LibraryCostAccounting.CreateCostJournalLine(CostJournalLine, CostJournalBatch."Journal Template Name", CostJournalBatch.Name);
        CostJournalLine.Validate("Bal. Cost Type No.", '');
        CostJournalLine.Modify(true);
        Amount := CostJournalLine.Amount;

        LibraryCostAccounting.CreateCostJournalLine(CostJournalLine, CostJournalBatch."Journal Template Name", CostJournalBatch.Name);
        CostJournalLine.Validate(Amount, -(Amount + LibraryRandom.RandInt(10)));
        CostJournalLine.Validate("Bal. Cost Type No.", '');
        CostJournalLine.Modify(true);

        // Verify:
        asserterror LibraryCostAccounting.PostCostJournalLine(CostJournalLine);
        // active bug (TO DO: validate error msg)

        // Teardown.
        ClearLastError();
        ClearCostAccountingSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorWhenPostingDateIsMissing()
    var
        CostJournalBatch: Record "Cost Journal Batch";
        CostJournalLine: Record "Cost Journal Line";
    begin
        Initialize();

        // Setup:
        FindCostJnlBatchAndTemplate(CostJournalBatch);

        // Exercise:
        LibraryCostAccounting.CreateCostJournalLine(CostJournalLine, CostJournalBatch."Journal Template Name", CostJournalBatch.Name);
        CostJournalLine.Validate("Posting Date", 0D);
        CostJournalLine.Modify(true);

        // Verify:
        asserterror LibraryCostAccounting.PostCostJournalLine(CostJournalLine);
        Assert.IsTrue(
          StrPos(GetLastErrorText, StrSubstNo(CostJournalFieldErrorMsg, CostJournalLine.FieldName("Posting Date"))) > 0,
          UnexpectedErrorMessage);

        // Teardown.
        ClearLastError();
        ClearCostAccountingSetup();
    end;

    [Test]
    [HandlerFunctions('CostJournalHandler')]
    [Scope('OnPrem')]
    procedure OpenJnlFromCostJnlBatchPage()
    var
        CostJnlBatchPage: TestPage "Cost Journal Batches";
    begin
        Initialize();

        // Setup:
        CostJnlBatchPage.OpenEdit();
        GlobalBatchName := CostJnlBatchPage.Name.Value();

        // Exercise:
        CostJnlBatchPage."Edit Journal".Invoke();

        // Clean-up
        CostJnlBatchPage.Close();
        ClearCostAccountingSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostInDeleteAfterPostBatch()
    var
        CostJournalBatch: Record "Cost Journal Batch";
        CostJournalLine: Record "Cost Journal Line";
    begin
        Initialize();

        // Setup:
        FindCostJnlBatchAndTemplate(CostJournalBatch);

        // Exercise:
        LibraryCostAccounting.CreateCostJournalLine(CostJournalLine, CostJournalBatch."Journal Template Name", CostJournalBatch.Name);
        LibraryCostAccounting.PostCostJournalLine(CostJournalLine);

        // Verify:
        ValidateCostJournalCount(CostJournalBatch, 0);
        ValidateCreatedEntries(CostJournalLine);

        // Teardown.
        ClearCostAccountingSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostInNoDeleteAfterPostBatch()
    var
        CostJournalBatch: Record "Cost Journal Batch";
        CostJournalLine: Record "Cost Journal Line";
    begin
        Initialize();

        // Setup:
        FindCostJnlBatchAndTemplate(CostJournalBatch);
        CostJournalBatch.Validate("Delete after Posting", false);
        CostJournalBatch.Modify(true);

        // Exercise:
        LibraryCostAccounting.CreateCostJournalLine(CostJournalLine, CostJournalBatch."Journal Template Name", CostJournalBatch.Name);
        LibraryCostAccounting.PostCostJournalLine(CostJournalLine);

        // Verify:
        ValidateCostJournalCount(CostJournalBatch, 1);
        ValidateCreatedEntries(CostJournalLine);

        // Clean-up:
        CostJournalBatch.Validate("Delete after Posting", true);
        CostJournalBatch.Modify(true);
        ClearCostAccountingSetup();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostDirectlyFromBatch()
    var
        CostJournalBatch: Record "Cost Journal Batch";
        CostJournalLine: Record "Cost Journal Line";
    begin
        Initialize();

        // Setup:
        FindCostJnlBatchAndTemplate(CostJournalBatch);
        CostJournalLine.SetRange("Journal Template Name", CostJournalBatch."Journal Template Name");
        CostJournalLine.DeleteAll();

        // Exercise:
        LibraryCostAccounting.CreateCostJournalLine(CostJournalLine, CostJournalBatch."Journal Template Name", CostJournalBatch.Name);
        Commit();
        CODEUNIT.Run(CODEUNIT::"CA Jnl.-B. Post", CostJournalBatch);

        // Verify:
        ValidateCostJournalCount(CostJournalBatch, 0);
        ValidateCreatedEntries(CostJournalLine);

        // Teardown.
        ClearCostAccountingSetup();
    end;

    [Test]
    [HandlerFunctions('CostJnlBatchHandler')]
    [Scope('OnPrem')]
    procedure UpdateJnlBatchFromJnlBatchPage()
    var
        CostJournalPage: TestPage "Cost Journal";
    begin
        Initialize();

        // Setup:
        CostJournalPage.OpenEdit();

        // Exercise:
        CostJournalPage.CostJnlBatchName.Lookup();

        // Verify:
        Assert.AreEqual(GlobalBatchName, CostJournalPage.CostJnlBatchName.Value, CostJournalBatchNameError);

        // Clean-up
        CostJournalPage.Close();
        ClearCostAccountingSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateJnlBatchDirectly()
    var
        CostJournalBatch: Record "Cost Journal Batch";
        CostJournalPage: TestPage "Cost Journal";
    begin
        Initialize();

        // Setup:
        FindCostJnlBatchAndTemplate(CostJournalBatch);
        CostJournalPage.OpenEdit();

        // Exercise:
        CostJournalPage.CostJnlBatchName.SetValue(CostJournalBatch.Name);

        // Verify:
        Assert.AreEqual(CostJournalBatch.Name, CostJournalPage.CostJnlBatchName.Value, CostJournalBatchNameError);

        // Clean-up
        CostJournalPage.Close();
        ClearCostAccountingSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorWhenPostingReportIdEmpty()
    var
        CostJnlLine: Record "Cost Journal Line";
        CostJnlTemplate: Record "Cost Journal Template";
        TempCostJnlTemplate: Record "Cost Journal Template" temporary;
        CostJnlMgt: Codeunit CostJnlManagement;
        JnlSelected: Boolean;
    begin
        // Save CostJnlTmplate
        CopyCostJnlTemplate(CostJnlTemplate, TempCostJnlTemplate);

        CostJnlTemplate.DeleteAll();
        CostJnlMgt.TemplateSelection(CostJnlLine, JnlSelected);

        CostJnlTemplate.Get(CostJnlLine.GetRangeMax("Journal Template Name"));
        Assert.AreEqual(REPORT::"Cost Register", CostJnlTemplate."Posting Report ID",
          StrSubstNo(InvalidPostingReportIDErr, CostJnlTemplate.FieldCaption("Posting Report ID")));

        // Restore all deleted records
        CopyCostJnlTemplate(TempCostJnlTemplate, CostJnlTemplate);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM CA Cost Journal");
        LibraryCostAccounting.InitializeCASetup();
    end;

    local procedure ClearCostAccountingSetup()
    var
        CostAccountingSetup: Record "Cost Accounting Setup";
    begin
        CostAccountingSetup.Get();
        CostAccountingSetup.Validate("Align G/L Account", CostAccountingSetup."Align G/L Account"::"No Alignment");
        CostAccountingSetup.Modify(true);
    end;

    local procedure FindCostJnlBatchAndTemplate(var CostJournalBatch: Record "Cost Journal Batch")
    var
        CostJournalTemplate: Record "Cost Journal Template";
    begin
        LibraryCostAccounting.FindCostJournalTemplate(CostJournalTemplate);
        LibraryCostAccounting.FindCostJournalBatch(CostJournalBatch, CostJournalTemplate.Name);
        LibraryCostAccounting.ClearCostJournalLines(CostJournalBatch);
    end;

    local procedure VerifyCostEntryCommonFields(CostEntry: Record "Cost Entry")
    var
        CostAccountingSetup: Record "Cost Accounting Setup";
        SourceCodeSetup: Record "Source Code Setup";
    begin
        CostAccountingSetup.Get();
        SourceCodeSetup.Get();

        Assert.AreEqual(0, CostEntry."G/L Entry No.", StrSubstNo(CostEntryFieldError, CostEntry.FieldName("G/L Entry No.")));
        Assert.AreEqual(false, CostEntry."System-Created Entry",
          StrSubstNo(CostEntryFieldError, CostEntry.FieldName("System-Created Entry")));
        Assert.AreEqual(SourceCodeSetup."Cost Journal", CostEntry."Source Code",
          StrSubstNo(CostEntryFieldError, CostEntry.FieldName("Source Code")));
    end;

    local procedure VerifyCostEntrySpecificFields(CostEntry: Record "Cost Entry"; CostTypeNo: Code[20]; CostCenterCode: Code[20]; CostObjectCode: Code[20]; Amount: Decimal)
    begin
        Assert.AreEqual(Amount, CostEntry.Amount, StrSubstNo(CostEntryFieldError, CostEntry.FieldName(Amount)));
        Assert.AreEqual(CostTypeNo, CostEntry."Cost Type No.", StrSubstNo(CostEntryFieldError, CostEntry.FieldName("Cost Type No.")));
        Assert.AreEqual(
          CostCenterCode, CostEntry."Cost Center Code", StrSubstNo(CostEntryFieldError, CostEntry.FieldName("Cost Center Code")));
        Assert.AreEqual(
          CostObjectCode, CostEntry."Cost Object Code", StrSubstNo(CostEntryFieldError, CostEntry.FieldName("Cost Object Code")));
        if Amount > 0 then
            Assert.AreEqual(Amount, CostEntry."Debit Amount", StrSubstNo(CostEntryFieldError, CostEntry.FieldName("Debit Amount")))
        else
            Assert.AreEqual(-Amount, CostEntry."Credit Amount", StrSubstNo(CostEntryFieldError, CostEntry.FieldName("Credit Amount")));
    end;

    local procedure ValidateCreatedEntries(CostJournalLine: Record "Cost Journal Line")
    var
        CostEntry: Record "Cost Entry";
        CostRegister: Record "Cost Register";
    begin
        // Validate cost register
        CostRegister.FindLast();
        Assert.AreEqual(CostRegister.Source::"Cost Journal", CostRegister.Source, CostRegisterSourceCodeError);
        // active bug id 252400
        Assert.AreEqual(CostRegister."No. of Entries", CostRegister."To Cost Entry No." - CostRegister."From Cost Entry No." + 1,
          StrSubstNo(CostRegisterFieldError, CostRegister.FieldName("No. of Entries")));

        // Validate cost entries
        CostEntry.SetRange("Entry No.", CostRegister."From Cost Entry No.", CostRegister."To Cost Entry No.");

        // First entry is the posted journal line
        CostEntry.Find('-');
        VerifyCostEntryCommonFields(CostEntry);
        VerifyCostEntrySpecificFields(CostEntry, CostJournalLine."Cost Type No.", CostJournalLine."Cost Center Code",
          CostJournalLine."Cost Object Code", CostJournalLine.Amount);

        // Second entry is the balancing entry
        CostEntry.Next();
        VerifyCostEntryCommonFields(CostEntry);
        VerifyCostEntrySpecificFields(CostEntry, CostJournalLine."Bal. Cost Type No.", CostJournalLine."Bal. Cost Center Code",
          CostJournalLine."Bal. Cost Object Code", -CostJournalLine.Amount);
    end;

    local procedure ValidateCostJournalCount(CostJournalBatch: Record "Cost Journal Batch"; ExpectedCount: Integer)
    var
        CostJournalLine: Record "Cost Journal Line";
    begin
        CostJournalLine.SetRange("Journal Template Name", CostJournalBatch."Journal Template Name");
        CostJournalLine.SetRange("Journal Batch Name", CostJournalBatch.Name);
        Assert.AreEqual(ExpectedCount, CostJournalLine.Count, CostJournalLinesCountError);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CostJournalHandler(var CostJournalPage: TestPage "Cost Journal")
    begin
        // Verify that the correct batch is used
        CostJournalPage.CostJnlBatchName.AssertEquals(GlobalBatchName);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CostJnlBatchHandler(var CostJnlBatchPage: TestPage "Cost Journal Batches")
    begin
        CostJnlBatchPage.Last();
        GlobalBatchName := CostJnlBatchPage.Name.Value();
        CostJnlBatchPage.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // dummy message handler
    end;

    [Normal]
    local procedure CopyCostJnlTemplate(var CostJnlTemplateFrom: Record "Cost Journal Template"; var CostJnlTemplateTo: Record "Cost Journal Template")
    begin
        CostJnlTemplateTo.DeleteAll();
        if CostJnlTemplateFrom.FindSet() then
            repeat
                CostJnlTemplateTo.Copy(CostJnlTemplateFrom);
                CostJnlTemplateTo.Insert();
            until CostJnlTemplateFrom.Next() = 0;
    end;
}

