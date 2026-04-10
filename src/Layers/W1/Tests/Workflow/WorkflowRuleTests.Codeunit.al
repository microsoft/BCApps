codeunit 134206 "Workflow Rule Tests"
{
    Permissions = TableData "Workflow Step Instance Archive" = d;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Rule] [UT]
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWorkflow: Codeunit "Library - Workflow";
        EvaluationFailedErr: Label 'Rule returned a wrong result.';
        LeftNotEqualToRightErr: Label 'Left argument should not be equal to the right.';
        LeftEqualToRightErr: Label 'Left argument should be equal to the right.';
        LeftNotLessThanRightErr: Label 'Left argument should be not be less than the right.';
        LeftLessThanRightErr: Label 'Left argument should be less than the right.';
        LeftGreaterThanRightErr: Label 'Left argument should be greater than the right.';
        LeftDifferentFromRightErr: Label 'Left argument should be different than the right.';
        LeftNotDifferentFromRightErr: Label 'Left argument should not be different than the right.';

    local procedure Initialize()
    var
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryWorkflow.DeleteAllExistingWorkflows();
        LibraryApplicationArea.EnableFoundationSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOperatorIncreaseForDecimal()
    var
        WorkflowRule: Record "Workflow Rule";
        LeftDecimal: Decimal;
        RightDecimal: Decimal;
    begin
        Initialize();
        WorkflowRule.Validate(Operator, WorkflowRule.Operator::Increased);
        WorkflowRule.Insert(true);

        LeftDecimal := LibraryRandom.RandDec(100, 2);
        RightDecimal := LeftDecimal + LibraryRandom.RandDec(100, 2);
        Assert.IsTrue(WorkflowRule.CompareValues(LeftDecimal, RightDecimal), LeftLessThanRightErr);
        Assert.IsFalse(WorkflowRule.CompareValues(RightDecimal, LeftDecimal), LeftGreaterThanRightErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOperatorDecreaseForDecimal()
    var
        WorkflowRule: Record "Workflow Rule";
        LeftDecimal: Decimal;
        RightDecimal: Decimal;
    begin
        Initialize();
        WorkflowRule.Validate(Operator, WorkflowRule.Operator::Decreased);
        WorkflowRule.Insert(true);

        LeftDecimal := LibraryRandom.RandDec(100, 2);
        RightDecimal := LeftDecimal - LibraryRandom.RandDec(100, 2);
        Assert.IsTrue(WorkflowRule.CompareValues(LeftDecimal, RightDecimal), LeftGreaterThanRightErr);
        Assert.IsFalse(WorkflowRule.CompareValues(RightDecimal, LeftDecimal), LeftLessThanRightErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOperatorChangeForDecimal()
    var
        WorkflowRule: Record "Workflow Rule";
        LeftDecimal: Decimal;
        RightDecimal: Decimal;
    begin
        Initialize();
        WorkflowRule.Validate(Operator, WorkflowRule.Operator::Changed);
        WorkflowRule.Insert(true);

        LeftDecimal := LibraryRandom.RandDec(100, 2);
        RightDecimal := LeftDecimal + LibraryRandom.RandDec(100, 2);
        Assert.IsTrue(WorkflowRule.CompareValues(LeftDecimal, RightDecimal), LeftDifferentFromRightErr);
        Assert.IsTrue(WorkflowRule.CompareValues(RightDecimal, LeftDecimal), LeftDifferentFromRightErr);
        Assert.IsFalse(WorkflowRule.CompareValues(LeftDecimal, LeftDecimal), LeftNotDifferentFromRightErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOperatorIncreaseForDates()
    var
        WorkflowRule: Record "Workflow Rule";
        LeftDate: Date;
        RightDate: Date;
        DateFormula: DateFormula;
    begin
        Initialize();
        WorkflowRule.Validate(Operator, WorkflowRule.Operator::Increased);
        WorkflowRule.Insert(true);

        Evaluate(DateFormula, '<+1D>');
        LeftDate := WorkDate();
        RightDate := CalcDate(DateFormula, WorkDate());
        Assert.IsTrue(WorkflowRule.CompareValues(LeftDate, RightDate), LeftLessThanRightErr);
        Assert.IsFalse(WorkflowRule.CompareValues(RightDate, LeftDate), LeftGreaterThanRightErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOperatorDecreaseForDates()
    var
        WorkflowRule: Record "Workflow Rule";
        LeftDate: Date;
        RightDate: Date;
        DateFormula: DateFormula;
    begin
        Initialize();
        WorkflowRule.Validate(Operator, WorkflowRule.Operator::Decreased);
        WorkflowRule.Insert(true);

        Evaluate(DateFormula, '<-1D>');
        LeftDate := Today;
        RightDate := CalcDate(DateFormula, Today);
        Assert.IsTrue(WorkflowRule.CompareValues(LeftDate, RightDate), LeftLessThanRightErr);
        Assert.IsFalse(WorkflowRule.CompareValues(RightDate, LeftDate), LeftNotLessThanRightErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOperatorChangeForDates()
    var
        WorkflowRule: Record "Workflow Rule";
        LeftDate: Date;
        RightDate: Date;
        DateFormula: DateFormula;
    begin
        Initialize();
        WorkflowRule.Validate(Operator, WorkflowRule.Operator::Changed);
        WorkflowRule.Insert(true);

        Evaluate(DateFormula, '<+1D>');
        LeftDate := Today;
        RightDate := CalcDate(DateFormula, Today);
        Assert.IsTrue(WorkflowRule.CompareValues(LeftDate, RightDate), LeftDifferentFromRightErr);
        Assert.IsFalse(WorkflowRule.CompareValues(LeftDate, LeftDate), LeftEqualToRightErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOperatorIncreaseForTimes()
    var
        WorkflowRule: Record "Workflow Rule";
        LeftTime: Time;
        RightTime: Time;
    begin
        Initialize();
        WorkflowRule.Validate(Operator, WorkflowRule.Operator::Increased);
        WorkflowRule.Insert(true);

        LeftTime := Time;
        RightTime := LeftTime + 10;
        Assert.IsTrue(WorkflowRule.CompareValues(LeftTime, RightTime), LeftLessThanRightErr);
        Assert.IsFalse(WorkflowRule.CompareValues(RightTime, LeftTime), LeftGreaterThanRightErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOperatorDecreaseForTimes()
    var
        WorkflowRule: Record "Workflow Rule";
        LeftTime: Time;
        RightTime: Time;
    begin
        Initialize();
        WorkflowRule.Validate(Operator, WorkflowRule.Operator::Decreased);
        WorkflowRule.Insert(true);

        LeftTime := Time;
        RightTime := LeftTime - 10;
        Assert.IsTrue(WorkflowRule.CompareValues(LeftTime, RightTime), LeftLessThanRightErr);
        Assert.IsFalse(WorkflowRule.CompareValues(RightTime, LeftTime), LeftNotLessThanRightErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOperatorChangeForTimes()
    var
        WorkflowRule: Record "Workflow Rule";
        LeftTime: Time;
        RightTime: Time;
    begin
        Initialize();
        WorkflowRule.Validate(Operator, WorkflowRule.Operator::Changed);
        WorkflowRule.Insert(true);

        LeftTime := Time;
        RightTime := LeftTime + 10;
        Assert.IsTrue(WorkflowRule.CompareValues(LeftTime, RightTime), LeftDifferentFromRightErr);
        Assert.IsFalse(WorkflowRule.CompareValues(LeftTime, LeftTime), LeftEqualToRightErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOperatorIncreaseForDateTimes()
    var
        WorkflowRule: Record "Workflow Rule";
        LeftDateTime: DateTime;
        RightDateTime: DateTime;
    begin
        Initialize();
        WorkflowRule.Validate(Operator, WorkflowRule.Operator::Increased);
        WorkflowRule.Insert(true);

        LeftDateTime := CreateDateTime(WorkDate(), Time);
        RightDateTime := LeftDateTime + 10;
        Assert.IsTrue(WorkflowRule.CompareValues(LeftDateTime, RightDateTime), LeftLessThanRightErr);
        Assert.IsFalse(WorkflowRule.CompareValues(RightDateTime, LeftDateTime), LeftGreaterThanRightErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOperatorDecreaseForDateTimes()
    var
        WorkflowRule: Record "Workflow Rule";
        LeftDateTime: DateTime;
        RightDateTime: DateTime;
    begin
        Initialize();
        WorkflowRule.Validate(Operator, WorkflowRule.Operator::Decreased);
        WorkflowRule.Insert(true);

        LeftDateTime := CreateDateTime(WorkDate(), Time);
        RightDateTime := LeftDateTime - 10;
        Assert.IsTrue(WorkflowRule.CompareValues(LeftDateTime, RightDateTime), LeftLessThanRightErr);
        Assert.IsFalse(WorkflowRule.CompareValues(RightDateTime, LeftDateTime), LeftNotLessThanRightErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOperatorChangeForDateTimes()
    var
        WorkflowRule: Record "Workflow Rule";
        LeftDateTime: DateTime;
        RightDateTime: DateTime;
    begin
        Initialize();
        WorkflowRule.Validate(Operator, WorkflowRule.Operator::Changed);
        WorkflowRule.Insert(true);

        LeftDateTime := CreateDateTime(WorkDate(), Time);
        RightDateTime := LeftDateTime + 10;
        Assert.IsTrue(WorkflowRule.CompareValues(LeftDateTime, RightDateTime), LeftDifferentFromRightErr);
        Assert.IsFalse(WorkflowRule.CompareValues(LeftDateTime, LeftDateTime), LeftEqualToRightErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOperatorChangeForText()
    var
        WorkflowRule: Record "Workflow Rule";
        LeftText: Text;
        RightText: Text;
    begin
        Initialize();
        WorkflowRule.Validate(Operator, WorkflowRule.Operator::Changed);
        WorkflowRule.Insert(true);

        LeftText := LibraryUtility.GenerateRandomText(10);
        RightText := LeftText + LibraryUtility.GenerateRandomText(10);
        Assert.IsTrue(WorkflowRule.CompareValues(LeftText, RightText), LeftNotEqualToRightErr);
        Assert.IsFalse(WorkflowRule.CompareValues(LeftText, LeftText), LeftEqualToRightErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEvaluateRuleForIncrease()
    var
        Customer: Record Customer;
        Customer1: Record Customer;
        WorkflowRule: Record "Workflow Rule";
        RecRef: RecordRef;
        RecRef1: RecordRef;
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomer(Customer1);
        Customer1."Credit Limit (LCY)" := Customer."Credit Limit (LCY)" + LibraryRandom.RandDec(100, 2);
        Customer1.Modify(true);

        CreateWorkflowRule(WorkflowRule, DATABASE::Customer, Customer.FieldNo("Credit Limit (LCY)"), WorkflowRule.Operator::Increased);
        RecRef.GetTable(Customer);
        RecRef1.GetTable(Customer1);

        // Verify.
        Assert.IsTrue(WorkflowRule.EvaluateRule(RecRef1, RecRef), EvaluationFailedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEvaluateRuleForDecrease()
    var
        Customer: Record Customer;
        Customer1: Record Customer;
        WorkflowRule: Record "Workflow Rule";
        RecRef: RecordRef;
        RecRef1: RecordRef;
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomer(Customer1);
        Customer1."Credit Limit (LCY)" := Customer."Credit Limit (LCY)" - LibraryRandom.RandDec(100, 2);
        Customer1.Modify(true);

        CreateWorkflowRule(WorkflowRule, DATABASE::Customer, Customer.FieldNo("Credit Limit (LCY)"), WorkflowRule.Operator::Decreased);
        RecRef.GetTable(Customer);
        RecRef1.GetTable(Customer1);

        // Verify.
        Assert.IsTrue(WorkflowRule.EvaluateRule(RecRef1, RecRef), EvaluationFailedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEvaluateRuleForChange()
    var
        Customer: Record Customer;
        Customer1: Record Customer;
        WorkflowRule: Record "Workflow Rule";
        RecRef: RecordRef;
        RecRef1: RecordRef;
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomer(Customer1);
        Customer1."Credit Limit (LCY)" := Customer."Credit Limit (LCY)" + LibraryRandom.RandDec(100, 2);
        Customer1.Modify(true);

        CreateWorkflowRule(WorkflowRule, DATABASE::Customer, Customer.FieldNo("Credit Limit (LCY)"), WorkflowRule.Operator::Changed);
        RecRef.GetTable(Customer);
        RecRef1.GetTable(Customer1);

        // Verify.
        Assert.IsTrue(WorkflowRule.EvaluateRule(RecRef1, RecRef), EvaluationFailedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEvaluateEntryPointEventRuleForIncrease()
    var
        Customer: Record Customer;
        WorkflowRule: Record "Workflow Rule";
        Workflow: Record Workflow;
        CustomerCard: TestPage "Customer Card";
    begin
        // [SCENARIO] On Customer Changed event is picked up when using rules.
        // [GIVEN] A Customer record and an OnCustomerChanged workflow event with rules.
        // [WHEN] The user changes the Customer record.
        // [THEN] The workflow is executed.

        Initialize();

        // Setup.
        LibrarySales.CreateCustomer(Customer);
        CreateAndEnableWorkflow(Workflow, Customer.FieldNo("Credit Limit (LCY)"), WorkflowRule.Operator::Increased);

        // Exercise.
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);
        CustomerCard."Credit Limit (LCY)".SetValue(LibraryRandom.RandDec(100, 2));
        CustomerCard.OK().Invoke();

        // Verify.
        VerifyWorkflowStepInstance(Workflow);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEvaluateEntryPointEventRuleForDecrease()
    var
        Customer: Record Customer;
        WorkflowRule: Record "Workflow Rule";
        Workflow: Record Workflow;
        CustomerCard: TestPage "Customer Card";
    begin
        // [SCENARIO] On Customer Changed event is picked up when using rules.
        // [GIVEN] A Customer record and an OnCustomerChanged workflow event with rules.
        // [WHEN] The user changes the Customer record.
        // [THEN] The workflow is executed.

        Initialize();

        // Setup.
        LibrarySales.CreateCustomer(Customer);
        CreateAndEnableWorkflow(Workflow, Customer.FieldNo("Credit Limit (LCY)"), WorkflowRule.Operator::Decreased);

        // Exercise.
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);
        CustomerCard."Credit Limit (LCY)".SetValue(-LibraryRandom.RandDec(100, 2));
        CustomerCard.OK().Invoke();

        // Verify.
        VerifyWorkflowStepInstance(Workflow);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEvaluateEntryPointEventRuleForChanged()
    var
        Customer: Record Customer;
        WorkflowRule: Record "Workflow Rule";
        Workflow: Record Workflow;
        CustomerCard: TestPage "Customer Card";
    begin
        // [SCENARIO] On Customer Changed event is picked up when using rules.
        // [GIVEN] A Customer record and an OnCustomerChanged workflow event with rules.
        // [WHEN] The user changes the Customer record.
        // [THEN] The workflow is executed.

        Initialize();

        // Setup.
        LibrarySales.CreateCustomer(Customer);
        CreateAndEnableWorkflow(Workflow, Customer.FieldNo("Credit Limit (LCY)"), WorkflowRule.Operator::Changed);

        // Exercise.
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);
        CustomerCard."Credit Limit (LCY)".SetValue(LibraryRandom.RandDec(100, 2));
        CustomerCard.OK().Invoke();

        // Verify.
        VerifyWorkflowStepInstance(Workflow);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEvaluateNonEntryPointEventRule()
    var
        Customer: Record Customer;
        WorkflowRule: Record "Workflow Rule";
        Workflow: Record Workflow;
        CustomerCard: TestPage "Customer Card";
    begin
        // [SCENARIO] On Customer Changed event is picked up when using rules.
        // [GIVEN] A Customer record and an OnCustomerChanged non-entry point workflow event with rules.
        // [WHEN] The user changes the Customer record twice.
        // [THEN] The workflow is executed fully.

        Initialize();

        // Setup.
        CreateAndEnableWorkflow(Workflow, Customer.FieldNo("Credit Limit (LCY)"), WorkflowRule.Operator::Increased);
        Customer.Init();
        Customer.Insert(true);

        // Exercise.
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);
        CustomerCard."Credit Limit (LCY)".SetValue(LibraryRandom.RandDec(100, 2));
        CustomerCard.OK().Invoke();

        // Verify.
        VerifyWorkflowStepInstance(Workflow);

        // Exercise.
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);
        CustomerCard."Credit Limit (LCY)".SetValue(CustomerCard."Credit Limit (LCY)".AsDecimal() + LibraryRandom.RandDec(100, 2));
        CustomerCard.OK().Invoke();

        // Verify.
        VerifyArchivedWorkflowStepInstance(Workflow);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEvaluateMissingFieldEventRule()
    var
        WorkflowRule: Record "Workflow Rule";
        RecRef: RecordRef;
        Result: Boolean;
    begin
        // Initialize
        Initialize();

        // Setup
        WorkflowRule."Table ID" := DATABASE::Customer;
        WorkflowRule."Field No." := -LibraryRandom.RandIntInRange(50000, 99999);
        WorkflowRule.Insert();
        RecRef.Open(DATABASE::Customer);
        RecRef.Find('-');
        ClearLastError();

        // Exercise
        Result := WorkflowRule.EvaluateRule(RecRef, RecRef);

        // Verify
        Assert.AreEqual('', GetLastErrorText, 'An unexpected error was thrown');
        Assert.IsFalse(Result, 'The workflow rule evaluated to TRUE for a non-existing field');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEnableTwoWorkflowsWithDifferentRules()
    var
        Customer: Record Customer;
        Workflow1: Record Workflow;
        Workflow2: Record Workflow;
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        EntryPointEventStepId1: Integer;
        EntryPointEventStepId2: Integer;
    begin
        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow1);
        LibraryWorkflow.CreateWorkflow(Workflow2);

        EntryPointEventStepId1 := LibraryWorkflow.InsertEntryPointEventStep(Workflow1,
            WorkflowEventHandling.RunWorkflowOnCustomerChangedCode());
        EntryPointEventStepId2 := LibraryWorkflow.InsertEntryPointEventStep(Workflow2,
            WorkflowEventHandling.RunWorkflowOnCustomerChangedCode());

        LibraryWorkflow.InsertEventRule(EntryPointEventStepId1, DATABASE::Customer, Customer.FieldNo("Credit Limit (LCY)"));
        LibraryWorkflow.InsertEventRule(EntryPointEventStepId2, DATABASE::Customer, Customer.FieldNo(Name));

        // Exercise
        LibraryWorkflow.EnableWorkflow(Workflow1);
        LibraryWorkflow.EnableWorkflow(Workflow2);

        // Verify
        Workflow1.TestField(Enabled, true);
        Workflow2.TestField(Enabled, true);
    end;

    local procedure CreateWorkflowRule(var WorkflowRule: Record "Workflow Rule"; TableID: Integer; FieldNo: Integer; Operator: Option)
    begin
        WorkflowRule.Init();
        WorkflowRule."Table ID" := TableID;
        WorkflowRule."Field No." := FieldNo;
        WorkflowRule.Operator := Operator;
        WorkflowRule.Insert(true);
    end;

    local procedure CreateAndEnableWorkflow(var Workflow: Record Workflow; FieldNo: Integer; Operator: Option)
    var
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        EntryPointEventID: Integer;
        SecondEventID: Integer;
        ResponseStepID: Integer;
    begin
        LibraryWorkflow.CreateWorkflow(Workflow);

        EntryPointEventID := LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnCustomerChangedCode());
        LibraryWorkflow.InsertEventRule(EntryPointEventID, FieldNo, Operator);

        ResponseStepID := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.DoNothingCode(), EntryPointEventID);
        SecondEventID := LibraryWorkflow.InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnCustomerChangedCode(), ResponseStepID);
        LibraryWorkflow.InsertEventRule(SecondEventID, FieldNo, Operator);

        LibraryWorkflow.EnableWorkflow(Workflow);
    end;

    local procedure VerifyWorkflowStepInstance(Workflow: Record Workflow)
    var
        WorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowRule: Record "Workflow Rule";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        WorkflowStepInstance.SetRange("Workflow Code", Workflow.Code);
        WorkflowStepInstance.SetRange("Function Name", WorkflowEventHandling.RunWorkflowOnCustomerChangedCode());
        Assert.RecordCount(WorkflowStepInstance, 2);
        WorkflowStepInstance.FindSet();
        repeat
            WorkflowRule.SetRange("Workflow Code", Workflow.Code);
            WorkflowRule.SetRange("Workflow Step ID", WorkflowStepInstance."Workflow Step ID");
            WorkflowRule.SetRange("Workflow Step Instance ID", WorkflowStepInstance.ID);
            Assert.RecordCount(WorkflowRule, 1);
        until WorkflowStepInstance.Next() = 0;
    end;

    local procedure VerifyArchivedWorkflowStepInstance(Workflow: Record Workflow)
    var
        WorkflowStepInstanceArchive: Record "Workflow Step Instance Archive";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        WorkflowStepInstanceArchive.SetRange("Workflow Code", Workflow.Code);
        WorkflowStepInstanceArchive.SetRange("Function Name", WorkflowEventHandling.RunWorkflowOnCustomerChangedCode());
        Assert.RecordCount(WorkflowStepInstanceArchive, 2);
    end;
}

